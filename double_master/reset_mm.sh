#!/bin/bash

result=`mysqladmin -uppl -p123456 -h121.201.125.74 ping 2>/dev/null` 
expected='mysqld is alive'
if [[ "$result" != "$expected" ]]
then
    exit 1
fi

#backup the data of the master
ssh 121.201.125.74 "mysql -uroot -p123456 -e'reset master; stop slave; reset slave all;' 2>/dev/null"
ssh 121.201.125.74 "innobackupex --user=root --password=123456 --no-timestamp /mysql_backup/tmp"
ssh 121.201.125.74 "service mysql stop"  
ssh 121.201.125.74 "cd /mysql_backup;tar czvf backup.tar tmp"                    
scp -r root@121.201.125.74:/mysql_backup/backup.tar /mysql_backup
ssh 121.201.125.74 "rm -rf /mysql_backup/tmp"
ssh 121.201.125.74 "rm -rf /mysql_backup/backup.tar"

#recover the data from master
service mysql stop
rm -rf /mysql_backup/former/*
mv /var/lib/mysql/* /mysql_backup/former/
tar zxvf /mysql_backup/backup.tar -C /mysql_backup
innobackupex --apply-log /mysql_backup/tmp
innobackupex --copy-back /mysql_backup/tmp
rm -rf /mysql_backup/tmp
rm -rf /mysql_backup/backup.tar
chown -R mysql.mysql /var/lib/mysql
service mysql start
ssh 121.201.125.74 "service mysql start"                     

mysql -uroot -p123456 -e"reset master; stop slave; reset slave all;" 2>/dev/null
/root/double_master/set_slave.sh

#After the recovery, the other server should set the slave
#ssh 121.201.125.74 "service mysql start"
ssh 121.201.125.74 "/root/double_master/set_slave.sh"      
echo "master-master has been set"
