# Dotfiles Setup Script

This script automates the setup of dotfiles on a fresh system using modern tools.

## Features

- **Package Management**: Universal installer functions for xbps (Void Linux), apt (Debian/Ubuntu), yum (RHEL/Fedora), and pkg (Termux)
- **System Updates**: `udug` function to update system packages, Flatpak apps, and utilities
- **UV Package Manager**: Uses [UV](https://github.com/astral-sh/uv) instead of pip for Python package management
- **GNU Stow**: Uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink-based dotfile management

## Prerequisites

- Bash
- Internet connection

## Quick Start

Run this one-liner on a fresh system (no git required):

```bash
curl -fsSL https://raw.githubusercontent.com/wastemans/dfsetup/main/setup.sh | bash
```

## Alternative Usage

Download and inspect first:

```bash
curl -O https://raw.githubusercontent.com/wastemans/dfsetup/main/setup.sh
chmod +x setup.sh
./setup.sh
```

Or clone the repository:

```bash
git clone https://github.com/wastemans/dfsetup
cd dfsetup
./setup.sh
```

## What it does

1. **Installs required packages**:
   - curl, git, stow, vim
   - Python 3 development files

2. **Installs UV**:
   - Downloads and installs UV if not already present

3. **Sets up dotfiles**:
   - Clones your dotfiles repository to `~/projects/dotfiles`
   - Uses GNU Stow to symlink all dotfile packages to your home directory
   - Sources `~/.bashrc` if it exists

4. **Installs Python tools**:
   - Reads from `~/.config/uv/tools.txt` (if present)
   - Installs each tool using `uv tool install`

5. **Updates the system** (runs last):
   - Flatpak apps
   - System packages (xbps/apt/yum)
   - xlocate database (if available)
   - tldr cache (if available)
   - UV tools

## Dotfiles Repository Structure

Your dotfiles repository should be structured with each application's config in its own directory:

```
dotfiles/
├── bash/
│   └── .bashrc
├── vim/
│   └── .vimrc
├── git/
│   └── .gitconfig
└── ...
```

When you run `stow bash`, it will create symlinks in your home directory:
- `~/.bashrc` → `~/projects/dotfiles/bash/.bashrc`

## UV Tools Configuration

Create a file at `~/.config/uv/tools.txt` with one tool per line:

```
pip-review
pipdeptree
ruff
```

The script will install these tools using UV's isolated tool environments.

## Helper Functions

### `i` - Install packages
```bash
i package1 package2 package3
```

### `r` - Remove packages
```bash
r package1 package2
```

### `udug` - Update, Upgrade, and Garbage collect
```bash
udug
```
Updates all system packages, Flatpak apps, and utilities.

## Migration from pip to UV

UV is a modern, fast Python package manager written in Rust. Key differences:

- **Virtual environments**: `uv venv` instead of `python -m venv`
- **Package installation**: `uv pip install` instead of `pip install`
- **Tool installation**: `uv tool install` for command-line tools (isolated from project dependencies)
- **Self-updating**: `uv self update` keeps UV up to date

## Migration from dotfiles to Stow

GNU Stow is a symlink farm manager that eliminates the need for custom dotfile management scripts:

- **No Python dependency**: Stow is a standard Unix tool
- **Transparent symlinks**: Your actual configs stay in the repo, symlinks point to them
- **Easy package management**: Add/remove dotfile packages individually
- **Selective deployment**: Choose which configs to deploy on each machine

### Stow commands:
```bash
# Install/link a package
stow -t ~ -S bash

# Uninstall/unlink a package
stow -t ~ -D bash

# Reinstall a package (useful after updates)
stow -t ~ -R bash
```

## Compatibility

Tested on:
- Void Linux (xbps)
- Debian/Ubuntu (apt)
- RHEL/Fedora (yum)
- Termux (pkg)

## Notes

- The script avoids running Flatpak and UV tools as root for safety
- Old kernel versions are automatically cleaned up on Void Linux using `vkpurge`
- The script preserves the original installer/updater functions for flexibility

