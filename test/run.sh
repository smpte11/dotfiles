#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

image=dotfiles-test
volume=dotfiles-test-mise
platform=linux/amd64

usage() {
    echo "usage: test/run.sh fresh [modules...] | migrate <chezmoi-ref> [profiles...] | shell | clean" >&2
    exit 2
}

if [ "${1:-}" = clean ]; then
    docker image rm -f "$image" >/dev/null 2>&1 || true
    docker volume rm -f "$volume" >/dev/null 2>&1 || true
    exit 0
fi

docker build --quiet --platform "$platform" \
    --build-arg MISE_VERSION="$(mise --version | cut -d' ' -f1)" \
    -t "$image" -f test/Containerfile test >/dev/null

mounts=(-v "$PWD:/src:ro" -v "$volume:/home/tester/.local/share/mise")
tty_opts=()
run() {
    docker run --rm --platform "$platform" ${tty_opts[@]+"${tty_opts[@]}"} "${mounts[@]}" "$image" "$@"
}

scenario=${1:-}
[ $# -gt 0 ] && shift
case "$scenario" in
shell)
    tty_opts=(-it)
    run bash
    exit 0
    ;;
fresh)
    [ $# -gt 0 ] || set -- none personal work
    ;;
migrate)
    [ $# -gt 0 ] || usage
    base=$(mktemp -d)
    trap 'rm -rf "$base"' EXIT
    git archive "$1" | tar -x -C "$base"
    mounts+=(-v "$base:/base:ro")
    shift
    [ $# -gt 0 ] || set -- personal work
    ;;
*)
    usage
    ;;
esac

failed=0
for modules in "$@"; do
    [ "$modules" = none ] && modules=""
    echo "=== $scenario ${modules:-none}"
    run /src/test/e2e.sh "$scenario" "$modules" || failed=1
done
exit $failed
