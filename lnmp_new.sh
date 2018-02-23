#!/bin/bash
# Author: 小白扮大神.
#Date & Time: 2018-02-23
#Description: 1.3.0

start_time=`date +%s`
function checkos(){
	if [ -f /etc/redhat-release ];then
		VER=`cat /etc/centos-release | tr -dc '0-9' | cut -c1`
		if [ ! -f /etc/centos-release ];then
			VER=`cat /etc/os-release | tr -dc '0-9' | cut -c1`
		fi
        centos_version=`grep -oE  "[0-9.]+" /etc/redhat-release`
        echo -e "SYSTEM VERSION:${centos_version}"
		if [ "$VER" == "6" ];then
			prepare
			centos6_lnmp_install
		elif [ "$VER" == "7" ];then
			prepare
			centos7_lnmp_install
		else
			echo -e "\033[31m The installation is terminated\a! Please check and try again! \033[0m";
			exit;
		fi
	fi
}

function prepare(){
	IP=$(curl -s icanhazip.com)
	if [[ "$IP" = "" ]]; then
    	IP=$(curl -s ipinfo.io/ip)
	fi
	if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
		sed -ri.bak 's/(^SELINUX=).*/\1permissive/' /etc/selinux/config
		echo "/usr/sbin/setenforce 0" >> /etc/rc.local
		setenforce 0
	fi
	groupadd -g 501 www
	useradd -g www -M www
}

function centos6_lnmp_install(){
echo "Cleaning..."
yum -y remove nginx
yum -y remove mysql mysql-server mysql-devel
yum -y remove php php-mysql php-fpm
echo -e "\033[32m lnmp install script starts \033[0m"
yum -y install epel-release
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi
yum -y install nginx
mkdir -p /home/wwwroot/default
mkdir -p /home/wwwlogs/
chown -R www:www /home/wwwroot/default
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name  localhost;
    index index.html index.htm index.php default.html default.htm default.php;
    root /home/wwwroot/default;
    
    location / {
        # try_files \$uri \$uri/ /index.php index.php;
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
    {
        expires      30d;
    }

    location ~ .*\.(js|css)?$
    {
        expires      12h;
    }

    location ~ \.php$ {
        fastcgi_index  index.php;
        fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_split_path_info  ^(.+\.php)(/.*)$;
	}
}
EOF
cat << EOF > /home/wwwroot/default/index.php
<p>The lnmp is success! time=`date`</p>
<?php phpinfo(); ?>
EOF
service nginx start
chkconfig nginx on
yum -y --enablerepo=remi install mysql mysql-server mysql-devel
service mysqld start
/usr/bin/mysqladmin -u root password 'oeone'
mysql -uroot -p'oeone' << EOF
USE mysql;
DELETE FROM user WHERE host<>'localhost';
GRANT ALL ON *.* TO 'root'@'127.0.0.1'  IDENTIFIED BY 'oeone';
FLUSH PRIVILEGES;
EOF
chkconfig mysqld on
yum -y --enablerepo=remi --enablerepo=remi-php56 install php php-opcache php-pecl-apcu php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-pdo php-pear php-fpm php-cli php-xml php-bcmath php-process php-gd php-common php-json
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' /etc/php.ini
sed -i 's,listen = 127.0.0.1:9000,listen = /var/run/php-fpm/php-fpm.sock,g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0666/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sed -i 's/user = apache/user = www/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = www/g' /etc/php-fpm.d/www.conf
mkdir -p /var/lib/php/session/
chown -R www:www /var/lib/php/session/
service php-fpm start
chkconfig php-fpm on
cd /home/wwwroot/default
wget http://oeone-1252394125.cossh.myqcloud.com/lnmp/phpMyAdmin-4.4.15-all-languages.zip
unzip phpMyAdmin-4.4.15-all-languages.zip >/dev/null 2>&1
mv phpMyAdmin-4.4.15-all-languages phpmyadmin
rm -rf phpMyAdmin-4.4.15-all-languages.zip
cat << EOF > /home/wwwroot/default/phpmyadmin/config.inc.php
<?php 
\$cfg['blowfish_secret'] = 'ba1213123';
\$i= 0 ; 
\$i++ ; 
\$cfg['Servers'][\$i]['auth_type'] = 'cookie'; 
?>
EOF
echo "
echo -e '正在重启lnmp服务		  [\033[32m  OK  \033[0m]'
service nginx restart
service mysqld restart
service php-fpm restart
exit 0;
" >/bin/lnmp
chmod 777 /bin/lnmp
}

