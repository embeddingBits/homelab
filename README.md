# Selfhosted Setup

My selfhosted homelab setup managed using [Podman](https://podman.io/) and **Podman Compose**. Services are managed with the `scripts/homelab.sh` wrapper.

# Infrastructure
## Tools 
- [Podman](https://podman.io/): Container orchestration

## Services

| Service    | Description            | Stack                |
| ---------- | ---------------------- | -------------------- |
| Homepage   | Dashboard              | `docker/homepage`    |
| Trilium Next | Notes app              | `docker/TriliumNotes` |
| Kavita     | Book / reading server  | `docker/kavita`      |
| Navidrome  | Music streaming server | `docker/navidrome`   |
| Immich     | Photo/Video storage server | `docker/immich`  |
| Actual Budget | Finance / budgeting | `docker/budget`      |
## Directory layout

```
.
├── docker/             # Docker compose files
├── data/               # Service data and config (gitignored)
├── media/
└── scripts/            # Some scripts to manage services
```

Service state and app config live under `data/` (Homepage's dashboard config,
Navidrome's database, Kavita's library config, and so on). This directory is
deliberately not committed — it holds runtime data and would be useless to
clone. Trilium Next keeps its notes at `${TRILIUM_DATA_DIR}`, outside the repo
for the same reason.

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
- [ ] Recommendation and Downloading pipeline for Navidrome
- [ ] Migrate to Kubernetes
