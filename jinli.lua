package.cpath = package.cpath .. ";/usr/lib/conky/lib?.so"
require 'lib'
require 'cairo-tools'
require 'imlib2'
-- cairo works on Ubuntu, cairo_xlib works on Fedora
local ok, cairo = pcall(require, "cairo_xlib")
if not ok then
    cairo = require("cairo")
end

-- make the cairo functions globally available if needed
_G.cairo = cairo

conky = {}
require 'jinli-config'
local settings, cache = conky.jinli, {}
local cr, width, height, updates
local isIconFontAvailable = font_exists(settings.icon_font or 'Symbols Nerd Font')

function conky_main()
  if conky_window==nil or conky_window.width == 0 then return end
  local cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height
  )

  cr = cairo_create(cs)
  width = conky_window.width
  height = conky_window.height

  updates=tonumber(conky_parse('${updates}'))

  local start = mtime()
  for widget,config in pairs(settings.widgets) do
    updateWidget(widget, config)
  end
  -- print(os.date('%c') .. ' updated in ' .. string.format('%.2f seconds', mtime() - start))
end

function updateWidget(widget, config)
  if config.hide ~= nil and config.hide == true then
      return
  end
  local start = mtime()
  if widget == 'clock'   then updateClock(config)   end
  if widget == 'system'  then updateSystem(config)  end
  if widget == 'cpu'     then updateCpu(config)     end
  if widget == 'gpu'     then updateGpu(config)     end
  if widget == 'memory'  then updateMemory(config)  end
  if widget == 'disks'   then updateDisks(config)   end
  if widget == 'network' then updateNetwork(config) end
  --print(os.date('%c') .. ' updated ' .. widget .. ' in ' .. string.format('%.2f seconds', mtime() - start))
end

function scale(n)
  return math.floor(n * (settings.scaling or 1));
end

