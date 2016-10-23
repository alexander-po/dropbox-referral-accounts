#!/bin/bash
# Note: This code is not actually used by the scripts.
#It's kept here to show some of the steps required to setup the box before it's packaged.

echo "Upgrading arch version"
sudo pacman -Syu --noconfirm

echo "Install TOR"
sudo pacman -S --noconfirm tor
sudo systemctl start tor
sudo systemctl enable tor

# @see http://stackoverflow.com/questions/11246770/tor-curl-cant-complete-socks5-connection-to-0-0-0-00
echo "Setting up ntp to avoid cURL and TOR issues"
sudo pacman -S --noconfirm ntp
sudo systemctl start ntpd
sudo systemctl enable ntpd

echo "Setting up python and modules"
sudo pacman -S --noconfirm python3 python-pip
sudo pip3 install requests
sudo pip3 install selenium
sudo pip3 install pyvirtualdisplay

echo "Installing chromium"
sudo pacman -S --noconfirm chromium

echo "Installing unzip"
sudo pacman -S --noconfirm unzip

echo "Setting up chromedriver"
wget -O chromedriver.zip http://chromedriver.storage.googleapis.com/2.25/chromedriver_linux64.zip
unzip chromedriver.zip
sudo mv chromedriver /usr/bin
rm -rf chromedriver.zip
sudo pacman -S --noconfirm gconf

echo "Installing Xvfb"
sudo pacman -S --noconfirm xorg-server-xvfb

echo "Giving current user chown to /usr/lib/python3.5"
sudo chown -R "${USER}" /usr/lib/python3.5

echo "Installing pacaur"
gpg --recv-key 1EB2638FF56C0C53
yaourt -S --noconfirm pacaur

echo "Uninstalling yaourt"
sudo pacaur -Rsn --noconfirm yaourt
exit $?
