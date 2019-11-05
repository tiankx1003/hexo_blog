create table score_tab(
	uid varchar(10),
	subject_id varchar(10),
	score int
);
insert into  `score_tab` values ('001','a',70);
insert into  `score_tab` values ('001','b',60);
insert into  `score_tab` values ('003','a',72);
insert into  `score_tab` values ('004','a',77);
insert into  `score_tab` values ('002','a',72);
insert into  `score_tab` values ('003','b',66);
insert into  `score_tab` values ('001','c',11);
insert into `score_tab` values ('003','c',89);

select subject_id, avg(score),uid
from score_tab
group by subject_id,uid

-- 1
drop table if exists `user_table`;
CREATE EXTERNAL TABLE `user_table`(
	userId string comment '用户编号',
	visitDate string comment '访问日期',
	visitCount int comment '访问次数'
)comment '用户访问数据'
ROW format delimited fields terminated BY '\t';
insert into table `user_table` values ('u02','2017/1/23',6);
insert into table `user_table` values ('u03','2017/1/22',8);
insert into table `user_table` values ('u04','2017/1/20',3);
insert into table `user_table` values ('u01','2017/1/23',6);
insert into table `user_table` values ('u01','2017/2/21',8);
insert into table `user_table` values ('U02','2017/1/23',6);
insert into table `user_table` values ('U01','2017/2/22',4);
insert into table `user_table` values ('u01','2017/1/21',3);
insert into table `user_table` values ('u01','2017/1/21',2);
select * from `user_table`;
-- 统计出每个用户访问数的每月小计和累积
select t2.id `用户id`,t2.mn `月份`,sum_vc `小计`,
	sum(sum_vc) over(partition by t2.id order by t2.mn) `累积`
from(
	select id,mn,sum(vc) sum_vc
	from(
		select lower(userid) id,
			from_unixtime(unix_timestamp(visitdate,'yyyy/mm/dd'),'yyyy-mm') mn,
			visitcount vc
		from user_table
		)t1
	group by id,mn)t2;
-- regexp_replacd(visitdate,'/','-') month 替换符号
---------------------------------------------------------------------
-- 2
drop table if exists visit;
create table visit(
    shop string COMMENT '店铺名称',
    user_id string COMMENT '用户id',
    visit_time string COMMENT '访问时间'
)
row format delimited fields terminated by '\t';
insert into table visit values ('huawei','1005','2017-02-10');
insert into table visit values ('huawei','1005','2017-02-10');
insert into table visit values ('huawei','1005','2017-02-10');
insert into table visit values ('huawei','1005','2017-02-10');
insert into table visit values ('huawei','1004','2017-02-10');
insert into table visit values ('huawei','1004','2017-02-10');
insert into table visit values ('huawei','1003','2017-02-10');
insert into table visit values ('huawei','1003','2017-02-10');
insert into table visit values ('huawei','1001','2017-02-10');
insert into table visit values ('huawei','1002','2017-02-10');
insert into table visit values ('huawei','1006','2017-02-10');
insert into table visit values ('apple','1001','2017-02-10');
insert into table visit values ('apple','1001','2017-02-10');
insert into table visit values ('apple','1001','2017-02-10');
insert into table visit values ('apple','1001','2017-02-10');
insert into table visit values ('apple','1002','2017-02-10');
insert into table visit values ('apple','1002','2017-02-10');
insert into table visit values ('apple','1005','2017-02-10');
insert into table visit values ('apple','1005','2017-02-10');
insert into table visit values ('apple','1006','2017-02-10');
insert into table visit values ('apple','1004','2017-02-10');
insert into table visit values ('meizu','1006','2017-02-10');
insert into table visit values ('meizu','1006','2017-02-10');
insert into table visit values ('meizu','1006','2017-02-10');
insert into table visit values ('meizu','1006','2017-02-10');
insert into table visit values ('meizu','1003','2017-02-10');
insert into table visit values ('meizu','1003','2017-02-10');
insert into table visit values ('meizu','1003','2017-02-10');
insert into table visit values ('meizu','1002','2017-02-10');
insert into table visit values ('meizu','1002','2017-02-10');
insert into table visit values ('meizu','1004','2017-02-10');
select * from visit;
-- 每个店铺的UV（访客数）
select shop,count(distinct(user_id))
from visit
group by shop;

select shop,count(user_id)
from(
	select shop,user_id
	from visit
	group by shop,user_id)t1
group by shop;

-- 每个店铺访问次数top3的访客信息。输出店铺名称、访客id、访问次数

select shop,user_id,rank_num,counts
from(
	select 
		shop,
		user_id,
		counts,
		rank() over(partition by shop order by counts) rank_num
	from(
		select shop,user_id,count(visit_time) counts
		from visit
		group by shop,user_id
		)t1
	)t2
where rank_num<=3;

