<!--
How to run: on the media-server, get this file without bootstrapping:
  cd ~/.dotfiles && jj git fetch && jj rebase --branch @ --destination 'trunk()'
Then start an agent in ~/.dotfiles and tell it: "follow docs/migrations/2026-11-12-torrent-media-server.md".
-->

# Migrate the media server to the torrent module

Dotfiles commit `0f7627888b7a` split the download stack into a `torrent` module and moved `gaming` (Questarr) from the media server to home-desktop. You move this machine to the new `media-server` profile. home-desktop runs its own brief after you finish, so end with the hand-off in step 6.

## Rules

- Read every file in `~/.agents/machine/` first. `protect-media-drives.md` makes the media pool at `/run/media/system/media` read-only for you.
- Show the human each state-changing command before you run it, and run it after they say yes.
- A step is done only when its check passes. When a check fails, stop and report the output to the human.

## Steps

1. **Confirm the machine.** Print `hostname` and the `env = [...]` line of `~/.dotfiles/home/.config/mise/miserc.local.toml`. Ask the human to confirm that this is the media server. Done when the human confirms and the list contains `media`.

2. **Back up Questarr.** Run `systemctl --user stop questarr-config.timer questarr.service`, then `tar -C ~/.config -czf ~/questarr-backup.tar.gz questarr`. `gaming` declares `~/.config/questarr` as a bootstrap directory, and its unapply can remove that directory. So this backup is the only copy that is sure to remain. Done when `tar -tzf ~/questarr-backup.tar.gz` lists files under `questarr/` and `systemctl --user is-active questarr.service` prints `inactive`.

3. **Switch the profile.** Run `DOTFILES_ENV=media-server mise run dotfiles:update`, then `systemctl --user daemon-reload`. If pass-cli asks for a login, the human does it. Done when the env line lists `torrent` and `media` but not `gaming`, and `~/.config/containers/systemd/netfelix/questarr.container` is gone.

4. **Check the pod.** Run `systemctl --user cat netfelix-pod.service` and count the `--publish` flags. Done when there are exactly 11: 9696 and 8191 from `torrent`, and 8989, 7878, 7879, 8096, 8920, 7359/udp, 1900/udp, 5055 and 5056 from the `media` drop-in. The running pod already publishes these ports, so you do not restart it. If the count is wrong, stop: a restart would drop the missing ports.

5. **Apply Configarr.** Run `systemctl --user start prowlarr-config.service`, then `systemctl --user start configarr.service`. Then check Sonarr's indexers through its API, with the key from `~/.config/sonarr/config.xml`: `curl -s -H "X-Api-Key: <key>" http://localhost:8989/api/v3/indexer`. Done when `systemctl --user show -p Result prowlarr-config.service configarr.service` prints `Result=success` two times, and Sonarr lists the five `(Prowlarr)` indexers: Knaben, LimeTorrents, Torrent9, TorrentDownload and YTS. For a failure, read `journalctl --user -u prowlarr-config -u configarr -n 50`.

6. **Hand off.** Tell the human three things. The media server is done. `~/questarr-backup.tar.gz` is ready for home-desktop. The next step is `docs/migrations/2026-11-12-torrent-home-desktop.md`. Keep the backup until home-desktop confirms the import.
