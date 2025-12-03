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
  pkg update -y
  pkg upgrade -y
  pkg autoclean
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
if [ -x "$(command -v uv)" ]; then
  if [ $UID == "0" ]; then
    read -p "You are updating UV tools as root, do you want to proceed?"
    uv self update
    uv tool upgrade --all
  else
    uv self update
    uv tool upgrade --all
  fi
else
  echo "NO UV"
fi ; }

# Install base packages first (needed for the rest of the script)
if [ -x /bin/xbps-install ]; then
    # Void Linux
    i curl git stow vim python3-devel
elif [ -x /data/data/com.termux/files/usr/bin/pkg ]; then
    # Termux - python includes dev files, stow available via pkg
    pkg install curl git stow vim python
else
    # Debian/Ubuntu/RHEL
    i curl git stow vim python3-dev
fi

# Ensure ~/.local/bin is in PATH (where UV and other tools live)
export PATH="$HOME/.local/bin:$PATH"

# Install UV if not already installed
if ! command -v uv &> /dev/null; then
  echo "Installing UV..."
  if [ -x /data/data/com.termux/files/usr/bin/pkg ]; then
    # Termux - curl installer doesn't support this arch
    pkg install uv
  else
    # Debian/Ubuntu/RHEL - use the official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
fi

# Create folders
mkdir -p ~/projects/stow

# Create a general-purpose venv
if [ ! -d ~/projects/venv ]; then
  echo "Creating venv at ~/projects/venv..."
  uv venv ~/projects/venv
fi

# Get dotfiles repo (skip if already exists)
if [ ! -d ~/projects/stow/.git ]; then
  git clone https://github.com/wastemans/dotfiles ~/projects/stow
fi

# Setup dotfiles using GNU Stow (like ssync but without push)
cd ~/projects/stow || exit 1

# Pull latest changes
git pull --no-rebase || {
  echo "Pull failed - you may need to resolve conflicts manually"
}

# Stow the main dotfiles package
stow --ignore='^\.config$' -R -d . -t ~ git_dotfiles_home

# Create symlinks for config directories
for pkg_dir in git_dotfiles_home_configdir/*/; do
  [ ! -d "$pkg_dir" ] && continue
  pkg_name=$(basename "$pkg_dir")
  target="$PWD/git_dotfiles_home_configdir/$pkg_name"
  link_path=~/.config/"$pkg_name"
  [ -e "$link_path" ] && rm -rf "$link_path"
  ln -s "$target" "$link_path"
done

# Source bashrc if it exists
if [ -f ~/.bashrc ]; then
  # shellcheck source=/dev/null
  source ~/.bashrc
fi

# Re-ensure ~/.local/bin is in PATH after sourcing bashrc
export PATH="$HOME/.local/bin:$PATH"

# Install Python tools using UV
if [ -f ~/.config/uv/tools.txt ]; then
  echo "Installing UV tools from tools.txt..."
  while IFS= read -r tool; do
    [ -n "$tool" ] && uv tool install "$tool"
  done < ~/.config/uv/tools.txt
fi

# Run updates/upgrades at the end
udug
