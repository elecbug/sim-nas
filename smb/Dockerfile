FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       samba \
       samba-common-bin \
       smbclient \
       gettext-base \
       ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY smb.conf.template /etc/samba/smb.conf.template
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh

RUN chmod 0755 /entrypoint.sh /healthcheck.sh \
    && mkdir -p /nas/storage /run/samba /var/log/samba

EXPOSE 445/tcp

ENTRYPOINT ["/entrypoint.sh"]
