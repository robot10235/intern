

### 任务

mysql-8.0 或者以上，用云主机实现以下架构及功能：
1.单节点
  实现数据库的数据备份、恢复（指定时间点恢复）功能；
  可以指定全库（整个数据库所有表格）、单表（单个数据库指定表格）备份、恢复；
2.双节点
  部署两台云主机安装2台mysql，组成主-备架构；
  实现主-备架构（master-slave）：数据热备，主负责对外实现读写，备只能读；当主出现故障不可用是，备机切换成主，当旧的主恢复时变成备机，同时数据要及时同步；
  实现主-主架构（master-master）：数据热备，任意一台都能对外提供读写服务；当其中一台主宕机再恢复时，数据要及时同步；
3.三节点
  部署mysql官方的MGR（mysql group replication）高可用架构；
  验证MGR架构下，任意一台服务器宕机情况下，服务可用不中断；故障机器恢复时自动加入MGR集群同步数据一致性并可用



### 1.单节点

#### 备份流程

> 全量备份 or 增量备份
>
> > 若为全量备份
> >
> > 全部备份 or 部分备份
> >
> > >全部备份，直接备份
> > >
> > >部分备份，单库 or 单表？
> > >
> > >>单库，输入库名，备份
> > >>
> > >>单表，输入库名及表名，备份
> >
> > 增量备份
> >
> > >全部备份 or 部分备份
> > >
> > >>全部备份，输入basedir的文件名，备份
> > >>
> > >>部分备份
> > >>
> > >>部分备份，单库 or 单表？
> > >>
> > >>>单库，输入basedir文件名，库名，备份文件序号，备份
> > >>>
> > >>>单表，输入basedir文件名，库名，表名，备份文件序号，备份

全部备份的文件名均以时间戳命名，部分备份文件名均以database_table_no命名



##### `finalbackup.sh`

```sh
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
```



#### 恢复流程

> 全量备份 or 增量备份
>
> > 全量：输入备份文件名，--apply-log 准备恢复
> >
> > 增量：输入增量备份的basedir，并一个个输入所有的增量备份文件名，准备恢复
>
> 全部恢复 or 部分恢复
>
> > 全部：`copy-back`
> >
> > 部分：`cp -rf`



##### `finalrecover.sh`

```sh
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
   	cp /mysql_backup/$target/$db/* /var/lib/mysql -rf
      
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
```

关于部分备份有趣的现象：如果在/var/lib/mysql目录下删除数据库文件夹db内部的文件（例如删除表格文件`ta.ibd`/`ta.frm`），并且不重启mysql，select查询db.ta会发现数据仍然存在，但是重启mysql后就会消失，像是cache那样不读盘的操作



### 2.双节点

#### 基于gtid主从

实验主机ip：121.201.94.134 、121.201.135.74



##### 服务文件

###### `check.service`

```sh
[Unit]
Description=check the network of the other server
After=mysql.service

[Service]
Type=forking
ExecStart=/root/double_master/check.sh

[Install]
WantedBy=multi-user.target 
```



###### `reset.service`

```sh
[Unit]
Description=recover from down
After=mysql.service

[Service]
Type=forking
ExecStart=/root/double_master/recover.sh

[Install]
WantedBy=multi-user.target
```





##### 配置文件

###### `single_master.cnf`

```sh
[mysqld]
server_id=3
master_info_repository=TABLE
relay_log_info_repository=TABLE
gtid_mode=ON
enforce_gtid_consistency=ON
log-bin=mysql-bin
skip_slave_start=1
binlog_format=ROW
log_slave_updates=ON
```

注意server_id要不一样，log_slave_updates让从节点记录主节点的操作记录到binlog中，这对于主从切换是很重要的



##### 脚本文件

###### `set_user.sh`

创建复制用户

