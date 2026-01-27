alias vi="nvim"
alias zsource="source ~/.zshrc"

# python
alias ve="python3 -m venv ./venv && echo 'venv created'"
alias va="source ./venv/bin/activate && echo 'sourced venv'"
alias da="deactivate && echo 'deactivated venv'"

# Kubernetes
alias k="kubectl"
alias mkube="minikube"

# Lazy
alias lgt="lazygit"
alias ldk="lazydocker"

# Quickaccess
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias zconf="nvim ~/.dotfiles/zsh/.zshrc"
alias tconf="nvim ~/.dotfiles/tmux/.config/tmux/tmux.conf"

## File system
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias cd="z"
