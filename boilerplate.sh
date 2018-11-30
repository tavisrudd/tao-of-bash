set -o pipefail
set -o errexit

## don't use nounset if you want to get stacktraces
#set -o nounset

## enable nice stack tracing on errors
trap 'errexit' ERR
set -o errtrace

echo_bash_source_line() {
  local offset
  offset="${1-0}"
  local corrected_offset
  corrected_offset="$((offset + 1))"
  sed -n "${BASH_LINENO[$corrected_offset]}p" < "${BASH_SOURCE[$corrected_offset+1]}"
}

errexit() {
  set +o xtrace
  local code
  code="${1:-1}"
  echo -e "\e[31mError in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $code\e[0m"

  if ((${#FUNCNAME[@]} > 2)); then
    echo -ne "\e[33m"           # yellow
    echo "Call tree:"
    echo " 0: ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
    echo -n '    - '
    echo_bash_source_line 0
    for ((i=1;i<${#FUNCNAME[@]}-1;i++)); do
      echo " $i: ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
      echo -n '    - '
      echo_bash_source_line "$i"
    done
  fi
  echo -ne "\e[0m"
  echo -e "\e[31mExiting with status ${code}\e[0m"
  exit "${code}"
}

exitcode_colored() {
  local rc
  rc="$1"
  if ((rc > 0)); then
    echo -ne "\\e[41m^ err $rc\\e[0m"
  fi
}

export PS4='+\e[0;33m ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}()$(exitcode_colored $?): }\e[0m'
configure_xtrace() {
  if [[ -n "$XTRACE" ]]; then
    set -o xtrace
  fi
}
configure_xtrace
