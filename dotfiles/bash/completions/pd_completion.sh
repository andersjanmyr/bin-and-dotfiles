_pd() {
    local cmd=${COMP_WORDS[0]}
    local cur=${COMP_WORDS[COMP_CWORD]}

    project_dir=`find ~/Projects -print -type d -maxdepth 2 | tail +2 | xargs -n1 basename`
    words="$project_dir"

    COMPREPLY=($(compgen -W "$words" -- $cur))
    return 0
}

complete -o default -F _pd pd
