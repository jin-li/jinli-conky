-- Set to a number for a fixed scale, or use 'auto' to fit the primary
-- display's detected screen height.
local scaling = 'auto'
-- In auto mode, use 'primary' or a KDE output name reported by
-- `kscreen-doctor -o` (for example, 'eDP-1').
local autoScalingOutput = 'primary'
local configScaling = type(scaling) == 'number' and scaling or 1
function scale(n)
  return math.floor(n * configScaling)
end

-- Conky evaluates this file before loading jinli.lua, so this must remain in
-- the configuration phase rather than in the drawing script.
function getOsIcon()
  local handle = io.popen('lsb_release -is 2>/dev/null')
  local osName = handle and handle:read('*l') or 'linux'
  if handle then handle:close() end

  local distro = (osName or 'linux'):lower():match('^%s*(.-)%s*$')
  distro = distro:gsub('^"(.-)"$', '%1'):gsub("^'(.-)'$", '%1')
  local icon_map = {
    fedora = '\u{f30a}', ubuntu = '\u{f0548}', deepin = '\u{f321}',
    archlinux = '\u{f303}', manjaro = '\u{f312}', debian = '\u{e77d}',
    archcraft = '\u{f345}', mint = '\u{f08ed}', nixos = '\u{f313}',
    gentoo = '\u{f30d}', elementary = '\u{f309}', endeavour = '\u{f322}',
    centos = '\u{f304}', pop_os = '\u{f32a}', suse = '\u{ef6d}',
    kubuntu = '\u{f333}', raspberry = '\u{f315}',
  }
  print('Distro detected: ' .. distro)
  return icon_map[distro] or '\u{ebc6}'
end

local function runCommand(command)
  local pipe = io.popen(command)
  if not pipe then return nil end
  local output = pipe:read('*a')
  pipe:close()
  return output
end

local function detectKscreenHeight()
  -- On KDE Wayland, Xwayland tools describe the combined virtual desktop.
  -- KScreen provides each output's logical geometry and fractional scale;
  -- multiplying them gives the physical output height used by Conky.
  local output = runCommand('kscreen-doctor -o 2>/dev/null')
  if not output then return nil end

  local selected, outputName, geometryHeight, scale
  for line in (output .. '\n'):gmatch('(.-)\n') do
    if line:match('^Output:') then
      if selected and geometryHeight and scale then
        return math.floor(geometryHeight * scale + 0.5), outputName
      end
      outputName = line:match('^Output:%s+%d+%s+(%S+)')
      selected = autoScalingOutput == 'primary'
        and line:match('%f[%a]primary%f[^%a]') ~= nil
        or outputName == autoScalingOutput
      geometryHeight, scale = nil, nil
    elseif selected then
      local height = line:match('^%s*Geometry:%s*%-?%d+,%-?%d+%s+%d+x(%d+)')
      if height then geometryHeight = tonumber(height) end
      local outputScale = line:match('^%s*Scale:%s*([%d%.]+)')
      if outputScale then scale = tonumber(outputScale) end
    end
  end

  if selected and geometryHeight and scale then
    return math.floor(geometryHeight * scale + 0.5), outputName
  end
  return nil
end

local function detectScreenHeight()
  local kscreenHeight = detectKscreenHeight()
  if kscreenHeight and kscreenHeight > 0 then return kscreenHeight end

  local xrandrHeight = runCommand("xrandr --current 2>/dev/null | sed -n 's/.* connected primary .* \\([0-9][0-9]*\\)x\\([0-9][0-9]*\\).*/\\2/p' | head -n 1")
  local detected = xrandrHeight and tonumber(xrandrHeight:match('(%d+)')) or nil
  if detected and detected > 0 then return detected end

  local xdpHeight = runCommand("xdpyinfo 2>/dev/null | sed -n 's/ dimensions: *[0-9][0-9]*x\\([0-9][0-9]*\\) pixels.*/\\1/p' | head -n 1")
  detected = xdpHeight and tonumber(xdpHeight:match('(%d+)')) or nil
  return detected and detected > 0 and detected or nil
end

