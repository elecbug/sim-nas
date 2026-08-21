#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Created .env from .env.example"
else
    echo ".env already exists; keeping current configuration."
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

SMB_USER="${SMB_USER:-nas}"
SMB_SHARE="${SMB_SHARE:-storage}"
HOST_STORAGE_PATH="${HOST_STORAGE_PATH:-/mnt/nas}"

mkdir -p secrets state/samba
chmod 700 secrets

printf 'SMB password for %s: ' "$SMB_USER"
IFS= read -r -s PASSWORD
echo
printf 'Confirm SMB password: '
IFS= read -r -s PASSWORD_CONFIRM
echo

if [[ -z "$PASSWORD" ]]; then
    echo "ERROR: password must not be empty." >&2
    exit 1
fi

if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    echo "ERROR: passwords do not match." >&2
    exit 1
fi

printf '%s' "$PASSWORD" > secrets/smb_password
chmod 600 secrets/smb_password

cat <<MSG

sim-nas initialized.

SMB user   : $SMB_USER
SMB share  : $SMB_SHARE
Host path  : $HOST_STORAGE_PATH

Review .env if needed, then run:
  ./sim-nas check
  ./sim-nas start
MSG
