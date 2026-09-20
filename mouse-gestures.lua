-- Opera-style mouse gestures at the compositor.
-- Hold right mouse, flick, release. Left/right send Alt+Arrow (back/forward).
-- Up sends Alt+Up (parent folder). Down sends Ctrl+T (new tab).
-- Down-then-right (or a ↘ diagonal) sends Ctrl+W (close tab).
-- Down-then-up sends F5 (refresh). Super+RMB still resizes windows.
-- Games/fullscreen skip so RMB is not stolen. A click with almost no movement
-- is replayed as RMB.

local THRESHOLD = 64
local SEGMENT = 40
local origin = nil
local injecting = false
local samples = {}
local sampler = nil

local function send_keys(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end

local function skip_gestures()
  local window = hl.get_active_window()
  if not window then
    return true
  end
  if (window.fullscreen or 0) ~= 0 then
    return true
  end
  local class = window.class or ""
  if class:match("^steam_app_") or class:match("gamescope") then
    return true
  end
  return false
end

local function copy_pos(pos)
  if not pos then
    return nil
  end
  return { x = pos.x, y = pos.y }
end

local function stop_sampler()
  if sampler then
    sampler:set_enabled(false)
  end
end

local function start_sampler()
  samples = {}
  local pos = copy_pos(hl.get_cursor_pos())
  if pos then
    samples[1] = pos
  end
  if sampler then
    sampler:set_enabled(true)
    return
  end
  sampler = hl.timer(function()
    local p = copy_pos(hl.get_cursor_pos())
    if p then
      samples[#samples + 1] = p
    end
  end, { timeout = 16, type = "repeat" })
end

local function path_dirs(points)
  local dirs = {}
  if not points or #points < 2 then
    return dirs
  end
  local accx, accy = 0, 0
  for i = 2, #points do
    local a, b = points[i - 1], points[i]
    accx = accx + (b.x - a.x)
    accy = accy + (b.y - a.y)
    if math.abs(accx) >= SEGMENT or math.abs(accy) >= SEGMENT then
      local dir
      if math.abs(accx) >= math.abs(accy) then
        dir = accx < 0 and "left" or "right"
      else
        dir = accy < 0 and "up" or "down"
      end
      if dirs[#dirs] ~= dir then
        dirs[#dirs + 1] = dir
      end
      accx, accy = 0, 0
    end
  end
  return dirs
end

local function path_starts(dirs, first, second)
  return dirs[1] == first and dirs[2] == second
end

local function replay_right_click()
  injecting = true
  hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "mouse:273" }))
  hl.timer(function()
    injecting = false
  end, { timeout = 80, type = "oneshot" })
end

o.bind("mouse:273", "Mouse gesture start", function()
  if injecting then
    return { ok = false }
  end
  if skip_gestures() then
    origin = nil
    samples = {}
    stop_sampler()
    return { ok = false }
  end
  origin = copy_pos(hl.get_cursor_pos())
  start_sampler()
end, { auto_consuming = true })

o.bind("mouse:273", "Mouse gesture", function()
  if injecting then
    return { ok = false }
  end

  stop_sampler()
  local start = origin
  local points = samples
  origin = nil
  samples = {}
  if not start then
    return { ok = false }
  end

  local pos = copy_pos(hl.get_cursor_pos())
  if pos then
    points[#points + 1] = pos
  else
    pos = points[#points]
  end
  if not pos then
    replay_right_click()
    return
  end

  local dx = pos.x - start.x
  local dy = pos.y - start.y
  local dirs = path_dirs(points)

  -- Two-segment strokes first: down-up returns near the start, so it would
  -- otherwise look like a click.
  if path_starts(dirs, "down", "right") or (dx >= THRESHOLD and dy >= THRESHOLD) then
    send_keys("CTRL", "W")
    return
  end
  if path_starts(dirs, "down", "up") then
    send_keys("", "F5")
    return
  end

  if math.abs(dx) < THRESHOLD and math.abs(dy) < THRESHOLD then
    replay_right_click()
    return
  end

  if math.abs(dx) >= math.abs(dy) then
    send_keys("ALT", dx < 0 and "left" or "right")
  elseif dy < 0 then
    send_keys("ALT", "up")
  else
    send_keys("CTRL", "T")
  end
end, { release = true, auto_consuming = true })
