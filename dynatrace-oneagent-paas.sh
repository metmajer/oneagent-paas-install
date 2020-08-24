#!/bin/sh
ME=$(basename "$0")

help() {
  EXIT_CODE=${1:-0}

  echo "The Dynatrace OneAgent for PaaS installer enables Dynatrace monitoring in environments\n\
where installing OneAgent for full-stack monitoring on cluster nodes is not an option.\n\
\n\
Usage:\n\
\n\
  ./$ME [flags]
\n\
Available Flags:\n\
\n\
  -h, --help: help for $ME\n\
\n\
Required Environment Variables:\n\
\n\
  DT_TENANT:    Your Dynatrace Tenant (Environment ID).\n\
  DT_API_TOKEN: Your Dynatrace API Token.\n\
\n\
Optional Environment Variables:\n\
\n\
  DT_CLUSTER_HOST:        The hostname to your Dynatrace cluster. Defaults to 'live.dynatrace.com'. Override if you are running a Dynatrace Managed cluster.\n\
  DT_ONEAGENT_PREFIX_DIR: The installation prefix location (to contain OneAgent in the 'dynatrace/oneagent' subdirectory). Defaults to '/var/lib'.\n\
\n\
  DT_ONEAGENT_BITNESS:    Can be one of (all|32|64). Defaults to '64'.\n\
  DT_ONEAGENT_FOR:        Can be any of (all|apache|java|nginx|nodejs|php|varnish|websphere) in a comma-separated list. Defaults to 'all'.\n\
  DT_ONEAGENT_APP:        The path to an application file. Currently only supported in combination with DT_ONEAGENT_FOR=nodejs.\n\
\n\
Examples:\n\
\n\
  General)\n\
\n\
  1. Installs OneAgent for all supported technologies into '/var/lib/dynatrace/oneagent':\n\
  DT_TENANT=abc DT_API_TOKEN=123 ./$ME\n\
\n\
  2. Loads OneAgent with a Java application in '/app/app.jar':\n\
  /var/lib/dynatrace/oneagent/dynatrace-agent64.sh java -jar /app/app.jar\n\
\n\
  You should always set DT_ONEAGENT_FOR to a particular technology to minimize download time and space.\n\
\n\
  NodeJS)\n\
\n\
  Installs OneAgent for the NodeJS technology and integrates it into the application in '/app/index.js':\n\
  DT_TENANT=abc DT_API_TOKEN=123 DT_ONEAGENT_FOR=nodejs DT_ONEAGENT_APP=/app/index.js ./$ME"

  exit $EXIT_CODE
}

build_api_url() {
  DT_CLUSTER_HOST="$1"
  DT_TENANT="$2"

  DT_API_URL="https://"
  if is_dynatrace_saas_cluster_host "$DT_CLUSTER_HOST"; then
    DT_API_URL="${DT_API_URL}${DT_TENANT}.${DT_CLUSTER_HOST}/api"
  else
    DT_API_URL="${DT_API_URL}${DT_CLUSTER_HOST}/e/${DT_TENANT}/api"
  fi
}

build_oneagent_download_url() {
  DT_API_URL="$1"
  DT_API_TOKEN="$2"
  DT_ONEAGENT_BITNESS="$3"
  DT_ONEAGENT_FOR="$4"

  DT_ONEAGENT_URL="${DT_API_URL}/v1/deployment/installer/agent/unix/paas-sh/latest?Api-Token=${DT_API_TOKEN}&bitness=${DT_ONEAGENT_BITNESS}"

  DT_ONEAGENT_FOR_SEP=,
  if validate_contains "$DT_ONEAGENT_FOR" "$DT_ONEAGENT_FOR_SEP"; then
    IFS="$DT_ONEAGENT_FOR_SEP"
    for technology in $DT_ONEAGENT_FOR; do
      DT_ONEAGENT_URL="$DT_ONEAGENT_URL&include=$technology"
    done
  else
    DT_ONEAGENT_URL="$DT_ONEAGENT_URL&include=$DT_ONEAGENT_FOR"
  fi
}

die() {
  echo >&2 "${ME}: $@"
  exit 1
}

download_oneagent() {
  URL="$1"
  FILE="$2"

  echo "Connecting to $URL"

  ERROR=""
  if validate_command_exists wget; then
    ERROR=`wget -nv -O "${FILE}" "${URL}" 2>&1`
  elif validate_command_exists curl; then
    ERROR=`curl -fsSL -o "${FILE}" "${URL}" 2>&1`
  else
    die "failed to download Dynatrace OneAgent: neither curl nor wget are available"
  fi

  if [ $? -ne 0 ]; then
    rm -f "${FILE}"
    die "${ERROR}"
  fi
}

