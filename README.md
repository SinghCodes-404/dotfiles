# dotfiles

My personal Arch Linux + Hyprland configuration.

## What's here

- **zsh** — Zsh config, starship prompt, autosuggestions, syntax highlighting
- **starship** — Starship prompt config (Catppuccin Frappe)
- **tmux** — tmux config with Catppuccin theme, TPM plugins
- **nvim** — Neovim config (Kickstart-based) with LSP, Telescope, Neo-tree
- **git** — gitconfig with aliases, delta diffs, global gitignore
- **hypr** — Hyprland UserConfigs and UserScripts (keybinds, window rules, decorations, startup apps, scripts)

## Install

### Requirements
- Arch Linux
- GNU Stow (`sudo pacman -S stow`)
- Neovim 0.12+, tmux, starship, zoxide, bat, fd, ripgrep, lazygit, git-delta, lsd

### Setup
```bash
git clone https://github.com/SinghCodes-404/dotfiles ~/dotfiles
cd ~/dotfiles
stow zsh starship tmux nvim git hypr
```

Open nvim once to let plugins install automatically.
Open tmux and press `Ctrl-A + I` to install tmux plugins via TPM.
