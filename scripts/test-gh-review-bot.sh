#!/usr/bin/env bash
# test-gh-review-bot.sh — token-free tests for scripts/gh-review-bot.sh.
#
# All cases run WITHOUT the real bot token. They drive the wrapper with a stubbed `security` binary on
# PATH so no Keychain access (and no real token) is ever needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/gh-review-bot.sh"

# A clearly-fake token value used ONLY inside an ephemeral stub written to a temp dir (never committed,
# never a real credential). Generated at runtime so no token-shaped literal lives in this file.
FAKE_TOKEN="stub-token-$$-$RANDOM"

TMPROOT="$(mktemp -d)"
trap 'rm -rf "${TMPROOT}"' EXIT

pass=0
fail=0
note() {
    printf '  %s\n' "$1"
}
ok() {
    pass=$((pass + 1))
    printf 'PASS: %s\n' "$1"
}
ko() {
    fail=$((fail + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

# Build a PATH directory holding stubs. `security` succeeds and prints the fake token; the target
# command `gh` records the args it received and confirms GH_TOKEN was set in its environment.
make_stub_path() {
    local mode="$1" dir
    dir="$(mktemp -d "${TMPROOT}/stubXXXXXX")"

    # security stub
    if [[ "${mode}" == "present" ]]; then
        cat > "${dir}/security" <<EOF
#!/usr/bin/env bash
# Stub: emulate a Keychain hit, printing the fake token to stdout (like \`security … -w\`).
printf '%s\n' "${FAKE_TOKEN}"
EOF
    else
        cat > "${dir}/security" <<'EOF'
#!/usr/bin/env bash
# Stub: emulate a MISSING Keychain item — exit non-zero, print nothing.
exit 44
EOF
    fi
    chmod +x "${dir}/security"

    # gh stub: record argv and whether GH_TOKEN is set (but never the value) to files.
    cat > "${dir}/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "${dir}/gh.args"
if [[ -n "\${GH_TOKEN:-}" ]]; then
    echo "GH_TOKEN_SET" > "${dir}/gh.tokenflag"
else
    echo "GH_TOKEN_UNSET" > "${dir}/gh.tokenflag"
fi
EOF
    chmod +x "${dir}/gh"

    printf '%s' "${dir}"
}

# --- (a) absent Keychain item: non-zero exit, actionable message, target NOT run ------------------
test_absent_item() {
    local dir out rc
    dir="$(make_stub_path absent)"
    set +e
    out="$(PATH="${dir}:${PATH}" "${WRAPPER}" gh api user 2>&1)"
    rc=$?
    set -e

    if [[ ${rc} -ne 0 ]]; then
        ok "absent item -> non-zero exit (${rc})"
    else
        ko "absent item should exit non-zero, got 0"
    fi
    if grep -q "hana-review-bot" <<< "${out}" && grep -q "docs/bot-credentials.md" <<< "${out}"; then
        ok "absent item -> actionable message names service + docs"
    else
        ko "absent item message missing service/docs: ${out}"
    fi
    if [[ ! -e "${dir}/gh.args" ]]; then
        ok "absent item -> target command NOT run"
    else
        ko "absent item should not run the target command"
    fi
}

# --- (b) no token leak: token value absent from stdout/stderr and any file --------------------------
test_no_leak() {
    local dir out rc leakhit
    dir="$(make_stub_path present)"
    set +e
    out="$(PATH="${dir}:${PATH}" "${WRAPPER}" gh api user 2>&1)"
    rc=$?
    set -e

    if grep -qF "${FAKE_TOKEN}" <<< "${out}"; then
        ko "token value leaked to wrapper stdout/stderr"
    else
        ok "no token in wrapper stdout/stderr"
    fi

    # Scan every file written under the stub dir for the token value.
    leakhit=0
    while IFS= read -r f; do
        if grep -qF "${FAKE_TOKEN}" "${f}" 2>/dev/null; then
            leakhit=1
            note "leak in ${f}"
        fi
    done < <(find "${dir}" -type f ! -name 'security' ! -name 'gh')
    if [[ ${leakhit} -eq 0 ]]; then
        ok "no token written to any recorded file"
    else
        ko "token value found in a written file"
    fi
}

# --- (c) arg passthrough + GH_TOKEN set in child --------------------------------------------------
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
test_absent_item
test_no_leak
test_passthrough

echo
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
[[ ${fail} -eq 0 ]]
