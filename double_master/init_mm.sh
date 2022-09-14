#!/bin/bash
service check stop
ssh 121.201.125.74 "service check stop"
#create replication user
/root/double_master/set_user.sh
ssh 121.201.125.74 "/root/double_master/set_user.sh"

#set service
systemctl disable reset.service
systemctl disable check.service
rm -rf /lib/systemd/system/reset.service
rm -rf /lib/systemd/system/check.service
cp /root/double_master/reset.service /lib/systemd/system/
cp /root/double_master/check.service /lib/systemd/system/
systemctl enable reset.service
systemctl enable check.service
ssh 121.201.125.74 "systemctl disable reset.service"
ssh 121.201.125.74 "systemctl disable check.service"
ssh 121.201.125.74 "rm -rf /lib/systemd/system/reset.service"
ssh 121.201.125.74 "rm -rf /lib/systemd/system/check.service"
ssh 121.201.125.74 "cp /root/double_master/reset.service /lib/systemd/system/"
ssh 121.201.125.74 "cp /root/double_master/check.service /lib/systemd/system/"
ssh 121.201.125.74 "systemctl enable reset.service"
ssh 121.201.125.74 "systemctl enable check.service"

#set config
rm -rf /etc/mysql/conf.d/MGR.cnf
rm -rf /etc/mysql/conf.d/single_master.cnf
rm -rf /etc/mysql/conf.d/double_master.cnf
cp /root/double_master/double_master.cnf /etc/mysql/conf.d
ssh 121.201.125.74 "rm -rf /etc/mysql/conf.d/single_master.cnf"
ssh 121.201.125.74 "rm -rf /etc/mysql/conf.d/double_master.cnf"
ssh 121.201.125.74 "rm -rf /etc/mysql/conf.d/MGR.cnf"
ssh 121.201.125.74 "cp /root/double_master/double_master.cnf /etc/mysql/conf.d"

ssh 121.201.125.74 "service mysql restart"
service mysql restart

/root/double_master/reset_mm.sh

nohup /root/double_master/check.sh &
ssh 121.201.125.74 "service check start"