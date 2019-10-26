---
title: md4interview
tags: interview
---

## 项目技术
### Kafka
#### Kafka架构
<!-- TOOD 手绘Kafka架构图 -->

#### Kafka压测
Kafka官方压测脚本kafka-consumer-pref-test.sh kafka-producer-pref-test.sh
使用压测可以查看系统的瓶颈出现在那个部分(CPU、内存、网络IO)，**一般都是网络IO达到瓶颈**

#### Kafka机器数量
kafka数量 = 2 * (峰值生产速度 * 副本数 / 100) + 1

#### kafka的日志保存时间
七天

#### Kafka的硬盘大小
每天的数据量 * 7天

#### Kafka监控
公司自己开发的监控器
开源的监控器: KafkaManager、KafkaMonitor

#### Kafka分区数
分区数并不是越多越好，一般分区数不要超过集群机器数量，分区数越多占用内存越大(ISR等)，一个节点集中的分区也就越多，当它宕机的时候，对系统的影响也就越大
分区数一般设置为3-10个

#### 副本数设定
一般设置成2或3个，大部分企业设置为2个

#### Topic个数
通常情况下，多少个日志类型就用多少个Topic，也有对日志类型进行合并的

#### Kafka丢不丢数据
**Ack=0** 相当于异步发送，消息发送完毕即offset增加，继续生产
**Ack=1** leader收到leader replica对一个消息的接收ack才增加offset，然后继续生产
**Ack=-1** leader收到所有的replica对一个消息的接收ack才增加offset，然后继续生产
 * 当ack设置成-1时是不会丢失数据的

<!-- TOOD kafka丢不丢数据 -->

#### Kafka的ISR副本同步队列



#### Kafka分区分配策略


#### Kafka中的数据量计算


#### Kafka挂掉
Flume记录 <!-- 使用Flume恢复Kafka数据 -->
Kafka日志 <!-- kafka日志和原始数据的格式不同 -->
Kafka中日志保存时间为7天，短期内没事

#### Kafka数据积压怎么处理
 * 如果是kafka消费能力不足，可以同时增加topic的分区数和消费者组的消费者数量来提升(注:保证**消费者数=分区数**)
 * 如果是下游的数据处理不及时，可以提高没批次拉取的数量。批次拉取数据过好(拉取数据/处理事件<生产速度)，导致处理的数据小于生产的数据，也会造成数据积压

#### Kafka幂等性
Producer的幂等性指的是当发送一条消息时，数据在Server端只会被持久化一次，数据不丢且不重。
但是这里的幂等性是有条件的:
 * 只能保证Producer在单个会话内不丢不重，如果Producer出现意外挂掉再重启是无法保证的(幂等性情况下，是无法获取之前的状态信息的，因此无法做到跨会话级别的不丢不重)
 * 幂等性不能跨多个Topic-Partition，只能单个Partition内的幂等性，当涉及多个Topic-Partition时，这中间的状态并没有同步
**数据不丢，但是有可能数据重复**

#### Kafka事务

#### Kafka数据重复
Kafka数据重复，可以在下一级SparkStreaming、redis、或hive中dwd层去重
去重的手段:分组、按照id开窗只取第一个值

#### Kafka参数优化
>**Brokercan参数设置(server.properties)**

1. 网络和io操作线程配置优化
```conf
# broker处理消息的最大线程数(默认为3)
num.network.threads=cpu核心数+1
# broker处理磁盘io的线程数
num.io.threads=cpu核心数*2
```

2. log数据文件刷盘策略
```conf
# producer每写入10000条数据时，刷新数据到磁盘
log.flush.interval.messages=1000
# 每间隔1秒钟刷数据到磁盘
log.flush.interval.ms=1000
```

3. 日志保留策略配置
```conf
# 保留三天或者更短(log.clear.delete.retention.ms)
log.retention.hours=72
```

4. Replica相关配置
```conf
# 新创建一个topic时，默认的Replica数量，Replica过少会影响数据的可用性，太多则会白白浪费存储资源，一般建议2~3为宜
offsets.topic.replication.factor=3
```

>**Producer优化(producer.properties)**
```conf
# 在producer端用来存放尚未发出去的Message的缓冲区大小，缓冲区满了之后可以选择阻塞发送或抛出异常，由block.on.buffer.full的配置决定
buffer.memory=335544323 (32MB)
# 默认发送不进行压缩，推荐配置一种适合的压缩算法，可以大幅度的减缓网络压力和Broker的存储压力
compression.type=none
```

>**Consumer优化**
```conf
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

