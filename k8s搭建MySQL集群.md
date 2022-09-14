## k8s搭建MySQL集群



### k8s集群

搭建参考

https://www.runoob.com/docker/ubuntu-docker-install.html

https://www.cnblogs.com/xl2432/p/10931045.html

https://blog.csdn.net/cainiaoxiaozhang/article/details/105604415

https://zhuanlan.zhihu.com/p/78695894

https://kubernetes.io/zh/docs/tasks/run-application/run-replicated-stateful-application/

需要下载docker和k8s，要注意的是docker和k8s的版本需要兼容。

docker 版本：server & client  18.06.3-ce				k8s版本：1.13.12



### 下载docker

#### 卸载旧版本

Docker 的旧版本被称为 docker，docker.io 或 docker-engine 。如果已安装，请卸载它们：

```
$ sudo apt-get remove docker docker-engine docker.io containerd runc
```

当前称为 Docker Engine-Community 软件包 docker-ce 。

#### 使用 Docker 仓库进行安装

在新主机上首次安装 Docker Engine-Community 之前，需要设置 Docker 仓库。之后，您可以从仓库安装和更新 Docker 。

#### 设置仓库

更新 apt 包索引。

```shell
$ sudo apt-get update
```

安装 apt 依赖包，用于通过HTTPS来获取仓库:

```shell
$ sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common
```

添加 Docker 的官方 GPG 密钥：

```shell
$ curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
```

9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88 通过搜索指纹的后8个字符，验证您现在是否拥有带有指纹的密钥。

```shell
$ sudo apt-key fingerprint 0EBFCD88
```

> pub  rsa4096 2017-02-22 **[**SCEA**]**
>    9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
> uid      **[** unknown**]** Docker Release **(**CE deb**)** **<**docker**@**docker.com**>**
> sub  rsa4096 2017-02-22 **[**S**]**

使用以下指令设置稳定版仓库

```shell
$ sudo add-apt-repository \
  "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
 $(lsb_release -cs) \
 stable"
```



#### 安装 Docker Engine-Community

更新 apt 包索引。

```sh
$ sudo apt-get update
```

安装最新版本的 Docker Engine-Community 和 containerd ，或者转到下一步安装特定版本：

```sh
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

要安装特定版本的 Docker Engine-Community，请在仓库中列出可用版本，然后选择一种安装。列出您的仓库中可用的版本：

```sh
$ apt-cache madison docker-ce
```

>  docker-ce **|** 5:18.09.1~3-0~ubuntu-xenial **|** https:**//**mirrors.ustc.edu.cn**/**docker-ce**/**linux**/**ubuntu  xenial**/**stable amd64 Packages
>  docker-ce **|** 5:18.09.0~3-0~ubuntu-xenial **|** https:**//**mirrors.ustc.edu.cn**/**docker-ce**/**linux**/**ubuntu  xenial**/**stable amd64 Packages
>  docker-ce **|** 18.06.1~ce~3-0~ubuntu    **|** https:**//**mirrors.ustc.edu.cn**/**docker-ce**/**linux**/**ubuntu  xenial**/**stable amd64 Packages
>  docker-ce **|** 18.06.0~ce~3-0~ubuntu    **|** https:**//**mirrors.ustc.edu.cn**/**docker-ce**/**linux**/**ubuntu  xenial**/**stable amd64 Packages
>  ...

使用第二列中的版本字符串安装特定版本，例如 5:18.09.1~3-0~ubuntu-xenial。

```sh
$ sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io
```

测试 Docker 是否安装成功，输入以下指令，打印出以下信息则安装成功:

```sh
$ sudo docker run hello-world
```

> Unable to **find** image 'hello-world:latest' locally
> latest: Pulling from library**/**hello-world
> 1b930d010525: Pull **complete**                                                                  Digest: sha256:c3b4ada4687bbaa170745b3e4dd8ac3f194ca95b2d0518b417fb47e5879d9b5f
> Status: Downloaded newer image **for** hello-world:latest
>
>
> Hello from Docker**!**
> This message shows that your installation appears to be working correctly.
>
> To generate this message, Docker took the following steps:
>  \1. The Docker client contacted the Docker daemon.
>  \2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
>   **(**amd64**)**
>  \3. The Docker daemon created a new container from that image **which** runs the
>   executable that produces the output you are currently reading.
>  \4. The Docker daemon streamed that output to the Docker client, **which** sent it
>   to your terminal.
>
>
> To try something **more** ambitious, you can run an Ubuntu container with:
>  $ docker run -it ubuntu **bash**
>
>
> Share images, automate workflows, and **more** with a **free** Docker ID:
>  https:**//**hub.docker.com**/**
>
> For **more** examples and ideas, visit:
>  https:**//**docs.docker.com**/**get-started**/**





### 配置k8s

#### 关闭swap并关闭防火墙

首先，我们需要先关闭swap和防火墙,否则在安装Kubernetes时会导致不成功：

```sh
# 临时关闭
swapoff -a

