---
description: List available skills (global and local)
---

!`echo "=== Global Skills ===" && fd . ~/.config/opencode/skill/ --max-depth 1 --type d --exec basename {} 2>/dev/null | grep -v "^skill$" || echo "(none)"; echo ""; echo "=== Local Skills ===" && fd . .opencode/skill/ --max-depth 1 --type d --exec basename {} 2>/dev/null | grep -v "^skill$" || echo "(none)"`

Just list the skill names above. No further action needed.
