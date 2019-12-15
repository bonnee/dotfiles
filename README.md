# dotfiles X11 Edition
A collection of my configuration dotfiles.
# Installation
1. Clone this repo in your home directory
2. Use [GNU stow](https://www.gnu.org/software/stow/) to install the files you want
2. Use [mir.qualia](https://github.com/darkfeline/mir.qualia) to auto comment/uncomment config sections to handle more devices

# Content
## `/alacritty`
Configuration for [alacritty](https://github.com/jwilm/alacritty)
## `/bash`
Configuration for [Bash](https://www.gnu.org/software/bash/)
## `/dunst`
Configuration for [Dunst](http://knopwob.org/dunst/index.html)
## `/htop`
Configuration for [htop](https://hisham.hm/htop/)
## `/i3`
* `.config/i3/config` [i3-gaps](https://github.com/Airblader/i3) config
* `.config/i3/i3blocks` [i3blocks](https://vivien.github.io/i3blocks/) config
* `.config/i3/blocks/` my custom blocklets
* `.config/i3/wallpaper.png` my wallpaper

## `/locale`
Configuration for language and locales
## `/logitech`
Configuration for my MX Master 2S using [logiops](https://github.com/PixlOne/logiops)
## `/rofi`
Configuration for [rofi](https://github.com/DaveDavenport/rofi)
## `/scripts`
Various utilities and scripts
## `/vim`
Configuration for [vim](https://vim.sourceforge.io/)
## `/vscode`
Configuration for [Visual Studio Code](https://code.visualstudio.com/)
## `/xinit`
My .xinitrc
## `/xresources`
X Resources file

WARN: To use xresources files you have to add `#include ".Xresources.d/FILENAME` for every file you want to include into `~/.Xresources`