```sh
#!/bin/bash

mysql -uroot -p123456 -e"DELETE FROM mysql.user where user='ppl';" 2>/dev/null
mysql -uroot -p123456 -e"FLUSH PRIVILEGES;" 2>/dev/null
mysql -uroot -p123456 -e"CREATE USER 'ppl'@'%' IDENTIFIED BY '123456';" 2>/dev/null
mysql -uroot -p123456 -e"GRANT REPLICATION SLAVE ON *.* TO 'ppl'@'%';" 2>/dev/null
mysql -uroot -p123456 -e"FLUSH PRIVILEGES;" 2>/dev/null
```



###### `init_ms.sh`

初始化主从架构

```sh
#!/bin/bash
service check stop
ssh 121.201.94.134 "service check stop"

#create replication user
/root/single_master/set_user.sh
ssh 121.201.94.134 "/root/single_master/set_user.sh"

#set service
systemctl disable reset.service
systemctl disable check.service
rm -rf /lib/systemd/system/reset.service
rm -rf /lib/systemd/system/check.service
cp /root/single_master/reset.service /lib/systemd/system/
cp /root/single_master/check.service /lib/systemd/system/
systemctl daemon-reload
systemctl enable reset.service
systemctl enable check.service
ssh 121.201.94.134 "systemctl disable reset.service"
ssh 121.201.94.134 "systemctl disable check.service"
ssh 121.201.94.134 "rm -rf /lib/systemd/system/reset.service"
ssh 121.201.94.134 "rm -rf /lib/systemd/system/check.service"
ssh 121.201.94.134 "cp /root/single_master/reset.service /lib/systemd/system/"
ssh 121.201.94.134 "cp /root/single_master/check.service /lib/systemd/system/"
ssh 121.201.125.74 "systemctl daemon-reload"
ssh 121.201.94.134 "systemctl enable reset.service"
ssh 121.201.94.134 "systemctl enable check.service"

#set config
rm -rf /etc/mysql/conf.d/MGR.cnf
rm -rf /etc/mysql/conf.d/single_master.cnf
rm -rf /etc/mysql/conf.d/double_master.cnf
cp /root/single_master/single_master.cnf /etc/mysql/conf.d
ssh 121.201.94.134 "rm -rf /etc/mysql/conf.d/double_master.cnf"
ssh 121.201.94.134 "rm -rf /etc/mysql/conf.d/single_master.cnf"
ssh 121.201.94.134 "rm -rf /etc/mysql/conf.d/MGR.cnf"
ssh 121.201.94.134 "cp /root/single_master/single_master.cnf /etc/mysql/conf.d"

ssh 121.201.94.134 "service mysql restart"
service mysql restart

/root/single_master/reset_ms.sh
service check start
```

synchronize

###### `reset_ms.sh`

用于初始化主从架构，这里可以使用流备份，据说会快一点

```sh
#!/bin/bash

#backup the data of the master
#initialize bin log
ssh 121.201.125.74 "mysql -uroot -p123456 -e'reset master; stop slave; reset slave all;'"          
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

echo "121.201.125.74 is master"
#After the recovery, the other server should set the slave
#ssh 121.201.125.74 "/root/single_master/set_slave.sh"    
```



###### `set_slave.sh`

建立主从架构

```sh
#!/bin/bash

mysql -uroot -p123456 -e"CHANGE MASTER TO 
MASTER_HOST='121.201.125.74',
MASTER_USER='ppl',
MASTER_PASSWORD='123456',
MASTER_PORT=3306,
MASTER_AUTO_POSITION=1;
start slave; set global read_only=1;" 2>/dev/null
```



###### `check.sh`

检测其它节点的心跳，如果没有则取消主从

```sh
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
            s=`mysql -uroot -p123456 -e"show slave status\G" | grep -i "running" 2>/dev/null`
            state=`echo $s | awk -F: '{print $4}'`
            exp=" Slave has read all relay log; waiting for more updates"
            if [[ "$state" == " Slave has read all relay log; waiting for more updates" ]]
            then
                /root/single_master/reset_one_server.sh
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
```



