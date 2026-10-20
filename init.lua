-- ============================================================
--  ~/.config/nvim/init.lua
--  Single-file Neovim IDE setup. Read top to bottom.
-- ============================================================

-- ------------------------------------------------------------
-- 1. LEADER KEY
--    Must be set before plugins load. Space is the modern default.
-- ------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ------------------------------------------------------------
-- 2. OPTIONS  (this is the "Step 11" config, no plugins involved)
-- ------------------------------------------------------------
local opt = vim.opt

opt.number = true            -- absolute number on the cursor line
opt.relativenumber = false   -- absolute line numbers (set true for distance-from-cursor)

opt.tabstop = 2              -- a tab renders as 2 columns
opt.shiftwidth = 2           -- >> and << shift by 2
opt.expandtab = true         -- insert spaces, never literal tabs
opt.smartindent = true

opt.ignorecase = true        -- /foo matches Foo
opt.smartcase = true         -- ...unless you type a capital: /Foo is exact
opt.incsearch = true         -- jump to matches as you type
opt.hlsearch = false         -- don't leave matches lit up forever

opt.clipboard = "unnamedplus" -- y and p use the macOS system clipboard
opt.scrolloff = 8             -- keep 8 lines visible above/below the cursor
opt.signcolumn = "yes"        -- reserve the gutter so text stops jumping
opt.undofile = true           -- undo history survives closing the file
opt.termguicolors = true      -- 24-bit color
opt.splitright = true         -- vertical splits open to the right
opt.splitbelow = true         -- horizontal splits open below
opt.wrap = false
opt.cursorline = true         -- highlight the line you're on
opt.updatetime = 250          -- faster diagnostics / git signs
opt.mouse = "a"               -- mouse works if you want it

-- ------------------------------------------------------------
-- 3. BASIC KEYMAPS (no plugins needed)
-- ------------------------------------------------------------
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Move between splits with Ctrl + hjkl
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Buffer (open file) navigation
-- Shift+L / Shift+H are defined in the bufferline block below, so they follow
-- the VISUAL tab order rather than internal buffer numbers.
-- Close the current buffer WITHOUT collapsing the window layout.
-- Plain :bdelete closes every window showing the buffer, so when the code
-- window goes away the file tree is left alone and closes itself too.
-- This points those windows at another buffer first, then deletes.
map("n", "<leader>x", function()
  local cur = vim.api.nvim_get_current_buf()

  if vim.bo[cur].modified then
    vim.notify("Unsaved changes - :w to save, or :bd! to discard", vim.log.levels.WARN)
    return
  end

  local listed = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == cur then
      vim.api.nvim_win_call(win, function()
        if #listed > 1 then vim.cmd("bprevious") else vim.cmd("enew") end
      end)
    end
  end

  if vim.api.nvim_buf_is_valid(cur) then
    vim.api.nvim_buf_delete(cur, {})
  end
end, { desc = "Close buffer (keep layout)" })

-- Save / quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Keep the cursor centered when jumping half-pages
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- ------------------------------------------------------------
-- 4. AUTO-RELOAD FILES CHANGED OUTSIDE NVIM
--    'autoread' is already on by default, but nvim only acts on it
--    when something triggers a timestamp check. These autocmds do
--    the triggering, so edits made in an IDE / by git show up here.
-- ------------------------------------------------------------
opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  desc = "Check whether the file changed on disk",
  callback = function()
    -- skip while typing a command or in the cmdline window, where :checktime errors
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  desc = "Tell me when a buffer was reloaded from disk",
  callback = function()
    vim.notify("File changed on disk - buffer reloaded", vim.log.levels.WARN)
  end,
})

-- Manual escape hatches, in case you want to force it:
--   :e          reload this file        :e!   force, discard local edits
--   :bufdo e    reload every buffer     :checktime  check now
map("n", "<leader>rr", "<cmd>checktime<CR>", { desc = "Reload changed files" })

