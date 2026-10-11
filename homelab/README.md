# Homelab Infrastructure Automation

Ansible playbook for provisioning homelab servers (Raspberry Pi, Beelink, etc.) with shell environment, dev tools, Tailscale VPN, and optional services like the Coolify control plane and a Cloudflare tunnel.

## What Gets Automated

- **System**: Updates, timezone, packages
- **Shell**: Zsh + Oh My Zsh (`half-life` theme, 12 plugins)
- **CLI Tools**: fd, ripgrep, bat, jq, yq, fzf, ast-grep, ncdu, tree
- **Git**: User config (marcos@msegovia.dev)
- **Tailscale**: VPN with MagicDNS + Tailscale SSH
- **Coolify** (optional): control plane on `neo`, worker on `bee`
- **Cloudflare tunnel** (optional, on `neo`): outbound tunnel for public hostnames

## Current Servers

- **neo**: Raspberry Pi — Coolify control plane, Cloudflare tunnel
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
ansible-playbook playbook.yml --tags coolify
ansible-playbook playbook.yml --tags zsh,tools

# Provision a single server
ansible-playbook playbook.yml --limit bee
```

**Runtime**: ~5-10 min first run, ~1-2 min subsequent (idempotent)

## Services & Configuration

### Tailscale VPN
- **MagicDNS**: `neo.lamancha-smoot.ts.net`, `bee.lamancha-smoot.ts.net`
- **SSH**: Tailscale SSH (`tailscale_ssh_enabled: true`), no port-22 rule needed on the tailnet
- **Auth**: Manual (SSH to server and run `sudo tailscale up` after first install)

### Coolify
- **Control plane** (on `neo`): dashboard on `neo_lan_ip:8000`, Traefik proxy on `127.0.0.1:8080` (HTTP) and `127.0.0.1:8081` (admin, SSH-forward only)
- **Worker** (on `bee`): Traefik on `bee_lan_ip:8080` (LAN), admin on `127.0.0.1:8081`
- **Onboarding**: run `--tags coolify-worker-ssh` before adding the server in Coolify, then `--tags coolify-worker-proxy` after

### Cloudflare Tunnel (on `neo`)
- Outbound-only connector; no inbound port is opened
- Ingress list lives in `group_vars/all.yml` and targets `bee_lan_ip:8080`
- DNS CNAMEs are created manually in the Cloudflare dashboard

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
update                   # Update everything (system packages, zsh, cli-tools, tailscale)
zsh, shell              # Shell environment
tools, cli              # CLI tools installation
git, config             # Git configuration
tailscale, vpn          # Tailscale VPN
coolify, server         # Coolify control plane
coolify, worker         # Coolify worker
coolify-worker-ssh      # Worker: authorize Coolify root SSH key (run before adding server in Coolify)
coolify-worker-proxy    # Worker: Traefik override + Keycloak admin block (run after adding server in Coolify)
cloudflare, tunnel      # Cloudflare tunnel

# Update-specific tags (only update tasks, no install/setup)
tailscale-update        # Check/update Tailscale version
cli-update              # Update CLI tools (yq, ast-grep, rtk)
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

### 2. Verify Services
```bash
ssh neo
systemctl status tailscaled

ssh bee
systemctl status tailscaled
```

## Customization

Edit `group_vars/all.yml` for configuration:

```yaml
ansible_user: marcos
timezone: Europe/Zurich
git_user_email: marcos@msegovia.dev
zsh_theme: half-life
zsh_prompt_icon: ""
```

Host-specific overrides and secrets go in `host_vars/<hostname>.yml` (e.g., `host_vars/neo.yml`, `host_vars/bee.yml`). These files are gitignored. Use the corresponding `host_vars/<hostname>.yml.example` files as templates.

### Optional services per host

The following flags control which optional roles run on each host:

```yaml
# host_vars/neo.yml example
tailscale_hostname: neo
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
systemctl status tailscaled
journalctl -u cloudflared -f
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
ansible-playbook playbook.yml --tags tailscale-update
ansible-playbook playbook.yml --tags cli-update
ansible-playbook playbook.yml --tags zsh-update

# Full re-provision (idempotent)
ansible-playbook playbook.yml
```

## Architecture

```
Mac / clients
    ├── LAN            → neo (Coolify dashboard, 8000), bee (Traefik, 8080)
    ├── Tailscale VPN  → SSH to neo and bee
    └── Internet       → Cloudflare edge → cloudflared on neo → Traefik on bee
```

Services:
- `tailscaled.service` - Tailscale daemon (both hosts)
- `cloudflared.service` - outbound tunnel (neo)
- Coolify Compose stack - dashboard, proxy, realtime (neo) and apps (bee)

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
    ├── docker/
    ├── tailscale/
    ├── coolify-server/
    ├── coolify-worker/
    └── cloudflare-tunnel/
```

## Security

✅ No secrets in repository  
✅ Safe for version control  
✅ Tailscale auth manual (not automated)

---

**Idempotent** - Safe to run repeatedly without breaking anything
