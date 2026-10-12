#!/usr/bin/env bash
set -Eeuo pipefail
readonly SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
    readonly SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd -P)"
else
    readonly SCRIPT_DIR=""
fi

DEFAULT_REPO_URL="https://github.com/physteorts/wisp-shell.git"
if [[ -n "$SCRIPT_DIR" ]] && git -C "$SCRIPT_DIR/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _detected_origin="$(git -C "$SCRIPT_DIR/.." config --get remote.origin.url || true)"
    if [[ "$_detected_origin" =~ ^git@github\.com:(.*)$ ]]; then
        _detected_origin="https://github.com/${BASH_REMATCH[1]}"
    fi
    if [[ -n "$_detected_origin" ]]; then
        DEFAULT_REPO_URL="$_detected_origin"
    fi
fi

detect_greeter_user() {
    if [[ -n "${GREETER_USER:-}" ]]; then
        echo "$GREETER_USER"
        return
    fi
    if id -u greetd >/dev/null 2>&1; then
        echo "greetd"
    elif id -u greeter >/dev/null 2>&1; then
        echo "greeter"
    elif [[ -f /etc/greetd/config.toml.orig ]] && grep -qE '^[[:space:]]*user[[:space:]]*=[[:space:]]*"greetd"' /etc/greetd/config.toml.orig 2>/dev/null; then
        echo "greetd"
    elif [[ -f /etc/greetd/config.toml ]] && grep -qE '^[[:space:]]*user[[:space:]]*=[[:space:]]*"greetd"' /etc/greetd/config.toml 2>/dev/null; then
        echo "greetd"
    elif [[ -d /var/lib/greetd ]] && [[ "$(stat -c '%U' /var/lib/greetd 2>/dev/null || true)" == "greetd" ]]; then
        echo "greetd"
    else
        echo "greetd"
    fi
}

GREETER_USER="$(detect_greeter_user)"
readonly CONFIG_DIR="$HOME/.config/wisp-shell"
readonly PROJECT_DIR="$HOME/.config/quickshell/wisp-shell"
readonly SHELL_CONFIG_DIR="$PROJECT_DIR"
readonly NIRI_CONFIG_DIR="$HOME/.config/niri"

SKIP_PACKAGES=false
ENABLE_GREETD=true
SUDO_KEEP_ALIVE_PID=""

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    readonly C_RESET=$'\033[0m'
    readonly C_BOLD=$'\033[1m'
    readonly C_BLUE=$'\033[38;2;177;204;195m'
    readonly C_CYAN=$'\033[38;2;133;214;192m'
    readonly C_GREEN=$'\033[38;2;133;214;192m'
    readonly C_YELLOW=$'\033[38;2;170;203;227m'
    readonly C_RED=$'\033[38;2;255;180;171m'
else
    readonly C_RESET=""
    readonly C_BOLD=""
    readonly C_BLUE=""
    readonly C_CYAN=""
    readonly C_GREEN=""
    readonly C_YELLOW=""
    readonly C_RED=""
fi

if [[ "${LANG:-}" =~ [Uu][Tt][Ff]-?8 || "${LC_ALL:-}" =~ [Uu][Tt][Ff]-?8 || "${LC_CTYPE:-}" =~ [Uu][Tt][Ff]-?8 ]]; then
    readonly ICON_DOT="●"
    readonly ICON_CHECK="✔"
    readonly ICON_CROSS="✖"
    readonly ICON_INFO="ℹ"
    readonly ICON_ARROW="➜"
    readonly ICON_WARN="⚠"
else
    readonly ICON_DOT="*"
    readonly ICON_CHECK="[OK]"
    readonly ICON_CROSS="[FAIL]"
    readonly ICON_INFO="[i]"
    readonly ICON_ARROW="->"
    readonly ICON_WARN="[!]"
fi

