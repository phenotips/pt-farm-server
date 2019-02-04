#!/bin/bash

########################
#
## Servers that do NOT need updating:
# -Gateway HTTPD proxy
# -PC Beacon - hosts Care4Rare exomes, no way to change them?
# -PC Preprod - Old data doesn't matter?
# -PC Dev - Old data doesn't matter
# -PC Playground - Old data doesn't matter
#
########################

########################
#
## Servers that DO need updating:
# - PhenoTips Database: PT Farm, PC Prod2
# - ElasticCompute: Stats
# - Jenkins: CI
# - Nexus: Nexus
#
########################

########################
## Dump PhenoTips Database
#
# Apply to Servers:
# PT Farm
# PC Prod2
#
########################
# Detect where the PhenoTips instance is
if [[ -f /var/lib/tomcat6/webapps/ROOT/WEB-INF/xwiki.properties ]]
then
  HIBERNATE_CONFIG="/var/lib/tomcat6/webapps/ROOT/WEB-INF/hibernate.cfg.xml"
elif [[ -f /var/lib/tomcat6/webapps/phenotips/WEB-INF/xwiki.properties ]]
then
  HIBERNATE_CONFIG="/var/lib/tomcat6/webapps/phenotips/WEB-INF/hibernate.cfg.xml"
elif [[ -f /var/lib/phenotips/webapp/WEB-INF/xwiki.properties ]]
then
  HIBERNATE_CONFIG="/var/lib/phenotips/webapp/WEB-INF/hibernate.cfg.xml"
fi

# Extract the mysql host, DB name, username and password
MHOST=`cat $HIBERNATE_CONFIG | grep 'jdbc:mysql://' | sed -r -e 's/.*\/\/([^\/]+)\/.*/\1/'`
MDB=`cat $HIBERNATE_CONFIG | grep 'jdbc:mysql://' | sed -r -e 's/.*\/\/[^\/]+\/([^?<]+).*/\1/'`
MUSER=`cat $HIBERNATE_CONFIG | grep 'jdbc:mysql://' -A 5 | grep 'connection.username' | sed -r -e 's/.*>([^<]+)<.*/\1/'`
MPASS=`cat $HIBERNATE_CONFIG | grep 'jdbc:mysql://' -A 5 | grep 'connection.password' | sed -r -e 's/.*>([^<]+)<.*/\1/'`

# Compute the backup filename and make sure its parent directory exists
BACKUPDIR=/var/lib/phenotips/backups/mysql
DBFILE=data.sql

# Dump the database
mysqldump --events --single-transaction $MDB -u $MUSER -h $MHOST -p $MPASS > $DBFILE

########################
## Load PhetoTips Database
########################
mysql -u $MUSER -h $MHOST -p $MPASS < $DBFILE

########################
## Upgrade Phenotips Version (Only if out of date)
########################

# Option 1) Install PhenoTips From APT
curl https://phenotips.org/download/PhenoTips/Download/PhenoTips.repo > PhenoTips.repo
sudo chown root:root PhenoTips.repo
sudo mv PhenoTips.repo /etc/yum.repos.d/
sudo yum install -y phenotips

# Option 2) Install PhenoTips From WGET
systemctl stop tomcat || service tomcat stop
mkdir -p /var/lib/phenotips/next
cd /var/lib/phenotips/next
wget https://nexus.phenotips.org/nexus/content/repositories/releases/org/phenotips/phenotips-standalone/1.2.5/phenotips-standalone-1.2.5.zip 
unzip phenotips-*.zip && rm phenotips-*.zip
cd phenotips-*
rm -rf ../../solr/ && cp -r data/solr ../../
mkdir /var/lib/phenotips/backup
mv /var/lib/tomcat*/webapps/phenotips /var/lib/phenotips/backup 
mv /var/lib/tomcat*/webapps/ROOT /var/lib/phenotips/backup # ? needed
mv webapps/phenotips /var/lib/tomcat*/webapps 
rm -rf /var/lib/phenotips/next
chown -R tomcat:tomcat /var/lib/phenotips || chown -R tomcat:tomcat /var/lib/phenotips

# Merge any custom changes done in the following configuration files from the old instance into the new one:
diff xwiki.cfg /var/lib/phenotips/webapp/WEB-INF/xwiki.cfg
diff xwiki.properties /var/lib/phenotips/webapp/WEB-INF/xwiki.properties
diff hibernate.cfg.xml /var/lib/phenotips/webapp/WEB-INF/hibernate.cfg.xml

# Start new version of Phenotips
systemctl start tomcat || service tomcat start


########################
## Elastic Compute
#
# Apply to Server: Stats
#
########################
# Initialize Snapshot Respository
    curl -sX PUT http://$ES_HOST:$ES_PORT/_snapshot/$REPOSITORY_NAME -w "\n" -d  @- << EOF
{
  "type": "fs",
  "settings": {
      "location": "/root/elastic_backup"
  }
}
EOF

# Perform a snapshat
curl -sX PUT -w "\n" http://$ES_HOST:$ES_PORT/_snapshot/$REPOSITORY_NAME/$SNAPNAME?wait_for_completion=true

# Restore from an existing snapshot:
curl -sX POST -w "\n" http://$ES_HOST:$ES_PORT/_snapshot/$REPOSITORY_NAME/$SNAPNAME/_restore

/var/lib

########################
## Nexus
#
# Apply to Server: Nexus
#
########################
cat <<EOF  >> /etc/ssh/ssh_config
Host *.local
    ProxyCommand ssh -i ~/.ssh/id_rsa.dan -q root@frontend1.ccm.sickkids.ca nc %h 22
EOF

rsync -v  -e "ssh -i /root/.ssh/id_rsa.dan" nexus.local:/home/nexus /home/nexus



########################
## Jenkins
## https://wiki.jenkins.io/display/JENKINS/Administering+Jenkins
#
# Apply to Server: CI
#
########################
cat <<EOF  >> /etc/ssh/ssh_config
Host *.local
    ProxyCommand ssh -i ~/.ssh/id_rsa.dan -q root@frontend1.ccm.sickkids.ca nc %h 22
EOF

rsync -v  -e "ssh -i /root/.ssh/id_rsa.dan" ci.local:/var/lib/jenkins /var/lib/jenkins
```
