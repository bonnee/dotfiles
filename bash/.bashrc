#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source /usr/share/git/completion/git-prompt.sh

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true

PS1='[\e[32m\u\e[39m@\e[91m\h\e[39m] (\W\e[96m$(__git_ps1 " %s")\e[39m)\$ '

# Quick and dirty tweak to make aliases available under linux
alias sudo='sudo '

alias ls='ls --color=auto'
alias ll='ls -l'

alias xbuild-rel="xbuild /p:Configuration=Release"
alias gputop='sudo intel_gpu_top'
alias todo='todo.sh'

export TERM="xterm"

printf "\e[1mWhat to do:\e[0m\n"
todo.sh ls
printf "\n\e[1;7m$HOSTNAME\e[0m at your commands.\n"
