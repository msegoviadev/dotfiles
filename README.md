# Dotfiles

Personal configuration files for development tools.

## Setup

Clone this repository and create symlinks to the appropriate config directories.

### 1. Clone the repository

```bash
git clone <your-repo-url> ~/workspace/dotfiles
```

### 2. Create symlinks

**Claude**

```bash
ln -s ~/workspace/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/workspace/dotfiles/claude/RTK.md ~/.claude/RTK.md
ln -s ~/workspace/dotfiles/claude/hooks ~/.claude/hooks
ln -s ~/workspace/dotfiles/claude/settings.json ~/.claude/settings.json
```

**Ghostty**

```bash
ln -s ~/workspace/dotfiles/ghostty ~/.config/ghostty
```

**Neovim**

```bash
ln -s ~/workspace/dotfiles/nvim ~/.config/nvim
```

**OpenCode**

```bash
ln -s ~/workspace/dotfiles/opencode ~/.config/opencode
```
