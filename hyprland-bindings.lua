-- Optional keyboard integration for ~/.config/hypr/bindings.lua.
-- Super+number targets the notebook (NB); Super+Ctrl+number targets M1.
local pluginPath = (os.getenv("HOME") or "") .. "/.config/omarchy/plugins/kauanmassuia14.omaspacetor"
local workspaceFocus = pluginPath .. "/focus-workspace.py"

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function bindWorkspaceSet(modifiers, monitor)
  for slot = 1, 10 do
    -- Omarchy registers its digit shortcuts as keycodes (code:10 through
    -- code:19), so use the same form to unbind the default actions reliably.
    local key = "code:" .. tostring(slot + 9)
    local binding = modifiers .. " + " .. key
    hl.unbind(binding)
    o.bind(
      binding,
      "Workspace " .. slot .. " on " .. monitor,
      "python3 " .. shellQuote(workspaceFocus) .. " " .. slot .. " " .. monitor
    )
  end
end

bindWorkspaceSet("SUPER", "NB")
bindWorkspaceSet("SUPER + CTRL", "M1")
