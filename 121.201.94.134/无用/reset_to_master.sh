#!/bin/bash
echo "Now changing the slave to the master..."
mysql -uroot -e"stop slave; reset master; reset slave all; set global super_read_only=0;"
service mysql restart
echo "sucess!"