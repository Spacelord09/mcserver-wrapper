#!/bin/bash
################ SETUP ################
exec_path=$(echo $PWD)
source "$exec_path"/mcctl.conf
################ SETUP ################
cd $exec_path
trap exit_msg SIGINT SIGTERM SIGKILL

LOG () {        # Use case to switch between info / error. Usage: LOG "info" "TEXT"
    TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
    case "$1" in
      info)    # INFO
        printf "\n$TIMESTAMP [INFO] $2" >> $LOGFILE_WATCH
        printf "\n[INFO] $2"
      ;;
      warn)    # WARN
        printf "\n$TIMESTAMP [WARN] $2" >> $LOGFILE_WATCH
        printf "\n[WARN] $2"
      ;;
      error)    # ERROR
        printf "\n$TIMESTAMP [ERROR] $2" >> $LOGFILE_WATCH
        printf "\n[ERROR] $2"
      ;;
      newline)
        printf "\n\n" >> $LOGFILE_WATCH
      ;;
      *)    # Unknown
        printf "\n$TIMESTAMP [?] $2" >> $LOGFILE_WATCH
        printf "\n[?]  $2"
        LOG "error" "log -$1- not found! Please report to the script maintainer!"
      ;;
    esac
    printf "\n"
}

exit_msg () {
  LOG "warn" "Watchdog is stopping!"
  exit 0
}
LOG "newline"
LOG "info" "Watchdog is starting."
## Checks if the screen session exists. If not automatically restart the service!
while true
do
        printf "\nLooking for Screen Session $server_session."
        if ! screen -list | grep -q "$server_session"; then
            LOG "warn" "Session exited. Restarting."
#	    $exec_path/$main_script "start"
            sleep 16s
	else
        LOG "info" "$server_session still alive."
        fi
	sleep $watch_timeout
done
