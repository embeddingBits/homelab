#!/usr/bin/env python3
"""Build the service status JSON consumed by the Glance analytics page.

For each service it collects:
  - container state from rootless Podman (when the service runs as a container)
  - HTTP health check result: status code, response time in ms, error text

Output: data/glance/assets/services.json (served by Glance under /assets/).
Designed to run from a systemd user timer every minute.
"""

import json
import subprocess
import time
import urllib.request
import urllib.error
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "data/glance/assets/services.json"
ICON_URL = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/{}.svg"
CHECK_TIMEOUT = 3  # seconds

SERVICES = [
    {
        "name": "Immich",
        "container": "immich_server",
        "port": 2283,
        "icon": "immich",
        "children": [
            {"name": "Immich ML", "container": "immich_machine_learning"},
            {"name": "Immich Redis", "container": "immich_redis"},
            {"name": "Immich Postgres", "container": "immich_postgres"},
        ],
    },
    {"name": "Kavita", "container": "kavita", "port": 5000, "icon": "kavita"},
    {
        "name": "Navidrome",
        "container": "navidrome_navidrome_1",
        "port": 4533,
        "icon": "navidrome",
    },
    # Trilium Next runs as a standalone server (no container). Default port 8080.
    {"name": "Trilium Next", "container": None, "port": 8080, "icon": "trilium"},
    {"name": "Glance", "container": "glance", "port": 7070, "icon": "glance"},
]


def container_states():
    """Map container name -> (running, status string) from podman ps -a."""
    try:
        out = subprocess.run(
            ["podman", "ps", "-a", "--format", "{{.Names}}\t{{.State}}\t{{.Status}}"],
            capture_output=True, text=True, timeout=15, check=True,
        ).stdout
    except Exception as exc:  # podman missing or daemon/socket issues
        return {}, str(exc)
    states = {}
    for line in out.splitlines():
        if not line.strip():
            continue
        name, state, status = line.split("\t", 2)
        states[name] = (state == "running", status)
    return states, None


def http_check(port):
    """GET localhost:<port>/ and return (ok, code, ms, error)."""
    url = f"http://localhost:{port}/"
    start = time.perf_counter()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "glance-status/1.0"})
        with urllib.request.urlopen(req, timeout=CHECK_TIMEOUT) as resp:
            code = resp.status
            ok = 200 <= code < 400
            error = None
    except urllib.error.HTTPError as exc:
        code, ok, error = exc.code, False, None
    except Exception as exc:  # connection refused, timeout, DNS...
        code, ok, error = 0, False, type(exc).__name__
    ms = round((time.perf_counter() - start) * 1000)
    return ok, code, ms, error


def build():
    global SERVICES_CHILDREN
    states, podman_error = container_states()
    services = []
    for svc in SERVICES:
        has_container = svc["container"] is not None
        if has_container:
            running, status = states.get(svc["container"], (False, None))
            container_state = status or "not created"
        else:
            running, container_state = None, ""

        children = []
        for child in svc.get("children", []):
            c_running, c_status = states.get(child["container"], (False, None))
            children.append(
                {
                    "name": child["name"],
                    "running": c_running,
                    "state": c_status or "not created",
                }
            )

        ok, code, ms, error = http_check(svc["port"])
        entry = {
            "name": svc["name"],
            "icon": ICON_URL.format(svc["icon"]),
            "url": f"http://localhost:{svc['port']}/",
            "has_container": has_container,
            "container_state": container_state,
            "running": running,
            "ok": ok,
            "code": code,
            "ms": ms,
            "error": error or "",
            "children": children,
        }
        services.append(entry)

    return {"checked_at": int(time.time()), "podman_error": podman_error or "", "services": services}


def main():
    data = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=1))
    tmp.replace(OUT)
    print(f"wrote {OUT} ({len(data['services'])} services)")


if __name__ == "__main__":
    main()
