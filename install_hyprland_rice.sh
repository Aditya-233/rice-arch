#!/bin/bash

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


print_info "Starting Hyprland Rice Installation"
echo ""

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
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xorg-xwayland \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland
print_success "Hyprland and Wayland core installed"
echo ""

print_info "Installing SDDM display manager..."
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm.service
print_success "SDDM installed and enabled"

echo ""

# Install terminal emulators
print_info "Installing terminal emulator (kitty)..."
sudo pacman -S --needed --noconfirm kitty
print_success "Terminal emulator installed"
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
sudo systemctl start NetworkManager.service || true
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service || true
print_success "Services enabled"
echo ""

# Install Hyprland ecosystem packages (all packages from your configs)
print_info "Installing Hyprland ecosystem packages..."
sudo pacman -S --needed --noconfirm \
    waybar \
    rofi-wayland \
    brightnessctl \
    playerctl \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    rfkill
print_success "Hyprland ecosystem packages installed"
echo ""

# Install fonts
print_info "Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    ttf-font-awesome
print_success "Fonts installed"
echo ""

# Install additional utilities
print_info "Installing additional utilities..."
sudo pacman -S --needed --noconfirm \
    btop \
    fastfetch \
    unzip \
    zip \
    ffmpeg \
    mpv \
    imv \
    okular
print_success "Additional utilities installed"
echo ""

# Install AUR packages specific to your config
print_info "Installing AUR packages (swww, grimblast, swaync, matugen)..."
yay -S --noconfirm --answerclean All --answerdiff None \
    swww \
    grimblast-git \
    swaync \
    matugen-bin \
    wlogout

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

configs_to_backup=("hypr" "waybar" "rofi" "swaync" "kitty")
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

# Copy configuration files based on repository structure
if [ -d ".config/hypr" ]; then
    print_info "Copying Hyprland configs..."
    cp -r .config/hypr "$HOME/.config/"
elif [ -d "hypr" ]; then
    cp -r hypr "$HOME/.config/"
fi

# Copy other configs if they exist
for config_dir in waybar rofi swaync kitty; do
    if [ -d ".config/$config_dir" ]; then
        cp -r ".config/$config_dir" "$HOME/.config/"
        print_info "Copied $config_dir config"
    elif [ -d "$config_dir" ]; then
        cp -r "$config_dir" "$HOME/.config/"
        print_info "Copied $config_dir config"
    fi
done

print_success "Configuration files installed"
echo ""

# Create required directory structure
print_info "Creating required directories..."
mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.config/hypr/configs"
mkdir -p "$HOME/.config/waybar/configs"
mkdir -p "$HOME/.config/waybar/style"
mkdir -p "$HOME/.config/swaync/icons"
mkdir -p "$HOME/.config/swaync/images"
mkdir -p "$HOME/.config/rofi"
mkdir -p "$HOME/.local/bin"
print_success "Directories created"
echo ""

# Copy wallpapers if they exist in the repo
if [ -d "$REPO_DIR/wallpapers" ]; then
    print_info "Copying wallpapers..."
    cp -r "$REPO_DIR/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    print_success "Wallpapers copied"
elif [ -d "$REPO_DIR/Wallpapers" ]; then
    print_info "Copying wallpapers..."
    cp -r "$REPO_DIR/Wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    print_success "Wallpapers copied"
else
    print_warning "No wallpapers found in repository"
    print_info "You can add wallpapers to ~/Pictures/wallpapers/ manually"
fi
echo ""

# Download a default wallpaper if none exist
if [ -z "$(ls -A $HOME/Pictures/wallpapers 2>/dev/null)" ]; then
    print_info "Downloading a default wallpaper..."
    wget -q -O "$HOME/Pictures/wallpapers/default.jpg" \
        "https://w.wallhaven.cc/full/pk/wallhaven-pkz35y.jpg" 2>/dev/null || \
        print_warning "Failed to download wallpaper, please add one manually"
fi
echo ""

# Final instructions
print_success "============================================"
print_success "Installation complete!"
print_success "============================================"
echo ""
print_info "Next steps:"
echo "  1. Reboot your system: sudo reboot"
echo "  2. If you installed SDDM, select Hyprland from the session menu"
echo "  3. If no display manager, login and run: Hyprland"
echo ""
print_info "Key bindings (from your config):"
echo "  • SUPER + RETURN      - Open terminal (kitty)"
echo "  • SUPER + SPACE       - Application launcher (rofi)"
echo "  • SUPER + Q           - Close window"
echo "  • SUPER + L           - Lock screen"
echo "  • SUPER + E           - File manager"
echo "  • SUPER + ESCAPE      - Power menu"
echo "  • SUPER + SHIFT + S   - Screenshot (area)"
echo "  • SUPER + 1-9         - Switch workspaces"
echo "  • SUPER + CTRL + SPACE - Wallpaper picker"
echo ""
print_info "Configuration backed up to: $BACKUP_DIR"
print_info "Main config location: ~/.config/hypr/"
echo ""
print_warning "Note: Some applications may need additional configuration"
print_warning "Check ~/.config/hypr/, ~/.config/waybar/, etc. for customization"
echo ""
