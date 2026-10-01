-- Select machine-local macros when present, otherwise use publishable helpers.
-- Local errors are intentionally not swallowed.
local localPath = hs.configdir .. "/local_config/dev_macros.lua"
if hs.fs.attributes(localPath) then
  return require("local_config.dev_macros")
end

return require("helpers.dev_macros_public")