function updateClock(config)
  local pos = config.pos or {x = 0, y = 0}
  -- time
  write(cr, os.date(config.timeFormat or '%H:%M'), {
    pos = {x = pos.x, y = pos.y - scale(10)},
    font = {settings.fonts.significant, scale(40)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  -- date
  if config.showDate == nil or config.showDate then
    write(cr, os.date(config.dateFormat or '%A, %b %e'), {
      pos = {x = pos.x, y = pos.y + scale(35)},
      font = {settings.fonts.significant, scale(16), 1},
      color = settings.colors.highlight,
      align = {'left', 'top'},
    })
  end
  -- icon for distro
  write(cr, config.osIcon, {
    pos = {x = width - scale(50), y = pos.y},
    font = {'Symbols Nerd Font', scale(50)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end

function updateSystem(config)
  local pos = config.pos or {x = 0, y = scale(70)}
  local leftTextX = pos.x
  local rightTextX = width
  local y = pos.y + scale(2)

  -- os
  local os = conky_parse('${exec lsb_release -irs}')
  write(cr, 'OS', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, os, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- hostname
  local hostname = conky_parse('${nodename}')
  write(cr, 'Hostname', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, hostname, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- kernel
  local kernel = conky_parse('${kernel}')
  write(cr, 'Kernel', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, kernel, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- uptime
  local uptime = conky_parse('${uptime}')
  write(cr, 'Uptime', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, uptime, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- cpu
  local cpu = conky_parse('${execi 10000 cat /proc/cpuinfo | grep \'model name\' | sed -e \'s/model name.*: //\'| uniq}')
  write(cr, 'CPU', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, cpu, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- gpu
  local gpu = conky_parse('${execi 10000 lspci | grep \' VGA \' | cut -d "[" -f2 | cut -d "]" -f1}')
  write(cr, 'GPU', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- processes
  local processes = conky_parse('${processes}')
  local running_processes = conky_parse('${running_processes}')
  write(cr, 'Processes', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, running_processes .. ' / ' .. processes, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- threads
  local threads = conky_parse('${threads}')
  local running_threads = conky_parse('${running_threads}')
  write(cr, 'Threads', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, running_threads .. ' / ' .. threads, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- load average
  local load1 = conky_parse('${loadavg 1}')
  local load5 = conky_parse('${loadavg 2}')
  local load15 = conky_parse('${loadavg 3}')
  write(cr, 'Load Average', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, load1 .. ' | ' .. load5 .. ' | ' .. load15, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- fan speed
  --local fan_speed = conky_parse('${hwmon 0 fan 1}')
  --write(cr, 'Fan Speed', {
  --  pos = {x = x, y = y},
  --  font = {settings.fonts.default, scale(10)},
  --  color = settings.colors.default,
  --  align = {'left'},
  --})
  --write(cr, fan_speed .. ' RPM', {
  --  pos = {x = x + scale(200), y = y},
  --  font = {settings.fonts.default, scale(10)},
  --  color = settings.colors.default,
  --  align = {'right'},
  --})
  --y = y + scale(12)
end

function updateCpu(config)
  local pos = config.pos or {x = 0, y = 0}
  local freq = conky_parse('${freq_g cpu0}')
  local hwmon = config.hwmon or getCoreHwmon()
  local tempSensor = config.tempSensor or 1
  local temperature = conky_parse('${hwmon ' .. hwmon .. ' temp '  .. tempSensor .. '}')
  local avgCpu = conky_parse('${cpu cpu0}')
  local cpuCount = getCpuCount()
  local warnTemp, critTemp, maxTemp = 60, 80, 110
  if (cache.cpu == nil or cache.cpu.idleTemperatureCount < 1000) and (tonumber(freq) < 1 or tonumber(avgCpu) < 10) then
    if cache.cpu == nil then cache.cpu = {} end
    cache.cpu.idleTemperatureSum = (cache.cpu.idleTemperatureSum or 0) + tonumber(temperature)
    cache.cpu.idleTemperatureCount = (cache.cpu.idleTemperatureCount or 0) + 1
  end
  if cache.cpu ~= nil and cache.cpu.idleTemperatureSum ~= nil and cache.cpu.idleTemperatureCount ~= nil then
    warnTemp = cache.cpu.idleTemperatureSum / cache.cpu.idleTemperatureCount * 1.5
    critTemp = warnTemp * 1.3
  end

  local y = pos.y + scale(5) -- start of text
  local gauge_center = {x = scale(110), y = pos.y + scale(120)}
  local leftTextX = gauge_center.x + scale(7)
  local rightTextX = width
  if config.gaugeLoc == 'right' then
    gauge_center.x = width - scale(110)
    leftTextX = pos.x
    rightTextX = gauge_center.x - scale(7)
  end

  local gauge_from = 180
  local gauge_to = 360
  if config.gaugeLoc == 'right' then
    gauge_from = 0
    gauge_to = 180
  end

  -- temperature
  write(cr, 'CPU Temperature', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, temperature .. '°C', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  gauge(cr, tonumber(temperature), {
    pos = gauge_center,
    radius = scale(108), thickness = scale(3),
    from = gauge_from, to = gauge_to,
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    max = maxTemp,
    warn = {from = warnTemp, color = settings.colors.gaugeWarn},
    crit = {from = critTemp, color = settings.colors.gaugeCrit},
  })

  -- average cpu
  y = y+scale(12)
  write(cr, 'Average CPU usage ', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, avgCpu:pad(3, ' ', 'STR_PAD_LEFT') .. '%', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  gauge(cr, tonumber(avgCpu), {
    pos = gauge_center,
    radius = scale(98), thickness = scale(11),
    from = gauge_from + scale(2), to = gauge_to - scale(2),
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    warn = {from = 100/cpuCount, color = settings.colors.gaugeInfo},
    crit = {from = 90, color = settings.colors.gaugeWarn},
  })

  -- cpu cores
  y = y+scale(13)
  if cpuCount > 1 then
    local r = scale(89)
    local perRow = math.ceil(cpuCount/4)
    local minCoresPerRow = config.minCoresPerRow or 2
    if perRow < minCoresPerRow then
        perRow = minCoresPerRow
    end
    local s = ''
    for i=1,cpuCount,1 do
      s = s .. '${cpu cpu' .. i .. '},'
    end
    local cpuUsage = conky_parse(s):split(',')
    for i=1,cpuCount,perRow do
      local usages = {}
      local sum = 0
      local j
      for j=i,i+perRow-1,1 do
        if j > cpuCount then
          break
        end
        table.insert(usages, tonumber(cpuUsage[j]))
        sum = sum + cpuUsage[j]
      end

      local avg = round(sum/perRow,1)

      local leftText, rightText
      if perRow == 1 then
        leftText = 'Core ' .. i
        rightText = avg .. '%'
      else
        leftText = 'Cores ' .. (i .. '-' .. i+perRow-1):pad(5, ' ', 'STR_PAD_LEFT')
        rightText = avg .. '%'
      end

      -- cpu cores text
      write(
        cr,
        leftText,
        {
          pos = {x = leftTextX, y = y},
          font = {settings.fonts.default, scale(10)},
          color = settings.colors.default,
          align = {'left', 'top'},
        }
      )
      write(
        cr,
        rightText,
        {
          pos = {x = rightTextX, y = y},
          font = {settings.fonts.default, scale(10)},
          color = settings.colors.default,
          align = {'right', 'top'},
        }
      )

      -- cpu cores gauges
      local thickness = math.floor(scale(12) / perRow)                   -- 4 = 3 / 6 = 2 / 8 = 1   / 12 = 1 / 16 = 0
      local rDec = thickness + (scale(12) - thickness * perRow) / perRow -- 4 = 3 / 6 = 2 / 8 = 1.5 / 12 = 0 / 16 = 0.75
      if thickness == 0 then
        thickness = 1
      elseif thickness > 2 then
        rDec = thickness
        thickness = math.ceil(thickness / 2 )
      end
      local usage
      for j,usage in ipairs(usages) do
        gauge(cr, usage, {
          pos = gauge_center,
          radius = r - rDec * (j-1), thickness = thickness,
          from = gauge_from, to = gauge_to,
          background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
          color = settings.colors.gauge,
          alpha = settings.colors.gaugeAlpha,
          warn = {from = 50, color = settings.colors.gaugeInfo},
        })
      end

      y = y + scale(12)
      r = r - scale(12)
    end
  end

  -- average cpu graph
  y = y + scale(55)
  local graph_x = gauge_center.x + scale(30)
  local graph_width = width - graph_x
  local graph_direction = 'right'
  if config.gaugeLoc == 'right' then
    graph_x = gauge_center.x - scale(30)
    graph_width = graph_x
    graph_direction = 'left'
  end
  graph(cr, 'cpu', tonumber(avgCpu), {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'up',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(40),
  })
  y = y + scale(1)
  local text_align = 'left'
  if config.gaugeLoc == 'right' then
    text_align = 'right'
  end
  write(cr, freq .. ' GHz', {
    pos = {x = graph_x, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {text_align, 'top'},
  })

  -- top
  y = y + scale(12)
  if config.top and config.top > 0 then
    if cache.top == nil or updates % 4 == 0 then
      -- local topCpu = os.capture('LC_ALL=C ps -eo comm,%cpu --sort=-%cpu --no-headers|head -4'):split('\n')
      local topCpu = os.capture(
        'LC_ALL=C top -w 512 -bn 1 -d 1 -o %CPU|grep -A40 "PID USER"|tail -40|' ..
        'tr -s " "|cut -d " " -f10,13-'
      ):split('\n')
      topCpu = table.map(topCpu, function (row)
        local cpu, cmd = row:match('^([%d.]+) +(.-)$')
        if cmd == nil then return {cmd = '', cpu = 0} end
        return {
          cmd = string.sub(cmd, 1, 20),
          cpu = cpu,
        }
      end)
      topCpu = table.group(
        topCpu,
        function (row) return row.cmd end,
        {
          sum = function (sum, row)
            if sum == nil then
              return tonumber(row.cpu)
            end
            return sum + tonumber(row.cpu)
          end,
        }
      )

      topCpu = table.values(table.filter(topCpu, function (row)
        return row.sum
      end))
      table.sort(topCpu, function (row1, row2)
        return row1.sum > row2.sum
      end)

      cache.top = {}
      table.move(topCpu, 1, config.top, 1, cache.top)
    end

    local firstRow = y;
    for _, data in pairs(cache.top) do
      -- Process name, left aligned
      write(cr, data.key:pad(20), {
        pos = { x = leftTextX, y = y },
        font = {settings.fonts.default, scale(10)},
        color = settings.colors.default,
        align = {'left', 'top'},
      })
      -- CPU percentage, right aligned
      write(cr, tostring(round(data.sum/cpuCount, 1)):pad(7, ' ', 'STR_PAD_LEFT') .. '%', {
        pos = { x = rightTextX, y = y }, -- adjust 140 to your desired right margin
        font = {settings.fonts.default, scale(10)},
        color = settings.colors.default,
        align = {'right', 'top'},
      })
      y = y + scale(12)
    end
    y = firstRow + scale(12) * config.top
  end

  -- icon for CPU
  -- if font is not found, fall back to text 'CPU'
  local text = '\u{f4bc}' -- nf-fa-microchip
  local font = {settings.icon_font, scale(40)}
  local icon_x = gauge_center.x - scale(20)
  local icon_y = gauge_center.y - scale(20)
  if config.gaugeLoc == 'right' then
    icon_x = gauge_center.x + scale(20)
  end
  if not isIconFontAvailable then
    text = 'CPU'
    font = {settings.fonts.significant, scale(20), 1}
    icon_y = gauge_center.y - scale(17)
  end
  write(cr, text, {
    pos = {x = gauge_center.x - scale(20), y = icon_y},
    font = font,
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end

function updateGpu(config)
  local pos = config.pos or {x = 0, y = scale(250)}
  -- Get GPU stats using nvidia-smi
  local gpu_query = 'nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,power.draw,memory.used,fan.speed,memory.total,clocks.current.graphics --format=csv,noheader,nounits'
  local output = os.capture(gpu_query):gsub('\r', ''):gsub('\n', '')
  local gpu_load, gpu_temp, gpu_power, gpu_mem_used, gpu_fan_speed, gpu_mem_total, gpu_clock = output:match('(%d+), (%d+), ([%d.]+), ([%d.]+), ([%d.]+), ([%d.]+), ([%d.]+)')
  gpu_load = tonumber(gpu_load) or 0
  gpu_temp = tonumber(gpu_temp) or 0
  gpu_power = tonumber(gpu_power) or 0
  gpu_mem_used = tonumber(gpu_mem_used) or 0
  gpu_fan_speed = tonumber(gpu_fan_speed) or 0
  gpu_mem_total = tonumber(gpu_mem_total) or 0
  gpu_clock = tonumber(gpu_clock) or 0
  gpu_mem_used_gb = round(gpu_mem_used / 1024, 1)
  gpu_mem_total_gb = round(gpu_mem_total / 1024, 1)

  local gauge_from = 180
  local gauge_to = 400
  local gauge_center = {x = pos.x+scale(83), y = pos.y+scale(83)}
  if config.gaugeLoc == 'right' then
    gauge_center.x = pos.x + width - scale(83)
    gauge_from = -40
    gauge_to = 180
  end
  -- GPU Temperature Gauge
  gauge(cr, gpu_temp, {
    pos = gauge_center,
    radius = scale(80), thickness = scale(5),
    from = gauge_from, to = gauge_to,
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    warn = {from = 70, color = settings.colors.gaugeWarn},
    crit = {from = 85, color = settings.colors.gaugeCrit},
    max = 100,
  })
  -- GPU Load Gauge
  gauge(cr, gpu_load, {
    pos = gauge_center,
    radius = scale(65), thickness = scale(16),
    from = gauge_from + scale(4), to = gauge_to - 4,
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    warn = {from = 80, color = settings.colors.gaugeWarn},
    crit = {from = 95, color = settings.colors.gaugeCrit},
  })
  -- GPU Power Gauge
  gauge(cr, gpu_power, {
    pos = gauge_center,
    radius = scale(50), thickness = scale(8),
    from = gauge_from, to = gauge_to,
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    warn = {from = 250, color = settings.colors.gaugeWarn},
    crit = {from = 280, color = settings.colors.gaugeCrit},
    max = config.maxPower or 300,
  })
  -- GPU Fan Speed Gauge
  gauge(cr, gpu_fan_speed, {
    pos = gauge_center,
    radius = scale(40), thickness = scale(8),
    from = gauge_from, to = gauge_to,
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    warn = {from = 70, color = settings.colors.gaugeWarn},
    crit = {from = 85, color = settings.colors.gaugeCrit},
    max = 100,
  })

  local y = pos.y + scale(15) -- start of text
  local leftTextX = pos.x + scale(145)
  local rightTextX = width
  if config.gaugeLoc == 'right' then
    leftTextX = pos.x
    rightTextX = pos.x + width - scale(145)
  end
  write(cr, 'Temperature', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu_temp .. '°C', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  if config.gaugeLoc == 'right' then
    rightTextX = rightTextX + scale(10)
  else
    leftTextX = leftTextX - scale(10)
  end
  y = y + scale(12)
  write(cr, 'Average Load', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu_load .. '%', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  if config.gaugeLoc == 'right' then
    rightTextX = rightTextX + scale(10)
  else
    leftTextX = leftTextX - scale(10)
  end
  y = y + scale(12)
  write(cr, 'Power', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu_power .. 'W', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  if config.gaugeLoc == 'right' then
    rightTextX = rightTextX + scale(10)
  else
    leftTextX = leftTextX - scale(10)
  end
  y = y + scale(12)
  write(cr, 'Fan Speed', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu_fan_speed .. '%', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })

  -- Graph for GPU load history (similar to CPU)
  y = y + scale(35)
  local graph_direction = 'right'
  local graph_x = leftTextX
  local graph_width = width - graph_x
  if config.gaugeLoc == 'right' then
    graph_direction = 'left'
    graph_x = rightTextX
    graph_width = graph_x
  end
  graph(cr, 'gpu', gpu_load, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'up',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(20),
  })
  -- Graph for GPU memory usage history (similar to CPU)
  y = y + scale(2)
  graph(cr, 'gpu_mem', gpu_mem_used, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'down',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(20),
    max = config.maxMemory or 16000, -- in MB
  })
  y = y + scale(27)
  rightTextX = width
  if config.gaugeLoc == 'right' then
    rightTextX = gauge_center.x - scale(10)
  end
  write(cr, gpu_clock .. ' MHz', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, gpu_mem_used_gb .. '/' .. gpu_mem_total_gb .. ' GB ', {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })

  -- Top 3 GPU processes by memory usage
  local gpu_top_query = 'nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv,noheader,nounits'
  local gpu_top_output = os.capture(gpu_top_query)
  local gpu_top = {}
  for line in gpu_top_output:gmatch('[^\n]+') do
    local pid, pname, mem = line:match('(%d+), ([^,]+), ([%d.]+)')
    if pid and pname and mem then
      table.insert(gpu_top, {pid=pid, pname=pname, mem=tonumber(mem)})
    end
  end
  table.sort(gpu_top, function(a, b) return a.mem > b.mem end)
  y = y + scale(14)
  for i=1,math.min(3,#gpu_top) do
    local proc = gpu_top[i]
    -- Trim to executable name and max 18 chars
    local exec_name = proc.pname:match('([^/\\]+)$') or proc.pname
    exec_name = exec_name:sub(1, 18)
    write(cr, exec_name:pad(18), {
      pos = {x = leftTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'left', 'top'},
    })
    write(cr, tostring(proc.mem):pad(7, ' ', 'STR_PAD_LEFT') .. ' MB', {
      pos = {x = rightTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'right', 'top'},
    })
    y = y + scale(12)
  end

  -- icon for GPU
  -- if font is not found, fall back to text 'GPU'
  local text = '\u{f08ae}' -- nf-fa-video_card
  local font = {settings.icon_font, scale(60)}
  local icon_x = gauge_center.x - scale(25)
  local icon_y = gauge_center.y - scale(30)
  if config.gaugeLoc == 'right' then
    icon_x = gauge_center.x + scale(25)
  end
  if not isIconFontAvailable then
    text = 'GPU'
    font = {settings.fonts.significant, scale(20), 1}
    icon_y = gauge_center.y - scale(17)
  end
  write(cr, text, {
    pos = {x = gauge_center.x - scale(25), y = icon_y},
    font = font,
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end

function updateMemory(config)
  local pos = config.pos or {x = width-scale(205), y = scale(150)}
  local free = os.capture('LC_ALL=C free -m'):split('\n')
  local memTotal, memUsed, memFree, memShared, memBuffers, memAvailable =
    free[2]:match('(%d+) +(%d+) +(%d+) +(%d+) +(%d+) +(%d+)')
  local swapTotal, swapUsed, swapFree = free[3]:match('(%d+) +(%d+) +(%d+)')

  local gauge_from = 180
  local gauge_to = 400
  local gauge_center = {x = pos.x + scale(68), y = pos.y + scale(68)}
  local leftTextX = gauge_center.x + scale(47)
  local rightTextX = width
  if config.gaugeLoc == 'right' then
    gauge_from = -40
    gauge_to = 180
    gauge_center.x = pos.x + width - scale(68)
    leftTextX = pos.x
    rightTextX = gauge_center.x - scale(47)
  end

  -- memory
  local used = humanReadableBytes(memUsed + memShared, 'MiB'):pad(7, ' ', 'STR_PAD_LEFT')
  local total = humanReadableBytes(memTotal + 0, 'MiB'):pad(7, ' ', 'STR_PAD_LEFT')
  gauge(cr, memUsed + memShared, {
    pos = gauge_center,
    radius = scale(60), thickness = scale(15),
    from = gauge_from + scale(4), to = gauge_to - scale(4),
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    max = memTotal,
    warn = {from = memTotal * 0.5, color = settings.colors.gaugeInfo},
    crit = {from = memTotal * 0.95, color = settings.colors.gaugeCrit},
    level2 = {
      color = settings.colors.gauge,
      alpha = 0.2,
      value = memUsed + memShared + memBuffers
    }
  })

  local y = pos.y + scale(10)
  write(cr, 'RAM', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, used .. '/' .. total, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- caches
  local buffer = humanReadableBytes(memBuffers + 0, 'MiB'):pad(7, ' ', 'STR_PAD_LEFT')
  write(cr, 'Cache', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, buffer, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  y = y + scale(12)

  -- swap
  local used = humanReadableBytes(swapUsed + 0, 'MiB'):pad(7, ' ', 'STR_PAD_LEFT')
  local total = humanReadableBytes(swapTotal + 0, 'MiB'):pad(7, ' ', 'STR_PAD_LEFT')
  if config.gaugeLoc == 'right' then
    rightTextX = rightTextX + scale(10)
  else
    leftTextX = leftTextX - scale(10)
  end
  write(cr, 'Swap', {
    pos = {x = leftTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left', 'top'},
  })
  write(cr, used .. '/' .. total, {
    pos = {x = rightTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right', 'top'},
  })
  gauge(cr, tonumber(swapUsed), {
    pos = gauge_center,
    radius = scale(43), thickness = scale(11),
    from = gauge_from + scale(2), to = gauge_to - scale(2),
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    max = swapTotal,
    warn = {from = swapTotal * 0.1, color = settings.colors.gaugeWarn},
    crit = {from = swapTotal * 0.2, color = settings.colors.gaugeCrit},
  })

  -- graph
  y = y + scale(50)
  local graph_x = leftTextX
  local graph_width = width - graph_x
  local graph_direction = 'right'
  if config.gaugeLoc == 'right' then
    graph_x = rightTextX
    graph_width = graph_x
    graph_direction = 'left'
  end
  graph(cr, 'mem', tonumber(memUsed) + tonumber(memShared), {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'up',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(30),
    max = tonumber(memTotal),
  })

  -- top
  y = y + scale(15)
  if config.top and config.top > 0 then
    if cache.topMem == nil or updates % 4 == 0 then
      local topMem = os.capture('LC_ALL=C ps -eo comm,%mem --sort=-%mem --no-headers|head -40'):split('\n')
      topMem = table.map(topMem, function (row)
        local cmd, mem = row:match('^(.-) +([%d.]+)$')
        return {
          cmd = cmd,
          mem = tonumber(mem),
        }
      end)
      topMem = table.group(
        topMem,
        function (row) return row.cmd end,
        {
          sum = function (sum, row)
            if sum == nil then
              return row.mem
            end
            return sum + row.mem
          end,
        }
      )
      topMem = table.values(topMem)

      table.sort(topMem, function (row1, row2)
        return tonumber(row1.sum) > tonumber(row2.sum)
      end)
      cache.topMem = {}
      table.move(topMem, 1, config.top, 1, cache.topMem)
    end

    leftTextX = gauge_center.x + scale(10)
    rightTextX = width
    if config.gaugeLoc == 'right' then
      leftTextX = pos.x
      rightTextX = gauge_center.x - scale(10)
    end
    for _, data in pairs(cache.topMem) do
      write(cr, data.key:pad(20, ' '), {
        pos = { x = leftTextX, y = y },
        font = {settings.fonts.default, scale(10)},
        color = settings.colors.default,
        align = {'left', 'top'},
      });
      write(cr, tostring(data.sum):pad(6, ' ', 'STR_PAD_LEFT') .. '%', {
        pos = { x = rightTextX, y = y },
        font = {settings.fonts.default, scale(10)},
        color = settings.colors.default,
        align = {'right', 'top'},
      });
      y = y + scale(12)
    end
  end

  -- icon for RAM
  -- if font is not found, fall back to text 'RAM'
  local text = '\u{efc5}' -- nf-fa-memory
  local font = {settings.icon_font, scale(40)}
  local icon_x = gauge_center.x - scale(20)
  local icon_y = gauge_center.y - scale(20)
  if not isIconFontAvailable then
    text = 'RAM'
    font = {settings.fonts.significant, scale(20), 1}
    icon_y = gauge_center.y - scale(17)
  end
  write(cr, text, {
    pos = {x = icon_x, y = icon_y},
    font = font,
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end

function updateNetwork(config)
  local pos = config.pos or {x = width - scale(210), y = scale(315)}
  local network = config.network or getCurrentNetwork()
  if network == 'auto' then
    network = getCurrentNetwork()
  end

  local downspeed = tonumber(conky_parse('${downspeedf ' .. network .. '}'))
  local upspeed = tonumber(conky_parse('${upspeedf ' .. network .. '}'))
  if cache.maxDown == nil or cache.maxDown < downspeed then cache.maxDown = downspeed end
  if cache.maxUp == nil or cache.maxUp < upspeed then cache.maxUp = upspeed end
  if cache.maxDown == 0 or cache.maxUp == 0 then return end

  local gauge_center = {x = pos.x+scale(50), y = pos.y+scale(50)}
  local gauge_from = 180
  local gauge_to = 400
  if config.gaugeLoc == 'right' then
    gauge_center.x = pos.x + width - scale(50)
    gauge_from = -40
    gauge_to = 180
  end

  -- download gauge
  gauge(cr, downspeed, {
    pos = gauge_center,
    radius = scale(45), thickness = scale(10),
    from = gauge_from, to = gauge_to - scale(2),
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    max = cache.maxUp,
    warn = {from = cache.maxUp * .50, color = settings.colors.gaugeInfo},
  })
  -- upload gauge
  gauge(cr, upspeed, {
    pos = gauge_center,
    radius = scale(35), thickness = scale(5),
    from = gauge_from - scale(2), to = gauge_to - scale(1),
    background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
    color = settings.colors.gauge,
    alpha = settings.colors.gaugeAlpha,
    max = cache.maxUp,
    warn = {from = cache.maxUp * .50, color = settings.colors.gaugeInfo},
  })

  -- info
  local leftTextX = gauge_center.x + scale(40)
  local rightTextX = width
  if config.gaugeLoc == 'right' then
    leftTextX = pos.x
    rightTextX = gauge_center.x - scale(40)
  end
  local y = pos.y + scale(2)
  if config.hideInfo == nil or config.hideInfo == false then
    local localIp = conky_parse('${addr ' .. network .. '}')
    write(cr, 'LAN', {
      pos = {x = leftTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'left', 'top'},
    })
    write(cr, localIp:pad(15, ' ', 'STR_PAD_LEFT'), {
      pos = {x = rightTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'right', 'top'},
    })
    y = y + scale(12)
    local publicIp = conky_parse('${execi 3600 wget -q -O - checkip.dyndns.org | sed -e \'s/[^[:digit:]\\|.]//g\'}')
    write(cr, 'WAN', {
      pos = {x = leftTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'left', 'top'},
    })
    write(cr, publicIp:pad(15, ' ', 'STR_PAD_LEFT'), {
      pos = {x = rightTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'right', 'top'},
    })
  end

  y = y + scale(35)
  local graph_x = leftTextX
  local graph_width = width - graph_x
  local graph_direction = 'right'
  if config.gaugeLoc == 'right' then
    graph_x = rightTextX
    graph_width = graph_x
    graph_direction = 'left'
  end
  -- upload
  graph(cr, 'upload', upspeed, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'up',
    color = settings.colors.gauge,
    alpha = 0.9, max = 'auto',
    width = graph_width, height = scale(12),
  })
  -- download
  y = y + scale(3)
  graph(cr, 'download', downspeed, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'down',
    color = settings.colors.gauge,
    alpha = 0.9, max = 'auto',
    width = graph_width, height = scale(12),
  })

  -- current speeds / full speeds / total
  local x = gauge_center.x + scale(20)
  local upDownTextX = width
  if config.gaugeLoc == 'right' then
    x = pos.x + scale(10)
    upDownTextX = gauge_center.x - scale(10)
  end
  y = y + scale(38)
  path(cr, {
    pos = {x = x, y = y-scale(7)},
    points = {
        { x = x + scale(5), y = y},
        { x = x - scale(5), y = y},
    },
    fill = { color = upspeed > 0.1 and settings.colors.highlight or settings.colors.default },
  })
  local totalUp = conky_parse('${totalup ' .. network .. '}'):pad(7, ' ', 'STR_PAD_LEFT')
  local up = humanReadableBytes(upspeed, 'KiB'):pad(7, ' ', 'STR_PAD_LEFT')
  local upMax = humanReadableBytes(cache.maxUp, 'KiB'):pad(7, ' ', 'STR_PAD_LEFT')
  write(cr, up .. ' / ' .. upMax .. ' ' .. totalUp, {
    pos = {x = upDownTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right'},
  })
  y = y + scale(12)
  path(cr, {
    pos = {x = x, y = y},
    points = {
        { x = x + scale(5), y = y-scale(7)},
        { x = x - scale(5), y = y-scale(7)},
    },
    fill = { color = downspeed > 0.1 and settings.colors.highlight or settings.colors.default },
  })
  local totalDown = conky_parse('${totaldown ' .. network .. '}'):pad(7, ' ', 'STR_PAD_LEFT')
  local down = humanReadableBytes(downspeed, 'KiB'):pad(7, ' ', 'STR_PAD_LEFT')
  local downMax = humanReadableBytes(cache.maxDown, 'KiB'):pad(7, ' ', 'STR_PAD_LEFT')
  write(cr, down .. ' / ' .. downMax .. ' ' .. totalDown, {
    pos = {x = upDownTextX, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'right'},
  })

  -- icon for network f059f or ef09
  -- if font is not found, fall back to text 'NET'
  local text = '\u{ef09}'
  local font = {settings.icon_font, scale(40)}
  local icon_x = gauge_center.x - scale(22)
  local icon_y = gauge_center.y - scale(20)
  if not isIconFontAvailable then
    text = 'NET'
    font = {settings.fonts.significant, scale(20), 1}
    icon_y = gauge_center.y - scale(15)
  end
  if config.gaugeLoc == 'right' then
    icon_x = gauge_center.x - scale(22)
  end
  write(cr, text, {
    pos = {x = icon_x, y = icon_y},
    font = font,
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end

function updateDisks(config)
  local pos = config.pos or {x = 0, y = scale(250)}
  local disks = config.disks or 'auto'
  if disks == 'auto' then
    disks = {
      Root = '/'
    }

    if config.include ~= nil then
      for name,mount in pairs(config.include) do
        if os.capture('mount |grep \'' .. mount .. '\''):len() > 0 then
          disks[name] = mount
        end
      end
    end

    local mounts = os.capture('mount |grep -E \'^/dev/\''):split("\n")
    for _,mount in pairs(mounts) do
      mount = mount:match('on (/[a-zA-Z0-9 ./_-]*) type')
      if mount ~= nil and mount ~= '/' then
        local excluded = false
        for _,exclude in pairs(config.exclude) do
          if mount:match(exclude) then
            excluded = true
            break
          end
        end
        if not excluded then
          disks[mount:gsub('(.*/)(.*)', '%2'):gsub('[./_-]', ' '):titlecase()] = mount
        end
      end
    end
  end

  local sort, i = {}, 0
  if not config.sort or config.sort == 'size' then
    local sizes, j = {}, 0
    for name,mount in pairs(disks) do
      j = j + 1
      sizes[j] = {tonumber(os.capture('df -P ' .. mount .. '|tail -1|awk \'{print $2}\'')), name}
    end
    table.sort(sizes, function (a, b) return a[1] > b[1]; end)
    for _,size in pairs(sizes) do
      i = i + 1
      sort[i] = size[2]
    end
  elseif type(config.sort) == "table" then
    sort = config.sort
  end

  local radius, y, i = scale(56.5), pos.y + scale(8), 0
  local gauge_center = {x = pos.x + radius + 3.5, y = pos.y + radius + 3.5}
  local leftTextX = pos.x + radius + scale(13.5)
  local rightTextX = pos.x + width
  local gauge_from = 180
  local gauge_to = 360
  if config.gaugeLoc == 'right' then
    gauge_center.x = width - radius - 3.5
    gauge_from = 0
    gauge_to = 180
    leftTextX = pos.x
    rightTextX = pos.x + width - radius - scale(10)
  end
  for _,name in pairs(sort) do
    local mount = disks[name]
    i = i + 1
    if i > 4 then break end
    local used = conky_parse('${fs_used ' .. mount .. '}'):pad(7, ' ', 'STR_PAD_LEFT')
    local total = conky_parse('${fs_size ' .. mount .. '}'):pad(7, ' ', 'STR_PAD_LEFT')
    write(cr, name, {
      pos = {x = leftTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'left'},
    })
    write(cr, used .. ' / ' .. total, {
      pos = {x = rightTextX, y = y},
      font = {settings.fonts.default, scale(10)},
      color = settings.colors.default,
      align = {'right'},
    })
    gauge(cr, tonumber(conky_parse('${fs_used_perc ' .. mount .. '}')), {
        pos = gauge_center,
        radius = radius, thickness = scale(7),
        from = gauge_from, to = gauge_to,
        background = { color = settings.colors.gaugeBg, alpha = settings.colors.gaugeBgAlpha },
        color = settings.colors.gauge,
        alpha = settings.colors.gaugeAlpha,
        warn = {from = 85, color = settings.colors.gaugeInfo},
        crit = {from = 98, color = settings.colors.gaugeCrit},
    })
    radius = radius - scale(12)
    y = y + scale(12)
  end

  local function parseDiskioValue(val)
  local num, unit = val:match('([%d%.]+)%s*(%a+)')
  num = tonumber(num) or 0
  if unit == 'B' then
    return num
  elseif unit == 'KiB' then
    return num * 1024
  elseif unit == 'MiB' then
    return num * 1024 * 1024
  elseif unit == 'GiB' then
    return num * 1024 * 1024 * 1024
  else
    return num
  end
end

  -- graph for disk activity (read + write)
  local graph_x = gauge_center.x + scale(50)
  local graph_width = width - graph_x
  local graph_direction = 'right'
  local rw_text_x = graph_x
  if config.gaugeLoc == 'right' then
    graph_x = gauge_center.x - scale(50)
    graph_width = graph_x
    graph_direction = 'left'
    rw_text_x = pos.x
  end
  y = y + scale(4)
  local read_str = conky_parse('${diskio_read}')
  local disk_read = parseDiskioValue(read_str)
  write(cr, 'Read:' .. read_str .. '/s', {
    pos = {x = rw_text_x, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left'},
  })
  y = y + scale(18)
  
  graph(cr, 'disk', disk_read, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'up',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(15),
    max = 'auto',
  })
  local write_str = conky_parse('${diskio_write}')
  local disk_write = parseDiskioValue(write_str)
  y = y + scale(3)
  graph(cr, 'disk_write', disk_write, {
    pos = {x = graph_x, y = y},
    direction = graph_direction, amplitude = 'down',
    color = settings.colors.gauge,
    alpha = 0.9, width = graph_width, height = scale(15),
    max = 'auto',
  })
  y = y + scale(18) + scale(12)
  write(cr, 'Write:' .. write_str .. '/s', {
    pos = {x = rw_text_x, y = y},
    font = {settings.fonts.default, scale(10)},
    color = settings.colors.default,
    align = {'left'},
  })

  -- icon for hard disk
  local icon_x = gauge_center.x + scale(10)
  if config.gaugeLoc == 'right' then
    icon_x = gauge_center.x - scale(40)
  end
  -- if font is not found, fall back to text 'DISK'
  local text = '\u{f02ca}'
  local font = {settings.icon_font, scale(40)}
  local icon_y = gauge_center.y
  if not isIconFontAvailable then
    text = 'DISK'
    font = {settings.fonts.significant, scale(15), 1}
    icon_y = gauge_center.y + scale(10)
  end
  write(cr, text, {
    pos = {x = icon_x, y = icon_y},
    font = font,
    color = settings.colors.default,
    align = {'left', 'top'},
  })
end
