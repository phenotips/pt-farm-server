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
sudo systemctl start mysqld
sudo systemctl enable mysqld
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
keybase pgp decrypt -i ca-bundle.trust.crt.asc -o ca-bundle.trust.crt
keybase pgp decrypt -i ca-bundle.crt.asc -o ca-bundle.crt
keybase pgp decrypt -i DigiCertCA.crt.asc -o DigiCertCA.crt
keybase pgp decrypt -i star_ccm_sickkids_ca.crt.asc -o star_ccm_sickkids_ca.crt
keybase pgp decrypt -i star_ccm_sickkids_ca.key.asc -o star_ccm_sickkids_ca.key

sudo mkdir /etc/httpd/certs/
sudo cp ./star_ccm_sickkids_ca.crt /etc/pki/tls/certs/star_ccm_sickkids_ca.crt
sudo cp ./ca-bundle.trust.crt /etc/pki/tls/certs/ca-bundle.trust.crt
sudo cp ./DigiCertCA.crt /etc/pki/tls/certs/DigiCertCA.crt
sudo cp ./ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt
sudo cp ./star_ccm_sickkids_ca.crt /etc/httpd/certs/star_ccm_sickkids_ca.crt
sudo cp ./star_ccm_sickkids_ca.key /etc/httpd/certs/star_ccm_sickkids_ca.key
sudo cp ./DigiCertCA.crt /etc/httpd/certs/DigiCertCA.crt

sudo chmod 644 /etc/pki/tls/certs/star_ccm_sickkids_ca.crt
sudo chmod 644 /etc/pki/tls/certs/ca-bundle.trust.crt
sudo chmod 644 /etc/pki/tls/certs/DigiCertCA.crt
sudo chmod 644 /etc/pki/tls/certs/ca-bundle.crt
sudo chmod 644 /etc/httpd/certs/star_ccm_sickkids_ca.crt
sudo chmod 644 /etc/httpd/certs/star_ccm_sickkids_ca.key
sudo chmod 644 /etc/httpd/certs/DigiCertCA.crt
ln -s /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/cert.pem

rm ./ca-bundle.trust.crt
rm ./ca-bundle.crt
rm ./DigiCertCA.crt
rm ./star_ccm_sickkids_ca.crt
rm ./star_ccm_sickkids_ca.key

##################
# WORK IN PROGRESS ...
##################

# Tomcat
sudo systemctl start tomcat
sudo systemctl enable tomcat

# HTTPD
sudo systemctl start httpd
sudo systemctl enable httpd

# Configure PhenoTips


# Test website login pages
curl -v https://genenames.phenotips.org/info


# sudo reboot


