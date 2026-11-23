-- Tango: Linux's Tango colors, to go with Ghostty's "Builtin Tango Dark".
-- Code colors follow GNOME's dark Tango style for code (Oblivion, from
-- GNOME's text editor): white bold keywords, yellow strings, green bold
-- types, sky-blue functions, plum imports and decorators, orange special
-- values (None, True, \n), gray comments.
-- Turn on with :colorscheme tango. init.lua picks the one that loads.

-- ===== TRANSPARENT KNOB =====
-- Change this one value and restart nvim.
--   true   see-through: the terminal's background shows through the
--          editor, file tree and tab bar (popups stay solid)
--   false  solid BG everywhere
local TRANSPARENT = true

-- ===== BACKGROUND COLOR KNOB (only used when TRANSPARENT is false) =====
--   "#000000"  black, like Ghostty's Tango Dark
--   "#2e3436"  GNOME's dark gray (Oblivion)
local BG = "#000000"

-- The Tango palette (tango.freedesktop.org), 1 = lightest
local c = {
  butter1 = "#fce94f", butter2 = "#edd400",
  chameleon1 = "#8ae234", chameleon2 = "#73d216", chameleon3 = "#4e9a06",
  orange1 = "#fcaf3e", orange2 = "#f57900",
  skyblue1 = "#729fcf", skyblue2 = "#3465a4", skyblue3 = "#204a87",
  plum1 = "#ad7fa8",
  red1 = "#ef2929",
  alu1 = "#eeeeec", alu2 = "#d3d7cf", alu3 = "#babdb6",
  alu4 = "#888a85", alu5 = "#555753", alu6 = "#2e3436",
  white = "#ffffff", black = "#000000",
}

vim.cmd("highlight clear")
vim.g.colors_name = "tango"
vim.o.background = "dark"

local bg = not TRANSPARENT and BG or nil

