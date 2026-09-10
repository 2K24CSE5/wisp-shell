#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
    readonly SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
else
    readonly SCRIPT_DIR=""
fi
readonly CONFIG_DIR="$HOME/.config/wisp-shell"
readonly GREETER_USER="greeter"
readonly REPOSITORY_URL="https://github.com/physteorts/wisp-shell.git"
if [[ -n "$SCRIPT_DIR" ]]; then
    PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
else
    PROJECT_DIR="$HOME/.config/quickshell/wisp-shell"
fi

log() {
    printf '[wisp-shell] %s\n' "$*"
}

fail() {
    printf '[wisp-shell] error: %s\n' "$*" >&2
    exit 1
}

need_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command is missing: $1"
}

run_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_packages() {
    local package_manager=""
    local -a packages=()

    if command -v dnf >/dev/null 2>&1; then
        package_manager=dnf
        packages=(git findutils gawk quickshell greetd niri python3 acl polkit glib2 fontconfig)
    elif command -v pacman >/dev/null 2>&1; then
        package_manager=pacman
        packages=(git findutils gawk quickshell greetd niri python python-pip acl polkit glib2 fontconfig)
    elif command -v apt-get >/dev/null 2>&1; then
        package_manager=apt-get
        packages=(git findutils gawk python3 acl policykit-1 libglib2.0-bin fontconfig)
        log "Quickshell, greetd, Niri, and Matugen may require third-party repositories on Debian-based systems."
    else
        fail "Unsupported distribution: install Quickshell, greetd, Niri, Python 3, acl, polkit, glib2, and fontconfig manually."
    fi

    log "Installing system packages with $package_manager"
    case "$package_manager" in
        dnf)
            run_root dnf install -y "${packages[@]}"
            ;;
        pacman)
            run_root pacman -Sy --needed --noconfirm "${packages[@]}"
            ;;
        apt-get)
            run_root apt-get update
            run_root apt-get install -y "${packages[@]}"
            ;;
    esac
}

