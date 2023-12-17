#!/bin/bash

read -rp "New site for which user? " username
if [ ! -d "/home/$username" ]; then
    echo "User does not exist."
    exit 1
fi

read -rp "Domain name? " domain

cp /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/$domain.conf
sed -i -e "s/\[www\]/\[$domain\]/" /etc/php/8.1/fpm/pool.d/$domain.conf
sed -i -e "s/www-data/$username/" /etc/php/8.1/fpm/pool.d/$domain.conf
sed -i -e "s/php8.1-fpm.sock/php8.1-fpm.$domain.sock/" /etc/php/8.1/fpm/pool.d/$domain.conf

cat <<EOF > /etc/apache2/sites-available/$domain.conf
<VirtualHost *:80>
  ServerName $domain
  DocumentRoot /home/$username/sites/$domain/public_html
  Header set Access-Control-Allow_origin "*"

  <IfModule mod_fcgid.c>
    FcgidConnectTimeout 20
    AddType application/x-httpd-php .php
    AddHandler application/x-httpd-php .php

    ProxyPassMatch " ^/(.*\.php(/.*)?)$" "unix:/run/php/php8.1-fpm.$domain.sock|fcgi://localhost/home/$username/sites/$domain/public_html/"

    <Directory /home/$username/sites/$domain/public_html/>
      Options +ExecCgi
      Options -Indexes
      AllowOverride None
      Require all granted

      # Uncomment the following lines if needed
      # RewriteEngine On
      # RewriteCond "%{REQUEST_URI}" "!=/index.php"
      # RewriteRule "^(.*)$" "/index.php?\$1" [NC,NE,L,PT,QSA]
    </Directory>
  </IfModule>

  # CPU usage limits 5s 10s
  RLimitCPU 5 10
  # memory limits to 10M 20M
  RLimitMEM 10000000 20000000
  # limit of forked processes 20 30
  RLimitNPROC 20 30
  LogLevel warn
  ErrorLogFormat connection "[%t] New connection: [%{c}L] [ip: %a]"
  ErrorLogFormat request "[%t] [%{c}L] New request: [%L] [pid %P] %F: %E"
  ErrorLogFormat "[%t] [%{c}L] [%L] [%l] [pid %P] %F: %E: %M"
  ErrorLog /home/$username/sites/$domain/logs/apache_error.log
  CustomLog /home/$username/sites/$domain/logs/apache_access.log combined
  ServerSignature Off
</VirtualHost>
EOF

echo -e "127.0.0.1\t$domain" >> /etc/hosts

a2ensite $domain
mkdir -p /home/$username/sites/$domain/public_html
mkdir -p /home/$username/sites/$domain/logs
chown -R $username:$username /home/$username/sites/$domain
find /home/$username/sites/$domain -type d -name '*' | xargs chmod 700
find /home/$username/sites/$domain -type f -name '*' | xargs chmod 600
chmod 711 /home/$username/sites/$domain
chmod 711 /home/$username/sites/$domain/public_html

systemctl reload php8.1-fpm
systemctl restart php8.1-fpm
systemctl restart apache2

echo "New site has been created in /home/$username/sites/$domain"

