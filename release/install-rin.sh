#!/bin/bash
# =============================================================================
# Rin AI — Installer / Upgrader
# Supports: Ubuntu, Arch Linux, GitHub Codespaces, Generic VPS
# =============================================================================
# One command:
#   curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/install-rin.sh | bash
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
RIN_VERSION="1.16.2"
RIN_HOME="${RIN_HOME:-$HOME/.rin}"
BIN_DIR="$RIN_HOME/bin"

# =============================================================================
# Detect environment
# =============================================================================
detect_env() {
    ENV_TYPE="generic"
    IS_CODESPACE=false
    IS_ROOT=false
    [ "$(id -u)" = "0" ] && IS_ROOT=true
    if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ] || [ -f "/workspaces/.codespaces" ]; then
        ENV_TYPE="codespace"
        IS_CODESPACE=true
    fi
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        [ "$ENV_TYPE" = "generic" ] && ENV_TYPE="vps"
    else
        DISTRO="unknown"
    fi
    echo -e "${G}▸${N} Environment: ${B}$ENV_TYPE${N} / ${B}$DISTRO${N}"
    $IS_CODESPACE && echo -e "${G}▸${N} GitHub Codespaces detected"
    $IS_ROOT && echo -e "${Y}▸${N} Running as root"
}

# =============================================================================
# Ensure curl exists
# =============================================================================
ensure_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${G}▸${N} Installing curl..."
        if command -v apt-get &>/dev/null; then
            $IS_ROOT && apt-get update -qq && apt-get install -y -qq curl || \
                sudo apt-get update -qq && sudo apt-get install -y -qq curl
        elif command -v pacman &>/dev/null; then
            $IS_ROOT && pacman -Sy --noconfirm curl || sudo pacman -Sy --noconfirm curl
        elif command -v dnf &>/dev/null; then
            $IS_ROOT && dnf install -y curl || sudo dnf install -y curl
        fi
    fi
    echo -e "${G}✓${N} curl ready"
}

# =============================================================================
# Download binary — primary install path
# =============================================================================
download_binary() {
    mkdir -p "$BIN_DIR"

    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in linux) ;; darwin) ;; mingw*|msys*) os="windows" ;; *) os="linux" ;; esac
    arch=$(uname -m)
    case "$arch" in x86_64|amd64) arch="x64" ;; aarch64|arm64) arch="arm64" ;; *) arch="x64" ;; esac

    local url="https://github.com/$RIN_REPO/releases/download/v${RIN_VERSION}/rin-${os}-${arch}.tar.gz"
    echo -e "${G}▸${N} Downloading binary (${os}-${arch})..."

    curl -fsSL -L --connect-timeout 15 --max-time 120 "$url" -o /tmp/rin-bin.tar.gz || {
        echo -e "${Y}▸${N} Binary not available for ${os}-${arch}, trying linux-x64..."
        curl -fsSL -L --connect-timeout 15 --max-time 120 \
            "https://github.com/$RIN_REPO/releases/download/v${RIN_VERSION}/rin-linux-x64.tar.gz" \
            -o /tmp/rin-bin.tar.gz || {
            echo -e "${RED}✖ Binary download failed${N}"
            return 1
        }
    }

    # Extract
    local tmpdir
    tmpdir=$(mktemp -d)
    tar -xzf /tmp/rin-bin.tar.gz -C "$tmpdir" 2>/dev/null
    local binary
    binary=$(find "$tmpdir" -type f -name "rin" 2>/dev/null | head -1)
    if [ -z "$binary" ]; then
        binary=$(find "$tmpdir" -type f 2>/dev/null | head -1)
    fi

    if [ -n "$binary" ] && [ -f "$binary" ]; then
        cp "$binary" "$BIN_DIR/rin"
        chmod +x "$BIN_DIR/rin"
        rm -rf "$tmpdir" /tmp/rin-bin.tar.gz
        echo -e "${G}✓${N} Binary installed: $BIN_DIR/rin ($(du -h "$BIN_DIR/rin" | cut -f1))"
        return 0
    fi

    rm -rf "$tmpdir" /tmp/rin-bin.tar.gz
    echo -e "${RED}✖ No valid binary in archive${N}"
    return 1
}

