#!/bin/bash
#service mysql start
while :
do
    while :
    do
        r=`mysqladmin -uroot -p123456 ping 2>/dev/null`
        expected='mysqld is alive'
        if [[ "$r" == "$expected" ]]
        then
            break
        fi
        sleep 10
    done
    result=`mysqladmin -uppl -p123456 -h121.201.125.74 ping 2>/dev/null` 
    expected='mysqld is alive'
    if [[ "$result" != "$expected" ]]
    then
        while :
        do
            s=`mysql -uroot -p123456 -e"show slave status\G" 2>/dev/null | grep -i "running"`
            state=`echo $s | awk -F: '{print $4}'`
            exp=" Slave has read all relay log; waiting for more updates"
            if [[ "$state" == " Slave has read all relay log; waiting for more updates" ]]
            then
                /root/double_master/reset_one_server.sh
                break
            elif [[ "$state" == "" ]]
            then
                #echo "slave is dead"
                break
            else
                #echo "the other server is dead, but the slave has not read all relay log. please wait..."
                sleep 10
            fi
        done
    fi
    sleep 10
done