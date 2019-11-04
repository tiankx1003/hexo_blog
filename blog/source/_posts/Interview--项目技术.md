---
title: Interview--项目技术
typora-copy-images-to: Interview--项目技术
tags:
 - BigData
 - Interview
---
# Linux & Shell
### Linux命令总结

| 序号 | 命令                          | 命令解释                               |
| ---- | ----------------------------- | -------------------------------------- |
| 1    | top                           | 查看内存                               |
| 2    | df -h                         | 查看磁盘存储情况                       |
| 3    | iotop                         | 查看磁盘IO读写(yum install iotop安装） |
| 4    | iotop -o                      | 直接查看比较高的磁盘读写程序           |
| 5    | netstat -tunlp \| grep 端口号 | 查看端口占用情况                       |
| 6    | uptime                        | 查看报告系统运行时长及平均负载         |
| 7    | ps   aux                      | 查看进程                               |


### Shell工具
<!-- TODO 添加具体使用和demo -->
awk
sed
cut
sort

# Hadoop
### 常用端口号

| Port  | Desc |
| :---- | :--- |
| 50070 | -    |
| 50075 | -    |
| 50090 | -    |
| 50010 | -    |
| 9000  | -    |
| 8088  | -    |
| 19888 | -    |
| 16010 | -    |
| 8080  | -    |
| 8081  | -    |
| 18080 | -    |
| 7180  | -    |
| 5601  | -    |
| 55555 | -    |



### Hadoop配置文件和测试集群的搭建

### HDFS读写流程
<!-- TODO 手绘流程图并叙述 -->


### MapReduce的Shuffle过程
<!-- TODO 绘图并叙述 -->

### Hadoop优化


### Yarn的Job提交流程


### Yarn调度器


### LZO压缩

### Hadoop参数调优


### Hadoop宕机


# Zookeeper
### 选举机制
半数机制: 2n+1
10台服务器: 3台
20台服务器: 5台
100台服务器: 11台

 * 台数不是越多越好，太多时选举时间过长会影响性能

<!-- TODO 添加半数机制的描述 -->

### 常用命令
ls  get  create

<!-- TODO 添加完整命令语句 -->

# Flume
### Flume组成，Put事务，Take事务
**Taildir Source** 断点续传、多目录监控，Flume1.6之前需要自己自定义Source记录每次读取文件位置，实现断点续传
**File Channel** 数据存储在磁盘，宕机数据可以保存，但是传输速率慢，适合对数据传输可靠性要求不高的场景，如金融
**Memory Channel** 数据存储在内存中，宕机数据丢失。传输速度快，适合对数据传输可靠性不高的场景，如普通的日志数据
**Kafka Channel** 减少了Flume Sink的阶段，提高了传输效率
**Put事务** Source到Channel阶段
**Take事务** Channel到Sink阶段

### Flume拦截器
**拦截器注意事项**
项目中自定义了:ETL拦截器和类型区分拦截器
采用两个拦截器优点是模块化开发和可移植性，缺点是性能会低一点

**自定义拦截器步骤**
1. 实现Interceptor接口
2. 重写方法`initialize`初始化 `public Event intercept(Event event)`处理单个Event `public List<Event> intercept(List<Event> events)`处理多个Event，在这个方法中调用`Event intercept(Event event)` `close`
3. 静态内部类，实现`Interceptor.Builder`

### Flume Channel Selectors
<!-- TODO 配图 -->
Channel Selectors可以让不同的项目日志通过不同的Channel到不同的Sink中去。
官方文档中Channel Selectors有两种类型: Replicating Channel Selector(default)和Multiplexing Channel Selector
这两种Selector的区别是Replicating会将source过来的events发往所有channel，而Multiplexing可以选择该发往哪些Channel

### Flume监控器
Ganglia

### Flume采集数据会不会丢失 (防止丢失数据的机制)
Flume采集数据不会丢失，Channel存储可以存储在File中，数据传输自身有事务

### Flume内存
开发中在flume-env.sh中设置JVM heap为4G或更高，部署在单独的服务器上(4核8线程16G内存)
`-Xmx`与`-Xms`最好设置一致，减少内存抖动带来的性能影响，如果设置不一致容易导致频繁fullgc

### FileChannel优化
通过配置dataDirs指向多个路径，每个路径对应不同的硬盘，增大Flume吞吐量
***官方说明***
*Comma separated list of directories for storing log files. Using multiple directories on separate disks can improve file channel peformance.*

checkpiontDir和backupCheckpointDir也尽量配置在不容硬盘对应的目录中，保证checkpoint坏掉后，可以快速使用backupCheckpointDir恢复数据

### HDFS Sink小文件处理
>**HDFS存入大量小文件的影响**

1. **元数据层面** 每个小文件都有一份元数据，其中包括文件路径，文件名，所有者，所数组，权限，创建时间等，这些信息都保存在Namenode内存中，所以小文件过多，会占用Namenode服务器大量内存，影响Namenode性能和使用寿命
2. **计算层面** 默认情况下MR会对每个小文件启用一个Map任务计算，非常影响计算性能，同时也影响磁盘寻址时间

>**HDFS小文件处理**

官方默认的配置三个参数会产生小文件`hdfs.rollInterval` `hdfs.rollSize` `hdfs.rollCount`
```properties
 tmp文件创建超过3600秒时会滚动生成正式文件
hdfs.rollInterval=3600
 tmp文件达到128M时会滚动生成正式文件
hdfs.rollSize=134217728
hdfs.rollCount=0
hdfs.roundValue=3600
hdfs.roundUnit=second
```
如*2019-10-27 05:23*接收倒数接收到数据时会产生tmp文件`/demo/20191027/demo.201910270520.tmp`
即使文件内容没有达到128M，也会在06:23时滚动生成正式文件


# Kafka
### Kafka架构
<!-- TOOD 手绘Kafka架构图 -->

### Kafka概念

* AR 所有副本
* ISR 与leader保持同步的follow集合
* OSR 与leader未保持同步的副本集合
* LEO 每个副本的最后一条消息的offset
* HW 一个分区中，所有副本最小的offset

### Kafka压测
Kafka官方压测脚本kafka-consumer-pref-test.sh kafka-producer-pref-test.sh
使用压测可以查看系统的瓶颈出现在那个部分(CPU、内存、网络IO)，**一般都是网络IO达到瓶颈**

### Kafka机器数量
kafka数量 = 2 * (峰值生产速度 * 副本数 / 100) + 1

### kafka的日志保存时间
七天

### Kafka的硬盘大小
每天的数据量 * 7天

### Kafka监控
公司自己开发的监控器
开源的监控器: KafkaManager、KafkaMonitor

### Kafka分区数
分区数并不是越多越好，一般分区数不要超过集群机器数量，分区数越多占用内存越大(ISR等)，一个节点集中的分区也就越多，当它宕机的时候，对系统的影响也就越大
分区数一般设置为3-10个

### 副本数设定
一般设置成2或3个，大部分企业设置为2个

### Topic个数
通常情况下，多少个日志类型就用多少个Topic，也有对日志类型进行合并的

### Kafka丢不丢数据
**Ack=0** 相当于异步发送，消息发送完毕即offset增加，继续生产
**Ack=1** leader收到leader replica对一个消息的接收ack才增加offset，然后继续生产
**Ack=-1** leader收到所有的replica对一个消息的接收ack才增加offset，然后继续生产
 * 当ack设置成-1时是不会丢失数据的

<!-- TOOD kafka丢不丢数据 -->

### Kafka的ISR副本同步队列
ISR(In-Sync Replicas) 副本同步队列。ISR中包括Leader和Follower，如果Leader进程挂掉，会在ISR队列中选择一个服务作为新的Leader，有replica.lag.max.messages(延迟条数)和replica.lag.time.max.ms(延迟时间)两个参数决定一台服务器是否可以加入ISR副本队列，在0.10版本移除了replica.lag.max.messages参数，防止服务频繁的进入队列。
任意一个维度超过阈值都会把Follower剔除出ISR，存入OSR(Outof-Sync Replicas)列表，新加入的Follower也会存放在OSR中。


### Kafka分区分配策略
Kafka内部存在两种默认的分区分配策略:**Range**和**RoundRobin**
>**Range策略**

是kafka的默认分区分配策略，是对每个topic而言(即一个topic一个topic分)。
首先对同一个topic里面的分区按照序列号进行排序，并对消费者按照字母顺序进行排序，然后用Partitions分区的个数除以消费者线程的总数来决定每个消费者线程消费几个分区。如果除不尽，那么前几个消费者线程将会多消费一个分区

>**RoundRobin**

前提是同一个ConsumerGroup里面的所有消费者的num.streams(消费者线程数)必须相等，每个消费者订阅的主题必须相同
将所有主题分区组成TopicAndPartition列表，然后对TopicAndPartition列表按照hashCode进行排序，最后按照轮询的方式发给每一个消费线程

### Kafka中的数据量计算
每天的总数据量100g，每天产生1亿条日志，10000万/24/60/60=1150条/秒
平均每秒钟1150条
低谷每秒钟400条
高峰每秒钟1150条*(2 ~ 20倍)=2300条 ~ 23000条
每条日志大小0.5k ~ 2k
每秒数据量2.3MB ~20MB

### Kafka挂掉
Flume记录 <!-- 使用Flume恢复Kafka数据 -->
Kafka日志 <!-- kafka日志和原始数据的格式不同 -->
Kafka中日志保存时间为7天，短期内没事

### Kafka数据积压怎么处理
 * 如果是kafka消费能力不足，可以同时增加topic的分区数和消费者组的消费者数量来提升(注:保证**消费者数=分区数**)
 * 如果是下游的数据处理不及时，可以提高没批次拉取的数量。批次拉取数据过好(拉取数据/处理事件<生产速度)，导致处理的数据小于生产的数据，也会造成数据积压

### Kafka幂等性
Producer的幂等性指的是当发送一条消息时，数据在Server端只会被持久化一次，数据不丢且不重。
但是这里的幂等性是有条件的:
 * 只能保证Producer在单个会话内不丢不重，如果Producer出现意外挂掉再重启是无法保证的(幂等性情况下，是无法获取之前的状态信息的，因此无法做到跨会话级别的不丢不重)
 * 幂等性不能跨多个Topic-Partition，只能单个Partition内的幂等性，当涉及多个Topic-Partition时，这中间的状态并没有同步
**数据不丢，但是有可能数据重复**

### Kafka事务
Kafka从0.11版本开始引入了事务支持，事务可以保证Kafka在Exactly Once语义的基础上，生产和消费可以跨分区和会话，要么全部成功，要么全部失败。

1. Produce事务
为了实现跨分区跨会话的事务，需要引入一个全局唯一的Transaction ID，并将Producer获得的PID和Transaction ID绑定，这样当Producer重启后就可以通过正在进行的Transaction ID获得原来的PID
为了管理Transction Coordinator交互获得Transaction ID对应的任务状态。Transaction Coordinator还负责将事务所有写入Kafka的一个内部Topic，这样即使整个服务重启，由于事务状态得到保存，进行中的事务状态可以得到恢复，从而继续进行。
2. Consumer事务
上述事务机制主要是从Producer方面考虑，对于Consumer而言，事务的保证就会相对较弱，尤其是无法保证Commit的信息被精确消费。这是由于Consumer可以通过offset访问任意信息，而且不同的Segment File生命周期不同，同一事务的消息可能会出现重启后被删除的情况

### Kafka数据重复
Kafka数据重复，可以在下一级SparkStreaming、redis、或hive中dwd层去重
去重的手段:分组、按照id开窗只取第一个值

### Kafka参数优化
>**Brokercan参数设置(server.properties)**

1. 网络和io操作线程配置优化

```properties
 broker处理消息的最大线程数(默认为3)
num.network.threads=cpu核心数+1
 broker处理磁盘io的线程数
num.io.threads=cpu核心数*2
```

2. log数据文件刷盘策略

```properties
 producer每写入10000条数据时，刷新数据到磁盘
log.flush.interval.messages=1000
 每间隔1秒钟刷数据到磁盘
log.flush.interval.ms=1000
```

3. 日志保留策略配置

```properties
 保留三天或者更短(log.clear.delete.retention.ms)
log.retention.hours=72
```

4. Replica相关配置

```properties
 新创建一个topic时，默认的Replica数量，Replica过少会影响数据的可用性，太多则会白白浪费存储资源，一般建议2 ~ 3为宜
offsets.topic.replication.factor=3
```

>**Producer优化(producer.properties)**
```properties
 在producer端用来存放尚未发出去的Message的缓冲区大小，缓冲区满了之后可以选择阻塞发送或抛出异常，由block.on.buffer.full的配置决定
buffer.memory=335544323 (32MB)
 默认发送不进行压缩，推荐配置一种适合的压缩算法，可以大幅度的减缓网络压力和Broker的存储压力
compression.type=none
```

>**Consumer优化**
```properties
 启动consumer的个数，适当增加可以提高的并发度
num.consumer.fetchers=1
 每次fetch request至少拿到多少字节的数据才可以返回
fetch.min.bytes=1
 在fetch request获取的数据至少到达fetch.min.bytes之前，允许等待的最大时长，对应上面硕大欧帝尔Purgatory中请求的超时时间
fetch.wait.max.ms=100
```

>**Kafka内存调整(kafka-server-start.sh**
```shell
 默认内存1个G，生产环境经历爱情不要超过6G
export KAFKA_HEAP_OPTS="-Xms4g -Xmx4g"
```

# Hive
### Hive架构
### Hive和数据库比较
1. 数据存储位置不同
    Hive存储在HDFS，数据库将数据保存在块设备或者本地文件系统中
2. 数据更新
    Hive不建议对数据改写，而数据库中的数据通常是需要经常进行修改的
3. 执行延迟
    Hive执行延迟较高，数据库的执行延迟低，但是数据库的数据规模也较小，当数据的规模超过数据库的处理能力时，Hive的并行计算显然能体现出优势
4. 数据规模
    Hive支持很大规模的数据计算，数据库可以支持的数据规模较小

### 内部表和外部表
**管理表** 当删除一个管理表时，Hive也会删除表对应的数据，管理表不适合和其他工具共享数据
**外部表** 删除该表并不会删除掉原始数据，删除的是表的元数据

### 4个By
**Sort By** 分区内有序
**Order By** 全局排序，只有一个Reducer
**Distribute By** 类似MR中Partition，进行分区，结合sort by使用
**Cluster By** 当Distribute by和Sort by字段相同时，可以使用Cluster by代替。Cluster by兼具Distribute by和Sort by的功能，但是排序只能是升序排序，不能指定排序规则ASC或者DESC

### 窗口函数
***RANK()*** 排序，相同时会重复，总数不会变
***DENSE_RANK()*** 排序相同时会重复，总数会减少
***ROW_NUMBER()*** 会根据顺序计算
`OVER()` 指定分析函数工作的数据窗口大小，这个数据窗口大小可能会随着行的变化而变化
`CURRENT ROW` 当前行
`n PRECEDING` 往前n行数据
`n FOLLOWING` 往后n行数据
`UNBOUNDED` 起点，`UNBOUNDED PRECEDING`表示从前面的起点，`UNBOUNDED FOLLOWING`表示到后面的终点
`LAG(col,n)` 往前第n行数据
`LEAD(col,n)` 往后第n行数据
`NTILE(n)` 把有序分区中的行分发到指定数据的组中，各个组有编号，编号从1开始，对于每一行，NTILE返回慈航所属的组的编号，注意:n必须为int类型

### 自定义UDF UDAF UDTF
**UDF** 继承UDF重写evaluate方法
**UDTF** 继承自GenericUDTF，重写3个方法，initialize(自定义输出的列名和类型) process(将结果返回forward(result)) close
自定义UDF/UDTF用于自己埋点Log打印日志，出错或者数据异常，方便调试

### Hive优化
**MapJoin**
如果不指定MapJoin或者不符合MapJoin的条件，那么Hive解析器会将Join操作转换成Common Join，即在Reduce阶段完成Join，容易发生数据倾斜。可以使用MapJoin把小表全部加载到内存Map端执行Join，避免reduce处理
**行列过滤**
列处理: 在SELECT中，只拿需要的列，如果有，尽量使用分区过滤，少用SELECT *
行处理: 在分区裁剪中，当使用外关联时，如果将副表的过滤条件写在Where后面，那么就会先全表关联，然后再过滤
**采用分桶技术**
**采用分区技术**
**合理设置Map数**
通常情况下，作业会通过input的目录产生一个或者多个map任务，主要的决定因素有:input的文件总个数，input的文件大小，集群设置的文件块大小；
map数并不是越多越好，如果一个任务有很多小文件(远远小于块大小128m)，则每个小文件也会被当作一个块，用一个map任务来完成，而一个map任务启动和初始化的时间远远大于逻辑处理的时间，就会造成很大的资源浪费，而且同时可执行的map数都是受限的。这种情形一般通过减少map数来解决；
并不是每个map处理接近128m的文件块就能解决所有问题，如果一个127m的文件，正常会用一个map完成，但是如果这个文件只有一个或者两个小字段，却有几千万条记录，如果map处理的逻辑比较复杂，用一个map任务去做，肯定效率很低。发生这种情况就需要增加map数。
**小文件进行合并**
在map执行前合并小文件，减少map数，CombineHiveInputFormat具有对文件进行合并的功能(系统默认的格式)，HiveInputFormat没有对小文件合并功能
**合理设置Reduce数**
Reduce个数并不是越多越好。过多的启动和初始化Reduce也会消耗时间和资源，另外有多少个Reduce就会有多少输出文件，如果生成了很多小文件，那么如果这些小文件作为下一个任务的输入，则会出现小文件过多的问题。
**常用参数**
```sql
-- 输出合并小文件
SET hive.merge.mapfiles=true; --默认true，在map-only任务结束时合并小文件
SET hive.merge.mapredfiles=true; --默认false，在map-reduce任务结束时合并小文件
SET hive.merge.size.per.task=268435456; --默认256
SET hive.merge.smallfiles.avgsize=16777216; --当输出文件的平均大小小于该值时，启动一个独立的map-reduce任务进行小文件merge
```

# HBase
### HBase存储结构
<!-- TODO 配图 -->

### rowkey设计原则
1. rowkey长度原则
2. rowkey散列原则
3. rowkey唯一原则

<!-- TODO 添加具体原则 -->

### rowkey具体设计
1. 生成随机数、Hash、散列值
2. 字符串反转

### Phoenix二级索引原理
<!-- TODO 详述原理 -->

# Sqoop
### Sqoop任务提交参数
```bash
sqoop import \
--count \
--username \
--password \
--target-dir \
--delete-target-dir \
--num-mappers \
--fields-terminated-by \
--query "$2" 'and $CONDITIONS;'
```

### Sqoop导入导出Null存储一致性问题
Hive中的Null在底层是以`\N`来存储，而MySQL中的Null的底层就是Null，为了保证数据两端的一致性。在导出数据时采用`--input-null-string`和`--input-null-non-string`两个参数。导入时采用`--null-string`和`--null-non-string`

### Sqoop数据导出一致性问题
1. 场景一: 如Sqoop在导出到MySQL时，使用4个Map任务，过程中有2个任务失败，那此时MySQL中存储了另外两个Map任务导入的数据，此时老板正好看到这个报表数据。而开发工程师发现任务失败后，会调试问题并最终将全部数据正确的导入MySQL，那后面老板再次看报表数据，发现本次看到的数据和之前的不一致，这在生产环境是不允许的。
参考官网描述 http://sqoop.apache.org/docs/1.4.6/SqoopUserGuide.html
*Since Sqoop breaks down export process into multiple transactions, it is possible that a failed export job may result in partial data being committed to the database. This can further lead to subsequent jobs failing due to insert collisions in some cases, or lead to duplicated data in others. You can overcome this problem by specifying a staging table via the --staging-table option which acts as an auxiliary table that is used to stage exported data. The staged data is finally moved to the destination table in a single transaction.*
-staging-table方式
```bash
sqoop export --connect jdbc:mysql://192.168.137.10:3306/user_behavior \
--username root \
--password 123456 \
--table app_cource_study_report \
--columns watch_video_cnt,complete_video_cnt,dt \
--fields-terminated-by "\t" \
--export-dir "/user/hive/warehouse/tmp.db/app_cource_study_analysis_${day}" \
--staging-table app_cource_study_report_tmp \
--clear-staging-table \
--input-null-string '\N'
```
2. 场景2: 设置map数量为1个(不推荐，面试官想要的答案不只是这个)，多个map任务时，采用-staging-table方式，任然可以解决数据一致性问题

### Sqoop底层运行的任务是什么
只有Map阶段，没有Reduce阶段的任务，默认开启4个MR

### Sqoop数据导出的时候一次执行多长时间
Sqoop任务5分钟~2小时的都有，取决于数量

# Scala


# Spark

# Spark Sql, DataFrames, DataSet
### Spark Streaming第一次运行不丢失数据
kafka参数`auto.offset.reset`参数设置成earliest从最初始偏移量开始消费数据

### Spark Streaming精准一次消费
1. 手动维护偏移量offset
2. 处理完业务数据后再进行提交偏移量操作

极端情况下，如在提交偏移量时断网或停电会造成spark程序第二次启动时重复消费问题，所以在涉及到金额和精确计算的场景需要使用事务保证一次消费

### Spark Streaming控制每秒消费数据的速度
通过`spark.streaming.kafka.maxRatePerPartition`参数
# SparkStreaming


# 元数据管理(Atlas血缘系统)

# 数据质量监控(Griffin)




# Flink
### 应用架构
公司中怎么提交实时任务，有多少Job Manager
1. 我们使用yarn session模式提交任务，每次提交会创建一个新的Flink集群，为每一个job提供一个yarn-session，任务之间互相独立，互不影响，方便管理。任务执行完成之后创建的集群也会消失，线上脚本命令如下
```bash
bin/yarn-session.sh -n 7 -s 8 -tm 32768 -qu root.*.* -nm *-* -d
```
其中申请7个taskManager，每个8核，每个taskmanager有32867M内存
2. 集群默认只有一个Job Manager，但为了防止单点故障，我们配置了高可用。我们公司一般配置一个主Job Manager，两个备用Job Manager，然后结合Zookeeper的使用，来达到高可用

### 压测和监控
一般碰到的压力来自以下几个方面
1. 产生数据流的速度如果过快，而下游的算子消费不过来的haunted，会产生背压。背压的监控可以使用Flink Web UI(Port 8081)来可视化监控，一旦报警就能知道。一般情况下背压问题的产生可能是由于sink这个操作符没有优化好，做一下优化就可以了。如写入到ES，可以改成批量写入，可以调大ES队列的大小等
2. 设置watermark的最大延迟时间这个参数，如果设置的过大，可能会造成内存的压力。可以设置最大延迟时间小一些，然后把迟到元素发送到侧输出流中去，晚一点更新结果，或者使用类似于RocksDB这样的状态后端，RocksDB会开辟堆外内存空间，但是IO速度会变慢，需要权衡
3. 还有就是滑动窗口的长度如果过长，而滑动距离很短的话，Flink的性能会下降的很厉害。可以通过时间分片的方法，将每个元素只存入一个"重叠窗口"，这样就可以减少窗口中状态的写入，参考 https://www.infoq.cn/article/sIhs_qY6HCpMQNblTI9M
4. 状态后端使用RocksDB，还没有碰到被撑爆的问题。


### 为什么使用Flink
Flink的延迟低、高吞吐量和对流式数据应用场景更好的支持；另外，flink可以很好地处理乱序数据，而且可以保证exactly-once的状态一致性。
<!-- TODO 文档第一章有详细对比 -->

### checkpoint的存储
Flink的checkpoint存储在内存或者文件系统，或者RocksDB

### exactly-once的保证
如果下级存储不支持事务，Flink怎么保证exactly-once
端到端exactly-once对sink要求比较高，具体实现主要有幂等写入和事务性写入两种方式。幂等写入的场景依赖于业务逻辑，更常见的是用事务性写入。而事务性写入又有预写日志(WAL)和两阶段提交(2PC)两种方式
如果外部系统不支持事务，那么可以用预写日志的方式，把结果数据先当成状态保存，然后收到checkpoint完成的通知时，一次性写入sink系统
<!-- TODO 文档9.2 9.3 课件-Flink的状态一致性 -->

### 状态机制
Flink内置的很多算子，包括源source，数据存储sink都是有状态的。在Flink中，状态时钟特定算子相关联。Flink会以checkpoint的形式对各个任务的状态进行快照，用于保证故障恢复时的状态一致性。Flink通过状态后端管理状态和checkpoint的存储，状态后端可以有不同的配置选择
<!-- TODO 文档第九章 -->

### 海量key去重
如实际场景:双十一时，滑动窗口长度是要1个小时，滑动距离为10秒钟，亿级用户，如何计算UV
使用scala的set数据结构或者redis的set显然不行，因为可能有上亿个key，内存放不下，所以可以考虑是使用布隆过滤器(Bloom Filter)来去重

### checkpoint与spark的比较
spark streaming的checkpoint仅仅是针对driver的故障恢复做了数据和元数据的checkpoint，而flink的checkpoint机制要复杂了很多，它采用的是轻量级的分布式快照，实现了每个算子的快照，及流动中的数据的快照
参考 https://cloud.tencent.com/developer/article/1189624 
<!-- TODO 文档9.3 -->

### watermark机制
Watermark本质是Flink中衡量EventTime进展的一个机制，主要用来处理乱序数据
<!-- TODO 文档1.3 -->

### exactly-once如何实现
Flink依靠checkpoint机制来实现exactly-once语义，如果要实现端到端的exactly-once，还需要外部source和sink满足一定的条件。状态的存储通过状态后端来管理，Flink中可以配置不同的状态后端
<!-- TODO 文档9.2 9.3 9.4 -->

### CEP编程中，当状态没有到达的时候会将数据保存在哪里
在流式处理中，CEP要支持EventTime，相对应的也要支持数据的迟到现象，也就是watermark的处理逻辑。CEP对未匹配成功的事件序列的处理，和迟到数据是类似的。在Flink CEP的处理逻辑中，状态没有满足的和迟到的数据，都会存储在一个map数据结构中，也就是说，如果我们限定判断事件序列的时长为5分钟，那么内存中就会存储5分钟的数据，这在我看来，也是对内存的极大损伤之一。

### 时间语义
**Event Time** 这是实际应用最常见的时间语义 <!-- TODO 摘抄文档第七章 -->
**Processing Time** 没有事件时间的情况下，或者对实时性要求超高的情况下
**Ingestion Time** 存在多个Source Operator的情况下，每个Source Operator可以使用自己本地系统时钟指派Ingestion Time，后续基于时间相关的各种操作，都会使用数据记录中的Ingestion Time

### 数据高峰的处理
使用容量的kafka把数据先放到消息队列里面作为数据源，在使用Flink进行消费，不过这样会影响到一点实时性
