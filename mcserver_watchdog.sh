#!/bin/bash


loop_timeout="4s"
startup_timeout="8s"
exec_path="/home/iamroot/bin/minecraft_server"
main_file="/mcserver.sh"
watch_session="mcserver"

## Check if screen session exists. If not restart the service!
while true
do
        printf "\nLooking for Screen Session $watch_session."
        if ! screen -list | grep -q "$watch_session"; then
            printf "\nSession exited. restarting.."
	    $exec_path/$main_file "start"
            sleep $startup_timeout
	else
        printf "\n$watch_session is running."
        fi
	sleep $loop_timeout
done


# config file mit source importieren?
