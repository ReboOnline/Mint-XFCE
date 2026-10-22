#!/usr/bin/env bash
# Install the latest uCareSystem Core release on Linux Mint / Ubuntu derivatives.

set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Start dit script als gewone gebruiker, niet met sudo." >&2
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is niet geïnstalleerd. Kan niet doorgaan." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Kan /etc/os-release niet lezen." >&2
    exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "linuxmint" && "${ID_LIKE:-}" != *ubuntu* ]]; then
    echo "Dit script is bedoeld voor Linux Mint en Ubuntu-gebaseerde distributies." >&2
    exit 1
fi

printf '%s\n' "==========================================================" "Install uCareSystem Core" "=========================================================="
sudo apt-get update
sudo apt-get install -y curl jq ca-certificates

release_json="$(curl -fsSL -A 'NewStart-XFCE-uCareSystem-installer' https://api.github.com/repos/Utappia/uCareSystem/releases/latest)"
deb_url="$(printf '%s' "$release_json" | jq -r '[.assets[]? | select(.name | test("^ucaresystem-core_.*\\.deb$")) | .browser_download_url][0] // empty')"

if [[ -z "$deb_url" ]]; then
    echo "Kon geen ucaresystem-core .deb vinden in de nieuwste GitHub-release." >&2
    exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
curl -fL "$deb_url" -o "$tmpdir/ucaresystem-core.deb"
sudo apt-get install -y "$tmpdir/ucaresystem-core.deb"

printf '\n%s\n' "uCareSystem Core is geïnstalleerd." "Start het via het applicatiemenu of met: ucaresystem-core" "Bekijk opties met: ucaresystem-core -h"
