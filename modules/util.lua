-- modules/util.lua — shared helpers: paths, JSON/file IO, modifier normalization.
local M = {}

-- Runtime data locations (all local; nothing leaves the machine).
M.usageDir    = hs.configdir .. "/usage"
M.focusLog    = M.usageDir .. "/focus.jsonl"
M.countsFile  = M.usageDir .. "/counts.json"
M.reportsDir  = M.usageDir .. "/reports"

function M.ensureDirs()
  hs.fs.mkdir(M.usageDir)     -- no-op (returns nil,err) if it already exists
  hs.fs.mkdir(M.reportsDir)
end

-- ---- JSON / file IO ---------------------------------------------------------

function M.readJson(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a"); f:close()
  if not content or content == "" then return nil end
  local ok, decoded = pcall(hs.json.decode, content)
  if ok then return decoded end
  return nil
end

-- Atomic write: write to .tmp then rename, so a crash mid-write can't corrupt.
function M.writeJsonAtomic(path, tbl)
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then return false end
  f:write(hs.json.encode(tbl))
  f:close()
  os.rename(tmp, path)
  return true
end

function M.appendLine(path, line)
  local f = io.open(path, "a")
  if not f then return false end
  f:write(line .. "\n")
  f:close()
  return true
end

-- Read a .jsonl file into a list of decoded objects (skips unparseable lines).
function M.readJsonl(path)
  local rows = {}
  local f = io.open(path, "r")
  if not f then return rows end
  for line in f:lines() do
    if line ~= "" then
      local ok, obj = pcall(hs.json.decode, line)
      if ok and obj then rows[#rows + 1] = obj end
    end
  end
  f:close()
  return rows
end

-- ---- Modifiers --------------------------------------------------------------

local MOD_ALIAS = {
  option = "alt", opt = "alt", alt = "alt", ["⌥"] = "alt",
  command = "cmd", cmd = "cmd", ["⌘"] = "cmd",
  control = "ctrl", ctrl = "ctrl", ["⌃"] = "ctrl",
  shift = "shift", ["⇧"] = "shift",
  fn = "fn",
}

-- Canonical string for a set of modifiers: lowercased, aliased, sorted, joined.
-- Makes {cmd,alt} == {alt,cmd} so duplicate bindings are detected reliably.
function M.normalizeMods(mods)
  local out = {}
  for _, m in ipairs(mods or {}) do
    local key = tostring(m):lower()
    out[#out + 1] = MOD_ALIAS[key] or key
  end
  table.sort(out)
  return table.concat(out, "+")
end

-- Canonical combo key "alt+cmd+c" used for conflict detection + counts display.
function M.comboKey(mods, key)
  local nm = M.normalizeMods(mods)
  local k = tostring(key):lower()
  if nm == "" then return k end
  return nm .. "+" .. k
end

-- Pretty combo "⌥⌘C" for the cheatsheet UI.
local MOD_SYMBOL = { alt = "⌥", cmd = "⌘", ctrl = "⌃", shift = "⇧", fn = "fn" }
local KEY_SYMBOL = {
  left = "←", right = "→", up = "↑", down = "↓",
  ["return"] = "⏎", space = "␣", escape = "⎋", delete = "⌫",
}
function M.prettyCombo(mods, key)
  local order = { "ctrl", "alt", "shift", "cmd" }
  local set = {}
  for _, m in ipairs(mods or {}) do
    local n = MOD_ALIAS[tostring(m):lower()] or tostring(m):lower()
    set[n] = true
  end
  local out = ""
  for _, m in ipairs(order) do
    if set[m] then out = out .. (MOD_SYMBOL[m] or m) end
  end
  local k = tostring(key):lower()
  return out .. (KEY_SYMBOL[k] or key:upper())
end

return M
