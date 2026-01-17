- **Language:** English only - all code, comments, docs, examples, commits, configs, errors, tests

## Style Guidelines
- Prefer self-documenting code over comments
- Don't use em dashes (—). Use commas, parentheses, or separate sentences instead.

## Git/Commit Guidelines
- Never add "Claude" or any AI assistant as a co-author in git commits
- Keep commit messages succinct, providing a summary of functionality or changes rather than bullet-pointing each specific detail

## Tooling for shell interactions

IMPORTANT, always consider the following rules:
- Is it about finding FILES? use 'fd'
- Is it about finding TEXT/strings? use 'rg'
- Is it about finding CODE STRUCTURE? use 'ast-grep'
- Is it about SELECTING from multiple results? pipe to 'fzf'
- Is it about interacting with JSON? use 'jq'
- Is it about interacting with YAML or XML? use 'yq'
