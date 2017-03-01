# ~/.bash_profile
#
#
PATH=$PATH:$HOME/bin

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  IS_SSH=true
else
  IS_SSH=false
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
