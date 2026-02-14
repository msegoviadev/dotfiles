# Raspberry Pi Infrastructure Automation

Ansible playbook for fully automated Raspberry Pi provisioning with shell environment, dev tools, Tailscale VPN, and OpenCode AI server.

## What Gets Automated

- **System**: Updates, timezone, packages
- **Shell**: Zsh + Oh My Zsh (`half-life` theme, 12 plugins)
- **CLI Tools**: fd, ripgrep, bat, jq, yq, fzf, ast-grep, ncdu, tree
- **Git**: User config (marcos@msegovia.dev)
- **Tailscale**: VPN with MagicDNS + HTTPS certificates
- **OpenCode**: AI server with automatic updates (HTTPS via Tailscale Serve)

## Prerequisites

- **Mac**: Ansible installed (`brew install ansible`)
- **Raspberry Pi**: SSH access configured (`ssh neo` works passwordless)
- **Network**: Internet connectivity on both machines

## Usage

```bash
cd ~/workspace/dotfiles/raspberry-pi

# Full provisioning
ansible-playbook playbook.yml

# Specific roles
ansible-playbook playbook.yml --tags tailscale
ansible-playbook playbook.yml --tags opencode
ansible-playbook playbook.yml --tags zsh,tools

# Check for OpenCode updates
ansible-playbook playbook.yml --tags opencode-update
```

**Runtime**: ~5-10 min first run, ~1-2 min subsequent (idempotent)

## Services & Configuration

### Tailscale VPN
- **Domain**: `neo.lamancha-smoot.ts.net` (MagicDNS)
- **HTTPS**: Auto-managed Let's Encrypt certificates
- **Service**: `tailscale-serve.service` (HTTPS proxy on port 443)
- **Auth**: Manual (SSH to Pi and run `tailscale up` after first install)

### OpenCode AI Server
- **URL**: `https://neo.lamancha-smoot.ts.net/`
- **Port**: 4096 (HTTP, proxied via Tailscale Serve)
- **Service**: `opencode.service`
- **Updates**: Automatic version checking and npm updates
- **User Data**: `/home/marcos/.local/share/opencode/` (never touched by updates)

### Shell (Zsh)
- **Theme**: `half-life` with Tux icon ()
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
system, update, prep    # System configuration
zsh, shell              # Shell environment
tools, cli              # CLI tools
git, config             # Git configuration
tailscale, vpn          # Tailscale VPN + HTTPS
opencode, server        # OpenCode server
opencode-update         # Check/update OpenCode version
verify                  # Post-deployment verification
```

## Post-Install Steps

### 1. Authenticate Tailscale (first time only)
```bash
ssh neo
sudo tailscale up
# Follow the URL to authenticate
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
tailscale_hostname: neo
opencode_port: 4096
zsh_theme: half-life
zsh_prompt_icon: ""
```

Re-run playbook after changes: `ansible-playbook playbook.yml`

## Troubleshooting

```bash
# Test connectivity
ansible raspberry_pi -m ping

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

## Multiple Raspberry Pis

Edit `inventory.ini`:
```ini
[raspberry_pi]
neo ansible_host=neo.local ansible_user=marcos
neo2 ansible_host=neo2.local ansible_user=marcos
```

Run against all: `ansible-playbook playbook.yml`  
Run specific host: `ansible-playbook playbook.yml --limit neo2`

Host-specific config: Create `host_vars/neo2.yml` with overrides

## Maintenance

```bash
# Update system packages
ansible-playbook playbook.yml --tags update

# Update OpenCode
ansible-playbook playbook.yml --tags opencode-update

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
raspberry-pi/
├── ansible.cfg
├── inventory.ini
├── playbook.yml
├── group_vars/all.yml
└── roles/
    ├── system-prep/
    ├── zsh/
    ├── cli-tools/
    ├── git-config/
    ├── tailscale/
    └── opencode-server/
```

## Security

✅ No secrets in repository  
✅ Safe for version control  
✅ Tailscale auth manual (not automated)  
✅ OpenCode API keys stored separately in `~/.local/share/opencode/`

---

**Idempotent** - Safe to run repeatedly without breaking anything
