#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
    echo "usage: test/run.sh fresh [modules...] | migrate <chezmoi-ref> [profiles...] | shell | clean" >&2
    exit 2
}

case "$(uname -m)" in
arm64 | aarch64) native=linux/arm64 ;;
*) native=linux/amd64 ;;
esac

scenario=${1:-}
[ $# -gt 0 ] && shift

if [ "$scenario" = clean ]; then
    docker image rm -f dotfiles-test-amd64 dotfiles-test-arm64 >/dev/null 2>&1 || true
    docker volume ls -q --filter name=dotfiles-test-mise- | xargs docker volume rm -f >/dev/null 2>&1 || true
    exit 0
fi

default_platform=$native
[ "$scenario" = migrate ] && default_platform=linux/amd64
platform=${DOTFILES_TEST_PLATFORM:-$default_platform}
image=dotfiles-test-${platform##*/}

docker build --quiet --platform "$platform" \
    --build-arg MISE_VERSION="$(mise --version | cut -d' ' -f1)" \
    -t "$image" -f test/Containerfile test >/dev/null

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mounts=(-v "$PWD:/src:ro")
tty_opts=()
run() {
    local volume=dotfiles-test-mise-${platform##*/}-${1//,/-}
    shift
    docker run --rm --platform "$platform" ${tty_opts[@]+"${tty_opts[@]}"} "${mounts[@]}" \
        -v "$volume:/home/tester/.local/share/mise" "$image" "$@"
}

case "$scenario" in
shell)
    tty_opts=(-it)
    run shell bash
    exit 0
    ;;
fresh)
    [ $# -gt 0 ] || set -- none personal work,ssh,desktop
    ;;
migrate)
    [ $# -gt 0 ] || usage
    mkdir "$work/base"
    git archive "$1" | tar -x -C "$work/base"
    mounts+=(-v "$work/base:/base:ro")
    shift
    [ $# -gt 0 ] || set -- personal work
    ;;
*)
    usage
    ;;
esac

pids=()
names=()
for modules in "$@"; do
    [ "$modules" = none ] && modules=""
    run "$scenario-${modules:-none}" /src/test/e2e.sh "$scenario" "$modules" >"$work/${#names[@]}.log" 2>&1 &
    pids+=("$!")
    names+=("$scenario ${modules:-none}")
done

failed=0
for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
        echo "PASS: ${names[$i]}"
    else
        failed=1
        echo "=== FAIL: ${names[$i]}"
        cat "$work/$i.log"
    fi
done
exit $failed
