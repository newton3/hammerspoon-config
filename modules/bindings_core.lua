-- modules/bindings_core.lua — the single path every hotkey flows through.
-- Does conflict detection, usage counting, and cheatsheet registration.
local util    = require("modules.util")
local counter = require("modules.counter")
local browser = require("helpers.browser")

local M = {}
M.registry  = {}   -- ordered list of bound rows (source of truth for cheatsheet)
M.conflicts = {}   -- { combo, a, b } for each duplicate detected
M.seen      = {}   -- comboKey -> row (first binder wins the slot semantically)

-- Turn a registry row's `action` into a plain function.
local function resolveAction(action)
  local t = action.type
  if t == "app" then
    return function() hs.application.launchOrFocus(action.path) end
  elseif t == "chromeUrl" then
    return browser.chrome_active_tab_with_url(action.url)
  elseif t == "chromeName" then
    return browser.chrome_active_tab_with_name(action.name, action.url)
  elseif t == "safariUrl" then
    return browser.safari_active_tab_with_url(action.url)
  elseif t == "fn" then
    return action.fn
  end
  return function() hs.alert.show("Unknown action type: " .. tostring(t)) end
end

function M.bind(row)
  local combo = util.comboKey(row.mods, row.key)
  if M.seen[combo] then
    M.conflicts[#M.conflicts + 1] = { combo = combo, a = M.seen[combo].desc, b = row.desc }
    hs.printf("[bindings] CONFLICT %s: '%s' overrides '%s'", combo, row.desc, M.seen[combo].desc)
  end
  M.seen[combo] = row
  row._combo = combo
  M.registry[#M.registry + 1] = row

  local wrapped = counter.wrap(row.id, resolveAction(row.action))
  hs.hotkey.bind(row.mods, row.key, wrapped)
end

function M.bindAll(rows)
  for _, row in ipairs(rows) do M.bind(row) end
  counter.persist()  -- write counts.json so every id (incl. count:0) is on disk
  if #M.conflicts > 0 then
    hs.alert.show("⚠ " .. #M.conflicts .. " hotkey conflict(s) — see cheatsheet (⌃⌥⌘/)", 4)
  end
end

return M
