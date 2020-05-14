# bash completion for usc                                  -*- shell-script -*-

__usc_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__usc_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__usc_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__usc_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__usc_handle_reply()
{
    __usc_debug "${FUNCNAME[0]}"
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r c; do
                COMPREPLY+=("$c")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __usc_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __usc_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r c; do
        COMPREPLY+=("$c")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r c; do
            COMPREPLY+=("$c")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __usc_custom_func >/dev/null; then
			# try command name qualified custom func
			__usc_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__usc_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__usc_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__usc_handle_flag()
{
    __usc_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __usc_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __usc_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __usc_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __usc_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __usc_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__usc_handle_noun()
{
    __usc_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __usc_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __usc_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__usc_handle_command()
{
    __usc_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_usc_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __usc_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__usc_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __usc_handle_reply
        return
    fi
    __usc_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __usc_handle_flag
    elif __usc_contains_word "${words[c]}" "${commands[@]}"; then
        __usc_handle_command
    elif [[ $c -eq 0 ]]; then
        __usc_handle_command
    elif __usc_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __usc_handle_command
        else
            __usc_handle_noun
        fi
    else
        __usc_handle_noun
    fi
    __usc_handle_word
}

_usc_completion()
{
    last_command="usc_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_usc_delete()
{
    last_command="usc_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    local_nonpersistent_flags+=("--debug")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--dry")
    local_nonpersistent_flags+=("--dry")
    flags+=("--files=")
    two_word_flags+=("--files")
    local_nonpersistent_flags+=("--files=")
    flags+=("--quiet")
    local_nonpersistent_flags+=("--quiet")
    flags+=("--start=")
    two_word_flags+=("--start")
    local_nonpersistent_flags+=("--start=")
    flags+=("--target=")
    two_word_flags+=("--target")
    local_nonpersistent_flags+=("--target=")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_usc_md5()
{
    last_command="usc_md5"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    local_nonpersistent_flags+=("--debug")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--files=")
    two_word_flags+=("--files")
    local_nonpersistent_flags+=("--files=")
    flags+=("--target=")
    two_word_flags+=("--target")
    local_nonpersistent_flags+=("--target=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_flag+=("--dir=")
    must_have_one_noun=()
    noun_aliases=()
}

_usc_update()
{
    last_command="usc_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    local_nonpersistent_flags+=("--debug")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_usc_upload()
{
    last_command="usc_upload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    local_nonpersistent_flags+=("--debug")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--dry")
    local_nonpersistent_flags+=("--dry")
    flags+=("--files=")
    two_word_flags+=("--files")
    local_nonpersistent_flags+=("--files=")
    flags+=("--quiet")
    local_nonpersistent_flags+=("--quiet")
    flags+=("--start=")
    two_word_flags+=("--start")
    local_nonpersistent_flags+=("--start=")
    flags+=("--target=")
    two_word_flags+=("--target")
    local_nonpersistent_flags+=("--target=")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_flag+=("--dir=")
    must_have_one_noun=()
    noun_aliases=()
}

_usc_version()
{
    last_command="usc_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_usc_wait()
{
    last_command="usc_wait"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--debug")
    local_nonpersistent_flags+=("--debug")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--files=")
    two_word_flags+=("--files")
    local_nonpersistent_flags+=("--files=")
    flags+=("--quiet")
    local_nonpersistent_flags+=("--quiet")
    flags+=("--start=")
    two_word_flags+=("--start")
    local_nonpersistent_flags+=("--start=")
    flags+=("--target=")
    two_word_flags+=("--target")
    local_nonpersistent_flags+=("--target=")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_usc_root_command()
{
    last_command="usc"

    command_aliases=()

    commands=()
    commands+=("completion")
    commands+=("delete")
    commands+=("md5")
    commands+=("update")
    commands+=("upload")
    commands+=("version")
    commands+=("wait")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--color")
    flags+=("--json")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_usc()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __usc_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("usc")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __usc_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_usc usc
else
    complete -o default -o nospace -F __start_usc usc
fi

# ex: ts=4 sw=4 et filetype=sh