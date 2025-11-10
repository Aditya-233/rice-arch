#!/bin/bash

# Hyprland Rice Installation Script for binnewbs/arch-hyprland
# This script automates the installation on a fresh Arch Linux system

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

print_info "Starting Hyprland Rice Installation for binnewbs/arch-hyprland"
echo ""

# Prompt user to continue
read -p "This script will install Hyprland and related packages. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 0
fi

# Update system
print_info "Updating system..."
sudo pacman -Syu --noconfirm
print_success "System updated"
echo ""

# Install essential tools
print_info "Installing base development tools..."
sudo pacman -S --needed --noconfirm git base-devel
print_success "Base tools installed"
echo ""

# Install Hyprland and core dependencies
print_info "Installing Hyprland and core dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    kitty \
    sddm
print_success "Hyprland and core dependencies installed"
echo ""

# Enable SDDM
print_info "Enabling SDDM display manager..."
sudo systemctl enable sddm.service
print_success "SDDM enabled"
echo ""

# Install yay (AUR helper)
print_info "Installing yay AUR helper..."
if command -v yay &> /dev/null; then
    print_warning "yay is already installed, skipping..."
else
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    print_success "yay installed"
fi
echo ""

# Install additional packages from official repos
print_info "Installing additional packages from official repos..."
sudo pacman -S --needed --noconfirm \
    waybar \
    wofi \
    dunst \
    pipewire \
    pipewire-pulse \
    wireplumber \
    brightnessctl \
    pamixer \
    playerctl \
    grim \
    slurp \
    wl-clipboard
print_success "Additional packages installed"
echo ""

# Install AUR packages
print_info "Installing AUR packages (swww, matugen)..."
yay -S --needed --noconfirm swww matugen-bin
print_success "AUR packages installed"
echo ""

# Clone the dotfiles repository
print_info "Cloning binnewbs/arch-hyprland repository..."
REPO_DIR="$HOME/arch-hyprland"
if [ -d "$REPO_DIR" ]; then
    print_warning "Repository already exists at $REPO_DIR"
    read -p "Remove and re-clone? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
        git clone https://github.com/binnewbs/arch-hyprland.git "$REPO_DIR"
        print_success "Repository cloned"
    else
        print_info "Using existing repository"
    fi
else
    git clone https://github.com/binnewbs/arch-hyprland.git "$REPO_DIR"
    print_success "Repository cloned"
fi
echo ""

# Backup existing configs
print_info "Backing up existing configurations..."
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

configs_to_backup=("hypr" "waybar" "wofi" "dunst" "kitty")
for config in "${configs_to_backup[@]}"; do
    if [ -d "$HOME/.config/$config" ]; then
        cp -r "$HOME/.config/$config" "$BACKUP_DIR/"
        print_info "Backed up $config to $BACKUP_DIR"
    fi
done
print_success "Configurations backed up to $BACKUP_DIR"
echo ""

# Install the dotfiles
print_info "Installing dotfiles..."
cd "$REPO_DIR"

# Check if .config directory exists in the repo
if [ -d ".config" ]; then
    print_info "Copying configuration files..."
    mkdir -p "$HOME/.config"
    cp -r .config/* "$HOME/.config/"
    print_success "Configuration files copied"
elif [ -d "config" ]; then
    print_info "Copying configuration files from 'config' directory..."
    mkdir -p "$HOME/.config"
    cp -r config/* "$HOME/.config/"
    print_success "Configuration files copied"
else
    print_warning "No .config or config directory found in repository"
    print_info "Please manually copy the configuration files"
fi
echo ""

# Make scripts executable
print_info "Making scripts executable..."
find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
print_success "Scripts made executable"
echo ""

# Additional setup
print_info "Performing additional setup..."

# Create common directories
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/.local/bin"

print_success "Additional setup complete"
echo ""

# Final message
print_success "Installation complete!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Reboot your system: ${YELLOW}sudo reboot${NC}"
echo -e "  2. At login, select 'Hyprland' from the session menu"
echo -e "  3. Place wallpapers in ${YELLOW}~/Pictures/Wallpapers${NC}"
echo -e "  4. Review configs in ${YELLOW}~/.config/hypr${NC}"
echo -e "  5. Check logs if issues occur: ${YELLOW}/tmp/hypr/*/hyprland.log${NC}"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo -e "  - This rice uses Matugen for color schemes"
echo -e "  - Wallpaper backend is swww"
echo -e "  - Some scripts may need tweaking for your system"
echo -e "  - Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
