# Protect the media drives

This machine (bazzite) is the media player. The media collection lives on a btrfs pool that spans /dev/sda (7.3T) and /dev/sdb (14.6T), device /dev/sda1, mounted at /run/media/system/media (df shows about 22T total, 2.6T used). It holds media/, torrents/, usenet/, libraryfolder.vdf and steamapps/. Nothing must ever happen to these drives.

## Rules

- Never write to, delete from, move, rename, reformat or relabel /run/media/system/media or the devices /dev/sda and /dev/sdb. Never run any state-changing or destructive command against that mount or those devices. Treat the pool as strictly read-only.
- The only writes allowed on the pool are the media server containers' own normal operation: the podman quadlets in ~/.config/containers/systemd/netfelix/ mount /run/media/system/media into the sonarr, radarr and jellyfin containers as /data, and those containers manage their own files there. The qbittorrent container mounts /run/media/system/media/torrents at the same path inside the container and manages download files under that folder only. If the questarr container is deployed, it mounts the same torrents folder at the same path and imports finished game downloads from torrents/questarr into its own games folder on the system disk.
- Never run rm, cp, mv, rsync, mount, umount, mkfs or any btrfs command that writes to or modifies /run/media/system/media, /dev/sda or /dev/sdb, not even to clean up, reorganize, rebalance or "fix" something. Reading from the pool (ls, find, cat, playing a file, copying a file out of it onto the system disk) is fine.
- Be careful with podman volume mounts and configarr root folders that point at /data: /data inside those containers is /run/media/system/media on the host. Do not change, prune, recreate or "clean" those mounts, volumes or root folders.
- If a task seems to require touching the media pool or its disks in any way, stop and ask the user first. Do not proceed and do not improvise a "safe" variant.
- The system disk is normal: /var/home is on /dev/nvme0n1p3, not on the media pool. Work under /var/home as usual.
