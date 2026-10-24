#!/usr/bin/env bash

# ==================================================
# Prism Launcher installeren
# Linux Mint XFCE
#
# Installatiemethode: Flatpak + Flathub
# Java: beheerd via Prism Launcher
# ==================================================

set -Eeuo pipefail

# Kleuren voor de terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functies
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[LET OP]${NC} $1"
}

error() {
    echo -e "${RED}[FOUT]${NC} $1" >&2
    exit 1
}

# Controleer besturingssysteem
if [[ ! -f /etc/os-release ]]; then
    error "Kan het besturingssysteem niet identificeren."
fi

source /etc/os-release

if [[ "${ID:-}" != "linuxmint" &&
      "${ID:-}" != "ubuntu" &&
      "${ID_LIKE:-}" != *debian* ]]; then
    error "Dit script is bedoeld voor Linux Mint en vergelijkbare systemen."
fi

# Controleer of sudo beschikbaar is
command -v sudo >/dev/null 2>&1 ||
    error "sudo is niet beschikbaar."

echo
echo "=========================================="
echo " Prism Launcher installatie"
echo " Linux Mint XFCE"
echo "=========================================="
echo

# Controleer internetverbinding
info "Internetverbinding controleren..."

if ! curl -fsSI --max-time 10 \
    https://flathub.org >/dev/null 2>&1; then

    warn "Internetverbinding kon niet worden gecontroleerd."
    warn "De installatie kan alsnog proberen door te gaan."
fi

# Pakketlijsten bijwerken
info "Pakketlijsten bijwerken..."

sudo apt update

# Installeer Flatpak indien nodig
if ! command -v flatpak >/dev/null 2>&1; then
    info "Flatpak installeren..."
    sudo apt install -y flatpak
else
    info "Flatpak is al geïnstalleerd."
fi

# Flathub toevoegen indien nodig
info "Flathub controleren..."

if ! flatpak remotes --columns=name |
    grep -Fxq "flathub"; then

    info "Flathub toevoegen..."

    sudo flatpak remote-add \
        --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
else
    info "Flathub is al beschikbaar."
fi

# Prism Launcher installeren
info "Prism Launcher installeren..."

sudo flatpak install \
    --system \
    --assumeyes \
    flathub \
    org.prismlauncher.PrismLauncher

# Installatie controleren
info "Installatie controleren..."

if flatpak info \
    --system \
    org.prismlauncher.PrismLauncher >/dev/null 2>&1; then

    echo
    echo "=========================================="
    echo " INSTALLATIE GESLAAGD"
    echo "=========================================="
    echo
    info "Prism Launcher is geïnstalleerd."
    info "Java-runtimevoorzieningen zijn opgenomen in de Flatpak-oplossing."
    echo
    echo "Start Prism Launcher via het Mint-menu"
    echo "of gebruik de volgende opdracht:"
    echo
    echo "flatpak run org.prismlauncher.PrismLauncher"
    echo
    echo "Volgende stappen:"
    echo "1. Start Prism Launcher."
    echo "2. Voeg je Microsoft-account toe."
    echo "3. Maak een Minecraft-instantie aan."
    echo "4. Selecteer de gewenste Minecraft-versie."
    echo "5. Start Minecraft."
    echo
else
    error "Prism Launcher kon niet worden geverifieerd."
fi