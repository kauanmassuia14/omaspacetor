-- Optional keyboard integration for ~/.config/hypr/bindings.lua.
-- Append this file there after installing the plugin to make Super+number
-- choose that number on the currently focused monitor.
local pluginPath = (os.getenv("HOME") or "") .. "/.config/omarchy/plugins/kauanmassuia14.omaspacetor"
local workspaceFocus = pluginPath .. "/focus-workspace.py"

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

for slot = 1, 10 do
  local key = slot == 10 and "0" or tostring(slot)
  hl.unbind("SUPER + " .. key)
  o.bind(
    "SUPER + " .. key,
    "Workspace " .. slot .. " on this monitor",
    "python3 " .. shellQuote(workspaceFocus) .. " " .. slot
  )
end
