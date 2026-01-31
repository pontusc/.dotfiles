export EDITOR="/usr/bin/nvim"
export GIT_EDITOR="/usr/bin/nvim"
export SUDO_EDITOR="$EDITOR"

# History Configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# Options
setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
setopt SHARE_HISTORY          # Share history between all sessions.
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