function centos7_lnmp_install(){
echo "Cleaning..."
yum -y remove nginx
yum -y remove mariadb mariadb-server mariadb-client
yum -y remove php70w php70w-fpm php70w-cli php70w-mysql php70w-gd php70w-ldap php70w-odbc php70w-pdo php70w-pecl-memcache php70w-pear php70w-mbstring php70w-xml php70w-xmlrpc php70w-mbstring php70w-snmp php70w-soap
echo -e "\033[32m lnmp install script starts \033[0m"
yum -y install epel-release.noarch
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install nginx
mkdir -p /home/wwwroot/default
mkdir -p /home/wwwlogs/
chown -R www:www /home/wwwroot/default
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name  localhost;
    index index.html index.htm index.php default.html default.htm default.php;
    root /home/wwwroot/default;

    include enable-php.conf;
    location / {
        # try_files \$uri \$uri/ /index.php index.php;
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    
    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
    {
        expires      30d;
    }

    location ~ .*\.(js|css)?$
    {
        expires      12h;
    }

}
EOF
cat << EOF > /etc/nginx/enable-php.conf
    location ~ \.php$ {
        fastcgi_index  index.php;
        fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_split_path_info  ^(.+\.php)(/.*)$;
}
EOF
cat << EOF > /home/wwwroot/default/index.php
<p>The lnmp is success! time=`date`</p>
<?php phpinfo(); ?>
EOF
systemctl start nginx.service
systemctl enable nginx.service
sleep 1
yum -y install mariadb mariadb-server mariadb-client net-tools
systemctl start mariadb.service
/usr/bin/mysqladmin -u root password 'oeone'
mysql -uroot -p'oeone' << EOF
USE mysql;
DELETE FROM user WHERE host<>'localhost';
GRANT ALL ON *.* TO 'root'@'127.0.0.1'  IDENTIFIED BY 'oeone';
FLUSH PRIVILEGES;
EOF
systemctl enable mariadb.service
sleep 1
yum -y install php70w php70w-fpm php70w-cli php70w-mysql php70w-gd php70w-ldap php70w-odbc php70w-pdo php70w-pecl-memcache php70w-pear php70w-mbstring php70w-xml php70w-xmlrpc php70w-mbstring php70w-snmp php70w-soap
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' /etc/php.ini
sed -i 's,listen = 127.0.0.1:9000,listen = /var/run/php-fpm/php-fpm.sock,g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0666/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sed -i 's/user = apache/user = www/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = www/g' /etc/php-fpm.d/www.conf
mkdir -p /var/lib/php/session/
chown -R www:www /var/lib/php/session/
systemctl start php-fpm.service
systemctl enable php-fpm.service
cd /home/wwwroot/default
wget http://oeone-1252394125.cossh.myqcloud.com/lnmp/phpMyAdmin-4.4.15-all-languages.zip
unzip phpMyAdmin-4.4.15-all-languages.zip >/dev/null 2>&1
mv phpMyAdmin-4.4.15-all-languages phpmyadmin
rm -rf phpMyAdmin-4.4.15-all-languages.zip
cat << EOF > /home/wwwroot/default/phpmyadmin/config.inc.php
<?php 
\$cfg['blowfish_secret'] = 'ba1213123';
\$i= 0 ; 
\$i++ ; 
\$cfg['Servers'][\$i]['auth_type'] = 'cookie'; 
?>
EOF
echo "
echo -e '正在重启lnmp服务'
systemctl restart nginx.service
systemctl restart mariadb.service
systemctl restart php-fpm.service
echo -e '[\033[32m  OK  \033[0m]'
exit 0;
" >/bin/lnmp
chmod 777 /bin/lnmp
}
checkos
end_time=`date +%s`
time=$[ end_time - start_time ]
echo -e "\033[34m 网站目录/home/wwwroot/default \033[0m"
echo -e "\033[34m 数据库访问地址：http://${IP}/phpmyadmin \033[0m"
echo -e "\033[34m 快速重启lnmp命令：lnmp \033[0m"
echo -e "\033[34m lnmp安装结束，历时:${time}s.     ——小白扮大神 \033[0m"
exit 0;
