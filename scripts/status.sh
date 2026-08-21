#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
load_env

STATE="stopped"
HEALTH="-"
if docker inspect sim-nas >/dev/null 2>&1; then
    STATE="$(docker inspect -f '{{.State.Status}}' sim-nas 2>/dev/null || echo unknown)"
    HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' sim-nas 2>/dev/null || echo unknown)"
fi

MOUNTED=no
if mountpoint -q "$HOST_STORAGE_PATH" 2>/dev/null; then
    MOUNTED=yes
fi

DEVICE="-"
FSTYPE="-"
if command -v findmnt >/dev/null 2>&1 && [[ -e "$HOST_STORAGE_PATH" ]]; then
    DEVICE="$(findmnt -n -o SOURCE -T "$HOST_STORAGE_PATH" 2>/dev/null || echo '-')"
    FSTYPE="$(findmnt -n -o FSTYPE -T "$HOST_STORAGE_PATH" 2>/dev/null || echo '-')"
fi

printf 'sim-nas\n\n'
printf 'Container\n'
printf '  State       : %s\n' "$STATE"
printf '  Health      : %s\n' "$HEALTH"
printf '\nSMB\n'
printf '  User        : %s\n' "$SMB_USER"
printf '  Share       : %s\n' "$SMB_SHARE"
printf '  Port        : %s\n' "$SMB_PORT"
printf '\nStorage\n'
printf '  Host        : %s\n' "$HOST_STORAGE_PATH"
printf '  Container   : /nas/storage\n'
printf '  Mounted     : %s\n' "$MOUNTED"
printf '  Device      : %s\n' "$DEVICE"
printf '  Filesystem  : %s\n' "$FSTYPE"

if [[ -d "$HOST_STORAGE_PATH" ]]; then
    printf '\nCapacity\n'
    df -h "$HOST_STORAGE_PATH" | awk 'NR==1 || NR==2 {print "  " $0}'
fi
