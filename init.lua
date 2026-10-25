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

-- Web files indent by 4 like VS Code (Python already uses 4). softtabstop
-- makes Backspace remove a whole indent level, not one space.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
  desc = "Indent web files by 4",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

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
  -- purple strings, teal None/True/False, green comments (COMMENT knob).
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

      -- ===== COMMENT COLOR KNOB =====
      -- Change this one value and restart nvim.
      --   "#42be65"  oxocarbon's green (used nowhere else in code)
      --   "#8d8d8d"  lighter gray
      --   nil        oxocarbon's own dim gray (#575757)
      local COMMENT = "#42be65"

      -- oxocarbon has no setup() options, so after it loads, swap its
      -- background (#161616) for BG in every highlight group that uses it,
      -- and recolor comments with COMMENT.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "oxocarbon",
        desc = "Apply the BG and COMMENT knobs to oxocarbon",
        callback = function()
          if BG then
            for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
              if hl.bg == 0x161616 then
                hl.bg = BG
                vim.api.nvim_set_hl(0, name, hl)
              end
            end
          end
          if COMMENT then
            vim.api.nvim_set_hl(0, "Comment", { fg = COMMENT, italic = true })
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
      -- Saving an HTML file tidies it. Keep <head> and <body> indented inside
      -- <html> like VS Code, and don't add blank lines before them.
      vim.lsp.config("html", {
        settings = { html = { format = { indentInnerHtml = true, extraLiners = "" } } },
      })
      -- Emmet only where you write tags. In CSS files its shortcuts crowd
      -- out the real suggestions (col -> "columns: ;" above color).
      vim.lsp.config("emmet_language_server", { filetypes = { "html", "javascriptreact", "typescriptreact" } })
      require("mason-lspconfig").setup({
        -- html / cssls: tag, attribute and CSS property suggestions + hover
        -- docs (the same servers VS Code uses). emmet: ul>li*3 style shortcuts.
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "html", "cssls", "emmet_language_server" },
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
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      npairs.setup()
      -- HTML: Enter between <div>|</div> moves </div> down and puts the
      -- cursor on an indented line in between, like VS Code.
      npairs.add_rule(Rule("<%a[^<>]*>[^<]*$", "^</", "html"):use_regex(true):only_cr())
    end,
  },

  -- ---------- Auto-close and auto-rename HTML tags ----------
  -- Type <div> and </div> appears after the cursor. Change <div> to <section>
  -- and the closing tag changes too. Uses the treesitter parsers above.
  { "windwp/nvim-ts-autotag", event = { "BufReadPre", "BufNewFile" }, opts = {} },

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

  -- ---------- Debugger : breakpoints, stepping, variables panel ----------
  -- Like VS Code's debugger. Press Space b and which-key lists every key.
  -- Python only for now; debugpy (the Python debug adapter) installs itself
  -- through Mason the first time nvim starts.
  --   Space b b   toggle a breakpoint (red dot)      F5   start / continue
  --   Space b n   next line (step over)              F10  step over
  --   Space b i   step into a function               F11  step into
  --   Space b o   step out of a function             F12  step out
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",      -- required by nvim-dap-ui
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",  -- variable values at the end of each line
      "mason-org/mason.nvim",
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()

      -- Variable values at the end of each line while paused, like an IDE
      require("nvim-dap-virtual-text").setup({
        all_references = true,   -- show the value on every line the variable appears, not just where it's first set
        virt_text_pos = "eol",   -- at the end of the line like VS Code ("inline" puts them right after each variable)
      })

      -- Python adapter: debugpy lives in its own venv inside Mason's folder
      local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(debugpy)

      -- Give debugpy 15s to start instead of 4. Past the limit nvim-dap warns
      -- "Debug adapter didn't respond", and that two-line warning pops up a
      -- "Press ENTER" prompt that freezes the debugger until you press a key.
      local python_adapter = dap.adapters.python
      dap.adapters.python = function(cb, config)
        python_adapter(function(adapter)
          adapter.options = vim.tbl_extend("force", adapter.options or {}, { initialize_timeout_sec = 15 })
          cb(adapter)
        end, config)
      end

      -- Keep only the "file" config so F5 just runs the current file instead of
      -- asking which config to use (delete these 3 lines to get the others back)
      dap.configurations.python = vim.tbl_filter(function(c)
        return c.name == "file"
      end, dap.configurations.python)

      -- Show the paused line in your code window no matter which panel the
      -- cursor is in. The default picks "the window you were in before",
      -- which fails if that was a panel (the cursor then stays stuck in the
      -- terminal and no ▶ appears).
      dap.defaults.fallback.switchbuf = function(bufnr, line, column)
        local target
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if buf == bufnr then target = win; break end                 -- already showing this file
          if not target and vim.bo[buf].buftype == "" then target = win end  -- else any normal file window
        end
        if not target then return end
        vim.api.nvim_win_set_buf(target, bufnr)
        pcall(vim.api.nvim_win_set_cursor, target, { line, math.max((column or 1) - 1, 0) })
        vim.api.nvim_win_call(target, function() vim.cmd("normal! zv") end)
        -- keep the cursor where it is if you're typing in the REPL
        if vim.bo.filetype ~= "dap-repl" then vim.api.nvim_set_current_win(target) end
      end

      -- When the program starts, move the cursor into its terminal window so
      -- you can answer input() prompts (press i, type, Enter). This waits
      -- until the panels have finished opening, because opening them hands
      -- the cursor back to your code (so nvim-dap's focus_terminal can't work).
      dap.listeners.after.launch.focus_terminal = function()
        local tries, steady = 0, 0
        local timer = vim.uv.new_timer()
        timer:start(100, 100, vim.schedule_wrap(function()
          tries = tries + 1
          local term_win, panels_open = nil, false
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "terminal" then term_win = win end
            if vim.bo[buf].filetype == "dapui_watches" then panels_open = true end
          end
          if term_win and (panels_open or tries >= 15) then steady = steady + 1 end
          if steady >= 2 then
            timer:stop(); timer:close()
            -- only while the program is still running (not already paused at a breakpoint)
            local session = dap.session()
            if session and not session.stopped_thread_id then
              vim.api.nvim_set_current_win(term_win)
            end
          elseif tries >= 40 then
            timer:stop(); timer:close()
          end
        end))
      end

      -- Install debugpy through Mason if it's missing
      local registry = require("mason-registry")
      if not registry.is_installed("debugpy") then
        registry.refresh(function()
          local ok, pkg = pcall(registry.get_package, "debugpy")
          if ok then pkg:install() end
        end)
      end

      -- Panels open when a debug session starts. They stay open after the
      -- program ends so you can read its output (or the error that stopped
      -- it); Space b t or Space b u closes them.
      dap.listeners.before.attach.dapui_config = dapui.open
      dap.listeners.before.launch.dapui_config = dapui.open

      -- Gutter icons + colors. Re-applied on :colorscheme so they survive a switch.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })
      local function set_dap_colors()
        vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ee5396" })      -- pink-red dot
        vim.api.nvim_set_hl(0, "DapStopped", { fg = "#42be65" })         -- green arrow
        vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#16261b" })     -- line you're paused on
        vim.api.nvim_set_hl(0, "NvimDapVirtualText", { fg = "#8d8d8d", italic = true })         -- variable values (gray, so they don't look like code)
        vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = "#ff7eb6", italic = true })  -- a value that just changed (pink)
      end
      set_dap_colors()
      vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Re-apply the debugger colors",
        callback = set_dap_colors,
      })

      -- Start from the code even when the cursor is in the file tree or a
      -- panel. Plain dap.continue only looks at the window you're in, so from
      -- the tree it says "No configuration found for `NvimTree`".
      local function continue()
        if not dap.session() and not dap.configurations[vim.bo.filetype] then
          local wins = vim.api.nvim_tabpage_list_wins(0)
          table.insert(wins, 1, vim.fn.win_getid(vim.fn.winnr("#")))  -- the window you were just in, first
          local code_win
          for _, win in ipairs(wins) do
            if win ~= 0 and dap.configurations[vim.bo[vim.api.nvim_win_get_buf(win)].filetype] then
              code_win = win; break
            end
          end
          if not code_win then
            vim.notify("Debug: open a Python file first", vim.log.levels.WARN)
            return
          end
          vim.api.nvim_set_current_win(code_win)
        end
        dap.continue()
      end

      -- Keymaps (F-keys need the fn key held on a Mac laptop)
      map("n", "<F5>",  continue,      { desc = "Debug: start / continue" })
      map("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
      map("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
      map("n", "<F12>", dap.step_out,  { desc = "Debug: step out" })
      map("n", "<leader>bb", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      map("n", "<leader>bB", function()
        dap.set_breakpoint(vim.fn.input("Break when: "))
      end, { desc = "Conditional breakpoint" })
      map("n", "<leader>bc", continue,      { desc = "Start / continue" })
      map("n", "<leader>bn", dap.step_over, { desc = "Next line (step over)" })
      map("n", "<leader>bi", dap.step_into, { desc = "Step into" })
      map("n", "<leader>bo", dap.step_out,  { desc = "Step out" })
      map("n", "<leader>bt", function()
        if dap.session() then dap.terminate() end
        dapui.close()
      end, { desc = "Stop debugging + close panels" })
      map("n", "<leader>bu", dapui.toggle,  { desc = "Toggle debug panels" })
      map({ "n", "v" }, "<leader>be", dapui.eval, { desc = "Evaluate under cursor" })

      local ok, wk = pcall(require, "which-key")
      if ok then wk.add({ { "<leader>b", group = "debug" } }) end
    end,
  },

}, {
  ui = { border = "rounded" },
  checker = { enabled = false },  -- don't auto-check for updates on startup
})
