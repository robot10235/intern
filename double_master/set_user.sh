#!/bin/bash

mysql -uroot -p123456 -e"DELETE FROM mysql.user where user='ppl';" 2>/dev/null
mysql -uroot -p123456 -e"flush privileges;" 2>/dev/null
mysql -uroot -p123456 -e"CREATE USER 'ppl'@'%' IDENTIFIED BY '123456';" 2>/dev/null
mysql -uroot -p123456 -e"GRANT REPLICATION SLAVE ON *.* TO 'ppl'@'%';" 2>/dev/null