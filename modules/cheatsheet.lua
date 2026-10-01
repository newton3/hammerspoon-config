-- modules/cheatsheet.lua — searchable overlay of every binding, built live from
-- the registry + counts so it never goes stale. Trigger: ⌃⌥⌘/
local util    = require("modules.util")
local core    = require("modules.bindings_core")
local counter = require("modules.counter")

local M = {}
M.chooser = nil

local CAT_ORDER = { Window = 1, Apps = 2, Work = 3, Dev = 4, Text = 5, Config = 6 }

local function buildChoices()
  local rows = {}
  for _, b in ipairs(core.registry) do
    local c = counter.counts[b.id]
    local count = (c and c.count) or 0
    rows[#rows + 1] = {
      text    = util.prettyCombo(b.mods, b.key) .. "   " .. b.desc,
      subText = (b.cat or "?") .. "  ·  used " .. count .. "×",
      _cat    = b.cat or "?",
      _combo  = b._combo or "",
      _count  = count,
    }
  end
  table.sort(rows, function(a, b)
    local ca, cb = CAT_ORDER[a._cat] or 99, CAT_ORDER[b._cat] or 99
    if ca ~= cb then return ca < cb end
    return a._combo < b._combo
  end)
  -- Surface any detected conflicts at the very top.
  for i = #core.conflicts, 1, -1 do
    local cf = core.conflicts[i]
    table.insert(rows, 1, {
      text    = "⚠ CONFLICT  " .. cf.combo,
      subText = "'" .. tostring(cf.b) .. "' overrides '" .. tostring(cf.a) .. "'",
    })
  end
  return rows
end

function M.show()
  if not M.chooser then
    M.chooser = hs.chooser.new(function(_choice) end)  -- selection is a no-op; it's a reference sheet
    M.chooser:searchSubText(true)
  end
  M.chooser:choices(buildChoices())
  M.chooser:show()
end

function M.rows()
  return {
    { id = "sys_cheatsheet", mods = { "ctrl", "alt", "cmd" }, key = "/",
      desc = "Show hotkey cheatsheet", cat = "System", action = { type = "fn", fn = M.show } },
  }
end

return M
