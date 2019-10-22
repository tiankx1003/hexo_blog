---
title: Flink--状态一致性
tags: BigData
---

 * 状态一致性，就是计算结果正确性的另一种说法，即发生故障并恢复后得到的计算结果和没有发生故障相比的正确性。

## 1 状态一致性分类
**at-most-once最多一次**
当任务故障时，最简单的做法就是什么都不做，既不恢复丢失的状态，也不重播丢失的数据，at-most-once语义的含义是最多处理一次事件

**at-least-once至少一次**
在大多数的真实应用场景，我们不希望数据丢失id，即所有的事件都得到了处理，而一些事件还可能被处理多次

**exactly-once精确一次**
恰好处理一次是最严格的保证，也是最难实现的，精准处理一次语义不仅仅意味着没有时间丢失，还意味着针对每一个数据，内部状态仅仅更新一次

 * Flink既能保证exactly-once，也具有低延迟和高吞吐的处理能力。

## 2 端到端(end-to-end)状态一致性
实际应用时，不只是要求流处理器阶段的状态一致性，还要求source到sink阶段(从数据源到输出到持久化系统)的状态一致性

 * 内部保证 -- 依赖checkpoint
 * source端 -- 需要外部源可以重设数据的读取位置
 * sink端 -- 需要保证从故障恢复时，数据不会重复写入外部系统

## 3  sink端实现方式
对于sink端有两种实现方式，幂等(Idempotent)写入和事务性(Transactional)写入
**幂等写入**
所谓幂等操作，是说一个操作，可以重复执行很多次，但是只导致一次结果更改，也就是说后面再重复执行就不起作用了

**事务写入**
需要构建事务来写入外部系统，构建的事务对应着checkpoint，等到checkpoint真正完成的时候，才把所有对应的结果写入sink系统中


## 4 事务性写入的实现方式
 * 对于事务性写入，具体又有两种实现方式：预写日志（WAL）和两阶段提交（2PC）。
 * DataStream API 提供了GenericWriteAheadSink模板类和TwoPhaseCommitSinkFunction 接口，可以方便地实现这两种方式的事务性写入。

**预写日志**(Writ-Ahead-Log, WAL)
 * 把结果数据先当成状态保存，然后在收到checkpoint完成的通知时，一次性写入sink系统
 * 简单易于实现，由于数据提前在状态后端中做了缓存，所以无论什么sink系统，都能用这种方式一批搞定
 * DataStream API提供了一个模版类: GenericWriteAheadSink，来实现这种事务性sink

**两阶段提交**(Two-Phase-Commit, 2PC)
 * 对于每个checkpoint，sink任务会启动一个事务，并将接下来所有接受的数据添加到事务里
 * 然后将这些数据写入外部sink系统，但不真正提交他们 -- 这是预提交
 * 当它收到checkpoint完成的通知时，它才正式提交事务，实现结果的真正写入
 * 这种方式真正实现了exactly-once，它需要一个提供事务支持的外部sink系统，Flink提供了TwoPhaseCommitSinkFunction接口


## 5 2PC对外部sink系统的要求
 * 外部sink系统必须提供事务支持，或者sink任务必须能够模拟外部系统上的事务
 * 在checkpoint的间隔期间里，必须能够开启一个事务并接受数据写入
 * 在收到checkpoint完成的通知之前，事务必须是"等待提交"的状态，在故障恢复的情况下，这可能需要一些时间，如果这个时候sink系统关闭事务(例如超时了)，那么未提交的数据就会丢失
 * sink任务必须能够在进程失败后恢复事务
 * 提交事务必须是幂等操作

| sink↓ \ source→ |    不重置    |                    可重置                    |
| :-------------: | :----------: | :------------------------------------------: |
|    任意(Any)    | At-most-once |                At-least-once                 |
|      幂等       | At-most-once | Exactly-once<br>(故障回复时会出现暂时不一致) |
|  预写日志(WAL)  | At-most-once |                At-least-once                 |
| 两阶段提交(2PC) | At-most-once |                 Exactly-once                 |

## 6 Flink+Kafka端到端状态一致性的保证
 * 内部 -- 利用checkpoint机制，把状态存盘，发生故障的时候可以恢复，保证内部的状态一致性
 * source -- kafka consumer作为source，可以将偏移量保存下来，如果后续任务出现了故障，恢复的时候可以由连接器重置偏移量，重新消费数据，保证一致性
 * sink -- kafka producer作为sink，才哟过两阶段提交sink，需要实现一个`TwoPhaseCommitSinkFunction`

## 7 Exactly-once两阶段提交步骤
 * 第一条数据来了之后，开启一个kafka的事务(transaction)，正常写入kafka分区日志但标记为未提交，这就是预提交
 * jobmanager触发checkpoint操作，barrier从source开始向下传递，遇到barrier的算子将状态存入状态后端，并通知jobmanager
 * sink连接器收到barrier，保存当前状态，存入checkpoint，通知jobmanager，并开启下一阶段的事务，用于提价下个检查点的数据
 * jobmanager收到所有任务的通知，发生确认信息，表示checkpoint完成
 * sink任务收到jobmanager的确认信息，正式提交这段时间的数据
 * 外部kafka关闭事务，提交的数据可以正常消费了

<!-- TODO 代码实现 -->