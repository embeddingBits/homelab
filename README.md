# Selfhosted Setup

My selfhosted homelab setup managed using [Podman](https://podman.io/) and **Podman Compose**. Services are managed either with the `scripts/homelab.sh` wrapper or the Ansible playbook in `ansible/`.

# Infrastructure
## Tools 
- [Podman](https://podman.io/): Container orchestration
- [Ansible](https://ansible.com/): Automation and management

## Services

| Service    | Description            | Stack                |
| ---------- | ---------------------- | -------------------- |
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

Service state and app config live under `data/` (Glance's dashboard config,
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
`docker/` with a compose file (`compose.yml` or `docker-compose.yml`); with
no stack name the command runs against every stack. Directories without a
compose file (e.g. the standalone Trilium tarball) are skipped with a note.

```sh
scripts/homelab.sh up            # start everything
scripts/homelab.sh up kavita     # start one stack
scripts/homelab.sh ps            # container status
scripts/homelab.sh logs -f       # logs (follow)
scripts/homelab.sh restart glance
scripts/homelab.sh down          # stop and remove everything
```

# TODO
- [x] Ansible Playbooks
- [ ] Migrate to Kubernetes
