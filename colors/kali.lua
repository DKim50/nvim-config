-- Kali: Kali Linux's code colors, to go with Ghostty's "Kali Dark" theme.
-- Taken from the Kali-Dark style Kali ships for its text editors
-- (kali-themes, gtksourceview), using GNOME's rules for which part of the
-- code gets which color: cyan comments, pink keywords, blue functions
-- and types, teal-green strings, purple numbers, red escapes like \n.
-- Turn on with :colorscheme kali. init.lua picks the one that loads.

-- ===== TRANSPARENT KNOB =====
-- Change this one value and restart nvim.
--   true   see-through: the terminal's background shows through the
--          editor, file tree and tab bar (popups stay solid)
--   false  solid BG everywhere
local TRANSPARENT = true

-- ===== BACKGROUND COLOR KNOB (only used when TRANSPARENT is false) =====
--   "#23252e"  Kali's dark slate (its editor and terminal background)
local BG = "#23252e"

-- Kali-Dark's colors
local c = {
  fg = "#f8f8f0",       -- "bone white" text
  line = "#333333",     -- the line you're on
  sel = "#111111",      -- selection background
  black = "#1f2229",    -- Kali's black (popups)
  dim = "#4c4f5c",      -- spaces, line numbers
  gray = "#cccccc",
  blue = "#4a88f1",
  cyan = "#49aee6",
  green = "#5ebdab",
  purple = "#9755b3",
  pink = "#f4719d",     -- Kali's own is a darker red ("bordeaux", #bf2e5e)
  red = "#d41919",
  orange = "#fd7d00",
  yellow = "#fea44c",   -- Kali's terminal yellow
  accent = "#367bf0",   -- Kali's terminal blue (menu selection)
  white = "#ffffff",
}

vim.cmd("highlight clear")
vim.g.colors_name = "kali"
vim.o.background = "dark"

local bg = not TRANSPARENT and BG or nil

