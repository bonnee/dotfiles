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


if [[ $EUID -eq "0" ]]; then
    USR_COLOR=$RED
else
    USR_COLOR=$LBLUE
fi
HST_COLOR=$YELLOW
GIT_COLOR=$GREEN

export TERM="xterm"
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export EDITOR=vim

# bash history mods
export HISTFILESIZE=20000
export HISTSIZE=10000

# Functions

# shortcut to awk '{print $1}' command
fawk()
{
    first="awk '{print "
    last="}'"
    cmd="${first}\$${1}${last}"
    eval $cmd
}

free_mem()
{
    printf $(($(cat /proc/meminfo | sed -n '3p' | fawk 2) / 1024))
}

load()
{
    cat /proc/loadavg | fawk 1
}


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
if ! hash __git_ps1 2> /dev/null; then
    source /usr/share/git/completion/git-prompt.sh
fi

bind "set show-all-if-ambiguous On"

# Combine multiline commands into one in history
shopt -s cmdhist
# Auto cd when a path is entered
shopt -s autocd

# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
HISTIGNORE="&:ls:[bf]g:exit"

# Quick and dirty tweak to make aliases available under sudo
alias sudo='sudo '

alias ll='ls -l'
alias la='ls -a'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias xbuild-rel="xbuild /p:Configuration=Release"
alias todo='todo.sh'

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if [ -x /usr/bin/pbzip2 ]; then
	alias bzip2='pbzip2'
fi

if [ -x /usr/bin/intel_gpu_top ]; then
	alias itop='/usr/bin/intel_gpu_top'
fi

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    host="@\[$HST_COLOR\]\h\[$RST_COLOR\]"
fi

printf "Welcome $USER,\n"
if hash todo.sh ls 2> /dev/null; then
    printf "$BOLD\nTODO:$RST_ATTR\n"
    todo.sh ls
fi

printf "\n$BOLD$REVERSE$HOSTNAME$RST_ATTR [$GREEN$(free_mem) M$RST_COLOR | $GREEN$(load)$RST_COLOR] is ready.\n"

export PS1="\[$USR_COLOR\]\A \$(free_mem) \[$BOLD\]\u\[$RST_ATTR$RST_COLOR\]$host [\W\[$GIT_COLOR\]\$(__git_ps1 ' %s')\[$RST_COLOR\]]$ "
export PS2='> '
