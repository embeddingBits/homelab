#!/usr/bin/env bash 
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$REPO_ROOT/docker"

usage() {
	cat <<EOF
Usage: $(basename "$0") <command> [stack] [options]

Commands:
  up        Create and start containers (detached)
  down      Stop and remove containers
  logs      Show logs (-f to follow)
  restart   Restart running containers (use "down" then "up" to fully recreate)
  ps        List containers

Stacks are directories under $COMPOSE_DIR containing a compose file
(compose.yml / compose.yaml / docker-compose.yml / docker-compose.yaml).
With no stack name, the command runs against every stack.

Examples:
  $(basename "$0") up
  $(basename "$0") up kavita
  $(basename "$0") logs -f
  $(basename "$0") restart glance
  $(basename "$0") down
EOF
}

compose_file() {
	local dir="$1"
	local f
	for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
		if [[ -f "$dir/$f" ]]; then
			return 0
		fi
	done
	return 1
}

stacks() {
	local name="${1:-}"
	if [[ -n "$name" ]]; then
		local dir="$COMPOSE_DIR/$name"
		if ! compose_file "$dir"; then
			echo "Error: no stack '$name' (no compose file in $dir)" >&2
			exit 1
		fi
		printf '%s\n' "$dir"
	else
		local found=0 dir
		for dir in "$COMPOSE_DIR"/*/; do
			dir="${dir%/}"
			if compose_file "$dir"; then
				printf '%s\n' "$dir"
				found=1
			elif [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
				echo "Note: skipping $(basename "$dir") (no compose file)" >&2
			fi
		done
		if [[ $found -eq 0 ]]; then
			echo "Error: no stacks found under $COMPOSE_DIR" >&2
			exit 1
		fi
	fi
}

run_in() {
	local dir="$1"
	shift
	echo "==> $(basename "$dir")"
	(cd "$dir" && podman-compose "$@")
}

# Run a podman-compose command against every stack. A failure in one stack
# is reported but does not stop the remaining stacks.
run_all() {
	local failed=0 dir
	for dir in "${DIRS[@]}"; do
		if ! run_in "$dir" "$@"; then
			echo "Error: stack $(basename "$dir") failed" >&2
			failed=1
		fi
	done
	return "$failed"
}

main() {
	if [[ $# -eq 0 ]]; then
		usage
		exit 1
	fi

	local command="$1"
	shift

	local follow=0 stack="" dir
	local -a passthrough=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f|--follow) follow=1 ;;
			-*) passthrough+=("$1") ;;
			*) stack="$1" ;;
		esac
		shift
	done

	DIRS=()
	while IFS= read -r dir; do
		DIRS+=("$dir")
	done < <(stacks "$stack")

	case "$command" in
		up)
			# Make sure the podman Docker-compatible API socket exists before
			# starting stacks that mount it (homepage). The socket unit stays
			# disabled at boot (nothing podman-related autostarts); starting it
			# here is on-demand, and the API daemon behind it only activates
			# when a client actually connects.
			systemctl --user start podman.socket 2>/dev/null || true
			run_all up -d "${passthrough[@]}"
			;;
		down)
			run_all down "${passthrough[@]}"
			;;
		restart)
			run_all restart "${passthrough[@]}"
			;;
		ps)
			for dir in "${DIRS[@]}"; do
				run_in "$dir" ps "${passthrough[@]}"
			done
			;;
		logs)
			if [[ $follow -eq 1 ]]; then
				local -a pids=()
				for dir in "${DIRS[@]}"; do
					(cd "$dir" && exec podman-compose logs -f "${passthrough[@]}") &
					pids+=("$!")
				done
				trap 'kill "${pids[@]}" 2>/dev/null' INT TERM EXIT
				wait
				trap - INT TERM EXIT
			else
				for dir in "${DIRS[@]}"; do
					run_in "$dir" logs --tail=200 "${passthrough[@]}"
				done
			fi
			;;
		*)
			echo "Error: unknown command '$command'" >&2
			usage
			exit 1
			;;
	esac
}

main "$@"
