# nvim-config

My Neovim setup: a single-file `init.lua` using [lazy.nvim](https://github.com/folke/lazy.nvim).
Plugins install themselves on first launch, pinned to the versions in `lazy-lock.json`.

## Install on a new machine

```sh
# 1. Back up any existing config (skip if there is none)
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null

# 2. Clone into the config folder
git clone https://github.com/DKim50/nvim-config.git ~/.config/nvim

# 3. Launch. lazy.nvim, the plugins, treesitter parsers and the
#    language servers (via Mason) all install themselves.
nvim
```

Once the first launch finishes, run `:Lazy restore` to make sure every plugin is at
the exact commit in `lazy-lock.json`, then restart.

## Requirements

macOS (Homebrew):

```sh
brew install neovim git ripgrep tree-sitter-cli node
brew install --cask font-jetbrains-mono-nerd-font
xcode-select --install   # C compiler, needed to build treesitter parsers
```

| Tool | Why |
| --- | --- |
| Neovim **0.12+** | nvim-treesitter's `main` branch requires it |
| git | lazy.nvim clones plugins |
| ripgrep (`rg`) | Telescope live grep (`<leader>fg`) |
| tree-sitter CLI + C compiler | builds treesitter parsers |
| node / npm | Mason installs `pyright`, `ts_ls` and the HTML, CSS and Emmet servers through npm |
| python3 (with `venv`) | Mason installs `debugpy` for the Python debugger (`<leader>b`) |
| A Nerd Font | file icons; set your terminal's font to *JetBrainsMono Nerd Font* |

Optional formatters for format-on-save (without them it falls back to the LSP formatter):

```sh
brew install stylua black prettier
```

On Linux, distro packages of Neovim are often too old; use the official release
tarball/AppImage or `brew` on Linux.

## Keymaps

Leader is `Space`.

| Keys | Action |
| --- | --- |
| `jk` (insert) | Exit insert mode |
| `<leader>w` / `<leader>q` | Write / quit |
| `<leader>x` | Close buffer, keep window layout |
| `Shift-H` / `Shift-L` | Previous / next buffer tab |
| `<leader><` / `<leader>>` | Move buffer tab left / right |
| `Ctrl-h/j/k/l` | Move between splits |
| `<leader>e` | Toggle file tree |
| `<leader>ff` `fg` `fb` `fr` `fh` `fs` | Find files, grep, buffers, recent, help, symbols |
| `gd` / `gr` / `K` | Definition / references / hover (LSP) |
| `<leader>rn` / `<leader>ca` / `<leader>d` | Rename / code action / show diagnostic |
| `Ctrl-y` / `Ctrl-n` / `Ctrl-p` (insert) | Accept / next / previous suggestion. Accepting expands Emmet (`!`, `ul>li*3`) |
| `Tab` / `Shift-Tab` (insert) | Jump to the next / previous blank in an expanded snippet |
| `<leader>gb` / `<leader>gp` | Git blame line / preview hunk |
| `<leader>rr` | Reload files changed on disk |
| `Ctrl-\` | Floating terminal |
| `<leader>bb` / `<leader>bB` | Debug: toggle breakpoint / conditional breakpoint |
| `<leader>bc` `bn` `bi` `bo` | Debug: continue (start), next line, step into, step out |
| `F5` `F10` `F11` `F12` | Same as above (hold `fn` on a Mac laptop) |
| `<leader>bt` / `<leader>bu` / `<leader>be` | Debug: stop + close panels / toggle panels / evaluate under cursor |

Press `Space` and wait to see everything in the which-key popup.

## Keeping machines in sync

```sh
cd ~/.config/nvim
git pull                  # get changes from another machine
# then in nvim:  :Lazy restore   (match plugin versions to the lockfile)
```

After `:Lazy update` or editing `init.lua`, commit and push so other machines get it:

```sh
cd ~/.config/nvim
git add -A && git commit -m "Update config" && git push
```
