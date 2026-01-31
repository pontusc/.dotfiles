# Launch tmux in default session if exists, make if not
tmux() {
    if [ $# -eq 0 ]; then
        command tmux attach -t default || command tmux new -s default
    else
        command tmux "$@"
    fi
}
