#!/bin/bash
################ SETUP ################
exec_path=$(echo $PWD)
source "$exec_path"/mcctl.conf
################ SETUP ################
cd $exec_path

LOG () {        # Use case to switch between info / error. Usage: LOG "info" "TEXT"
#    find /var/log/ -name somefiles.log.* -ctime +3 -delete
    TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
    case "$1" in
      info)    # INFO
        printf "\n$TIMESTAMP [INFO] ["$log_exec"] $2" >> $LOGFILE
        printf "\n[INFO] $2"
      ;;
      warn)    # WARN
        printf "\n$TIMESTAMP [WARN] ["$log_exec"] $2" >> $LOGFILE
        printf "\n[WARN] $2"
      ;;
      error)    # ERROR
        printf "\n$TIMESTAMP [ERROR] ["$log_exec"] $2" >> $LOGFILE
        printf "\n[ERROR] $2"
      ;;
      *)    # Unknown
        printf "\n$TIMESTAMP [?] ["$log_exec"] $2" >> $LOGFILE
        printf "\n[?]  $2"
        LOG "error" "log -$1- not found! Please report to the script maintainer!"
      ;;
    esac
    printf "\n"
}

console() { # Passes commands to the console.
    if  screen -list | grep -q "$server_session"; then
        LOG "info" 'Sending ''"'"$*"'"'' to console.'
        screen -S "$server_session" -X stuff ''"$*\n"''
    else
        ERROR 2
    fi
}

console-check() {
if screen -list | grep -q "$server_session"; then  
    shift 1
    if [[ -n "$1" ]]; then console "$@"; else
        screen -r $screen_session
        LOG "info" "User $(whoami) opened the server console."
    fi
else
    ERROR 2
fi

}

start() {
    if ! screen -list | grep -q "$server_session"; then
        screen -AmdS $server_session $start_cmd
        sleep 4s
        watchdog start
    else
        ERROR 1
    fi
}

stop() {
    if screen -list | grep -q "$server_session"; then
        watchdog stop
        all_timeout=$(expr "$1" + "10")
        console 'save-all'  # Save worlds.
        sleep "1s"
        console 'title @a actionbar {"text":"Server shutdown in '$all_timeout's!","color":"dark_red"}'
        sleep "0.2s"
        sleep ""$1"s"

        for i in {10..1}
        do
         console 'title @a actionbar {"text":"Server shutdown in '$i's","color":"gold"}'
         sleep 1s
        done

        sleep 0.5s
        console 'title @a actionbar {"text":"Shutdown NOW!","color":"dark_red"}'
        console 'stop'
    else
        ERROR 2
    fi
}

restart() {
    if screen -list | grep -q "$server_session"; then
        watchdog stop
	      all_timeout=$(expr "$1" + "10")
        console 'save-all'  # Save worlds.
        sleep "1s"
        console 'title @a actionbar {"text":"Server Restart in '$all_timeout's!","color":"dark_red"}'
        sleep "0.2s"
        sleep ""$1"s"

        for i in {10..1}
        do
         console 'title @a actionbar {"text":"Server Restart in '$i's","color":"gold"}'
         sleep 1s
        done

        sleep 0.5s
        console 'title @a actionbar {"text":"Restart NOW!","color":"dark_red"}'
	      sleep 0.2s
        console 'stop'
        sleep 4s
        watchdog start
    else
        ERROR 2
    fi
}

killp() {
    if screen -list | grep -q "$server_session"; then
        watchdog stop
        screen -X -S $server_session kill
    else
        ERROR 2
    fi
}

# Watchdog script handler.
watchdog() {
    case "$1" in
      start)
      if ! screen -list | grep -q "$screen_watch_session"; then
        LOG "info" "Starting Watchdog.."
        screen -AmdS "$screen_watch_session" "./$watch_file"
      else
        ERROR 3
      fi
      ;;
      stop)
      if screen -list | grep -q "$screen_watch_session"; then
        LOG "info" "Stopping Watchdog.."
        screen -X -S "$screen_watch_session" stuff "^C"
      else
        ERROR 4
      fi
      ;;
      kill)
      if screen -list | grep -q "$screen_watch_session"; then
        LOG "warn" "Killing Watchdog.."
        screen -X -S "$screen_watch_session" kill
      else
        ERROR 4
      fi
      ;;
      *)
      echo "Usage: ${0} watchdog {start|stop|ḱill}"
    esac
}

ERROR() {
    printf "\n"
    case "$@" in
      1)    # Error code 1
        LOG "warn" 'Screen session('"$server_session"') allready started!'
      ;;
      2)    # Error code 2
        LOG "warn" 'Screen session('"$server_session"') is not running!'
      ;;
      3)    # Error code 2
        LOG "warn" 'Screen session('"$screen_watch_session"') allready started!'
      ;;
      4)    # Error code 2
        LOG "warn" 'Screen session('"$screen_watch_session"') is not running!'
      ;;
      *)    # Unknown error code
        LOG "error" 'Unknown error '"$@"'!'
      ;;
    esac
    printf "\n"
}


################################ MAIN ################################
log_exec=$(echo $1)
case $1 in
    console)
        console-check "$@"
    ;;
    start)
        start          # Starts the server.
    ;;
    stop)
        stop "$2"      # Stops the Server and the Watchdog!
    ;;
    restart)
        restart "$2"      # Restart the Server.
    ;;
    kill)
        killp         #  Kills the Server & Watchdog
    ;;
    watchdog)
        watchdog "$2"
    ;;
    *)
        echo "Usage: ${0} {start|stop <count+10s>|restart <count+10s>|kill|watchdog|console|console 'command'}"
    ;;
esac
exit 0
