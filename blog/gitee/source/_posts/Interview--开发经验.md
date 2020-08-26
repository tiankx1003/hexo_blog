---
title: Interview--开发经验
tags:
 - BigData
 - Interview
typora-copy-images-to: Interview--开发经验
---
# 一、技术经验
## 1.Hadoop
1. 集群基	准测试(HDFS的读写性能、MapReduce的计算能力测试))
2. 一台服务器一百年有很多个硬盘插槽，如果不配置`datanode.data.dir`多目录，每次插入一块新的硬盘都需要重启服务器，配置了即插即用
3. HDFS参数调优(项目中遇到的问题)
Namenode有一个工作线程池，用来处理与datanode的心跳(报告自身的健康状况和文件恢复请求)和元数据请求`dfs.namenode.handler.count=20*log2(cluster size)`
4. 编辑日志存储路径`dfs.namenode.edits.dir`设置与镜像文件存储路径`dfs.namenode.name.dir`尽量分开，达到最低写入延迟(提高写入的吞吐量)
5. Yarn参数调优yarn-site.xml，服务器节点上的Yarn可使用的物理内存总量，默认是8192MB，单个任务可申请的最多物理内存量，默认是8192MB
6. HDFS和硬盘使用控制在70%以下
7. **Hadoop宕机**，如果MR造成宕机就调整Yarn同时运行的任务数，和每个任务申请的最大内存，`yarn.scheduler.maximum-allocation-mb`(任务可申请的最多物理内存量，默认是8192MB);如果写入文件过量造成NameNode宕机，那么调高Kafka的存储大小，控制从Kafk到HDFS的写入速度，高峰期的时候用Kafka进行缓存，高峰期过去数据同步会自动跟上。

## 2.Flume
1. Flume内存配置为4G(在flume-env.sh中修改)
2. FileChannel优化，通过dataDir指向多个路径，每个路径对应不同的硬盘，增大Flume吞吐量，`checkpointDir`和`backCheckpointDir`也尽量配置在不同硬盘对应的目录中，保证checkpoint坏掉后，可以快速使用backupCheckpointDir恢复数据
3. HDFS Sink小文件处理，`hdfs.rollInterval` `hdfs.rollSize` `hdfs.rollCount`
4. Ganglia监控Flume发现尝试提交的次数大于最终成功的次数，可以通过增大Flume内存或者增大Flume台数解决

## 3.Kafka
1. Kafka吞吐量测试(测试生产速度和消费速度)
2. Kafka内存为6G，不能超过6G
3. Kafka数量的确定，2 * 峰值生产速度(m/s) * 副本数 / 100 + 1
4. Kafka中数据量的计算
    每天数据总量100g(1亿条)  10000万/24/60/60 = 1150 条/s
    平均每秒: 1150 条
    低估每秒: 400 条
    高峰每秒: 1150 * 10 ≈ 11000 条
    每条日志大小: 1KB左右
    每条数据量: 20MB左右
5. Kafka消息积压和消费能力不足的解决
    如果是Kafka消费能力的不足，则可以考虑增加Topic的分区数，并且同时提升消费组的消费者数量，消费者数=分区数(两者缺一不可)
    如果是下游的数据处理不及时，提高每批次的拉取数量，批次拉取数据过少(拉取数据/处理事件<生产速度)导致处理的数据小于生产的数据，也会造成数据积压
6. Kafka挂掉之后，Flume Channel可以缓存一段时间，短期没事；日志服务器有30天记录，可以重写跑
7. Kafka数据重复，在下一级消费者中去重(redis SparkStreaming Hive的dwd层)

## 4.Hive
1. 自定义UDF和UDTF解析和调试复杂字段
    自定义UDF(extends UDF实现evaluate方法)解析公共字段
    自定义UDTF(extends Genertic UDTF -> 实现init指定返回值的名称和类型 process处理字段一进多出 close三个方法) -> 更加灵活以及方便定位bug
2. Hive优化

## 5.MySQL
1. 元数据备份(重点，如数据损坏，可能整个集群无法运行，至少要保证每日零点之后备份到其他服务器两个副本)，MysqlHA Keepalived mycat
2. MySQL utf8超过字节数问题，Mysql的utf8编码最多存储3个字节，当数据中存在表情号、特色符号时会占用超过3个字节数的字节，那么会出现错误 `Incorrect string value: '\xF0\x9F\x91\x91\xE5\xB0...'` 解决办法：将utf8修改为utf8mb4 `set character_set_server = utf8mb4`

