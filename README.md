# Selfhosted Setup

My selfhosted homelab setup managed using [Podman](https://podman.io/) and **Podman Compose**. Services are managed with the `scripts/homelab.sh` wrapper.

# Infrastructure
## Tools 
- [Podman](https://podman.io/): Container orchestration

## Services

| Service    | Description            | Stack                |
| ---------- | ---------------------- | -------------------- |
| Homepage   | Dashboard              | `docker/homepage`    |
| Trilium Next | Note Taking              | `docker/TriliumNotes` |
| Kavita     | Book / reading server  | `docker/kavita`      |
| Navidrome  | Music streaming server | `docker/navidrome`   |
| Immich     | Photo/Video storage server | `docker/immich`  |
| Vaultwarden | Password Management | `docker/vaultwarden`      |
| Actual Budget | Budget Management App | `docker/budget`      |


## Directory layout

```
.
├── docker/             # Compose files per stack (+ .env, gitignored)
├── data/               # Service data and config (gitignored)
└── scripts/            # Some scripts to manage services
```


## Managing services

All the services that I use are only for myself, so at the moment I just manage them using scripts [scripts](./scripts/homelab.sh). 

```sh
scripts/homelab.sh up
scripts/homelab.sh up kavita
scripts/homelab.sh ps
scripts/homelab.sh logs -f
scripts/homelab.sh restart kavita
scripts/homelab.sh down
```

# TODO
- [ ] Ansible for management
- [ ] Recommendation and Downloading pipeline for Navidrome
- [ ] Container orchestration using Kubernetes
