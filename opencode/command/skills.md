---
description: List available skills (global and local)
---

!`echo "=== Global Skills ===" && fd . ~/.config/opencode/skills/ --max-depth 1 --type f --exec basename {} 2>/dev/null || echo "(none)"; echo ""; echo "=== Local Skills ===" && fd . .opencode/skills/ --max-depth 1 --type f --exec basename {} 2>/dev/null || echo "(none)"`

Just list the skill names above. No further action needed.
