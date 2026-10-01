-- helpers/browser.lua — Chrome/Safari tab helpers (moved verbatim from init.lua).
-- Each returns a function suitable for use as a hotkey action.
local M = {}

-- Bring a Chrome tab whose title matches `name` to the front; if none, open `url`.
function M.chrome_active_tab_with_name(name, url)
  url = url or "https://keep.google.com/"  -- Default URL if none provided
  return function()
    local success, result, raw = hs.osascript.javascript([[
      var chrome = Application('Google Chrome');
      chrome.activate();
      var wins = chrome.windows;
      var targetUrl = "]] .. url .. [[";
      function busyWait(milliseconds) {
        var start = new Date().getTime();
        var end = start;
        while (end < start + milliseconds) {
          end = new Date().getTime();
        }
      }
      function main() {
        for (var i = 0; i < wins.length; i++) {
          var win = wins.at(i);
          var tabs = win.tabs;
          for (var j = 0; j < tabs.length; j++) {
            var tab = tabs.at(j);
            tab.title(); j;
            var re = new RegExp("]] .. name .. [[");
            if (re.test(tab.title())) {
              win.activeTabIndex = j+1;
              var tabIndex = j+1;
              win.activeTabIndex.set(tabIndex);
              win.index = 1;
              return "brought to front";
            }
          }
        }
        var win = wins.at(0);
        win.tabs.push(tab = chrome.Tab());
        var tabIndex = win.tabs.length;
        tab.url.set(targetUrl);
        win.activeTabIndex.set(tabIndex);
        win.activeTabIndex = tabIndex;
        win.index = 1;
        return "Here";
      }
      main();
    ]])
  end
end

-- Bring a Chrome tab with an exact `url` to the front; if none, open it.
function M.chrome_active_tab_with_url(url)
  url = url or "https://keep.google.com/"  -- Default URL if none provided
  return function()
    local success, result, raw = hs.osascript.javascript([[
      var chrome = Application('Google Chrome');
      chrome.activate();
      var wins = chrome.windows;
      var targetUrl = "]] .. url .. [[";
      function busyWait(milliseconds) {
        var start = new Date().getTime();
        var end = start;
        while (end < start + milliseconds) {
          end = new Date().getTime();
        }
      }
      function main() {
        for (var i = 0; i < wins.length; i++) {
          var win = wins.at(i);
          var tabs = win.tabs;
          for (var j = 0; j < tabs.length; j++) {
            var tab = tabs.at(j);
            tab.title(); j;
            if (tab.url() === targetUrl) {
              win.activeTabIndex = j+1;
              var tabIndex = j+1;
              win.activeTabIndex.set(tabIndex);
              win.index = 1;
              return "brought to front";
            }
          }
        }
        var win = wins.at(0);
        win.tabs.push(tab = chrome.Tab());
        var tabIndex = win.tabs.length;
        busyWait(50);
        tab.url.set(targetUrl);
        win.activeTabIndex.set(tabIndex);
        win.activeTabIndex = tabIndex;
        win.index = 1;
        return "Here";
      }
      main();
    ]])
  end
end

-- Bring a Safari tab with `url` to the front (URL-normalized); if none, open it.
function M.safari_active_tab_with_url(url)
  return function()
    local escapedUrl = url:gsub("\\", "\\\\"):gsub('"', '\\"')
    hs.osascript.applescript([[
      set targetUrl to "]] .. escapedUrl .. [["
      set normalizedTargetUrl to targetUrl
      if normalizedTargetUrl ends with "/" then set normalizedTargetUrl to text 1 thru -2 of normalizedTargetUrl

      tell application "Safari"
        activate
        if (count of windows) = 0 then
          make new document with properties {URL:targetUrl}
          return
        end if

        repeat with w in windows
          repeat with t in tabs of w
            set tabUrl to URL of t
            set normalizedTabUrl to tabUrl
            if normalizedTabUrl ends with "/" then set normalizedTabUrl to text 1 thru -2 of normalizedTabUrl
            if normalizedTabUrl is normalizedTargetUrl then
              set current tab of w to t
              set index of w to 1
              return
            end if
          end repeat
        end repeat

        tell window 1
          set current tab to (make new tab with properties {URL:targetUrl})
        end tell
      end tell
    ]])
  end
end

return M
