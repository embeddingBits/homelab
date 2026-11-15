# Selfhosted Setup

My selfhosted homelab setup managed using [Podman](https://podman.io/) and **Podman Compose**. Services are managed either with the `scripts/homelab.sh` wrapper or the Ansible playbook in `ansible/`.

# Infrastructure
## Tools 
- [Podman](https://podman.io/): Container orchestration
- [Ansible](https://ansible.com/): Automation and management

## Services

| Service    | Description            | Stack                |
| ---------- | ---------------------- | -------------------- |
| Homepage   | Dashboard              | `docker/homepage`    |
| Glance     | Dashboard / analytics  | `docker/glance`      |
| Trilium Next | Notes app              | Server tarball (standalone) |
| Kavita     | Book / reading server  | `docker/kavita`      |
| Navidrome  | Music streaming server | `docker/navidrome`   |
| Immich     | Photo/Video storage server | `docker/immich`  |
## Directory layout

```
.
├── docker/             # Docker compose files
├── data/               # Service data and config (gitignored)
├── media/
├── scripts/            # Some scripts to manage services
└── ansible/            # Ansible playbook, inventory and vars
```

Service state and app config live under `data/` (Homepage dashboards,
Navidrome's database, Kavita's library config, and so on). This directory is
deliberately not committed — it holds runtime data and would be useless to
clone. Trilium Next runs standalone from a tarball in `docker/TriliumNotes/`,
which is also gitignored for the same reason.

Secrets are kept in `.env` files next to each compose file (e.g.
`docker/immich/.env` holds the database password). The `.env` pattern is
gitignored, so nothing sensitive reaches the repo. Compose files only
reference the values as `${VAR}` placeholders.

## Managing services

`scripts/homelab.sh` wraps podman-compose. Stacks are directories under
`docker/` with a `compose.yml`; with no stack name the command runs against
every stack.

```sh
scripts/homelab.sh up            # start everything
scripts/homelab.sh up kavita     # start one stack
scripts/homelab.sh ps            # container status
scripts/homelab.sh logs -f       # logs (follow)
scripts/homelab.sh restart homepage
scripts/homelab.sh down          # stop and remove everything
```

## Managing with Ansible

The `ansible/` directory contains a playbook that manages the services on this
host. It runs locally (rootless, as the current user) and covers the full
deploy: installing prerequisites, syncing the repo, and starting the stacks.
The stacks it manages are listed in `ansible/group_vars/all.yml` (currently
homepage, kavita, and navidrome; Immich and Glance are started with the
wrapper script for now).

```sh
cd ansible
ansible-playbook homelab.yml                          # full deploy
ansible-playbook homelab.yml -e homelab_action=up     # start all stacks
ansible-playbook homelab.yml -e homelab_action=down   # stop and remove all stacks
ansible-playbook homelab.yml -e homelab_action=restart
ansible-playbook homelab.yml -e homelab_action=status # show container status
ansible-playbook homelab.yml -e homelab_action=logs   # show recent logs
```

## Music cover art

`scripts/music_cover.py` matches and embeds album cover art for the music
library. It reads each track's tags, looks the track up on the iTunes Search
API, and writes a plan you can review before it changes anything.

```sh
scripts/music_cover.py --music-dir ~/Music --dry-run   # write and review the plan
scripts/music_cover.py --music-dir ~/Music --apply     # download and embed covers
```

Tracks with an empty album tag get the resolved album name written back
(`set_album` in the plan). If a match is wrong, edit `resolved_album` / `art`
in the plan file before applying. Requires `ffmpeg` and `ffprobe`.

Cover art is embedded for `.m4a`/`.mp4`, `.mp3`, and `.flac`; `.ogg`, `.opus`,
and `.wav` are skipped (ffmpeg can't embed art in those containers).

# TODO
- [x] Ansible Playbooks
- [ ] Migrate to Kubernetes
- [ ] Backup using syncthing
