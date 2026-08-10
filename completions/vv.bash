_vv_complete() {
  local word=${COMP_WORDS[COMP_CWORD]}
  if [[ $word == -* ]]; then
    COMPREPLY=( $(compgen -W '-h --help --verified-version --version' -- "$word") )
  else
    COMPREPLY=( $(compgen -c -- "$word") )
  fi
}
complete -F _vv_complete vv
