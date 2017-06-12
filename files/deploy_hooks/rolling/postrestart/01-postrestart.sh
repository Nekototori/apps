#!/usr/bin/env bash
#
# apps::files::deploy_hooks::rolling:postdeploy:
#
# author: lsmith
# date: 2015-10-16
#
# shared shared postdeploy script for rolling deploy style
#
# params:
#  :application: (string) name of application being deploy
#  :healthcheck: (sting) uri of healtheck (optional)
#
IFS='
'

# 
# global vars
#
SUPERVISORPROCS=""
NGINXPID=""
TRY=0
SLEEP=5

# --------- #
# functions #
# --------- #
log() {
  # expects $MESSAGE
  # optional $EXITCODE
  #
  local MESSAGE="${1}"
  local EXITCODE="${2}"
  echo "deploy: $MESSAGE"
  logger -t "deploy" $MESSAGE
  [ -z "${EXITCODE}" ] || exit "${EXITCODE}"
}

mod_health() {
  # expects $APPNAME, $HEALTHCHECKURL, $ACTION, global $TRY
  # returns 0 on success
  # exits 10-19 on failure
  # 
  # makes a local http call to a to the healthcheck uri
  # with a action of DISBLE|ENABLE|STATUS
  #
  local APPNAME=$1 
  local HEALTHCHECKURL=$2
  local ACTION=$3
  local HOST=${HEALTHCHECKURL%%/*}
  local HCPATH=${HEALTHCHECKURL#*/}
  local RESP=""

  while [ "${TRY}" -lt 4 ]; do
    RESP=$(curl -is -w "\n" -H "Host: ${HOST}" "${HOSTNAME}/${HCPATH}/${ACTION}" | grep -i http )
    if echo "${RESP}" | grep 200; then
      log "${APPNAME} healthcheck ${ACTION} returned ${RESP}"
      TRY=99
      return 0
    else
      TRY=$(( $TRY + 1 ))
      INCSLEEP=$(( $TRY * 10 ))
      log "${APPNAME} healthcheck ${ACTION} returned ${RESP}. Sleeping ${INCSLEEP} before retry"
      sleep "${INCSLEEP}"
      mod_health "${APPNAME}" "$HEALTHCHECKURL" "${ACTION}"
      if [ "${TRY}" -eq 99 ]; then return 0; fi
    fi
  done

  log "failed: ${APPNAME} healthcheck ${ACTION} returned ${RESP} after 3 retries; exit 10" 10
}



main() {
  if [ -e /tmp/deploy-stopped-nginx.pid ]; then
    log "restarting starting nginx"
    service nginx start > /dev/null 2>&1 && rm -f /tmp/deploy-stopped-nginx.pid || log "failed to restart nginx; exit 1" 1
  fi
  if [ -n "${HEALTHCHECKURL}" ]; then
    TRY=0
    mod_health "${APPNAME}" "${HEALTHCHECKURL}" "enable"
  fi
}

# ---------- #
# procedural #
# ---------- #

# parse params
while [ $# -gt 0 ]; do

  case "$1" in
    "-v" | "--version" )
      VERSION="$2"
      shift 2
      ;;
    "-a" | "--application" )
      APPNAME="$2"
      shift 2
      ;;
    "-h" | "--healthcheck-url" )
      HEALTHCHECKURL="$2"
      shift 2
      ;;
    *)
      echo "something went horribley wrong" && exit 1
      ;;
  esac

done

main
