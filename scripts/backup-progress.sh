#!/usr/bin/env bash
# Snapshot the local Hanahuac progress data (SwiftData store + preferences) into a timestamped
# backup directory, then prune to a fixed retention cap. Used by `just install` as a safety net so a
# local app upgrade can never be the cause of progress loss.
#
# Usage:
#   backup-progress.sh backup    # create a new timestamped backup, then prune
#   backup-progress.sh verify    # warn (exit 0) if the live store is missing, naming latest backup
#
# All operations are best-effort: a missing store on a first-ever install is NOT an error.
set -euo pipefail

APP_SUPPORT="${HOME}/Library/Application Support"
BACKUP_ROOT="${APP_SUPPORT}/Hanahuac-backups"
STORE="${APP_SUPPORT}/default.store"
PREFS="${HOME}/Library/Preferences/maccatalyst.com.hanahuac.app.plist"
RETENTION=10

# Sources to snapshot (store + its WAL/SHM sidecars + the preferences plist).
sources=(
    "${STORE}"
    "${STORE}-wal"
    "${STORE}-shm"
    "${PREFS}"
)

prune() {
    # Keep only the RETENTION most-recent backup subdirectories; remove the rest.
    [[ -d "${BACKUP_ROOT}" ]] || return 0
    local dirs=()
    while IFS= read -r d; do
        dirs+=("${d}")
    done < <(find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d | sort)
    local count=${#dirs[@]}
    if (( count > RETENTION )); then
        local remove=$(( count - RETENTION ))
        local i
        for (( i = 0; i < remove; i++ )); do
            rm -rf "${dirs[i]}"
        done
        echo "  pruned ${remove} old backup(s) (cap ${RETENTION})."
    fi
}

latest_backup() {
    [[ -d "${BACKUP_ROOT}" ]] || return 0
    find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d | sort | tail -1
}

do_backup() {
    local stamp dest copied=0
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    dest="${BACKUP_ROOT}/${stamp}"
    local src
    for src in "${sources[@]}"; do
        if [[ -e "${src}" ]]; then
            mkdir -p "${dest}"
            cp -R "${src}" "${dest}/"
            copied=$(( copied + 1 ))
        fi
    done
    if (( copied > 0 )); then
        echo "  backed up ${copied} progress file(s) -> ${dest}"
    else
        echo "  no existing progress data found (fresh install) — nothing to back up."
    fi
    prune
}

do_verify() {
    if [[ -e "${STORE}" ]]; then
        echo "  verified: live progress store present at ${STORE}"
        return 0
    fi
    local latest
    latest="$(latest_backup)"
    echo "WARNING: live progress store is MISSING at ${STORE} after install." >&2
    if [[ -n "${latest}" ]]; then
        echo "WARNING: most recent backup is ${latest} — restore manually if this was unexpected." >&2
    else
        echo "WARNING: no backups exist to restore from." >&2
    fi
    # A missing store may be legitimate (first launch reseeds), so do not fail the install.
    return 0
}

case "${1:-}" in
    backup) do_backup ;;
    verify) do_verify ;;
    *)
        echo "usage: $0 {backup|verify}" >&2
        exit 2
        ;;
esac
