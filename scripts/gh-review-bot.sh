#!/usr/bin/env bash
# gh-review-bot.sh — the single sanctioned path to authenticate as the Hanahuac-Bot identity.
#
# Mints a SHORT-LIVED GitHub App installation token at runtime (replacing the old long-lived classic
# PAT) and execs the command passed as arguments with GH_TOKEN set in the CHILD process's environment
# only. No secret (App private key, JWT, signature, or installation token) is ever printed, written to
# a file, or visible in this script's own output.
#
# Flow:
#   1. Read three items from the macOS Keychain (service `hana-review-bot`), distinguished by account:
#        -a private-key       the App's RSA private key (PEM)
#        -a app-id            the GitHub App's numeric App ID
#        -a installation-id   the App installation ID on this repo
#      Fail CLOSED if ANY is absent/empty — the underlying command is NOT run.
#   2. Build a JWT signed RS256 with the private key via `openssl` (iss = App ID, iat = now-60s for
#      clock-skew margin, exp = now+540s — well under GitHub's 10-minute cap).
#   3. POST https://api.github.com/app/installations/<installation-id>/access_tokens with the JWT as a
#      Bearer credential; parse `.token` from the JSON response. Fail CLOSED if no token is returned.
#   4. Inject that short-lived token as GH_TOKEN into the child and `exec` the command.
#
# Usage:
#   scripts/gh-review-bot.sh gh api user
#   scripts/gh-review-bot.sh gh pr review 123 --approve
#
# Setup (one-time, human): see docs/bot-credentials.md.
#
# Credential-safety invariants (do not weaken):
#   - xtrace (`set -x` / `set -o xtrace`) is NEVER enabled — it would echo secret-bearing lines.
#   - No secret (private key, JWT, signature, installation token) is ever echo/printf'd, redirected,
#     or written to any file. Secrets live in shell variables / process substitution only; the private
#     key is fed to openssl via process substitution, never a CLI arg (would land in `ps`).
#   - On an absent Keychain item, or a failed token exchange, the underlying command is NOT run
#     (fail closed — no fallback to an unauthenticated call).
set -euo pipefail

readonly KEYCHAIN_SERVICE="hana-review-bot"
readonly SETUP_DOCS="docs/bot-credentials.md"

# Keychain account names for the three App credentials (see header).
readonly ACCT_PRIVATE_KEY="private-key"
readonly ACCT_APP_ID="app-id"
readonly ACCT_INSTALLATION_ID="installation-id"

# Fail-closed helper: print an actionable message naming the service + docs, then exit non-zero.
fail_closed() {
    {
        echo "error: $1"
        echo "The underlying command was NOT run."
        echo "Configure the GitHub App credentials in the macOS Keychain (service '${KEYCHAIN_SERVICE}')."
        echo "Setup instructions: ${SETUP_DOCS}"
    } >&2
    exit 1
}

# base64url-encode stdin: standard base64, then `+`->`-`, `/`->`_`, strip `=` padding, no newlines.
b64url() {
    openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# Build an RS256-signed JWT and print it to stdout (consumed in-process only).
# $1 = App ID (iss), $2 = PEM private key.
build_jwt() {
    local app_id="$1" private_key="$2" now header payload signing_input signature
    now="$(date +%s)"

    header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url)"
    # iat back-dated 60s for clock skew; exp 540s out (< GitHub's 10-minute maximum).
    payload="$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now - 60))" "$((now + 540))" "${app_id}" | b64url)"
    signing_input="${header}.${payload}"

    # Sign with the private key supplied via process substitution (never a CLI arg, never a temp file
    # holding the key on disk). The signing input is fed on stdin.
    #
    # NOTE: a failed command-substitution ASSIGNMENT does not abort under `set -e`, so an openssl
    # signing failure here would otherwise leave `signature` empty and let build_jwt return 0 with a
    # trailing-dot JWT — making the caller's "openssl signing error" branch unreachable. Guard
    # explicitly: if the signature is empty (signing produced nothing), return non-zero so the caller's
    # failure handler fires. Secrets stay in-process; nothing is echoed.
    signature="$(printf '%s' "${signing_input}" \
        | openssl dgst -sha256 -sign <(printf '%s' "${private_key}") \
        | b64url)"
    if [[ -z "${signature}" ]]; then
        return 1
    fi

    printf '%s.%s' "${signing_input}" "${signature}"
}

