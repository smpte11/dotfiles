<!--
How to run: on the home-desktop, get this file without bootstrapping:
  cd ~/.dotfiles && jj git fetch && jj rebase --branch @ --destination 'trunk()'
Then start an agent in ~/.dotfiles and tell it: "follow docs/migrations/2026-11-12-torrent-home-desktop.md".
Run it only after docs/migrations/2026-11-12-torrent-media-server.md is done.
-->

# Move Questarr to home-desktop

Dotfiles commit `0f7627888b7a` added a `torrent` module (netfelix pod with prowlarr and byparr, plus a VPN-gated qbittorrent) and moved `gaming` (Questarr) to home-desktop. The media server has already stopped Questarr and left a backup at `~/questarr-backup.tar.gz` on that machine. You restore that backup here and bring up the stack.

## Rules

- Read every file in `~/.agents/machine/` first.
- Show the human each state-changing command before you run it, and run it after they say yes.
- Treat the media server as read-only. You only read from it: the backup, and the games under `/run/media/system/media/media/games`.
- The human does the logins (pass-cli, the qbittorrent WebUI) and gives you the media server's SSH target.
- A step is done only when its check passes. When a check fails, stop and report the output to the human.

## Steps

1. **Confirm the machine.** Print `hostname` and the `env = [...]` line of `~/.dotfiles/home/.config/mise/miserc.local.toml`. Ask the human to confirm that this is home-desktop and that the media server brief is done. Done when the human confirms both, `ss -ltn` shows nothing on port 8081, and `ip -4 addr show dev proton0` shows an `inet` address. The qbittorrent container needs port 8081. The VPN guard starts qbittorrent only while `proton0` is up.

2. **Restore Questarr.** Ask the human for the media server's SSH target. Copy `<target>:questarr-backup.tar.gz` to `~/questarr-backup.tar.gz`. If `~/.config/questarr` has files, move it aside to `~/.config/questarr.bak-<timestamp>`. Then extract with `tar -C ~/.config -xzf ~/questarr-backup.tar.gz`. Done when `~/.config/questarr` holds the restored files.

3. **Copy the games.** Ask the human if they want the games copied. If yes, run `rsync -a <target>:/run/media/system/media/media/games/ ~/.local/share/questarr/games/`. Done when the human says no, or when the file count in `~/.local/share/questarr/games` matches the file count of the source dir.

4. **Switch the profile.** Run `DOTFILES_ENV=home-desktop mise run dotfiles:update`, then `systemctl --user daemon-reload`. Then start `netfelix-pod.service`, `prowlarr.service`, `byparr.service` and `questarr.service`. If pass-cli asks for a login, the human does it. Done when the env line lists `torrent` and `gaming`, and `podman ps` shows prowlarr, byparr, qbittorrent and questarr as running.

5. **Set the qbittorrent login.** The qbittorrent config is new, so the WebUI has a temporary password. Get it from `podman logs qbittorrent`. Give it to the human, and ask them to do this at `http://localhost:8081`: log in as `admin`, go to Tools -> Options -> WebUI, and set the username from `pass://Media/Netfelix/QBIT_USERNAME` and the password from `pass://Media/qbittorrent`. Done when the human confirms that the login is saved.

6. **Apply the config.** Run `systemctl --user start prowlarr-config.service`, then `systemctl --user start questarr-config.service`. Done when `systemctl --user show -p Result prowlarr-config.service questarr-config.service` prints `Result=success` two times, and prowlarr lists the five indexers. To list them, run `curl -s -H "X-Api-Key: <key>" http://localhost:9696/api/v1/indexer` with the key from `~/.config/prowlarr/config.xml`. The five indexers are Knaben, LimeTorrents, Torrent9, TorrentDownload and YTS. For a failure, read `journalctl --user -u prowlarr-config -u questarr-config -n 50`.

7. **Test an import.** Ask the human to open `http://localhost:5000`, check that the library from the media server is there, and start one small game download. Questarr saves the download to `~/.local/share/torrents/questarr`, and when it is complete, imports it into `~/.local/share/questarr/games`. It needs no path mapping, because both containers mount the torrents dir at the same path. Done when the new game is in `~/.local/share/questarr/games`.

8. **Clean up.** Tell the human that the migration is done. They can now delete `~/questarr-backup.tar.gz` on both machines. Delete the local copy only if the human says yes.
