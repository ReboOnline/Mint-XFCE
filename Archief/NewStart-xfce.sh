#!/usr/bin/env bash
# NewStart-XFCE — post-install setup for Linux Mint XFCE
# Keep this script in the same repository folder as ./up and ./uit.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n\n==========================================================\n%s\n==========================================================\n' "$1"; }
warn() { printf 'WAARSCHUWING: %s\n' "$1" >&2; }

if [[ $EUID -eq 0 ]]; then
    echo "Start dit script als gewone gebruiker, niet met sudo. Het vraagt zelf om sudo waar nodig." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Kan /etc/os-release niet lezen; kan de Linux-distributie niet controleren." >&2
    exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "linuxmint" ]]; then
    warn "Dit script is bedoeld voor Linux Mint. Gedetecteerd: ${PRETTY_NAME:-onbekend}."
    read -r -p "Toch doorgaan? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is niet geïnstalleerd. Kan niet doorgaan." >&2
    exit 1
fi

log "Controleer repositorybestanden up en uit"
for name in up uit; do
    if [[ ! -f "$SCRIPT_DIR/$name" ]]; then
        echo "Bestand ontbreekt: $SCRIPT_DIR/$name" >&2
        echo "Zet up en uit in dezelfde map als dit script en probeer opnieuw." >&2
        exit 1
    fi
done
chmod +x "$SCRIPT_DIR/up" "$SCRIPT_DIR/uit"
sudo install -o root -g root -m 755 "$SCRIPT_DIR/up" /usr/local/bin/up
sudo install -o root -g root -m 755 "$SCRIPT_DIR/uit" /usr/local/bin/uit
echo "up en uit zijn geïnstalleerd in /usr/local/bin."

log "Werk pakketlijsten bij en installeer beschikbare updates"
sudo apt-get update
sudo apt-get -y upgrade

log "Installeer standaardsoftware via APT"
# Pakketten die niet beschikbaar zijn in de ingeschakelde Mint-bronnen worden overgeslagen.
packages=(
    variety
    gparted
    gimp
    nemo
    dconf-editor
    git
    fastfetch
    dmenu
    flameshot
    simplescreenrecorder
    flatpak
    preload
    gdebi
    ubuntu-restricted-extras
    libavcodec-extra
    htop
    doublecmd-gtk
    pavucontrol
    rar
    p7zip-rar
    catfish
    vlc
    curl
    wget
    gpg
    ca-certificates
    ufw
)

# Ubuntu Restricted Extras kan om een EULA-bevestiging vragen.
# Deze instelling accepteert de Microsoft-fontslicentie vooraf voor non-interactieve installatie.
if command -v debconf-set-selections >/dev/null 2>&1; then
    printf '%s\n' 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true' \
        | sudo debconf-set-selections
fi

available_packages=()
skipped_packages=()
for package in "${packages[@]}"; do
    candidate="$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
    if [[ -n "$candidate" && "$candidate" != "(none)" ]]; then
        available_packages+=("$package")
    else
        skipped_packages+=("$package")
    fi
done

if ((${#available_packages[@]})); then
    sudo apt-get install -y "${available_packages[@]}"
fi
if ((${#skipped_packages[@]})); then
    warn "Deze pakketten zijn niet beschikbaar en zijn overgeslagen: ${skipped_packages[*]}"
fi

log "Configureer Flatpak en installeer Spotify"
if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install --user --noninteractive -y flathub com.spotify.Client
else
    warn "Flatpak is niet beschikbaar; Spotify via Flatpak is overgeslagen."
fi

log "Installeer Visual Studio Code via de officiële Microsoft APT-repository"
if [[ "$(dpkg --print-architecture)" =~ ^(amd64|arm64|armhf)$ ]]; then
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg
    sudo chmod 0644 /etc/apt/keyrings/microsoft.gpg
    arch="$(dpkg --print-architecture)"
    printf 'Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/microsoft.gpg\n' "$arch" \
        | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null
    sudo apt-get update
    sudo apt-get install -y code
else
    warn "Microsoft biedt in deze scriptconfiguratie geen ondersteunde VS Code-architectuur: $(dpkg --print-architecture)."
fi

log "Installeer Discord"
if [[ "$(dpkg --print-architecture)" == "amd64" ]]; then
    discord_deb="$(mktemp --suffix=.deb)"
    trap 'rm -f "${discord_deb:-}"' EXIT
    if wget -q -O "$discord_deb" 'https://discord.com/api/download?platform=linux&format=deb'; then
        chmod 0644 "$discord_deb"
        sudo apt-get install -y "$discord_deb"
    else
        warn "Discord kon niet worden gedownload; installatie overgeslagen."
    fi
    rm -f "$discord_deb"
    trap - EXIT
else
    warn "De Discord .deb-download is in dit script alleen ingeschakeld voor amd64; installatie overgeslagen."
fi

log "Stel vm.swappiness in op 5"
sudo install -d -m 0755 /etc/sysctl.d
printf '%s\n' '# Managed by NewStart-XFCE' 'vm.swappiness=5' \
    | sudo tee /etc/sysctl.d/99-newstart-swappiness.conf >/dev/null
sudo sysctl --system >/dev/null
sysctl vm.swappiness

log "Controleer en activeer de firewall"
if command -v ufw >/dev/null 2>&1; then
    echo "UFW-status vóór wijziging:"
    sudo ufw status
    echo "De firewall wordt nu ingeschakeld. Dit kan inkomende netwerkverbindingen blokkeren."
    sudo ufw --force enable
    sudo ufw status
else
    warn "UFW is niet geïnstalleerd; firewallinstelling is overgeslagen."
fi

log "Installatie voltooid"
echo "Controleer eventuele waarschuwingen hierboven en herstart de computer wanneer dat uitkomt."
