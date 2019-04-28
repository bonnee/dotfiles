#!/usr/bin/env bash
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

RST_ATTR="\e[0m"
RST_COLOR="\e[39m"

BOLD="\e[1m"
DIM="\e[2m"
ULINE="\e[4m"
BLINK="\e[5m"
REVERSE="\e[7m"
HIDDEN="\e[8m"

BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
LGRAY="\e[37m"
DGRAY="\e[90m"
LRED="\e[91m"
LGREEN="\e[92m"
LYELLOW="\e[93m"
LBLUE="\e[94m"
LMAGENTA="\e[95m"
LCYAN="\e[96m"
WHITE="\e[97m"

# If root, show username in red
if [[ $EUID -eq "0" ]]; then
    USR_COLOR=$RED
else
    USR_COLOR=$LBLUE
fi
HST_COLOR=$YELLOW
GIT_COLOR=$GREEN

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export EDITOR=vim

# bash history mods
export HISTFILESIZE=20000
export HISTSIZE=10000

git_prompt="/usr/share/git/completion/git-prompt.sh"

# shortcut to awk '{print $1}' command
fawk()
{
    first="awk '{print "
    last="}'"
    cmd="${first}\$${1}${last}"
    eval "$cmd"
}

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

if [ -r /usr/share/undistract-me/long-running.bash ]; then
  source /usr/share/undistract-me/long-running.bash;notify_when_long_running_commands_finish_install
fi

if ! type __git_ps1 >/dev/null 2>&1 && [ -r "$git_prompt" ]; then
  source "$git_prompt"
fi

bind "set show-all-if-ambiguous On"
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Combine multiline commands into one in history
shopt -s cmdhist
# Auto cd when a path is entered
shopt -s autocd

# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
HISTIGNORE="&:ls:[bf]g:exit"

# Quick and dirty tweak to make aliases available under sudo
alias sudo='sudo '

alias ll='ls -lh'
alias la='ls -lah'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias todo='todo.sh'
alias p='python'
alias tb='taskbook'

alias setclip='xclip -selection c'
alias getclip='xclip -selection c -o'

if type -p dircolors >/dev/null; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if type -p pbzip2 >/dev/null; then
  alias bzip2='pbzip2'
fi

itop="$(type -p intel_gpu_top)"
if [ ! -z $itop ]; then
  alias itop="$itop"
fi

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [[ $EUID -eq "0" ]];  then
  host="@\[$HST_COLOR\]\h\[$RST_COLOR\]"
fi

#printf "Welcome $USER,\n"
if hash todo.sh 2> /dev/null; then
    printf "%bTo Do:%b\n" "$BOLD" "$RST_ATTR"
    #tb
    todo.sh ls
    printf "\n"
fi

printf "%b%b%b%b is ready.\n" "$BOLD" "$REVERSE" "$HOSTNAME" "$RST_ATTR"

export PS1="\[$USR_COLOR\]\[$BOLD\]\u\[$RST_ATTR$RST_COLOR\]$host [\W\[$GIT_COLOR\]\$(__git_ps1 ' %s' 2> /dev/null)\[$RST_COLOR\]]> "
export PS2='> '

trap 'echo -ne "\033]2;$(history 1 | sed "s/^[ ]*[0-9]*[ ]*//g")\007"' DEBUG

