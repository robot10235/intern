#!/bin/bash

# this function will run when the server restart
# when the sever restart, it should judge that it will be the master or slave
# the rule is that only one server online will be the master, the other one will be the slave
result=`mysqladmin -uppl -p123456 -h121.201.125.74 ping 2>/dev/null` 
expected='mysqld is alive'
if [[ "$result" != "$expected" ]]
then
    /root/reset_to_master.sh
else
    /root/reset_to_slave.sh
fi
