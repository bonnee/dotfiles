#!/bin/sh

dotdir=$HOME/.dotfiles
alias dots='/usr/bin/git --git-dir=$dotdir --work-tree=$HOME'

git clone --bare https://github.com/Bonnee/dotfiles.git $dotdir
function config {
   /usr/bin/git --git-dir=$dotdir --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    dots checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dots-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no
