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

PATH=$PATH:$HOME/bin

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
export HISTIGNORE="&:ls:[bf]g:exit"

PS1='\[\e[94m\]\A \[\e[1m\]\u\[\e[21m\e[39m\]@\[\e[2m\]\h\[\e[22m\] [\W\[\e[32m\]$(__git_ps1 " %s")\[\e[39m\]]\$ '

# Quick and dirty tweak to make aliases available under linux
alias sudo='sudo '

alias grep='grep --color=auto'

alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -a'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias vi='vim'
alias xbuild-rel="xbuild /p:Configuration=Release"
alias gputop='sudo intel_gpu_top'
alias todo='todo.sh'


printf "Welcome $USER,\n"
if hash todo.sh 2> /dev/null; then
    printf "\n\e[1mHere are some things you need to do:\e[0m\n"
    todo.sh ls
fi

printf "\nYou still have $(free -h | fawk 3 | sed -n '2p') of memory to mess with.\n"
printf "Load is $(cat /proc/loadavg | fawk 1).\n"

printf "\n\e[1;7m$HOSTNAME\e[0m is ready.\n"
