# Auth0 Skill — Setup

## Credentials File

Create one env file per environment at `~/.config/hurl/auth0/<env>.env`.

```bash
mkdir -p ~/.config/hurl/auth0

# Copy the example and name it after your target environment (dev, stage, uat, etc.)
cp <SKILLS_DIR>/auth0/env/default.env.example ~/.config/hurl/auth0/dev.env
chmod 600 ~/.config/hurl/auth0/dev.env
```

Where `<SKILLS_DIR>` is the root skills directory (e.g. `~/workspace/dotfiles/opencode/skills/`).

Repeat for each environment, naming the file accordingly (`stage.env`, `uat.env`, etc.).

## Fill In Credentials

Open the env file and fill in:
- `tenant` — Auth0 tenant base URL (e.g. `https://auth.example.com`)
- `client_id` — Management API client ID
- `client_secret` — Management API client secret
- `resource_server_identifier` — Auth0 Management API audience URL (usually `https://<auth0-domain>/api/v2/`)
- `cacert` — SSL certificate path (`/etc/ssl/cert.pem` on macOS, `/etc/ssl/certs/ca-certificates.crt` on Linux)

The `client_assertion` field is optional. Uncomment and populate it only when using the `private_key_jwt` auth flow.

## Verify Setup

```bash
ENV_FILE=~/.config/hurl/auth0/dev.env
SKILLS_DIR=~/workspace/dotfiles/opencode/skills/auth0

ACCESS_TOKEN=$(hurl --variables-file "$ENV_FILE" "$SKILLS_DIR/templates/get-token.hurl" | jq -r '.access_token')
echo "Token acquired: ${ACCESS_TOKEN:0:20}..."
```
