#!/bin/bash
### Script is based off of:
### https://www.howtoforge.com/apache_php_mysql_on_centos_7_lamp

# Set up EPEL Repo for phpMyAdmin
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum -y install epel-release

# Install MariaDB
yum -y install mariadb-server mariadb
systemctl start mariadb.service
systemctl enable mariadb.service

#Set Mysql root password
mysqladmin -u root password NewPassword123
#Delete anonymous MySQL users
mysql -u root -p'NewPassword123' -e "delete from mysql.user where User='';"
#Disable remote MySQL access for root MySQL user
mysql -u root -p'NewPassword123' -e "delete from mysql.user where User='root' and host not in ('localhost', '127.0.0.1', '::1');"
#Remove the test database
mysql -u root -p'NewPassword123' -e "drop database test;"
mysql -u root -p'NewPassword123' -e "delete from mysql.db where Db='test' or Db='test\_%';"
mysql -u root -p'NewPassword123' -e "flush privileges;"

#Install Apache
yum -y install httpd
systemctl start httpd.service
systemctl enable httpd.service

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

#Install PHP
yum -y install php

systemctl restart httpd.service

touch /var/www/html/info.php
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown httpd:httpdp /var/www/html/info.php

#Install phpMyAdmin
yum -y install phpmyadmin

cat << EOF > /etc/httpd/conf.d/phpMyAdmin.conf
Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
        Options none
        AllowOverride Limit
        Require all granted
</Directory>
EOF

cat << EOF > /etc/phpMyAdmin/config.inc.php
$cfg['Servers'][$i]['auth_type']     = 'http';    // Authentication method (config, http or cookie based)?
EOF

systemctl restart httpd.service
