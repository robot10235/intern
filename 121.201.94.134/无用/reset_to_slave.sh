#!/bin/bash

mysql -uroot -p123456 -e"reset slave all;"

# if the master does not exist, this server wont be the slave 
result=`mysqladmin -uppl -p123456 -h121.201.125.74 ping 2>/dev/null`
expected='mysqld is alive'
if [[ "$result" != "$expected" ]]
then
    exit 1
fi

#backup the data of the master
ssh 121.201.125.74 "mysql -uroot -e'reset master;'"
ssh 121.201.125.74 "rm -rf /mysql_backup/tmp"
ssh 121.201.125.74 "innobackupex --user=root --password=123456 --no-timestamp /mysql_backup/tmp"
ssh 121.201.125.134 "cd /mysql_backup;tar czvf backup.tar tmp"
ssh 121.201.125.74 "service mysql stop"
scp -r root@121.201.125.74:/mysql_backup/backup.tar /mysql_backup

#recover the data from the master
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

result=`mysqladmin -uroot -p123456 ping`
expected='mysqld is alive'

if [[ "$result" == "$expected" ]]
then
	  echo "mysqld has recovered"
	  mysql -uroot -p123456 -e" reset master;  \
	  CHANGE MASTER TO
	  MASTER_HOST='121.201.125.74',
	  MASTER_USER='ppl',
	  MASTER_PASSWORD='123456',
	  MASTER_PORT=3306,
	  MASTER_AUTO_POSITION=1;
  	start slave;
  	set global super_read_only=1;" 2>/dev/null
  	echo "this server has been set up as slave"
else
  	echo "mysqld still stops"
fi
