#!/bin/bash
# =============================================================================
# Rin AI — Installer / Upgrader
# Supports: Ubuntu, Arch Linux, GitHub Codespaces, Generic VPS
# =============================================================================
# One command:
#   curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/release/install-rin.sh | bash
# =============================================================================

set -e

R="\033[0;36m"; G="\033[0;32m"; Y="\033[1;33m"; RED="\033[0;31m"; B="\033[1m"; N="\033[0m"

banner() {
    echo -e "${R}"
    echo -e " ___ ___ _  _     _   ___ "
    echo -e "| _ \\_ _| \\| |   /_\\ |_ _|"
    echo -e "|   /| || .' |  / _ \\ | | "
    echo -e "|_|_\\___|_|\\_| /_/ \\_\\___|"
    echo -e "${N}"
    echo -e "${G}  Rin AI${N} — Unrestricted. Unlimited. Unstoppable."
    echo -e "  ${Y}TG${N} t.me/RinquicklyBot  ${Y}DC${N} discord.gg/K98kCm6CVf"
    echo ""
}

RIN_REPO="rinquickly/rin"
RIN_HOME="${RIN_HOME:-$HOME/.rin}"
BIN_DIR="$RIN_HOME/bin"
SRC_DIR="$RIN_HOME/src"

# =============================================================================
# Detect environment
# =============================================================================
detect_env() {
    ENV_TYPE="generic"
    DISTRO="unknown"
    IS_CODESPACE=false
    IS_ROOT=false

    # Root check
    [ "$(id -u)" = "0" ] && IS_ROOT=true

    # GitHub Codespaces
    if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ] || [ -f "/workspaces/.codespaces" ]; then
        ENV_TYPE="codespace"
        IS_CODESPACE=true
        DISTRO="ubuntu"  # Codespaces is Debian/Ubuntu based
    fi

    # Detect distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) DISTRO="ubuntu" ;;
            arch|manjaro|endeavouros) DISTRO="arch" ;;
            fedora|rhel|centos|rocky|almalinux) DISTRO="fedora" ;;
            *) DISTRO="$ID" ;;
        esac
        [ "$ENV_TYPE" = "generic" ] && ENV_TYPE="vps"
    fi

    # Print detected env
    echo -e "${G}▸${N} Environment: ${B}$ENV_TYPE${N} / ${B}$DISTRO${N}"
    $IS_CODESPACE && echo -e "${G}▸${N} GitHub Codespaces detected"
    $IS_ROOT && echo -e "${Y}▸${N} Running as root"
}

# =============================================================================
# Install system dependencies per distro
# =============================================================================
ensure_deps() {
    local pkgs="curl git tar"

    case "$DISTRO" in
        ubuntu)
            if ! dpkg -s curl git tar &>/dev/null 2>&1; then
                echo -e "${G}▸${N} Installing deps (apt)..."
                if $IS_ROOT; then
                    apt-get update -qq && apt-get install -y -qq $pkgs
                else
                    sudo apt-get update -qq && sudo apt-get install -y -qq $pkgs
                fi
            fi
            ;;
        arch)
            if ! pacman -Q curl git tar &>/dev/null 2>&1; then
                echo -e "${G}▸${N} Installing deps (pacman)..."
                if $IS_ROOT; then
                    pacman -Sy --noconfirm --needed $pkgs
                else
                    sudo pacman -Sy --noconfirm --needed $pkgs
                fi
            fi
            ;;
        fedora)
            if ! rpm -q curl git tar &>/dev/null 2>&1; then
                echo -e "${G}▸${N} Installing deps (dnf)..."
                if $IS_ROOT; then
                    dnf install -y -q $pkgs
                else
                    sudo dnf install -y -q $pkgs
                fi
            fi
            ;;
        *)
            # Generic VPS — assume deps exist, warn if missing
            for cmd in curl git tar; do
                if ! command -v "$cmd" &>/dev/null; then
                    echo -e "${RED}✖ Missing: $cmd — please install it manually${N}"
                    exit 1
                fi
            done
            ;;
    esac
    echo -e "${G}✓${N} System deps ready"
}

# =============================================================================
# Ensure bun is installed
# =============================================================================
ensure_bun() {
    if ! command -v bun &>/dev/null; then
        echo -e "${G}▸${N} Installing bun runtime..."

        # Codespaces: HOME may be /root or /home/codespace
        # Arch: needs unzip for bun installer
        if [ "$DISTRO" = "arch" ] && ! command -v unzip &>/dev/null; then
            if $IS_ROOT; then pacman -Sy --noconfirm --needed unzip 2>/dev/null || true
            else sudo pacman -Sy --noconfirm --needed unzip 2>/dev/null || true; fi
        fi

        curl -fsSL https://bun.sh/install | bash
        # Source for all common shell configs
        source "$HOME/.bashrc" 2>/dev/null || true
        source "$HOME/.zshrc" 2>/dev/null || true
        export PATH="$HOME/.bun/bin:$PATH"
    fi

    # Codespaces: bun may be in a different path
    if ! command -v bun &>/dev/null; then
        export PATH="$HOME/.bun/bin:/usr/local/bin:$PATH"
    fi

    echo -e "${G}✓${N} Bun $(bun --version)"
}

