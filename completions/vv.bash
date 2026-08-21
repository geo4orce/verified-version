_vv_complete() {
  local word=${COMP_WORDS[COMP_CWORD]}
  local candidate
  COMPREPLY=()
  if [[ $word == -* ]]; then
    while IFS= read -r candidate; do
      COMPREPLY+=("$candidate")
    done < <(compgen -W '-h --help --verified-version --version --quarantine' -- "$word")
  else
    while IFS= read -r candidate; do
      COMPREPLY+=("$candidate")
    done < <(compgen -c -- "$word")
  fi
}
complete -F _vv_complete vv
