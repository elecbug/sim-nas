#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
load_env

FAIL=0

ok()   { printf '%-34s %s\n' "$1" 'OK'; }
warn() { printf '%-34s %s\n' "$1" 'WARN'; }
fail() { printf '%-34s %s\n' "$1" 'FAIL'; FAIL=1; }

printf 'sim-nas system check\n\n'

if command -v docker >/dev/null 2>&1; then
    ok "Docker"
else
    fail "Docker"
fi

if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose"
else
    fail "Docker Compose"
fi

if [[ -f secrets/smb_password && -s secrets/smb_password ]]; then
    ok "SMB secret"
else
    fail "SMB secret"
fi

if [[ -d "$HOST_STORAGE_PATH" ]]; then
    ok "Storage path exists"
else
    fail "Storage path exists"
fi

if [[ -d "$HOST_STORAGE_PATH" && -r "$HOST_STORAGE_PATH" && -w "$HOST_STORAGE_PATH" && -x "$HOST_STORAGE_PATH" ]]; then
    ok "Storage path accessible"
else
    fail "Storage path accessible"
fi

if is_true "$REQUIRE_MOUNT"; then
    if mountpoint -q "$HOST_STORAGE_PATH"; then
        ok "Storage is a mount point"
    else
        fail "Storage is a mount point"
        echo "  Expected an actual filesystem mount at: $HOST_STORAGE_PATH"
    fi
else
    warn "Mount guard disabled"
fi

if [[ "$PUID" =~ ^[0-9]+$ && "$PGID" =~ ^[0-9]+$ ]]; then
    ok "PUID/PGID syntax"
else
    fail "PUID/PGID syntax"
fi

if [[ "$SMB_PORT" =~ ^[0-9]+$ ]] && (( SMB_PORT >= 1 && SMB_PORT <= 65535 )); then
    ok "SMB port syntax"
else
    fail "SMB port syntax"
fi

if command -v ss >/dev/null 2>&1; then
    if ss -H -ltn "sport = :$SMB_PORT" 2>/dev/null | grep -q .; then
        if docker ps --format '{{.Names}}' | grep -qx 'sim-nas'; then
            ok "TCP port $SMB_PORT (sim-nas running)"
        else
            fail "TCP port $SMB_PORT available"
            echo "  Another process is already listening on TCP/$SMB_PORT"
        fi
    else
        ok "TCP port $SMB_PORT available"
    fi
else
    warn "Port check skipped (ss missing)"
fi

if docker compose config >/dev/null 2>&1; then
    ok "Compose configuration"
else
    fail "Compose configuration"
fi

if (( FAIL != 0 )); then
    printf '\nSystem check failed. sim-nas should not be started.\n' >&2
    exit 1
fi

printf '\nSystem ready.\n'
