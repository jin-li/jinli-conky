local scaling = 1
function scale(n)
  return math.floor(n * scaling)
end
function getOsIcon() -- this is only tested on fedora
  --local distro = os.capture('lsb_release -is'):lower():match('^%s*(.-)%s*$')
  local osName = io.popen('lsb_release -is'):read('*l') or 'linux'
  local distro = osName:lower():match('^%s*(.-)%s*$')
  local icon_map = {
    fedora = '\u{f30a}',
    ubuntu = '\u{f0548}',
    deepin = '\u{f321}',
    archlinux = '\u{f303}',
    manjaro = '\u{f312}',
    debian = '\u{e77d}',
    archcraft = '\u{f345}',
    mint = '\u{f08ed}',
    nixos = '\u{f313}',
    gentoo = '\u{f30d}',
    elementary = '\u{f309}',
    endeavour = '\u{f322}',
    centos = '\u{f304}',
    pop_os = '\u{f32a}',
    suse = '\u{ef6d}',
    kubuntu = '\u{f333}',
    raspberry = '\u{f315}',
  }
  print("Distro detected: " .. distro)
  local icon = icon_map[distro] or '\u{ebc6}' -- default linux icon
  return icon
end

local width, height, dpi = scale(250), scale(1000), 96
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
  icon_font = 'Symbols Nerd Font',
  widgets = {
    clock = {
      hide = false,
      pos = {x = 0, y = 0},
      showDate = true,
      timeFormat = '%H:%M:%S',
      dateFormat = '%A %d %b %Y',
      osIcon = getOsIcon(),
    },
    system = {
      hide = false,
      pos = {x = 0, y = scale(60)},
    },
    cpu = {
      hide = false,
      pos = {x = 0, y = scale(175)},
      gaugeLoc = 'right', -- left, right
      top = 7,
      -- hwmon = 0,
      -- tempSensor = 1,
      -- minCoresPerRow = 2,
    },
    gpu = {
      hide = false,
      pos = {x = 0, y = scale(420)},
      gaugeLoc = 'left', -- left, right
      maxPower = 300, -- max power in watts
      maxMemory = 16303, -- max memory in MB
      -- hwmon = 1,
    },
    memory = {
      hide = false,
      pos = {x = 0, y = scale(595)},
      gaugeLoc = 'right', -- left, right
      top = 3,
    },
    disks = {
      hide = false,
      pos = {x = 0, y = scale(742)},
      gaugeLoc = 'left', -- left, right
      -- disks = {Home = '/home', Root = '/'}
      disks = 'auto',
      exclude = {'/var/lib/docker', 'fast.workspace', '/boot/efi'},
      include = {NAS = '/media/nas/media'}
      -- sort = {NAS, Home, Root}
    },
    network = {
      hide = false,
      pos = {x = 0, y = scale(870)},
      gaugeLoc = 'right', -- left, right
      network = 'auto', -- network name 'eth0'
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
