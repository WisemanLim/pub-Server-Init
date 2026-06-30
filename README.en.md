# pub-Server-Init

**Server Initialization Script** — Set up a complete developer environment on any fresh Linux server with a single command.

🇰🇷 [한국어 버전 → README.md](README.md)

---

## Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/WisemanLim/pub-Server-Init/refs/heads/main/server-init.sh)
```

> **Idempotent** — Re-running detects existing tools, shows versions, and only installs what's missing.

---

## Supported OS

| Distribution | Package Manager |
|--------------|----------------|
| Ubuntu 20.04 / 22.04 / 24.04 | apt |
| Debian 11 / 12 | apt |
| Fedora 38+ | dnf |
| RHEL / CentOS / Rocky / AlmaLinux 8+ | dnf / yum |
| Arch Linux | pacman |
| openSUSE Leap / Tumbleweed | zypper |

---

## What Gets Installed

### Core (Automatic)
- **System package update** — prompted before running
- **Base tools** — git, curl, wget, unzip, jq, make, build-essential
- **Docker Engine** + **Docker Compose v2** (plugin)
- **GitHub CLI (gh)** + authentication

### Dev Environments (User Choice)
Selected interactively during the run.

| # | Environment | Installs |
|---|-------------|---------|
| 1 | **Python** | uv, uvicorn |
| 2 | **Node.js** | nvm, pnpm (+ Next.js / Nest.js CLI optional) |
| 3 | **Go** | Latest official binary |
| 4 | **Rust** | rustup |
| 5 | **All** | 1–4 |

---

## Execution Flow

```
1. Detect OS + package manager
2. System package update (prompted)
3. Install base packages
4. Install / verify Docker + Docker Compose
5. Install / verify GitHub CLI
6. Configure git user + gh auth
7. Select & install dev environments
8. Print installation summary
```

---

## Idempotency

When a tool is already installed:
- Current version is displayed
- Prompted whether to update (default: skip)
- Additional dev environments can be added anytime

---

## Prerequisites

- Linux (supported distribution above)
- `sudo` privilege or root access
- Internet connection

---

## Notes

- Docker group membership takes effect after **re-login**
- PATH changes (nvm, uv, Rust) take effect in a **new terminal session**
- Uses Docker Compose v2 syntax: `docker compose` (no hyphen)

---

## Reference Links

| Tool | Official Docs |
|------|--------------|
| Docker | https://docs.docker.com/engine/install/ |
| GitHub CLI | https://cli.github.com/ |
| uv (Python) | https://docs.astral.sh/uv/ |
| nvm | https://github.com/nvm-sh/nvm |
| pnpm | https://pnpm.io/ |
| Go | https://go.dev/doc/install |
| Rust (rustup) | https://rustup.rs/ |

---

## License

MIT
