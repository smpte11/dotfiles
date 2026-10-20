#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
identities_file="$source_dir/.chezmoidata/identities.toml"

run() {
    local tool=$1
    shift
    if command -v "$tool" >/dev/null 2>&1; then
        command "$tool" "$@"
    else
        mise exec "$tool@latest" -- "$tool" "$@"
    fi
}

gum() { run gum "$@"; }
jq() { run jq "$@"; }
chezmoi() { run chezmoi --source "$source_dir" "$@"; }

data() { chezmoi execute-template "$1" 2>/dev/null || true; }

heading() {
    gum style --foreground 212 --bold --margin "1 0 0 0" "$1"
}

ask_key() {
    local identity=$1 manager=$2 current
    current="$(jq -r --arg i "$identity" --arg m "$manager" '.[$i].ssh_keys[$m] // ""' <<<"$identities")"
    local key
    while :; do
        key="$(gum input --width 100 --header "$identity SSH public key stored in $manager" --placeholder "ssh-ed25519 AAAA..." --value "$current")"
        [[ $key == ssh-* || $key == ecdsa-* || $key == sk-* ]] && break
        gum style --foreground 196 "Expected an OpenSSH public key line."
    done
    identities="$(jq --arg i "$identity" --arg m "$manager" --arg k "$key" '.[$i].ssh_keys[$m] = $k' <<<"$identities")"
}

edit_identity() {
    local identity=$1 field value
    heading "Identity: $identity"
    for field in email ssh_host; do
        value="$(jq -r --arg i "$identity" --arg f "$field" '.[$i][$f] // ""' <<<"$identities")"
        value="$(gum input --width 80 --header "$field" --value "$value")"
        identities="$(jq --arg i "$identity" --arg f "$field" --arg v "$value" '.[$i][$f] = $v' <<<"$identities")"
    done
    value="$(jq -r --arg i "$identity" '.[$i].password_manager // "proton"' <<<"$identities")"
    value="$(gum choose --header "password manager" --selected "$value" 1password proton)"
    identities="$(jq --arg i "$identity" --arg v "$value" '.[$i].password_manager = $v' <<<"$identities")"
    value="$(jq -r --arg i "$identity" '.[$i].harness // "pi"' <<<"$identities")"
    value="$(gum choose --header "agent harness" --selected "$value" claude pi)"
    identities="$(jq --arg i "$identity" --arg v "$value" '.[$i].harness = $v' <<<"$identities")"
    ask_key "$identity" "$(jq -r --arg i "$identity" '.[$i].password_manager' <<<"$identities")"
}

gum style --border rounded --padding "0 2" --border-foreground 212 "dotfiles setup" "Pick this machine's profile and the identity it uses."

identities="$(data '{{ .identities | toJson }}')"
original_identities="$identities"
current_profile="$(data '{{ if .configured }}{{ .profile }}{{ end }}')"
current_name="$(data '{{ get . "name" }}')"

heading "Name"
name="$(gum input --width 60 --value "${current_name:-Felix Brousseau-Tremblay}")"

heading "Machine profile"
IFS=$'\n' read -r -d '' -a profiles < <(jq -r 'keys[]' <<<"$identities") || true
profile="$(gum choose --header "profile" --selected "${current_profile:-personal}" "${profiles[@]}" "new profile")"
if [[ $profile == "new profile" ]]; then
    profile="$(gum input --header "profile name" --placeholder "work")"
    identities="$(jq --arg i "$profile" '.[$i] //= {"ssh_keys": {}}' <<<"$identities")"
    edit_identity "$profile"
elif gum confirm --default=false "Edit the '$profile' identity?"; then
    edit_identity "$profile"
fi

manager="$(jq -r --arg i "$profile" '.[$i].password_manager' <<<"$identities")"
needed=(personal)
[[ $profile != personal ]] && needed+=("$profile")
for identity in "${needed[@]}"; do
    if [[ -z "$(jq -r --arg i "$identity" --arg m "$manager" '.[$i].ssh_keys[$m] // ""' <<<"$identities")" ]]; then
        heading "Missing key"
        ask_key "$identity" "$manager"
    fi
done

if [[ $identities != "$original_identities" ]]; then
    IDENTITIES="$identities" chezmoi execute-template '{{ dict "identities" (env "IDENTITIES" | fromJson) | toToml }}' >"$identities_file"
fi

heading "Summary"
gum style --border normal --padding "0 2" \
    "name              $name" \
    "profile           $profile" \
    "email             $(jq -r --arg i "$profile" '.[$i].email' <<<"$identities")" \
    "password manager  $manager" \
    "harness           $(jq -r --arg i "$profile" '.[$i].harness' <<<"$identities")"

gum confirm "Apply now?" || exit 0
DOTFILES_NAME="$name" DOTFILES_PROFILE="$profile" chezmoi init --apply

if [[ $identities != "$original_identities" ]]; then
    gum style --foreground 214 "Identities changed: commit .chezmoidata/identities.toml in $source_dir"
fi
