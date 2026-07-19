# Homelab Infrastructure Automation

Ansible playbook for provisioning homelab servers (Raspberry Pi, Beelink, etc.) with shell environment, dev tools, Tailscale VPN, and optional services like OpenCode AI server and Coolify.

## What Gets Automated

- **System**: Updates, timezone, packages
- **Shell**: Zsh + Oh My Zsh (`half-life` theme, 12 plugins)
- **CLI Tools**: fd, ripgrep, bat, jq, yq, fzf, ast-grep, ncdu, tree
- **Git**: User config (marcos@msegovia.dev)
- **Tailscale**: VPN with MagicDNS + HTTPS certificates
- **OpenCode** (optional, on `neo`): AI server with automatic updates (HTTPS via Tailscale Serve)

## Current Servers

- **neo**: Raspberry Pi — Coolify control plane, OpenCode server, Deutsch app, Cloudflare tunnel
- **bee**: Beelink MINI-S13 — Coolify worker/destination server

## Prerequisites

- **Mac**: Ansible installed (`brew install ansible`)
- **Servers**: SSH access configured (`ssh neo` and `ssh bee` work passwordless)
- **Network**: Internet connectivity on all machines

## Usage

```bash
cd ~/workspace/dotfiles/homelab

# Full provisioning
ansible-playbook playbook.yml

# Specific roles
ansible-playbook playbook.yml --tags tailscale
ansible-playbook playbook.yml --tags opencode
ansible-playbook playbook.yml --tags zsh,tools

# Check for OpenCode updates
ansible-playbook playbook.yml --tags opencode-update

# Provision a single server
ansible-playbook playbook.yml --limit bee
```

**Runtime**: ~5-10 min first run, ~1-2 min subsequent (idempotent)

## Services & Configuration

### Tailscale VPN
- **MagicDNS**: `neo.lamancha-smoot.ts.net`, `bee.lamancha-smoot.ts.net`
- **HTTPS**: Auto-managed Let's Encrypt certificates
- **Service**: `tailscale-serve.service` (HTTPS proxy on port 443, only where `tailscale_serve_enabled: true`, i.e. neo)
- **Auth**: Manual (SSH to server and run `sudo tailscale up` after first install)

### OpenCode AI Server (on `neo`)
- **URL**: `https://neo.lamancha-smoot.ts.net/`
- **Port**: 4096 (HTTP, proxied via Tailscale Serve)
- **Service**: `opencode.service`
- **Updates**: Automatic version checking and npm updates
- **User Data**: `/home/marcos/.local/share/opencode/` (never touched by updates)

### Shell (Zsh)
- **Theme**: `half-life` with Tux icon
- **Plugins**: git, docker, sudo, fzf, zsh-autosuggestions, zsh-syntax-highlighting, systemd, extract, history-substring-search, command-not-found, aliases
- **History**: 10k commands, shared sessions, deduplicated

### CLI Tools
fd, ripgrep, bat, jq, yq, fzf, ncdu, tree, ast-grep

### Git
```
user.name = marcos
user.email = marcos@msegovia.dev
init.defaultBranch = main
```

## Available Tags

```bash
system, prep             # System configuration
update                   # Update everything (system packages, zsh, cli-tools, tailscale, opencode)
zsh, shell              # Shell environment
tools, cli              # CLI tools installation
git, config             # Git configuration
tailscale, vpn          # Tailscale VPN + HTTPS
opencode, server        # OpenCode server (full install)
coolify-worker-ssh      # Worker: authorize Coolify root SSH key (run before adding server in Coolify)
coolify-worker-proxy    # Worker: Traefik override + Keycloak admin block (run after adding server in Coolify)

# Update-specific tags (only update tasks, no install/setup)
opencode-update         # Check/update OpenCode version
tailscale-update        # Check/update Tailscale version
cli-update              # Update CLI tools (nvm, node, yq, ast-grep, rtk)
zsh-update              # Update Oh My Zsh + plugins
verify                  # Post-deployment verification
```

## Post-Install Steps