local groups = {
  -- ---------- Editor ----------
  Normal = { fg = c.alu2, bg = bg },
  NormalNC = { link = "Normal" },
  NormalFloat = { fg = c.alu2, bg = c.alu6 },
  FloatBorder = { fg = c.alu4, bg = c.alu6 },
  FloatTitle = { fg = c.alu1, bg = c.alu6, bold = true },
  Cursor = { fg = c.black, bg = c.alu2 },
  TermCursor = { reverse = true },
  CursorLine = { bg = c.alu6 },
  CursorColumn = { bg = c.alu6 },
  ColorColumn = { bg = c.alu6 },
  CursorLineNr = { fg = c.alu1, bold = true },
  LineNr = { fg = c.alu5 },
  SignColumn = { bg = bg },
  FoldColumn = { fg = c.alu5, bg = bg },
  Folded = { fg = c.alu4, bg = c.alu6 },
  EndOfBuffer = { fg = c.alu6 },
  NonText = { fg = c.alu5 },
  Whitespace = { fg = c.alu6 },
  SpecialKey = { fg = c.alu5 },
  Conceal = { fg = c.alu4 },
  -- GNOME's selection: Tango gray at 30% over the dark background
  Visual = { bg = "#494e4e" },
  Search = { fg = c.alu1, bg = c.chameleon3 },
  CurSearch = { fg = c.black, bg = c.orange1, bold = true },
  IncSearch = { link = "CurSearch" },
  Substitute = { fg = c.black, bg = c.orange1 },
  MatchParen = { fg = c.alu1, bg = c.alu4, bold = true },
  Pmenu = { fg = c.alu2, bg = c.alu6 },
  PmenuSel = { fg = c.white, bg = c.skyblue2, bold = true },
  PmenuKind = { fg = c.alu4, bg = c.alu6 },
  PmenuExtra = { fg = c.alu4, bg = c.alu6 },
  PmenuMatch = { fg = c.chameleon1, bg = c.alu6, bold = true },
  PmenuSbar = { bg = c.alu5 },
  PmenuThumb = { bg = c.alu4 },
  WildMenu = { link = "PmenuSel" },
  StatusLine = { fg = c.alu1, bg = c.alu5 },
  StatusLineNC = { fg = c.alu4, bg = c.alu6 },
  TabLine = { fg = c.alu4, bg = c.alu6 },
  TabLineSel = { fg = c.alu1, bg = bg, bold = true },
  TabLineFill = { bg = bg },
  WinBar = { fg = c.alu2, bold = true },
  WinBarNC = { fg = c.alu4 },
  WinSeparator = { fg = c.alu5 },
  Title = { fg = c.chameleon1, bold = true },
  Directory = { fg = c.skyblue1 },
  ErrorMsg = { fg = c.red1, bold = true },
  WarningMsg = { fg = c.orange1 },
  ModeMsg = { fg = c.alu1, bold = true },
  MoreMsg = { fg = c.chameleon1 },
  Question = { fg = c.chameleon1 },
  QuickFixLine = { bg = c.alu6, bold = true },
  SpellBad = { undercurl = true, sp = c.red1 },
  SpellCap = { undercurl = true, sp = c.skyblue1 },
  SpellRare = { undercurl = true, sp = c.plum1 },
  SpellLocal = { undercurl = true, sp = c.chameleon1 },

  -- ---------- Git and diffs ----------
  DiffAdd = { bg = "#172e02" },
  DiffChange = { bg = "#0d1e36" },
  DiffDelete = { fg = c.red1, bg = "#390000" },
  DiffText = { bg = c.skyblue3 },
  Added = { fg = c.chameleon2 },
  Changed = { fg = c.skyblue1 },
  Removed = { fg = c.red1 },

  -- ---------- Errors and warnings from the language server ----------
  DiagnosticError = { fg = c.red1 },
  DiagnosticWarn = { fg = c.orange1 },
  DiagnosticInfo = { fg = c.skyblue1 },
  DiagnosticHint = { fg = c.alu3 },
  DiagnosticOk = { fg = c.chameleon1 },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red1 },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.orange1 },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.skyblue1 },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.alu3 },
  LspReferenceText = { bg = c.alu5 },
  LspReferenceRead = { bg = c.alu5 },
  LspReferenceWrite = { bg = c.alu5 },
  LspInlayHint = { fg = c.alu4, italic = true },
  LspSignatureActiveParameter = { fg = c.orange1, bold = true },

  -- ---------- Code (GNOME's Oblivion style) ----------
  Comment = { fg = c.alu4 },
  Constant = { fg = c.butter2 },
  String = { fg = c.butter2 },
  Character = { fg = c.butter2 },
  Number = { fg = c.butter2 },
  Boolean = { fg = c.orange2 },
  Float = { fg = c.orange2 },
  Identifier = { fg = c.skyblue1 },
  Function = { fg = c.skyblue1 },
  Statement = { fg = c.white, bold = true },
  Conditional = { link = "Statement" },
  Repeat = { link = "Statement" },
  Label = { link = "Statement" },
  Keyword = { link = "Statement" },
  Exception = { link = "Statement" },
  Operator = { fg = c.alu2 },
  PreProc = { fg = c.plum1 },
  Include = { link = "PreProc" },
  Define = { link = "PreProc" },
  Macro = { link = "PreProc" },
  PreCondit = { link = "PreProc" },
  Type = { fg = c.chameleon1, bold = true },
  StorageClass = { link = "Type" },
  Structure = { link = "Type" },
  Typedef = { link = "Type" },
  Special = { fg = c.orange2 },
  SpecialChar = { fg = c.orange2 },
  Tag = { fg = c.skyblue1 },
  Delimiter = { fg = c.alu2 },
  SpecialComment = { fg = c.alu4, bold = true },
  Debug = { fg = c.orange2 },
  Underlined = { fg = c.skyblue1, underline = true },
  Ignore = { fg = c.alu5 },
  Error = { fg = c.red1, bold = true },
  Todo = { fg = c.butter1, bg = c.black, bold = true },

  -- Treesitter: plain text for names, like GNOME's editor
  ["@variable"] = { fg = c.alu2 },
  ["@variable.member"] = { fg = c.alu2 },
  ["@variable.builtin"] = { link = "Special" },
  ["@property"] = { fg = c.alu2 },
  ["@property.css"] = { fg = c.skyblue1 },
  ["@module"] = { fg = c.alu2 },
  ["@keyword.import"] = { link = "PreProc" },
  ["@function.builtin"] = { link = "Function" },
  ["@constructor"] = { link = "Type" },
  ["@type.builtin"] = { link = "Type" },
  ["@constant.builtin"] = { link = "Special" },
  ["@tag.attribute"] = { fg = c.chameleon1 },
  ["@tag.delimiter"] = { fg = c.alu4 },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.raw"] = { fg = c.skyblue1 },
  ["@markup.list"] = { fg = c.white, bold = true },
  ["@markup.strong"] = { fg = c.white, bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.link.label"] = { fg = c.skyblue1 },
  ["@markup.link.url"] = { fg = c.skyblue1, italic = true, underline = true },
  ["@markup.quote"] = { fg = c.alu4, italic = true },
}

-- Text between HTML tags stays plain (GNOME's editor and VS Code agree),
-- not styled like Markdown headings and bold text
for _, g in ipairs({ "heading", "heading.1", "heading.2", "heading.3", "heading.4",
                     "heading.5", "heading.6", "strong", "italic", "underline",
                     "strikethrough", "link.label", "raw" }) do
  groups["@markup." .. g .. ".html"] = { fg = c.alu2 }
end

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