`reset_one_server`

从机切换为主机

```sh
#!/bin/bash
echo "Now changing to one master..."
mysql -uroot -p123456 -e"set global read_only=0; stop slave; reset slave all;"
echo "sucess!"
```



#### 主从实验

##### 初始化主从

运行`init_ms.sh`，设置该节点为另一个节点的从

开始会设置好开机自启的服务，check用于检测主节点宕机，reset用于宕机重启后自动变为从

（脚本还会设置好MySQL配置文件等）

![image-20201229083854285](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229083854285.png)



然后是主从数据同步

主备份

![image-20201229084252623](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084252623.png)

备份压缩

![image-20201229084500520](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084500520.png)

发送备份给从

![image-20201229084552827](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084552827.png)

从解压及同步

![image-20201229084653526](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084653526.png)

输出为这个时成功

![image-20201229084723789](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084723789.png)

检查主从状态

![image-20201229084848683](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229084848683.png)



##### 故障转移

模拟121.201.94.134宕机后，观察121.201.125.74的状态

![image-20201228173711070](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201228173711070.png)



现在121.201.125.74变为主，并向其插入数据

![image-20201228173826548](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201228173826548.png)



重启121.201.94.134，建立主从成功

![image-20201228174131455](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201228174131455.png)

![image-20201229082434698](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229082434698.png)



查看121.201.125.74的数据，主从数据一致

![image-20201229082619826](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229082619826.png)





#### 基于gtid主主

nohup  /root/double_master/check.sh & 重启后进程就会结束



##### 服务文件

###### `check.service`

```sh
[Unit]
Description=check the network of the other server
After=mysql.service

[Service]
Type=forking
ExecStart=/root/double_master/check.sh

[Install]
WantedBy=multi-user.target 
```



###### `reset.service`

```sh
[Unit]
Description=recover from down
After=mysql.service

[Service]
Type=forking
ExecStart=/root/double_master/recover.sh

[Install]
WantedBy=multi-user.target
```



##### 配置文件

###### `double_master.cnf`

注意除了server_id不一样，auto_increment_offset也要不一样，设置auto_increment_increment为2，这样两个主节点奇偶自动增长，不会重复

```sh
[mysqld]
auto_increment_offset=2
auto_increment_increment=2  
server_id=2
master_info_repository=TABLE
relay_log_info_repository=TABLE
gtid_mode=ON
enforce_gtid_consistency=ON
log-bin=mysql-bin
skip_slave_start=1
binlog_format=ROW
log_slave_updates=ON
```



##### 脚本文件

`set_user.sh` `check.sh` `set_slave.sh` `reset_one_server.sh` 与主从基本相同（去掉了read only）

`reset_mm.sh` 增加了远程启动 `set_slave.sh`

`init_mm.sh` 启动check用了 `nohup  /root/double_master/check.sh &` ，这是因为service check start会阻塞终端输入命令，暂时没有想到方法结决。当然另一台主机也需要启动check（service check start）

###### `recover.sh`

`reset.service` 会调用这个脚本用于恢复主主架构

```sh
#!/bin/bash
/root/double_master/set_slave.sh
#if it is ms, do not ssh set slave
ssh 121.201.125.74 "/root/double_master/set_slave.sh"
```



#### 主主实验

##### 初始化主主

在121.201.94.134执行`init_mm.sh`后，输出如下即设置成功

![image-20201229113359806](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229113359806.png)

同时查看check以及双主的状态

![image-20201229113703760](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229113703760.png)



登录121.201.125.74观察check以及双主状态

![image-20201229113552526](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229113552526.png)





##### 故障转移

模拟121.201.125.74宕机，查看121.201.94.134的状态

![image-20201229115909076](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229115909076.png)

没有slave status的输出，这说明该节点reset slave all，已经变成单节点

对121.201.94.134的db.ta的数据进行修改

