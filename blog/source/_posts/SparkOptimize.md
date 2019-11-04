---
titile: Spark Optimize
tags:
 - Spark
 - BigData
---
## 1.Cache
经常使用的表可以使用cache进行缓存
<!-- TODO 缓存和释放缓存的方法 -->
**缓存和释放缓存的方法**

```scala
// 缓存
dataFrame.cache
sparkSession.catalog.cacheTable("tableName")
// 释放缓存
dataFrame.unpersist
sparkSession.catalog.uncacheTable("tableName")
```
**缓存级别**

| Cache Level           | Description                                                   |
| :-------------------- | :------------------------------------------------------------ |
| DISK_ONLY             | 只缓存到磁盘没有副本                                          |
| DISK_ONLY_2           | 只缓存到磁盘有2份副本                                         |
| MEMORY_ONLY           | 只缓存到内存没有副本                                          |
| MEMORY_ONLY_2         | 只缓存到内存有2份副本                                         |
| MEMORY_ONLY_SER       | 只缓存到内存并且序列化没有副本                                |
| MEMORY_ONLY_SER_2     | 只缓存到内存并且序列化有2份副本                               |
| MEMORY_AND_DISK       | 缓存到内存和磁盘没有副本，如果内存放不下溢写到磁盘            |
| MEMORY_AND_DISK_2     | 缓存到内存和磁盘有2份副本，如果内存放不下溢写到磁盘           |
| MEMORY_AND_DISK_SER   | 缓存到内存和磁盘并且序列化，如果内存放不下溢写到磁盘          |
| MEMORY_ADN_DISK_SER_2 | 缓存到内存和磁盘并且序列化有2份副本，如果内存放不下溢写到磁盘 |
| OFF_HEAP              | 缓存到堆外内存                                                |

 * DataFrame的cache默认采用MEMORY_AND_DISK
 * RDD的cache默认采用MEMORY_ONLY

## 2.Spark Join
**Spark Join有三种:**

**HASH JOIN** v1.4之后被淘汰
**BRAODCAST HASH JOIN** 用于小表join大表，广播小表规避shuffle
**SORTMERGE JOIN** 用于大表join大表

#### 2.1 BROADCAST HASH JOIN
参数`spark.sql.autoBroadcastJoinThreshold`设置默认广播join的大小，当表的大小超过这个值时会被看作大表不进行广播，可以根据实际的集群规模进行更改。
广播过大的表会有OOM，当分发表的时间大于join的时间也就没有广播的必要了。
在项目中使用广播变量的场景:官博jediscluster对象

<!-- TODO 设置参数的方式，SparkConf使用set传入键值对字符串 -->
```scala
val sparkConf = new SparkConf()
    .setAppName("demo")
    .set("spark.sql.autoBroadcastJoinThreshold", "20480")
```

参数`spark.sql.shuffle.partitions`用于配置join时shuffle的分区数，只作用于DS和DF对RDD不起作用
参数`spark.default.parallelism`可用于设置RDD分区数，对DS和DF不起作用

表在进行join时，相同key的数据会发送到同一个分区(所以存在shuffle和网络传输)，对小表进行广播后就是本地join了，可以通过这种方法规避shuffle

Spark中改变分区的方法:coalesce 和 repartition
coalesce和repartiton都用于改变分区，coalesce用于缩小分区且不会进行shuffle，repartion用于增大分区（提供并行度）会进行shuffle,在spark中减少文件个数会使用coalesce来减少分区来到这个目的。但是如果数据量过大，分区数过少会出现OOM所以coalesce缩小分区个数也需合理

<!-- TODO 广播join的具体使用方法 -->
通过`4040`端口查看SparkUI中任务的具体执行情况，在SQL界面会显示表的大小，根据数值判断需要广播变量进行优化。

#### 2.2 SORT MERGE BUCKET JOIN
SMB JOIN（Sort-Merge-Bucket）是针对bucket majoin的一种优化
数据规模不够大时很少会使用到，分桶后小文件过多(分区数 * 桶个数)
表的数据量够大时(如每张表的数据量达到TB级别)

