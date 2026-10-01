-- Public, machine-independent app settings.
local M = {}

local home = os.getenv("HOME") or ""
M.CHROME_APPS = home .. "/Applications/Chrome Apps.localized/"

-- Safe defaults used by the optional remote-Linux shortcuts. Override these
-- in local_config/apps.lua on a real machine.
M.REMOTE_HOST = "linux-box.local"
M.REMOTE_LABEL = "Remote Linux"

function M.pwa(name)
  return M.CHROME_APPS .. name .. ".app"
end

return M
