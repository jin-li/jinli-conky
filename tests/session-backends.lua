local mode = assert(os.getenv('TEST_SESSION'), 'TEST_SESSION is required')

local kscreenSample = [[
Output: 1 eDP-1
	enabled
	connected
	priority 1
	Geometry: 1920,0 1520x1014
	Scale: 1.8
Output: 2 DP-2
	enabled
	connected
	priority 2
	Geometry: 0,0 1920x1200
	Scale: 1
]]

local niriSample = [[
Output "LG Display" (eDP-1)
  Current mode: 2736x1824 @ 59.959 Hz (preferred)
  Logical size: 1368x912
  Scale: 2
Output "Samsung" (DP-2)
  Current mode: 1920x1200 @ 59.950 Hz (preferred)
  Logical size: 1920x1200
  Scale: 1
]]

local originalPopen = io.popen
io.popen = function(command)
  local output = 'NixOS\n'
  if command:match('kscreen%-doctor') then output = kscreenSample end
  if command:match('niri msg outputs') then output = niriSample end
  return {
    read = function(_, format)
      if format == '*a' then return output end
      return output:match('([^\n]+)')
    end,
    close = function() end,
  }
end

conky = {}
dofile('jinli-config.example.lua')
io.popen = originalPopen

if mode == 'niri' then
  assert(conky.jinli.auto_scaling_screen_height == 912,
    'Niri should use logical height 912')
  assert(conky.config.minimum_width == 241,
    'Niri should use logical-width scaling')
  assert(conky.config.out_to_x == false,
    'Niri should disable X output')
  assert(conky.config.out_to_wayland == true,
    'Niri should enable native Wayland output')
  assert(conky.config.own_window_type == 'override',
    'Niri should use a non-reserving layer surface')
elseif mode == 'kde' then
  assert(conky.jinli.auto_scaling_screen_height == 1825,
    'KDE/XWayland should retain physical height 1825')
  assert(conky.config.minimum_width == 507,
    'KDE/XWayland should retain physical-width scaling')
  assert(conky.config.out_to_x == true,
    'KDE/XWayland should retain X output')
  assert(conky.config.out_to_wayland == nil,
    'KDE/XWayland should not require a Wayland setting')
  assert(conky.config.own_window_type == 'normal',
    'KDE/XWayland should retain the normal window type')
else
  error('unknown TEST_SESSION: ' .. mode)
end

print(mode .. ' session backend detection passed')
