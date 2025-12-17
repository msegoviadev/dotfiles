# Neovim Configuration Guidelines

## Build/Lint/Test Commands
- Check config: Open nvim and run `:checkhealth` to verify plugin setup
- Update plugins: Run `:Lazy sync` in nvim
- No formatter currently in use (stylua.toml exists but stylua not installed)
- No test suite present (this is a configuration repository)

## Code Style

### Formatting
- Use 2 spaces for indentation (no tabs)
- Max line width: 120 characters

### Lua Conventions
- Use double quotes for strings (based on existing code)
- Comment style: Inline comments with `--` for explanations above code blocks
- Write descriptive comments explaining the "why", not the "what"
- Prefer self-documenting code over comments where possible
- Variable naming: Use snake_case for local variables (e.g., `ts_config`, `local_leader`)

### Plugin Structure
- Each plugin in separate file under `lua/plugins/`
- Return table with plugin spec following lazy.nvim format
- Include dependencies in `dependencies` table
- Use `config` function for setup code
- Add descriptive comments for non-obvious configurations
- Set keymaps within plugin config when plugin-specific

### Keymaps
- Leader key is space: `<leader>` = ` `
- Include `desc` parameter for all keymaps for discoverability
- Format descriptions with [C]apital letters showing mnemonic (e.g., "[F]ind [F]iles")
