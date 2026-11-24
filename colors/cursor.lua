-- Cursor: the Cursor editor's "Cursor Dark" theme, read from the theme file
-- inside Cursor.app (theme-cursor/themes/cursor-dark-color-theme.json).
-- Goes with Ghostty's "Cursor Dark" theme. Teal keywords, pink strings,
-- peach functions and classes, lavender properties and calls, warm yellow
-- numbers, rose self, soft gray italic comments, bright off-white text.
-- Cursor's see-through colors are mixed with its dark background to get the
-- solid colors below.
-- Turn on with :colorscheme cursor. init.lua picks the one that loads.

-- ===== TRANSPARENT KNOB =====
-- Change this one value and restart nvim.
--   true   see-through: the terminal's background shows through the
--          editor, file tree and tab bar (popups stay solid)
--   false  solid BG everywhere
local TRANSPARENT = true

-- ===== BACKGROUND COLOR KNOB (only used when TRANSPARENT is false) =====
--   "#181818"  Cursor's editor background
--   "#141414"  Cursor's side bars and terminal (Ghostty's Cursor Dark)
local BG = "#181818"

local c = {
  fg = "#f0f0f0",        -- text
  text2 = "#d6d6dd",     -- variables, operators, punctuation
  comment = "#9a9a9a",   -- Cursor's text at 60%
  dim = "#636363",       -- line numbers, hints (text at 36%)
  faint = "#252525",     -- indent guides, borders
  line = "#262626",      -- the line you're on
  sel = "#3f638b",       -- selection: light blue (Cursor's own is gray #333333)
  popup = "#1f1f1f",
  popup_sel = "#343434",
  teal = "#82d2ce",      -- keywords
  pink = "#e394dc",      -- strings
  peach = "#efb080",     -- functions, classes, types
  lavender = "#aaa0fa",  -- properties, attributes, calls
  yellow = "#ebc88d",    -- numbers
  gold = "#f8c762",      -- parameters, CSS classes, bold
  sky = "#87c3ff",       -- HTML tags, CSS properties, JS variables
  frost = "#88c0d0",     -- headings, search
  rose = "#cc7c8a",      -- self, this
  green = "#a8cc7c",     -- decorators
  gray = "#a4a4a4",      -- < > around HTML tags
  module = "#cccccc",
  link = "#81a1c1",
  red = "#e34671",       -- errors
  orange = "#f1b467",    -- warnings
  added = "#3fa266",
  changed = "#d2943e",
}

vim.cmd("highlight clear")
vim.g.colors_name = "cursor"
vim.o.background = "dark"

local bg = not TRANSPARENT and BG or nil

local groups = {
  -- ---------- Editor ----------
  Normal = { fg = c.fg, bg = bg },
  NormalNC = { link = "Normal" },
  NormalFloat = { fg = c.fg, bg = c.popup },
  FloatBorder = { fg = "#3a3a3a", bg = c.popup },
  FloatTitle = { fg = c.fg, bg = c.popup, bold = true },
  Cursor = { fg = "#141414", bg = c.fg },
  TermCursor = { reverse = true },
  CursorLine = { bg = c.line },
  CursorColumn = { bg = c.line },
  ColorColumn = { bg = c.line },
  CursorLineNr = { fg = c.fg },
  LineNr = { fg = c.dim },
  SignColumn = { bg = bg },
  FoldColumn = { fg = c.dim, bg = bg },
  Folded = { fg = c.comment, bg = c.line },
  EndOfBuffer = { fg = c.faint },
  NonText = { fg = "#3e3e3e" },
  Whitespace = { fg = c.faint },
  SpecialKey = { fg = "#3e3e3e" },
  Conceal = { fg = c.comment },
  Visual = { bg = c.sel },
  Search = { bg = "#334247" },
  CurSearch = { bg = "#42595f", bold = true },
  IncSearch = { link = "CurSearch" },
  Substitute = { bg = "#42595f" },
  MatchParen = { bg = "#313131", bold = true },
  Pmenu = { fg = c.fg, bg = c.popup },
  PmenuSel = { bg = c.popup_sel, bold = true },
  PmenuKind = { fg = c.comment, bg = c.popup },
  PmenuExtra = { fg = c.comment, bg = c.popup },
  PmenuMatch = { fg = c.fg, bg = c.popup, bold = true },
  PmenuSbar = { bg = c.popup },
  PmenuThumb = { bg = "#3a3a3a" },
  WildMenu = { link = "PmenuSel" },
  StatusLine = { fg = c.comment, bg = "#141414" },
  StatusLineNC = { fg = c.dim, bg = "#141414" },
  TabLine = { fg = c.dim, bg = "#141414" },
  TabLineSel = { fg = c.fg, bg = "#181818" },
  TabLineFill = { bg = bg },
  WinBar = { fg = c.fg },
  WinBarNC = { fg = c.dim },
  WinSeparator = { fg = c.faint },
  Title = { fg = c.frost, bold = true },
  Directory = { fg = c.text2 },
  ErrorMsg = { fg = c.red },
  WarningMsg = { fg = c.orange },
  ModeMsg = { fg = c.fg, bold = true },
  MoreMsg = { fg = "#70b489" },
  Question = { fg = "#70b489" },
  QuickFixLine = { bg = c.line },
  SpellBad = { undercurl = true, sp = c.red },
  SpellCap = { undercurl = true, sp = c.link },
  SpellRare = { undercurl = true, sp = c.lavender },
  SpellLocal = { undercurl = true, sp = c.teal },

  -- ---------- Git and diffs ----------
  DiffAdd = { bg = "#1d3024" },
  DiffChange = { bg = "#3a2e1c" },
  DiffDelete = { fg = "#fc6b83", bg = "#35101f" },
  DiffText = { bg = "#574123" },
  Added = { fg = c.added },
  Changed = { fg = c.changed },
  Removed = { fg = c.red },

  -- ---------- Errors and warnings from the language server ----------
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.orange },
  DiagnosticInfo = { fg = c.link },
  DiagnosticHint = { fg = c.frost },
  DiagnosticOk = { fg = "#70b489" },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.orange },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.link },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.frost },
  LspReferenceText = { bg = "#303030" },
  LspReferenceRead = { bg = "#303030" },
  LspReferenceWrite = { bg = "#3a3a3a" },
  LspInlayHint = { fg = c.dim, italic = true },
  LspSignatureActiveParameter = { fg = c.gold, bold = true },

  -- ---------- Code ----------
  Comment = { fg = c.comment, italic = true },
  Constant = { fg = c.lavender },
  String = { fg = c.pink },
  Character = { fg = c.pink },
  Number = { fg = c.yellow },
  Float = { fg = c.yellow },
  -- Cursor leaves True / False / None in plain text
  Boolean = { fg = c.text2 },
  Identifier = { fg = c.text2 },
  Function = { fg = c.peach },
  Statement = { fg = c.teal },
  Conditional = { link = "Statement" },
  Repeat = { link = "Statement" },
  Label = { link = "Statement" },
  Keyword = { link = "Statement" },
  Exception = { link = "Statement" },
  Operator = { fg = c.text2 },
  PreProc = { fg = c.green },
  Include = { link = "Statement" },
  Define = { link = "PreProc" },
  Macro = { link = "PreProc" },
  PreCondit = { link = "PreProc" },
  Type = { fg = c.peach },
  StorageClass = { link = "Statement" },
  Structure = { link = "Type" },
  Typedef = { link = "Type" },
  Special = { fg = c.peach },
  SpecialChar = { fg = c.text2 },
  Tag = { fg = c.sky },
  Delimiter = { fg = c.text2 },
  SpecialComment = { fg = c.comment, italic = true },
  Debug = { fg = c.teal },
  Underlined = { fg = c.link, underline = true },
  Ignore = { fg = c.dim },
  Error = { fg = c.red },
  Todo = { fg = c.gold, bold = true },

  -- Treesitter
  ["@variable"] = { fg = c.text2 },
  ["@variable.parameter"] = { fg = c.text2, italic = true },
  ["@variable.builtin"] = { fg = c.rose },
  ["@variable.member"] = { fg = c.lavender },
  ["@property"] = { fg = c.lavender },
  ["@module"] = { fg = c.module },
  ["@constant.builtin"] = { fg = c.text2 },
  ["@function.builtin"] = { fg = c.peach },
  ["@function.call"] = { fg = c.peach },
  ["@constructor"] = { fg = c.peach },
  ["@type.builtin"] = { fg = c.teal },
  ["@attribute"] = { fg = c.green },
  ["@keyword.import"] = { fg = c.teal },
  ["@string.escape"] = { fg = c.text2 },
  ["@punctuation"] = { fg = c.text2 },
  ["@tag.attribute"] = { fg = c.lavender },
  ["@tag.delimiter"] = { fg = c.gray },
  ["@markup.heading"] = { fg = c.frost },
  ["@markup.strong"] = { fg = c.gold, bold = true },
  ["@markup.italic"] = { fg = c.teal, italic = true },
  ["@markup.raw"] = { fg = c.pink },
  ["@markup.list"] = { fg = c.text2 },
  ["@markup.link.label"] = { fg = c.lavender },
  ["@markup.link.url"] = { fg = c.teal, underline = true },
  ["@markup.quote"] = { fg = c.comment, italic = true },

  -- Python, as Cursor colors it: plain names, gold parameters, lavender
  -- calls, italic import and control-flow keywords
  ["@variable.python"] = { fg = c.fg },
  ["@variable.parameter.python"] = { fg = c.gold },
  ["@function.call.python"] = { fg = c.lavender },
  ["@function.method.call.python"] = { fg = c.lavender },
  ["@constructor.python"] = { fg = c.lavender },
  ["@punctuation.special.python"] = { fg = c.gold },
  ["@keyword.import.python"] = { fg = c.teal, italic = true },
  ["@keyword.conditional.python"] = { fg = c.teal, italic = true },
  ["@keyword.repeat.python"] = { fg = c.teal, italic = true },
  ["@keyword.return.python"] = { fg = c.teal, italic = true },
  ["@keyword.exception.python"] = { fg = c.teal, italic = true },

  -- JavaScript / TypeScript variables are sky blue in Cursor
  ["@variable.javascript"] = { fg = c.sky },
  ["@variable.typescript"] = { fg = c.sky },

  -- CSS: selectors teal, .class gold, #id lavender, property names sky,
  -- values pink, sizes yellow
  ["@tag.css"] = { fg = c.teal },
  ["@type.css"] = { fg = c.gold },
  ["@constant.css"] = { fg = c.lavender },
  ["@attribute.css"] = { fg = c.text2 },
  ["@character.special.css"] = { fg = c.teal },
  ["@property.css"] = { fg = c.sky },
  ["@variable.css"] = { fg = c.sky },
  ["@string.css"] = { fg = c.pink },
  ["@operator.css"] = { fg = c.text2 },

  -- JSON keys are teal
  ["@property.json"] = { fg = c.teal },
}

-- Text between HTML tags stays plain, as in Cursor
for _, g in ipairs({ "heading", "heading.1", "heading.2", "heading.3", "heading.4",
                     "heading.5", "heading.6", "strong", "italic", "underline",
                     "strikethrough", "link.label", "raw" }) do
  groups["@markup." .. g .. ".html"] = { fg = c.fg }
end

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
