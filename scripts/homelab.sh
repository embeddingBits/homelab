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
  $(basename "$0") restart homepage
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

	local -a dirs=()
	while IFS= read -r dir; do
		dirs+=("$dir")
	done < <(stacks "$stack")

	case "$command" in
		up)
			for dir in "${dirs[@]}"; do
				run_in "$dir" up -d "${passthrough[@]}"
			done
			;;
		down)
			for dir in "${dirs[@]}"; do
				run_in "$dir" down "${passthrough[@]}"
			done
			;;
		restart)
			for dir in "${dirs[@]}"; do
				run_in "$dir" restart "${passthrough[@]}"
			done
			;;
		ps)
			for dir in "${dirs[@]}"; do
				run_in "$dir" ps "${passthrough[@]}"
			done
			;;
		logs)
			if [[ $follow -eq 1 ]]; then
				local -a pids=()
				for dir in "${dirs[@]}"; do
					(cd "$dir" && exec podman-compose logs -f "${passthrough[@]}") &
					pids+=("$!")
				done
				trap 'kill "${pids[@]}" 2>/dev/null' INT TERM EXIT
				wait
				trap - INT TERM EXIT
			else
				for dir in "${dirs[@]}"; do
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
