# bash completion for arduino-cli                          -*- shell-script -*-

__arduino-cli_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__arduino-cli_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__arduino-cli_index_of_word()
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

__arduino-cli_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__arduino-cli_handle_go_custom_completion()
{
    __arduino-cli_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly arduino-cli allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __arduino-cli_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __arduino-cli_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __arduino-cli_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __arduino-cli_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __arduino-cli_debug "${FUNCNAME[0]}: the completions are: ${out[*]}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __arduino-cli_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __arduino-cli_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __arduino-cli_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __arduino-cli_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subDir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out[0]}")
        if [ -n "$subdir" ]; then
            __arduino-cli_debug "Listing directories in $subdir"
            __arduino-cli_handle_subdirs_in_dir_flag "$subdir"
        else
            __arduino-cli_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out[*]}" -- "$cur")
    fi
}

__arduino-cli_handle_reply()
{
    __arduino-cli_debug "${FUNCNAME[0]}"
    local comp
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
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
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
                __arduino-cli_index_of_word "${flag}" "${flags_with_completion[@]}"
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
    __arduino-cli_index_of_word "${prev}" "${flags_with_completion[@]}"
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
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __arduino-cli_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __arduino-cli_custom_func >/dev/null; then
			# try command name qualified custom func
			__arduino-cli_custom_func
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
__arduino-cli_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__arduino-cli_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__arduino-cli_handle_flag()
{
    __arduino-cli_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __arduino-cli_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __arduino-cli_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __arduino-cli_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
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
    if [[ ${words[c]} != *"="* ]] && __arduino-cli_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __arduino-cli_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__arduino-cli_handle_noun()
{
    __arduino-cli_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __arduino-cli_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __arduino-cli_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__arduino-cli_handle_command()
{
    __arduino-cli_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_arduino-cli_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __arduino-cli_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__arduino-cli_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __arduino-cli_handle_reply
        return
    fi
    __arduino-cli_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __arduino-cli_handle_flag
    elif __arduino-cli_contains_word "${words[c]}" "${commands[@]}"; then
        __arduino-cli_handle_command
    elif [[ $c -eq 0 ]]; then
        __arduino-cli_handle_command
    elif __arduino-cli_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __arduino-cli_handle_command
        else
            __arduino-cli_handle_noun
        fi
    else
        __arduino-cli_handle_noun
    fi
    __arduino-cli_handle_word
}

_arduino-cli_board_attach()
{
    last_command="arduino-cli_board_attach"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_board_details()
{
    last_command="arduino-cli_board_details"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--full")
    flags+=("-f")
    local_nonpersistent_flags+=("--full")
    flags+=("--list-programmers")
    local_nonpersistent_flags+=("--list-programmers")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_board_list()
{
    last_command="arduino-cli_board_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_board_listall()
{
    last_command="arduino-cli_board_listall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--show-hidden")
    flags+=("-a")
    local_nonpersistent_flags+=("--show-hidden")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_board()
{
    last_command="arduino-cli_board"

    command_aliases=()

    commands=()
    commands+=("attach")
    commands+=("details")
    commands+=("list")
    commands+=("listall")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_burn-bootloader()
{
    last_command="arduino-cli_burn-bootloader"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--port=")
    flags+=("--programmer=")
    two_word_flags+=("--programmer")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--programmer=")
    flags+=("--verify")
    flags+=("-t")
    local_nonpersistent_flags+=("--verify")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_cache_clean()
{
    last_command="arduino-cli_cache_clean"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_cache()
{
    last_command="arduino-cli_cache"

    command_aliases=()

    commands=()
    commands+=("clean")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_compile()
{
    last_command="arduino-cli_compile"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--build-cache-path=")
    two_word_flags+=("--build-cache-path")
    local_nonpersistent_flags+=("--build-cache-path=")
    flags+=("--build-path=")
    two_word_flags+=("--build-path")
    local_nonpersistent_flags+=("--build-path=")
    flags+=("--build-property=")
    two_word_flags+=("--build-property")
    local_nonpersistent_flags+=("--build-property=")
    flags+=("--clean")
    local_nonpersistent_flags+=("--clean")
    flags+=("--export-binaries")
    flags+=("-e")
    local_nonpersistent_flags+=("--export-binaries")
    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--libraries=")
    two_word_flags+=("--libraries")
    local_nonpersistent_flags+=("--libraries=")
    flags+=("--optimize-for-debug")
    local_nonpersistent_flags+=("--optimize-for-debug")
    flags+=("--output-dir=")
    two_word_flags+=("--output-dir")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--port=")
    flags+=("--preprocess")
    local_nonpersistent_flags+=("--preprocess")
    flags+=("--programmer=")
    two_word_flags+=("--programmer")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--programmer=")
    flags+=("--quiet")
    local_nonpersistent_flags+=("--quiet")
    flags+=("--show-properties")
    local_nonpersistent_flags+=("--show-properties")
    flags+=("--upload")
    flags+=("-u")
    local_nonpersistent_flags+=("--upload")
    flags+=("--verify")
    flags+=("-t")
    local_nonpersistent_flags+=("--verify")
    flags+=("--vid-pid=")
    two_word_flags+=("--vid-pid")
    local_nonpersistent_flags+=("--vid-pid=")
    flags+=("--warnings=")
    two_word_flags+=("--warnings")
    local_nonpersistent_flags+=("--warnings=")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_completion()
{
    last_command="arduino-cli_completion"

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
    flags+=("--no-descriptions")
    local_nonpersistent_flags+=("--no-descriptions")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("fish")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_arduino-cli_config_add()
{
    last_command="arduino-cli_config_add"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config_delete()
{
    last_command="arduino-cli_config_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config_dump()
{
    last_command="arduino-cli_config_dump"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config_init()
{
    last_command="arduino-cli_config_init"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dest-dir=")
    two_word_flags+=("--dest-dir")
    local_nonpersistent_flags+=("--dest-dir=")
    flags+=("--dest-file=")
    two_word_flags+=("--dest-file")
    local_nonpersistent_flags+=("--dest-file=")
    flags+=("--overwrite")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config_remove()
{
    last_command="arduino-cli_config_remove"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config_set()
{
    last_command="arduino-cli_config_set"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_config()
{
    last_command="arduino-cli_config"

    command_aliases=()

    commands=()
    commands+=("add")
    commands+=("delete")
    commands+=("dump")
    commands+=("init")
    commands+=("remove")
    commands+=("set")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_download()
{
    last_command="arduino-cli_core_download"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_install()
{
    last_command="arduino-cli_core_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--run-post-install")
    local_nonpersistent_flags+=("--run-post-install")
    flags+=("--skip-post-install")
    local_nonpersistent_flags+=("--skip-post-install")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_list()
{
    last_command="arduino-cli_core_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--updatable")
    local_nonpersistent_flags+=("--updatable")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_search()
{
    last_command="arduino-cli_core_search"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_uninstall()
{
    last_command="arduino-cli_core_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_update-index()
{
    last_command="arduino-cli_core_update-index"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core_upgrade()
{
    last_command="arduino-cli_core_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--run-post-install")
    local_nonpersistent_flags+=("--run-post-install")
    flags+=("--skip-post-install")
    local_nonpersistent_flags+=("--skip-post-install")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_core()
{
    last_command="arduino-cli_core"

    command_aliases=()

    commands=()
    commands+=("download")
    commands+=("install")
    commands+=("list")
    commands+=("search")
    commands+=("uninstall")
    commands+=("update-index")
    commands+=("upgrade")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_daemon()
{
    last_command="arduino-cli_daemon"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--daemonize")
    local_nonpersistent_flags+=("--daemonize")
    flags+=("--port=")
    two_word_flags+=("--port")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_debug()
{
    last_command="arduino-cli_debug"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--info")
    flags+=("-I")
    local_nonpersistent_flags+=("--info")
    flags+=("--input-dir=")
    two_word_flags+=("--input-dir")
    local_nonpersistent_flags+=("--input-dir=")
    flags+=("--interpreter=")
    two_word_flags+=("--interpreter")
    local_nonpersistent_flags+=("--interpreter=")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--port=")
    flags+=("--programmer=")
    two_word_flags+=("--programmer")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--programmer=")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_help()
{
    last_command="arduino-cli_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_arduino-cli_lib_deps()
{
    last_command="arduino-cli_lib_deps"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_download()
{
    last_command="arduino-cli_lib_download"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_examples()
{
    last_command="arduino-cli_lib_examples"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_install()
{
    last_command="arduino-cli_lib_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--git-url")
    local_nonpersistent_flags+=("--git-url")
    flags+=("--no-deps")
    local_nonpersistent_flags+=("--no-deps")
    flags+=("--zip-path")
    local_nonpersistent_flags+=("--zip-path")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_list()
{
    last_command="arduino-cli_lib_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    local_nonpersistent_flags+=("--all")
    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--updatable")
    local_nonpersistent_flags+=("--updatable")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_search()
{
    last_command="arduino-cli_lib_search"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--names")
    local_nonpersistent_flags+=("--names")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_uninstall()
{
    last_command="arduino-cli_lib_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_update-index()
{
    last_command="arduino-cli_lib_update-index"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib_upgrade()
{
    last_command="arduino-cli_lib_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_lib()
{
    last_command="arduino-cli_lib"

    command_aliases=()

    commands=()
    commands+=("deps")
    commands+=("download")
    commands+=("examples")
    commands+=("install")
    commands+=("list")
    commands+=("search")
    commands+=("uninstall")
    commands+=("update-index")
    commands+=("upgrade")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_outdated()
{
    last_command="arduino-cli_outdated"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_sketch_archive()
{
    last_command="arduino-cli_sketch_archive"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--include-build-dir")
    local_nonpersistent_flags+=("--include-build-dir")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_sketch_new()
{
    last_command="arduino-cli_sketch_new"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_sketch()
{
    last_command="arduino-cli_sketch"

    command_aliases=()

    commands=()
    commands+=("archive")
    commands+=("new")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_update()
{
    last_command="arduino-cli_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--show-outdated")
    local_nonpersistent_flags+=("--show-outdated")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_upgrade()
{
    last_command="arduino-cli_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--run-post-install")
    local_nonpersistent_flags+=("--run-post-install")
    flags+=("--skip-post-install")
    local_nonpersistent_flags+=("--skip-post-install")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_upload()
{
    last_command="arduino-cli_upload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fqbn=")
    two_word_flags+=("--fqbn")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--fqbn=")
    flags+=("--input-dir=")
    two_word_flags+=("--input-dir")
    local_nonpersistent_flags+=("--input-dir=")
    flags+=("--input-file=")
    two_word_flags+=("--input-file")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input-file=")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--port=")
    flags+=("--programmer=")
    two_word_flags+=("--programmer")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--programmer=")
    flags+=("--verify")
    flags+=("-t")
    local_nonpersistent_flags+=("--verify")
    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_version()
{
    last_command="arduino-cli_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_arduino-cli_root_command()
{
    last_command="arduino-cli"

    command_aliases=()

    commands=()
    commands+=("board")
    commands+=("burn-bootloader")
    commands+=("cache")
    commands+=("compile")
    commands+=("completion")
    commands+=("config")
    commands+=("core")
    commands+=("daemon")
    commands+=("debug")
    commands+=("help")
    commands+=("lib")
    commands+=("outdated")
    commands+=("sketch")
    commands+=("update")
    commands+=("upgrade")
    commands+=("upload")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--additional-urls=")
    two_word_flags+=("--additional-urls")
    flags+=("--config-file=")
    two_word_flags+=("--config-file")
    flags+=("--format=")
    two_word_flags+=("--format")
    flags+=("--log-file=")
    two_word_flags+=("--log-file")
    flags+=("--log-format=")
    two_word_flags+=("--log-format")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--verbose")
    flags+=("-v")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_arduino-cli()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __arduino-cli_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("arduino-cli")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function
    local last_command
    local nouns=()

    __arduino-cli_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_arduino-cli arduino-cli
else
    complete -o default -o nospace -F __start_arduino-cli arduino-cli
fi

# ex: ts=4 sw=4 et filetype=sh
