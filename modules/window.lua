-- modules/window.lua — window tiling on the ⌃⌥⌘ (ctrl+alt+cmd) layer.
-- This modifier space is otherwise free, so it won't clash with the alt+* set.
local M = {}

local HYPER = { "ctrl", "alt", "cmd" }

-- Apply a frame computed from the focused window's screen (usable) frame.
-- Using screen:frame() (not fullFrame) respects the menu bar and Dock.
local function place(compute)
  return function()
    local win = hs.window.focusedWindow()
    if not win then return end
    win:setFrame(compute(win:screen():frame()))
  end
end

local function moveToNextScreen()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:moveToScreen(win:screen():next())
end

-- Registry rows so tiling is counted + shows up in the cheatsheet like any bind.
function M.rows()
  return {
    { id = "win_left",   mods = HYPER, key = "left",  desc = "Window: left half",   cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x,           y = f.y, w = f.w / 2, h = f.h } end) } },
    { id = "win_right",  mods = HYPER, key = "right", desc = "Window: right half",  cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h } end) } },
    { id = "win_max",    mods = HYPER, key = "up",    desc = "Window: maximize",    cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x, y = f.y, w = f.w, h = f.h } end) } },
    { id = "win_center", mods = HYPER, key = "down",  desc = "Window: center",      cat = "Window", action = { type = "fn", fn = place(function(f)
        local w, h = f.w * 0.6, f.h * 0.8
        return { x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h }
      end) } },
    { id = "win_tl", mods = HYPER, key = "u", desc = "Window: top-left quarter",     cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x,           y = f.y,           w = f.w / 2, h = f.h / 2 } end) } },
    { id = "win_tr", mods = HYPER, key = "i", desc = "Window: top-right quarter",    cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x + f.w / 2, y = f.y,           w = f.w / 2, h = f.h / 2 } end) } },
    { id = "win_bl", mods = HYPER, key = "j", desc = "Window: bottom-left quarter",  cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x,           y = f.y + f.h / 2, w = f.w / 2, h = f.h / 2 } end) } },
    { id = "win_br", mods = HYPER, key = "k", desc = "Window: bottom-right quarter", cat = "Window", action = { type = "fn", fn = place(function(f) return { x = f.x + f.w / 2, y = f.y + f.h / 2, w = f.w / 2, h = f.h / 2 } end) } },
    { id = "win_next_display", mods = HYPER, key = "n", desc = "Window: next display", cat = "Window", action = { type = "fn", fn = moveToNextScreen } },
  }
end

return M