### 1. Authenticate Tailscale (first time only)
```bash
ssh neo
sudo tailscale up
# or for bee
ssh bee
sudo tailscale up --hostname=bee
```

### 2. Access OpenCode
Open `https://neo.lamancha-smoot.ts.net/` in your browser (must be on Tailscale network)

### 3. Verify Services
```bash
ssh neo
systemctl status opencode tailscale-serve
```

## Customization

Edit `group_vars/all.yml` for configuration:

```yaml
ansible_user: marcos
timezone: Europe/Zurich
git_user_email: marcos@msegovia.dev
opencode_port: 4096
zsh_theme: half-life
zsh_prompt_icon: ""
```

Host-specific overrides and secrets go in `host_vars/<hostname>.yml` (e.g., `host_vars/neo.yml`, `host_vars/bee.yml`). These files are gitignored. Use the corresponding `host_vars/<hostname>.yml.example` files as templates.

### Optional services per host

The following flags control which optional roles run on each host:

```yaml
# host_vars/neo.yml example
tailscale_hostname: neo
opencode_server_install: true
deutsch_app_install: true
coolify_server_install: true
cloudflare_tunnel_install: true
```

For `bee`, only the essentials plus the Coolify worker setup run:

```yaml
# host_vars/bee.yml example
tailscale_hostname: bee
coolify_worker_install: true
# All other optional service flags default to false
```

Re-run playbook after changes: `ansible-playbook playbook.yml`

## Troubleshooting

```bash
# Test connectivity
ansible servers -m ping

# Verbose output
ansible-playbook playbook.yml -vvv

# Check services
ssh neo
systemctl status opencode tailscale-serve

# View logs
journalctl -u opencode -f
journalctl -u tailscale-serve -f

# OpenCode not accessible
# 1. Verify Tailscale is connected: tailscale status
# 2. Check OpenCode is running: curl http://localhost:4096
# 3. Ensure you're on Tailscale network
```

## Multiple Servers

Edit `inventory.ini`:
```ini
[servers]
neo ansible_host=neo.local ansible_user=marcos
bee ansible_host=bee.local ansible_user=marcos
```

Run against all: `ansible-playbook playbook.yml`  
Run specific host: `ansible-playbook playbook.yml --limit bee`

Host-specific config: Create `host_vars/<hostname>.yml` with overrides

## Maintenance

```bash
# Update everything (system packages + all software)
ansible-playbook playbook.yml --tags update

# Update individual components
ansible-playbook playbook.yml --tags opencode-update
ansible-playbook playbook.yml --tags tailscale-update
ansible-playbook playbook.yml --tags cli-update
ansible-playbook playbook.yml --tags zsh-update

# Full re-provision (idempotent)
ansible-playbook playbook.yml
```

OpenCode user data is never touched by updates (lives in `~/.local/share/opencode/`)

## Architecture

```
Browser (Mac)
    ↓ HTTPS (Tailscale VPN)
Tailscale Serve (port 443, TLS termination)
    ↓ HTTP (localhost)
OpenCode Server (port 4096)
```

Services:
- `tailscaled.service` - Tailscale daemon
- `tailscale-serve.service` - HTTPS proxy
- `opencode.service` - AI server

## Structure

```
homelab/
├── ansible.cfg
├── inventory.ini
├── playbook.yml
├── group_vars/all.yml
├── host_vars/
│   ├── neo.yml
│   └── bee.yml
└── roles/
    ├── system-prep/
    ├── firewall/
    ├── zsh/
    ├── cli-tools/
    ├── git-config/
    ├── tailscale/
    ├── opencode-server/
    ├── coolify-server/
    ├── coolify-worker/
    └── cloudflare-tunnel/
```

## Security

✅ No secrets in repository  
✅ Safe for version control  
✅ Tailscale auth manual (not automated)  
✅ OpenCode API keys stored separately in `~/.local/share/opencode/`

---

**Idempotent** - Safe to run repeatedly without breaking anything

**Not committed or pushed** - pending your approval.
