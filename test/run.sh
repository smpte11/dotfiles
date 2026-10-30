#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

image=dotfiles-test
volume=dotfiles-test-mise
platform=linux/amd64
base_ref=${BASE_REF:-main}

if [ "${1:-}" = clean ]; then
    docker image rm -f "$image" >/dev/null 2>&1 || true
    docker volume rm -f "$volume" >/dev/null 2>&1 || true
    exit 0
fi

docker build --quiet --platform "$platform" \
    --build-arg MISE_VERSION="$(mise --version | cut -d' ' -f1)" \
    -t "$image" -f test/Containerfile test >/dev/null

mounts=(-v "$PWD:/src:ro" -v "$volume:/home/tester/.local/share/mise")
if [ -n "${BASE_DIR:-}" ]; then
    mounts+=(-v "$BASE_DIR:/base:ro")
elif [ "$base_ref" != none ]; then
    base=$(mktemp -d)
    trap 'rm -rf "$base"' EXIT
    git archive "$base_ref" | tar -x -C "$base"
    mounts+=(-v "$base:/base:ro")
fi

tty_opts=()
run() {
    local profile=$1
    shift
    docker run --rm --platform "$platform" ${tty_opts[@]+"${tty_opts[@]}"} "${mounts[@]}" \
        -e DOTFILES_PROFILE="$profile" "$image" "$@"
}

if [ "${1:-}" = shell ]; then
    tty_opts=(-it)
    run "${2:-personal}" bash
    exit 0
fi

profiles=("$@")
[ ${#profiles[@]} -gt 0 ] || profiles=(personal work)

failed=0
for profile in "${profiles[@]}"; do
    echo "=== $profile"
    run "$profile" /src/test/e2e.sh || failed=1
done
exit $failed
