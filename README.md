# SimNAS

**SimNAS** is a minimal Docker-based SMB NAS for Linux hosts. It exports one host directory through Samba while keeping disk mounting and filesystem management on the host.

## Architecture

```text
physical disk / RAID / LVM
          |
          | Linux mount
          v
       /mnt/nas
          |
          | Docker bind mount
          v
    /nas/storage
          |
          v
       Samba
          |
          v
  \\server\storage
```

## Requirements

- Linux
- Docker Engine
- Docker Compose v2 (`docker compose`)
- A mounted storage filesystem, by default at `/mnt/nas`

## Quick start

1. Mount the storage filesystem on the host.

```bash
sudo mkdir -p /mnt/nas
sudo mount /dev/sdX1 /mnt/nas
```

For persistent mounting, configure `/etc/fstab` using the filesystem UUID.

2. Run the interactive initializer.

```bash
./sim-nas init
```

`init` asks for the SMB account, share name, storage path, UID/GID, port and mount-guard policy. Press Enter to keep each displayed default. It then writes both `.env` and `compose.yaml` and creates/updates the SMB password secret.

Example:

```text
sim-nas initialization

SMB user [nas]: research
SMB share [storage]: data
Host storage path [/mnt/nas]: /mnt/storage
PUID [1000]:
PGID [1000]:
SMB port [445]:
Require actual mount (true/false) [true]:
```

Re-running `./sim-nas init` uses the current `.env` values as defaults. If a password secret already exists, pressing Enter at the password prompt keeps the existing password.

3. Verify the host and configuration.

```bash
./sim-nas check
```

4. Start the SMB server.

```bash
./sim-nas start
```

5. Check status.

```bash
./sim-nas status
```

Windows clients can connect to:

```text
\\<server-ip>\<share>
```

With the defaults:

```text
\\<server-ip>\storage
```

## Generated configuration

`./sim-nas init` generates these files:

```text
.env
compose.yaml
secrets/smb_password
```

Default values are:

```env
SMB_USER=nas
SMB_SHARE=storage
HOST_STORAGE_PATH=/mnt/nas
PUID=1000
PGID=1000
SMB_PORT=445
REQUIRE_MOUNT=true
```

`compose.yaml` is rendered with the selected values rather than relying on Compose-time variable substitution. This makes the effective Docker deployment easy to inspect. To change the configuration, re-run `./sim-nas init` instead of editing only one generated file.

`HOST_STORAGE_PATH` is mounted inside the container at the fixed path `/nas/storage`.

### Mount guard

By default, `sim-nas` refuses to start unless `HOST_STORAGE_PATH` is an actual mount point. This prevents an unmounted empty directory from being accidentally exposed when a disk failed to mount.

To intentionally export a directory on the root filesystem, select `false` for the mount guard during `./sim-nas init`.

## Commands

```text
./sim-nas init       Configure sim-nas and generate .env/compose.yaml
./sim-nas check      Validate Docker, storage, mount state, port, and Compose
./sim-nas start      Validate and start/rebuild the service
./sim-nas stop       Stop the service
./sim-nas restart    Restart the service
./sim-nas status     Show SMB, mount, device, filesystem, and capacity status
./sim-nas logs       Follow Samba container logs
```

## Permissions

The Samba account inside the container is created with `PUID` and `PGID`. The host storage should therefore be writable by those numeric IDs.

Example:

```bash
sudo chown 1000:1000 /mnt/nas
sudo chmod 0770 /mnt/nas
```

Do not recursively change ownership on an existing populated filesystem unless that is actually intended.

## Security notes

- SMB1 is disabled; Samba accepts SMB2/SMB3 only.
- Guest access is disabled.
- The SMB password is stored in `secrets/smb_password`, which is excluded from Git.
- Only the configured TCP SMB port is published to container port 445.
- The container does not receive block devices and does not run privileged.

Host firewall rules should restrict TCP/445 to trusted networks.
