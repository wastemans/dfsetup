#! /usr/bin/env bash

function i () {
if [ -x /bin/xbps-install ]; then
  if [ $UID == "0" ]; then
    xbps-install -S "$@"
  else
    sudo xbps-install -S "$@"
  fi
elif [ -x /data/data/com.termux/files/usr/bin/pkg ]; then
    pkg install "$@"
elif [ -x /bin/apt ]; then
  if [ $UID == "0" ]; then
    apt install "$@"
  else
    sudo apt install "$@"
  fi
elif [ -x /bin/yum ]; then
  if [ $UID == "0" ]; then
    yum install "$@"
  else
    sudo yum install "$@"
  fi
else
  echo "NO YUM/APT/XBPS"
fi ; }

function r () {
if [ -x /bin/xbps-remove ]; then
  if [ $UID == "0" ]; then
    xbps-remove -oO "$@"
    xbps-remove -oO
  else
    sudo xbps-remove -oO "$@"
    sudo xbps-remove -oO
  fi
elif [ -x /data/data/com.termux/files/usr/bin/pkg ]; then
  pkg uninstall "$@"
  pkg remove --autoremove
elif [ -x /bin/apt ]; then
  if [ $UID == "0" ]; then
    apt remove --purge "$@"
    apt autoremove --purge
  else
    sudo apt remove --purge "$@"
    sudo apt autoremove --purge
  fi
elif [ -x /bin/yum ]; then
  if [ $UID == "0" ]; then
    yum remove "$@"
    yum autoremove
  else
    sudo yum remove "$@"
    sudo yum autoremove
  fi
else
  echo "NO YUM/APT/XBPS"
fi ; }

function udug () {
echo -e "\n\n\nFLATPAK\n"
if [ -x /bin/flatpak ]; then
  if [ $UID == "0" ]; then
    echo "Do not run flatpak as root."
  else
    flatpak --user update -y
    flatpak --user uninstall --delete-data --unused -y
  fi
else
  echo "FLATPAK MISSING"
fi

echo -e "\n\n\nPACKAGES\n"
if [ -x /bin/xbps-install ]; then
  if [ $UID == "0" ]; then
    xbps-install -uy xbps
    xbps-install -Suy
    xbps-remove -Ooy
    vkpurge rm all
  else
    sudo xbps-install -uy xbps
    sudo xbps-install -Suy
    sudo xbps-remove -Ooy
    sudo vkpurge rm all
  fi
elif [ -x /data/data/com.termux/files/usr/bin/pkg ]; then
  pkg update
  pkg upgrade
  pkg uninstall "$@"
  pkg remove --autoremove
elif [ -x /bin/apt ]; then
  if [ $UID == "0" ]; then
    apt update
    apt upgrade -y
    apt autoremove --purge -y
  else
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove --purge -y
  fi
elif [ -x /bin/yum ]; then
  if [ $UID == "0" ]; then
    yum upgrade -y
    yum autoremove -y
  else
    sudo yum upgrade -y
    sudo yum autoremove -y
  fi
else
  echo "NO YUM/APT/XBPS"
fi

echo -e "\n\n\nUTILITIES\n"
if [ -x "$(command -v xlocate)" ]; then
  if [ $UID == "0" ]; then
    read -p "You are xlocate as root, do you want to proceed?"
    xlocate -S
  else
    xlocate -S
  fi
else
  echo "NO XLOCATE"
fi
if [ -x "$(command -v tldr)" ]; then
  if [ $UID == "0" ]; then
    read -p "You are tldr as root, do you want to proceed?"
    tldr -u
  else
    tldr -u
  fi
else
  echo "NO TLDR"
fi
if [ -x "$(command -v pip-review)" ]; then
  if [ $UID == "0" ]; then
    read -p "You are pip as root, do you want to proceed?"
    python -m pip install --upgrade pip
    pip-review -a
    pip-chill --no-version |tee /tmp/requirements.txt
  else
    python -m pip install --upgrade pip
    pip-review -a
    echo -e "\nCurrent packages:"
    #pip-chill --no-version |tee /tmp/requirements.txt
    pipdeptree -fl
  fi
else
  echo "NO PIP-REVIEW"
fi ; }

udug
if [ -x /bin/xbps-install ]; then
    i python3-devel python3-pip python3-virtualenv git
else
i python3-dev python3-pip python3-virtualenv git
fi
#Create folders
mkdir -p ~/projects/{dotfiles,vpy}
#Create & activate venv
python3 -m venv ~/projects/vpy
source ~/projects/vpy/bin/activate
# Get dotfiles
pip install dotfiles
# Fix line 150
vim ~/projects/vpy/lib/python3.12/site-packages/dotfiles/cli.py
#Get repo
git clone https://wastemans@github.com/wastemans/dotfiles ~/projects/dotfiles
#Setup dotfiles
cp ~/projects/dotfiles/dfrc ~/.dotfilesrc
dotfiles --sync --force
source ~/.bashrc
pip install -r ~/.pip-master