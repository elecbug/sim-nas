#!/usr/bin/env bash
set -euo pipefail

PASSWORD_FILE="/run/secrets/smb_password"
[[ -r "$PASSWORD_FILE" ]] || exit 1

PASSWORD="$(cat "$PASSWORD_FILE")"

smbclient \
    "//127.0.0.1/${SMB_SHARE}" \
    -U "${SMB_USER}%${PASSWORD}" \
    -c 'ls' \
    >/dev/null 2>&1
