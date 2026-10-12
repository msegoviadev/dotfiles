---
name: hermes
description: Talk to the Hermes agent that runs on the bee server, the same instance reachable from Telegram. Use when the user asks to message, ask, tell, or check something with Hermes, or to hand a task to Hermes from an OpenCode session. The hermes-bee wrapper sends a one-shot message to Hermes over HTTP and prints the reply.
---

# hermes

Talk to the Hermes agent on bee (the Telegram-connected instance) from this
machine.

## Send a message

```bash
hermes-bee "message text"
printf '%s' "message text" | hermes-bee
```

- Prints only the reply on stdout, exit code 0 on success.
- Each call is a one-shot session, so make the message self-contained.
- Reaches bee over Tailscale by default (`http://bee:8642`).

## How it works

The wrapper posts to the bee API server, an OpenAI-compatible HTTP endpoint on
the `hermes-agent` container, published over Tailscale. The API key is read from
`~/.config/hermes-bee/key`, and the base URL from `HERMES_BEE_URL` (default
`http://bee:8642`). The message is read from stdin, so quotes and special
characters pass through unchanged.

## Notes

- No local Hermes install is needed. The wrapper uses only `curl` and `jq`.
- Override the key with `HERMES_BEE_KEY` or `HERMES_BEE_KEY_FILE`.
- Keep messages self-contained: each call starts a fresh session, though the bee
  agent keeps its own long-term memory.
- The API server gives full tool access, so keep the key private.
