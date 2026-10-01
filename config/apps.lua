-- Select the machine-local app settings when present, otherwise use the
-- publishable defaults. Local errors are intentionally not swallowed.
local localPath = hs.configdir .. "/local_config/apps.lua"
if hs.fs.attributes(localPath) then
  return require("local_config.apps")
end

return require("config.apps_public")