---------------------------------------------------------------------
-- 3
drop table if exists ORDER_TBL;
create table ORDER_TBL(
    `Date` String COMMENT '下单时间',
    `Order_id` String COMMENT '订单ID',
    `User_id` String COMMENT '用户ID',
    `amount` decimal(10,2) COMMENT '金额')
row format delimited fields terminated by '\t';
insert into table ORDER_TBL values ('2017-10-01','10029011','1000003251',19.50);
insert into table ORDER_TBL values ('2017-10-03','10029012','1000003251',29.50);
insert into table ORDER_TBL values ('2017-10-04','10029013','1000003252',39.50);
insert into table ORDER_TBL values ('2017-10-05','10029014','1000003253',49.50);
insert into table ORDER_TBL values ('2017-11-01','10029021','1000003251',130.50);
insert into table ORDER_TBL values ('2017-11-03','10029022','1000003251',230.50);
insert into table ORDER_TBL values ('2017-11-04','10029023','1000003252',330.50);
insert into table ORDER_TBL values ('2017-11-05','10029024','1000003253',430.50);
insert into table ORDER_TBL values ('2017-11-07','10029025','1000003254',530.50);
insert into table ORDER_TBL values ('2017-11-15','10029026','1000003255',630.50);
insert into table ORDER_TBL values ('2017-12-01','10029027','1000003252',112.50);
insert into table ORDER_TBL values ('2017-12-03','10029028','1000003251',212.50);
insert into table ORDER_TBL values ('2017-12-04','10029029','1000003253',312.50);
insert into table ORDER_TBL values ('2017-12-05','10029030','1000003252',412.50);
insert into table ORDER_TBL values ('2017-12-15','10029032','1000003255',612.50);
select * from order_tbl;
-- 2017年每个月的订单数、用户数、总成交金额
select date_format(`Date`,'yyyy-MM') mn,
	count(order_id) order_num,
	count(distinct(user_id)) user_num,
	sum(amount) amount_sum
from order_tbl
group by date_format(`Date`,'yyyy-MM')

-- 2017年11月的新客数(指在11月才有第一笔订单)
select count(user_id)
from(
	select user_id,`date`,
		lag(`date`,1,'none') over(partition by user_id order by `date`) last_order
	from order_tbl)t1
where last_order='none' and date_format(`date`,'yyyy-MM')='2017-11';

---------------------------------------------------------------------
-- 4
create table users(
	user_id string,
	`name` string,
	age int);
create table views(
	user_id string,
	url string
	);
-- 根据年龄段观看电影的次数对年龄段进行排序
-- TODO 待验证
select age_stage,count(user_id) num 
from 
	(
		select u.user_id, age, url, age/10 age_stage
		from views v 
		left join users u 
	)t1 
group by age_stage
order by num;

---------------------------------------------------------------------
-- 5
drop table if exists user_age;
create table user_age(
    dt string,
    user_id string,
    age int
)
row format delimited fields terminated by ',';.
/*
11,test_1,23
11,test_2,19
11,test_3,39
11,test_1,23
11,test_3,39
11,test_1,23
12,test_2,19
13,test_1,23
15,test_2,19
16,test_2,19
*/
load data inpath '/user/user_age.txt' into table user_age;
select * from user_age;
-- 所有用户和活跃用户(连续两天)的总数及平均年龄
with t0 as
(select count(distinct(user_id)) all_num,floor(avg(age)) all_avg
from user_age)
select count(distinct(user_id)) act_num,avg(age) act_avg
from(
	select user_id,avg(age) age,diff_date,count(age) diff_num
	from(
		select user_id,age,`dt`-`rank_num` diff_date
		from(
			select 
				dt,
				user_id,
				age,
				rank() over(partition by user_id order by dt) rank_num
			from user_age)t1)t2
	group by user_id,diff_date
	having diff_num>=2)t3;


---------------------------------------------------------------------
-- 6
create table ordertable(
	user_id string,
	money decimal(10,2),
	pt string comment 'paymenttime'
);

-- 所有用户中在今年10月份第一次购买商品的金额
select money
from(
	select user_id,money,pt
	from ordertable
	where year(pt)=2019 and month(pt)=10)t1
where day(pt)=min(day(pt));
---------------------------------------------------------------------
-- 7
/*
图书（数据表名：BOOK）
序号	字段名称	字段描述	字段类型
1		BOOK_ID		总编号		文本
2		SORT		分类号		文本
3		BOOK_NAME	书名		文本
4		WRITER		作者		文本
5		OUTPUT		出版单位	文本
6		PRICE		单价		数值（保留小数点后2位）

读者（数据表名：READER）
序号	字段名称	字段描述	字段类型
1		READER_ID	借书证号	文本
2		COMPANY		单位		文本
3		NAME		姓名		文本
4		SEX			性别		文本
5		GRADE		职称		文本
6		ADDR		地址		文本

借阅记录（数据表名：BORROW_LOG）
序号	字段名称	字段描述	字段类型
1		READER_ID	借书证号	文本
2		BOOK_ID		总编号		文本
3		BORROW_DATE	借书日期	日期
*/
create table book(
	book_id string comment '总编号',
	sort string comment '分类号',
	book_name string comment '书名',
	writer string comment '作者',
	`output` string comment '出版单位',
	price decimal(10,2) comment '单价'
);
create table reader(
	reader_id string comment '借书编号',
	company string comment '单位',
	name string comment '姓名',
	sex string comment '性别',
	grade string comment '职称',
	addr string comment '地址'
);
create table borrow_log(
	reader_id string comment '借书编号',
	book_id string comment '总编号',
	borrow_date string comment '借书日期'
);
-- 找出姓李的读者姓名和所在单位
select name, company
from reader 
where name like '李%';

