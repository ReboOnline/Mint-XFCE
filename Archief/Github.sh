#!/bin/bash

echo "Install Github Desktop " #
sleep 2
wget -O github-desktop.deb https://github.com/shiftkey/desktop/releases/download/release-2.8.3-linux1/GitHubDesktop-linux-2.8.3-linux1.deb
sudo dpkg -i github-desktop.deb
sudo apt install -f
echo ""
echo ""
echo "##########################################################"
