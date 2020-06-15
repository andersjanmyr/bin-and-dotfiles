_awsconf() {
  profiles=$(cat ~/.aws/config \
  |grep '^\[profile' |tr -d '[]' | awk '{print $2}')

  COMPREPLY=()   # Array variable storing the possible completions.

  cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=( $( compgen -W "$(echo $profiles)" -- $cur ) )

  return 0
}
complete -F _awsconf awsconf
