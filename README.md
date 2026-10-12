# Wisp Shell

Wisp Shell is a Quickshell-based Wayland desktop shell with:

- Wallpaper management and dynamic colors
- Settings for appearance and Niri
- A lockscreen and polkit authentication UI
- A greetd login greeter

## Installation

Run the installer as your normal user. It uses `sudo` for system changes:

```bash
curl -fsSL https://raw.githubusercontent.com/physteorts/wisp-shell/main/scripts/install.sh | bash
```

The installer clones the project from git into `~/.config/quickshell/wisp-shell`.

The installer supports Fedora. It installs the required tools:

- Quickshell
- Ghostty
- greetd and Niri
- Python 3 and nautilus-python
- Matugen
- wl-mirror
- polkit and GLib utilities
- ACL and fontconfig support
- Google Material Symbols Rounded and Inter fonts

It also:

- Installs `/usr/local/bin/wisp-greeter`
- Configures greetd and the Niri greeter session
- Locates `greeter.qml` from the installed project or shared system paths
- Configures Niri compositor integration via `wisp-shell.kdl` (`include "wisp-shell.kdl"`)
- Links dynamic Ghostty Matugen theme configuration
- Grants the `greeter` user access to the shell source and `~/.config/wisp-shell`
