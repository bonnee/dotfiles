# dotfiles
A collection of my configuration dotfiles
# Installation
1. Clone this repo in your home directory
2. Use [GNU stow](http://www.gnu.org/software/stow/) to install the files you want

# Content
## `/atom`
Configuration for [Atom] (https://atom.io/)
## `/bash`
Configuration for [Bash] (https://savannah.gnu.org/git/?group=bash)
## `/compton`
Configuration for [compton](https://github.com/chjj/compton)
## `/i3`
* `.config/config` [i3-gaps](https://github.com/Airblader/i3) config
* `.config/i3blocks` [i3blocks](https://github.com/vivien/i3blocks) config
* `.config/lock.sh` [i3lock](https://github.com/i3/i3lock) based lockscreen script
* `.config/blocks/` container of i3blocks blocklets
* `.config/wallpaper.jpg` my wallpaper (I know, it sucks)

## `/dunst`
Configuration for [Dunst](http://knopwob.org/dunst/index.html)
## `/htop`
Configuration for [htop](http://hisham.hm/htop/)
## `/synergy`
Configuration for [Synergy](http://symless.com/synergy/)
## `/termite`
Configuration for [termite](https://github.com/thestinger/termite)
## `/xresources`
Configuration for [X Resources](https://wiki.archlinux.org/index.php/X_resources)  
WARN: To use xresources files you have to add `#include ".Xresources.d/FILENAME` for every file you want to include into `~/.Xresources`