# 编辑/etc/fstab，注释掉包含swap的那一行即可，重启后可永久关闭

ufw disable
```



#### 配置阿里源

```sh
sudo echo "deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
```

然后更新下：

```sh
sudo apt update
```

如果遇到以下问题：
![img](https://img2018.cnblogs.com/blog/1557897/201906/1557897-20190604143458387-1286091105.png)
可以记下提示的PUBKEY的最后8位，这里是BA07F4FB，然后执行：

```sh
gpg --keyserver keyserver.ubuntu.com --recv-keys BA07F4FB
gpg --export --armor BA07F4FB | sudo apt-key add -
sudo apt-get update
```



#### 安装组件

```sh
sudo apt install -y kubelet kubeadm kubectl	#可以像docker下载那样指定版本
sudo apt-mark hold kubelet kubeadm kubectl #确保不会被自动更新
```



#### 配置kubelet的cgroup drive

需要确保kubelet的cgroup drive在docker的一致。
分别可以通过以下命令查看：

```sh
docker info | grep -i cgroup

cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

若显示不一样，则添加或修改`Environment="KUBELET_CGROUP_ARGS=--cgroup-dirver=cgroupfs"`：

```sh
systemctl daemon-reload
systemctl restart kubelet
```



#### 启动kubelet

```sh
systemctl enable kubelet && systemctl start kubelet
```



#### 搭建k8s集群

```sh
kubeadm init --kubernetes-version=v1.13.12 --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address 192.168.0.102 --pod-network-cidr=10.244.0.0/16
```

注意

- pod-network-cidr: 选项--pod-network-cidr=10.0.0.0/24表示集群将使用网络的子网范围

- 选项--kubernetes-version=v1.14.2指定K8S版本,必须和前面导入的镜像一致

- 选项--apiserver-advertise-address表示绑定的网卡IP，这里是指定所用网络的网卡

- 若执行kubeadm init出错或强制终止，则再需要执行该命令时，需要先执行kubeadm reset重置、

在最后会提示要输入以下命令

```shell
mkdir -p $HOME/.kube 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



#### 配置cni

此时我们查看网络状态`kubectl get pod -n kube-system`，可以发现都处于Pending阻塞状态，我们需要配置网络，直接使用Calico

```sh
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
```

(注意这里也是有版本号的，如果不是很清楚是多少，可以直接访问官网获取最新的进行尝试：https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

过段时间，再执行`kubectl get pod -n kube-system`就会发现都处于running状态了

**master在k8s集群负责安排工作，大多数情况下是不会运行pod的**

将master设为工作节点

```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

执行成功时会显示

> node/xl-virtualbox untainted

对于mater至此配置成功，可以使用`kubectl get nodes`命令查看节点状态。当然目前只有一个master节点。



#### 工作节点加入

在主节点查看加入命令

```shell
kubeadm token create --print-join-command
```

对于普通的node节点，只需执行

```sh
kubeadm join 10.0.2.15:6443 --token zuhiop.bmxq2jofv1j68o9o \
    --discovery-token-ca-cert-hash sha256:b65ca09d1f18ef0af3ded2c831c609dfe48b19c5dc53a8398af5b735603828fb
```

就可以了

如果此时在master节点上使用`kubectl get nodes`查看节点的状态时'NotReady',请在对应主机上重启docker服务即可：

```
 systemctl restart docker
```

