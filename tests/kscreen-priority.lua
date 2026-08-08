local sample = [[
<ESC>[01;32mOutput: <ESC>[0;0m1 eDP-1
	<ESC>[01;32menabled<ESC>[0;0m
	<ESC>[01;32mconnected<ESC>[0;0m
	<ESC>[01;32mpriority 1<ESC>[0;0m
<ESC>[01;33m	Geometry: <ESC>[0;0m1920,0 1520x1014
<ESC>[01;33m	Scale: <ESC>[0;0m1.8
<ESC>[01;32mOutput: <ESC>[0;0m2 DP-2
	<ESC>[01;32menabled<ESC>[0;0m
	<ESC>[01;32mconnected<ESC>[0;0m
	<ESC>[01;32mpriority 2<ESC>[0;0m
<ESC>[01;33m	Geometry: <ESC>[0;0m0,0 1920x1200
<ESC>[01;33m	Scale: <ESC>[0;0m1
]]
sample = sample:gsub('<ESC>', string.char(27))

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

assert(conky.jinli.auto_scaling_screen_height == 1825,
  'expected priority 1 output height 1825, got ' .. tostring(conky.jinli.auto_scaling_screen_height))
assert(conky.config.minimum_width == 507,
  'expected auto-scaled width 507, got ' .. tostring(conky.config.minimum_width))

print('KScreen priority detection passed')
