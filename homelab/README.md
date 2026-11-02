# Homelab Infrastructure Automation

Ansible playbook for provisioning homelab servers (Raspberry Pi, Beelink, etc.) with shell environment, dev tools, Tailscale VPN, and optional services like the Coolify control plane and a Cloudflare tunnel.

## What Gets Automated

- **System**: Updates, timezone, packages
- **Shell**: Zsh + Oh My Zsh (`half-life` theme, plugin list empty by default)
- **CLI Tools**: fd, ripgrep, bat, jq, yq, fzf, ast-grep, ncdu, tree
- **Git**: User config (marcos@msegovia.dev)
- **Tailscale**: VPN with MagicDNS + Tailscale SSH
- **Security**: unattended-upgrades for Debian security, Raspberry Pi, and Docker updates
- **Coolify** (optional): control plane on `neo`, worker on `bee`
- **Cloudflare tunnel** (optional, on `neo`): outbound tunnel from the Cloudflare apt repository

## Current Servers

- **neo**: Raspberry Pi, Coolify control plane, Cloudflare tunnel
- **bee**: Beelink MINI-S13, Coolify worker and application host

## Prerequisites

- **Laptop**: Ansible installed. macOS uses `brew install ansible`. Arch uses `pacman -S ansible`, or install `ansible-core` and run `ansible-galaxy collection install -r collections/requirements.yml`.
- **Key**: The inventory uses `~/.ssh/id_ed25519_homelab`. Adjust it in `inventory.ini` if your key differs.
- **Host variables**: Copy `host_vars/<hostname>.yml.example` to `host_vars/<hostname>.yml` before the first run. The files are gitignored.
- **Servers**: Passwordless SSH to both hosts, and internet connectivity.

## Usage

```bash
cd ~/workspace/dotfiles/homelab

# Full provisioning
ansible-playbook playbook.yml

# Specific roles
ansible-playbook playbook.yml --tags tailscale
ansible-playbook playbook.yml --tags coolify
ansible-playbook playbook.yml --tags zsh,tools
ansible-playbook playbook.yml --tags verify

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
- Installed from the Cloudflare apt repository. Update it with `--tags cloudflare-update` or `--tags update`
- The tunnel is token-based, so the ingress rules live in the Cloudflare dashboard. The local `config.yml` is a copy and does not override the dashboard
- The ingress list in `group_vars/all.yml` documents the intended hostnames and targets `bee_lan_ip:8080`
- DNS CNAMEs are created manually in the Cloudflare dashboard
- Ansible management is off by default (`cloudflare_tunnel_install: false`). Set it to true and add `cloudflare_tunnel_token` only if Ansible should own the service unit

### Hermes (on `bee`)
- Agent API: Tailscale Serve publishes TCP 8642 on the tailnet and forwards to `127.0.0.1:8642` on bee
- The laptop wrapper `hermes-bee` uses `http://bee:8642` and the key in `~/.config/hermes-bee/key`
- Images: `nousresearch/hermes-agent` and `ghcr.io/nesquena/hermes-webui`
- The agent code lives in the `hermes-agent-src` volume. After an image update, recreate that volume from the new image, or the old code keeps running
- Job data lives in `/opt/data`, backed by the named volume `kdemakw5hk97ujuq7w0dijk6_hermes-data`. Never use an anonymous volume for this path
- Use `docker compose stop` and `up -d` for this service. Do not use `down`, because Docker detaches anonymous volumes
- The `hermes-data-backup.timer` archives `job-search` and `cv-build` to `/var/backups/hermes` at 07:30 each day and keeps 14 days
- Keep the Tailscale Serve target on the published host port, not the container IP, because the container IP changes on recreate
- Keep `tailscale_serve_reset: false` to preserve the API mapping

