# jinli-conky

An elegant, pure lua conky configuration.

![screenshot](./examples/jinli-conky.png)

## Features

- Pure Lua configuration, not mixed conkyrc with lua.
- Elegant and modern design.
- Highly configurable, all configurations are in `jinli-config.lua`.
- Icons from Nerd Fonts.
- Auto detect network interfaces and disks.

## Install

Download or clone this repository. Ensure Conky is installed, then run the `start.sh` script:

```bash
./start.sh
```

The script creates `jinli-config.lua` from the example when it does not already exist, then starts Conky after a short delay. It also writes `conky-start.desktop` beside `start.sh`. To start it automatically at login:

```bash
mkdir -p ~/.config/autostart
cp conky-start.desktop ~/.config/autostart/
```

The desktop entry uses the repository's absolute path. If you move or rename the checkout, run `./start.sh --no-sleep` once and copy the regenerated entry again.

## Font

This conky configuration requires [Nerd Fonts](https://www.nerdfonts.com/) for icons. Or the icons will not display and it will display text instead.

Here I packed the icons used in this config into a custom font, which is based on the original `Symbols Nerd Font`. The font name is still `Symbols Nerd Font`, but with only the icons used in this config to reduce its size. The font file is in the `fonts` folder, named `subset-SymbolsNF.ttf`. You can double click to install it or you can install it by copying it to `~/.local/share/fonts/` or `/usr/share/fonts/`:

```bash
cp fonts/subset-SymbolsNF.ttf ~/.local/share/fonts/
fc-cache -fv
```

You can view what icons are included in the font I packed in [this website](https://wakamaifondue.com/). It includes basic letters, numbers, and following icons:

![icons](./examples/icons.png)

Or you can use the original `Symbols Nerd Font` if you prefer, which can be downloaded from [Nerd Fonts](https://www.nerdfonts.com/font-downloads).

## Configuration

All configurations are in `jinli-config.lua`. You can change the position of widgets, colors, fonts, etc.

The runtime normalizes the distribution name used for the OS icon by removing
optional surrounding single or double quotes. This is needed on systems such
as NixOS where `lsb_release -is` may return a quoted name such as `"NixOS"`.

### Global Configurations

- Set `local scaling = 'auto'` to fit the detected display, or use a number for
  a fixed scale. In auto mode, set `autoScalingOutput` to an output name from
  `kscreen-doctor -o` or `niri msg outputs` when Conky should not use the
  primary display.

- In `conky.config` table, you can change the width and height.

- In `conky.config` table, you can change the update interval, location, transparency, gap to screen edge, etc.

### Widget Configurations

Each widget has its own configuration table in `conky.jinli.widgets`. You can show/hide widgets, change their position, and other specific settings. General settings for each widget include:

- `hide`: Set to `true` to hide the widget, `false` to show it, or `auto` for the GPU widget to hide it when no supported GPU is detected.
- `pos`: A table specifying the x and y position of the widget, e.g., `pos = {x = 0, y = scale(100)}`.
- `gaugeLoc`: Set to `'left'`, `'right'`.

### GPU Widget Notes

The GPU widget now supports both NVIDIA and AMD on Linux.

- `gpuBackend`: `auto` (default), `nvidia`, or `amd`.
- `amdCard`: `auto` (default) or a specific card such as `card0`, `card1`.

In `auto` mode, it detects an NVIDIA GPU through `nvidia-smi -L`, otherwise it falls back to AMD sysfs (`/sys/class/drm/card*/device/...` and `hwmon`).

The default GPU widget uses `hide = 'auto'`. Explicit `hide = true` and `hide = false` always override automatic visibility. The system widget shows a GPU row only when `lspci` detects a display controller.

## Known issues

- Automatic scaling has been tested on KDE Wayland. Support for X11 and other
  desktops uses XRandR and `xdpyinfo` fallbacks but has not yet been tested
  across all GUI environments. Niri uses its native Wayland layer-shell
  backend and `niri msg outputs`; visual placement still needs testing on
  different Niri layouts and monitor arrangements.
- KDE's `kscreen-doctor` output format varies by version and may contain ANSI
  color sequences. The parser strips those sequences and supports both
  explicit primary markers and numbered KScreen priorities. Please report any
  output format that is not detected correctly.
- On multi-monitor systems, set `autoScalingOutput` explicitly if KDE's
  preferred output is not the display where Conky should appear.

## Acknowledgements

- This configuration is adapted from [miracle-conky](https://github.com/tflori/miracle-conky).
- [Nerd Fonts](https://www.nerdfonts.com/) and "Symbols Nerd Font" for icons.
- [Transfonter](https://transfonter.org/) to pack the custom font.
- [Wakamai Fondue](https://wakamaifondue.com/) for viewing and creating custom fonts.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
