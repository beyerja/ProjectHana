#!/usr/bin/env bash
# test-gh-review-bot.sh — token-free tests for scripts/gh-review-bot.sh.
#
# All cases run WITHOUT any real App key or token. The wrapper is driven with stubbed `security`,
# `openssl`, `curl`, and `jq` binaries on PATH so no Keychain access, no real crypto, and no network
# is ever needed. The only secret-shaped values are clearly-fake markers generated at runtime — no
# key/token-shaped literal lives in this file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/gh-review-bot.sh"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# pass/fail/TMPROOT are assigned in the sourced lib (shellcheck cannot follow `source` without -x).
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# Clearly-fake secret markers, generated at runtime (never committed, never real credentials).
FAKE_KEY="stub-private-key-$$-$RANDOM"
FAKE_SIG="stub-signature-$$-$RANDOM"
FAKE_INSTALL_TOKEN="stub-install-token-$$-$RANDOM"
FAKE_APP_ID="123456"
FAKE_INSTALLATION_ID="987654"

# Build a PATH directory holding stubs.
#   mode: present       -> all three Keychain items resolve.
#         absent-key     -> private-key item missing.
#         absent-appid   -> app-id item missing.
#         absent-install -> installation-id item missing.
#         token-empty    -> token exchange returns JSON with no usable .token.
make_stub_path() {
    local mode="$1" dir
    dir="$(mktemp -d "${TMPROOT}/stubXXXXXX")"

    # --- security stub: emit the requested item by `-a <account>`, or fail (exit 44) when absent. ---
    cat > "${dir}/security" <<EOF
#!/usr/bin/env bash
set -euo pipefail
acct=""
while [[ \$# -gt 0 ]]; do
    case "\$1" in
        -a) acct="\$2"; shift 2;;
        *) shift;;
    esac
done
case "\${acct}" in
    private-key)
        [[ "${mode}" == "absent-key" ]] && exit 44
        printf '%s\n' "${FAKE_KEY}";;
    app-id)
        [[ "${mode}" == "absent-appid" ]] && exit 44
        printf '%s\n' "${FAKE_APP_ID}";;
    installation-id)
        [[ "${mode}" == "absent-install" ]] && exit 44
        printf '%s\n' "${FAKE_INSTALLATION_ID}";;
    *) exit 44;;
esac
EOF
    chmod +x "${dir}/security"

    # --- openssl stub: support both `base64` (real-ish, via system base64) and `dgst -sign`. -------
    # For signing it records that it was invoked and emits the fake signature, never touching a key.
    cat > "${dir}/openssl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-}" in
    base64)
        # Pass through to the system base64 so b64url() behaves; -A means no line wrapping.
        exec /usr/bin/base64 "\${@:2}";;
    dgst)
        # Signing path: record invocation, consume stdin, emit a fixed fake signature.
        echo "openssl-dgst-sign" >> "${dir}/openssl.calls"
        cat > /dev/null
        printf '%s' "${FAKE_SIG}";;
    *)
        exit 1;;
esac
EOF
    chmod +x "${dir}/openssl"

    # --- curl stub: record the URL it was POSTed to; return a JSON token body. ---------------------
    if [[ "${mode}" == "token-empty" ]]; then
        cat > "${dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
for arg in "\$@"; do
    case "\${arg}" in https://*) echo "\${arg}" >> "${dir}/curl.urls";; esac
done
printf '%s' '{"message":"Bad credentials"}'
EOF
    else
        cat > "${dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
for arg in "\$@"; do
    case "\${arg}" in https://*) echo "\${arg}" >> "${dir}/curl.urls";; esac
done
printf '%s' '{"token":"${FAKE_INSTALL_TOKEN}","expires_at":"2099-01-01T00:00:00Z"}'
EOF
    fi
    chmod +x "${dir}/curl"

    # --- jq stub: extract .token from the JSON body (covers `.token // empty`). --------------------
    cat > "${dir}/jq" <<EOF
