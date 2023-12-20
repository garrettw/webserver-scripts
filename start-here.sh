#!/bin/bash

echo "Beginning web server setup."

read -rp "Do you need to add a volume to /etc/fstab [y/N]? " addvols
if [[ $addvols == y || $addvols == Y ]]; then
	read -rp "Full device path of volume (/dev/xxx)? " devpath
	read -rp "Mount point? " mountpoint
	read -rp "Fileystem? " fs
	echo "$devpath	$mountpoint	$fs	defaults	0 2" >> /etc/fstab
	echo "Volume added. Reboot the system and run this script again to continue."
	read -rp "Reboot now [Y/n]? " rb
	if [[ $rb == y || $rb == Y || $rb == '' ]]; then
		reboot
	fi
	exit 0
fi
echo

read -rp "Enter the username of the default user (not root, maybe ubuntu): " defaultuser

apt update && sudo apt upgrade
apt install apache2 php php-fpm libapache2-mod-fcgid mariadb-client
a2dismod php8.1 mpm_prefork
a2enmod mpm_event proxy_fcgi headers rewrite
a2enconf php8.1-fpm
systemctl restart apache2
sed -i -e "s/FcgidConnectTimeout 20/FcgidConnectTimeout 20\n  AddType application\/x-httpd-php .php\n  AddHandler application\/x-httpd-php .php/" /etc/apache2/mods-available/fcgid.conf
addgroup sshlogin
adduser $defaultuser sshlogin
echo "AllowGroups sshlogin sudo" >> /etc/ssh/sshd_config

read -rp "Set minimum user password length: " pwlen
if [ -n $pwlen ]; then
    sed -i -e "s/pam_unix.so obscure yescrypt/pam_unix.so obscure yescrypt minlen=$pwlen/" /etc/pam.d/common-password
fi

read -rp "Set global default MariaDB host: " mysql_host
if [ -n mysql_host ]; then
    echo "MYSQL_HOST=$mysql_host" >> /etc/environment
    sed -i -e "s/socket = \/run\/mysqld\/mysqld.sock/# socket = \/run\/mysqld\/mysqld.sock\nhost = $mysql_host\n\n\[client\]\nhost = $mysql_host/" /etc/mysql/mariadb.cnf
fi

read -rp "Enter username of MariaDB superuser [root]: " mysql_root_user
if [ -z mysql_root_user ]; then
    mysql_root_user=root
fi
read -rsp "Enter password of MariaDB superuser: " mysql_root_password

cat << EOF > /root/.my.cnf
[client]
user=$mysql_root_user
password=$mysql_root_password
EOF

if [ ! -d /etc/skel/sites ]; then
    mkdir /etc/skel/sites
fi

echo -e "\nApache, PHP, and MariaDB client have been installed. Next, you can add new users using the (sudo) adduser command. Be sure to add them to the sudo and/or sshlogin groups if desired."

