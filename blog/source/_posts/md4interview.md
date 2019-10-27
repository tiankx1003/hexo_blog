---
title: md4interview
tags: interview
---

# 项目技术
## Zookeeper
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

## Flume
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
# tmp文件创建超过3600秒时会滚动生成正式文件
hdfs.rollInterval=3600
# tmp文件达到128M时会滚动生成正式文件
hdfs.rollSize=134217728
hdfs.rollCount=0
hdfs.roundValue=3600
hdfs.roundUnit=second
```
如*2019-10-27 05:23*接收倒数接收到数据时会产生tmp文件`/demo/20191027/demo.201910270520.tmp`
即使文件内容没有达到128M，也会在06:23时滚动生成正式文件


## Kafka
### Kafka架构
<!-- TOOD 手绘Kafka架构图 -->

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

### Kafka数据重复
Kafka数据重复，可以在下一级SparkStreaming、redis、或hive中dwd层去重
去重的手段:分组、按照id开窗只取第一个值

### Kafka参数优化
>**Brokercan参数设置(server.properties)**

1. 网络和io操作线程配置优化
```properties
# broker处理消息的最大线程数(默认为3)
num.network.threads=cpu核心数+1
# broker处理磁盘io的线程数
num.io.threads=cpu核心数*2
```

2. log数据文件刷盘策略
```properties
# producer每写入10000条数据时，刷新数据到磁盘
log.flush.interval.messages=1000
# 每间隔1秒钟刷数据到磁盘
log.flush.interval.ms=1000
```

3. 日志保留策略配置
```properties
# 保留三天或者更短(log.clear.delete.retention.ms)
log.retention.hours=72
```

4. Replica相关配置
```properties
# 新创建一个topic时，默认的Replica数量，Replica过少会影响数据的可用性，太多则会白白浪费存储资源，一般建议2 ~ 3为宜
offsets.topic.replication.factor=3
```

>**Producer优化(producer.properties)**
```properties
# 在producer端用来存放尚未发出去的Message的缓冲区大小，缓冲区满了之后可以选择阻塞发送或抛出异常，由block.on.buffer.full的配置决定
buffer.memory=335544323 (32MB)
# 默认发送不进行压缩，推荐配置一种适合的压缩算法，可以大幅度的减缓网络压力和Broker的存储压力
compression.type=none
```

>**Consumer优化**
```properties
# 启动consumer的个数，适当增加可以提高的并发度
num.consumer.fetchers=1
# 每次fetch request至少拿到多少字节的数据才可以返回
fetch.min.bytes=1
# 在fetch request获取的数据至少到达fetch.min.bytes之前，允许等待的最大时长，对应上面硕大欧帝尔Purgatory中请求的超时时间
fetch.wait.max.ms=100
```

>**Kafka内存调整(kafka-server-start.sh**
```shell
# 默认内存1个G，生产环境经历爱情不要超过6G
export KAFKA_HEAP_OPTS="-Xms4g -Xmx4g"
```