#!/usr/bin/env bash
set -euo pipefail
body="\$(cat)"
# crude .token extraction sufficient for the stubbed JSON bodies above.
if [[ "\${body}" == *'"token":"'* ]]; then
    val="\${body#*'"token":"'}"
    val="\${val%%'"'*}"
    printf '%s\n' "\${val}"
fi
EOF
    chmod +x "${dir}/jq"

    # --- gh stub (target command): record argv and whether GH_TOKEN is set (never its value). ------
    cat > "${dir}/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "${dir}/gh.args"
if [[ -n "\${GH_TOKEN:-}" ]]; then
    printf '%s' "\${GH_TOKEN}" > "${dir}/gh.tokenval"
    echo "GH_TOKEN_SET" > "${dir}/gh.tokenflag"
else
    echo "GH_TOKEN_UNSET" > "${dir}/gh.tokenflag"
fi
EOF
    chmod +x "${dir}/gh"

    printf '%s' "${dir}"
}

# --- (a) per-item absent Keychain: non-zero exit, actionable message, target NOT run --------------
assert_fail_closed() {
    local mode="$1" label="$2" dir out rc
    dir="$(make_stub_path "${mode}")"
    set +e
    out="$(PATH="${dir}:${PATH}" "${WRAPPER}" gh api user 2>&1)"
    rc=$?
    set -e

    if [[ ${rc} -ne 0 ]]; then
        ok "${label} -> non-zero exit (${rc})"
    else
        ko "${label} should exit non-zero, got 0"
    fi
    if grep -q "hana-review-bot" <<< "${out}" && grep -q "docs/bot-credentials.md" <<< "${out}"; then
        ok "${label} -> actionable message names service + docs"
    else
        ko "${label} message missing service/docs: ${out}"
    fi
    if [[ ! -e "${dir}/gh.args" ]]; then
        ok "${label} -> target command NOT run"
    else
        ko "${label} should not run the target command"
    fi
}

test_absent_items() {
    assert_fail_closed absent-key "absent private-key"
    assert_fail_closed absent-appid "absent app-id"
    assert_fail_closed absent-install "absent installation-id"
}

test_token_exchange_fails() {
    assert_fail_closed token-empty "token exchange returns no .token"
}

# --- (b) no secret leak: no fake key / signature / install token in stdout/stderr or any file ------
test_no_leak() {
    local dir out
    dir="$(make_stub_path present)"
    set +e
    out="$(PATH="${dir}:${PATH}" "${WRAPPER}" gh api user 2>&1)"
    set -e

    local marker leaked=""
    for marker in "${FAKE_KEY}" "${FAKE_SIG}" "${FAKE_INSTALL_TOKEN}"; do
        if grep -qF "${marker}" <<< "${out}"; then
            leaked="${marker}"
        fi
    done
    if [[ -z "${leaked}" ]]; then
        ok "no secret marker in wrapper stdout/stderr"
    else
        ko "secret marker leaked to wrapper stdout/stderr"
    fi

    # Scan every file written under the stub dir (excluding the stub binaries and the legitimate
    # child handoff record gh.tokenval, which by design holds the minted token in the CHILD).
    local f leakfile=""
    while IFS= read -r f; do
        for marker in "${FAKE_KEY}" "${FAKE_SIG}"; do
            if grep -qF "${marker}" "${f}" 2>/dev/null; then
                leakfile="${f}"
            fi
        done
        # The install token must not be written anywhere the WRAPPER controls. The child's own
        # gh.tokenval is the expected handoff sink and is excluded below.
        if grep -qF "${FAKE_INSTALL_TOKEN}" "${f}" 2>/dev/null; then
            leakfile="${f}"
        fi
    done < <(find "${dir}" -type f \
        ! -name 'security' ! -name 'gh' ! -name 'openssl' ! -name 'curl' ! -name 'jq' \
        ! -name 'gh.tokenval')
    if [[ -z "${leakfile}" ]]; then
        ok "no secret marker written to any wrapper-controlled file"
    else
        ko "secret marker found in a written file: ${leakfile}"
    fi
}

