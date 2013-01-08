
_pd() {
    local cmd=${COMP_WORDS[0]}
    local cur=${COMP_WORDS[COMP_CWORD]}

    project_dir=`ls -d ~/Projects/*/ | xargs -n1 basename`
    words="$project_dir"

    COMPREPLY=($(compgen -W "$words" -- $cur))
    return 0
}

complete -o default -F _pd pd
