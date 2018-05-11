_gd() {
    local cmd=${COMP_WORDS[0]}
    local cur=${COMP_WORDS[COMP_CWORD]}

    project_dir=`find ~/gocode/src -print -type d -maxdepth 3 | head -1`
    words="$project_dir"

    COMPREPLY=($(compgen -W "$words" -- $cur))
    return 0
}

complete -o default -F _gd gd

