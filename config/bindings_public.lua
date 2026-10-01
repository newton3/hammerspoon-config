-- Public starter registry. Put machine-, employer-, or account-specific rows
-- in local_config/bindings.lua, which is excluded from Git.
local apps = require("config.apps")
local dev = require("helpers.dev_macros")

local function app(path) return { type = "app", path = path } end
local function pwa(name) return { type = "app", path = apps.pwa(name) } end
local function safari(url) return { type = "safariUrl", url = url } end
local function fn(callback) return { type = "fn", fn = callback } end

return {
  -- App launchers
  { id = "app_keep",     mods = {"alt"}, key = ".", desc = "Google Keep",       cat = "Apps", action = pwa("Google Keep") },
  { id = "app_obsidian", mods = {"alt","cmd"}, key = ".", desc = "Obsidian", cat = "Apps", action = app("/Applications/Obsidian.app") },
  { id = "app_gtasks",   mods = {"alt"}, key = "/", desc = "Google Tasks",      cat = "Apps", action = pwa("Google Tasks") },
  { id = "app_acrobat",  mods = {"alt"}, key = "a", desc = "Adobe Acrobat",     cat = "Apps", action = app("/Applications/Adobe Acrobat DC/Adobe Acrobat.app") },
  { id = "app_chrome",   mods = {"alt","cmd"}, key = "c", desc = "Google Chrome", cat = "Apps", action = app("/Applications/Google Chrome.app") },
  { id = "app_claude",   mods = {"alt","shift"}, key = "c", desc = "Claude", cat = "Apps", action = pwa("Claude") },
  { id = "app_calendar", mods = {"alt"}, key = "c", desc = "Google Calendar",   cat = "Apps", action = pwa("Google Calendar") },
  { id = "app_docs",     mods = {"alt","cmd"}, key = "d", desc = "Google Docs", cat = "Apps", action = pwa("Docs") },
  { id = "app_stocks",   mods = {"alt"}, key = "f", desc = "Stocks",            cat = "Apps", action = app("/System/Applications/Stocks.app") },
  { id = "app_gmail",    mods = {"alt"}, key = "g", desc = "Gmail",             cat = "Apps", action = pwa("Gmail") },
  { id = "app_chatgpt",  mods = {"alt","cmd"}, key = "g", desc = "ChatGPT", cat = "Apps", action = pwa("ChatGPT") },
  { id = "app_logic",    mods = {"alt"}, key = "l", desc = "Logic Pro",         cat = "Apps", action = app("/Applications/Logic Pro.app") },
  { id = "app_notes",    mods = {"alt","cmd"}, key = "n", desc = "Apple Notes", cat = "Apps", action = app("/System/Applications/Notes.app") },
  { id = "app_onenote",  mods = {"alt"}, key = "n", desc = "Microsoft OneNote", cat = "Apps", action = app("/Applications/Microsoft OneNote.app") },
  { id = "app_outlook",  mods = {"alt","shift"}, key = "o", desc = "Outlook", cat = "Apps", action = pwa("Outlook (PWA)") },
  { id = "app_music",    mods = {"alt"}, key = "p", desc = "Music",             cat = "Apps", action = app("/System/Applications/Music.app") },
  { id = "app_windows",  mods = {"alt"}, key = "r", desc = "Windows App",       cat = "Apps", action = app("/Applications/Windows App.app") },
  { id = "app_safari",   mods = {"alt"}, key = "s", desc = "Safari",            cat = "Apps", action = app("/Applications/Safari.app") },
  { id = "app_slack",    mods = {"alt"}, key = "q", desc = "Slack",             cat = "Apps", action = app("/Applications/Slack.app") },
  { id = "app_iterm",    mods = {"alt"}, key = "t", desc = "iTerm 2",           cat = "Apps", action = app("/Applications/iTerm.app") },
  { id = "app_gchat",    mods = {"alt","cmd"}, key = "s", desc = "Google Chat", cat = "Apps", action = pwa("Google Chat") },
  { id = "app_ytmusic",  mods = {"alt","shift"}, key = "y", desc = "YouTube Music", cat = "Apps", action = pwa("YouTube Music") },
  { id = "app_zoom",     mods = {"alt"}, key = "z", desc = "Zoom",              cat = "Apps", action = app("/Applications/zoom.us.app") },

  -- Web
  { id = "web_whatsapp", mods = {"alt"}, key = "b", desc = "WhatsApp", cat = "Web", action = app("/Applications/WhatsApp.app") },
  { id = "web_youtube",  mods = {"alt"}, key = "y", desc = "YouTube",  cat = "Web", action = safari("https://www.youtube.com/") },

  -- Dev and remote access
  { id = "dev_edit_hs", mods = {"alt"}, key = "h", desc = "Edit Hammerspoon config", cat = "Dev", action = fn(dev.exec("open -a 'Visual Studio Code' ~/.hammerspoon")) },
  { id = "dev_reload", mods = {"alt","cmd"}, key = "h", desc = "Reload Hammerspoon", cat = "Dev", action = fn(dev.reload) },
  { id = "dev_remote_ssh", mods = {"alt","cmd","shift"}, key = "s", desc = "Remote Linux: SSH", cat = "Dev", action = fn(dev.remoteSSH) },
  { id = "dev_remote_vnc", mods = {"alt"}, key = "o", desc = "Remote Linux: Screen Sharing", cat = "Dev", action = fn(dev.remoteDesktop) },

  -- Text helpers
  { id = "text_lookup", mods = {"alt","ctrl"}, key = "l", desc = "Dictionary lookup selection", cat = "Text", action = fn(dev.getSelectedText) },
  { id = "text_end", mods = {}, key = "end", desc = "End of line", cat = "Text", action = fn(dev.keyStroke({"cmd"}, "right")) },
  { id = "text_home", mods = {}, key = "home", desc = "Start of line", cat = "Text", action = fn(dev.keyStroke({"cmd"}, "left")) },
  { id = "text_sel_end", mods = {"shift"}, key = "end", desc = "Select to end of line", cat = "Text", action = fn(dev.keyStroke({"cmd","shift"}, "right")) },
  { id = "text_sel_home", mods = {"shift"}, key = "home", desc = "Select to start of line", cat = "Text", action = fn(dev.keyStroke({"cmd","shift"}, "left")) },
}
