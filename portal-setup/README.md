# Yazi as System File Picker

This guide explains how to configure Yazi as your system file picker on Linux using `xdg-desktop-portal-termfilechooser`. When configured, applications like Firefox will open Yazi in a terminal window instead of the default GUI file picker.

## What This Does

- Replaces GUI file pickers (like Nautilus/Dolphin) with Yazi
- Works with Firefox, Chrome, and other XDG portal-aware applications
- Opens Yazi in your terminal emulator (default: kitty) for file selection
- System-wide integration - works across all supported applications

## Prerequisites

- **Linux** with Wayland or X11
- **Yazi** installed (`yazi` command available)
- **Terminal emulator** (kitty, foot, alacritty, etc.)
- **Desktop environment**: Sway, i3, Hyprland, or any wlroots-based DE

## Installation

### 1. Install xdg-desktop-portal-termfilechooser

#### Option A: From COPR (Fedora 43+)
```bash
sudo dnf copr enable mo-k12/personal
sudo dnf install xdg-desktop-portal-termfilechooser
```

#### Option B: From Source (Recommended for Fedora 41 and other distros)

**Install build dependencies:**

**Fedora/RHEL:**
```bash
sudo dnf install -y meson ninja-build gcc inih-devel systemd-devel scdoc git
```

**Arch Linux:**
```bash
sudo pacman -S xdg-desktop-portal libinih ninja meson scdoc git
```

**Debian/Ubuntu:**
```bash
sudo apt install xdg-desktop-portal build-essential ninja-build meson libinih-dev libsystemd-dev scdoc git
```

**Build and install:**
```bash
cd /tmp
git clone https://github.com/hunkyburrito/xdg-desktop-portal-termfilechooser
cd xdg-desktop-portal-termfilechooser
meson setup build
ninja -C build
sudo ninja -C build install

# Fedora/Arch: Move portal file to correct location
sudo mv /usr/local/share/xdg-desktop-portal/portals/termfilechooser.portal \
        /usr/share/xdg-desktop-portal/portals/
```

### 2. Configure Portal

**Create configuration directories:**
```bash
mkdir -p ~/.config/xdg-desktop-portal
mkdir -p ~/.config/xdg-desktop-portal-termfilechooser
```

**Copy configuration files from this directory:**
```bash
# Copy the portal preference file (adjust for your DE)
cp sway-portals.conf ~/.config/xdg-desktop-portal/sway-portals.conf

# Copy termfilechooser configuration
cp config ~/.config/xdg-desktop-portal-termfilechooser/

# Copy the yazi wrapper script
cp yazi-wrapper.sh ~/.config/xdg-desktop-portal-termfilechooser/
chmod +x ~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
```

**For other desktop environments**, rename `sway-portals.conf`:
- **Hyprland**: `hyprland-portals.conf`
- **i3**: `i3-portals.conf`
- **Generic/Fallback**: `portals.conf`

### 3. Remove FileChooser from GTK/GNOME Portals

This ensures termfilechooser is used instead of the default GUI picker:

```bash
# Backup first
sudo cp /usr/share/xdg-desktop-portal/portals/gtk.portal \
        /usr/share/xdg-desktop-portal/portals/gtk.portal.backup

# Remove FileChooser from GTK portal
sudo sed -i 's/org\.freedesktop\.impl\.portal\.FileChooser;//g' \
        /usr/share/xdg-desktop-portal/portals/gtk.portal

# If you have GNOME portal installed
sudo sed -i 's/org\.freedesktop\.impl\.portal\.FileChooser;//g' \
        /usr/share/xdg-desktop-portal/portals/gnome.portal
```

### 4. Restart Portal Services

```bash
# Kill all portal processes
killall xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome 2>/dev/null

# Start the main portal service
systemctl --user start xdg-desktop-portal.service

# Start termfilechooser
systemctl --user start xdg-desktop-portal-termfilechooser.service

# Verify it's running
systemctl --user status xdg-desktop-portal-termfilechooser.service
```

### 5. Configure Firefox (Optional but Recommended)

To force Firefox to use XDG portals:

1. Open Firefox
2. Go to `about:config`
3. Search for: `widget.use-xdg-desktop-portal.file-picker`
4. Set to: **1**

## Customization

### Using a Different Terminal

Edit `~/.config/xdg-desktop-portal-termfilechooser/config`:

**For foot:**
```ini
env=TERMCMD=foot --title "File Chooser"
```

**For alacritty:**
```ini
env=TERMCMD=alacritty --title "File Chooser"
```

**For wezterm:**
```ini
env=TERMCMD=wezterm start --
```

### Adjust Starting Directory

In `config`, change:
```ini
default_dir=$HOME/Downloads  # Start in Downloads
```

### Change Open/Save Behavior

- `suggested` - Use the path suggested by the application (recommended)
- `default` - Always start at your default directory
- `last` - Remember the last directory you used

```ini
open_mode=last
save_mode=last
```

## Usage

### Selecting Files

1. Application opens file picker → Kitty window appears with Yazi
2. Navigate to your file
3. Press **Enter** to select the file
4. Kitty closes, file is sent to the application

### Multiple File Selection

1. Press **Space** on files to toggle selection
2. Press **q** (lowercase) to confirm selection

### Directory Selection

1. Navigate **into** the directory you want to select
2. Press **q** (lowercase) to select current directory

### Cancel Selection

- Press **Q** (uppercase) or **Esc** to cancel

## Troubleshooting

### Test if it's working

```bash
# This should open Yazi in kitty if configured correctly
GTK_USE_PORTAL=1 zenity --file-selection
```

### Check service status

```bash
systemctl --user status xdg-desktop-portal-termfilechooser.service
```

### View logs

```bash
journalctl --user -eu xdg-desktop-portal-termfilechooser
```

### Verify portal registration

```bash
busctl --user list | grep termfilechooser
```

Should show:
```
org.freedesktop.impl.portal.desktop.termfilechooser
```

### Common Issues

**1. Still opens Nautilus/GUI picker**
- Verify FileChooser was removed from gtk.portal
- Restart all portal services
- Check that sway-portals.conf exists and has correct name for your DE

**2. "Failed to launch" error**
- Check wrapper script is executable: `chmod +x ~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh`
- Verify yazi is in PATH: `which yazi`
- Check logs: `journalctl --user -eu xdg-desktop-portal-termfilechooser`

**3. Zenity works but Firefox doesn't**
- Make sure Firefox portal setting is enabled (see step 5)
- Try `GTK_USE_PORTAL=1 firefox` to force portal usage
- Restart Firefox completely

## Uninstalling

To revert to the default file picker:

```bash
# Restore GTK portal
sudo mv /usr/share/xdg-desktop-portal/portals/gtk.portal.backup \
        /usr/share/xdg-desktop-portal/portals/gtk.portal

# Remove configuration
rm -rf ~/.config/xdg-desktop-portal-termfilechooser
rm ~/.config/xdg-desktop-portal/sway-portals.conf

# Restart portals
killall xdg-desktop-portal
systemctl --user restart xdg-desktop-portal.service
```

## Credits

- [xdg-desktop-portal-termfilechooser](https://github.com/hunkyburrito/xdg-desktop-portal-termfilechooser) by hunkyburrito
- [Yazi](https://github.com/sxyazi/yazi) file manager

## License

These configuration files are provided as-is for use with your Yazi setup.