### Shell (Zsh)
- **Theme**: `half-life` with Tux icon
- **Plugins**: none by default. `zsh_plugins` is an empty list, so the two plugin repositories are cloned but not loaded. Add names to `zsh_plugins` in `group_vars/all.yml` to enable them.
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
update                   # Update everything (system packages, zsh, cli-tools, tailscale, cloudflared)
security, updates        # unattended-upgrades configuration
zsh, shell              # Shell environment
tools, cli              # CLI tools installation
git, config             # Git configuration
tailscale, vpn          # Tailscale VPN
coolify, server         # Coolify control plane
coolify, worker         # Coolify worker
coolify-worker-ssh      # Worker: authorize Coolify root SSH key (run before adding server in Coolify)
coolify-worker-proxy    # Worker: Traefik override + Keycloak admin block (run after adding server in Coolify)
cloudflare, tunnel      # Cloudflare tunnel
verify                  # Read-only post-patch verification report

# Update-specific tags (only update tasks, no install/setup)
tailscale-update        # Check/update Tailscale version
cli-update              # Update CLI tools (yq, ast-grep, rtk)
zsh-update              # Update Oh My Zsh + plugins
cloudflare-update       # Update cloudflared
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
systemctl status cloudflared

ssh bee
systemctl status tailscaled
```

### 3. Confirm automatic security updates
```bash
ssh neo 'systemctl is-active unattended-upgrades; unattended-upgrade --dry-run'
ssh bee 'systemctl is-active unattended-upgrades; unattended-upgrade --dry-run'
```

Automatic reboot is off by default. A kernel update stays pending until the next reboot. Set `unattended_upgrades_auto_reboot: true` in `group_vars/all.yml` to reboot at 04:00.

## Customization

Edit `group_vars/all.yml` for configuration:

```yaml
ansible_user: marcos
timezone: Europe/Zurich
git_user_email: marcos@msegovia.dev
zsh_theme: half-life
zsh_prompt_icon: ""
unattended_upgrades_enabled: true
unattended_upgrades_auto_reboot: false
```

Host-specific overrides and secrets go in `host_vars/<hostname>.yml` (e.g., `host_vars/neo.yml`, `host_vars/bee.yml`). These files are gitignored. Use the corresponding `host_vars/<hostname>.yml.example` files as templates.

### Optional services per host

The following flags control which optional roles run on each host:

```yaml
# host_vars/neo.yml example
tailscale_hostname: neo
coolify_server_install: true
cloudflare_tunnel_install: false
# cloudflare_tunnel_token: "<token from the Cloudflare dashboard>"
```

Set `cloudflare_tunnel_install` to true only when Ansible should manage the tunnel service unit. The tunnel already updates through apt without that role.

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
ansible-playbook playbook.yml --tags cloudflare-update

# Apply the security update configuration
ansible-playbook playbook.yml --tags security

# Report the post-patch state
ansible-playbook playbook.yml --tags verify

# Full re-provision (idempotent)
ansible-playbook playbook.yml
```

After a kernel update, make sure that `/var/run/reboot-required` is absent or reboot the host. The `verify` tag reports the flag.

Container images are not part of the playbook. Update them in the Coolify dashboard, one resource at a time, and take a database dump first.

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
    ├── unattended-upgrades/
    ├── zsh/
    ├── cli-tools/
    ├── git-config/
    ├── docker/
    ├── tailscale/
    ├── coolify-server/
    ├── coolify-worker/
    ├── cloudflare-tunnel/
    └── verify/
```

## Security

- No secrets in the repository. Host secrets live in gitignored `host_vars/`.
- Password login is disabled on both hosts. SSH uses keys only.
- UFW blocks inbound traffic except the home LAN and the Tailscale interface.
- unattended-upgrades applies Debian security, Raspberry Pi, and Docker updates.
- Tailscale authentication is manual.
- The cloudflared service unit contains the tunnel token. The role marks the install task `no_log`.

## Patching

The full patch procedure is in `/home/marcos/.opencode/plan/homelab-patching.md`. It covers backups, OS patches, reboots, the tunnel update, container updates, and rollback.

---

**Idempotent** - Configuration is safe to run repeatedly. Package and image updates run only when a newer version exists.
