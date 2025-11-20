# Start Tmux when interactive
if (
    (which tmux | is-not-empty)
    and ($env.TMUX? | is-empty)                                         # not already in tmux
    and (not ($env.TERM? | default "" | str contains "tmux"))           # not inside tmux terminal
    and (not ($env.TERM_PROGRAM? | default "" | str contains "nvim"))   # not VS Code terminal
    and ($env.NVIM? | is-empty)                                         # not inside Neovim terminal
    and ($nu.is-interactive)                                            # only interactive sessions
    and ($env.NO_TMUX? | is-empty)                                      # manual opt-out
) {
    let session = ""

    # Check if session exists and has attached clients
    let attached_clients = (tmux list-clients -t $session | lines | length)
    let session_exists = (tmux has-session -t $session | complete | get exit_code) == 0

    if (not $session_exists) {
        tmux new-session -s $session
    } else if $attached_clients == 0 {
        tmux attach-session -t $session
    } else {
        tmux new-session -s "?"
    }
}
