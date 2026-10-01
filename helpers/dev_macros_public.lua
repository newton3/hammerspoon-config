-- Publishable non-browser actions: remote access, launchers, key remaps, and
-- dictionary lookup. Keep private command sequences in local_config/.
local apps = require("config.apps")
local M = {}

local REMOTE_HOST = apps.REMOTE_HOST or "linux-box.local"
local REMOTE_LABEL = apps.REMOTE_LABEL or "Remote Linux"
local SSH_BUNDLE = "com.googlecode.iterm2"
local VNC_BUNDLE = "com.apple.ScreenSharing"
local LOCAL_VNC_PORT = "5901"
local CONTROL_PATH = "/tmp/hammerspoon-remote-vnc-" .. (os.getenv("USER") or "user") .. ".sock"

local checkTask = nil
local tunnelTask = nil

local function openURL(url, bundleID, label)
  if not hs.urlevent.openURLWithBundle(url, bundleID) then
    hs.alert.show("Could not open " .. label, 5)
    return false
  end
  return true
end

function M.remoteSSH()
  openURL("ssh://" .. REMOTE_HOST, SSH_BUNDLE, "SSH to " .. REMOTE_LABEL)
end

local function openRemoteDesktop()
  openURL("vnc://127.0.0.1:" .. LOCAL_VNC_PORT, VNC_BUNDLE,
    "Screen Sharing for " .. REMOTE_LABEL)
end

local function conciseError(stderr)
  local message = (stderr or ""):match("^%s*(.-)%s*$")
  if message == "" then message = "SSH tunnel failed" end
  if #message > 220 then message = message:sub(1, 217) .. "..." end
  return message
end

local function startTunnel()
  os.remove(CONTROL_PATH)
  tunnelTask = hs.task.new("/usr/bin/ssh", function(exitCode, _stdout, stderr)
    tunnelTask = nil
    if exitCode == 0 then
      hs.timer.doAfter(0.2, openRemoteDesktop)
    else
      hs.alert.show(REMOTE_LABEL .. " desktop unavailable\n" .. conciseError(stderr)
        .. "\nOpen SSH once to establish host trust.", 8)
    end
  end, {
    "-fN",
    "-M", "-S", CONTROL_PATH,
    "-o", "BatchMode=yes",
    "-o", "ConnectTimeout=5",
    "-o", "ExitOnForwardFailure=yes",
    "-o", "ServerAliveInterval=30",
    "-o", "ServerAliveCountMax=3",
    "-L", LOCAL_VNC_PORT .. ":127.0.0.1:5900",
    REMOTE_HOST,
  })

  if not tunnelTask or not tunnelTask:start() then
    tunnelTask = nil
    hs.alert.show("Could not start the SSH tunnel to " .. REMOTE_LABEL, 5)
  end
end

function M.remoteDesktop()
  if checkTask or tunnelTask then
    hs.alert.show("Connecting to " .. REMOTE_LABEL .. "…", 2)
    return
  end

  checkTask = hs.task.new("/usr/bin/ssh", function(exitCode)
    checkTask = nil
    if exitCode == 0 then openRemoteDesktop() else startTunnel() end
  end, {
    "-S", CONTROL_PATH,
    "-O", "check",
    "-o", "BatchMode=yes",
    REMOTE_HOST,
  })

  if not checkTask or not checkTask:start() then
    checkTask = nil
    hs.alert.show("Could not check the SSH tunnel to " .. REMOTE_LABEL, 5)
  end
end

function M.copyPath(value)
  return function()
    hs.pasteboard.setContents(value)
    hs.alert.show("Copied to clipboard: " .. value)
  end
end

function M.exec(command)
  return function() hs.execute(command, true) end
end

function M.keyStroke(mods, key)
  return function() hs.eventtap.keyStroke(mods, key) end
end

function M.reload()
  hs.reload()
end

function M.fetchWordDetails(word)
  local apiURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    .. hs.http.encodeForQuery(word)
  hs.http.asyncGet(apiURL, nil, function(status, body)
    if status == 200 then
      local result = hs.json.decode(body)
      if result and #result > 0 then
        local info = result[1]
        local pronunciation = info.phonetics[1] and info.phonetics[1].text or "N/A"
        local meaning = info.meanings[1] and info.meanings[1].definitions[1].definition or "N/A"
        local synonyms = info.meanings[1] and info.meanings[1].synonyms or {}
        local synonymsText = table.concat(synonyms, ", ")
        if synonymsText == "" then synonymsText = "N/A" end
        hs.alert.show(string.format(
          "Word: %s\nPronunciation: %s\nMeaning: %s\nSynonyms: %s",
          word, pronunciation, meaning, synonymsText))
      else
        hs.alert.show("No information found for the word: " .. word, 5)
      end
    else
      hs.alert.show("Failed to fetch word details. Status: " .. status)
    end
  end)
end

function M.getSelectedText()
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.doAfter(0.1, function()
    local selectedText = hs.pasteboard.getContents()
    if selectedText and selectedText ~= "" then
      M.fetchWordDetails(selectedText)
    else
      hs.alert.show("No text selected")
    end
  end)
end

return M
