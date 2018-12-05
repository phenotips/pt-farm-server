#!/bin/bash

sudo yum update -y
sudo yum install -y mc tomcat epel-release screen tmux mysql-server mod_ssl ntpdate ntp jetty rsync telnet vim git

curl https://phenotips.org/download/PhenoTips/Download/PhenoTips.repo > PhenoTips.repo
sudo chown root:root PhenoTips.repo
sudo mv PhenoTips.repo /etc/yum.repos.d/
sudo yum install -y phenotips

sudo sed '/^127\.0\.0\.1/ s/$/ test.ccm.sickkids.ca/' /etc/hosts

sudo hostnamectl set-hostname webapps.ccm.sickkids.ca

cd ~
git clone https://github.com/phenotips/pt-farm-server
cd pt-farm-server

keybase pgp decrypt -i authorized_keys.asc -o ~/.ssh/authorized_keys

sudo systemctl start ntpd
sudo chkconfig ntpd on


curl https://repo.mysql.com//mysql80-community-release-el7-1.noarch.rpm -o mysql80-community-release-el7-1.noarch.rpm
sudo rpm -ivh mysql80-community-release-el7-1.noarch.rpm
sudo yum update -y
sudo yum install -y mysql-server
rm mysql80-community-release-el7-1.noarch.rpm
sudo systemctl start mysqld






sudo grep 'temporary password' /var/log/mysqld.log | rev | cut -d' ' -f 1 | rev



/etc/httpd/conf.d/phenotips.conf

mv /etc/tomcat/Catalina/localhost/phenotips.xml /etc/tomcat/Catalina/localhost/ROOT.xml

sudo systemctl start httpd
sudo systemctl start tomcat





/usr/bin/mysqld_safe --skip-grant-tables &
vi /etc/resolv.conf


73  /etc/init.d/mysqld start
85  /etc/init.d/tomcat restart
101  /etc/init.d/tomcat stop
105  /etc/init.d/tomcat start ; tail -f /var/log/tomcat/catalina.out
112  /etc/init.d/tomcat restart ; tail -f /var/log/tomcat/catalina.out
168  /etc/init.d/httpd restart
174  /etc/init.d/sshd restart
192  /etc/init.d/iptables status
193  /etc/init.d/iptables save
253  /etc/init.d/postfix restart
286  /etc/init.d/ntpdate restart
291  /etc/init.d/ntpd start
354  /etc/init.d/tomcat restart
544  /etc/init.d/httpd reload

chkconfig tomcat on
chkconfig mysqld on
chkconfig httpd on


# sudo reboot