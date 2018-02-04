#!/bin/bash
# Copyright (c) Jul. 2017, Cheng-Yueh Liu (cyliustack@gmail.com)

C_NONE="\033[0;00m"
C_CYAN="\033[1;36m"
C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_ORANGE="\033[1;33m"
C_BLUE="\033[1;34m"
C_PURPLE="\033[1;35m"
C_CYAN="\033[1;36m"
C_LIGHT_GRAY="\033[1;37m"
C_RED_BK="\033[1;41m"

function inform_sudo()
{
    [[ ! -z "$1" ]] && echo "$1"
    sudo -n true 2> /dev/null
    # Exit without printing messages if password is still in the cache.
    [[ $? == 0 ]] && return 0;
    sudo >&2 echo -e "\033[1;33mRunning with root privilege now...\033[0m";
    [[ $? != 0 ]] && >&2 echo -e "\033[1;31mAbort\033[0m" && exit 1;
}

function print_help()
{
    echo "This script help to set up permissions for running '/usr/sbin/tcpdump' in user mode for a specific user name."
    echo "Usage: $0 username..."
    echo "Examples: $0 $(whoami)"
    echo "          $0 first-user second-user third-user"
}

function set_tcpdump_group()
{
    inform_sudo "Running sudo for setting '/usr/sbin/tcpdump' with 'pcap' group."
    sudo chgrp pcap /usr/sbin/tcpdump
    [[ $? != 0 ]] && echo -e "${C_RED_BK}Failed... :(${C_NONE}" && exit 1
    sudo chmod 750 /usr/sbin/tcpdump
    sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
    [[ $? != 0 ]] && echo -e "${C_RED_BK}Failed... :(${C_NONE}" && exit 1
}

function main()
{
    if [[ "$*" == "" ]] || [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        print_help
        exit 0
    fi

    # Creating new group
    inform_sudo "Running sudo for creating 'pcap' group."
    sudo groupadd pcap

    # Change the group setting of tcpdump binary
    set_tcpdump_group

    # Adding groups for multiple users
    while [[ "$1" != "" ]]; do
        username=$1
        id -u "${username}" > /dev/null 2>/dev/null
        [[ $? != 0 ]] && echo -e "${C_RED_BK}User name - '$username' does not exist.${C_NONE}" && exit 1

        echo -e "${C_GREEN}Empower user - '$username' with Tcpdump${C_NONE}"

        inform_sudo "Running sudo for adding '$username' to 'pcap' group."
        sudo usermod -a -G pcap ${username}
        shift
    done
    echo -e "\n\n${C_GREEN}Please logout and then login to make group setting effective.${C_NONE}"
}

##### Main() #####
main "$@"

exit 0
