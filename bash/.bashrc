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
alias gputop='sudo intel_gpu_top'

export TERM="xterm"

echo $HOSTNAME at your commands.
