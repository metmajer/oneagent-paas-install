#!/bin/sh -e
die() {
  echo >&2 "${ME}: $@"
  exit 1
}

delete_file() {
  rm -f "$1"
}

download_file() {
  URL="$1"
  FILE="$2"

  # Test which of the following commands is available.
  cmd=
  if validate_command_exists curl; then
    cmd='curl -sSL'
  elif validate_command_exists wget; then
    cmd='wget -qO-'
  else
    die "failed to download Dynatrace OneAgent for PaaS installer: neither curl nor wget are available"
  fi

  echo "Downloading Dynatrace OneAgent for PaaS installer from $URL"
  $cmd "${URL}" > ${FILE}
}

execute_file() {
  sh "$1"
}

validate_command_exists() {
  "$@" > /dev/null 2>&1
  if [ $? -eq 127 ]; then
    return 1
  fi
  return 0
}

ONEAGENT_INSTALL_SH_URL="https://raw.githubusercontent.com/dynatrace-innovationlab/oneagent-paas-install/master/dynatrace-oneagent-paas.sh"
ONEAGENT_INSTALL_SH_FILE=`basename "$ONEAGENT_INSTALL_SH_URL"`

download_file "$ONEAGENT_INSTALL_SH_URL" "$ONEAGENT_INSTALL_SH_FILE"
execute_file  "$ONEAGENT_INSTALL_SH_FILE"
delete_file   "$ONEAGENT_INSTALL_SH_FILE"