#!/bin/bash

mysql -uroot -p123456 -e"CHANGE MASTER TO 
MASTER_HOST='121.201.125.74',
MASTER_USER='ppl',
MASTER_PASSWORD='123456',
MASTER_PORT=3306,
MASTER_AUTO_POSITION=1;
start slave; set global read_only=1;" 2>/dev/null