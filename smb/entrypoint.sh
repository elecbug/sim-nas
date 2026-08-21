#!/usr/bin/env bash
set -euo pipefail

: "${SMB_USER:?SMB_USER is required}"
: "${SMB_SHARE:?SMB_SHARE is required}"
: "${PUID:?PUID is required}"
: "${PGID:?PGID is required}"

PASSWORD_FILE="/run/secrets/smb_password"

if [[ ! -r "$PASSWORD_FILE" ]]; then
    echo "ERROR: SMB password secret is missing or unreadable: $PASSWORD_FILE" >&2
    exit 1
fi

if [[ ! -d /nas/storage ]]; then
    echo "ERROR: /nas/storage does not exist." >&2
    exit 1
fi

if [[ ! "$PUID" =~ ^[0-9]+$ ]] || [[ ! "$PGID" =~ ^[0-9]+$ ]]; then
    echo "ERROR: PUID and PGID must be numeric." >&2
    exit 1
fi

if [[ ! "$SMB_USER" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "ERROR: SMB_USER may contain only letters, numbers, '.', '_' and '-'." >&2
    exit 1
fi

if [[ ! "$SMB_SHARE" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "ERROR: SMB_SHARE may contain only letters, numbers, '.', '_' and '-'." >&2
    exit 1
fi

# Resolve or create the requested primary group.
GROUP_NAME="$(getent group "$PGID" | cut -d: -f1 || true)"
if [[ -z "$GROUP_NAME" ]]; then
    GROUP_NAME="simnas"
    groupadd --gid "$PGID" "$GROUP_NAME"
fi

# Resolve name collision carefully. The SMB username itself must exist.
if id "$SMB_USER" >/dev/null 2>&1; then
    CURRENT_UID="$(id -u "$SMB_USER")"
    if [[ "$CURRENT_UID" != "$PUID" ]]; then
        echo "ERROR: user '$SMB_USER' already exists with UID $CURRENT_UID, requested UID is $PUID." >&2
        exit 1
    fi
    usermod --gid "$PGID" --shell /usr/sbin/nologin "$SMB_USER"
else
    UID_OWNER="$(getent passwd "$PUID" | cut -d: -f1 || true)"
    if [[ -n "$UID_OWNER" ]]; then
        echo "ERROR: UID $PUID is already owned by user '$UID_OWNER'. Choose another PUID." >&2
        exit 1
    fi

    useradd \
        --uid "$PUID" \
        --gid "$PGID" \
        --no-create-home \
        --home-dir /nonexistent \
        --shell /usr/sbin/nologin \
        "$SMB_USER"
fi

PASSWORD="$(cat "$PASSWORD_FILE")"
if [[ -z "$PASSWORD" ]]; then
    echo "ERROR: SMB password must not be empty." >&2
    exit 1
fi

# The persistent bind mount may be empty on first boot.
mkdir -p /var/lib/samba/private /var/lib/samba/lock /var/lib/samba/msg.lock
chmod 0700 /var/lib/samba/private

# Add or update the Samba account. The password database is persisted.
printf '%s\n%s\n' "$PASSWORD" "$PASSWORD" | smbpasswd -a -s "$SMB_USER" >/dev/null
smbpasswd -e "$SMB_USER" >/dev/null

export SMB_USER SMB_SHARE
envsubst '${SMB_USER} ${SMB_SHARE}' \
    < /etc/samba/smb.conf.template \
    > /etc/samba/smb.conf

testparm -s /etc/samba/smb.conf >/dev/null

mkdir -p /run/samba /var/log/samba

exec smbd --foreground --no-process-group --debug-stdout
