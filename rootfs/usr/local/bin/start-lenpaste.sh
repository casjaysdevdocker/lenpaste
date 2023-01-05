#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202301051018-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  WTFPL
# @@ReadME           :  start-lenpaste.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Thursday, Jan 05, 2023 10:18 EST
# @@File             :  start-lenpaste.sh
# @@Description      :  script to start lenpaste
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set trap
trap -- 'retVal=$?;kill -9 $$;exit $retVal' SIGINT SIGTERM ERR EXIT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__cd() { [ -d "$1" ] && builtin cd "$1" || return 1; }
__curl() { curl -q -LSsf -o /dev/null "$@" &>/dev/null || return 10; }
__find() { find "$1" -mindepth 1 -type ${2:-f,d} 2>/dev/null | grep '^' || return 10; }
__pcheck() { [ -n "$(which pgrep 2>/dev/null)" ] && pgrep -x "$1" &>/dev/null || return 10; }
__pgrep() { __pcheck "$1" || ps aux 2>/dev/null | grep -Fw " $1" | grep -qv ' grep' || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__certbot() {
  [ -n "$DOMAINNAME" ] && [ -n "$CERT_BOT_MAIL" ] || { echo "The variables DOMAINNAME and CERT_BOT_MAIL are set" && exit 1; }
  [ "$SSL_CERT_BOT" = "true" ] && type -P certbot &>/dev/null || { export SSL_CERT_BOT="" && return 10; }
  certbot $1 --agree-tos -m $CERT_BOT_MAIL certonly --webroot -w "${WWW_ROOT_DIR:-/data/htdocs/www}" -d $DOMAINNAME -d $DOMAINNAME \
    --put-all-related-files-into "$SSL_DIR" -key-path "$SSL_KEY" -fullchain-path "$SSL_CERT"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__heath_check() {
  local healthStatus=0 health="Good"
  __pgrep ${1:-lenpaste} &>/dev/null || healthStatus=$((healthStatus + 1))
  #__curl "http://localhost:$SERVICE_PORT/server-health" || healthStatus=$((healthStatus + 1))
  [ "$healthStatus" -eq 0 ] || health="Errors reported see docker logs --follow $CONTAINER_NAME"
  return ${healthStatus:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_command() {
  local exitCode=0
  local cmd="${*:-bash -l}"
  echo "Executing: $cmd"
  $cmd || exitCode=1
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_pre_start() {
  true
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_service_start() {
  local exitCode=0
  local cmd="${*:-false}"
  echo "Setting up service to run as $SERVICE_USER"
  echo "Executing: $cmd "
  if [ "$SERVICE_USER" = "root" ]; then
    $cmd || exitCode=1
  elif [ "$(builtin type -P su)" ]; then
    su_cmd() { su -s /bin/sh - $SERVICE_USER -c "$@" || return 1; }
  elif [ "$(builtin type -P runuser)" ]; then
    su_cmd() { runuser -u $SERVICE_USER "$@" || return 1; }
  elif [ "$(builtin type -P sudo)" ]; then
    su_cmd() { sudo -u $SERVICE_USER "$@" || return 1; }
  else
    echo "Can not switch to $SERVICE_USER"
    exit 10
  fi
  su_cmd "$cmd" || exitCode=1
  su_cmd "touch /tmp/$SERVICE_NAME.pid"
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__start_message() {
  if [ "$ENTRYPOINT_MESSAGE" = "false" ]; then
    echo "Starting $SERVICE_NAME on port: $SERVICE_PORT"
  else
    echo "Starting $SERVICE_NAME on: $CONTAINER_IP_ADDRESS:$SERVICE_PORT"
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
DISPLAY="${DISPLAY:-}"
LANG="${LANG:-C.UTF-8}"
DOMAINNAME="${DOMAINNAME:-}"
TZ="${TZ:-America/New_York}"
PORT="${SERVICE_PORT:-$PORT}"
HOSTNAME="${HOSTNAME:-casjaysdev-lenpaste}"
HOSTADMIN="${HOSTADMIN:-root@${DOMAINNAME:-$HOSTNAME}}"
SSL_CERT_BOT="${SSL_CERT_BOT:-false}"
SSL_ENABLED="${SSL_ENABLED:-false}"
SSL_DIR="${SSL_DIR:-/config/ssl}"
SSL_CA="${SSL_CA:-$SSL_DIR/ca.crt}"
SSL_KEY="${SSL_KEY:-$SSL_DIR/server.key}"
SSL_CERT="${SSL_CERT:-$SSL_DIR/server.crt}"
SSL_CONTAINER_DIR="${SSL_CONTAINER_DIR:-/etc/ssl/CA}"
WWW_ROOT_DIR="${WWW_ROOT_DIR:-/data/htdocs}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
DATA_DIR_INITIALIZED="${DATA_DIR_INITIALIZED:-}"
CONFIG_DIR_INITIALIZED="${CONFIG_DIR_INITIALIZED:-}"
DEFAULT_DATA_DIR="${DEFAULT_DATA_DIR:-/usr/local/share/template-files/data}"
DEFAULT_CONF_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/config}"
DEFAULT_TEMPLATE_DIR="${DEFAULT_TEMPLATE_DIR:-/usr/local/share/template-files/defaults}"
CONTAINER_IP_ADDRESS="$(ip a 2>/dev/null | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's|/.*||g')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom variables
LENPASTE_ADDRESS="${LENPASTE_ADDRESS:-80}"
LENPASTE_ADMIN_NAME="${LENPASTE_ADMIN_NAME:-PasteIT}"
LENPASTE_ADMIN_MAIL="${LENPASTE_ADMIN_MAIL:-paste-admin@casjay.net}"
LENPASTE_DB_DRIVER="${LENPASTE_DB_DRIVER:-sqlite3}"
LENPASTE_ROBOTS_DISALLOW="${LENPASTE_ROBOTS_DISALLOW:-false}"
LENPASTE_BODY_MAX_LENGTH="${LENPASTE_BODY_MAX_LENGTH:-99999}"
LENPASTE_TITLE_MAX_LENGTH="${LENPASTE_TITLE_MAX_LENGTH:-100}"
LENPASTE_DB_CLEANUP_PERIOD="${LENPASTE_DB_CLEANUP_PERIOD:-3h}"
LENPASTE_NEW_PASTES_PER_5MIN="${LENPASTE_NEW_PASTES_PER_5MIN:-}"
LENPASTE_MAX_PASTE_LIFETIME="${LENPASTE_MAX_PASTE_LIFETIME:-never}"
LENPASTE_UI_DEFAULT_LIFETIME="${LENPASTE_UI_DEFAULT_LIFETIME:-never}"
DB_USER="${DB_USER:-}"
DB_PASS="${DB_PASS:-}"
DB_HOST="${DB_HOST:-}"
DB_URI="${DB_URI:-}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite variables
WORKDIR=""
SERVICE_PORT="$PORT"
SERVICE_NAME="lenpaste"
SERVICE_USER="${SERVICE_USER:-root}"
SERVICE_COMMAND="$SERVICE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$SERVICE_PORT" = "443" ] && SSL_ENABLED="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Pre copy commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if this is a new container
[ -z "$DATA_DIR_INITIALIZED" ] && [ -f "/data/.docker_has_run" ] && DATA_DIR_INITIALIZED="true"
[ -z "$CONFIG_DIR_INITIALIZED" ] && [ -f "/config/.docker_has_run" ] && CONFIG_DIR_INITIALIZED="true"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create default config
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_TEMPLATE_DIR" ]; then
  [ -d "/config" ] && cp -Rf "$DEFAULT_TEMPLATE_DIR/." "/config/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom config files
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_CONF_DIR" ]; then
  [ -d "/config" ] && cp -Rf "$DEFAULT_CONF_DIR/." "/config/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom data files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -n "$DEFAULT_DATA_DIR" ]; then
  [ -d "/data" ] && cp -Rf "$DEFAULT_DATA_DIR/." "/data/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy html files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -d "$DEFAULT_DATA_DIR/data/htdocs" ]; then
  [ -d "/data" ] && cp -Rf "$DEFAULT_DATA_DIR/data/htdocs/." "$WWW_ROOT_DIR/" 2>/dev/null
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Post copy commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialized
[ -d "/data" ] && touch "/data/.docker_has_run"
[ -d "/config" ] && touch "/config/.docker_has_run"
[ -d "/config/db" ] || mkdir -p "/config/db"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# APP Variables overrides
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && . "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Actions based on env
SERVICE_OPTIONS=""
[ -s "/config/lenpasswd" ] && SERVICE_OPTIONS+="-lenpasswd-le /config/lenpasswd "
[ -s "/config/html/about" ] && SERVICE_OPTIONS+="-server-about /config/html/about "
[ -s "/config/html/rules" ] && SERVICE_OPTIONS+="-server-rules /config/html/rules "
[ -s "/config/html/terms" ] && SERVICE_OPTIONS+="-server-terms /config/html/terms "
[ -z "$LENPASTE_ROBOTS_DISALLOW" ] && SERVICE_OPTIONS+="-robots-disallow "
[ -n "$LENPASTE_ADDRESS" ] && SERVICE_OPTIONS+="-address $LENPASTE_ADDRESS "
[ -n "$LENPASTE_DB_DRIVER" ] && SERVICE_OPTIONS+="-db-driver $LENPASTE_DB_DRIVER "
[ -n "$LENPASTE_ADMIN_NAME" ] && SERVICE_OPTIONS+="-admin-name $LENPASTE_ADMIN_NAME "
[ -n "$LENPASTE_ADMIN_MAIL" ] && SERVICE_OPTIONS+="-admin-mail $LENPASTE_ADMIN_MAIL "
[ -n "$LENPASTE_BODY_MAX_LENGTH" ] && SERVICE_OPTIONS+="-body-max-length $LENPASTE_BODY_MAX_LENGTH "
[ -n "$LENPASTE_TITLE_MAX_LENGTH" ] && SERVICE_OPTIONS+="-title-max-length $LENPASTE_TITLE_MAX_LENGTH "
[ -n "$LENPASTE_DB_CLEANUP_PERIOD" ] && SERVICE_OPTIONS+="-db-cleanup-period $LENPASTE_DB_CLEANUP_PERIOD "
[ -n "$LENPASTE_MAX_PASTE_LIFETIME" ] && SERVICE_OPTIONS+="-max-paste-lifetime $LENPASTE_MAX_PASTE_LIFETIME "
[ -n "$LENPASTE_NEW_PASTES_PER_5MIN" ] && SERVICE_OPTIONS+="-new-pastes-per-5min $LENPASTE_NEW_PASTES_PER_5MIN "
[ -n "$LENPASTE_UI_DEFAULT_LIFETIME" ] && SERVICE_OPTIONS+="-ui-default-lifetime $LENPASTE_UI_DEFAULT_LIFETIME "
if [ "$LENPASTE_DB_DRIVER" = "postgres" ]; then
  LENPASTE_DB_SOURCE="-db-source postgres://$DB_USER:$DB_PASS@$DB_HOST/$DB_URI?sslmode=disable"
else
  LENPASTE_DB_SOURCE="-db-source /config/db/lenpaste.db"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Change to working dir
[ -n "$WORKDIR" ] && __cd "$WORKDIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# begin main app
case "$1" in
healthcheck)
  shift 1
  __heath_check "${SERVICE_NAME:-bash}"
  exit $?
  ;;

certbot)
  shift 1
  SSL_CERT_BOT="true"
  if [ "$1" = "create" ]; then
    shift 1
    __certbot
  elif [ "$1" = "renew" ]; then
    shift 1
    __certbot "renew certonly --force-renew"
  else
    __exec_command "certbot" "$@"
  fi
  ;;

*)
  if __pgrep "$SERVICE_NAME" && [ -f "/tmp/$SERVICE_NAME.pid" ]; then
    echo "$SERVICE_NAME is running"
  else
    __start_message
    __exec_pre_start
    __exec_service_start "$SERVICE_COMMAND" "$SERVICE_OPTIONS" $LENPASTE_DB_SOURCE || rm -Rf "/tmp/$SERVICE_NAME.pid"
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set exit code
exitCode="${exitCode:-$?}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
# ex: ts=2 sw=2 et filetype=sh
