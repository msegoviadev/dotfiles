# Confluence Skill — Setup

## Credentials File

```bash
mkdir -p ~/.config/hurl/confluence
cp <SKILLS_DIR>/confluence/env/default.env.example ~/.config/hurl/confluence/default.env
chmod 600 ~/.config/hurl/confluence/default.env
```

Fill in `email`, `token`, `base_url_confluence`, and `cacert` in the file.
Get your API token from https://id.atlassian.com/manage-profile/security/api-tokens

Where `<SKILLS_DIR>` is the root skills directory (e.g., `~/.config/opencode/skills/` for opencode, `~/.claude/skills/` for claude-code).