最后，可以看到两个节点都能正常工作了：
![img](https://img2018.cnblogs.com/blog/1557897/201905/1557897-20190527210816645-1937350784.png)





### 无状态实践：nginx静态网站搭建

创建一个单Pod的Nginx应用

```shell
kubectl create deployment nginx --image=nginx:alpine
```

扩容至两个pod

```sh
kubectl scale deployment nginx --replicas=2
```

为nginx添加服务，并开启nodeport进行外部访问

```sh
kubectl expose deployment nginx --port=80 --type=NodePort
```

查看外部访问端口

```sh
kubectl get svc
```



![image-20201224100446549](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201224100446549.png)



 在外部网络输入121.201.124.117:31336



![image-20201224100625202](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201224100625202.png)

静态网站搭建成功





### 有状态实践：MySQL集群搭建

#### mysql-pv.yaml

有状态需要持续卷，持续卷能保证pod在宕机恢复之后还能得到宕机前的数据

```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-mysql00
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data00"

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-mysql03
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data03"
```



#### mysql-secret.yaml

提供加密密码，根据base64加密

加密：`echo 'str' | base64`

解密：`echo 'str' | base64 --decode`

```yaml
apiVersion: v1
data:
  user-password: c2ltb25zdQ==
  root-password: c2ltb25zdS5tYWlsQGdtYWlsLmNvbQ==
kind: Secret
metadata:
  name: mysql-pass
  namespace: default
type: Opaque
```





#### mysql-configmap.yaml

用于修改MySQL各节点的配置文件，这里选择gtid的主从配置

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql
  labels:
    app: mysql
data:
  master.cnf: |
    # Apply this config only on the master.
    [mysqld]
    log-bin
    gtid_mode = on
    enforce_gtid_consistency = 1
    skip_slave_start=1
    binlog_format=row
  slave.cnf: |
    # Apply this config only on slaves.
    [mysqld]
    super-read-only
    gtid_mode = on
    enforce_gtid_consistency = 1
    skip_slave_start=1
    binlog_format=row
```



#### mysql-service.yaml

这个无头服务给 StatefulSet 控制器为集合中每个 Pod 创建的 DNS 条目提供了一个宿主。 因为服务名为 `mysql`，所以可以通过在同一 Kubernetes 集群和名字中的任何其他 Pod 内解析 `<Pod 名称>.mysql` 来访问 Pod。

客户端服务称为 `mysql-read`，是一种常规服务，具有其自己的集群 IP。 该集群 IP 在报告就绪的所有MySQL Pod 之间分配连接。 可能的端点集合包括 MySQL 主节点和所有从节点。

请注意，只有读查询才能使用负载平衡的客户端服务。 因为只有一个 MySQL 主服务器，所以客户端应直接连接到 MySQL 主服务器 Pod （通过其在无头服务中的 DNS 条目）以执行写入操作。

```yaml
# Headless service for stable DNS entries of StatefulSet members.
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  clusterIP: None
  selector:
    app: mysql
---
# Client service for connecting to any MySQL instance for reads.
# For writes, you must instead connect to the master: mysql-0.mysql.
apiVersion: v1
kind: Service
metadata:
  name: mysql-read
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  selector:
    app: mysql
```



#### mysql-statefulset.yaml

初始化时（init-mysql）给主从节点分配不同的配置文件

（clone-mysql）没有数据的新节点需要从上一个节点获得数据

（xtrabackup）从节点要连接主节点，每个节点给下一个节点提供数据同步服务（这是一个sidecar）

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  replicas: 2
  template:
    metadata:
      labels:
        app: mysql
    spec:
      initContainers:
      - name: init-mysql
        image: mysql:5.7
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Generate mysql server-id from pod ordinal index.
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          echo [mysqld] > /mnt/conf.d/server-id.cnf
          # Add an offset to avoid reserved server-id=0 value.
          echo server-id=$((100 + $ordinal)) >> /mnt/conf.d/server-id.cnf
          # Copy appropriate conf.d files from config-map to emptyDir.
          if [[ $ordinal -eq 0 ]]; then
            cp /mnt/config-map/master.cnf /mnt/conf.d/
          else
            cp /mnt/config-map/slave.cnf /mnt/conf.d/
          fi                                                
        volumeMounts:
        - name: conf
          mountPath: /mnt/conf.d
        - name: config-map
          mountPath: /mnt/config-map
      - name: clone-mysql
        image: docker.io/selefantic/dockerlibraryk8s-xtrabackup:latest
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Skip the clone if data already exists.
          [[ -d /var/lib/mysql/mysql ]] && exit 0
          # Skip the clone on master (ordinal index 0).
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          [[ $ordinal -eq 0 ]] && exit 0
          # Clone data from previous peer.
          ncat --recv-only mysql-$(($ordinal-1)).mysql 3307 | xbstream -x -C /var/lib/mysql
          # Prepare the backup.
          xtrabackup --prepare --target-dir=/var/lib/mysql
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: root-password
        ports:
        - name: mysql
          containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
        livenessProbe:
          exec:
            command: #["mysqladmin", "-uroot", "-p$MYSQL_ROOT_PASSWORD", "ping"]
            command: 
            - /bin/sh
            - -ec
            - >-
              mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD ping 2>/dev/null
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            # Check we can execute queries over TCP (skip-networking is off).
            command: 
            - /bin/sh
            - -ec
            - >-
              mysql -uroot -p$MYSQL_ROOT_PASSWORD -e'SELECT 1' 2>/dev/null
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 1
      - name: xtrabackup
        image: docker.io/selefantic/dockerlibraryk8s-xtrabackup:latest
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-pass
              key: root-password
        ports:
        - name: xtrabackup
          containerPort: 3307
        command:
        - bash
        - "-c"
        - |
          set -ex
          cd /var/lib/mysql

          # Determine binlog position of cloned data, if any.
          #if [[ -f xtrabackup_slave_info && "x$(<xtrabackup_slave_info)" != "x" ]]; then
            # XtraBackup already generated a partial "CHANGE MASTER TO" query
            # because we're cloning from an existing slave. (Need to remove the tailing semicolon!)
            #cat xtrabackup_slave_info | sed -E 's/;$//g' > change_master_to.sql.in
            # Ignore xtrabackup_binlog_info in this case (it's useless).
            #rm -f xtrabackup_slave_info xtrabackup_binlog_info
          #elif [[ -f xtrabackup_binlog_info ]]; then
            # We're cloning directly from master. Parse binlog position.
            #[[ `cat xtrabackup_binlog_info` =~ ^(.*?)[[:space:]]+(.*?)$ ]] || exit 1
            #rm -f xtrabackup_binlog_info xtrabackup_slave_info
            #echo "CHANGE MASTER TO MASTER_LOG_FILE='${BASH_REMATCH[1]}',\
            #      MASTER_LOG_POS=${BASH_REMATCH[2]}" > change_master_to.sql.in
          #fi

          # Check if we need to complete a clone by starting replication.
          #if [[ -f change_master_to.sql.in ]]; then
          #  echo "Waiting for mysqld to be ready (accepting connections)"
          #  until mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"; do sleep 1; done
          
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          if [[ $ordinal -ne 0 ]]; then
            echo "Initializing replication from clone position"
            mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD \
                  -e "CHANGE MASTER TO \
                          MASTER_HOST='mysql-0.mysql', \
                          MASTER_USER='root', \
                          MASTER_PASSWORD='$MYSQL_ROOT_PASSWORD', \
                          MASTER_PORT=3306,
                          MASTER_AUTO_POSITION=1;
                          START SLAVE;" || exit 1
          fi
            # In case of container restart, attempt this at-most-once.

          # Start a server to send backups when requested by peers.
          exec ncat --listen --keep-open --send-only --max-conns=1 3307 -c \
            "xtrabackup --backup --slave-info --stream=xbstream --host=127.0.0.1 --user=root --password=$MYSQL_ROOT_PASSWORD"
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi
```

问题：在官方文件中，从节点只会在slave_info或binlog_info存在时才会连接主节点，而这两个文件存在是在从节点开始无数据的情况，经过xtrabackup备份恢复得到。如果是在从节点有数据宕机恢复后的情况下，就不会change master to了，那么就没有主从架构了？

搭建MySQL集群

```sh
kubectl apply -f /root/k8s_mysql/mysql-pv.yaml
kubectl apply -f /root/k8s_mysql/mysql-secret.yaml
kubectl apply -f /root/k8s_mysql/mysql-configmap.yaml
kubectl apply -f /root/k8s_mysql/mysql-service.yaml
kubectl apply -f /root/k8s_mysql/mysql-statefulset.yaml
```





#### 发送客户端请求

可以通过运行带有 `mysql:5.7` 镜像的临时容器并运行 `mysql` 客户端二进制文件， 将测试查询发送到 MySQL 主服务器（主机名 `mysql-0.mysql`）。

```shell
kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello');
EOF
```

使用主机名 `mysql-read` 将测试查询发送到任何报告为就绪的服务器：

```shell
kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never --\
  mysql -h mysql-read -e "SELECT * FROM test.messages"
```

相似的实验结果如下

![image-20201225083350369](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225083350369.png)





#### 可用性实验

在mysql-1中查看数据以及主从情况

![image-20201225083842964](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225083842964.png)



现删除pod mysql-1，模拟从节点宕机情况，同时在主节点插入数据

![image-20201225084353123](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225084353123.png)

查看mysql-1的数据以及主从情况，恢复主从成功

![image-20201225084448696](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225084448696.png)



如果主节点宕机，那么需要等待主节点恢复才能在更改数据（read-only）。



对外服务（暂时没想到）

目前我用的是navicat的ssh来进入集群内部的虚拟ip连接。

有些博客说sts不能对外暴露服务

nodeport暴露mysql-0这个pod可以

![image-20201225163328832](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225163328832.png)

而且如果mysql-0宕机后恢复，nodeport仍可行

![image-20201225163205412](C:\Users\28562\AppData\Roaming\Typora\typora-user-images\image-20201225163205412.png)



之前用port-forward但只能在本地连接转发端口，解决方法：nat

