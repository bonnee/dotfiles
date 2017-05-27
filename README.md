# dotfiles
A collection of my configuration dotfiles
# Installation
1. Clone this repo in your home directory
2. Use [GNU stow](http://www.gnu.org/software/stow/) to install the files you want
2. Use [mir.qualia](https://github.com/darkfeline/mir.qualia) to auto comment/uncomment config sections to handle more devices

# Content
## `/bash`
Configuration for [Bash] (https://savannah.gnu.org/git/?group=bash)
## `/compton`
Configuration for [compton](https://github.com/chjj/compton)
## `/dunst`
Configuration for [Dunst](http://knopwob.org/dunst/index.html)
## `/htop`
Configuration for [htop](http://hisham.hm/htop/)
## `/i3`
* `.config/config` [i3-gaps](https://github.com/Airblader/i3) config
* `.config/i3blocks` [i3blocks](https://github.com/vivien/i3blocks) config
* `.config/blocks/` container of custom i3blocks blocklets
* `.config/wallpaper.png` my wallpaper (I know, it sucks)
## `/neofetch`
Configuration for [Neofetch](https://github.com/dylanaraps/neofetch)
## `/scripts`
* `bin/lock.sh` [i3lock](https://github.com/i3/i3lock) based lockscreen script
## `/synergy`
Configuration for [Synergy](http://symless.com/synergy/)
## `/termite`
Configuration for [termite](https://github.com/thestinger/termite)
## `/vscode`
Configuration for [Visual Studio Code](https://github.com/Microsoft/vscode)
## `/xresources`
Configuration for [X Resources](https://wiki.archlinux.org/index.php/X_resources)  
WARN: To use xresources files you have to add `#include ".Xresources.d/FILENAME` for every file you want to include into `~/.Xresources`
