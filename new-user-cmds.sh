#!/bin/sh
# This script is executed at the end of adduser
# USAGE:
# adduser.local USER UID GID HOME

read -rp "Allow SSH login for this user [y/N]?" canssh
if [[ $canssh == y || $canssh == Y ]]; then
    adduser $1 sshlogin
fi

read -rp "Allow sudo for this user [y/N]?" cansudo
if [[ $cansudo == y || $cansudo == Y ]]; then
    adduser $1 sudo
fi

systemctl restart sshd

