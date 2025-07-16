#!/bin/bash

# -e: exit on error
# -u: exit on unset variables
set -eu

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Running on MacOS"
    HOMEBREW_PREFIX="/opt/homebrew"
else
    echo "Running on Linux"
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if command -v brew >/dev/null; then
    echo "brew is already installed"
else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    (
        echo
        echo "eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)""
    ) >>"$HOME"/.bashrc
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
fi

if ! chezmoi="$(command -v chezmoi)"; then
    bin_dir="${HOME}/.local/bin"
    chezmoi="${bin_dir}/chezmoi"
    echo "Installing chezmoi to '${chezmoi}'" >&2
    if command -v curl >/dev/null; then
        chezmoi_install_script="$(curl -fsSL https://chezmoi.io/get)"
    elif command -v wget >/dev/null; then
        chezmoi_install_script="$(wget -qO- https://chezmoi.io/get)"
    else
        echo "To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi
    sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
    unset chezmoi_install_script bin_dir
fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
