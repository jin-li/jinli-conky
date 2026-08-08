local sample = [[
Output: 1 eDP-1
	enabled
	connected
	priority 1
	Geometry: 0,0 1520x1013
	Scale: 1.8
Output: 2 DP-1
	enabled
	connected
	priority 0
	Geometry: 1520,0 1920x1200
	Scale: 1
]]

local originalPopen = io.popen
io.popen = function(command)
  local output = command:match('kscreen%-doctor') and sample or 'NixOS\n'
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

assert(conky.jinli.auto_scaling_screen_height == 1823,
  'expected priority 1 output height 1823, got ' .. tostring(conky.jinli.auto_scaling_screen_height))
assert(conky.config.minimum_width == 506,
  'expected auto-scaled width 506, got ' .. tostring(conky.config.minimum_width))

print('KScreen priority detection passed')