install_oneagent() {
  URL="$1"
  FILE="/tmp/dynatrace-oneagent.sh"
  PREFIX_DIR="$2"

  download_oneagent "${URL}" "${FILE}"
  sh "${FILE}" "${PREFIX_DIR}"
  rm -f "${FILE}"
}

integrate_oneagent_nodejs() {
  NODE_APP="$1"
  NODE_AGENT="try { require('$DT_ONEAGENT_PREFIX_DIR/dynatrace/oneagent/agent/bin/any/onenodeloader.js') ({ server: '$DT_CLUSTER_HOST', apitoken: '$DT_API_TOKEN' }); } catch(err) { console.log(err.toString()); }"

  if [ -f "$NODE_APP" ]; then
    # Backup the user's application.
    cp "$NODE_APP" "$NODE_APP.bak"
    # Prepend the node agent to the user's application.
    echo "$NODE_AGENT\n\n$(cat $NODE_APP)" > "$NODE_APP"
  else
    die "failed to install Dynatrace OneAgent: could not find $NODE_APP"
  fi
}

is_dynatrace_saas_cluster_host() {
  echo "$1" | grep -qE "live.dynatrace.com" >/dev/null 2>&1
}

validate_api_token() {
  echo "$1" | grep -qE "^[[:alnum:]_-]+$" >/dev/null 2>&1
}

validate_bitness() {
  echo "$1" | grep -qE "^(all|32|64)$" >/dev/null 2>&1
}

validate_command_exists() {
  "$@" > /dev/null 2>&1
  if [ $? -eq 127 ]; then
    return 1
  fi
  return 0
}

validate_contains() {
  echo "$1" | grep -qE "$2" >/dev/null 2>&1
}

validate_host() {
  echo "$1" | grep -qE "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$" >/dev/null 2>&1
}

validate_prefix_dir() {
  echo "$1" | grep -qE "^(/[[:alnum:]]+)+/?$" >/dev/null 2>&1
}

validate_technology() {
  REGEX_TECH_GROUP="(all|apache|java|nginx|nodejs|php|varnish|websphere)"
  echo "$1" | grep -qiE "^($REGEX_TECH_GROUP,)*$REGEX_TECH_GROUP$" >/dev/null 2>&1
}

validate_tenant() {
  echo "$1" | grep -qE "^[[:alnum:]_-]{8,}$" >/dev/null 2>&1
}

# Validate arguments.
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  help
fi

if [ -z "${DT_API_URL+x}" -a -z "${DT_TENANT+x}" ] || [ -z "${DT_API_TOKEN+x}" ]; then
  help 1
fi

if [ ! -z "${DT_CLUSTER_HOST+x}" ]; then
  validate_host "$DT_CLUSTER_HOST" || die "failed to validate DT_CLUSTER_HOST: $DT_CLUSTER_HOST"
fi

if [ ! -z "${DT_TENANT+x}" ]; then
  validate_tenant "$DT_TENANT" || die "failed to validate DT_TENANT: $DT_TENANT"
fi

if [ ! -z "${DT_API_TOKEN+x}" ]; then
  validate_api_token "$DT_API_TOKEN" || die "failed to validate DT_API_TOKEN: $DT_API_TOKEN"
fi

DT_CLUSTER_HOST="${DT_CLUSTER_HOST:-live.dynatrace.com}"
DT_ONEAGENT_BITNESS="${DT_ONEAGENT_BITNESS:-64}"
DT_ONEAGENT_FOR="${DT_ONEAGENT_FOR:-all}"
DT_ONEAGENT_PREFIX_DIR="${DT_ONEAGENT_PREFIX_DIR:-/var/lib}"
DT_API_URL="${DT_API_URL}"

validate_bitness    "$DT_ONEAGENT_BITNESS"    || die "failed to validate DT_ONEAGENT_BITNESS: $DT_ONEAGENT_BITNESS"
validate_prefix_dir "$DT_ONEAGENT_PREFIX_DIR" || die "failed to validate DT_ONEAGENT_PREFIX_DIR: $DT_ONEAGENT_PREFIX_DIR"
validate_technology "$DT_ONEAGENT_FOR"        || die "failed to validate DT_ONEAGENT_FOR: $DT_ONEAGENT_FOR"

# Build Dynatrace API URL.
if [ -z "$DT_API_URL" ]; then
  build_api_url "$DT_CLUSTER_HOST" "$DT_TENANT"
fi

# Build Dynatrace OneAgent download URL.
build_oneagent_download_url "$DT_API_URL" "$DT_API_TOKEN" "$DT_ONEAGENT_BITNESS" "$DT_ONEAGENT_FOR"

# Download and install Dynatrace OneAgent.
install_oneagent "$DT_ONEAGENT_URL" "$DT_ONEAGENT_PREFIX_DIR"

if [ "$DT_ONEAGENT_FOR" = "nodejs" ]; then
  integrate_oneagent_nodejs "$DT_ONEAGENT_APP"
fi
