
_doggo() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="-v --version -h --help -q --query -t --type -n --nameserver -c --class -r --reverse --strategy --ndots --search --timeout -4 --ipv4 -6 --ipv6 --tls-hostname --skip-hostname-verification -J --json --short --color --debug --time"

    case "${prev}" in
        -t|--type)
            COMPREPLY=( $(compgen -W "A AAAA CAA CNAME HINFO MX NS PTR SOA SRV TXT" -- ${cur}) )
            return 0
            ;;
        -c|--class)
            COMPREPLY=( $(compgen -W "IN CH HS" -- ${cur}) )
            return 0
            ;;
        -n|--nameserver)
            COMPREPLY=( $(compgen -A hostname -- ${cur}) )
            return 0
            ;;
        --strategy)
            COMPREPLY=( $(compgen -W "all random first" -- ${cur}) )
            return 0
            ;;
        --search|--color)
            COMPREPLY=( $(compgen -W "true false" -- ${cur}) )
            return 0
            ;;
    esac

    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    else
        COMPREPLY=( $(compgen -A hostname -- ${cur}) )
    fi
}

complete -F _doggo doggo