![image-20201229141339803](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229141339803.png)

重启121.201.125.74，检查其状态以及数据

![image-20201229141537332](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229141537332.png)

![image-20201229141615747](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229141615747.png)

再查看121.201.94.134的状态

![image-20201229141716982](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201229141716982.png)

主主恢复成功



### 3.三节点

https://dev.mysql.com/doc/refman/5.7/en/group-replication-configuring-instances.html

#### 配置文件

`MGR.CNF`

```sh
[mysqld]
server_id=3
gtid_mode=ON  
enforce_gtid_consistency=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog_checksum=NONE
log_slave_updates=ON
log_bin=binlog
binlog_format=ROW
relay_log_recovery=1
skip_slave_start=1

plugin_load_add='group_replication.so'
transaction_write_set_extraction=XXHASH64
loose-group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
loose-group_replication_start_on_boot=off
loose-group_replication_local_address="121.201.94.134:33061"
loose-group_replication_group_seeds="121.201.125.74:33061,121.201.94.134:33061,121.201.124.117:33061"
loose-group_replication_bootstrap_group=off
loose-group_replication_ip_whitelist="121.201.125.74,121.201.94.134,121.201.124.117"
```



#### 脚本文件

`set_user.sh` 与上面的相同

`init_MGR.sh`

初始化MGR（注意在初始化之前各节点的数据一致），分为主节点和从节点的脚本文件

主节点 121.201.134.117

```sh
#!/bin/bash

#create replication user
/root/MGR/set_user.sh

#set config
rm -rf /etc/mysql/conf.d/MGR.cnf
rm -rf /etc/mysql/conf.d/single_master.cnf
rm -rf /etc/mysql/conf.d/double_master.cnf
cp /root/MGR/MGR.cnf /etc/mysql/conf.d
service mysql restart

#initialize bin log
mysql -uroot -p123456 -e'reset master;' 2>/dev/null 

mysql -uroot -p123456 -e'CHANGE MASTER TO MASTER_USER='ppl', MASTER_PASSWORD='123456' FOR CHANNEL 'group_replication_recovery';' 2>/dev/null       
mysql -uroot -p123456 -e'SET GLOBAL group_replication_bootstrap_group=ON; START GROUP_REPLICATION; SET GLOBAL group_replication_bootstrap_group=OFF;' 2>/dev/null
```

从节点 121.201.125.74	121.201.94.134

 这里只同步了db这个数据库的数据

```sh
#!/bin/bash

#create replication user
/root/MGR/set_user.sh

#set config
rm -rf /etc/mysql/conf.d/MGR.cnf
rm -rf /etc/mysql/conf.d/single_master.cnf
rm -rf /etc/mysql/conf.d/double_master.cnf
cp /root/MGR/MGR.cnf /etc/mysql/conf.d
service mysql restart

#synchronize data
ssh 121.201.124.117 "mysql -uroot -p123456 -e'reset master;' 2>/dev/null"          
ssh 121.201.124.117 "innobackupex --user=root --password=123456 --databases='db' --no-timestamp /mysql_backup/tmp"
ssh 121.201.124.117 "cd /mysql_backup;tar czvf backup.tar tmp"
scp -r root@121.201.124.117:/mysql_backup/backup.tar /mysql_backup
ssh 121.201.124.117 "rm -rf /mysql_backup/tmp"
ssh 121.201.124.117 "rm -rf /mysql_backup/backup.tar"

#recover the data from master
service mysql stop
tar zxvf /mysql_backup/backup.tar -C /mysql_backup
innobackupex --apply-log /mysql_backup/tmp
cp /mysql_backup/tmp/db/* /var/lib/mysql/ -rf
rm -rf /mysql_backup/tmp
rm -rf /mysql_backup/backup.tar
chown -R mysql.mysql /var/lib/mysql
service mysql start

#initialize bin log
mysql -uroot -p123456 -e'reset master;reset slave;' 2>/dev/null 

mysql -uroot -p123456 -e"CHANGE MASTER TO MASTER_USER='ppl', MASTER_PASSWORD='123456' FOR CHANNEL 'group_replication_recovery';" 2>/dev/null       
mysql -uroot -p123456 -e'START GROUP_REPLICATION;' 2>/dev/null
```

