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

When run from GitHub, the installer clones the project into `~/.config/quickshell/wisp-shell`.

The installer supports Fedora, Arch Linux, and Debian-based systems. It installs the required tools:

- Quickshell
- greetd and Niri
- Python 3
- Matugen
- polkit and GLib utilities
- ACL and fontconfig support

It also:

- Installs `/usr/local/bin/wisp-greeter`
- Configures greetd and the Niri greeter session
- Locates `greeter.qml` from the installed project or shared system paths
- Grants the `greeter` user access to the shell source and `~/.config/wisp-shell`
