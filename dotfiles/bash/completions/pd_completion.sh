
_pd() {
    local cmd=${COMP_WORDS[0]}
    local cur=${COMP_WORDS[COMP_CWORD]}

    words=`ls ~/Projects ~/External_Projects | awk '{ print $1 }'`
    echo -n $words > .pd_completion
    COMPREPLY=($(compgen -W "$words" -- $cur))
    return 0
}

complete -o default -F _pd pd
