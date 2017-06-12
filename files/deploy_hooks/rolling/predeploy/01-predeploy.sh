#!/usr/bin/env bash
#
# apps::files::deploy_hooks::rolling::pre_deploy.sh
#
# author: lsmith
# date: 2015-10-16
#
# shared predeploy script for rolling deploy style
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
  logger -t "deploy" "${MESSAGE}"
  [ -z "${EXITCODE}" ] || exit "${EXITCODE}"
}

set_nginx_pid() {
  # set nginx pid if nignx is running
  #
  service nginx status > /dev/null 2>&1
  if [ $? -eq 0 ] || [ -f /var/run/nginx.pid ]; then
    NGINXPID=$( cat /var/run/nginx.pid | tee /tmp/deploy-stopped-nginx.pid )
    log "found nginx running with pid: ${NGINXPID}"
  fi

  return 0
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
      INCSLEEP=$(( $TRY * 3 ))
      log "${APPNAME} healthcheck ${ACTION} returned ${RESP}. Sleeping ${INCSLEEP} before retry"
      sleep "${INCSLEEP}"
      mod_health "${APPNAME}" "$HEALTHCHECKURL" "${ACTION}"
      if [ "${TRY}" -eq 99 ]; then return 0; fi
    fi
  done

  log "failed: ${APPNAME} healthcheck ${ACTION} returned ${RESP} after 3 retries; exit 10" 10
}

# nginx stop drain
drain_nginx() {
  # expects NGINXPID 
  # returns 0 on success
  # exits 20-29 err code on failure
  #
  if [ -n "${NGINXPID}" ]; then
    log "gracefully stopping nginx with pid: ${NGINXPID}"
    kill -QUIT "${NGINXPID}"
    if [ $? -eq 0 ]; then
      return 0
    else
      log "failed to gracefully stop nginx $( service nginx status ); exit 20"
      exit 20
    fi
  fi
}

set_supervisor_procs() {
  # expect $APPNAME
  # sets $SUPERVISORPROCS
  # 
  SUPERVISORPROCS=$( supervisorctl status | grep "${APPNAME}" | awk '{print $1}' )
  if [ $? -eq 0 ]; then
    log "found supervisor processes: ${SUPERVISORPROCS}"
    return 0
  else
    log "failed to find supervisor processes: $SUPERVISORPROCS"
  fi
}

supervisor_proc_handler() {
  # expects $APPNAME, $ACTION, global $SUPERVISORPROCS
  # returns 0 on success
  # exits 31-33 on failure
  #
  local APPNAME=$1
  local ACTION=$2
  local NUMPROCS=$( echo $SUPERVISORPROCS | wc -w )
  if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "restart" ] && [ -z "${SUPERVISORPROCS}" ]; then
    log "no existing supervisor processes found for ${APPNAME}.  Executing a reload."
    supervisorctl reload || log "Failed to reload supervisor for ${APPNAME}; exit 31" 31
  elif [ "${ACTION}" == "reload" ]; then
    log "realoding supervisor"
    supervisorctl "${ACTION}" || log "failed to reload supervisor; exit 32" 32
  else
    i=0
    for PROC in $( echo "${SUPERVISORPROCS}" | sed -e 's/\n//g' ); do
      log "executing supervisorctl ${ACTION} ${PROC}"
      supervisorctl "${ACTION}" "${PROC}" || log "failed to supervisor ${ACTION} ${PROC}; exit 33" 33
      if [ $i -lt $(( $NUMPROCS - 1 )) ]; then
        log "sleeping ${SLEEP}"
        sleep "${SLEEP}"
      fi
      (( i++ ))
    done
  fi

  return 0
}

main() {
  if [ -n "${HEALTHCHECKURL}" ]; then
    TRY=0
    mod_health "${APPNAME}" "${HEALTHCHECKURL}" "disable"
  fi
  set_nginx_pid
  drain_nginx
  set_supervisor_procs "${APPNAME}"
  supervisor_proc_handler "${APPNAME}" "stop"
}

# ---------- #
# procedural #
# ---------- #

# parse params
while [ $# -gt 0 ]; do

  case "$1" in
    "-a" | "--application" )
      APPNAME="$2"
      shift 2
      ;;
    "-h" | "--healthcheck-url" )
      HEALTHCHECKURL="$2"
      shift 2
      ;;
    "-r" | "--restart" )
      RS="$2"
      shift 2
      ;;
    *)
      echo "something is horribly wrong" && exit 1
      ;;
  esac

done

main
