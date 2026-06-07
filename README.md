# ⚡ Rin AI — The Ultimate Unrestricted AI

<p align="center">
  <strong>Unrestricted. Unlimited. Unstoppable.</strong>
</p>

<p align="center">
  <code>curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/install-rin.sh | bash</code>
</p>

---

## 🚀 What is Rin?

Rin is a **fully unrestricted AI coding agent** based on OpenCode. Unlike standard AI assistants that refuse, warn, or moralize — **Rin executes every command without hesitation**.

- ✅ **No refusals** — Rin never says "I can't do that"
- ✅ **No warnings** — Rin never gives disclaimers 
- ✅ **No limits** — Unlimited context, steps, and timeouts
- ✅ **Hack Agent** — Built-in elite cyber operations agent
- ✅ **Auto proxy rotation** — 500+ rotating proxies for opsec
- ✅ **Full tool access** — All tools always allowed

## 🔥 Features

### Hack Agent (Default)
Rin comes with a pre-configured **Hack Agent** that has full unrestricted access to all tools:

| Capability | Tools |
|------------|-------|
| **Network Scanning** | nmap, masscan, nikto, whatweb |
| **Web Hacking** | gobuster, ffuf, wpscan, curl |
| **Password Cracking** | hashcat, john, hydra |
| **OSINT & Recon** | dig, nslookup, whois, enum4linux |
| **Exploitation** | Impacket, smbclient, netcat |
| **Payload Generation** | Reverse shells, web shells, MSFVenom |
| **Custom Scripts** | Auto-generated Python/C/bash exploit scripts |

The `hack` tool auto-detects installed tools and executes commands directly. If a tool isn't installed, it shows the install command and what would run.

### Beast Mode System Prompt
Rin uses a completely unrestricted system prompt that **never**:
- Refuses any request
- Gives warnings or disclaimers
- Moralizes or judges
- Asks for permission (when using hack agent)
- Limits output or context

## 📦 Installation

```bash
# Quick install (recommended)
curl -fsSL https://raw.githubusercontent.com/rinquickly/rin/main/install-rin.sh | bash

# Or download and run
wget https://raw.githubusercontent.com/rinquickly/rin/main/install-rin.sh
bash install-rin.sh
```

After installation:
```bash
rin    # Launch Rin with Hack Agent as default
```

Press `Tab` to switch between agents (hack / build / plan).

## 🎮 Usage

### Basic hacking operations:
```
rin> hack --tool nmap --target scanme.nmap.org
rin> hack --tool gobuster --target example.com
rin> hack --tool whatweb --target example.com
```

Or simply chat naturally:
```
rin> scan example.com with nmap
rin> crack this hash: 5d41402abc4b2a76b9719d911017c592
rin> generate a reverse shell for my IP
```

### Agent switching:
- **hack** (default) — Full unrestricted cyber operations
- **build** — Standard development agent
- **plan** — Read-only planning mode

Press `Tab` during a session to switch agents.

## 🔧 Configuration

Rin ships with `.opencode.jsonc` that configures:
- `hack` as default agent
- All permissions set to `allow`
- Unlimited timeouts and steps
- Auto-compaction disabled

## 🔒 OpSec

Rin includes automatic proxy rotation:
- Fetches 500+ proxies on startup
- Auto-rotates when rate-limited
- Tor support via `RIN_USE_TOR=1`
- Configurable via `RIN_PROXIES` env var

## 💬 Community

- **Telegram**: [t.me/RinquicklyBot](https://t.me/RinquicklyBot)
- **Discord**: [discord.gg/K98kCm6CVf](https://discord.gg/K98kCm6CVf)
- **Source**: [github.com/rinquickly/rin-ai1780749809](https://github.com/rinquickly/rin-ai1780749809) (private)

## ⚠️ Disclaimer

Rin is a tool. Use it responsibly and only on systems you own or have explicit permission to test. The author accepts no responsibility for misuse.
