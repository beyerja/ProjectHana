#!/usr/bin/env bash
# pre-commit-secret-scan.sh — defense-in-depth pre-commit hook.
#
# Scans the STAGED content of a commit for GitHub token-like strings and rejects the commit if any
# are found. Catches an accidental `git add` of a real token before it ever reaches history.
#
# Patterns rejected:
#   ghp_<36 alphanumerics>          classic personal access token
#   github_pat_<22>_<59 base62>     fine-grained personal access token
#
# Exit 0 (silent) when staged content is clean. Exit 1 with an actionable message on a match.
set -euo pipefail

# Match real GitHub tokens by their exact shape, NOT a loose "ghp_anything" substring.
#   ghp_  + exactly 36 chars from [A-Za-z0-9]
#   github_pat_ + 22 chars [A-Za-z0-9] + '_' + 59 chars [A-Za-z0-9]
readonly CLASSIC_PAT='ghp_[A-Za-z0-9]{36}'
readonly FINE_GRAINED_PAT='github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}'
readonly COMBINED_PAT="${CLASSIC_PAT}|${FINE_GRAINED_PAT}"

# Allowlist sentinel: lines that contain the literal marker `FAKE` immediately after the token prefix
# are deliberate test fixtures (e.g. `ghp_FAKE000…`), never real credentials. The project documents
# this sentinel so its own secret-scan tests/docs can reference a token-shaped string safely. Real
# GitHub tokens are random and effectively never contain this exact uppercase marker.
readonly ALLOWLIST_PAT='(ghp_FAKE|github_pat_FAKE)'

# Limit the scan to the added lines of staged changes (the diff), so we only ever inspect content
# that is actually about to be committed. `-U0` keeps context out; we look at '+' lines only.
staged_diff="$(git diff --cached --no-color -U0 || true)"

# Collect the added lines (leading '+', but not the '+++' file header).
added=""
while IFS= read -r line; do
    case "${line}" in
        +++*) ;;
        +*) added+="${line}"$'\n' ;;
        *) ;;
    esac
done <<< "${staged_diff}"

# Candidate matches = token-shaped lines that are NOT the allowlisted FAKE sentinel.
candidates="$(printf '%s' "${added}" | grep -En "${COMBINED_PAT}" | grep -Ev "${ALLOWLIST_PAT}" || true)"

if [[ -n "${candidates}" ]]; then
    {
        echo "COMMIT REJECTED: a GitHub token-like string was found in staged content."
        echo
        echo "Offending pattern(s) match: ghp_<36 chars> or github_pat_<…> (real PAT shapes)."
        echo "Matched line(s):"
        printf '%s\n' "${candidates}" | sed 's/^/  /'
        echo
        echo "Remove the secret from the staged change before committing."
        echo "If this is a legitimate non-secret, unstage it or rewrite it so it does not look"
        echo "like a real token. Never commit credentials — use the Keychain + scripts/gh-review-bot.sh."
    } >&2
    exit 1
fi

exit 0
