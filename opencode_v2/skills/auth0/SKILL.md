---
name: auth0
description: Query and manage Auth0 tenant resources via the Management API v2. Use when working with Auth0 clients, client grants, credentials, resource servers, or signing keys.
metadata:
  tags: auth0, management-api, hurl, clients, grants, credentials
---

## When to Use

Use this skill when:
- User wants to list, get, create, update, or delete Auth0 clients
- User wants to manage client grants (audiences and scopes)
- User wants to manage client credentials (public key or certificate)
- User wants to inspect resource servers (APIs) and their scopes
- User wants to inspect tenant signing keys
- User references an Auth0 tenant management operation or URL containing `auth0.com`

## Prerequisites

- `hurl` installed: `brew install hurl`
- `jq` installed: `brew install jq`
- `node >= 18` installed (required for the `private_key_jwt` assertion flow)
- Target environment known (default: `dev`)

---

## Workflow

### Step 1: Confirm Setup

Check whether the env file exists for the target environment:

```bash
ls ~/.config/hurl/auth0/<env>.env
```

If missing, scaffold it and prompt the user to fill in their credentials:

```bash
SKILLS_DIR=<path-to-this-skill-directory>
mkdir -p ~/.config/hurl/auth0
cp "$SKILLS_DIR/env/default.env.example" ~/.config/hurl/auth0/<env>.env
chmod 600 ~/.config/hurl/auth0/<env>.env
```

Then open `~/.config/hurl/auth0/<env>.env` and fill in the fields for the auth flow you are using:

**client_credentials flow:**
- `tenant` — Auth0 tenant base URL (e.g. `https://auth.example.com`)
- `client_id` — Management API client ID
- `client_secret` — Management API client secret
- `resource_server_identifier` — Auth0 Management API audience URL (usually `https://<auth0-domain>/api/v2/`)
- `cacert` — SSL certificate path (`/etc/ssl/cert.pem` on macOS, `/etc/ssl/certs/ca-certificates.crt` on Linux)

**private_key_jwt flow** (uncomment and fill in instead of `client_secret`):
- `private_key_path` — absolute path to the PEM private key file
- `auth0_kid` — key ID registered in Auth0
- `auth0_client_id` — client ID that uses private key JWT auth
- `audience` — tenant URL used as JWT `aud` (e.g. `https://auth.dev.example.com/`)

---

### Step 2: Get Access Token

Read the env file to detect the auth flow, then obtain the token:

```bash
ENV_FILE=~/.config/hurl/auth0/<env>.env
SKILLS_DIR=<path-to-this-skill-directory>

PRIVATE_KEY_PATH=$(grep '^private_key_path=' "$ENV_FILE" | cut -d= -f2-)

if [[ -n "$PRIVATE_KEY_PATH" ]]; then
  # private_key_jwt flow: auto-generate the assertion then exchange it for a token
  AUTH0_KID=$(grep '^auth0_kid=' "$ENV_FILE" | cut -d= -f2-)
  AUTH0_CLIENT_ID=$(grep '^auth0_client_id=' "$ENV_FILE" | cut -d= -f2-)
  AUDIENCE=$(grep '^audience=' "$ENV_FILE" | cut -d= -f2-)

  CLIENT_ASSERTION=$(PRIVATE_KEY_PATH="$PRIVATE_KEY_PATH" \
    AUTH0_KID="$AUTH0_KID" \
    AUTH0_CLIENT_ID="$AUTH0_CLIENT_ID" \
    AUDIENCE="$AUDIENCE" \
    node "$SKILLS_DIR/scripts/generate-assertion.mjs")

  ACCESS_TOKEN=$(hurl --variables-file "$ENV_FILE" \
    --variable client_assertion="$CLIENT_ASSERTION" \
    "$SKILLS_DIR/templates/get-token-assertion.hurl" | jq -r '.access_token')
else
  # client_credentials flow
  ACCESS_TOKEN=$(hurl --variables-file "$ENV_FILE" \
    "$SKILLS_DIR/templates/get-token.hurl" | jq -r '.access_token')
fi
```

Verify the token is not empty before proceeding.

---

### Step 3: Identify Operation

Match the user's intent to a template:

| Operation | Template |
|---|---|
| List clients | `get-clients.hurl` |
| Get client by ID | `get-client.hurl` |
| Create client | `create-client.hurl` |
| Update client (metadata, credentials, etc.) | `update-client.hurl` |
| Delete client | `delete-client.hurl` |
| List client credentials | `get-client-credentials.hurl` |
| Add credential to client | `add-client-credential.hurl` |
| Update client credential | `update-client-credential.hurl` |
| Delete client credential | `delete-client-credential.hurl` |
| Get client grants | `get-client-grants.hurl` |
| Create client grant | `create-client-grant.hurl` |
| Update client grant scopes | `update-client-grant.hurl` |
| Delete client grant | `delete-client-grant.hurl` |
| List resource servers | `get-resource-servers.hurl` |
| Get signing keys | `get-signing-keys.hurl` |

---

### Step 4: Construct Variables and Body

**Read operations**: identify the required `{{variable}}` placeholders from the template (e.g. `{{client_id_target}}`, `{{grant_id}}`).

**Write operations** (POST / PATCH):
1. Build the JSON body based on the user's intent and the API shape in `references/api-commands.md`
2. **Show the full JSON body to the user and get explicit approval before proceeding**
3. Write the approved body to a temp file:

```bash
cat > "$TMPDIR/auth0-body.json" << 'EOF'
{
  "name": "example-client",
  "app_type": "non_interactive"
}
EOF
```

---

### Step 5: Execute

```bash
# Read operation
hurl --variables-file "$ENV_FILE" \
     --variable access_token="$ACCESS_TOKEN" \
     --variable client_id_target="<id>" \
     "$SKILLS_DIR/templates/get-client.hurl" | jq .

# Write operation
hurl --variables-file "$ENV_FILE" \
     --variable access_token="$ACCESS_TOKEN" \
     --variable body_file="$TMPDIR/auth0-body.json" \
     "$SKILLS_DIR/templates/create-client.hurl" | jq .
```

---

### Step 6: Present Output

Format with `jq`. For list responses, extract the relevant fields:

```bash
| jq '[.[] | {client_id, name, app_type}]'
```

---

## Safety Rules

- Never execute POST, PATCH, or DELETE without showing the payload and getting explicit user approval
- Never delete a client, credential, or grant without a separate confirmation step
- Prefer reading the resource first to confirm it exists before mutating or deleting it

---

## Environment Switching

Pass a different env file to target another environment:

```bash
--variables-file ~/.config/hurl/auth0/stage.env
--variables-file ~/.config/hurl/auth0/uat.env
```

---

## See Also

- `references/api-commands.md` — full endpoint reference with hurl examples
