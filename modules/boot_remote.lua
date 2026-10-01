-- modules/boot_remote.lua — menubar control for safe dual-boot switching.
local M = {}

local backend = hs.configdir .. "/tools/reboot-remote"
local config = hs.configdir .. "/local_config/boot_remote.conf"
local tasks = {}
local menu = nil
local state = "not checked"

local function trim(value)
  return (value or ""):match("^%s*(.-)%s*$")
end

local function combinedOutput(stdout, stderr)
  local out = trim(stdout)
  local err = trim(stderr)
  if out ~= "" and err ~= "" then return out .. "\n\n" .. err end
  if out ~= "" then return out end
  if err ~= "" then return err end
  return "No output"
end

local function setState(value, icon)
  state = value
  if menu then menu:setTitle(icon or "⇄") end
end

local function run(target, option, callback)
  local key = target .. option
  if tasks[key] then
    hs.alert.show("A " .. target .. " boot check is already running", 3)
    return
  end

  setState("checking " .. target .. "…", "⇄…")
  local task
  task = hs.task.new(backend, function(exitCode, stdout, stderr)
    tasks[key] = nil
    local output = combinedOutput(stdout, stderr)
    if exitCode == 0 then
      setState(target .. " preflight passed", "⇄✓")
    else
      setState(target .. " preflight failed", "⇄!")
    end
    if callback then callback(exitCode, output) end
  end, {target, option})
  tasks[key] = task

  if not task or not task:start() then
    tasks[key] = nil
    setState("could not start backend", "⇄!")
    hs.alert.show("Could not start the remote boot check", 5)
  end
end

local function shellQuote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function appleScriptQuote(value)
  return value:gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function openLiveTerminal(target)
  local command = shellQuote(backend) .. " " .. shellQuote(target) .. " --execute"
  local source = 'tell application "Terminal"\n'
    .. 'activate\n'
    .. 'do script "' .. appleScriptQuote(command) .. '"\n'
    .. 'end tell'
  local ok, result = hs.osascript.applescript(source)
  if not ok then
    hs.alert.show("Could not open Terminal: " .. tostring(result), 6)
  end
end

function M.dryRun(target)
  run(target, "--dry-run", function(exitCode, output)
    hs.dialog.blockAlert(
      exitCode == 0 and "Remote boot dry run passed" or "Remote boot dry run failed",
      output,
      "OK",
      nil,
      exitCode == 0 and "informational" or "critical"
    )
  end)
end

function M.requestLive(target)
  run(target, "--dry-run", function(exitCode, output)
    if exitCode ~= 0 then
      hs.dialog.blockAlert("Cannot reboot to " .. target, output, "OK", nil, "critical")
      return
    end

    local button = hs.dialog.blockAlert(
      "Reboot remote PC to " .. target .. "?",
      output .. "\n\nLive mode will open Terminal and require you to type “" .. target .. "”.",
      "Open live command",
      "Cancel",
      "critical"
    )
    if button == "Open live command" then openLiveTerminal(target) end
  end)
end

function M.check(target)
  run(target, "--check", function(exitCode, output)
    hs.dialog.blockAlert(
      exitCode == 0 and (target .. " is ready") or (target .. " is not ready"),
      output,
      "OK",
      nil,
      exitCode == 0 and "informational" or "critical"
    )
  end)
end

function M.popup()
  if menu then menu:popupMenu(hs.mouse.absolutePosition()) end
end

function M.rows()
  return {
    {
      id = "remote_boot_menu",
      mods = {"ctrl", "alt", "cmd", "shift"},
      key = "b",
      desc = "Remote dual-boot menu",
      cat = "Dev",
      action = {type = "fn", fn = M.popup},
    },
  }
end

function M.start()
  menu = hs.menubar.new()
  if not menu then
    hs.alert.show("Could not create the remote boot menubar", 5)
    return
  end
  menu:setTitle("⇄")
  menu:setTooltip("Remote dual-boot control")
  menu:setMenu(function()
    local configured = hs.fs.attributes(config) ~= nil
    local items = {
      {title = "Remote dual-boot · " .. state, disabled = true},
    }
    if not configured then
      items[#items + 1] = {title = "Configuration missing", disabled = true}
    end
    items[#items + 1] = {title = "-"}
    items[#items + 1] = {title = "Check Omarchy SSH (for → Windows)", fn = function() M.check("windows") end}
    items[#items + 1] = {title = "Check Windows SSH/admin (for → Omarchy)", fn = function() M.check("omarchy") end}
    items[#items + 1] = {title = "-"}
    items[#items + 1] = {title = "Dry run → Windows", fn = function() M.dryRun("windows") end}
    items[#items + 1] = {title = "Dry run → Omarchy", fn = function() M.dryRun("omarchy") end}
    items[#items + 1] = {title = "-"}
    items[#items + 1] = {title = "Reboot remote PC → Windows…", fn = function() M.requestLive("windows") end}
    items[#items + 1] = {title = "Reboot remote PC → Omarchy…", fn = function() M.requestLive("omarchy") end}
    return items
  end)
end

return M
