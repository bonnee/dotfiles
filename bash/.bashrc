#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

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

function fawk {
    first="awk '{print "
    last="}'"
    cmd="${first}\$${1}${last}"
    eval $cmd
}

export TERM="xterm"
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export EDITOR=nano

# bash history mods
export HISTFILESIZE=20000
export HISTSIZE=10000
# Combine multiline commands into one in history
shopt -s cmdhist
# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
HISTIGNORE="&:ls:[bf]g:exit"

# Quick and dirty tweak to make aliases available under sudo
alias sudo='sudo '

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -l'
alias la='ls -a'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

if [ -x /usr/bin/trash-put ]; then
    alias rm='trash-put'
fi

alias vi='vim'
alias xbuild-rel="xbuild /p:Configuration=Release"
alias todo='todo.sh'
if [ -x /usr/bin/intel_gpu_top ]; then
	alias itop='/usr/bin/intel_gpu_top'
fi
BOLD="\[\e[1m\]"
RST_BOLD="\[\e[21m\]"

RST_COLOR="\[\e[39m\]"
USR_COLOR="\[\e[94m\]"
HST_COLOR="\[\e[33m\]"
GIT_COLOR="\[\e[32m\]"

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    host="@$HST_COLOR\h$RST_COLOR"
fi

PS1="$USR_COLOR\A $BOLD\u$RST_BOLD$RST_COLOR$host [\W$GIT_COLOR\$(__git_ps1 ' %s')$RST_COLOR]$ "

printf "Welcome $USER,\n"
if hash todo.sh 2> /dev/null; then
    printf "\n\e[1mHere are some things you need to do:\e[0m\n"
    todo.sh ls
fi

printf "\nYou still have \e[1m$(($(cat /proc/meminfo | sed -n '3p' | fawk 2) / 1024)) MB\e[21m of memory to mess with.\n"
printf "Load is \e[1m$(cat /proc/loadavg | fawk 1)\e[21m.\n"

printf "\n\e[1;7m$HOSTNAME\e[0m is ready.\n"
