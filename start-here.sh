#!/bin/bash

echo "Beginning web server setup."

read -rp "Do you need to add a volume to /etc/fstab [y/N]?" addvols
if [[ $addvols == y || $addvols == Y ]]; then
	read -rp "Full device path of volume (/dev/xxx)?" devpath
	read -rp "Mount point?" mountpoint
	read -rp "Fileystem?" fs
	sudo echo "$devpath	$mountpoint	$fs	defaults	0 2" >> /etc/fstab
	echo "Volume added. Reboot the system and run this script again to continue."
	read -rp "Reboot now [Y/n]?" rb
	if [[ $rb == y || $rb == Y || $rb == '' ]]; then
		sudo reboot
	fi
	exit 0
fi
echo

read -rp "Enter the username of the default user (not root, maybe ubuntu):" defaultuser

sudo apt update && sudo apt upgrade
sudo apt install apache2 php php-fpm libapache2-mod-fcgid
sudo a2dismod php8.1 mpm_prefork
sudo a2enmod mpm_event proxy_fcgi headers rewrite
sudo a2enconf php8.1-fpm
sudo systemctl restart apache2
sudo sed "s/FcgidConnectTimeout 20/FcgidConnectTimeout 20\n  AddType application/x-httpd-php .php\n  AddHandler application/x-httpd-php .php/" /etc/apache2/mods-available/fcgid.conf
sudo addgroup sshlogin
sudo adduser $defaultuser sshlogin
sudo echo "AllowGroups sshlogin" >> /etc/ssh/sshd_config

read -rp "Do you want to allow SSH login for new users by default [Y/n]?" allowssh
if [[ $allowssh == Y || $allowssh == y || $allowssh == "" ]]; then
    sudo echo "EXTRA_GROUPS=\"sshlogin\"\nADD_EXTRA_GROUPS=1" >> /etc/adduser.conf
fi

echo "\nApache and PHP have been installed. Next, run the per-user install script."