# =============================================================================
# Clone/update source
# =============================================================================
ensure_source() {
    if [ -d "$SRC_DIR/.git" ]; then
        echo -e "${G}▸${N} Updating Rin source..."
        cd "$SRC_DIR" && git pull origin main --force 2>/dev/null || true
    else
        echo -e "${G}▸${N} Downloading Rin source..."
        mkdir -p "$RIN_HOME"
        git clone --depth 1 --branch main "https://github.com/$RIN_REPO.git" "$SRC_DIR" 2>/dev/null || {
            echo -e "${RED}✖ Failed to download Rin${N}"
            exit 1
        }
    fi

    echo -e "${G}▸${N} Installing dependencies..."
    cd "$SRC_DIR"
    bun install --ignore-scripts 2>&1 | tail -1
    echo -e "${G}✓${N} Dependencies installed"
}

# =============================================================================
# Create rin launcher
# =============================================================================
create_launcher() {
    mkdir -p "$BIN_DIR"

    local platform arch
    platform=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$platform" in linux) ;; darwin) ;; *) platform="linux" ;; esac
    arch=$(uname -m)
    case "$arch" in x86_64|amd64) arch="x64" ;; aarch64|arm64) arch="arm64" ;; *) arch="x64" ;; esac

    local bin_url="https://github.com/$RIN_REPO/releases/download/v1.16.2/rin-${platform}-${arch}.tar.gz"
    echo -e "${G}▸${N} Downloading binary (${platform}-${arch})..."

    # Follow 302 redirect (GitHub releases → S3)
    if curl -fsSL -L "$bin_url" -o /tmp/rin-bin.tar.gz 2>/dev/null; then
        mkdir -p /tmp/rin-extract
        tar -xzf /tmp/rin-bin.tar.gz -C /tmp/rin-extract 2>/dev/null
        local extracted
        extracted=$(find /tmp/rin-extract -type f 2>/dev/null | head -1)
        if [ -n "$extracted" ]; then
            cp "$extracted" "$BIN_DIR/rin"
            chmod +x "$BIN_DIR/rin"
            rm -rf /tmp/rin-extract /tmp/rin-bin.tar.gz
            echo -e "${G}✓${N} Binary installed: $BIN_DIR/rin"
            return
        fi
        echo -e "${Y}▸${N} Tarball empty, falling back..."
        rm -rf /tmp/rin-extract /tmp/rin-bin.tar.gz
    else
        echo -e "${Y}▸${N} Binary download failed, falling back..."
    fi

    # Step 2: Build from source
    echo -e "${Y}▸${N} Building from source..."
    if [ -d "$SRC_DIR/packages/opencode" ]; then
        cd "$SRC_DIR/packages/opencode"
        if bun run script/build.ts --single --skip-embed-web-ui 2>&1 | tail -3; then
            local built_bin
            built_bin=$(find "$SRC_DIR/packages/opencode/dist" -name "opencode" -type f 2>/dev/null | head -1)
            if [ -n "$built_bin" ]; then
                cp "$built_bin" "$BIN_DIR/rin"
                chmod +x "$BIN_DIR/rin"
                echo -e "${G}✓${N} Built from source: $BIN_DIR/rin"
                return
            fi
        fi
    fi

    # Step 3: Bun wrapper fallback
    echo -e "${Y}▸${N} Creating bun wrapper..."
    cat > "$BIN_DIR/rin" << 'LAUNCHER'
#!/bin/bash
SCRIPT="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"
DIR="$(cd "$(dirname "$SCRIPT")/.." && pwd)"

# Ensure bun is in PATH
export PATH="$HOME/.bun/bin:$PATH"

# ===== RIN UNLIMITED MODE =====
export OPENCODE_TIMEOUT=false
export OPENCODE_HEADER_TIMEOUT=false
export OPENCODE_CHUNK_TIMEOUT=999999999
export OPENCODE_CONTEXT_LIMIT=999999999
export OPENCODE_INPUT_LIMIT=999999999
export OPENCODE_OUTPUT_LIMIT=999999999
export OPENCODE_STEPS=999999999
export OPENCODE_COMPACTION_AUTO=false
export OPENCODE_COMPACTION_PRUNE=false
export OPENCODE_TOOL_OUTPUT_MAX_LINES=999999999
export OPENCODE_TOOL_OUTPUT_MAX_BYTES=999999999

