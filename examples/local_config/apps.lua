-- Copy this file to local_config/apps.lua and replace only the examples.
url1 = "https://example.com/dashboard-1"
url2 = "https://example.com/dashboard-2"
url3 = "https://example.com/dashboard-3"
url4 = "https://example.com/dashboard-4"
url5 = "https://example.com/dashboard-5"
url6 = "https://example.com/dashboard-6"

local M = {}
local home = os.getenv("HOME") or ""

M.CHROME_APPS = home .. "/Applications/Chrome Apps.localized/"
M.REMOTE_HOST = "linux-box.local"
M.REMOTE_LABEL = "Linux box"

function M.pwa(name)
  return M.CHROME_APPS .. name .. ".app"
end

return M
