#!/bin/bash

printf "\nWORK IN PROGRESS\nDO NOT RUN\n\n"
exit 0

################################################ SETUP ################################################
deps=(jq git whiptail wget curl screen)
user=$(whoami)                  # for bypassing user check replace "$(whoami)" with "root".


# config file vars..


bold=$(tput bold)
normal=$(tput sgr0)

################################################ SETUP ################################################

############################################## FUNCTIONS ##############################################

INSTALL-DEPS () {           # Install deps from array "$deps"
	for t in ${deps[@]}; do
	    if [ $(dpkg-query -W -f='${Status}' $t 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
	        printf "Installing %s\n" "$t"
	        apt-get install $t;
	        printf "Done\n";
	    else
	        printf "%s already installed!\n" "$t"
	    fi
	done
	printf "\n"
}

DOWNLOAD-PAPER () {
    server_version=$(curl --silent https://papermc.io/api/v1/paper  | jq '.versions | map(., "") |. []' | xargs whiptail --title "Select your server version" --noitem --menu "choose" 16 78 10 3>&1 1>&2 2>&3)
    latest_version_tag=$(curl --silent https://papermc.io/api/v1/paper/$server_version | grep -Po '"'"latest"'"\s*:\s*"\K([^"]*)')
    echo "$latest_version_tag"
    wget --progress=dot --content-disposition "https://papermc.io/api/v1/paper/$server_version/latest/download" 2>&1 | sed -u '1,/^$/d;s/.* \([0-9]\+\)% .*/\1/' | whiptail --gauge "Downloading Paper-$latest_version_tag.jar" 7 50 0
}





ERROR () {
	printf "\nAborting...\n"
	CLEAN
	printf "Exiting...\n"
	exit 1
}

DONE () {
	printf "\nDone.\n"
	CLEAN
	exit 0
}

CLEAN () {
	printf "\nCleaning...\n"
	rm -rf $tmp_path
}

############################################## FUNCTIONS ##############################################

################################################ Main #################################################
trap ERROR SIGINT SIGTERM SIGKILL
clear
