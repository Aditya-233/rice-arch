#!/bin/bash

# Hyprland Rice Installation Script for Aditya-233/rice-arch-hyprland
# This script automates the installation on a fresh Arch Linux system (archinstall minimal)

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

print_info "Starting Hyprland Rice Installation for Aditya-233/rice-arch-hyprland"

# Update system first
print_info "Updating system..."
sudo pacman -Syu --noconfirm
print_success "System updated"
echo ""

# Install essential build tools and git
print_info "Installing base development tools and git..."
sudo pacman -S --needed --noconfirm git base-devel wget curl
print_success "Base tools installed"
echo ""

# Install yay (AUR helper) - needed for AUR packages
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

# Install Hyprland and core Wayland dependencies
print_info "Installing Hyprland and core Wayland dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xorg-xwayland \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland
print_success "Hyprland and Wayland core installed"
echo ""

# Install display manager
print_info "Installing SDDM display manager..."
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm.service
print_success "SDDM installed and enabled"
echo ""

# Install terminal emulators
print_info "Installing terminal emulators..."
sudo pacman -S --needed --noconfirm kitty foot alacritty
print_success "Terminal emulators installed"
echo ""

# Install audio system (PipeWire)
print_info "Installing audio system (PipeWire)..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pamixer \
    pavucontrol
print_success "Audio system installed"
echo ""

# Install essential GUI applications and utilities
print_info "Installing essential applications..."
sudo pacman -S --needed --noconfirm \
    firefox \
    thunar \
    thunar-archive-plugin \
    file-roller \
    networkmanager \
    network-manager-applet \
    bluez \
    bluez-utils \
    blueman
print_success "Essential applications installed"
echo ""

# Enable NetworkManager and Bluetooth
print_info "Enabling NetworkManager and Bluetooth..."
sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service
print_success "Services enabled"
echo ""

# Install Hyprland ecosystem packages
print_info "Installing Hyprland ecosystem packages..."
sudo pacman -S --needed --noconfirm \
    waybar \
    wofi \
    rofi-wayland \
    dunst \
    hyprpaper \
    swaybg \
    brightnessctl \
    playerctl \
    grim \
    slurp \
    swappy \
    wl-clipboard \
    cliphist
print_success "Hyprland ecosystem packages installed"
echo ""

# Install fonts
print_info "Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-fira-code \
    noto-fonts \
    noto-fonts-emoji \
    ttf-font-awesome
print_success "Fonts installed"
echo ""

# Install additional utilities
print_info "Installing additional utilities..."
sudo pacman -S --needed --noconfirm \
    btop \
    neofetch \
    fastfetch \
    unzip \
    zip \
    jq \
    imagemagick \
    ffmpeg \
    mpv \
    imv
print_success "Additional utilities installed"
echo ""

# Install AUR packages
print_info "Installing AUR packages (swww, grimblast, hyprpicker)..."
yay -S --needed --noconfirm \
    swww \
    grimblast-git \
    hyprpicker
print_success "AUR packages installed"
echo ""

# Clone the dotfiles repository
print_info "Cloning Aditya-233/rice-arch-hyprland repository..."
REPO_DIR="$HOME/rice-arch-hyprland"
if [ -d "$REPO_DIR" ]; then
    print_warning "Repository already exists at $REPO_DIR"
    read -p "Remove and re-clone? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
        git clone https://github.com/Aditya-233/rice-arch-hyprland.git "$REPO_DIR"
        print_success "Repository cloned"
    else
        print_info "Using existing repository"
    fi
else
    git clone https://github.com/Aditya-233/rice-arch-hyprland.git "$REPO_DIR"
    print_success "Repository cloned"
fi
echo ""

# Backup existing configs
print_info "Backing up existing configurations..."
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

configs_to_backup=("hypr" "waybar" "wofi" "rofi" "dunst" "kitty" "foot" "alacritty")
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

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Check for different possible directory structures
if [ -d ".config" ]; then
    print_info "Copying from .config directory..."
    cp -r .config/* "$HOME/.config/"
elif [ -d "config" ]; then
    print_info "Copying from config directory..."
    cp -r config/* "$HOME/.config/"
elif [ -f "install.sh" ]; then
    print_warning "Repository has its own install.sh script"
    read -p "Run the repository's install script? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x install.sh
        ./install.sh
    fi
else
    print_info "Copying all configuration folders to ~/.config/..."
    for dir in */; do
        if [ "$dir" != ".git/" ] && [ "$dir" != ".github/" ]; then
            cp -r "$dir" "$HOME/.config/"
        fi
    done
fi
print_success "Configuration files installed"
echo ""

# Make scripts executable
print_info "Making scripts executable..."
find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$HOME/.config" -type f -path "*/scripts/*" -exec chmod +x {} \; 2>/dev/null || true
print_success "Scripts made executable"
echo ""

# Create common directories
print_info "Creating common directories..."
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share"
print_success "Directories created"
echo ""

# Copy wallpapers if they exist in the repo
if [ -d "$REPO_DIR/wallpapers" ]; then
    print_info "Copying wallpapers..."
    cp -r "$REPO_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
    print_success "Wallpapers copied"
elif [ -d "$REPO_DIR/Wallpapers" ]; then
    print_info "Copying wallpapers..."
    cp -r "$REPO_DIR/Wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
    print_success "Wallpapers copied"
fi
echo ""

# Final message
print_success "Installation complete!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Reboot your system: ${YELLOW}sudo reboot${NC}"
echo -e "  2. At SDDM login, select 'Hyprland' from the session menu"
echo -e "  3. Add wallpapers to ${YELLOW}~/Pictures/Wallpapers${NC}"
echo -e "  4. Review and customize configs in ${YELLOW}~/.config/hypr${NC}"
echo -e "  5. Check Hyprland keybindings in ${YELLOW}~/.config/hypr/hyprland.conf${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "  - Fresh archinstall detected - all dependencies installed"
echo -e "  - Audio: PipeWire (use ${YELLOW}pavucontrol${NC} for settings)"
echo -e "  - Network: NetworkManager (use ${YELLOW}nmtui${NC} or system tray)"
echo -e "  - Bluetooth: blueman applet available in system tray"
echo -e "  - Screenshots saved to ${YELLOW}~/Pictures/Screenshots${NC}"
echo -e "  - Logs: ${YELLOW}/tmp/hypr/*/hyprland.log${NC}"
echo -e "  - Backups: ${YELLOW}$BACKUP_DIR${NC}"
echo ""
echo -e "${BLUE}Common Keybindings (check config for full list):${NC}"
echo -e "  - Super + Q: Close window"
echo -e "  - Super + Return: Terminal"
echo -e "  - Super + D: App launcher"
echo -e "  - Super + E: File manager"
echo -e "  - Super + Shift + Q: Exit Hyprland"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
