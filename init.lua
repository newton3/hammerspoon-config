-- ~/.hammerspoon/init.lua — thin loader.
-- The former flat config is now split into modules/, config/, helpers/.
--
--   modules/   util, tracker, counter, bindings_core, window, cheatsheet, reports
--   config/    public defaults + loaders for optional local configuration
--   helpers/   browser helpers + public/local macro loader
--   local_config/  machine-specific configuration (ignored by Git)
--   usage/     runtime data: focus.jsonl, counts.json, reports/
--   tools/     manual historical-analysis scripts (run after Full Disk Access)

hs.window.animationDuration = 0  -- snappy window tiling

local util    = require("modules.util")
util.ensureDirs()

local counter = require("modules.counter"); counter.start()   -- load counts before binding
local tracker = require("modules.tracker"); tracker.start()   -- start logging focus now
local core    = require("modules.bindings_core")
local window  = require("modules.window")
local cheat   = require("modules.cheatsheet")
local reports = require("modules.reports")
local boot    = require("modules.boot_remote")

-- Gather every binding (config + tiling + system) and bind through one path so
-- all get conflict detection, usage counting, and cheatsheet registration.
local rows = {}
local function add(list) for _, r in ipairs(list) do rows[#rows + 1] = r end end
add(require("config.bindings"))
add(window.rows())
add(cheat.rows())
add(reports.rows())
add(boot.rows())

core.bindAll(rows)
reports.startPeriodic()
boot.start()

-- Single shutdown hook chains all flushes (avoids clobbering hs.shutdownCallback).
hs.shutdownCallback = function()
  pcall(function() tracker.flush() end)
  pcall(function() counter.flush() end)
end

hs.alert.show("Hammerspoon loaded · " .. #core.registry .. " bindings"
  .. (#core.conflicts > 0 and (" · ⚠ " .. #core.conflicts .. " conflicts") or ""))