# --- (c) happy path: exit 0, exact argv, GH_TOKEN set in child == minted install token ------------
test_passthrough() {
    local dir rc got
    dir="$(make_stub_path present)"
    set +e
    PATH="${dir}:${PATH}" "${WRAPPER}" gh api user --jq .login >/dev/null 2>&1
    rc=$?
    set -e

    if [[ ${rc} -eq 0 ]]; then
        ok "passthrough -> wrapper exited 0"
    else
        ko "passthrough -> wrapper exited ${rc}"
    fi

    got="$(cat "${dir}/gh.args" 2>/dev/null || true)"
    local want
    want=$'api\nuser\n--jq\n.login'
    if [[ "${got}" == "${want}" ]]; then
        ok "passthrough -> target received exact args"
    else
        ko "passthrough args mismatch. got: [${got}] want: [${want}]"
    fi

    if [[ "$(cat "${dir}/gh.tokenflag" 2>/dev/null || true)" == "GH_TOKEN_SET" ]]; then
        ok "passthrough -> GH_TOKEN set in child environment"
    else
        ko "passthrough -> GH_TOKEN was not set in child"
    fi

    # The child's GH_TOKEN must equal the minted FAKE installation token (not the JWT, not the key).
    local childtok
    childtok="$(cat "${dir}/gh.tokenval" 2>/dev/null || true)"
    if [[ "${childtok}" == "${FAKE_INSTALL_TOKEN}" ]]; then
        ok "passthrough -> child GH_TOKEN == minted installation token"
    else
        ko "passthrough -> child GH_TOKEN mismatch (expected minted install token)"
    fi
}

# --- (d) the access_tokens endpoint is hit, and the JWT was signed via openssl --------------------
test_token_exchange_path() {
    local dir
    dir="$(make_stub_path present)"
    set +e
    PATH="${dir}:${PATH}" "${WRAPPER}" gh api user >/dev/null 2>&1
    set -e

    if grep -qF "/app/installations/${FAKE_INSTALLATION_ID}/access_tokens" "${dir}/curl.urls" 2>/dev/null; then
        ok "token exchange -> access_tokens endpoint called with installation id"
    else
        ko "token exchange -> access_tokens endpoint not called with installation id"
    fi

    if grep -q "openssl-dgst-sign" "${dir}/openssl.calls" 2>/dev/null; then
        ok "token exchange -> JWT signed via openssl"
    else
        ko "token exchange -> openssl signing was not invoked"
    fi
}

# --- (e) xtrace is NEVER enabled (static source guard) --------------------------------------------
test_no_xtrace() {
    # Match only actual statements (a `set`/`BASH_XTRACEFD` at the start of a line, after optional
    # indentation) so the literal `set -x` mentioned in the header safety comment is not a false hit.
    if grep -Eq '^[[:space:]]*(set[[:space:]]+-[a-z]*x([[:space:]]|$)|set[[:space:]]+-o[[:space:]]+xtrace|BASH_XTRACEFD=)' "${WRAPPER}"; then
        ko "wrapper source enables xtrace (set -x / set -o xtrace / BASH_XTRACEFD)"
    else
        ok "wrapper source never enables xtrace"
    fi
}

# --- guard: no args -------------------------------------------------------------------------------
test_no_args() {
    local rc
    set +e
    "${WRAPPER}" >/dev/null 2>&1
    rc=$?
    set -e
    if [[ ${rc} -ne 0 ]]; then
        ok "no-args guard -> non-zero exit (${rc})"
    else
        ko "no-args guard should exit non-zero"
    fi
}

echo "== test-gh-review-bot.sh =="
test_no_args
test_absent_items
test_token_exchange_fails
test_no_leak
test_passthrough
test_token_exchange_path
test_no_xtrace

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
