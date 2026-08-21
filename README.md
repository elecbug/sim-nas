# sim-nas

`sim-nas` is a minimal Docker-based SMB NAS for Linux hosts.
It exports one host directory through Samba while keeping disk mounting and filesystem management on the host.

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

2. Initialize sim-nas.

```bash
cp .env.example .env
# Edit .env if necessary.
./sim-nas init
```

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
\\<server-ip>\storage
```

## Configuration

Default `.env` values:

```env
SMB_USER=nas
SMB_SHARE=storage
HOST_STORAGE_PATH=/mnt/nas
PUID=1000
PGID=1000
SMB_PORT=445
REQUIRE_MOUNT=true
```

`HOST_STORAGE_PATH` is the only storage path exposed from the host. Inside the container it is always mounted at `/nas/storage`.

### Mount guard

By default, `sim-nas` refuses to start unless `HOST_STORAGE_PATH` is an actual mount point. This prevents an unmounted empty directory from being accidentally exposed when a disk failed to mount.

To intentionally export a directory on the root filesystem:

```env
REQUIRE_MOUNT=false
```

## Commands

```text
./sim-nas init       Create the local secret and initial configuration
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
- Only TCP port 445 is published.
- The container does not receive block devices and does not run privileged.

Host firewall rules should restrict TCP/445 to trusted networks.
