_awsconf() {
  profiles=$((unset AWS_DEFAULT_PROFILE && \
    COMMAND_LINE="configure --profile" aws_completer) \
    | grep -v _path)

  COMPREPLY=()   # Array variable storing the possible completions.

  cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=( $( compgen -W "$(echo $profiles)" -- $cur ) )

  return 0
}
complete -F _awsconf awsconf