## 6.Tez
Tez可以将多个有依赖的作业转换为一个作业，这样只需一次HDFS，且中间节点较少，从而大大提升作业的计算性能

## 7.Sqoop
1. Sqoop数据导出Parquet，ads层数据用Sqoop往MySQL中导入数据的时候，如果用了orc(Parquet)不能导入，需转化成text格式
2. Sqoop数据导出控制，Sqoop中导入导出Null存储一致性问题，Hive中Null在底层以"\N"来存储，而MySQL中的null在底层就是Null，为了保证数据两端的一致性，在导出数据时采用`--input-null-string`和`--input-null-string`两个参数，导入导数据时采用`--null-string`和`--null-non-string`
3. Sqoop导出一致性问题，当Sqoop导出数据到MySQL时，4个map要保证一致性，因为在导出数据的过程中map任务可能会失败，可以使用`--staging-table` `--clear-staging`任务执行成功首先在tmp临时表中，然后tmp表中的数据复制到目标表中(这个时候可以使用事务，保证事务的一致性)
4. Sqoop数据导出的时候一次执行时间取决于数据量，5分钟到2小时不等

## 8.Azkaban
1. 每天集群运行多少job
2. 多个指标(200) * 6 = 1200 (100到1200个job)
3. 每天集群运行多少个task 1000 * (5 ~ 8) = 5000多个
4. 任务挂了怎么办，运行成功或者失败都会发邮件
5. `zip a.job b.job c.job job.zip` 把压缩的zip包放到azkaban的web界面上提交(指定scheduler)

## 9.Spark
1. 优雅的关闭SparkStreaming任务
2. SparkOOM、数据倾斜解决

# 二、业务经验
## 1.ODS层压缩方式与存储格式
采用Snappy压缩，存储采用orc，压缩比是100g数据压缩成10g左右
创建分区表 <!-- TODO 创建分区表 -->

## 2.DWD层做了哪些事
>**数据清洗**
去除空值
过滤核心字段无意义的数据，如订单表中订单id为null，支付表中支付id为空
对手机号、身份证号等敏感数据脱敏
对业务数据传过来的表进行维度退化和降维
将用户行为宽表和业务表进行数据一致性处理
```sql
select
    case when a is null then b else a end as JZR,
    ...
from A
```

>**清洗的手段**
SQL，mr，rdd，kettle，Python

>**清洗掉多少数据合理**
一万条数据清洗掉一条

## 3.DWS层做了哪些事
1. DWS层有3-5张宽表(处理100-200个指标，70%以上的需求)
具体宽表名称: 用户行为宽表，用户购买商品明细行为宽表，商品宽表，购物车宽表，物流宽表，登陆注册，售后等

2. 那个宽表长度最宽，大概有多少个字段
用户行为宽表，大概有60-100个字段(一百以上)

3. 具体用户行为宽表字段名称
评论、打赏、收藏、关注-用户、关注-商品、点赞、分享、好价爆料、文章发布、活跃、签到、补签卡、幸运屋、礼品、金币、电商点击、gmv

```sql
CREATE TABLE `app_usr_interact`(
  `stat_dt` date COMMENT '互动日期', 
  `user_id` string COMMENT '用户id', 
  `nickname` string COMMENT '用户昵称', 
  `register_date` string COMMENT '注册日期', 
  `register_from` string COMMENT '注册来源', 
  `remark` string COMMENT '细分渠道', 
  `province` string COMMENT '注册省份', 
  `pl_cnt` bigint COMMENT '评论次数', 
  `ds_cnt` bigint COMMENT '打赏次数', 
  `sc_add` bigint COMMENT '添加收藏', 
  `sc_cancel` bigint COMMENT '取消收藏', 
  `gzg_add` bigint COMMENT '关注商品', 
  `gzg_cancel` bigint COMMENT '取消关注商品', 
  `gzp_add` bigint COMMENT '关注人', 
  `gzp_cancel` bigint COMMENT '取消关注人', 
  `buzhi_cnt` bigint COMMENT '点不值次数', 
  `zhi_cnt` bigint COMMENT '点值次数', 
  `zan_cnt` bigint COMMENT '点赞次数', 
  `share_cnts` bigint COMMENT '分享次数', 
  `bl_cnt` bigint COMMENT '爆料数', 
  `fb_cnt` bigint COMMENT '好价发布数', 
  `online_cnt` bigint COMMENT '活跃次数', 
  `checkin_cnt` bigint COMMENT '签到次数', 
  `fix_checkin` bigint COMMENT '补签次数', 
  `house_point` bigint COMMENT '幸运屋金币抽奖次数', 
  `house_gold` bigint COMMENT '幸运屋积分抽奖次数', 
  `pack_cnt` bigint COMMENT '礼品兑换次数', 
  `gold_add` bigint COMMENT '获取金币', 
  `gold_cancel` bigint COMMENT '支出金币', 
  `surplus_gold` bigint COMMENT '剩余金币', 
  `event` bigint COMMENT '电商点击次数', 
  `gmv_amount` bigint COMMENT 'gmv', 
  `gmv_sales` bigint COMMENT '订单数')
PARTITIONED BY (  `dt` string)
```

