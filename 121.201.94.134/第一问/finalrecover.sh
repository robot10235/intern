#!/bin/bash
service mysql stop
read -r -p "recovering backup is 1:full backup  2:incremental backup " num1

target=a
if [ $num1 -eq 1 ]
then
  read -r -p "Please input the backup name: " base
  innobackupex --apply-log /mysql_backup/$base
  target=$base
  
elif [ $num1 -eq 2 ]
then 
  read -r -p "Please input the basedir name: " base
  innobackupex --apply-log --redo-only /mysql_backup/$base
  
  while true
  do
		read -r -p "Please input the next incremental backup name(0:end):" incre
		if [ $incre -eq 0 ]
		then
		  break
		else
		  innobackupex --apply-log --redo-only --user=root --password=123456 \
		  --incremental-dir=/mysql_backup/$incre /mysql_backup/$base
		fi
  done
  innobackupex --apply-log /mysql_backup/$base
  target=$base
  
else
  echo "wrong number"
  service mysql start
  exit 1
fi 


read -r -p "1:whole  2:partial " num2
if [ $num2 -eq 1 ]
then
  echo "recovering whole"
  mv /var/lib/mysql/* /var/lib/sqlback
  innobackupex --copy-back /mysql_backup/$target
  
elif [ $num2 -eq 2 ]
then

  read -r -p "Please input the database name: " db
  read -r -p "1:single database  2:single table " choose3
    
  if [ $choose3 -eq 1 ]
  then
    echo "recovering databace:$db "
   	cp /mysql_backup/$target/* /var/lib/mysql -rf
      
  elif [ $choose3 -eq 2 ]
  then
    read -r -p "Please input the table name: " table
 	  echo "recovering databace:$db table:$table"
    cp /mysql_backup/$target/$db/* /var/lib/mysql/$db -rf
    
  else
    echo "wrong number!"
    service mysql start
    exit 1
  fi
  
else
  echo "wrong number!"
  service mysql start
  exit 1
fi

chown -R mysql.mysql /var/lib/mysql
service mysql start