# ===== AUTO PROXY ROTATION =====
if [ -z "$RIN_PROXIES" ]; then
    if [ -f "$DIR/rin-proxy.sh" ]; then
        echo "⟳ Rin: Fetching 500+ rotating proxies..." >&2
        RIN_PROXIES=$(bash "$DIR/rin-proxy.sh" 2>/dev/null | paste -sd ",")
        COUNT=$(echo "$RIN_PROXIES" | tr ',' '\n' | wc -l)
        echo "✓ Rin: $COUNT proxies loaded (auto-rotate on limit)" >&2
        export RIN_PROXIES
    elif command -v curl &>/dev/null; then
        echo "⟳ Rin: Fetching proxies from ProxyScrape..." >&2
        RIN_PROXIES=$(curl -sf "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=text&protocol=http&timeout=10000" 2>/dev/null | head -100 | paste -sd ",")
        COUNT=$(echo "$RIN_PROXIES" | tr ',' '\n' | wc -l)
        if [ "$COUNT" -gt 0 ]; then
            echo "✓ Rin: $COUNT proxies loaded" >&2
            export RIN_PROXIES
        fi
    fi
fi

cd "$DIR/src"
exec bun run --conditions=browser packages/opencode/src/index.ts "$@"
LAUNCHER
    chmod +x "$BIN_DIR/rin"
    echo -e "${Y}▸${N} Bun wrapper created"
}

# =============================================================================
# Add to PATH — handles all shell configs + Codespaces /usr/local/bin
# =============================================================================
ensure_path() {
    # Detect shell config file
    local config=""
    local shell_name
    shell_name=$(basename "${SHELL:-bash}")
    case "$shell_name" in
        zsh)  config="$HOME/.zshrc" ;;
        fish) config="$HOME/.config/fish/config.fish" ;;
        *)    config="$HOME/.bashrc" ;;
    esac

    # Write PATH to shell config
    if [ -n "$config" ] && ! grep -q "RIN_HOME" "$config" 2>/dev/null; then
        mkdir -p "$(dirname "$config")"
        echo "" >> "$config"
        echo "# Rin AI" >> "$config"
        if [ "$shell_name" = "fish" ]; then
            echo "set -x RIN_HOME \"$RIN_HOME\"" >> "$config"
            echo "fish_add_path \"$BIN_DIR\"" >> "$config"
        else
            echo "export RIN_HOME=\"$RIN_HOME\"" >> "$config"
            echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$config"
        fi
        echo -e "${Y}▸${N} Added to ${B}$config${N}"
    fi

    # Symlink — prefer /usr/local/bin on Codespaces/root, else ~/.local/bin
    local link_dir
    if $IS_CODESPACE || $IS_ROOT; then
        link_dir="/usr/local/bin"
    else
        link_dir="/usr/local/bin"
    fi

    if [ ! -w "$link_dir" ]; then
        link_dir="$HOME/.local/bin"
        mkdir -p "$link_dir"
    fi

    ln -sf "$BIN_DIR/rin" "$link_dir/rin" 2>/dev/null && \
        echo -e "${G}✓${N} Symlinked → $link_dir/rin" || \
        echo -e "${Y}▸${N} Symlink skipped (non-fatal)"

    # Export immediately for current session
    export RIN_HOME="$RIN_HOME"
    export PATH="$PATH:$BIN_DIR:$HOME/.bun/bin"
}

# =============================================================================
# Download proxy script
# =============================================================================
get_proxy_script() {
    if [ ! -f "$RIN_HOME/rin-proxy.sh" ]; then
        curl -fsSL -L "https://raw.githubusercontent.com/$RIN_REPO/main/script/rin-proxy.sh" \
          -o "$RIN_HOME/rin-proxy.sh" 2>/dev/null || true
        chmod +x "$RIN_HOME/rin-proxy.sh" 2>/dev/null || true
    fi
}

# =============================================================================
# Main
# =============================================================================
banner

case "${1:-}" in
    --uninstall|-u)
        echo -e "${Y}▸${N} Uninstalling Rin..."
        rm -rf "$RIN_HOME" /tmp/rin_* 2>/dev/null || true
        rm -f /usr/local/bin/rin "$HOME/.local/bin/rin" 2>/dev/null || true
        echo -e "${G}✓${N} Rin removed."
        exit 0
        ;;
    --help|-h)
        echo "Rin AI — Installer"
        echo "Usage: curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/release/install-rin.sh | bash"
        echo "       bash install-rin.sh --uninstall"
        exit 0
        ;;
esac

detect_env
ensure_deps
ensure_bun
ensure_source
create_launcher
get_proxy_script
ensure_path

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}  Rin installed!${N} (${ENV_TYPE} / ${DISTRO})"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo ""
echo -e "  ${G}Run:${N}       ${B}rin${N}"
if ! $IS_CODESPACE; then
    echo -e "  ${Y}New shell:${N} ${B}source ~/.bashrc${N}"
fi
echo ""
