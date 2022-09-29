_curl() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--cookie --compressed --data --data-binary --data-url-encode --dump-header --fail --form --form-string --header --head --json --output --referer --request --silent --user --user-agent --verbose"

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}

complete -o default -F _curl curl
