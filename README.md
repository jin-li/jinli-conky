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

Download or clone this repository. Then run the `start.sh` script:

```bash
./start.sh
```

Running above script also generate an autostart desktop entry in current directory, called `conky-start.desktop`. You can copy it to `~/.config/autostart/` to make conky start at login.

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

### Global Configurations

- Above `conky.config` table, you can change the width, height and scaling factor.

- In `conky.config` table, you can change the update interval, location, transparency, gap to screen edge, etc.

- In `conky.jinli` table, you can change the scaling factor and icon font.

### Widget Configurations

Each widget has its own configuration table in `conky.jinli.widgets`. You can show/hide widgets, change their position, and other specific settings. General settings for each widget include:

- `hide`: Set to `true` to hide the widget, `false` to show it.
- `pos`: A table specifying the x and y position of the widget, e.g., `pos = {x = 0, y = scale(100)}`.
- `gaugeLoc`: Set to `'left'`, `'right'`.

## Acknowledgements

- This configuration is adapted from [miracle-conky](https://github.com/tflori/miracle-conky).
- [Nerd Fonts](https://www.nerdfonts.com/) and "Symbols Nerd Font" for icons.
- [Transfonter](https://transfonter.org/) to pack the custom font.
- [Wakamai Fondue](https://wakamaifondue.com/) for viewing and creating custom fonts.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
