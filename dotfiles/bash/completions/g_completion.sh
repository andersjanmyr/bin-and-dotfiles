source /opt/homebrew/etc/bash_completion.d/git-completion.bash

_git_squash() {
    __gitcomp_nl "$(__git_refs)"
}

# Register the completion
__git_complete squash _git_squash

__git_complete g __git_main