print_banner() {
    printf '%s\n' \
        "${C_BLUE}╭───────────────────────────────────────────────╮" \
        "│                                               │" \
        "│        ${C_CYAN}██╗    ██╗██╗███████╗██████╗${C_BLUE}           │" \
        "│        ${C_CYAN}██║    ██║██║██╔════╝██╔══██╗${C_BLUE}          │" \
        "│        ${C_CYAN}██║ █╗ ██║██║███████╗██████╔╝${C_BLUE}          │" \
        "│        ${C_CYAN}██║███╗██║██║╚════██║██╔═══╝${C_BLUE}           │" \
        "│        ${C_CYAN}╚███╔███╔╝██║███████║██║${C_BLUE}               │" \
        "│        ${C_CYAN} ╚══╝╚══╝ ╚═╝╚══════╝╚═╝${C_BLUE}               │" \
        "│                                               │" \
        "│           ${C_CYAN}Wayland Desktop Shell${C_BLUE}               │" \
        "│                                               │" \
        "╰───────────────────────────────────────────────╯${C_RESET}"
    echo
}

step_header() {
    local num="$1"
    local total="$2"
    local title="$3"
    printf '%s\n' "${C_CYAN}${ICON_DOT}${C_RESET} ${C_BOLD}[${num}/${total}] ${title}${C_RESET}"
}

log_ok() {
    printf '  %s %s\n' "${C_GREEN}${ICON_CHECK}${C_RESET}" "$*"
}

log_info() {
    printf '  %s %s\n' "${C_BLUE}${ICON_INFO}${C_RESET}" "$*"
}

log_action() {
    printf '  %s %s\n' "${C_CYAN}${ICON_ARROW}${C_RESET}" "$*"
}

log_warn() {
    printf '  %s %s\n' "${C_YELLOW}${ICON_WARN}${C_RESET}" "$*"
}

log_fail() {
    printf '  %s %s\n' "${C_RED}${ICON_CROSS}${C_RESET}" "$*" >&2
}

fail() {
    log_fail "$*"
    exit 1
}

cleanup() {
    if [[ -n "${SUDO_KEEP_ALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    fi
}

on_error() {
    local line_no="${1:-unknown}"
    log_fail "Installer failed unexpectedly at line ${line_no}."
}

trap cleanup EXIT INT TERM
trap 'on_error $LINENO' ERR

run_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

need_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required tool '$1' is missing from PATH."
}

verify_system_compatibility() {
    step_header 1 6 "Checking System Compatibility"

    if [[ ! -f /etc/os-release ]]; then
        fail "Cannot detect operating system (/etc/os-release was not found)."
    fi

    local os_id="" os_id_like="" os_pretty=""
    os_id="$(. /etc/os-release 2>/dev/null && echo "${ID:-}" || true)"
    os_id_like="$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}" || true)"
    os_pretty="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-}" || true)"

    if [[ "$os_id" != "fedora" && "$os_id_like" != *"fedora"* ]]; then
        printf '\n%s\n' \
            "${C_RED}╭─────────────────── Distribution Error ──────────────────────╮" \
            "│                                                             │" \
            "│  Wisp Shell installer is designed exclusively for Fedora.   │" \
            "│                                                             │" \
            "│  Requirements & native optimizations:                       │" \
            "│    • Fedora Linux 40+                                       │" \
            "│    • DNF package manager                                    │" \
            "│                                                             │" \
            "│  For other distributions, manual setup is required.         │" \
            "│                                                             │" \
            "╰─────────────────────────────────────────────────────────────╯${C_RESET}" >&2
        printf '\n%s\n' "${C_YELLOW}Detected system:${C_RESET} ${os_pretty:-$os_id}" >&2
        exit 1
    fi

    log_ok "${os_pretty:-Fedora Linux} verified"

    if [[ $EUID -eq 0 ]]; then
        fail "Please execute this installer as your regular user (sudo will be used when needed)."
    fi
    log_ok "Running as normal user '${USER:-$(id -un)}' (UID: $EUID)"

    need_command sudo
    if ! sudo -n true 2>/dev/null; then
        log_action "Authenticating administrative privileges..."
        sudo -v || fail "Sudo authentication failed."
    fi

    while true; do
        sudo -n true 2>/dev/null || true
        sleep 30
        kill -0 "$$" 2>/dev/null || exit 0
    done 2>/dev/null &
    SUDO_KEEP_ALIVE_PID=$!
    log_ok "Administrative privileges active"
    echo
}

