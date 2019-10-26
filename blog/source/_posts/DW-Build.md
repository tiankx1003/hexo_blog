---
title: 数仓环境搭建
tags:
  - BigData
  - Data-Warehouse
  - Linux
---

### CentOS 6.8 minimal

```bash
yum install -y vim tar rsync openssh openssh-clients libaio net-tools
```

```bash
#设置IP 主机名 hosts 关闭防火墙
service iptables stop
chkconfig iptables off
vim /etc/hosts
```
```host
192.168.2.100 hadoop100
192.168.2.102 hadoop102
192.168.2.103 hadoop103
192.168.2.104 hadoop104
192.168.2.104 hadoop104
192.168.2.105 hadoop105
192.168.2.106 hadoop106
```
```bash
###新建用户授权
useradd tian
passwd tian
vim /etc/sudoer
#tian ALL=(ALL)    NOPASSWD:ALL
```
```bash
sudo mkdir /opt/module
sudo mkdir /opt/software
#安装软件配置环境变量
sudo chown tian:tian /opt/module/ /opt/software -R
```
```bash
#编写同步脚本和免密连接配置文件
vim /home/tian/bin/xsync
vim /home/tian/bin/copy-ssh
vim /home/tian/bin/xcall
```
```sh
#!/bin/bash
pcount=$#
if ((pcount==0)); then
echo no args;
exit;
fi
p1=$1
fname=`basename $p1`
echo fname=$fname
pdir=`cd -P $(dirname $p1); pwd`
echo pdir=$pdir
user=`whoami`
for((host=102; host<104; host++)); 
do
	echo "\033[31m ------------ hadoop$host ------------ \033[0m"
	rsync -av $pdir/$fname $user@hadoop$host:$pdir
done
```
```sh
#!/bin/bash
ssh-keygen
for i in hadoop102 hadoop103 hadoop104
do
    echo "\033[31m ======== $i ======== \033[0m"
    ssh-copy-id $i
done
```
```sh
#! /bin/bash
# xcall jps
for i in hadoop102 hadoop103 hadoop104
do
        echo -e "\033[31m ---------- $i ---------- \033[0m"
        ssh $i "$*"
done
```

```bash
# Clone Server
vim /etc/udev/rules.d/70-persistent-net.rules
vim /etc/sysconfig/network-scripts/ifcfg-eth0
vim /etc/sysconfig/network #修改主机名
```
*配置多个节点之间的免密连接*

### Hadoop


```bash
vim core-site.xml
vim hdfs-site.xml
vi yarn-site.xml 
cp mapred-site.xml.template mapred-site.xml
vim mapred-site.xml

vim /opt/module/hadoop-2.7.2/etc/hadoop/slaves
```

```xml
<!-- core-site.xml -->
<property>
	<name>fs.defaultFS</name>
	<value>hdfs://hadoop102:9000</value>
</property>
<property>
	<name>hadoop.tmp.dir</name>
	<value>/opt/module/hadoop-2.7.2/data/tmp</value>
</property>
```
```xml
<!-- hdfs-site.xml -->
<property>
	<name>dfs.replication</name>
	<value>3</value>
</property>
<property>
	<name>dfs.namenode.secondary.http-address</name>
	<value>hadoop104:50090</value>
</property>
```
```xml
<!-- yarn-site.xml  -->
<property>
	<name>yarn.nodemanager.aux-services</name>
	<value>mapreduce_shuffle</value>
</property>
<property>
	<name>yarn.resourcemanager.hostname</name>
	<value>hadoop103</value>
</property>
<!-- 配置日志聚集 -->
<property>
	<name>yarn.log-aggregation-enable</name>
	<value>true</value>
</property>
<property>
	<name>yarn.log-aggregation.retain-seconds</name>
	<value>604800</value>
</property>
```
```xml
<!-- mapred-site.xml -->
<property>
	<name>mapreduce.framework.name</name>
	<value>yarn</value>
</property>
<!-- 配置历史服务器 -->
<property>
	<name>mapreduce.jobhistory.address</name>
	<value>hadoop102:10020</value>
</property>
<property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>hadoop102:19888</value>
</property>
```

```
hadoop102
hadoop103
hadoop104
```
* 该文件中添加的内容结尾不允许有空格，文件中不允许有空行
* 集群上分发配置

**群起集群**

