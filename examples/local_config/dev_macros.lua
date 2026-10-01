-- Copy to local_config/dev_macros.lua. Reuse the public helpers and add any
-- machine- or employer-specific macros here.
local M = require("helpers.dev_macros_public")

function M.exampleLocalMacro()
  hs.alert.show("Replace this with a local-only action")
end

return M
