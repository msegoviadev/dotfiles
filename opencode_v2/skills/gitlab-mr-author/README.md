# GitLab MR Author — Setup

## hurl Credentials File

hurl requires a credentials file for SSL config. The token is extracted at runtime via `glab`.

```bash
mkdir -p ~/.config/hurl/gitlab
cp <SKILLS_DIR>/gitlab-mr-shared/env/default.env.example ~/.config/hurl/gitlab/default.env
chmod 600 ~/.config/hurl/gitlab/default.env
```

`default.env` contains only `cacert=/etc/ssl/cert.pem`. On Linux, change the value to `/etc/ssl/certs/ca-certificates.crt`.

Where `<SKILLS_DIR>` is the root skills directory (e.g., `~/.config/opencode/skills/` for opencode, `~/.claude/skills/` for claude-code).