```bash
#第一次启动集群时需要格式化namenode
bin/hdfs namenode -format #102
#启动HDFS
sbin/start-dfs.sh #102
#启动历史服务器
sbin/mr-jobhistory-daemon.sh start historyserver
#启动YARN
sbin/start-yarn.sh #103
jpsall #查看所有进程
```
[Web端查看SecondaryNameNode](http://hadoop104:50090/status.html).
[web端查看HDFS文件系统](http://tian:50070/dfshealth.html#tab-overview)
[Web页面查看YARN](http://hadoop103:8088/cluster)
[查看JobHistory](http://hadoop102:19888/jobhistory)
[Web查看日志](http://hadoop103:19888/jobhistory)

### Zookeeper

**安装部署**
```bash
tar -zxvf zookeeper-3.4.10.tar.gz -C /opt/module/
### 配置服务器编号
mkdir -p zkData
vi myid # 在文件中添加与server对应的编号：
xsync myid # 并分别在hadoop102、hadoop103上修改myid
mv zoo_sample.cfg zoo.cfg
vim zoo.cfg
xsync zoo.cfg
```
```conf
# 修改数据存储路径配置
dataDir=/opt/module/zookeeper/zkData
# 增加如下配置
#######################cluster##########################
server.1=hadoop102:2888:3888
server.2=hadoop103:2888:3888
server.3=hadoop104:2888:3888
```

**启停测试**
```bash
bin/zkServer.sh start
jps
# QuorumPeerMain
bin/zkServer.sh status
bin/zkCli.sh
quit
bin/zkServer.sh stop
```

### Flume

```bash
tar -zxvf apache-flume-1.7.0-bin.tar.gz -C ../module/
mv apache-flume-1.7.0-bin flume
mv flume-env.sh.template flume-env.sh
vim flume-env.sh
# export JAVA_HOME=/opt/module/jdk1.8.0_144
```

### Kafka

```bash
tar -zxvf kafka_2.11-0.11.0.0.tgz -C /opt/module/
mv kafka_2.11-0.11.0.0/ kafka
mkdir logs
cd config/
vim server.properties
xsync /opt/module/kafka/ # 分发后配置其他节点环境变量
# 修改其他节点server.properties中的brokerid为1和2
```

```properties
#broker的全局唯一编号，不能重复
broker.id=0
#删除topic功能使能
delete.topic.enable=true
#处理网络请求的线程数量
num.network.threads=3
#用来处理磁盘IO的现成数量
num.io.threads=8
#发送套接字的缓冲区大小
socket.send.buffer.bytes=102400
#接收套接字的缓冲区大小
socket.receive.buffer.bytes=102400
#请求套接字的缓冲区大小
socket.request.max.bytes=104857600
#kafka运行日志存放的路径	
log.dirs=/opt/module/kafka/logs
#topic在当前broker上的分区个数
num.partitions=1
#用来恢复和清理data下数据的线程数量
num.recovery.threads.per.data.dir=1
#segment文件保留的最长时间，超时将被删除
log.retention.hours=168
#配置连接Zookeeper集群地址
zookeeper.connect=hadoop102:2181,hadoop103:2181,hadoop104:2181
```
**启停测试**
```bash
# 启动集群，先开zookeeper
kafka-server-start.sh -daemon config/server.properties # 在每个节点执行
# 关闭集群，先关zookeeper
kafka-server-stop.sh # 在每个节点执行
```

### HBase

```bash
# 启动zk hadoop
tar -zxvf hbase-1.3.1-bin.tar.gz -C /opt/module
vim hbase-env.sh
vim hbase-site.xml
vim regionservers
mv hbase-1.3.1/ hbase/
# 软链接hadoop配置文件到hbase,每个节点配置了hadoop环境变量可以省略这一步
ln -s /opt/module/hadoop-2.7.2/etc/hadoop/core-site.xml /opt/module/hbase/conf/core-site.xml
ln -s /opt/module/hadoop-2.7.2/etc/hadoop/hdfs-site.xml /opt/module/hbase/conf/hdfs-site.xml
xsync /opt/module/hbase/ # 分发配置
# 启停
hbase-daemon.sh start master
hbase-daemon.sh start regionserver
start-hbase.sh # 启动方法二
stop-hbase.sh
hbase shell # 启动交互
```

```properties
export JAVA_HOME=/opt/module/jdk1.8.0_144
export HBASE_MANAGES_ZK=false
```

```xml
<configuration>
	<property>     
		<name>hbase.rootdir</name>     
		<value>hdfs://hadoop102:9000/hbase</value>   
	</property>

	<property>   
		<name>hbase.cluster.distributed</name>
		<value>true</value>
	</property>

   <!-- 0.98后的新变动，之前版本没有.port,默认端口为60000 -->
	<property>
		<name>hbase.master.port</name>
		<value>16000</value>
	</property>

	<property>   
		<name>hbase.zookeeper.quorum</name>
	     <value>hadoop102,hadoop103,hadoop104</value>
	</property>

	<property>   
		<name>hbase.zookeeper.property.dataDir</name>
	     <value>/opt/module/zookeeper/zkData</value>
	</property>
</configuration>
```

```
hadoop102
hadoop103
hadoop104
```

[hbase页面](http://hadoop102:16010)

### Redis

```bash
tar -zcvf file.tar.gz -C /opt/module #解压
yum -y install gcc-c++ #安装gcc编译器
make #编译
make install #安装在/usr/local/bin
vim /etc/profile #配置环境变量
```

```properties
bind 192.168.2.102
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
save 900 1 
save 300 10
save 60 10000
```

### MySQL

```bash
rpm -qa|grep mysql #查看当前mysql的安装情况
sudo rpm -e --nodeps mysql-libs-5.1.73-8.el6_8.x86_64 #卸载之前的mysql
sudo rpm -ivh MySQL-client-5.6.24-1.el6.x86_64.rpm #在包所在的目录中安装
sudo rpm -ivh MySQL-server-5.6.24-1.el6.x86_64.rpm
mysqladmin --version #查看mysql版本
rpm -qa|grep MySQL #查看mysql是否安装完成
sudo service mysql restart # 重启服务
cat /root/.mysql_secret
mysqladmin -u root password #设置密码,需要先启动服务
```
```sql
# 修改密码
SET PASSWORD=PASSWORD('root');
## MySQL在user表中主机配置
show databases;
use mysql;
show tables;
desc user;
select User, Host, Password from user;
# 修改user表，把Host表内容修改为%
update user set host='%' where host='localhost';
# 删除root中的其他账户
delete from user where Host='hadoop101';
delete from user where Host='127.0.0.1';
delete from user where Host='::1';
# 刷新
flush privileges;
\q;
```

### MySQL HA

 * 如果Hive元数据配置到了MySQL，需要更改hive-site.xml中javax.jdo.option.ConnectionURL为虚拟ip

**一主一从**
| hadoop102 | hadoop103 | hadoop104 |
| :-------- | :-------- | :-------- |
| Master    | Slave     |           |

```bash
# 修改hadoop102中MySQL的/usr/my.cnf配置文件
sudo vim /usr/my.cnf 
sudo service mysql restart
mysql -uroot -proot
```
```properties
[mysqld]
#开启binlog
log_bin = mysql-bin
#MySQL服务器唯一id
server_id = 1
```
```sql
show master status
```

```bash
# 修改hadoop103中MySQL的/usr/my.cnf配置文件
sudo vim /usr/my.cnf
sudo service mysql restart
mysql -uroot -proot
```
```properties
[mysqld]
#MySQL服务器唯一id
server_id = 2
#开启slave中继日志
relay-log=mysql-relay
```
```sql
CHANGE MASTER TO 
MASTER_HOST='hadoop102',
MASTER_USER='root',
MASTER_PASSWORD='root',
MASTER_LOG_FILE='mysql-bin.000001',
MASTER_LOG_POS=120; -- 根据position设置
start slave;
show slave status \G;
```
**双主**
| hadoop102     | hadoop103     | hadoop104 |
| :------------ | :------------ | :-------- |
| Master(Slave) | Slave(Master) |           |

```bash
# hadoop102
sudo vim /usr/my.cnf
sudo service mysql restart
mysql -uroot -proot
# show master status;
```
```properties
[mysqld]

#开启binlog
log_bin = mysql-bin
#MySQL服务器唯一id
server_id = 2
#开启slave中继日志
relay-log=mysql-relay
```
```bash
# hadoop103
sudo vim /usr/my.cnf
sudo service mysql restart
mysql -uroot -proot
```
```properties
[mysqld]
#MySQL服务器唯一id
server_id = 1

#开启binlog
log_bin = mysql-bin

#开启slave中继日志
relay-log=mysql-relay
```
```sql
CHANGE MASTER TO 
MASTER_HOST='hadoop102',
MASTER_USER='root',
MASTER_PASSWORD='root',
MASTER_LOG_FILE='mysql-bin.000001',
MASTER_LOG_POS=107;
```
**两个节点安装配置Keepalived**

 * hadoop102

```bash
sudo yum install -y keepalived
sudo chkconfig keepalived on
sudo vim /etc/keepalived/keepalived.conf
sudo vim /var/lib/mysql/keepalived.sh
sudo keepalived start
```
```properties
! Configuration File for keepalived
global_defs {
    router_id MySQL-ha
}
vrrp_instance VI_1 {
    state master #初始状态
    interface eth0 #网卡
    virtual_router_id 51 #虚拟路由id
    priority 100 #优先级
    advert_int 1 #Keepalived心跳间隔
    nopreempt #只在高优先级配置，原master恢复之后不重新上位
    authentication {
        auth_type PASS #认证相关
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.1.100 #虚拟ip
    }
} 

#声明虚拟服务器
virtual_server 192.168.2.100 3306 {
    delay_loop 6
    persistence_timeout 30
    protocol TCP
    #声明真实服务器
    real_server 192.168.2.102 3306 {
        notify_down /var/lib/mysql/killkeepalived.sh #真实服务故障后调用脚本
        TCP_CHECK {
            connect_timeout 3 #超时时间
            nb_get_retry 1 #重试次数
            delay_before_retry 1 #重试时间间隔
        }
    }
}
```
```sh
#!/bin/bash
sudo service keepalived stop
```

 * hadoop103

```bash
sudo yum install -y keepalived
sudo chkconfig keepalived on
sudo vim /etc/keepalived/keepalived.conf
sudo vim /var/lib/mysql/killkeepalived.sh
sudo service keepalived start
```
```conf
! Configuration File for keepalived
global_defs {
    router_id MySQL-ha
}
vrrp_instance VI_1 {
    state master #初始状态
    interface eth0 #网卡
    virtual_router_id 51 #虚拟路由id
    priority 100 #优先级
    advert_int 1 #Keepalived心跳间隔
    nopreempt #只在高优先级配置，原master恢复之后不重新上位
    authentication {
        auth_type PASS #认证相关
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.2.100 #虚拟ip
    }
} 

#声明虚拟服务器
virtual_server 192.168.1.100 3306 {
    delay_loop 6
    persistence_timeout 30
    protocol TCP
    #声明真实服务器
    real_server 192.168.2.103 3306 {
        notify_down /var/lib/mysql/killkeepalived.sh #真实服务故障后调用脚本
        TCP_CHECK {
            connect_timeout 3 #超时时间
            nb_get_retry 1 #重试次数
            delay_before_retry 1 #重试时间间隔
        }
    }
}
```
```sh
#! /bin/bash
sudo service keepalived stop
```

### Hive

```bash
tar -zxvf apache-hive-1.2.1-bin.tar.gz -C /opt/module/
mv apache-hive-1.2.1-bin/ hive
mv hive-env.sh.template hive-env.sh
# export HADOOP_HOME=/opt/module/hadoop-2.7.2
# export HIVE_CONF_DIR=/opt/module/hive/conf

# 在HDFS上创建/tmp和/user/hive/warehouse两个目录并修改他们的同组权限可写
bin/hadoop fs -mkdir /tmp
bin/hadoop fs -mkdir -p /user/hive/warehouse
bin/hadoop fs -chmod g+w /tmp
bin/hadoop fs -chmod g+w /user/hive/warehouse
```

**Hive元数据配置到MySQL**
 * 如果MySQL配置了HA，需要更改hive-site.xml中javax.jdo.option.ConnectionURL为虚拟ip

```bash
# 拷贝驱动
tar -zxvf mysql-connector-java-5.1.27.tar.gz
cp mysql-connector-java-5.1.27-bin.jar /opt/module/hive/lib/
```
```bash
# 配置Metastore到MySQL
# /opt/module/hive/conf目录下创建一个hive-site.xml
touch hive-site.xml
vi hive-site.xml
pwd
mv hive-log4j.properties.template hive-log4j.properties
vim hive-log4j.properties
# hive.log.dir=/opt/module/hive/logs
```

根据官方文档配置参数
[官方文档参数](https://cwiki.apache.org/confluence/display/Hive/AdminManual+MetastoreAdmin)
[**hive-site.xml**](../../Configuration/Hive/hive-site.xml)

```bash
hiveserver2
beeline
# !connect jdbc:hive2://hadoop102:10000
```

### Tez

```bash
tar -zxvf apache-tez-0.9.1-bin.tar.gz -C /opt/module/
mv apache-tez-0.9.1-bin/ tez-0.9.1
# Hive配置Tez
vim hive-env.sh
vim hive-site.xml
```
```properties
# Set HADOOP_HOME to point to a specific hadoop install directory
export HADOOP_HOME=/opt/module/hadoop-2.7.2

# Hive Configuration Directory can be controlled by:
export HIVE_CONF_DIR=/opt/module/hive/conf

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
export TEZ_HOME=/opt/module/tez-0.9.1    #是你的tez的解压目录
export TEZ_JARS=""
for jar in `ls $TEZ_HOME |grep jar`; do
    export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/$jar
done
for jar in `ls $TEZ_HOME/lib`; do
    export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/lib/$jar
done

export HIVE_AUX_JARS_PATH=/opt/module/hadoop-2.7.2/share/hadoop/common/hadoop-lzo-0.4.20.jar$TEZ_JARS
```
```xml
	<property>
		<name>hive.execution.engine</name>
		<value>tez</value>
	</property>
```
/opt/module/hive/conf目录下添加[**tez-site.xml**](../../Configuration/tez-site.xml)
```bash
vim $HADOOP_HOME/etc/hadoop/yarn-site.xml
```
```xml
<!-- 关闭内存检查防止杀进程 -->
<property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
</property>
```
```bash
# 上传tez到HDFS
hadoop fs -mkdir /tez
hadoop fs -put /opt/module/tez-0.9.1/ /tez
hadoop fs -ls /tez /tez/tez-0.9.1
# 启动hive测试
hive
```
```sql
create table student(
id int,
name string);
insert into student values(1,"lisi");
select * from student;
```


### Spark


```bash
tar -zxvf spark-2.1.1-bin-hadoop2.7.tgz -C /opt/module/
mv spark-2.1.1-bin-hadoop2.7 spark-local
# 官方迭代求π案例
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--executor-memory 1G \
--total-executor-cores 2 \
./examples/jars/spark-examples_2.11-2.1.1.jar \
100
# 另一种写法
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master local[2] \
./examples/jars/spark-examples_2.11-2.1.1.jar 100
# zsh需要把local[2]加上引号:'local[2]'
# 快捷方式
bin/run-example SparkPi 100
```


### ElasticSearch





### Canal



### Phoenix



### Flink

```bash
tar -zxvf flink-1.7.2-bin-hadoop27-scala_2.11.tgz ../module
vim conf/flink-conf.yaml
vim conf/slave
```

```properties
jpbmanager.rpc.address: hadoop102
```

```
hadoop102
hadoop103
hadoop104
```

[Flink Web页面](http://localhost:8081)

### Sqoop


```bash
tar -zxf sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz -C /opt/module/
mv sqoop-1.4.6.bin__hadoop-2.0.4-alpha/ sqoop/
vim /etc/profile
source /etc/profile # 配置环境变量
mv sqoop-env-template.sh sqoop-env.sh
vim sqoop-env.sh # 添加下述配置
# 拷贝MySQL驱动到lib
cp mysql-connector-java-5.1.27-bin.jar /opt/module/sqoop/lib/
```
```
export HADOOP_COMMON_HOME=/opt/module/hadoop-2.7.2
export HADOOP_MAPRED_HOME=/opt/module/hadoop-2.7.2
export HIVE_HOME=/opt/module/hive
export ZOOKEEPER_HOME=/opt/module/zookeeper
export ZOOCFGDIR=/opt/module/zookeeper/conf
export HBASE_HOME=/opt/module/hbase
```
```bash
# 验证Sqoop
bin/sqoop help
# Available commands:
#   codegen            Generate code to interact with database records
#   create-hive-table     Import a table definition into Hive
#   eval               Evaluate a SQL statement and display the results
#   export             Export an HDFS directory to a database table
#   help               List available commands
#   import             Import a table from a database to HDFS
#   import-all-tables     Import tables from a database to HDFS
#   import-mainframe    Import datasets from a mainframe server to HDFS
#   job                Work with saved jobs
#   list-databases        List available databases on a server
#   list-tables           List available tables in a database
#   merge              Merge results of incremental imports
#   metastore           Run a standalone Sqoop metastore
#   version            Display version information
```
```bash
# 测试Sqoop是否能够成功连接数据库
bin/sqoop list-databases --connect jdbc:mysql://hadoop102:3306/ --username root --password root
# information_schema
# metastore
# mysql
# oozie
# performance_schema
```


### Azkaban


[==**下载地址**==](http://azkaban.github.io/downloads.html)

```bash
mkdir /opt/module/azkaban
tar -zxvf azkaban-web-server-2.5.0.tar.gz -C /opt/module/azkaban/
tar -zxvf azkaban-executor-server-2.5.0.tar.gz -C /opt/module/azkaban/
tar -zxvf azkaban-sql-script-2.5.0.tar.gz -C /opt/module/azkaban/
mv azkaban-web-2.5.0/ server
mv azkaban-executor-2.5.0/ executor
mysql -uroot -proot # 建表
keytool -keystore keystore -alias jetty -genkey -keyalg RSA # 生成密钥和整数
tzselect # 同步时间
```

```sql
create database azkaban;
use azkaban;
source /opt/module/azkaban/azkaban-2.5.0/create-all-sql-2.5.0.sql;
```

```bash
# Web Server 配置
vim /opt/module/azkaban/server/conf/azkaban.properties
vim /opt/module/azkaban/server/conf/azkaban-users.xml
```

```properties
#默认web server存放web文件的目录
web.resource.dir=/opt/module/azkaban/server/web/
#默认时区,已改为亚洲/上海 默认为美国
default.timezone.id=Asia/Shanghai
#用户权限管理默认类（绝对路径）
user.manager.xml.file=/opt/module/azkaban/server/conf/azkaban-users.xml
#global配置文件所在位置（绝对路径）
executor.global.properties=/opt/module/azkaban/executor/conf/global.properties
#数据库连接IP
mysql.host=hadoop101
#数据库用户名
mysql.user=root
#数据库密码
mysql.password=000000
#SSL文件名（绝对路径）
jetty.keystore=/opt/module/azkaban/server/keystore
#SSL文件密码
jetty.password=000000
#Jetty主密码与keystore文件相同
jetty.keypassword=000000
#SSL文件名（绝对路径）
jetty.truststore=/opt/module/azkaban/server/keystore
#SSL文件密码
jetty.trustpassword=000000
# mial settings
mail.sender=Tiankx1003@gmial.com
mail.host= stmp.gmail.com
mail.user=Tiankx1003@gmail.com
mail.password=Tt181024
# web 配置
job.failure.email= 
# web 配置
joa.success.email= 
```

```xml
<azkaban-users>
	<user username="azkaban" password="azkaban" roles="admin" groups="azkaban" />
	<user username="metrics" password="metrics" roles="metrics"/>
	<user username="admin" password="admin" roles="admin,metrics"/>
	<role name="admin" permissions="ADMIN" />
	<role name="metrics" permissions="METRICS"/>
</azkaban-users>
```

```bash
# Executor Server 配置
vim /opt/module/azkaban/server/conf/azkaban.properties
```

```properties
#时区
default.timezone.id=Asia/Shanghai
executor.global.properties=/opt/module/azkaban/executor/conf/global.properties
mysql.host=hadoop101
mysql.database=azkaban
mysql.user=root
mysql.password=000000
```

先启动executor在执行web，避免web server因为找不到executor启动失败

```bash
bin/azkaban-executor-start.sh # executor
bin/azkaban-web-start.sh # server
jps
bin/azkaban-executor-shutdown.sh
bin/azkaban-web-shutdown.sh
```

[==**Web页面查看 https://hadoop101:8443**==](hattps://hadoop101:8443)



### Oozie




### Presto


**Presto Server**
```bash
tar -zxvf presto-server-0.196.tar.gz -C /opt/module/
mv presto-server-0.196/ presto
# 在presto目录下创建存储数据文件夹和存储配置文件文件夹
mkdir data
mkdir etc
# etc/下添加jvm.configh文件和catalog目录
vim jvm.config
# 在catalog目录下创建hive.properties文件
vim properties
xsync /opt/module/presto # 分发
# 每个节点配置/opt/module/presto/etc/node.properties
xcall vim /opt/module/presto/etc/node.properties
# hadoop102配置coordinator节点，其他配置worker节点
xcall vim /opt/module/presto/etc/config.properties
```
```conf
-server
-Xmx16G
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
```
```properties
connector.name=hive-hadoop2
hive.metastore.uri=thrift://hadoop102:9083
```
```properties
# hadoop102
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
node.data-dir=/opt/module/presto/data

# hadoop103
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-fffffffffffe
node.data-dir=/opt/module/presto/data

# hadoop104
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-fffffffffffd
node.data-dir=/opt/module/presto/data
```
```properties
# hadoop102
coordinator=true
node-scheduler.include-coordinator=false
http-server.http.port=8881
query.max-memory=50GB
discovery-server.enabled=true
discovery.uri=http://hadoop102:8881

# hadoop103
coordinator=false
http-server.http.port=8881
query.max-memory=50GB
discovery.uri=http://hadoop102:8881

# hadoop104
coordinator=false
http-server.http.port=8881
query.max-memory=50GB
discovery.uri=http://hadoop102:8881
```
```bash
# 前台启动Presto控制台显示日志
xcall /opt/module/presto/launcher run
# 后台启动Presto
xcall /opt/module/presto/launcher start
# 日志查看路径/opt/module/presto/data/var/log
```

**Presto Client**
```bash
# 上传presto-cli-0.196-executable.jar至/opt/module/presto
# 修改文件名并增加执行权限
mv presto-cli-0.196-executable.jar  prestocli
chmod +x prestocli
# 启动prestocli
./prestocli --server hadoop102:8881 --catalog hive --schema default
```
 * Presto命令行操作相当于hive命令行操作，每个表必须加上schema，如`select * from schema.table limit 100`

**Presto 可视化Client**
```bash
# 上传yanagishima-18.0.zip至module并解压
unzip yanagishima-18.0.zip
cd yanagishima-18.0
# /opt/module/yanagishima-18.0/conf下编辑yanagishima.properties
vim yanagishima.properties
# /opt/module/yanagishima-18.0/下启动yanagishima-18.0
nohup bin/yanagishima-start.sh >y.log 2>&1 &
```
```properties
jetty.port=7080
presto.datasources=atiguigu-presto
presto.coordinator.server.atiguigu-presto=http://hadoop102:8881
catalog.atiguigu-presto=hive
schema.atiguigu-presto=default
sql.query.engines=presto
```
查看Web页面http://hadoop102:7080


### Druid



### Impala



### Kylin

[**官网地址**http://kylin.apache.org/cn/](http://kylin.apache.org/cn/)
[**官方文档**http://kylin.apache.org/cn/docs/](http://kylin.apache.org/cn/docs/)
[**下载地址**http://kylin.apache.org/cn/download/](http://kylin.apache.org/cn/download/)
```bash
# 解压
tar -zxvf apache-kylin-2.5.1-bin-hbase1x.tar.gz -C /opt/module/
# 使用Kylin需要配置HADOOP_HOME,HIVE_HOME,HBASE_HOME，并添加PATH
# 先启动hdsf,yarn,historyserver,zk,hbase
start-dfs.sh # hadoop101
start-yarn.sh # hadoop102
mr-jobhistoryserver.sh start historyserver # hadoop101
start-zk # shell
start-hbase.sh
jpsall # 查看所有进程
# --------------------- hadoop101 ----------------
# 3360 JobHistoryServer
# 31425 HMaster
# 3282 NodeManager
# 3026 DataNode
# 53283 Jps
# 2886 NameNode
# 44007 RunJar
# 2728 QuorumPeerMain
# 31566 HRegionServer
# --------------------- hadoop102 ----------------
# 5040 HMaster
# 2864 ResourceManager
# 9729 Jps
# 2657 QuorumPeerMain
# 4946 HRegionServer
# 2979 NodeManager
# 2727 DataNode
# --------------------- hadoop103 ----------------
# 4688 HRegionServer
# 2900 NodeManager
# 9848 Jps
# 2636 QuorumPeerMain
# 2700 DataNode
# 2815 SecondaryNameNode
```
[**Web页面**http://hadoop101:7070/kylin/](http://hadoop101:7070/kylin/)



