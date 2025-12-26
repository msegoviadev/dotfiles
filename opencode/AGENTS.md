## Style Guidelines

- Prefer self-documenting code over comments
- Don't use em dashes (—). Use commas, parentheses, or separate sentences instead.

## Tooling for shell interactions

IMPORTANT, always consider the following rules:
- Is it about finding FILES? use 'fd'
- Is it about finding TEXT/strings? use 'rg'
- Is it about finding CODE STRUCTURE? use 'ast-grep'
- Is it about SELECTING from multiple results? pipe to 'fzf'
- Is it about interacting with JSON? use 'jq'
- Is it about interacting with YAML or XML? use 'yq'
