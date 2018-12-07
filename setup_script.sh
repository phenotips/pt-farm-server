#!/bin/bash

# Dependencies
sudo yum update -y
sudo yum install -y mc tomcat postfix mariadb mariadb-server screen tmux mysql-server mod_ssl ntpdate ntp jetty rsync telnet vim git

# Install PhenoTips
curl https://phenotips.org/download/PhenoTips/Download/PhenoTips.repo > PhenoTips.repo
sudo chown root:root PhenoTips.repo
sudo mv PhenoTips.repo /etc/yum.repos.d/
sudo yum install -y phenotips

# Download server setup helper files
cd ~
git clone https://github.com/phenotips/pt-farm-server
cd pt-farm-server

# Hostname
sudo hostnamectl set-hostname webapps.ccm.sickkids.ca

# SSH
keybase pgp decrypt -i authorized_keys.asc -o ~/.ssh/authorized_keys

# NTP
sudo systemctl start ntpd
sudo systemctl enable ntpd

# Database
sudo systemctl start mariadb
sudo systemctl enable mariadb
## Migrate database
# mysqldump -u root --all-databases > alldb.sql
# mysql -u root < alldb.sql

# Mail server
sudo echo 'relayhost = mailrelay.research.sickkids.ca' >> /etc/postfix/main.cf
sudo systemctl restart postfix
sudo systemctl enable postfix
# sendmail daniel.snider@sickkids.ca << EOF
# Subject: Terminal Email Send
# Email Content line 1
# EOF

# SSL keys
keybase pgp decrypt -i ./certs/ca-bundle.trust.crt.asc -o ca-bundle.trust.crt
keybase pgp decrypt -i ./certs/ca-bundle.crt.asc -o ca-bundle.crt
keybase pgp decrypt -i ./certs/DigiCertCA.crt.asc -o DigiCertCA.crt
keybase pgp decrypt -i ./certs/star_ccm_sickkids_ca.crt.asc -o star_ccm_sickkids_ca.crt
keybase pgp decrypt -i ./certs/star_ccm_sickkids_ca.key.asc -o star_ccm_sickkids_ca.key

sudo mkdir /etc/httpd/certs/
sudo cp ./star_ccm_sickkids_ca.crt /etc/pki/tls/certs/star_ccm_sickkids_ca.crt
sudo cp ./ca-bundle.trust.crt /etc/pki/tls/certs/ca-bundle.trust.crt
sudo cp ./DigiCertCA.crt /etc/pki/tls/certs/DigiCertCA.crt
sudo cp ./ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt
sudo cp ./star_ccm_sickkids_ca.crt /etc/httpd/certs/star_ccm_sickkids_ca.crt
sudo cp ./star_ccm_sickkids_ca.key /etc/httpd/certs/star_ccm_sickkids_ca.key
sudo cp ./star_ccm_sickkids_ca.key /etc/pki/tls/private/star_ccm_sickkids_ca.key
sudo cp ./DigiCertCA.crt /etc/httpd/certs/DigiCertCA.crt
ln -s /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/cert.pem

rm ./ca-bundle.trust.crt
rm ./ca-bundle.crt
rm ./DigiCertCA.crt
rm ./star_ccm_sickkids_ca.crt
rm ./star_ccm_sickkids_ca.key

# Tomcat
echo 'JAVA_OPTS="-Xmx6g -Djsse.enableSNIExtension=true -Djava.security.egd=file:/dev/./urandom"' >> /etc/tomcat/tomcat.conf
sudo systemctl enable tomcat

# HTTPD
sudo cp ./ssl.conf /etc/httpd/conf.d/ssl.conf
sudo cp httpd.conf /etc/httpd/conf/httpd.conf
sudo cp 50-ccm-farm.webapps-sk.conf /etc/httpd/conf.d/50-ccm-farm.webapps-sk.conf
sudo systemctl start httpd
sudo systemctl enable httpd

# Configure PhenoTips
keybase decrypt -i hibernate.cfg.xml.asc -o hibernate.cfg.xml
keybase decrypt -i xwiki.cfg.asc -o xwiki.cfg
sudo mv hibernate.cfg.xml /var/lib/phenotips/webapp/WEB-INF/hibernate.cfg.xml
sudo mv xwiki.cfg /var/lib/phenotips/webapp/WEB-INF/xwiki.cfg
sudo cp xwiki.properties /var/lib/phenotips/webapp/WEB-INF/xwiki.properties
rm hibernate.cfg.xml xwiki.cfg

## Migrate Phenotips data directory
# tar -vczf phenotips-data.tar.gz /var/lib/phenotips/data/extension /var/lib/phenotips/data/jobs /var/lib/phenotips/data/storage
# scp root@webapps.ccm.sickkids.ca:/var/lib/phenotips/data/phenotips-data.tar.gz ./
# tar -vxzf phenotips-data.tar.gz
# sudo mv ./var/lib/phenotips/data/extension /var/lib/phenotips/data/extension
# sudo mv ./var/lib/phenotips/data/jobs /var/lib/phenotips/data/jobs
# sudo mv ./var/lib/phenotips/data/storage /var/lib/phenotips/data/storage
# rm phenotips-data.tar.gz var -r

# Start Phenotips
sudo systemctl start tomcat

