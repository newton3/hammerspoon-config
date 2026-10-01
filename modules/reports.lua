-- modules/reports.lua — usage insights.
--   (a) on-demand summary hotkey (⌃⌥⌘.) — top apps by time + top/dead shortcuts
--   (b) periodic Markdown reports written to usage/reports/ (daily + weekly)
local util    = require("modules.util")
local core    = require("modules.bindings_core")
local counter = require("modules.counter")

local M = {}
M.dailyTimer = nil

-- ---- formatting / aggregation ----------------------------------------------
local function human(s)
  local h = math.floor(s / 3600)
  local m = math.floor((s % 3600) / 60)
  if h > 0 then return string.format("%dh %02dm", h, m) end
  return string.format("%dm", m)
end

-- Sum focus duration per app. `dayset` = nil (all) or a set of "YYYY-MM-DD".
local function aggByApp(rows, dayset)
  local totals = {}
  for _, r in ipairs(rows) do
    if (not dayset) or dayset[r.day] then
      totals[r.app] = (totals[r.app] or 0) + (r.dur or 0)
    end
  end
  local list = {}
  for app, dur in pairs(totals) do list[#list + 1] = { app = app, dur = dur } end
  table.sort(list, function(a, b) return a.dur > b.dur end)
  return list
end

local function shortcutStats()
  local used, dead = {}, {}
  for _, b in ipairs(core.registry) do
    local c = counter.counts[b.id]
    local n = (c and c.count) or 0
    if n > 0 then
      used[#used + 1] = { desc = b.desc, combo = b._combo, n = n }
    else
      dead[#dead + 1] = b.desc
    end
  end
  table.sort(used, function(a, b) return a.n > b.n end)
  return used, dead
end

local function lastNDays(n)
  local set = {}
  local now = os.time()
  for i = 0, n - 1 do
    set[os.date("%Y-%m-%d", now - i * 86400)] = true
  end
  return set
end

-- ---- (a) on-demand summary --------------------------------------------------
function M.showSummary()
  local today = os.date("%Y-%m-%d")
  local rows = util.readJsonl(util.focusLog)
  local apps = aggByApp(rows, { [today] = true })
  local used, dead = shortcutStats()

  local lines = { "📊 Today — where your time went" }
  if #apps == 0 then
    lines[#lines + 1] = "  (no focus data yet)"
  else
    for i = 1, math.min(5, #apps) do
      lines[#lines + 1] = string.format("  %d. %s — %s", i, apps[i].app, human(apps[i].dur))
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "⌨️  Top shortcuts (all-time)"
  if #used == 0 then
    lines[#lines + 1] = "  (none used yet)"
  else
    for i = 1, math.min(5, #used) do
      lines[#lines + 1] = string.format("  %d. %s — %d×", i, used[i].desc, used[i].n)
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = string.format("💤 %d unused bindings", #dead)

  hs.alert.show(table.concat(lines, "\n"), { textSize = 15 }, hs.screen.mainScreen(), 10)
end

-- ---- (b) periodic Markdown reports -----------------------------------------
local function writeReport(path, title, apps, used, dead)
  local out = { "# " .. title, "" , "## Where time went", "" }
  if #apps == 0 then
    out[#out + 1] = "_No focus data recorded._"
  else
    out[#out + 1] = "| App | Time |"
    out[#out + 1] = "| --- | ---- |"
    for _, a in ipairs(apps) do
      out[#out + 1] = string.format("| %s | %s |", a.app, human(a.dur))
    end
  end
  out[#out + 1] = ""
  out[#out + 1] = "## Most-used shortcuts"
  out[#out + 1] = ""
  for i = 1, math.min(15, #used) do
    out[#out + 1] = string.format("%d. `%s` %s — %d×", i, used[i].combo, used[i].desc, used[i].n)
  end
  out[#out + 1] = ""
  out[#out + 1] = string.format("## Unused bindings (%d)", #dead)
  out[#out + 1] = ""
  out[#out + 1] = table.concat(dead, ", ")
  out[#out + 1] = ""

  local f = io.open(path, "w")
  if f then f:write(table.concat(out, "\n")); f:close() end
end

function M.genDaily(day)
  day = day or os.date("%Y-%m-%d")
  local rows = util.readJsonl(util.focusLog)
  local apps = aggByApp(rows, { [day] = true })
  local used, dead = shortcutStats()
  writeReport(util.reportsDir .. "/" .. day .. ".md", "Daily report · " .. day, apps, used, dead)
  local top = apps[1] and (apps[1].app .. " " .. human(apps[1].dur)) or "no data"
  hs.alert.show("Daily report saved · top: " .. top, 4)
end

function M.genWeekly()
  local rows = util.readJsonl(util.focusLog)
  local apps = aggByApp(rows, lastNDays(7))
  local used, dead = shortcutStats()
  local label = os.date("%Y-W%V")
  writeReport(util.reportsDir .. "/week-" .. label .. ".md", "Weekly report · " .. label, apps, used, dead)
end

function M.startPeriodic()
  if M.dailyTimer then M.dailyTimer:stop() end
  M.dailyTimer = hs.timer.doAt("23:55", "1d", function()
    M.genDaily(os.date("%Y-%m-%d"))
    if os.date("*t").wday == 1 then M.genWeekly() end  -- Sunday → weekly rollup
  end)
end

function M.rows()
  return {
    { id = "sys_summary", mods = { "ctrl", "alt", "cmd" }, key = ".",
      desc = "Show usage summary", cat = "System", action = { type = "fn", fn = M.showSummary } },
  }
end

return M
