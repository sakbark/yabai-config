# Yabai + SKHD Configuration

Complete macOS window management setup using [yabai](https://github.com/koekeishiya/yabai) and [skhd](https://github.com/koekeishiya/skhd).

## Features

- **BSP (Binary Space Partitioning) Layout** - Automatic window tiling
- **Multi-Monitor Support** - Smart display detection and handling
- **App Space Assignments** - Automatic workspace organization
- **Auto Focus on Window Creation** - Seamlessly switches to new windows when apps open
- **Auto Focus on App Activation** - Automatically switches to already-running apps' spaces
- **Smart Scratchpad System** - Quick-access floating windows
- **Keyboard-Driven Workflow** - Comprehensive keybindings for window management

**📋 [View Testing & Debugging Report](TESTING.md)** - Comprehensive test results and validation

## Quick Start

### Prerequisites

```bash
# Install yabai and skhd
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd

# Install jq (required for scripts)
brew install jq
```

### Installation

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url>
   cd yabai-config
   ```

2. **Install configuration files:**
   ```bash
   # Create config directory if it doesn't exist
   mkdir -p ~/.config/yabai

   # Copy yabai configuration
   cp yabairc ~/.config/yabai/
   chmod +x ~/.config/yabai/yabairc

   # Copy helper scripts
   cp on-window-created.sh ~/.config/yabai/
   cp on-app-activated.sh ~/.config/yabai/
   cp handle-display-change.sh ~/.config/yabai/
   cp clear_indicators.sh ~/.config/yabai/
   cp fix_offscreen_windows.sh ~/.config/yabai/
   chmod +x ~/.config/yabai/*.sh

   # Copy skhd configuration
   cp skhdrc ~/.skhdrc
   ```

3. **Configure scripting addition (optional but recommended):**
   ```bash
   # Add sudoers entry for yabai
   echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
   ```

4. **Start services:**
   ```bash
   yabai --start-service
   skhd --start-service
   ```

## Configuration Overview

### Yabai (`yabairc`)

**Layout Settings:**
- BSP layout with 50/50 split ratio
- 6px window gaps and padding
- Auto-balance disabled (manual control)
- Smart mouse focus behavior (autofocus mode)

**Space Assignments:**
- Space 1: Productivity (Conduit, Helpdesk, Todoist, Spark)
- Space 2: Communication (Google Chat, Messages, Messenger, WhatsApp)
- Space 3: Browser (Google Chrome)
- Space 4: Development (Reclaim, Warp, Home Assistant, Loopback)

**Display Assignments:**
- Multi-monitor aware with automatic display detection
- ChatMate → Third display (MacBook)
- Fantastical → Secondary display

**Floating Apps:**
- ChatGPT (sticky, centered grid)
- Bitwarden, Google Meet, System Settings
- iPhone Mirroring, FaceTime, Calculator

### SKHD (`skhdrc`)

**Key Features:**
- Hyper key (cmd + shift + alt + ctrl) for window operations
- Simple modifier keys for common actions
- Comprehensive window movement and resizing
- Space switching and window relocation
- Scratchpad toggles

**Common Keybindings:**
- `alt - h/j/k/l` - Focus window (vim-style)
- `hyper - h/j/k/l` - Swap windows
- `shift + alt - h/j/k/l` - Move windows between spaces
- `alt - 1/2/3/4` - Switch to space
- `alt - f` - Toggle float/tile
- `alt - e` - Balance space layout

## Helper Scripts

### `on-window-created.sh`
Automatically switches to the space where a new window is created and focuses it. This makes app space assignments seamless - when you open a new window for an app, it opens on its assigned space and automatically switches you there.

**Triggers on:** New window creation (e.g., launching an app for the first time, creating a new window)

### `on-app-activated.sh`
Automatically switches to the space where an already-running app is located when you activate it. This makes it seamless to switch between apps - just click an app in the Dock or use Spotlight, and yabai automatically takes you to the space where that app lives.

**Triggers on:** App activation (e.g., clicking app in Dock, using Spotlight/Alfred, Cmd+Tab)

**Example:** If Chrome is running on Space 3 and you're on Space 1, clicking Chrome in the Dock will automatically switch you to Space 3.

### `handle-display-change.sh`
Gracefully handles display connection/disconnection events, preventing yabai from hanging during monitor changes. **Automatically runs `fix_offscreen_windows.sh`** after display changes to fix any windows that went offscreen.

### `fix_offscreen_windows.sh`
Detects and fixes windows with negative coordinates or positioned beyond display boundaries. Handles both tiled and floating windows.

**Runs automatically when:**
- Display connected/disconnected
- Monitor configuration changes

**Manual trigger:**
- Keyboard: `alt + shift + f`
- Command: `~/.config/yabai/fix_offscreen_windows.sh`

**Common when:**
- Disconnecting external monitors
- Menubar popover apps on secondary displays
- Resolution changes

### `clear_indicators.sh`
Clears yabai's window indicators (useful for debugging).

## Usage Tips

### Scratchpads

Scratchpads are quick-access floating windows that follow you across all spaces:

- `alt - return` - Terminal scratchpad
- `alt - n` - Notes app
- `alt - c` - Calculator
- Scratchpads are sticky and float above tiled windows

### Window Management Workflow

1. **Create new windows** - They auto-tile in BSP layout
2. **Rotate layout** - `alt - r` rotates the BSP tree
3. **Balance layout** - `alt - e` equalizes all window sizes
4. **Move windows** - Use `hyper + h/j/k/l` to swap positions
5. **Resize** - Use mouse with `fn` key or window borders

### Multi-Monitor Setup

The configuration automatically detects displays and applies labels:
- Display 1: "Main"
- Display 2: "Secondary"
- Display 3: "Third"

Move windows between displays with `shift + alt - 1/2/3`.

## Customization

### Adding App Assignments

Edit `yabairc` and add rules:

```bash
yabai -m rule --add app="^YourApp$" space=X
```

Replace `X` with your target space number (1-4).

### Adding Display Assignments

```bash
yabai -m rule --add app="^YourApp$" display=X
```

### Creating New Scratchpads

Edit `skhdrc` and add a toggle binding:

```bash
alt - x : yabai -m window --toggle yourapp || open -a "Your App"
```

Then add a scratchpad rule in `yabairc`:

```bash
yabai -m rule --add app="^Your App$" manage=off sticky=on scratchpad=yourapp
```

## Debugging & Validation

### Comprehensive Debug Script

Run the comprehensive debug script to validate all yabai automation:

```bash
~/.config/yabai/debug-all-scripts.sh
```

**What it checks:**
- ✅ All dependencies installed (yabai, skhd, jq)
- ✅ All scripts have correct permissions
- ✅ All signals properly registered
- ✅ Functional tests (queries, offscreen detection)
- ✅ Performance metrics
- ✅ Log file analysis
- ✅ Edge case validation

**Output:**
- Real-time console output with color-coded results
- Full report saved to `/tmp/yabai-debug-report-*.log`

**When to run:**
- After initial setup
- After making configuration changes
- When troubleshooting issues
- Monthly validation check

**📋 See [DEBUG-REPORT.md](DEBUG-REPORT.md) for full validation results**

---

## Troubleshooting

### Services Not Starting

```bash
# Check service status
yabai --check-sa
skhd --check

# View logs
tail -f /tmp/yabai_*.out
tail -f /tmp/skhd_*.out

# Restart services
yabai --restart-service
skhd --restart-service
```

### Windows Not Tiling

```bash
# Check if window is managed
yabai -m query --windows | jq '.[] | select(.focused == 1)'

# Force manage window
yabai -m window --toggle float
yabai -m window --toggle float
```

### Keybindings Not Working

```bash
# Test skhd is running
pgrep -x skhd

# Check for conflicts with macOS shortcuts
# System Settings > Keyboard > Keyboard Shortcuts
```

## Resources

- [Yabai Wiki](https://github.com/koekeishiya/yabai/wiki)
- [SKHD Documentation](https://github.com/koekeishiya/skhd)
- [My Stream Deck Profile](yabai-stream-deck-xl-complete.streamDeckProfile) *(if available)*

## License

MIT

## Credits

Configuration by [@saady](https://github.com/sakbark)
