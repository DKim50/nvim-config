-- Orion's file icons in Neovim: the same icon for each file and folder as
-- the Orion IDE's icon theme. The pictures live in the "JetBrainsMono Orion"
-- font (Terminal must use it, or you'll see boxes); data.lua says which file
-- gets which picture.
local data = require("orion_icons.data")

local M = {}

-- Highlight group for an icon id, e.g. "folder-src" -> DevIconOrion_folder_src.
-- Terminal draws the icons in their own colors; the group's color only shows
-- if the font ever falls back to one-color icons.
local function hl_suffix(id)
  return "Orion_" .. id:gsub("[^%w]", "_")
end

local function entry(id)
  local icon = data.icons[id]
  return { icon = icon[1], color = icon[2], name = hl_suffix(id) }
end

-- Run before anything loads nvim-web-devicons: swap its built-in icon tables
-- for Orion's, so a file Orion doesn't know gets Orion's plain document icon
-- instead of a mismatched Nerd Font one.
function M.replace_devicon_tables()
  local by_name, by_ext = {}, {}
  for name, id in pairs(data.filenames) do by_name[name] = entry(id) end
  for ext, id in pairs(data.extensions) do by_ext[ext] = entry(id) end
  -- lookup keys for buffers known only by filetype (see setup_devicons)
  for id in pairs(data.icons) do by_name["orion:" .. id] = entry(id) end
  local tables = {
    icons_by_filename = by_name,
    icons_by_file_extension = by_ext,
    icons_by_operating_system = {},
    icons_by_desktop_environment = {},
    icons_by_window_manager = {},
  }
  package.loaded["nvim-web-devicons.icons-default"] = tables
  package.loaded["nvim-web-devicons.icons-light"] = tables
end

function M.setup_devicons()
  local devicons = require("nvim-web-devicons")
  -- strict: match a file by its name first, then its extension (VS Code's order)
  devicons.setup({ strict = true, default = true })
  local doc = entry(data.default_file)
  devicons.set_default_icon(doc.icon, doc.color)
  local by_ft = {}
  for ft, id in pairs(data.filetypes) do by_ft[ft] = "orion:" .. id end
  devicons.set_icon_by_filetype(by_ft)
end

local function set_folder_highlights()
  for id, icon in pairs(data.icons) do
    vim.api.nvim_set_hl(0, "DevIcon" .. hl_suffix(id), { fg = icon[2] })
  end
end

-- nvim-tree decorator: Orion's per-name folder icons (src, assets, tests, ...)
-- and its plain folder for the rest. Same icon open or closed, like Orion;
-- the arrow beside it shows which.
function M.folder_decorator()
  set_folder_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "Re-apply Orion folder icon colors",
    callback = set_folder_highlights,
  })

  local Folders = require("nvim-tree.api").Decorator:extend()
  function Folders:new()
    self.enabled = true
    self.highlight_range = "none"
    self.icon_placement = "none"
  end
  function Folders:icon_node(node)
    if node.type ~= "directory" then
      return nil
    end
    local id = data.folders[node.name:lower()] or data.default_folder
    return { str = data.icons[id][1], hl = { "DevIcon" .. hl_suffix(id) } }
  end
  return Folders
end

return M
