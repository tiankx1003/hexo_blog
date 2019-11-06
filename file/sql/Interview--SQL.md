---
title: Interview--SQL
typora-copy-images-to: Interview--SQL
tags:
 - BigData
 - Interview
---
1. 表结构：uid,subject_id,score
    求：找出所有科目成绩都大于某一学科平均成绩的用户

```sql
SELECT uid, subject_id, avg_sub, score
FROM (
	SELECT uid, t1.subject_id, score, avg_sub
	FROM score_tab t1
		JOIN (
			SELECT subject_id, AVG(score) AS avg_sub
			FROM score_tab
			GROUP BY subject_id
		) t2
		ON t1.subject_id = t2.subject_id
) t3
WHERE score > avg_sub;
```


2. 有如下的用户访问数据

| userId | visitDate | visitCount |
| ------ | --------- | ---------- |
| u01    | 2017/1/21 | 5          |
| u02    | 2017/1/23 | 6          |
| u03    | 2017/1/22 | 8          |
| u04    | 2017/1/20 | 3          |
| u01    | 2017/1/23 | 6          |
| u01    | 2017/2/21 | 8          |
| U02    | 2017/1/23 | 6          |
| U01    | 2017/2/22 | 4          |

要求使用sql统计出每个用户的累积访问次数，结果如下

| 用户id | 月份    | 小计 | 累积 |
| ------ | ------- | ---- | ---- |
| u01    | 2017-01 | 11   | 11   |
| u01    | 2017-02 | 12   | 23   |
| u02    | 2017-01 | 12   | 12   |
| u03    | 2017-01 | 8    | 8    |
| u04    | 2017-01 | 3    | 3    |

```sql
-- 用户名大小写转换，日期格式转换，开窗计算小计和累积
SELECT t2.id AS `用户id`, t2.mn AS `月份`, sum_vc AS `小计`, SUM(sum_vc) OVER (PARTITION BY t2.id ORDER BY t2.mn) AS `累积`
FROM (
	SELECT id, mn, SUM(vc) AS sum_vc
	FROM (
		SELECT lower(userid) AS id, from_unixtime(unix_timestamp(visitdate, 'yyyy/mm/dd'), 'yyyy-mm') AS mn, visitcount AS vc
		FROM user_table
	) t1
	GROUP BY id, mn
) t2;
```

3. 有50W个京东店铺，每个顾客访客访问任何一个店铺的任何一个商品时都会产生一条访问日志，访问日志存储的表名为Visit，访客的用户id为user_id，被访问的店铺名称为shop，请统计：

   1）每个店铺的UV（访客数）

   2）每个店铺访问次数的访客信息。输出店铺名称、访客、访问次数

```sql

```

4. 已知一个表STG.ORDER，有如下字段:Date，Order_id，User_id，amount。请给出sql进行统计:数据样例:2017-01-01,10029028,1000003251,33.57。

   1）给出 2017年每个月的订单数、用户数、总成交金额。

   2）给出年月的新客数指在月才有第一笔订单

```sql

```

5. 有一个5000万的用户文件(user_id，name，age)，一个2亿记录的用户看电影的记录文件(user_id，url)，统计各年龄段观看电影的次数

```sql

```

6.有日志如下，请写出代码求得所有用户和活跃用户的总数及平均年龄。（活跃用户指连续两天都有访问记录的用户）

```
日期 用户 年龄
11,test_1,23
11,test_2,19
11,test_3,39
11,test_1,23
11,test_3,39
11,test_1,23
12,test_2,19
13,test_1,23
```

```sql

```

7. 请用sql写出所有用户中在今年10月份第一次购买商品的金额，表ordertable字段（购买用户：userid，金额：money，购买时间：paymenttime(格式：2017-10-01)，订单id：orderid）

```sql

```

8. 有一个线上服务器访问日志格式如下（用sql答题）
```
时间           			接口             		ip地址
2016-11-09 11：22：05  	/api/user/login        110.23.5.33
2016-11-09 11：23：10 	/api/user/detail       57.3.2.16
.....
2016-11-09 23：59：40  	/api/user/login        200.6.5.166
```
   求11月9号下午14点（14-15点），访问api/user/login接口的top10的ip地址

```sql

```

9. 有一个账号表如下，请写出SQL语句，查询各自区组的money排名前十的账号（分组取前10）

```sql
CREATE TABIE `account` 
(
    `dist_id` int（11）
    DEFAULT NULL COMMENT '区组id'，
    `account` varchar（100）DEFAULT NULL COMMENT '账号' ,
    `gold` int（11）DEFAULT NULL COMMENT '金币' 
    PRIMARY KEY （`dist_id`，`account_id`），
）ENGINE=InnoDB DEFAULT CHARSET-utf8
```

```sql

```