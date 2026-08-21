#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

cd "$ROOT_DIR"

load_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "ERROR: .env does not exist. Run './sim-nas init' first." >&2
        exit 1
    fi

    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a

    SMB_USER="${SMB_USER:-nas}"
    SMB_SHARE="${SMB_SHARE:-storage}"
    HOST_STORAGE_PATH="${HOST_STORAGE_PATH:-/mnt/nas}"
    PUID="${PUID:-1000}"
    PGID="${PGID:-1000}"
    SMB_PORT="${SMB_PORT:-445}"
    REQUIRE_MOUNT="${REQUIRE_MOUNT:-true}"
}

compose() {
    docker compose --project-directory "$ROOT_DIR" "$@"
}

is_true() {
    case "${1,,}" in
        1|true|yes|on) return 0 ;;
        *) return 1 ;;
    esac
}
