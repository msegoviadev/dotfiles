# Tailscale Role

Installs and configures Tailscale VPN with HTTPS support for OpenCode.

## What This Does

- Installs Tailscale on Raspberry Pi
- Configures Tailscale Serve to provide HTTPS access
- Creates systemd service for reliability

## Architecture

```
Browser → HTTPS (443) → Tailscale Serve → HTTP (4096) → OpenCode
          [Let's Encrypt cert]
```

## Manual Steps Required

1. **Authenticate Device**
   ```bash
   ssh neo
   sudo tailscale up --hostname=neo
   # Visit URL to approve
   ```

2. **Enable MagicDNS & HTTPS**
   - Go to https://login.tailscale.com/admin/dns
   - Enable MagicDNS
   - Enable HTTPS certificates

3. **Access OpenCode**
   - https://neo.lamancha-smoot.ts.net/

## Services

- `tailscaled.service` - Tailscale daemon
- `tailscale-serve.service` - HTTPS proxy
- `opencode.service` - OpenCode server

## Certificate Management

Certificates are managed automatically by Tailscale:
- Auto-provisioned from Let's Encrypt
- Auto-renewed every 90 days
- No manual management needed

## Verification

```bash
# Check Tailscale connection
tailscale status

# Check Tailscale Serve
tailscale serve status

# Check systemd service
sudo systemctl status tailscale-serve

# Test HTTPS
curl https://neo.lamancha-smoot.ts.net/global/health
```