**使用条件**
两张表的bucket必须相等
bucket列==joinlie==sort列
必须应用在bucket mapjoin，建表时，必须是clustered且sorted

**在Hive中的使用**
```sql
set hive.auto.convert.sortmerge.join=true; 
set hive.optimize.bucketmapjoin = true; 
set hive.optimize.bucketmapjoin.sortedmerge = true; 
set hive.auto.convert.sortmerge.join.noconditionaltask=true;
```
```scala
//spark中使用分桶
peopleDF
    .write
    .bucketBy(42, "name")
    .sortBy("age")
    .saveAsTable("people_bucketd")
```
Hive不兼容`saveAsTable`算子，创建的表不能在Hive查询到，只能在SparkShell中查询到。

## 3.Kryo
序列化是一种牺牲CPU来节省内存的手段，可以在内存紧张时使用，使用Kyro序列化可以减少Shuffle的数量。
DF和DS默认使用Kryo序列化，RDD默认使用Java的序列化，使用Kryo需要手动注册样例类
在集群资源绝对充足的情况下推荐直接使用cache，在集群内存资源十分紧张的情况推荐下使用kryo序列化，并使用`persist(StorageLevel.MEMORY_ONLY_SER)`

<!-- TODO 手动注册 -->
```scala
val sparkConf = new SparkConf().setAppName("demo")//.setMaster("local[*]")
sparkConf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
sparkConf.registerKryoClasses(Array(Class[QueryResult]))
val result = IdlMemberDao.queryIdlMemberData(sparkSession).as[QueryResult]
result.persist(StorageLevel.MEMORY_ONLY_SER) //设置缓存级别
```

Spark对于DF和DS要比RDD的优化程度更高，尽量只使用DF和DS，DF和DS是Spark的未来趋势，RDD可能在v3.0之后取消。

## 4.Spark Reduce Buf & Shuffle Optimize
参数`spark.reducer.maxSizeFlight`表示reduce task拉取多少数据量，默认为48M，当集群资源足够时，增大此参数可以减少reduce的拉取次数，从而达到优化shuffle的效果，一般调大到94M，如果资源足够大可以继续往上调
参数`spark.shuffle.file.buffer`
这两个参数都是优化次数，效果不明显，只有5%优化率，在超大规模的数据场景下才能发挥作用。
参数`spark.sql.shuffle.partitions`可用于调整shuffle并行度，默认200，一般设置为core个数的两倍或者三倍

## 5.groupByKey
dataframe并没有reducebykey算子，只有reduce算子但是reduce算子并不符合业务需求，那么需要使用Spark2.0新增算子groupbykey，groupbykey后返回结果会转换成`KeyValueGroupDataSet`，开发者可以自定义key，groupbykey后数据集就变成了一个`(key,iterable[bean1,bean2,bean3])`   bean为dataset所使用的实体类，groupbykey后，会将所有符合key规则的数据聚合成一个迭代器放在value处，那么如果我们需要对key和value进行重组就可以是用mapGroups算子，针对这一对key,value数据，可以对value集合内的数据进行求和处理重组一个返回对象,mapGroups的返回值是一个DataSeT,那么返回的就是你所重组的DataSet,操作类似于rdd groupbykey map。
如果需要保留key,只需要对value进行重构那么可以调用mapValues方法重构value,再进行reduceGroups对value内的各属性进行汇总。
`rdd.groupByKey( ... ).map( ... )`等价于`rdd.reduceByKey( ... )`
```scala
result
    .mapPartitions(partition => {
        partition.map(data => (data.sitename + "_" + data.website, 1))
    })
    .groupByKey(_._1)
    .mapValues((item => item._2))
    .map(item => {
        val keys = item._1.split("_")
        val sitename = key(0)
        val website = key(1)
        (sitename, item._2, website)
    })
```

