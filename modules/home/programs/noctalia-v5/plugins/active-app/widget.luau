local windows = {}
local focused = nil
local started = false
local lastApp = nil
local names = noctalia.json.decode(noctalia.readFile("~/.local/state/noctalia/apps.json") or "{}") or {}
local function render()
  local win = focused and windows[tostring(focused)] or nil
  if not win then barWidget.setVisible(false); return end
  local app = win.app_id or ""
  if app == "" then barWidget.setVisible(false); return end
  local name = names[app] or names[string.lower(app)] or ({["org.wezfurlong.wezterm"]="WezTerm",["org.gnome.Nautilus"]="Файлы",["org.telegram.desktop"]="Telegram"})[app] or string.match(app, "[^.]+$") or app
  barWidget.setText(name)
  barWidget.setTooltip(win.title or name)
  if app ~= lastApp then
    local icon = noctalia.appIconPath(app, 24)
    if icon then barWidget.setImage(icon, false, 18, 18)
    else barWidget.setGlyph("app-window") end
    lastApp = app
  end
  barWidget.setVisible(true)
end
local function onLine(line)
  local event = noctalia.json.decode(line)
  if not event then return end
  if event.WindowsChanged then
    windows = {}; focused = nil
    for _, win in ipairs(event.WindowsChanged.windows or {}) do
      windows[tostring(win.id)] = win
      if win.is_focused then focused = win.id end
    end
  elseif event.WindowOpenedOrChanged then
    local win = event.WindowOpenedOrChanged.window
    windows[tostring(win.id)] = win
    if win.is_focused then focused = win.id end
  elseif event.WindowFocusChanged then
    focused = event.WindowFocusChanged.id
  elseif event.WindowClosed then
    windows[tostring(event.WindowClosed.id)] = nil
  else return end
  render()
end
function update()
  noctalia.setUpdateInterval(5000)
  if not started then
    started = noctalia.runStream("niri msg --json event-stream", onLine)
  end
end
