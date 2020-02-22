#!/bin/bash
################ SETUP ################
screen_session="mcserver"
screen_watch_session="watch_mc_server"

exec_path="/home/iamroot/bin/minecraft_server"

exec_file="paper-105.jar"
watchdog_file="$screen_session""_watchdog.sh"
log_file=""$exec_path"/$screen_session_"$date".log"

start_cmd="java -Xmx1024M -Xms256M -jar $exec_file nogui"
################ SETUP ################
cd $exec_path

console() { # Passes commands to the console.
    if  screen -list | grep -q "$screen_session"; then
        printf "\nSending "$@" to console..."
        screen -S mcserver -X stuff $"$@\n"       #WIP! &4 works?
        printf "[done.]\n"
    else
        ERROR 2
    fi
}

log-output() {
    printf "\n	\n"	# 	Send $@ to user.
    printf "\n	\n"	#	Send $@ to logfile.
}

console-check() {
if screen -list | grep -q "$screen_session"; then  
    if [[ -n "$1" ]]; then console "$1"; else screen -r $screen_session; fi
else
    ERROR 2
fi
}


start() {
    if ! screen -list | grep -q "$screen_session"; then
        screen -AmdS $screen_session $start_cmd
        sleep 4s
        watchdog start
    else
        ERROR 1
    fi
}

stop() {
    if screen -list | grep -q "$screen_session"; then
        watchdog stop
        stop_all_timeout=$(expr "$1" + "10")
        console 'save-all'  # Save worlds.
        console 'title @a actionbar {"text":"Server shutdown in '$stop_all_timeout's!","color":"dark_red"}'
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
oking for Screen Session mcserver.

}

restart() {
    if screen -list | grep -q "$screen_session"; then
        watchdog stop
	restart_all_timeout=$(expr "$1" + "10")
        console 'save-all'  # Save worlds.
        console 'title @a actionbar {"text":"Server Restart in '$restart_all_timeout's!","color":"dark_red"}'
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
    if screen -list | grep -q "$screen_session"; then
        watchdog stop
        screen -X -S $screen_session kill
    else
        ERROR 2
    fi
}

# Watchdog script handler. Cronjob @reboot ?!
watchdog() {
    case "$1" in
      start)
      if ! screen -list | grep -q "$screen_watch_session"; then
        printf "\nStarting Watchdog...\n"
        screen -AmdS "$screen_watch_session" $watchdog_file
	screen -AmdS watch_mc_server /home/iamroot/bin/minecraft_server/mcserver_watchdog.sh
      else
        ERROR 3
      fi
      ;;
      stop)
      if screen -list | grep -q "$screen_watch_session"; then
        printf "\nKilling Watchdog...\n"
        screen -X -S "$screen_watch_session" kill
      else
        ERROR 4
      fi
      ;;
      *)
      echo "Usage: ${0} watchdog {start|stop}"
    esac
}



ERROR() {
    printf "\n"
    case "$@" in
      1)    # Error code 1
        printf 'Screen session('"$screen_session"') allready running!'
      ;;
      2)    # Error code 2
        printf 'Screen session('"$screen_session"') is not running!'
      ;;
      3)    # Error code 2
        printf 'Screen session('"$screen_watch_session"') allready running!'
      ;;
      4)    # Error code 2
        printf 'Screen session('"$screen_watch_session"') is not running!'
      ;;
      *)    # Unknown error code
        printf 'Unknown error '"$@"'!'
      ;;
    esac
    printf "\n"
}


################################ MAIN ################################

case $1 in
    console)
        console-check "$2"
    ;;
    start)
        start     # Start the Server (Spins up the watchdog?) [WIP]
    ;;
    stop)
        stop "$2"      # Stops the Server and the Watchdog!
    ;;
    restart)
        restart "$2"      # Restart the Server. (Server is starting via watchdog script.) [Prob. add to script.]
    ;;
    kill)
        killp         #  Kills the Server & Watchdog
    ;;
    watchdog)
        watchdog "$2"
    ;;
    *)
        echo "Usage: ${0} {start|stop <count+10s>|restart <count+10s>|kill|watchdog|console|console '"CMD"'}"
    ;;
esac
exit 0