-- ------------------------------------------------------------
-- 5. BOOTSTRAP lazy.nvim (the plugin manager)
--    Clones itself on first launch if it isn't present.
-- ------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ------------------------------------------------------------
-- 6. PLUGINS
-- ------------------------------------------------------------
require("lazy").setup({

  -- ---------- Colorscheme : VS Code Dark+ (the active one) ----------
  -- Same syntax colors as VS Code: blue def/class, pink if/return,
  -- yellow functions, light-blue variables, orange strings, green comments.
  -- Compare themes live:  :Telescope colorscheme enable_preview=true
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,  -- load before everything else
    config = function()
      -- ===== BACKGROUND COLOR KNOB =====
      -- Change this one value and restart nvim.
      --   "#0d0d0d"  near-black (same as the tokyonight setup)
      --   nil        the real VS Code background (#1F1F1F)
      local BG = "#0d0d0d"

      local overrides = {}
      if BG then
        overrides = {
          vscBack           = BG,         -- main editor background
          vscTabCurrent     = BG,         -- the active buffer tab
          vscLeftDark       = BG,         -- tab bar behind the tabs
          vscPopupBack      = BG,         -- floating windows, completion menu
          vscCursorDarkDark = "#1c1c1c",  -- the highlighted current line
        }
      end

      require("vscode").setup({
        style = "dark",
        color_overrides = overrides,
      })
      vim.cmd.colorscheme("vscode")
    end,
  },

  -- ---------- Colorscheme : tokyonight (backup) ----------
  -- Still set up, just not switched on. Go back with :colorscheme tokyonight
  -- or make it permanent by moving the colorscheme() call back here.
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- ===== BACKGROUND COLOR KNOB =====
      -- Change this one value and restart nvim.
      --   "#000000"  pure black
      --   "#0d0d0d"  near-black  (easier on the eyes than pure black)
      --   "#121212"  very dark gray
      --   "#1a1a1a"  dark gray
      --   "#1e1e1e"  VS Code Dark+ gray
      --   nil        leave tokyonight's default blue (#1a1b26)
      local BG = "#0d0d0d"

      require("tokyonight").setup({
        style = "night",
        on_colors = function(c)
          if not BG then return end
          c.bg           = BG   -- main editor background
          c.bg_dark      = BG   -- sidebars, file tree
          c.bg_float     = BG   -- floating windows (telescope, hover)
          c.bg_sidebar   = BG
          c.bg_statusline = BG
          c.bg_popup     = BG
        end,
        on_highlights = function(hl, c)
          -- kill the blue tint on a few things that set their own bg
          hl.NormalFloat  = { bg = c.bg }
          hl.FloatBorder  = { bg = c.bg, fg = c.fg_gutter }
          hl.TelescopeNormal = { bg = c.bg }
          hl.TelescopeBorder = { bg = c.bg, fg = c.fg_gutter }
          hl.CursorLine   = { bg = "#1c1c1c" }  -- the highlighted current line
        end,
      })
    end,
  },

  -- ---------- Icons (needs the Nerd Font) ----------
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- ---------- Fuzzy finder : your Cmd+P ----------
  {
    "nvim-telescope/telescope.nvim",
    -- master, not the 0.1.x release branch: 0.1.x is from May 2024 and calls
    -- nvim-treesitter's removed `parsers.ft_to_lang()`, which errors in the
    -- file preview. master uses Neovim's own vim.treesitter.language.get_lang().
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local t = require("telescope.builtin")
      map("n", "<leader>ff", t.find_files,  { desc = "Find files" })
      map("n", "<leader>fg", t.live_grep,   { desc = "Grep in project" })
      map("n", "<leader>fb", t.buffers,     { desc = "Open buffers" })
      map("n", "<leader>fh", t.help_tags,   { desc = "Help tags" })
      map("n", "<leader>fr", t.oldfiles,    { desc = "Recent files" })
      map("n", "<leader>fs", t.lsp_document_symbols, { desc = "Symbols in file" })
    end,
  },

  -- ---------- Treesitter : real syntax understanding ----------
  -- NOTE: the `main` branch is the one that supports Neovim 0.12+.
  -- The old `master` branch says "Neovim 0.12 is not supported" and throws
  -- "attempt to call method 'range' (a nil value)" on every redraw.
  -- Needs the tree-sitter CLI: brew install tree-sitter-cli
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,             -- this plugin does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local langs = {
        "lua", "vim", "vimdoc", "python", "javascript",
        "typescript", "tsx", "html", "css", "json",
        "bash", "markdown", "markdown_inline",
      }

      require("nvim-treesitter").setup()
      require("nvim-treesitter").install(langs)   -- no-op if already installed

      -- Highlighting is Neovim's now; nvim-treesitter only supplies parsers
      -- and queries. Turn it on per filetype.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = langs,
        desc = "Start treesitter highlighting",
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- ---------- File tree sidebar ----------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 32 },
        renderer = { group_empty = true },
        filters = { dotfiles = false },
      })
      map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
    end,
  },

  -- ---------- Buffer tabs across the top ----------
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = { offsets = { { filetype = "NvimTree", text = "Files" } } },
      })
      -- Rearrange the tabs. Mnemonic matches >> / << for indenting.
      -- Shift+L / Shift+H are left alone - they still just cycle.
      -- Cycle in VISUAL tab order. Plain :bnext/:bprevious walk internal buffer
      -- numbers, which stop matching the tab bar as soon as you reorder.
      map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
      map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

      -- Rearrange the tabs. Mnemonic matches >> / << for indenting.
      map("n", "<leader>>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
      map("n", "<leader><", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })
    end,
  },

  -- ---------- Statusline ----------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- "auto" follows whichever colorscheme is active
      require("lualine").setup({ options = { theme = "auto" } })
    end,
  },

  -- ---------- Git gutter ----------
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
      map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { desc = "Blame line" })
      map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })
    end,
  },

  -- ---------- LSP : go-to-def, hover, errors ----------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", config = true },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls" },
      })

      -- Keymaps attach only once a language server is running
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local o = { buffer = ev.buf }
          map("n", "gd", vim.lsp.buf.definition,      vim.tbl_extend("force", o, { desc = "Go to definition" }))
          map("n", "gr", vim.lsp.buf.references,      vim.tbl_extend("force", o, { desc = "References" }))
          map("n", "K",  vim.lsp.buf.hover,           vim.tbl_extend("force", o, { desc = "Hover docs" }))
          map("n", "<leader>rn", vim.lsp.buf.rename,  vim.tbl_extend("force", o, { desc = "Rename symbol" }))
          map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", o, { desc = "Code action" }))
          map("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", o, { desc = "Show diagnostic" }))
        end,
      })

      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
      })
    end,
  },

  -- ---------- Autocomplete ----------
  {
    "saghen/blink.cmp",
    version = "*",            -- use a release tag -> downloads a prebuilt binary
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },

  -- ---------- Format on save ----------
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "black" },
          javascript = { "prettier" },
          typescript = { "prettier" },
        },
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
      })
    end,
  },

  -- ---------- Auto-close brackets and quotes ----------
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },

  -- ---------- Indent guide lines ----------
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

  -- ---------- Keybinding hints popup ----------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ---------- Floating terminal ----------
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-\>]],
        direction = "float",
      })
    end,
  },

}, {
  ui = { border = "rounded" },
  checker = { enabled = false },  -- don't auto-check for updates on startup
})