4. 商品点击 -> 购物车 -> 订单 -> 付款 转化率
5%  50%  80%

5. 每天的GMV是多少，那个商品卖的好，每天下单量是多少
100万的日活每天大概有10万人购买，平均每天消费100元，一天的GMV在1000万
具体商品的销量要看季度，面膜和化妆品销量一般都会居高不下
每天下单量在10万左右


## 4.分析过那些指标
>**离线指标**
网站流量指标  独立访问UV  页面访客数PV
流量质量指标  跳出率  平均页面访问时长  人均页面访问数

>**购物车类指标**
加入购物车次数  加入购物车买家数  加入购物车商品数
购物车支付转化率

>**下单类指标**
下单笔数  下单金额  下单买家数  浏览下单转化率

>**支付类指标**
支付金额  支付买家数  支付商品数  浏览-支付买家转化率
下单-支付金额转化率  下单-支付买家转化率

>**交易类指标**
交易成功订单数  交易成功金额  交易成功买家数  交易成功商品数
交易失败订单数  交易失败订单金额  交易失败买家数
交易失败商品数  退款总订单量  退款金额  退款率

>**市场营销活动指标**
新增访客人数  新增注册人数  广澳投资回报率  UV  订单转化率

>**风控类指标**
买家评价数  买家商品图片数  买家评价率  买家好评率 买家差评率
物流平均配送时间

>**投诉类指标**
发起投诉数  投诉率  撤销投诉(申诉数)

>**商品类指标**
产品总数  SKU数  SPU数
上架商品SKU数  上架商品SPU数 上架商品数

![data-analysis.png](Interview--开发经验/data-analysis.png.png)

日活跃用户，
月活跃用户，
各区域Top10商品统计，
季度商品品类点击率top10，
用户留存，
月APP的用户增长人数，
广告区域点击数top3，
活跃用户每天在线时长，
投诉人数占比，
沉默用户占比，
用户的新鲜度，
商品上架的sku数，
同种品类的交易额排名，
统计买家的评价率，
用户浏览时长，
统计下单的数量，
统计支付的数量，
统计退货的数量，
用户的（日活、月活、周活），
统计流失人数

日活，周活，月活，沉默用户占比，增长人数，活跃用户占比，在线时长统计，歌曲访问数，歌曲访问时长，各地区Top10歌曲统计 ,投诉人数占比，投诉回应时长，留存率，月留存率，转化率，GMV，复购vip率，vip人数，歌榜，挽回率，粉丝榜，打赏次数，打赏金额，发布歌曲榜单，歌曲热度榜单，歌手榜单，用户年龄组，vip年龄组占比，收藏数榜单，评论数
用户活跃数统计（日活，月活，周活），某段时间的新增用户/活跃用户数，页面单跳转化率统计，活跃人数占比（占总用户比例），在线时长统计（活跃用户每天在线时长），统计本月的人均在线时长，订单产生效率（下单的次数与访问次数比），页面访问时长（单个页面访问时长），统计本季度付款订单，统计某广告的区城点击数top3，统计本月用户的流失人数，统计本月流失人数占用户人数的比例，统计本月APP的用户增长人数，统计本月的沉默用户，统计某时段的登录人数，统计本日用户登录的次数平均值，统计用户在某类型商品中的浏览深度（页面转跳率），统计用户从下单开始到交易成功的平均时长，Top10热门商品的统计，统计下单的数量，统计支付的数量，统计退货的数量，统计动销率（有销量的商品/在线销售的宝贝），统计支付转化率，统计用户的消费频率，统计商品上架的SKU数，统计同种品类的交易额排名，统计按下单退款排序的top10的商品，统计本APP的投诉人数占用户人数的比例，用户收藏商品


