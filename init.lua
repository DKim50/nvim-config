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

  -- ---------- Colorscheme : oxocarbon (the active one) ----------
  -- Built from IBM's Carbon design system palette. Mostly white/gray text
  -- with sharp accents: blue keywords, pink functions, cyan `def`,
  -- purple strings, teal None/True/False, dim gray comments.
  -- Compare themes live:  :Telescope colorscheme enable_preview=true
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    priority = 1000,  -- load before everything else
    config = function()
      -- ===== BACKGROUND COLOR KNOB =====
      -- Change this one value and restart nvim.
      --   "#0d0d0d"  near-black (same as the other themes)
      --   nil        oxocarbon's own background (#161616)
      local BG = "#0d0d0d"

      -- oxocarbon has no setup() options, so after it loads, swap its
      -- background (#161616) for BG in every highlight group that uses it.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "oxocarbon",
        desc = "Swap oxocarbon's background for the BG knob",
        callback = function()
          if not BG then return end
          for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
            if hl.bg == 0x161616 then
              hl.bg = BG
              vim.api.nvim_set_hl(0, name, hl)
            end
          end
        end,
      })

      vim.o.background = "dark"
      vim.cmd.colorscheme("oxocarbon")  -- this line is what makes it the active theme
    end,
  },

  -- ---------- Colorscheme : VS Code Dark+ (backup) ----------
  -- Same syntax colors as VS Code: blue def/class, pink if/return,
  -- yellow functions, light-blue variables, orange strings, green comments.
  -- Switch with :colorscheme vscode
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
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

  -- ---------- Start screen ----------
  -- Shows when you run `nvim` with no file. Press a letter to pick an action.
  -- snacks.nvim is a bundle of small tools; only its dashboard is turned on.
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- ===== HEADER TEXT KNOB =====
      -- Make your own at patorjk.com/software/taag  (font: "ANSI Shadow")
      local header = {
        "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
      }

      -- One color per header line, top to bottom: an oxocarbon gradient
      -- from cyan through blue and purple to pink.
      local gradient = { "#3ddbd9", "#82cfff", "#78a9ff", "#be95ff", "#ff7eb6", "#ee5396" }

      -- ===== STARFIELD KNOB =====
      -- Twinkling stars in the empty space around the menu.
      local STARS = {
        enabled = true,
        density = 0.02,  -- share of empty cells holding a star (0.02 = 2%)
        fps     = 10,    -- redraws per second
        -- mostly white, with the odd oxocarbon cyan / blue / purple / pink star
        colors  = { "#dde1e6", "#dde1e6", "#dde1e6", "#3ddbd9", "#78a9ff", "#be95ff", "#ff7eb6" },
      }
      -- A star brightens through these, then dims back down.
      local GLYPHS     = { "·", "·", "+", "*" }
      local BRIGHTNESS = { 0.3, 0.55, 0.8, 1.0 }  -- how far each step is from the background

      -- Mix a color toward the background: amount 1 = full color, 0 = invisible.
      local function fade(color, bg, amount)
        local function channel(hex, i) return tonumber(hex:sub(i, i + 1), 16) end
        local out = "#"
        for _, i in ipairs({ 2, 4, 6 }) do
          local c, b = channel(color, i), channel(bg, i)
          out = out .. string.format("%02x", math.floor(b + (c - b) * amount + 0.5))
        end
        return out
      end

      local function set_colors()
        for i, color in ipairs(gradient) do
          vim.api.nvim_set_hl(0, "DashHeader" .. i, { fg = color })
        end
        local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
        local bg = normal_bg and string.format("#%06x", normal_bg) or "#000000"
        for c, color in ipairs(STARS.colors) do
          for level, amount in ipairs(BRIGHTNESS) do
            vim.api.nvim_set_hl(0, ("DashStar%d_%d"):format(c, level), { fg = fade(color, bg, amount) })
          end
        end
      end
      set_colors()
      -- :colorscheme wipes custom colors, so put these back after a switch
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_colors })

      local header_section = {}
      for i, line in ipairs(header) do
        local color = "DashHeader" .. math.min(i, #gradient)
        table.insert(header_section, { text = { { line, hl = color, align = "center" } } })
      end
      header_section[#header_section].padding = 2  -- space below the logo

      require("snacks").setup({
        dashboard = {
          sections = {
            header_section,
            { icon = " ", title = "Keymaps",      section = "keys",         indent = 2, padding = 1 },
            { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
            { icon = " ", title = "Projects",     section = "projects",     indent = 2, padding = 1 },
            { section = "startup" },
          },
        },
      })

      -- ---------- Starfield animation ----------
      -- Stars are "extmarks": decorations drawn on top of the dashboard's
      -- blank space without changing its text. A timer redraws them ~10x/sec.
      local ns = vim.api.nvim_create_namespace("dashboard_stars")
      local field  -- the running starfield: { buf, win, timer, stars, nlines, height }

      local function stop_stars()
        if not field then return end
        field.timer:stop()
        field.timer:close()
        if vim.api.nvim_buf_is_valid(field.buf) then
          vim.api.nvim_buf_clear_namespace(field.buf, ns, 0, -1)
        end
        field = nil
      end

      -- Scatter stars over the window, leaving a clear border around the menu.
      local function place_stars(buf, width, height)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local top, bottom, left, right = math.huge, -1, math.huge, -1
        for row, line in ipairs(lines) do
          local first = line:find("%S")
          if first then
            top    = math.min(top, row - 1)
            bottom = math.max(bottom, row - 1)
            left   = math.min(left, vim.fn.strdisplaywidth(line:sub(1, first - 1)))
            right  = math.max(right, vim.fn.strdisplaywidth((line:gsub("%s+$", ""))))
          end
        end
        top, bottom, left, right = top - 1, bottom + 1, left - 4, right + 4

        local stars = {}
        for row = 0, height - 1 do
          for col = 0, width - 1 do
            local in_menu = row >= top and row <= bottom and col >= left and col < right
            if not in_menu and math.random() < STARS.density then
              local size = math.random()
              table.insert(stars, {
                row   = row,
                col   = col,
                color = math.random(#STARS.colors),
                max   = size < 0.6 and 2 or size < 0.9 and 3 or 4,  -- small / medium / big star
                speed = 0.6 + math.random(),                         -- one twinkle every ~4-10s
                phase = math.random() * 2 * math.pi,                 -- so they don't sync up
              })
            end
          end
        end
        return stars, #lines
      end

      local function draw(t)
        local f = field
        if not (f and vim.api.nvim_buf_is_valid(f.buf) and vim.api.nvim_win_is_valid(f.win)
                and vim.api.nvim_win_get_buf(f.win) == f.buf) then
          return stop_stars()  -- the dashboard is gone
        end
        vim.api.nvim_buf_clear_namespace(f.buf, ns, 0, -1)

        local below = {}  -- stars past the last buffer line, keyed by row
        for _, s in ipairs(f.stars) do
          local wave = (math.sin(t * s.speed + s.phase) + 1) / 2  -- 0..1 and back
          local level = math.min(math.floor(wave * (s.max + 1)), s.max)
          if level > 0 then
            local chunk = { GLYPHS[level], ("DashStar%d_%d"):format(s.color, level) }
            if s.row < f.nlines then
              vim.api.nvim_buf_set_extmark(f.buf, ns, s.row, 0, { virt_text = { chunk }, virt_text_win_col = s.col })
            else
              below[s.row] = below[s.row] or {}
              table.insert(below[s.row], { col = s.col, chunk = chunk })
            end
          end
        end

        -- The buffer ends before the window does, so the bottom rows are
        -- "virtual lines" hung under the last line.
        if f.nlines < f.height then
          local vlines = {}
          for row = f.nlines, f.height - 1 do
            local items, chunks, at = below[row] or {}, {}, 0
            table.sort(items, function(a, b) return a.col < b.col end)
            for _, it in ipairs(items) do
              table.insert(chunks, { string.rep(" ", it.col - at) })
              table.insert(chunks, it.chunk)
              at = it.col + 1
            end
            table.insert(vlines, chunks)
          end
          vim.api.nvim_buf_set_extmark(f.buf, ns, f.nlines - 1, 0, { virt_lines = vlines })
        end
      end

      local function start_stars()
        stop_stars()
        if not STARS.enabled then return end
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "snacks_dashboard" and vim.bo[buf].buftype ~= "terminal" then
            set_colors()  -- the theme has fully loaded by now, so fades match its background
            local height = vim.api.nvim_win_get_height(win)
            local stars, nlines = place_stars(buf, vim.api.nvim_win_get_width(win), height)
            field = { buf = buf, win = win, timer = vim.uv.new_timer(), stars = stars, nlines = nlines, height = height }
            local start = vim.uv.now()
            field.timer:start(0, math.floor(1000 / STARS.fps), vim.schedule_wrap(function()
              -- if anything goes wrong, stop quietly instead of erroring 10x a second
              if not pcall(draw, (vim.uv.now() - start) / 1000) then stop_stars() end
            end))
            return
          end
        end
      end

      math.randomseed(os.time())  -- a different sky every launch
      -- Snacks fires these after it draws (also on resize) and when it closes.
      vim.api.nvim_create_autocmd("User", { pattern = "SnacksDashboardUpdatePost", callback = start_stars })
      vim.api.nvim_create_autocmd("User", { pattern = "SnacksDashboardClosed", callback = stop_stars })
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
