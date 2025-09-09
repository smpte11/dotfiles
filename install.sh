#!/bin/bash

# On Linux, detect user context and switch if necessary (for devcontainer scenarios)
if [[ "$(uname -s)" != "Darwin" ]] && [ "$(id -u)" -eq 0 ]; then
    # We are root on Linux. Check for a non-root user to switch to.
    # Priority:
    # 1. DOTFILES_USER environment variable
    # 2. 'vscode' user
    # 3. User with UID 1000
    TARGET_USER=""
    if [ -n "${DOTFILES_USER:-}" ]; then
        # Check if user exists
        if id -u "$DOTFILES_USER" >/dev/null 2>&1; then
            TARGET_USER="$DOTFILES_USER"
        else
            echo "Warning: User '$DOTFILES_USER' specified in DOTFILES_USER env var not found. Ignoring."
        fi
    fi

    # If DOTFILES_USER was not set or not found, try vscode user
    if [ -z "$TARGET_USER" ] && getent passwd vscode >/dev/null 2>&1; then
        TARGET_USER="vscode"
    fi

    # If still no user, try UID 1000
    if [ -z "$TARGET_USER" ] && getent passwd 1000 >/dev/null 2>&1; then
        TARGET_USER=$(getent passwd 1000 | cut -d: -f1)
    fi

    if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
        echo "Running as root on Linux. Switching to user '$TARGET_USER' to continue installation."
        # Re-execute this script as the target user.
        # The Homebrew installer within the script is smart enough to use `sudo`
        # for system-level dependencies, and devcontainer users typically have passwordless sudo.
        if command -v sudo >/dev/null 2>&1; then
            exec sudo -u "$TARGET_USER" -H -- "$0" "$@"
        elif command -v gosu >/dev/null 2>&1; then
            exec gosu "$TARGET_USER" "$0" "$@"
        elif command -v su-exec >/dev/null 2>&1; then
            exec su-exec "$TARGET_USER" "$0" "$@"
        else
            echo "ERROR: Cannot switch to user '$TARGET_USER'." >&2
            echo "Please install 'sudo', 'gosu', or 'su-exec' to proceed." >&2
            exit 1
        fi
    fi
fi

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
