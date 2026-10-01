-- modules/counter.lua — per-binding usage counts.
-- In-memory increments, atomic periodic flush + shutdown flush.
local util = require("modules.util")

local M = {}
M.counts = {}          -- id -> { count = n, last = epoch (0 = never) }
M.flushTimer = nil
M.dirty = false

function M.load()
  M.counts = util.readJson(util.countsFile) or {}
end

function M.seed(id)
  if M.counts[id] == nil then
    M.counts[id] = { count = 0, last = 0 }
  end
end

-- Wrap an action so every press bumps its counter, then runs the action.
-- Errors in the action are logged, never swallowed silently.
function M.wrap(id, fn)
  M.seed(id)
  return function()
    local c = M.counts[id]
    c.count = c.count + 1
    c.last = os.time()
    M.dirty = true
    local ok, err = pcall(fn)
    if not ok then hs.printf("[counter] binding '%s' errored: %s", id, tostring(err)) end
  end
end

-- Write only if something changed (called by the periodic timer).
function M.flush()
  if M.dirty then
    util.writeJsonAtomic(util.countsFile, M.counts)
    M.dirty = false
  end
end

-- Force a write regardless of dirty (used once after all bindings are seeded).
function M.persist()
  util.writeJsonAtomic(util.countsFile, M.counts)
  M.dirty = false
end

function M.start()
  M.load()
  if M.flushTimer then M.flushTimer:stop() end
  M.flushTimer = hs.timer.doEvery(120, M.flush)
end

return M
