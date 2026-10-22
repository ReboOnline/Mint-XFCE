```bash
#!/bin/bash

# ==========================================================
# Script: Enable Ctrl+Alt+Backspace
# Systeem: Linux Mint XFCE
# Doel: Grafische X-sessie kunnen beëindigen met een
#       toetsencombinatie
# ==========================================================

set -e

CONFIG="/etc/default/keyboard"
BACKUP="/etc/default/keyboard.bak"
OPTION="terminate:ctrl_alt_bksp"

echo "=========================================================="
echo " Enable Ctrl+Alt+Backspace"
echo "=========================================================="
echo ""

# Controleer of het script als root draait
if [[ $EUID -ne 0 ]]; then
    echo "Dit script heeft beheerdersrechten nodig."
    echo "Start het opnieuw met: sudo bash $0"
    exit 1
fi

# Controleer of het configuratiebestand bestaat
if [[ ! -f "$CONFIG" ]]; then
    echo "FOUT: $CONFIG niet gevonden."
    exit 1
fi

# Controleer of de instelling al actief is
if grep -qE '^XKBOPTIONS="[^"]*terminate:ctrl_alt_bksp' "$CONFIG"; then
    echo "De instelling is al ingeschakeld."
    exit 0
fi

# Maak een reservekopie als die nog niet bestaat
if [[ ! -f "$BACKUP" ]]; then
    cp -a "$CONFIG" "$BACKUP"
    echo "Reservekopie gemaakt: $BACKUP"
else
    echo "Bestaande reservekopie behouden: $BACKUP"
fi

# Voeg de instelling toe of pas de bestaande regel aan
if grep -q '^XKBOPTIONS=' "$CONFIG"; then
    sed -i \
        's|^XKBOPTIONS=.*|XKBOPTIONS="terminate:ctrl_alt_bksp"|' \
        "$CONFIG"
else
    echo 'XKBOPTIONS="terminate:ctrl_alt_bksp"' >> "$CONFIG"
fi

echo ""
echo "Instelling aangepast."
echo "Huidige configuratie:"
grep '^XKBOPTIONS=' "$CONFIG" || true
echo ""
echo "Herstart de computer om de wijziging toe te passen."
echo ""
echo "LET OP:"
echo "Ctrl+Alt+Backspace kan de grafische sessie abrupt"
echo "beëindigen. Niet-opgeslagen werk kan verloren gaan."
echo ""
echo "=========================================================="
```

