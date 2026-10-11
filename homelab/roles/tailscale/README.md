# Tailscale Role

Installs and configures Tailscale VPN.

## What This Does

- Installs Tailscale on the host
- Enables Tailscale SSH (where `tailscale_ssh_enabled` is true)
- Removes any legacy Tailscale Serve unit and resets the route table

## Architecture

```
Client → WireGuard (tailnet) → host
```

## Manual Steps Required

1. **Authenticate Device**
   ```bash
   ssh neo
   sudo tailscale up --hostname=neo
   # Visit URL to approve
   ```

2. **Enable MagicDNS**
   - Go to https://login.tailscale.com/admin/dns
   - Enable MagicDNS
   - Enable HTTPS certificates (only needed if a host publishes HTTPS)

## Services

- `tailscaled.service` - Tailscale daemon

## Verification

```bash
# Check Tailscale connection
tailscale status

# Check peers
tailscale status

# Check systemd service
sudo systemctl status tailscaled
```
