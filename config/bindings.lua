-- Select the machine-local registry when present, otherwise use the
-- publishable starter registry. Local errors are intentionally not swallowed.
local localPath = hs.configdir .. "/local_config/bindings.lua"
if hs.fs.attributes(localPath) then
  return require("local_config.bindings")
end

return require("config.bindings_public")
