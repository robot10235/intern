主从

/lib/systemd/system

check.service

```shell
[Unit]
Description=check the network of the other server
After=mysql.service									#在mysql服务启动后再启动检测服务

[Service]
Type=forking
ExecStart=/root/double_master/check.sh				#运行路径
KillMode=none										#长期运行

[Install]
WantedBy=multi-user.target 
```



reset.service

```shell
[Unit]
Description=recover from down
After=mysql.service

[Service]
Type=forking
ExecStart=/root/double_master/recover.sh

[Install]
WantedBy=multi-user.target
```



init.mm为初始化双主，修改配置文件（如果是单主则将single_master.cnf放入/etc/mysql/conf.d中 ），并开启reset_two_master.sh，reset_two_master.sh可以将自己的数据与另一台主机数据一致（xtrabackup ssh），然后本机以及另一台机set_slave构建主主（如果是主从可以不用将远程change master）

check服务检测主节点的心跳，如果没有信号，且Slave has read all relay log;，说明本节点可以变为单主机（reset_one_master.sh），如果从节点没有读完所有的relay log，则需要等待至读完才能变单主机（这里跟主主一样）

主节点重启后会自动启动reset服务，recover.sh会终止主节点的slave的状态，然后set_slave.sh将其设为原从节点的slave。（主主需要ssh set_slave.sh）

set_slave就是reset slave然后再change master to，slave会从主的bin-log中读到relay-log然后executed，因此不需要备份恢复



提升的地方：使用流备份，这样初始化会快，



https://www.jianshu.com/p/caae9a019dbd
