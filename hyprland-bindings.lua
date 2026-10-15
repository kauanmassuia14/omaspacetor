-- Optional keyboard integration for ~/.config/hypr/bindings.lua.
-- Super+number targets the notebook (NB); Super+Ctrl+number targets M1.
local pluginPath = (os.getenv("HOME") or "") .. "/.config/omarchy/plugins/kauanmassuia14.omaspacetor"
local workspaceFocus = pluginPath .. "/focus-workspace.py"

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function bindWorkspaceSet(modifiers, monitor)
  for slot = 1, 10 do
    local key = slot == 10 and "0" or tostring(slot)
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