enable_quickshell_copr() {
    if compgen -G "/etc/yum.repos.d/*errornointernet*quickshell*.repo" >/dev/null 2>&1; then
        log_ok "Quickshell COPR repository active (errornointernet/quickshell)"
        return 0
    fi

    log_action "Enabling Quickshell COPR (errornointernet/quickshell)..."
    run_root dnf copr enable -y errornointernet/quickshell || fail "Failed to enable errornointernet/quickshell COPR."
    log_ok "Quickshell COPR repository enabled"
}

enable_ghostty_copr() {
    if compgen -G "/etc/yum.repos.d/*scottames*ghostty*.repo" >/dev/null 2>&1; then
        log_ok "Ghostty COPR repository active (scottames/ghostty)"
        return 0
    fi

    log_action "Enabling Ghostty COPR (scottames/ghostty)..."
    run_root dnf copr enable -y scottames/ghostty || fail "Failed to enable scottames/ghostty COPR."
    log_ok "Ghostty COPR repository enabled"
}

install_packages() {
    step_header 2 6 "Installing System Packages & Repositories"

    if [[ "$SKIP_PACKAGES" == "true" ]]; then
        log_info "Package installation skipped via --skip-packages"
        echo
        return 0
    fi

    need_command dnf

    enable_quickshell_copr
    enable_ghostty_copr

    local -a packages=(
        git
        curl
        findutils
        gawk
        python3
        nautilus-python
        acl
        polkit
        glib2
        fontconfig
        rsms-inter-fonts
        brightnessctl
        pulseaudio-utils
        wireplumber
        quickshell
        greetd
        greetd-selinux
        niri
        matugen
        ghostty
        wl-mirror
    )

    local -a missing=()
    for pkg in "${packages[@]}"; do
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_ok "All required packages are already installed"
    else
        log_action "Installing missing packages (${#missing[@]} packages)..."
        log_info "Missing: ${missing[*]}"

        if ! run_root dnf install -y "${missing[@]}"; then
            log_warn "Standard installation encountered an issue; retrying with --skip-unavailable..."
            run_root dnf install -y --skip-unavailable "${missing[@]}" || fail "Failed to install required system packages via DNF."
        fi
        log_ok "Required packages installed successfully"
    fi

    install_matugen_fallback

    install_fonts

    echo
}

