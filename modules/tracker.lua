-- modules/tracker.lua — app-focus dwell tracker.
-- Records one JSONL row per focus "session" (how long an app stayed frontmost).
-- Time while the screen is locked / display asleep / user idle is NOT counted.
local util = require("modules.util")

local M = {}
M.appWatcher  = nil
M.caffWatcher = nil
M.idleTimer   = nil
M.current     = nil    -- { app, bundle, start }
M.idlePaused  = false  -- set when idle > threshold
M.lockPaused  = false  -- set when screen locked / asleep

local IDLE_THRESHOLD = 300  -- seconds of HID inactivity before we stop counting
local MIN_SESSION    = 1    -- ignore sub-second focus flickers

local function isPaused()
  return M.idlePaused or M.lockPaused
end

-- Close the open session, writing a row. `endTime` lets callers back-date the
-- end (e.g. to now-idleTime) so idle/locked seconds aren't counted.
local function closeSession(endTime)
  if not M.current then return end
  local s = M.current
  local e = endTime or os.time()
  if e < s.start then e = s.start end
  local dur = e - s.start
  if dur >= MIN_SESSION then
    util.appendLine(util.focusLog, hs.json.encode({
      app    = s.app,
      bundle = s.bundle,
      start  = s.start,
      ["end"] = e,
      dur    = dur,
      day    = os.date("%Y-%m-%d", s.start),
    }))
  end
  M.current = nil
end

local function openSession(appObj)
  if isPaused() then return end
  local app = appObj or hs.application.frontmostApplication()
  if not app then return end
  M.current = {
    app    = app:name() or "?",
    bundle = app:bundleID() or "?",
    start  = os.time(),
  }
end

local function resumeIfActive()
  if not isPaused() and not M.current then
    openSession(hs.application.frontmostApplication())
  end
end

local function onApp(_name, eventType, appObj)
  if eventType == hs.application.watcher.activated then
    -- An app activation is user input, so any idle pause is over.
    M.idlePaused = false
    closeSession(os.time())
    if not isPaused() then openSession(appObj) end
  end
end

local function onCaffeine(event)
  local w = hs.caffeinate.watcher
  if event == w.screensDidLock or event == w.screensDidSleep
     or event == w.systemWillSleep then
    closeSession(os.time())
    M.lockPaused = true
  elseif event == w.screensDidUnlock or event == w.screensDidWake
     or event == w.systemDidWake then
    M.lockPaused = false
    resumeIfActive()
  end
end

local function checkIdle()
  local idle = hs.host.idleTime()
  if idle >= IDLE_THRESHOLD then
    if not M.idlePaused then
      closeSession(os.time() - idle)  -- don't count the idle stretch
      M.idlePaused = true
    end
  elseif M.idlePaused then
    M.idlePaused = false
    resumeIfActive()
  end
end

function M.start()
  util.ensureDirs()
  M.stop()  -- reload safety: tear down any prior watchers/timers
  M.appWatcher  = hs.application.watcher.new(onApp); M.appWatcher:start()
  M.caffWatcher = hs.caffeinate.watcher.new(onCaffeine); M.caffWatcher:start()
  M.idleTimer   = hs.timer.doEvery(60, checkIdle)
  openSession(hs.application.frontmostApplication())
end

function M.stop()
  if M.appWatcher then M.appWatcher:stop(); M.appWatcher = nil end
  if M.caffWatcher then M.caffWatcher:stop(); M.caffWatcher = nil end
  if M.idleTimer then M.idleTimer:stop(); M.idleTimer = nil end
end

-- Flush the open session (called from hs.shutdownCallback).
function M.flush()
  closeSession(os.time())
end

return M