prepare_project() {
    if [[ -f "$PROJECT_DIR/greeter.qml" ]]; then
        return
    fi

    PROJECT_DIR="$HOME/.config/quickshell/wisp-shell"
    if [[ ! -f "$PROJECT_DIR/greeter.qml" ]]; then
        need_command git
        if [[ -e "$PROJECT_DIR" && ! -d "$PROJECT_DIR" ]]; then
            fail "Project destination exists and is not a directory: $PROJECT_DIR"
        fi
        if [[ -d "$PROJECT_DIR" && -n "$(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
            fail "Project destination exists but is not a Wisp Shell checkout: $PROJECT_DIR"
        fi
        log "Cloning Wisp Shell into $PROJECT_DIR"
        mkdir -p "$(dirname -- "$PROJECT_DIR")"
        git clone "$REPOSITORY_URL" "$PROJECT_DIR"
    fi
}

install_matugen() {
    if command -v matugen >/dev/null 2>&1; then
        return
    fi

    export PATH="$HOME/.cargo/bin:$PATH"
    if command -v matugen >/dev/null 2>&1; then
        return
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        log "Installing Rust tooling for Matugen"
        if command -v dnf >/dev/null 2>&1; then
            run_root dnf install -y cargo
        elif command -v pacman >/dev/null 2>&1; then
            run_root pacman -Sy --needed --noconfirm rust
        elif command -v apt-get >/dev/null 2>&1; then
            run_root apt-get install -y cargo
        else
            fail "Cargo is required to install Matugen on this system."
        fi
    fi

    log "Installing Matugen"
    cargo install matugen
    command -v matugen >/dev/null 2>&1 || fail "Matugen was installed but is not available in PATH"
}

install_greeter_files() {
    [[ -d /etc/greetd ]] || fail "/etc/greetd does not exist; greetd was not installed correctly"

    local launcher
    launcher="$(mktemp)"
    cat > "$launcher" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
unset DISPLAY WAYLAND_DISPLAY WAYLAND_SOCKET

export XDG_RUNTIME_DIR="/tmp/greetd-runtime-\$(id -u)"
mkdir -p "\$XDG_RUNTIME_DIR"
chmod 0700 "\$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export XDG_DATA_DIRS="/usr/local/share:/usr/share"

# Dynamically find the greeter file location
GREETER_PATH=""

# 1. Check shared system locations first
if [[ -f "/etc/greetd/wisp-shell/greeter.qml" ]]; then
    GREETER_PATH="/etc/greetd/wisp-shell/greeter.qml"
elif [[ -f "/usr/share/wisp-shell/greeter.qml" ]]; then
    GREETER_PATH="/usr/share/wisp-shell/greeter.qml"
else
    # 2. Fall back to finding it in the primary user's home directory (UID >= 1000)
    for home_dir in \$(awk -F: '\$3 >= 1000 && \$3 < 60000 {print \$6}' /etc/passwd); do
        target="\$home_dir/.config/quickshell/wisp-shell/greeter.qml"
        if [[ -f "\$target" ]]; then
            GREETER_PATH="\$target"
            break
        fi
    done
fi

if [[ -z "\$GREETER_PATH" ]]; then
    echo "Error: Could not locate greeter.qml" >&2
    exit 1
fi

exec niri --config /etc/greetd/niri-greeter.kdl -- quickshell -p "\$GREETER_PATH" >/dev/null 2>&1
EOF
    chmod 0755 "$launcher"
    run_root rm -f /usr/local/bin/wisp-greeter
    run_root install -o root -g root -m 0755 "$launcher" /usr/local/bin/wisp-greeter
    rm -f "$launcher"

    local greeter_config
    greeter_config="$(mktemp)"
    cat > "$greeter_config" <<EOF
input {
    touchpad {
        tap
        natural-scroll
    }
}

prefer-no-csd
screenshot-path null

layout {
    background-color "#000000"
    focus-ring {
        off
    }
    border {
        off
    }
}

hotkey-overlay {
    skip-at-startup
}
EOF
    run_root rm -f /etc/greetd/niri-greeter.kdl
    run_root install -o root -g root -m 0644 "$greeter_config" /etc/greetd/niri-greeter.kdl
    rm -f "$greeter_config"

    if [[ -f /etc/greetd/config.toml ]]; then
        local greetd_config
        greetd_config="$(mktemp)"
        awk '
            BEGIN { in_default = 0; skip_default = 0; skip_initial = 0; saw_default = 0; seen_command = 0; seen_user = 0 }
            /^\[initial_session\]/ { in_default = 0; skip_default = 0; skip_initial = 1; next }
            /^\[default_session\]/ {
                if (saw_default) {
                    in_default = 0
                    skip_default = 1
                    next
                }
                in_default = 1
                skip_default = 0
                saw_default = 1
            }
            /^\[/ && !/^\[default_session\]/ && !/^\[initial_session\]/ { in_default = 0; skip_default = 0; skip_initial = 0 }
            skip_initial { next }
            skip_default { next }
            in_default && /^command[[:space:]]*=/ { print "command = \"/usr/local/bin/wisp-greeter\""; seen_command = 1; next }
            in_default && /^user[[:space:]]*=/ { print "user = \"greeter\""; seen_user = 1; next }
            { print }
            END {
                if (!saw_default) {
                    print ""
                    print "[default_session]"
                }
                if (!seen_command) print "command = \"/usr/local/bin/wisp-greeter\""
                if (!seen_user) print "user = \"greeter\""
            }
        ' /etc/greetd/config.toml > "$greetd_config"
        run_root rm -f /etc/greetd/config.toml
        run_root install -o root -g root -m 0644 "$greetd_config" /etc/greetd/config.toml
        rm -f "$greetd_config"
    fi
}

setup_access() {
    [[ $(id -u "$GREETER_USER" 2>/dev/null || true) ]] || fail "The $GREETER_USER user does not exist"
    need_command setfacl

    mkdir -p "$CONFIG_DIR"
    setfacl -m "u:$GREETER_USER:x" "$HOME"
    setfacl -R -m "u:$GREETER_USER:rwX" "$PROJECT_DIR" "$CONFIG_DIR"
    find "$PROJECT_DIR" "$CONFIG_DIR" -type d -exec setfacl -m "d:u:$GREETER_USER:rwx" {} +
}

main() {
    [[ $EUID -ne 0 ]] || fail "Run this installer as your normal user; it will request sudo when needed."
    need_command sudo

    install_packages
    prepare_project
    install_matugen
    setup_access
    install_greeter_files

    need_command quickshell
    need_command niri
    need_command python3
    need_command matugen
    need_command awk
    need_command getent
    need_command install
    need_command systemctl
    log "Installation complete. Restart greetd to launch the greeter."
}

main "$@"