local groups = {
  -- ---------- Editor ----------
  Normal = { fg = c.fg, bg = bg },
  NormalNC = { link = "Normal" },
  NormalFloat = { fg = c.fg, bg = c.black },
  FloatBorder = { fg = c.dim, bg = c.black },
  FloatTitle = { fg = c.white, bg = c.black, bold = true },
  Cursor = { fg = c.black, bg = c.white },
  TermCursor = { reverse = true },
  CursorLine = { bg = c.line },
  CursorColumn = { bg = c.line },
  ColorColumn = { bg = c.line },
  CursorLineNr = { fg = c.fg, bold = true },
  LineNr = { fg = c.dim },
  SignColumn = { bg = bg },
  FoldColumn = { fg = c.dim, bg = bg },
  Folded = { fg = c.gray, bg = c.line },
  EndOfBuffer = { fg = c.dim },
  NonText = { fg = c.dim },
  Whitespace = { fg = c.dim },
  SpecialKey = { fg = c.dim },
  Conceal = { fg = c.gray },
  -- Kali's selection turns the text blue on near-black
  Visual = { fg = c.blue, bg = c.sel },
  Search = { fg = c.sel, bg = c.blue },
  CurSearch = { fg = c.sel, bg = c.orange, bold = true },
  IncSearch = { link = "CurSearch" },
  Substitute = { fg = c.sel, bg = c.orange },
  -- Kali underlines the matching bracket
  MatchParen = { underline = true, bold = true },
  Pmenu = { fg = c.fg, bg = c.black },
  PmenuSel = { fg = c.white, bg = c.accent, bold = true },
  PmenuKind = { fg = c.gray, bg = c.black },
  PmenuExtra = { fg = c.gray, bg = c.black },
  PmenuMatch = { fg = c.cyan, bg = c.black, bold = true },
  PmenuSbar = { bg = c.line },
  PmenuThumb = { bg = c.dim },
  WildMenu = { link = "PmenuSel" },
  StatusLine = { fg = c.fg, bg = c.line },
  StatusLineNC = { fg = c.gray, bg = c.black },
  TabLine = { fg = c.gray, bg = c.black },
  TabLineSel = { fg = c.white, bg = bg, bold = true },
  TabLineFill = { bg = bg },
  WinBar = { fg = c.fg, bold = true },
  WinBarNC = { fg = c.gray },
  WinSeparator = { fg = c.dim },
  Title = { fg = c.blue, bold = true },
  Directory = { fg = c.blue },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.orange },
  ModeMsg = { fg = c.fg, bold = true },
  MoreMsg = { fg = c.green },
  Question = { fg = c.green },
  QuickFixLine = { bg = c.line, bold = true },
  SpellBad = { undercurl = true, sp = c.red },
  SpellCap = { undercurl = true, sp = c.blue },
  SpellRare = { undercurl = true, sp = c.purple },
  SpellLocal = { undercurl = true, sp = c.green },

  -- ---------- Git and diffs (added green, changed pink, removed purple) ----------
  DiffAdd = { bg = "#2f4347" },
  DiffChange = { bg = "#4d3444" },
  DiffDelete = { fg = c.purple, bg = "#3a2f49" },
  DiffText = { bg = "#77435a" },
  Added = { fg = c.green },
  Changed = { fg = c.pink },
  Removed = { fg = c.purple },

  -- ---------- Errors and warnings from the language server ----------
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.orange },
  DiagnosticInfo = { fg = c.cyan },
  DiagnosticHint = { fg = c.gray },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.orange },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.cyan },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.gray },
  LspReferenceText = { bg = c.dim },
  LspReferenceRead = { bg = c.dim },
  LspReferenceWrite = { bg = c.dim },
  LspInlayHint = { fg = c.dim, italic = true },
  LspSignatureActiveParameter = { fg = c.orange, bold = true },

  -- ---------- Code (Kali-Dark) ----------
  Comment = { fg = c.cyan },
  Constant = { fg = c.blue },
  String = { fg = c.green },
  Character = { fg = c.blue },
  Number = { fg = c.purple },
  Float = { fg = c.purple },
  Boolean = { fg = c.purple },
  Identifier = { fg = c.pink },
  Function = { fg = c.blue },
  Statement = { fg = c.pink },
  Conditional = { link = "Statement" },
  Repeat = { link = "Statement" },
  Label = { link = "Statement" },
  Keyword = { link = "Statement" },
  Exception = { link = "Statement" },
  -- GNOME colors operators (= + >) like keywords
  Operator = { fg = c.pink },
  PreProc = { fg = c.pink },
  Include = { link = "PreProc" },
  Define = { link = "PreProc" },
  Macro = { link = "PreProc" },
  PreCondit = { link = "PreProc" },
  Type = { fg = c.blue },
  StorageClass = { link = "Type" },
  Structure = { link = "Type" },
  Typedef = { link = "Type" },
  -- built-ins like print, len, int
  Special = { fg = c.cyan },
  SpecialChar = { fg = c.red },
  Tag = { fg = c.pink },
  Delimiter = { fg = c.fg },
  SpecialComment = { fg = c.cyan, bold = true },
  Debug = { fg = c.red },
  Underlined = { fg = c.cyan, underline = true },
  Ignore = { fg = c.dim },
  Error = { fg = c.white, bg = c.red, bold = true },
  Todo = { fg = c.blue, bg = c.yellow, bold = true },

  -- Treesitter: plain text for names, like Kali's editor
  ["@variable"] = { fg = c.fg },
  ["@variable.member"] = { fg = c.fg },
  ["@variable.builtin"] = { link = "Identifier" },
  ["@property"] = { fg = c.fg },
  ["@module"] = { fg = c.fg },
  ["@keyword.import"] = { link = "PreProc" },
  ["@function.builtin"] = { link = "Special" },
  ["@type.builtin"] = { link = "Special" },
  ["@constructor"] = { link = "Function" },
  ["@constant.builtin"] = { link = "Constant" },
  ["@string.escape"] = { link = "SpecialChar" },
  ["@punctuation.special"] = { fg = c.blue },
  ["@tag.attribute"] = { link = "Type" },
  ["@tag.delimiter"] = { fg = c.fg },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.strong"] = { fg = c.purple, bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.raw"] = { fg = c.green },
  ["@markup.list"] = { fg = c.purple, bold = true },
  ["@markup.link"] = { fg = c.cyan, bold = true },
  ["@markup.link.label"] = { fg = c.cyan },
  ["@markup.link.url"] = { fg = c.fg, italic = true, underline = true },
  ["@markup.quote"] = { fg = c.gray, italic = true },

  -- CSS, by GNOME's CSS rules: tag selectors blue, .class and #id
  -- pink, :hover blue, property names pink, values blue, sizes purple
  ["@tag.css"] = { fg = c.blue },
  ["@type.css"] = { fg = c.pink },
  ["@constant.css"] = { fg = c.pink },
  ["@attribute.css"] = { fg = c.blue },
  ["@character.special.css"] = { fg = c.fg },
  ["@property.css"] = { fg = c.pink },
  ["@variable.css"] = { fg = c.pink },
  ["@string.css"] = { fg = c.blue },
  ["@operator.css"] = { fg = c.fg },
  ["@operator.html"] = { fg = c.fg },
}

-- Text between HTML tags stays plain (Kali's editor and VS Code agree),
-- not styled like Markdown headings and bold text
for _, g in ipairs({ "heading", "heading.1", "heading.2", "heading.3", "heading.4",
                     "heading.5", "heading.6", "strong", "italic", "underline",
                     "strikethrough", "link.label", "raw" }) do
  groups["@markup." .. g .. ".html"] = { fg = c.fg }
end

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
