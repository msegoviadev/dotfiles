- **Language:** English only - all code, comments, docs, examples, commits, configs, errors, tests

## Style Guidelines
- Prefer self-documenting code over comments
- Don't use em dashes (—). Use commas, parentheses, or separate sentences instead.

## Git/Commit Guidelines
- Never add "Claude" or any AI assistant as a co-author in git commits
- Keep commit messages succinct, providing a summary of functionality or changes rather than bullet-pointing each specific detail

## Symlinks
When editing any file, always resolve symlinks first and write to the original source file, never to the symlink path itself.

## Tooling for shell interactions

IMPORTANT, always consider the following rules:
- Is it about finding FILES? use 'fd'
- Is it about finding TEXT/strings? use 'rg'
- Is it about finding CODE STRUCTURE? use 'ast-grep'
- Is it about SELECTING from multiple results? pipe to 'fzf'
- Is it about interacting with JSON? use 'jq'.

> **CRITICAL jq rule — never break this:** The Bash tool escapes `!` to `\!`, which breaks `!=` in jq filters. NEVER write `select(.field != null)` or any `!=` expression inline. Always use `select(.field)` instead (null is falsy in jq). If `!=` is truly required, write the filter to a file with the Write tool and pass it via `jq -f filter.jq`.
- Is it about interacting with YAML or XML? use 'yq'
- Each Bash tool invocation runs in a fresh subshell: variables do not persist across calls. Inline captures or combine with `&&`.
- Use `$(printenv VAR)` instead of `$VAR` when passing env vars as path prefixes to external commands — `$VAR` may silently expand to empty.
