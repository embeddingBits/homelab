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
├── docker/             # Compose files per stack (+ .env, gitignored)
├── data/               # Service data and config (gitignored)
├── media/
└── scripts/            # Some scripts to manage services
```

Service state and app config live under `data/` (Homepage's dashboard config,
Navidrome's database, Kavita's library config, and so on). This directory is
deliberately not committed — it holds runtime data and would be useless to
clone. Trilium Next keeps its notes in the host directory set by
`TRILIUM_DATA_DIR` (outside the repo by default).

Every host path a stack mounts, plus any secrets, lives in a `.env` file next
to its compose file. Those files are gitignored, so personal paths and
credentials never reach the repo. Each stack ships a committed
`.env.example` template:

```sh
cp docker/kavita/.env.example docker/kavita/.env
$EDITOR docker/kavita/.env
```

Compose files only reference the values as `${VAR}` placeholders (for example
`${KAVITA_BOOKS_DIR}:/books`). `scripts/homelab.sh` runs `podman-compose`
inside the stack directory, so the local `.env` is picked up automatically.

| Stack | Variables |
| ----- | --------- |
| `budget` | `ACTUAL_DATA_DIR` |
| `homepage` | `HOMEPAGE_CONFIG_DIR`, `HOMEPAGE_MEDIA_DIR`, `PODMAN_SOCKET`, `TZ_FILE`, `HOMEPAGE_VAR_IMMICH_KEY`, `HOMEPAGE_ALLOWED_HOSTS` |
| `immich` | `UPLOAD_LOCATION`, `DB_DATA_LOCATION`, `TZ_FILE`, `IMMICH_VERSION`, `DB_PASSWORD`, `DB_USERNAME`, `DB_DATABASE_NAME` |
| `kavita` | `KAVITA_BOOKS_DIR`, `KAVITA_COLLEGE_DIR`, `KAVITA_CONFIG_DIR` |
| `navidrome` | `NAVIDROME_DATA_DIR`, `NAVIDROME_MUSIC_DIR` |
| `TriliumNotes` | `TRILIUM_DATA_DIR`, `TZ_FILE` |

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
scripts/homelab.sh restart kavita
scripts/homelab.sh down          # stop and remove everything
```

# TODO
- [ ] Recommendation and Downloading pipeline for Navidrome
- [ ] Migrate to Kubernetes
