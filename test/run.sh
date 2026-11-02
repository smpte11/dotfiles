#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
    cat >&2 <<EOF
usage: test/run.sh fresh [modules...] [--only group,...] [--fresh]
       test/run.sh migrate <chezmoi-ref> [profiles...] [--only group,...] [--fresh]
       test/run.sh shell [fresh|migrate] [modules]
       test/run.sh clean
groups: $(bash test/e2e.sh groups | paste -sd, -)
EOF
    exit 2
}

engine=${DOTFILES_TEST_ENGINE:-}
if [ -z "$engine" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        engine=docker
    else
        engine=podman
    fi
fi

case "$(uname -m)" in
arm64 | aarch64) native=linux/arm64 ;;
*) native=linux/amd64 ;;
esac

scenario=${1:-}
[ $# -gt 0 ] && shift

only=""
fresh=0
args=()
while [ $# -gt 0 ]; do
    case "$1" in
    --only) only=${2:?--only needs a list of groups}; shift ;;
    --fresh) fresh=1 ;;
    *) args+=("$1") ;;
    esac
    shift
done
set -- ${args[@]+"${args[@]}"}

if [ "$scenario" = clean ]; then
    "$engine" images --format '{{.Repository}}:{{.Tag}}' | grep -E '(^|/)dotfiles-test' | xargs "$engine" image rm -f >/dev/null 2>&1 || true
    "$engine" volume ls -q | grep '^dotfiles-test-mise-' | xargs "$engine" volume rm -f >/dev/null 2>&1 || true
    exit 0
fi

default_platform=$native
[ "$scenario" = migrate ] && default_platform=linux/amd64
platform=${DOTFILES_TEST_PLATFORM:-$default_platform}
arch=${platform##*/}
image=dotfiles-test-$arch

"$engine" build --quiet --platform "$platform" \
    --build-arg MISE_VERSION="$(mise --version | cut -d' ' -f1)" \
    -t "$image" -f test/Containerfile test >/dev/null

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mounts=(-v "$PWD:/src:ro")
base_id=""

slug_of() { printf '%s-%s' "$scenario" "${1:-none}" | tr , -; }

run_in() {
    local slug=$1
    shift
    "$engine" run --platform "$platform" --security-opt label=disable "${mounts[@]}" \
        -v "dotfiles-test-mise-$arch-$slug:/home/tester/.local/share/mise" "$@"
}

inputs_hash() {
    jj file list | grep -vxE 'test/(e2e|run)\.sh|README\.md|mise\.toml|docs/.*' | sort | while IFS= read -r f; do
        [ -f "$f" ] && shasum "$f"
    done | shasum | cut -c1-16
}

checkpoint_of() {
    local key
    key=$(printf '%s %s %s %s %s\n' "$files_hash" "$platform" "$1" "$base_id" "$(mise --version | cut -d' ' -f1)" | shasum | cut -c1-16)
    printf 'dotfiles-test-ckpt-%s-%s:%s' "$arch" "$1" "$key"
}

has_image() { "$engine" image inspect "$1" >/dev/null 2>&1; }

prune_checkpoints() {
    local repo=${1%:*} tag=${1##*:}
    "$engine" images --format '{{.Repository}}:{{.Tag}}' | grep -E "(^|/)$repo:" | grep -v ":$tag\$" |
        xargs "$engine" image rm -f >/dev/null 2>&1 || true
}

install() {
    local modules=$1 slug ckpt name
    slug=$(slug_of "$modules")
    ckpt=$(checkpoint_of "$slug")
    name=dotfiles-test-install-$arch-$slug
    "$engine" rm -f "$name" >/dev/null 2>&1 || true
    if run_in "$slug" --name "$name" "$image" /src/test/install.sh "$scenario" "$modules"; then
        "$engine" commit "$name" "$ckpt" >/dev/null
        "$engine" rm "$name" >/dev/null
        prune_checkpoints "$ckpt"
    else
        "$engine" rm -f "$name" >/dev/null 2>&1 || true
        return 1
    fi
}

check() {
    local modules=$1 group=$2 slug
    slug=$(slug_of "$modules")
    run_in "$slug" --rm -e MISE_FETCH_REMOTE_VERSIONS_CACHE=30d "$(checkpoint_of "$slug")" /src/test/e2e.sh "$scenario" "$modules" "$group"
}

jobs_max=${DOTFILES_TEST_JOBS:-6}
labels=()
spawn() {
    local id=${#labels[@]} label=$1 kind=$2
    shift 2
    while [ "$(jobs -rp | wc -l)" -ge "$jobs_max" ]; do sleep 0.2; done
    (
        rc=0
        case "$kind" in
        install) install "$@" ;;
        check) check "$@" ;;
        esac >"$work/$id.log" 2>&1 || rc=$?
        echo "$rc" >"$work/$id.rc"
    ) &
    labels+=("$label")
}

case "$scenario" in
shell)
    scenario=${1:-fresh}
    target=$image
    if [ $# -gt 0 ]; then
        files_hash=$(inputs_hash)
        ckpt=$(checkpoint_of "$(slug_of "${2:-}")")
        has_image "$ckpt" && target=$ckpt
    fi
    run_in "$(slug_of "${2:-}")" --rm -it "$target" bash
    exit 0
    ;;
fresh)
    [ $# -gt 0 ] || set -- none personal work,ssh,desktop
    ;;
migrate)
    [ $# -gt 0 ] || usage
    base_id=$(git rev-parse "$1^{commit}")
    mkdir "$work/base"
    git archive "$base_id" | tar -x -C "$work/base"
    mounts+=(-v "$work/base:/base:ro")
    shift
    [ $# -gt 0 ] || set -- personal work
    ;;
*)
    usage
    ;;
esac

groups=$(bash test/e2e.sh groups)
if [ -n "$only" ]; then
    for g in ${only//,/ }; do
        grep -qxF "$g" <<<"$groups" || { echo "unknown group: $g" >&2; usage; }
    done
    groups=${only//,/ }
fi
files_hash=$(inputs_hash)

for modules in "$@"; do
    [ "$modules" = none ] && modules=""
    if [ "$fresh" = 1 ] || ! has_image "$(checkpoint_of "$(slug_of "$modules")")"; then
        spawn "install $(slug_of "$modules")" install "$modules"
    fi
done
wait

failed=0
report() {
    local i rc
    for i in "${!labels[@]}"; do
        [ -f "$work/$i.reported" ] && continue
        rc=$(cat "$work/$i.rc")
        case "$rc" in
        0) echo "PASS: ${labels[$i]}" ;;
        77) echo "SKIP: ${labels[$i]}" ;;
        *)
            failed=1
            echo "=== FAIL: ${labels[$i]}"
            cat "$work/$i.log"
            ;;
        esac
        : >"$work/$i.reported"
    done
}
[ ${#labels[@]} -eq 0 ] || report

for modules in "$@"; do
    [ "$modules" = none ] && modules=""
    slug=$(slug_of "$modules")
    has_image "$(checkpoint_of "$slug")" || continue
    for group in $groups; do
        spawn "$slug $group" check "$modules" "$group"
    done
done
wait
[ ${#labels[@]} -eq 0 ] || report
exit $failed
