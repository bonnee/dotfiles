#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Quick and dirty tweak to make aliases available under linux
alias sudo='sudo '
alias xbuild-rel="xbuild /p:Configuration=Release"

export TERM="xterm"

#neofetch
