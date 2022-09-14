#!/bin/bash
t=_
read -p "1:full backup  2:incremental backup " num1
if [ $num1 -eq 1 ]
then
  read -p "1:whole  2:partial " choose2
  
  if [ $choose2 -eq 1 ]
  then
    echo "backing up full"
    innobackupex /mysql_backup --user=root --password=123456
    
  elif [ $choose2 -eq 2 ]
  then
    read -p "1:single database  2:single table" choose3
    
    if [ $choose3 -eq 1 ]
    then
      read -r -p "Please input the name of the database: " database
      rm -rf /mysql_backup/$database
      mkdir /mysql_backup/$database
      echo "backing up database:$database"
      innobackupex --databases="$database mysql" --user=root --password=123456 --no-timestamp /mysql_backup/$database
      
    elif [ $choose3 -eq 2 ]
    then 
      read -r -p "Please input the name of the database: " database
      read -r -p "Please input the name of the table: " table
      mkdir /mysql_backup/$database$t$table
      echo "backing up table"
      innobackupex --databases="$database.$table mysql" --user=root --password=123456 --no-timestamp \
        /mysql_backup/$database$t$table
      
    else
      echo "wrong number!"
      exit 1
    fi
    
  else 
    echo "wrong number!"
    exit 1
  fi
  
elif [ $num1 -eq 2 ]
then
  read -p "1:whole  2:partial " choose4
  
  if [ $choose4 -eq 1 ]
  then
    read -r -p "Please input basedir name: " bd
    echo "backing up incremental"
    innobackupex --user=root --password=123456 --incremental /mysql_backup --incremental-basedir=/mysql_backup/$bd
    
  elif [ $choose4 -eq 2 ]
  then
    read -p "1:single database  2:single table " choose5
    
    if [ $choose5 -eq 1 ]
    then
      read -r -p "Please input the No. of the incremental: " no
      read -r -p "Please input the name of the database: " database
      mkdir /mysql_backup/$database$t$no
      if [ "$?" != 0 ] 
      then
          exit 1
      fi  
      echo "backing up incremental database"
      innobackupex --databases="$database mysql" --user=root --password=123456 --incremental --no-timestamp \
        /mysql_backup/$database$t$no --incremental-basedir=/mysql_backup/$database
      
    elif [ $choose5 -eq 2 ]
    then 
      read -r -p "Please input the No. of the incremental: " no
      read -r -p "Please input the name of the database: " database
      read -r -p "Please input the name of the table: " table
      mkdir /mysql_backup/$database$t$table$t$no
      echo "backing up incremental table"
      innobackupex --databases="$database.$table mysql" --user=root --password=123456 --incremental --no-timestamp \
        /mysql_backup/$database$t$table$t$no --incremental-basedir=/mysql_backup/$database$t$table
      
    else
      echo "wrong number!"
      exit 1
    fi
    
  else 
    echo "wrong number!"
    exit 1
  fi
  
else
  echo "wrong number!"
  exit 1
fi