先运行主节点的`init_MGR`脚本，再运行从节点的即可初始化MGR



查看各节点读写权限

121.201.124.117

![image-20201230082842771](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230082842771.png)

121.201.125.74

![image-20201230083007452](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230083007452.png)

121.201.94.134

![image-20201230082947985](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230082947985.png)

可知121.201.124.117为主节点，其余为从节点



#### MGR实验

##### 数据同步

在主节点上在`db.ta`中插入数据，并观察数据同步情况

主节点 121.201.124.117

![image-20201230140511461](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230140511461.png)

从节点 121.201.125.74

![image-20201230140558094](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230140558094.png)

121.201.94.134

![image-20201230140643401](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230140643401.png)





##### 从节点宕机

令从节点121.201.125.74停止mysql服务，并在主节点121.201.124.117上插入数据

121.201.125.74

![image-20201230141210791](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230141210791.png)

121.201.124.117

![image-20201230141323776](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230141323776.png)

可知从节点恢复成功



##### 主节点宕机

停止121.201.124.117的mysql服务，此时121.201.94.134成为主节点

在主节点上更改数据

![image-20201230141916172](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230141916172.png)

查看从节点121.201.125.74数据同步情况

![image-20201230142007420](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230142007420.png)



恢复旧主节点121.201.124.117的mysql服务，并查看数据同步情况以及主从情况

![image-20201230142229885](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230142229885.png)

现在121.201.124.117为从节点





#### 多主模式

1、多主模式启用需设置两个参数

```sh
group_replication_single_primary_mode=OFF #这个参数很好理解，就是关闭单master模式
group_replication_enforce_update_everywhere_checks=ON #这个参数设置多主模式下各个节点严格一致性检查
```

2、 默认启动的都是单master模式，其他节点都设置了read_only、super_read_only这两个参数，需要修改这两个配置
3、 完成上面的配置后就可以执行多点写入了，多点写入会存在冲突检查，这耗损性能挺大的，官方建议采用网络分区功能，在程序端把相同的业务定位到同一节点，尽量减少冲突发生几率。



##### 初始化

如果是要初始化为多主模式，就在配置文件中加入

```sh
group_replication_single_primary_mode=0 
group_replication_enforce_update_everywhere_checks=1
```



##### 切换

MGR切换模式需要重新启动组复制，因些需要在所有节点上先关闭组复制，设置 group_replication_single_primary_mode=OFF 等参数，再启动组复制

一主多从切换为多主

在所有节点输入

```mysql
# 停止组复制(所有节点执行)：
stop group_replication;
set global group_replication_single_primary_mode=OFF;
set global group_replication_enforce_update_everywhere_checks=ON;
```

```mysql
# 随便选择某个节点执行
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION; 
SET GLOBAL group_replication_bootstrap_group=OFF;
```

```mysql
# 其余节点执行
START GROUP_REPLICATION; 
```



检查各节点主从情况，如图

121.201.124.117

![image-20201230145512695](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230145512695.png)

121.201.125.74

![image-20201230145541190](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230145541190.png)

121.201.94.134

![image-20201230145608649](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201230145608649.png)

多主切换为一主多从将两个参数改了重启组复制即可。



### 参考

https://www.jianshu.com/p/87f66cdeb49c

https://blog.csdn.net/zhu19774279/article/details/49681767

https://www.percona.com/doc/percona-xtrabackup/2.4/innobackupex/partial_backups_innobackupex.html

https://dev.mysql.com/doc/refman/5.7/en/group-replication-user-credentials.html

http://blog.itpub.net/26736162/viewspace-2675139/