local autoScalingScreenHeight = detectScreenHeight()
local baseLayoutHeight = 860
local windowScaling = configScaling
if scaling == 'auto' and autoScalingScreenHeight then
  -- Keep widget heights unscaled here. jinli.lua applies this factor while it
  -- draws, so pre-scaling them would make the layout gaps grow twice as fast.
  windowScaling = math.max((autoScalingScreenHeight - 80) / baseLayoutHeight, 0.1)
end

local width = math.floor(250 * windowScaling)
local height = scaling == 'auto' and (autoScalingScreenHeight or 1000) or scale(1000)
print(string.format('Conky auto-scaling config: screenHeight=%s windowScaling=%.3f', tostring(autoScalingScreenHeight), windowScaling))
local dpi = 96
local default, primary, warn, crit = 0xffffff, 0x00bfa5, 0xfbc02d, 0xdd2c00

conky.config = {
  -- Conky settings #
  background = false,
  update_interval = 0.5,

  cpu_avg_samples = 2,
  net_avg_samples = 2,

  override_utf8_locale = true,

  double_buffer = true,
  no_buffers = true,

  text_buffer_size = 2048,
  --imlib_cache_size 0

  temperature_unit = 'celsius',

  -- Window specifications
  own_window_argb_visual = true,
  own_window_argb_value = 0,
  own_window_class = 'Conky',
  own_window = true,
  own_window_type = 'normal', -- for kde use dock and add window rules
  own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
  -- own_window_transparent = false, -- I don't know if this helps

  border_inner_margin = 0,
  border_outer_margin = 0,

  minimum_width = math.ceil(width / dpi * 96),
  minimum_height = math.ceil(height / dpi * 96),

  alignment = 'top_right',
  gap_x = 10,
  gap_y = 10,

  lua_load = 'jinli.lua',
  lua_draw_hook_pre = 'conky_main',
}

conky.text = [[]]

conky.jinli = {
  scaling = scaling,
  auto_scaling_screen_height = autoScalingScreenHeight,
  auto_scaling_bottom_margin = 80,
  icon_font = 'Symbols Nerd Font',
  pos = {x = 0, y = 0},
  show_widgets = {'clock', 'system', 'cpu', 'gpu', 'memory', 'network', 'disks'},
  widgets = {
    clock = {
      hide = false,
      height = scale(60),
      showDate = true,
      timeFormat = '%H:%M:%S',
      dateFormat = '%A %d %b %Y',
      osIcon = getOsIcon(),
    },
    system = {
      hide = false,
      height = scale(115),
    },
    cpu = {
      hide = false,
      height = scale(235),
      gaugeLoc = 'right', -- left, right
      top = 7,
      -- hwmon = 0,
      -- tempSensor = 1,
      -- minCoresPerRow = 2,
    },
    gpu = {
      hide = 'auto', -- true, false, auto (hide when no supported GPU is detected)
      height = scale(175),
      gaugeLoc = 'left', -- left, right
      gpuBackend = 'auto', -- auto, nvidia, amd
      amdCard = 'auto', -- auto, card0, card1 ...
      maxPower = 300, -- max power in watts
      maxMemory = 16303, -- max memory in MB
      -- hwmon = 1,
    },
    memory = {
      hide = false,
      height = scale(155),
      gaugeLoc = 'right', -- left, right
      top = 3,
    },
    network = {
      hide = false,
      height = scale(125),
      gaugeLoc = 'left', -- left, right
      network = 'auto', -- network name 'eth0'
      showIpv6 = true,
    },
    disks = {
      hide = false,
      height = scale(170),
      gaugeLoc = 'right', -- left, right
      -- disks = {Home = '/home', Root = '/'}
      disks = 'auto',
      exclude = {'/var/lib/docker', 'fast.workspace', '/boot/efi'},
      include = {NAS = '/media/nas/media'}
      -- sort = {NAS, Home, Root}
    },
  },
  fonts = {
    default = 'Monaco', -- suggestion: use a mono spaced font
    significant = 'GE Inspira',
  },
  colors = {
    default = default,
    highlight = primary,
    gaugeBg = default,
    gaugeBgAlpha = 0.1,
    gauge = default,
    gaugeAlpha = 0.8,
    gaugeInfo = primary,
    gaugeWarn = warn,
    gaugeCrit = crit,
  }
}