install_matugen_fallback() {
    if command -v matugen >/dev/null 2>&1; then
        return 0
    fi

    export PATH="$HOME/.cargo/bin:$PATH"
    if command -v matugen >/dev/null 2>&1; then
        return 0
    fi

    log_action "Matugen binary not found in system PATH. Installing via Cargo..."
    if ! command -v cargo >/dev/null 2>&1; then
        log_action "Installing cargo via DNF..."
        run_root dnf install -y cargo
    fi

    cargo install matugen

    if [[ -x "$HOME/.cargo/bin/matugen" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        run_root ln -sf "$HOME/.cargo/bin/matugen" /usr/local/bin/matugen
        log_ok "Matugen installed via Cargo and linked to /usr/local/bin/matugen"
    fi
}

install_fonts() {
    local font_dir="/usr/local/share/fonts/google-material-symbols"
    local font_file="$font_dir/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    local font_url="https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"

    if fc-list : family | grep -qi "Material Symbols Rounded"; then
        log_ok "Google Material Symbols Rounded font verified"
        return 0
    fi

    log_action "Installing Google Material Symbols Rounded font..."
    run_root mkdir -p "$font_dir"

    if command -v curl >/dev/null 2>&1; then
        run_root curl -fsSL -o "$font_file" "$font_url" || fail "Failed to download Material Symbols Rounded font via curl."
    elif command -v wget >/dev/null 2>&1; then
        run_root wget -qO "$font_file" "$font_url" || fail "Failed to download Material Symbols Rounded font via wget."
    else
        fail "Neither curl nor wget is available to download Google Material Symbols font."
    fi

    run_root chmod 0644 "$font_file"
    run_root fc-cache -f "$font_dir" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    log_ok "Google Material Symbols Rounded font installed successfully"
}

setup_project_files() {
    step_header 3 6 "Preparing Wisp Shell Workspace"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname -- "$PROJECT_DIR")"

    if [[ -d "$PROJECT_DIR/.git" ]]; then
        log_ok "Wisp Shell git repository found at: $PROJECT_DIR"
    elif [[ -f "$PROJECT_DIR/greeter.qml" && -f "$PROJECT_DIR/shell.qml" ]]; then
        log_ok "Using existing Wisp Shell workspace at: $PROJECT_DIR"
    else
        need_command git
        if [[ -e "$PROJECT_DIR" && ! -d "$PROJECT_DIR" ]]; then
            fail "Destination exists and is not a directory: $PROJECT_DIR"
        fi
        if [[ -d "$PROJECT_DIR" && -n "$(find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
            fail "Destination exists but is not an empty directory or Wisp checkout: $PROJECT_DIR"
        fi

        log_action "Cloning Wisp Shell into $PROJECT_DIR..."
        git clone "$REPOSITORY_URL" "$PROJECT_DIR"
        log_ok "Repository cloned successfully"
    fi

    log_ok "Workspace ready at $PROJECT_DIR"
    echo
}

setup_niri_configuration() {
    step_header 4 6 "Configuring Niri Compositor & Shell Integration"

    local niri_config_file="$NIRI_CONFIG_DIR/config.kdl"
    local niri_alt_file="$NIRI_CONFIG_DIR/niri.kdl"
    local wisp_kdl_source="$PROJECT_DIR/configs/wisp-shell.kdl"
    local wisp_kdl_target="$NIRI_CONFIG_DIR/wisp-shell.kdl"

    mkdir -p "$NIRI_CONFIG_DIR"

    if [[ -L "$wisp_kdl_target" ]]; then
        rm -f "$wisp_kdl_target"
    fi
    cp -f "$wisp_kdl_source" "$wisp_kdl_target"
    log_ok "Installed Niri module: $wisp_kdl_target"

    local primary_config="$niri_config_file"
    if [[ ! -f "$primary_config" && -f "$niri_alt_file" ]]; then
        primary_config="$niri_alt_file"
    fi

    if [[ ! -f "$primary_config" ]]; then
        log_action "No existing Niri config found; creating initial $niri_config_file..."
        cat <<'EOF' > "$niri_config_file"
include "wisp-shell.kdl"
EOF
        primary_config="$niri_config_file"
        log_ok "Created initial $niri_config_file"
    fi

    if grep -qE '^[[:space:]]*include[[:space:]]+"[./]*wisp-shell\.kdl"' "$primary_config"; then
        log_ok "wisp-shell.kdl is already included in $(basename "$primary_config")"
    else
        log_action "Including wisp-shell.kdl in $(basename "$primary_config")..."
        [[ -s "$primary_config" && -n "$(tail -c 1 "$primary_config")" ]] && echo >> "$primary_config"
        printf '\ninclude "wisp-shell.kdl"\n' >> "$primary_config"
        log_ok "Added include \"wisp-shell.kdl\" to $(basename "$primary_config")"
    fi

    if grep -qE '^[[:space:]]*spawn-at-startup[[:space:]]+"waybar"' "$primary_config"; then
        log_action "Disabling conflicting waybar spawn in $(basename "$primary_config")..."
        sed -i -E 's/^([[:space:]]*)(spawn-at-startup[[:space:]]+"waybar")/\1\/\/ Disabled for Wisp Shell: \2/' "$primary_config"
        log_ok "Waybar startup disabled in favor of Wisp Shell top bar"
    fi

    local ghostty_dir="$HOME/.config/ghostty"
    local ghostty_conf="$ghostty_dir/config"
    mkdir -p "$ghostty_dir"
    if [[ ! -f "$ghostty_conf" ]]; then
        cat <<'EOF' > "$ghostty_conf"
window-padding-x = 10
window-padding-y = 10
config-file = ?theme.conf
EOF
        log_ok "Configured Ghostty theme link: $ghostty_conf"
    elif ! grep -q "theme.conf" "$ghostty_conf"; then
        printf '\nconfig-file = ?theme.conf\n' >> "$ghostty_conf"
        log_ok "Added Matugen theme include to $ghostty_conf"
    fi

    if command -v niri >/dev/null 2>&1; then
        if niri validate -c "$primary_config" >/dev/null 2>&1; then
            log_ok "Niri configuration validated successfully"
        else
            log_warn "Niri config validation reported issues; run 'niri validate' to inspect"
        fi
    fi

    echo
}

setup_greeter_configuration() {
    step_header 5 6 "Configuring Greetd & Greeter Session"

    run_root mkdir -p /etc/greetd /usr/local/bin

    cat <<'EOF' | run_root install -o root -g root -m 0755 /dev/stdin /usr/local/bin/wisp-greeter
#!/usr/bin/env bash
set -Eeuo pipefail
unset DISPLAY WAYLAND_DISPLAY WAYLAND_SOCKET

umask 0077

if [[ -d "/run/user/$(id -u)" && -w "/run/user/$(id -u)" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
else
    export XDG_RUNTIME_DIR="/tmp/greetd-runtime-$(id -u)"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 0700 "$XDG_RUNTIME_DIR"
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export XDG_DATA_DIRS="/usr/local/share:/usr/share"

GREETER_PATH=""

if [[ -f "/etc/greetd/wisp-shell/greeter.qml" ]]; then
    GREETER_PATH="/etc/greetd/wisp-shell/greeter.qml"
elif [[ -f "/usr/share/wisp-shell/greeter.qml" ]]; then
    GREETER_PATH="/usr/share/wisp-shell/greeter.qml"
else
    for home_dir in $(awk -F: '$3 >= 1000 && $3 < 60000 {print $6}' /etc/passwd); do
        target="$home_dir/.config/quickshell/wisp-shell/greeter.qml"
        if [[ -f "$target" ]]; then
            GREETER_PATH="$target"
            break
        fi
    done
fi

if [[ -z "$GREETER_PATH" ]]; then
    echo "Error: Could not locate greeter.qml" >&2
    exit 1
fi

exec niri --config /etc/greetd/niri-greeter.kdl -- quickshell -p "$GREETER_PATH" >/dev/null 2>&1
EOF
    log_ok "Installed hardened launcher: /usr/local/bin/wisp-greeter"

    cat <<'EOF' | run_root install -o root -g root -m 0644 /dev/stdin /etc/greetd/niri-greeter.kdl
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
    log_ok "Installed compositor config: /etc/greetd/niri-greeter.kdl"

    local greetd_target="/etc/greetd/config.toml"

    if [[ -f "$greetd_target" ]]; then
        if [[ ! -f "/etc/greetd/config.toml.orig" ]]; then
            run_root cp -f "$greetd_target" "/etc/greetd/config.toml.orig"
        fi

        local updated_conf
        updated_conf="$(mktemp)"
        awk -v target_user="$GREETER_USER" '
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
            in_default && /^user[[:space:]]*=/ { print "user = \"" target_user "\""; seen_user = 1; next }
            { print }
            END {
                if (!saw_default) {
                    print ""
                    print "[default_session]"
                }
                if (!seen_command) print "command = \"/usr/local/bin/wisp-greeter\""
                if (!seen_user) print "user = \"" target_user "\""
            }
        ' "$greetd_target" > "$updated_conf"

        run_root install -o root -g root -m 0644 "$updated_conf" "$greetd_target"
        rm -f "$updated_conf"
    else
        cat <<EOF | run_root install -o root -g root -m 0644 /dev/stdin "$greetd_target"
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/wisp-greeter"
user = "$GREETER_USER"
EOF
    fi

    log_ok "Configured default greeter session: /etc/greetd/config.toml"
    echo
}

setup_security_and_display_managers() {
    step_header 6 6 "Configuring Security & Display Manager"

    if ! id -u "$GREETER_USER" >/dev/null 2>&1; then
        log_action "Creating hardened system user '$GREETER_USER'..."
        run_root useradd -r -M -d /var/lib/greetd -s /sbin/nologin -G video,input "$GREETER_USER"
        run_root usermod -L "$GREETER_USER" 2>/dev/null || true
        log_ok "Created restricted system user '$GREETER_USER'"
    else
        log_ok "System user '$GREETER_USER' verified"
        if ! id -nG "$GREETER_USER" | grep -qw video || ! id -nG "$GREETER_USER" | grep -qw input; then
            run_root usermod -aG video,input "$GREETER_USER" 2>/dev/null || true
        fi
        run_root usermod -e "" "$GREETER_USER" 2>/dev/null || true
        run_root usermod -L "$GREETER_USER" 2>/dev/null || true
    fi

    local target_owner="$GREETER_USER"
    if [[ -f /usr/lib/tmpfiles.d/greetd.conf ]]; then
        local tmpfile_owner
        tmpfile_owner="$(awk '/\/var\/lib\/greetd/ {print $4; exit}' /usr/lib/tmpfiles.d/greetd.conf 2>/dev/null || true)"
        if [[ -n "$tmpfile_owner" ]] && id -u "$tmpfile_owner" >/dev/null 2>&1; then
            target_owner="$tmpfile_owner"
        fi
    fi

    run_root mkdir -p /var/lib/greetd
    run_root chown -R "$target_owner:$target_owner" /var/lib/greetd 2>/dev/null || true
    run_root chmod 0750 /var/lib/greetd 2>/dev/null || true

    need_command setfacl
    log_action "Applying least-privilege POSIX ACLs..."

    mkdir -p "$HOME/.config/quickshell" "$CONFIG_DIR"

    apply_acls_for_user() {
        local u="$1"
        setfacl -m "u:$u:x" "$HOME" "$HOME/.config" "$HOME/.config/quickshell" 2>/dev/null || true
        setfacl -R -m "u:$u:rX,d:u:$u:rX" "$PROJECT_DIR" 2>/dev/null || true
        setfacl -R -m "u:$u:rwX,d:u:$u:rwx" "$CONFIG_DIR" 2>/dev/null || true
    }

    apply_acls_for_user "$GREETER_USER"
    if [[ "$GREETER_USER" != "greeter" ]] && id -u greeter >/dev/null 2>&1; then
        apply_acls_for_user "greeter"
        run_root usermod -aG "$target_owner" greeter 2>/dev/null || true
    fi
    if [[ "$GREETER_USER" != "greetd" ]] && id -u greetd >/dev/null 2>&1; then
        apply_acls_for_user "greetd"
    fi
    log_ok "Access ACLs applied (shell source locked to read-only for '$GREETER_USER')"

    if [[ "$ENABLE_GREETD" == "true" ]]; then
        log_action "Checking and disabling conflicting display managers..."
        local -a conflicting_services=(
            gdm.service
            sddm.service
            lightdm.service
            lxdm.service
            ly.service
            lemurs.service
            emptty.service
        )

        local disabled_count=0
        for s in "${conflicting_services[@]}"; do
            if systemctl is-enabled "$s" >/dev/null 2>&1; then
                log_info "Disabling conflicting service: $s"
                run_root systemctl disable "$s" 2>/dev/null || true
                ((disabled_count++)) || true
            fi
        done

        if [[ $disabled_count -gt 0 ]]; then
            log_ok "Disabled conflicting display managers ($disabled_count service(s) disabled)"
        else
            log_ok "No conflicting display managers were active"
        fi

        log_action "Enabling greetd.service as primary display manager..."
        run_root systemctl enable greetd.service || fail "Failed to enable greetd.service."
        run_root systemctl set-default graphical.target 2>/dev/null || true
        log_ok "greetd.service enabled successfully (graphical.target default)"
    fi

    if command -v restorecon >/dev/null 2>&1; then
        log_action "Restoring Fedora SELinux contexts..."
        run_root restorecon -v /usr/local/bin/wisp-greeter 2>/dev/null || true
        run_root restorecon -Rv /etc/greetd 2>/dev/null || true
        run_root restorecon -Rv /usr/local/share/fonts 2>/dev/null || true
        log_ok "SELinux file contexts updated"
    fi

    echo
}

verify_installation() {
    local -a required_bins=(quickshell niri greetd matugen python3 ghostty wl-mirror)
    local all_found=true

    for b in "${required_bins[@]}"; do
        if ! command -v "$b" >/dev/null 2>&1; then
            log_warn "Command '$b' was not found in PATH"
            all_found=false
        fi
    done

    if [[ ! -x "/usr/local/bin/wisp-greeter" ]]; then
        log_warn "/usr/local/bin/wisp-greeter is not executable"
        all_found=false
    fi

    if [[ ! -f "$HOME/.config/niri/wisp-shell.kdl" ]]; then
        log_warn "Wisp Shell Niri config (~/.config/niri/wisp-shell.kdl) was not found"
        all_found=false
    fi

    if ! fc-list : family | grep -qi "Material Symbols Rounded"; then
        log_warn "'Material Symbols Rounded' font was not detected in fontconfig"
        all_found=false
    fi

    if [[ "$all_found" == "true" ]]; then
        log_ok "System dependencies, fonts, and launcher binaries validated"
    fi
}

print_summary() {
    echo
    printf '%s\n' \
        "${C_GREEN}╭─────────────────────────────────────────────────────────────╮" \
        "│                 ${C_BOLD}Installation Complete${C_RESET}${C_GREEN}                       │" \
        "│                                                             │" \
        "│    ${C_CYAN}Reboot your system for the changes to take effect.${C_RESET}${C_GREEN}       │" \
        "╰─────────────────────────────────────────────────────────────╯${C_RESET}"
    echo
}

show_help() {
    cat <<EOF
Wisp Shell Installer

Usage:
  ./install.sh [OPTIONS]

Options:
  --skip-packages    Skip DNF package installation
  --no-enable        Do not disable other display managers or enable greetd
  -h, --help         Show this help message and exit

Description:
  Installs Quickshell (via errornointernet/quickshell COPR), Ghostty (via
  scottames/ghostty COPR), Greetd, Niri, Matugen, wl-mirror, and dependencies on Fedora
  Linux, configures Wisp Shell Niri integration (wisp-shell.kdl), sets up
  hardened security permissions, disables conflicting display managers (e.g.
  GDM, SDDM), and enables greetd.service as the default display manager.
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --no-enable)
                ENABLE_GREETD=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                fail "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done

    print_banner
    verify_system_compatibility
    install_packages
    setup_project_files
    setup_niri_configuration
    setup_greeter_configuration
    setup_security_and_display_managers
    verify_installation
    print_summary
}

main "$@"
