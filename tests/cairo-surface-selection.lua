local file = assert(io.open('jinli.lua', 'r'))
local source = file:read('*a')
file:close()

local xlibBranch = assert(source:find(
  "if conky_window.display ~= nil then",
  1,
  true
), 'X11/Xwayland surface branch is missing')

local nativeWaylandBranch = assert(source:find(
  "elseif type(conky_surface) == 'function' then",
  1,
  true
), 'native Wayland surface fallback is missing')

assert(xlibBranch < nativeWaylandBranch,
  'X11/Xwayland must select its Xlib surface before native Wayland')

print('Cairo surface selection passed')
