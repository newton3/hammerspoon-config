-- Copy to local_config/bindings.lua. Start with the public registry, then add
-- private rows here. This entire file is excluded from Git.
local rows = require("config.bindings_public")

rows[#rows + 1] = {
  id = "url_private_dashboard",
  mods = {"alt"},
  key = "1",
  desc = "Private dashboard",
  cat = "Local",
  action = {type = "chromeUrl", url = url1},
}

return rows