## 5.手写分析过得最难的指标
1. 最近连续三周活跃用户数

```sql
drop table if exists ads_continuity_wk_count;
create external table ads_continuity_wk_count( 
    `dt` string COMMENT '统计日期,一般用结束周周日日期,如果每天计算一次,可用当天日期',
    `wk_dt` string COMMENT '持续时间',
    `continuity_count` bigint
) 
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_continuity_wk_count';

insert into table ads_continuity_wk_count
select 
     '2019-02-20',
     concat(date_add(next_day('2019-02-20','MO'),-7*3),'_',date_add(next_day('2019-02-20','MO'),-1)),
     count(*)
from 
(
    select mid_id
    from dws_uv_detail_wk
    where wk_dt>=concat(date_add(next_day('2019-02-20','MO'),-7*3),'_',date_add(next_day('2019-02-20','MO'),-7*2-1)) 
    and wk_dt<=concat(date_add(next_day('2019-02-20','MO'),-7),'_',date_add(next_day('2019-02-20','MO'),-1))
    group by mid_id
    having count(*)=3
)t1;
```

2. 最近七天内连续三天活跃用户数


```sql
drop table if exists ads_continuity_uv_count;
create external table ads_continuity_uv_count( 
    `dt` string COMMENT '统计日期',
    `wk_dt` string COMMENT '最近7天日期',
    `continuity_count` bigint
) COMMENT '连续活跃设备数'
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_continuity_uv_count';

insert into table ads_continuity_uv_count
select
    '2019-02-12',
    concat(date_add('2019-02-12',-6),'_','2019-02-12'),
    count(*)
from
(
    select mid_id
    from
    (
        select mid_id      
        from
        (
            select 
                mid_id,
                date_sub(dt,rank) date_dif
            from
            (
                select 
                    mid_id,
                    dt,
                    rank() over(partition by mid_id order by dt) rank
                from dws_uv_detail_day
                where dt>=date_add('2019-02-12',-6) and dt<='2019-02-12'
            )t1
        )t2 
        group by mid_id,date_dif
        having count(*)>=3
    )t3 
    group by mid_id
)t4;
```


## 6.每天运行多少张表，什么时间运行，运行多久
基本一个项目建一个库，表个数为初始的原始数据表加上统计结果表格的总数(70-100张表)
每天00:30开始运行
所有离线数据报表控制在8小时之内
大数据实时处理部分控制在5分钟之内
评分标准满分5分

## 7.数仓中使用的文件存储格式
常用的包括 textFile rcFile ORC Parquet 一般企业使用ORC或者Parquet，因为这两者是列式存储，且压缩比较高，所以相比于textFile，查询速度快，占用磁盘空间少

## 8.数仓中用到的shell脚本与具体功能
集群启停(Hadoop Flume Kafka Zookeeper)
Sqoop与数仓之间的导入导出
数仓层级之间的导入导出

## 9.项目中用过的报表工具
Echarts kabana Tableau Superset

## 10.测试相关
1. 公司有多少台测试服务器
一般有三台

2. 测试数据哪来的
一部分自己写java程序自己造，一部分从生产环境中取

3. 如何确保sql的正确性
造一些特定的模拟数据进行测试
离线和实时分析结果比较

4. 测试环境怎么样
测试环境的配置是生产的一半

5. 测试之后如何上限
将脚本打包提交git到git，发邮件抄送经理和总监，运维，通过之后跟运维一起配合上线

## 11.项目实际工作流程
1. 先与产品讨论，看报表的各个数据从哪些埋点中取
2. 将取得逻辑过程设计好，与产品确定后开始开发
3. 开发出报表sql脚本，并且跑几天的历史数据，观察结果
4. 将报表放入调度任务中，第二天给产品看结果
5. 周期性将表结果导出或是导入后台数据库，生成可视化报表

## 12.项目中实现一个需求大概多长时间
刚入职第一个需求大概7天左右，业务熟悉后平均每天一个需求
具体进度也会收到别的因素影响，如开会讨论需求、权限申请和测试

## 13.项目在三年的迭代次数，每个项目具体如何迭代
大约一个月迭代一次，产品或者我们提出优化需求，然后评估时间，每周我们都会开会做本周总结和下周计划，偶尔会讨论预研的新技术。

## 14.项目开发中每天做什么事
新需求(如埋点)，报表来了之后需要设计方案，设计完成后与产品讨论再开发
业务中出现问题，需要查错，如日活月活下降