# =============================================================================
# Add to PATH and symlink
# =============================================================================
ensure_path() {
    # Symlink to /usr/local/bin (or ~/.local/bin)
    local link_dir="/usr/local/bin"
    if [ ! -w "$link_dir" ]; then
        link_dir="$HOME/.local/bin"
        mkdir -p "$link_dir"
    fi
    ln -sf "$BIN_DIR/rin" "$link_dir/rin" 2>/dev/null && \
        echo -e "${G}✓${N} Symlink: $link_dir/rin"

    # Shell config
    local config=""
    case "$(basename "${SHELL:-bash}")" in
        zsh)  config="$HOME/.zshrc" ;;
        fish) config="$HOME/.config/fish/config.fish" ;;
        *)    config="$HOME/.bashrc" ;;
    esac

    if [ -n "$config" ] && ! grep -q "RIN_HOME" "$config" 2>/dev/null; then
        echo "" >> "$config"
        echo "# Rin AI" >> "$config"
        echo "export RIN_HOME=\"$RIN_HOME\"" >> "$config"
        echo "export PATH=\"\$PATH:$BIN_DIR:$HOME/.local/bin\"" >> "$config"
        echo -e "${Y}▸${N} Added to PATH in ${B}$config${N}"
        echo -e "${Y}▸${N} Run: ${B}source $config${N}"
    fi

    export RIN_HOME="$RIN_HOME"
    export PATH="$PATH:$BIN_DIR:$HOME/.local/bin"
}

# =============================================================================
# Auto-fetch proxies
# =============================================================================
fetch_proxies() {
    if command -v rin &>/dev/null || [ -f "$BIN_DIR/rin" ]; then
        local cmd
        cmd="$(command -v rin 2>/dev/null || echo "$BIN_DIR/rin")"
        echo -e "${G}▸${N} Fetching rotating proxies..."
        "$cmd" proxy fetch 200 2>/dev/null || true
    fi
}

# =============================================================================
# Verify installation
# =============================================================================
verify() {
    if command -v rin &>/dev/null || [ -f "$BIN_DIR/rin" ]; then
        local cmd
        cmd="$(command -v rin 2>/dev/null || echo "$BIN_DIR/rin")"
        echo -e "${G}✓${N} Rin version: $($cmd --version 2>/dev/null || echo "$RIN_VERSION")"
        return 0
    fi
    return 1
}

# =============================================================================
# Main
# =============================================================================
banner

case "${1:-}" in
    --uninstall|-u)
        echo -e "${Y}▸${N} Uninstalling Rin..."
        rm -rf "$RIN_HOME" /tmp/rin_* /tmp/rin-bin.tar.gz /tmp/rin-extract 2>/dev/null || true
        rm -f /usr/local/bin/rin "$HOME/.local/bin/rin" 2>/dev/null || true
        echo -e "${G}✓${N} Rin removed."
        exit 0
        ;;
    --help|-h)
        echo "Rin AI — Installer"
        echo "Usage: curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/install-rin.sh | bash"
        echo "       bash install-rin.sh --uninstall"
        exit 0
        ;;
esac

detect_env
ensure_curl

if download_binary; then
    ensure_path
    fetch_proxies
    verify
else
    echo -e "${RED}✖ Installation failed.${N}"
    echo -e "${Y}▸${N} Try: Download manually from https://github.com/$RIN_REPO/releases"
    exit 1
fi

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}  Rin installed!${N}"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo ""
echo -e "  ${G}Run:${N}       ${B}rin${N}"
if ! $IS_CODESPACE; then
    echo -e "  ${Y}New shell:${N} ${B}source ~/.bashrc${N}"
fi
echo ""