# Read a single Keychain item by account; echoes the value (consumed in-process only).
read_keychain_item() {
    security find-generic-password -s "${KEYCHAIN_SERVICE}" -a "$1" -w 2>/dev/null
}

main() {
    # Guard: nothing to exec.
    if [[ $# -eq 0 ]]; then
        echo "usage: $0 <command> [args...]   (e.g. $0 gh api user)" >&2
        echo "Mints a short-lived GitHub App token from Keychain service '${KEYCHAIN_SERVICE}'." >&2
        exit 2
    fi

    # --- Step 1: read the three Keychain items. Fail closed if any is absent/empty. ---------------
    local private_key app_id installation_id
    private_key="$(read_keychain_item "${ACCT_PRIVATE_KEY}" || true)"
    app_id="$(read_keychain_item "${ACCT_APP_ID}" || true)"
    installation_id="$(read_keychain_item "${ACCT_INSTALLATION_ID}" || true)"

    if [[ -z "${private_key}" ]]; then
        fail_closed "no App private key in the Keychain (account '${ACCT_PRIVATE_KEY}')."
    fi
    if [[ -z "${app_id}" ]]; then
        fail_closed "no App ID in the Keychain (account '${ACCT_APP_ID}')."
    fi
    if [[ -z "${installation_id}" ]]; then
        fail_closed "no installation ID in the Keychain (account '${ACCT_INSTALLATION_ID}')."
    fi

    # macOS `security … -w` returns any value that contains newlines (such as a multi-line PEM) as a
    # contiguous hex string, NOT raw text — so a correctly-stored App private key comes back
    # hex-encoded regardless of whether it was stored via the CLI or the Keychain Access GUI. If the
    # value isn't already PEM-armored, treat it as that hex encoding and decode it back to the real
    # PEM. A value that already arrives in PEM form is passed through untouched. Done in-process; no
    # secret is echoed (xtrace stays off).
    if [[ "${private_key}" != *"-----BEGIN"* ]]; then
        local private_key_hex
        private_key_hex="$(printf '%s' "${private_key}" | tr -d '[:space:]')"
        if [[ "${private_key_hex}" =~ ^[0-9A-Fa-f]+$ ]]; then
            private_key="$(printf '%s' "${private_key_hex}" | xxd -r -p)"
        fi
        if [[ "${private_key}" != *"-----BEGIN"* ]]; then
            fail_closed "the stored App private key is neither PEM nor hex-encoded PEM (account '${ACCT_PRIVATE_KEY}')."
        fi
    fi

    # --- Step 2: build the RS256 JWT. ------------------------------------------------------------
    local jwt
    if ! jwt="$(build_jwt "${app_id}" "${private_key}")" || [[ -z "${jwt}" ]]; then
        fail_closed "failed to build the App JWT (openssl signing error)."
    fi

    # --- Step 3: exchange the JWT for a short-lived installation token. ---------------------------
    local token_url response token
    token_url="https://api.github.com/app/installations/${installation_id}/access_tokens"
    if ! response="$(curl -sS -X POST "${token_url}" \
        -H "Authorization: Bearer ${jwt}" \
        -H "Accept: application/vnd.github+json" 2>/dev/null)"; then
        fail_closed "the installation-token request to GitHub failed."
    fi

    token="$(printf '%s' "${response}" | jq -r '.token // empty' 2>/dev/null || true)"
    if [[ -z "${token}" ]]; then
        fail_closed "GitHub returned no installation token (check App permissions/installation)."
    fi

    # --- Step 4: inject the minted token as GH_TOKEN into the child only and hand off. -----------
    # `exec` replaces this shell so the token-bearing environment never lingers.
    exec env GH_TOKEN="${token}" "$@"
}

main "$@"
