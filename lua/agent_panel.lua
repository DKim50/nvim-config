-- Agent panel: one AI panel on the right with two views, both run by
-- CodeCompanion. Swap between them and pick any agent for either one.
-- Separate from the Ctrl-\ terminal.
--   chat      a chat buffer (normal Neovim text): ACP agents like OpenCode,
--             or models straight from Ollama
--   terminal  an agent's own terminal app: Claude Code, Orion, Codex... or a
--             plain shell
-- The agents themselves are listed in init.lua (the codecompanion block).
local M = {}

M.view = "chat"        -- the view the panel shows when opened: "chat" or "terminal"
M.chat_choices = {}    -- { label, adapter } pairs for the picker, set by setup()

local term             -- the terminal agent the panel shows (a CodeCompanion CLI)

local function cc() return require("codecompanion") end
local function Chat() return require("codecompanion.interactions.chat") end
local function CLI() return require("codecompanion.interactions.cli") end

local function chat_visible() return Chat().is_visible() end
local function term_visible()
  return term ~= nil and vim.api.nvim_buf_is_valid(term.bufnr) and term.ui:is_visible()
end

-- Hide whatever the panel shows. Every CLI counts, not just ours, so an agent
-- opened with :CodeCompanionCLI doesn't end up beside the panel.
local function hide()
  if Chat().is_visible() then Chat().last_chat().ui:hide() end
  local cli = CLI().get_visible()
  while cli do
    cli.ui:hide()
    cli = CLI().get_visible()
  end
end

local function show_chat()
  if chat_visible() then
    vim.api.nvim_set_current_win(Chat().last_chat().ui.winnr)
  else
    local code_buf = vim.api.nvim_get_current_buf()
    hide()
    -- Opens the last chat, or starts one with the default agent. Passing the
    -- code buffer makes #{buffer} in the chat mean the file you came from.
    cc().toggle_chat({ context = require("codecompanion.utils.context").get(code_buf) })
  end
  M.view = "chat"
end

-- agent: a name from the terminal agents in init.lua; nil = the current one
local function show_term(agent)
  if agent and (not term or term.agent_name ~= agent) then
    term = CLI().find_by_agent(agent)
  end
  if not (term and vim.api.nvim_buf_is_valid(term.bufnr)) then
    term = CLI().create({ agent = agent })  -- starts the agent (nil = the default)
  end
  if not term then return end
  if not term_visible() then
    hide()
    term.ui:open()
  end
  term:focus()
  M.view = "terminal"
end

local function show(view)
  if view == "terminal" then show_term() else show_chat() end
end

-- Space a a: open / close the panel
function M.toggle()
  if chat_visible() or term_visible() or CLI().is_visible() then
    hide()
  else
    show(M.view)
  end
end

-- Space a s: swap the panel's view, chat <-> terminal
function M.swap()
  local showing = term_visible() and "terminal" or chat_visible() and "chat" or nil
  if showing then
    show(showing == "chat" and "terminal" or "chat")
  else
    show(M.view)
  end
end

-- Space a p: pick an agent for the panel. A chat choice starts a new chat with
-- it; a terminal choice shows that agent (starting it if it isn't running).
function M.pick()
  local items = {}
  for _, c in ipairs(M.chat_choices) do
    table.insert(items, { view = "chat", label = "Chat       " .. c.label, adapter = c.adapter })
  end
  local agents = require("codecompanion.config").interactions.cli.agents
  local names = vim.tbl_keys(agents)
  table.sort(names)
  for _, name in ipairs(names) do
    table.insert(items, { view = "terminal", label = "Terminal   " .. (agents[name].description or name), agent = name })
  end
  vim.ui.select(items, {
    prompt = "Agent panel",
    format_item = function(item) return item.label end,
  }, function(item)
    if not item then return end
    if item.view == "chat" then
      hide()
      cc().chat({ params = { adapter = item.adapter } })
      M.view = "chat"
    else
      show_term(item.agent)
    end
  end)
end

-- Space a c: send the selection (visual mode) or the current file (normal
-- mode) to the panel's view, then put the cursor there to type your question
function M.send()
  local visual = vim.fn.mode():match("^[vV\22]") ~= nil
  if M.view == "terminal" then
    local agent = term and vim.api.nvim_buf_is_valid(term.bufnr) and term.agent_name or nil
    -- #{this} = the selection, or the file as an @path. It's typed into the
    -- agent (queued until the agent is ready) but not submitted.
    cc().cli("#{this}", { agent = agent, focus = false })
    term = agent and CLI().find_by_agent(agent) or CLI().last_cli()
    show_term()
  elseif visual then
    hide()
    cc().add({})  -- pastes the selected lines into the chat as a code block
    M.view = "chat"
  else
    show_chat()
    -- #{buffer} shares the file with the agent when you send your message
    local chat = Chat().last_chat()
    local last = vim.api.nvim_buf_line_count(chat.bufnr)
    local line = vim.api.nvim_buf_get_lines(chat.bufnr, last - 1, last, false)[1]
    vim.api.nvim_buf_set_text(chat.bufnr, last - 1, #line, last - 1, #line, { (line == "" and "" or " ") .. "#{buffer} " })
    vim.api.nvim_win_set_cursor(0, { last, 0 })
    vim.cmd("startinsert!")
  end
end

---@param opts { view?: "chat"|"terminal", chat_choices?: { label: string, adapter: string }[] }
function M.setup(opts)
  M.view = opts.view or M.view
  M.chat_choices = opts.chat_choices or M.chat_choices
end

return M