-- 找出高等教育出版社的的所有图书名称和单价,按单价降序排序
select book_name, price
from book
where `output`='高等教育出版社'
order by price desc;

-- 查找价格介于10元和20元之间的图书种类(SORT）出版单位（OUTPUT）和单价（PRICE）,
-- 结果按出版单位（OUTPUT）和单价（PRICE）升序排序
select sort, `output`, price
from book
where price between 10 and 20
order by `output`, price;

-- 查找所有借了书的读者的姓名（NAME）及所在单位（COMPANY）
select r.name, r.company
from borrow_log bl
left join reader r
on bl.reader_id=r.reader_id
group by r.name, r.company;

-- 求”科学出版社”图书的最高单价、最低单价、平均单价
select max(price), min(price), avg(price)
from book
where output='科学出版社';

-- 找出当前至少借阅了2本图书（大于等于2本）的读者姓名及其所在单位
select name, company
from(
	select r.name name,r.company company,count(borrow_date) num 
	from borrow_log bl
	left join reader r
	on bl.reader_id=r.reader_id
	group by r.name,r.company)t1
where num>=2;

-- 请使用一条SQL语句,
-- 在备份用户bak下创建与“借阅记录”表结构完全一致的数据表BORROW_LOG_BAK
-- 并且将“借阅记录”中现有数据全部复制到BORROW_LOG_BAK


-- 写出“图书”在Hive中的建表语句（Hive实现,
-- 提示：列分隔符|；数据表数据需要外部导入：
-- 分区分别以month＿part、day＿part 命名）

-- Hive中有表A,现在需要将表A的月分区201505中user＿id为20000的user＿dinner字段更新为bonc8920,
-- 其他用户user＿dinner字段数据不变,请列出更新的方法步骤。
-- （Hive实现,提示：Hlive中无update语法,请通过其他办法进行数据更新）





---------------------------------------------------------------------
-- 8
-- 有一个线上服务器访问日志格式如下（用sql答题）
-- 时间						接口				ip地址
-- 2016-11-09 11：22：05	/api/user/login		110.23.5.33
-- 2016-11-09 11：23：10	/api/user/detail	57.3.2.16
-- .....
-- 2016-11-09 23：59：40	/api/user/login		200.6.5.166
create table net(
	dt string,
	port string,
	ip string
);

-- 求11月9号下午14点（14-15点）,访问api/user/login接口的top10的ip地址
select ip,count(dt) num
from(
select dt, port, ip 
	from net
	where year(dt)=2016 and month(dt)=11 and day(dt)=9 and hour(dt)=14
		and port='api/user/login'
)t1
group by ip
order by num desc;
-- TODO 尝试用开窗的方式解决

---------------------------------------------------------------------
-- 9
create table credit_log(
	dist_id int comment '区组id',
	account string comment '账号',
	money int comment '充值金额',
	create_time string comment '订单时间'
);
-- 请写出SQL语句,查询充值日志表2015年7月9号每个区组下充值额最大的账号,
-- 要求结果：区组id,账号,金额,充值时间
select dist_id,max(money)
from credit_log
where create_time='2015-07-09'
group by dist_id;


---------------------------------------------------------------------
-- 10
-- 查询各自区组的money排名前十的账号（分组取前10）
select account
from(
	select account,
		row_number() over(partition by dist_id order by money desc) rank_num
	from credit_log)t1
where rank_num<=10;

---------------------------------------------------------------------
-- 11
create table member(
	memberid string comment '会员id',
	credits string comment '积分'
);
create table sale(
	memberid string comment '会员id',
	MNAccount string comment '购买金额'
);
create table member(
	memberid string comment '会员id',
	RMNAccount string comment '退货金额'
);

---------------------------------------------------------------------
-- 12
-- score中的id、cid，分别是student、course
create table student
(
	id bigint comment '学号',
	name string comment '姓名',
	age bigint comment '年龄'
);
create table course
(
	cid string comment '课程号,001/002格式',
	cname string comment '课程名'
);
Create table score
(
	Id bigint comment '学号',
	cid string comment '课程号',
	score bigint comment '成绩'
) partitioned by(event_day string);
