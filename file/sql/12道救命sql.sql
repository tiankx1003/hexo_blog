--建表
drop table if exists test_one;
create table test_one(
    userId string comment '用户id',
    visitDate string comment '访问日期',
    visitCount bigint comment '访问次数'
) comment '第一题'
row format delimited fields terminated by '\t';

--插入数据
insert into table test_one values('u01','2017/1/21',5);
insert into table test_one values('u02','2017/1/23',6);
insert into table test_one values('u03','2017/1/22',8);
insert into table test_one values('u04','2017/1/20',3);
insert into table test_one values('u01','2017/1/23',6);
insert into table test_one values('u01','2017/2/21',8);
insert into table test_one values('u02','2017/1/23',6);
insert into table test_one values('u01','2017/2/22',4);

--查询
select
    userId `用户id`,
    visitDate `月份`,
    sum_mn `小计`,
    sum(sum_mn) over(partition by userId rows between UNBOUNDED PRECEDING and current row) `累计` 
from
(
    select
        t1.userId,
        t1.visitDate,
        sum(t1.visitCount) sum_mn
    from
    (
        select 
            userId,
            date_format(to_date(from_unixtime(UNIX_TIMESTAMP(visitDate,'yyyy/MM/dd'))),'yyyy-MM') visitDate,
            --regexp_replace(substring(visitDate,1,6),'/','-') visitDate,
            visitCount
        from test_one
    ) t1
    group by userId,visitDate
) t2;

==================================== 第二题 ===============================
有50W个京东店铺，每个顾客访客访问任何一个店铺的任何一个商品时都会产生一条访问日志，访问日志存储的表名为Visit，访客的用户id为user_id，被访问的店铺名称为shop，请统计：
1）每个店铺的UV（访客数）
2）每个店铺访问次数top3的访客信息。输出店铺名称、访客id、访问次数

--建表
drop table if exists test02_Visit;
create table test_two(
    shoop_name string COMMENT '店铺名称',
    user_id string COMMENT '用户id',
    visit_time string COMMENT '访问时间'
)
row format delimited fields terminated by '\t';

--插入数据
insert into table test_two values ('huawei','1001','2017-02-10');
insert into table test_two values ('icbc','1001','2017-02-10');
insert into table test_two values ('huawei','1001','2017-02-10');
insert into table test_two values ('apple','1001','2017-02-10');
insert into table test_two values ('huawei','1001','2017-02-10');
insert into table test_two values ('huawei','1002','2017-02-10');
insert into table test_two values ('huawei','1002','2017-02-10');
insert into table test_two values ('huawei','1001','2017-02-10');
insert into table test_two values ('huawei','1003','2017-02-10');
insert into table test_two values ('huawei','1004','2017-02-10');
insert into table test_two values ('huawei','1005','2017-02-10');
insert into table test_two values ('icbc','1002','2017-02-10');
insert into table test_two values ('jingdong','1006','2017-02-10');
insert into table test_two values ('jingdong','1003','2017-02-10');
insert into table test_two values ('jingdong','1002','2017-02-10');
insert into table test_two values ('jingdong','1004','2017-02-10');
insert into table test_two values ('apple','1001','2017-02-10');
insert into table test_two values ('apple','1001','2017-02-10');
insert into table test_two values ('apple','1001','2017-02-10');
insert into table test_two values ('apple','1002','2017-02-10');
insert into table test_two values ('apple','1002','2017-02-10');
insert into table test_two values ('apple','1005','2017-02-10');
insert into table test_two values ('apple','1005','2017-02-10');
insert into table test_two values ('apple','1006','2017-02-10');

--1)每个店铺的UV（访客数）
select 
    shoop_name,
    count(*) shoop_uv
from test_two
group by shoop_name
order by shoop_uv desc;

--2）每个店铺访问次数top3的访客信息。输出店铺名称、访客id、访问次数
select
    shoop_name `商店名称`,
    user_id `用户id`,
    visit_time `访问次数`,
    rank_vis `忠诚排名`
from
    (
    select
        shoop_name,
        user_id,
        visit_time,
        row_number() over(partition by shoop_name order by visit_time desc) rank_vis

    from
    (
        select
            shoop_name,
            user_id,
            count(*) visit_time
        from test_two
        group by shoop_name,user_id
    ) t1
) t2
where rank_vis<=3;

==================================== 第三题 ===============================

-- 已知一个表STG.ORDER,有如下字段:Date,Order_id,User_id,amount。
-- 请给出sql进行统计:数据样例:2017-01-01,10029028,1000003251,33.57。
-- 1）给出 2017年每个月的订单数、用户数、总成交金额。
-- 2）给出2017年11月的新客数(指在11月才有第一笔订单)

drop table if exists test_three_ORDER;
create table test_three_ORDER
(
    `Date` String COMMENT '下单时间',
    `Order_id` String COMMENT '订单ID',
    `User_id` String COMMENT '用户ID',
    `amount` decimal(10,2) COMMENT '金额'
)
row format delimited fields terminated by '\t';

--插入数据
insert into table test_three_ORDER values ('2017-10-01','10029011','1000003251',19.50);
insert into table test_three_ORDER values ('2017-10-03','10029012','1000003251',29.50);
insert into table test_three_ORDER values ('2017-10-04','10029013','1000003252',39.50);
insert into table test_three_ORDER values ('2017-10-05','10029014','1000003253',49.50);
insert into table test_three_ORDER values ('2017-11-01','10029021','1000003251',130.50);
insert into table test_three_ORDER values ('2017-11-03','10029022','1000003251',230.50);
insert into table test_three_ORDER values ('2017-11-04','10029023','1000003252',330.50);
insert into table test_three_ORDER values ('2017-11-05','10029024','1000003253',430.50);
insert into table test_three_ORDER values ('2017-11-07','10029025','1000003254',530.50);
insert into table test_three_ORDER values ('2017-11-15','10029026','1000003255',630.50);
insert into table test_three_ORDER values ('2017-12-01','10029027','1000003252',112.50);
insert into table test_three_ORDER values ('2017-12-03','10029028','1000003251',212.50);
insert into table test_three_ORDER values ('2017-12-04','10029029','1000003253',312.50);
insert into table test_three_ORDER values ('2017-12-05','10029030','1000003252',412.50);
insert into table test_three_ORDER values ('2017-12-07','10029031','1000003258',512.50);
insert into table test_three_ORDER values ('2017-12-15','10029032','1000003255',612.50);

-- 1）给出 2017年每个月的订单数、用户数、总成交金额。

select
    date_format(`date`,'yyyy-MM') `date`,
    count(*) `订单数`,
    count(distinct(user_id)) `用户数`,
    sum(amount) `总成交金额`
from test_three_ORDER
group by date_format(`date`,'yyyy-MM');

-- 2）给出2017年11月的新客数(指在11月才有第一笔订单)
select
    t1.user_id
from
(
    select
        user_id
    from test_three_ORDER
    where date_format(`date`,'yyyy-MM') = '2017-11'
    group by user_id
) t1
left join
(
select
    user_id
from test_three_ORDER
where date_format(`date`,'yyyy-MM') < '2017-11'
group by user_id
) t2
on t1.user_id = t2.user_id
where t2.user_id is null;
-- 第二种写法
select
    count(User_id) `11月新客数`
from
(
    SELECT
        User_id,
        Order_id,
        `Date`,
        LAG (`DATE`,1,0) over(partition by User_id order by `Date`) preOrder
    FROM
        test_three_ORDER
) t1
where date_format(`date`,'yyyy-MM')='2017-11' and preOrder=0;

==================================== 第四题 ===============================
-- 有一个5000万的用户文件(user_id,name,age),一个2亿记录的用户看电影的记录文件(user_id,url),
-- 根据年龄段观看电影的次数进行排序？
--建表
--用户表
drop table if exists test_four_log;
create table test_four_user(
    user_id string COMMENT '用户ID',
    name string COMMENT '用户姓名',
    age int COMMENT '用户年龄'
) 
row format delimited fields terminated by '\t';
--日志表
drop table if exists test_four_log;
create table test_four_log(
    user_id string COMMENT '用户ID',
    url string COMMENT '链接'
)
row format delimited fields terminated by '\t';
--插入数据
insert into table test_four_user values ('1','1',8);
insert into table test_four_user values ('2','2',45);
insert into table test_four_user values ('3','3',14);
insert into table test_four_user values ('4','4',18);
insert into table test_four_user values ('5','5',17);
insert into table test_four_user values ('6','6',19);
insert into table test_four_user values ('7','7',26);
insert into table test_four_user values ('8','8',22);
insert into table test_four_log values('1','111');
insert into table test_four_log values('2','111');
insert into table test_four_log values('3','111');
insert into table test_four_log values('4','111');
insert into table test_four_log values('5','111');
insert into table test_four_log values('6','111');
insert into table test_four_log values('7','111');
insert into table test_four_log values('8','111');
insert into table test_four_log values('1','111');
insert into table test_four_log values('2','111');
insert into table test_four_log values('3','111');
insert into table test_four_log values('4','111');
insert into table test_four_log values('5','111');
insert into table test_four_log values('6','111');
insert into table test_four_log values('7','111');
insert into table test_four_log values('8','111');
insert into table test_four_log values('1','111');
insert into table test_four_log values('2','111');
insert into table test_four_log values('3','111');
insert into table test_four_log values('4','111');
insert into table test_four_log values('5','111');
insert into table test_four_log values('6','111');
insert into table test_four_log values('7','111');
insert into table test_four_log values('8','111');

-- 根据年龄段观看电影的次数进行排序？
select
    age_size `年龄段`,
    count(*) `观影次数`
from
(
    select
    u.*,
    l.url,
    case
    when u.age >=0 and u.age <= 10 then '1-10'
    when u.age >=11 and u.age <= 20 then '11-20'
    when u.age >=21 and u.age <= 30 then '21-30'
    when u.age >=31 and u.age <= 40 then '31-40'
    when u.age >=41 and u.age <= 50 then '41-50'
    else '51-100'
    end age_size
    from
    test_four_user u join test_four_log l on u.user_id = l.user_id 
) t1
group by age_size
order by `观影次数` desc;

==================================== 第五题 ===============================
-- 有日志如下，请写出代码求得所有用户和活跃用户的总数及平均年龄。（活跃用户指连续两天都有访问记录的用户）
-- 日期 用户 年龄
-- 11,test_1,23
-- 11,test_2,19
-- 11,test_3,39
-- 11,test_1,23
-- 11,test_3,39
-- 11,test_1,23
-- 12,test_2,19
-- 13,test_1,23

create table test_five_active(
    active_time string COMMENT '活跃日期',
    user_id string COMMENT '用户id',
    age int COMMENT '用户年龄'
)
row format delimited fields terminated by '\t';

insert into table test_five_active values ('11','test_1',11);
insert into table test_five_active values ('11','test_2',22);
insert into table test_five_active values ('11','test_3',33);
insert into table test_five_active values ('11','test_4',44);

insert into table test_five_active values ('12','test_3',33);
insert into table test_five_active values ('12','test_5',55);
insert into table test_five_active values ('12','test_6',66);

insert into table test_five_active values ('13','test_4',44);
insert into table test_five_active values ('13','test_5',55);
insert into table test_five_active values ('13','test_7',77);

-- 所有用户的总数及平均年龄
select
    count(*) sum_user,
    avg(age) avg_age
from
(
    select 
        user_id,
        avg(age) age
    from test_five_active
    group by user_id
) t1;

-- 活跃人数的总数及平均年龄
select  -- 最外一层算出活跃用户的个数以及平均年龄
    count(*),
    avg(d.age)
from
(
    select -- 最后还需要以user_id分组,去重(防止某个用户在11,12号连续活跃,然后在14,15号又连续活跃,导致diff求出不一致,所以此用户会出现两次)
        c.user_id,
        c.age
    from
    (
        select -- 以用户和差值diff分组,看分组下的数据的个数是否大于等于2(连续两天登录),取出活跃用户的数据
            b.user_id,
            b.age,
            b.diff,
            count(*) flag
        from
        (
            select  -- 用活跃日期减去排名,求出差值,看差值是否相等,相等差值的数据肯定是连续活跃的数据
                a.active_time,
                a.user_id,
                a.age,
                a.rank_time,
                a.active_time-a.rank_time diff 
            from
            (
                select  -- 以用户和活跃日期分组(去重,防止某个用户在同一天活跃多次),求出每个用户的活跃日期排名
                    active_time,
                    user_id,
                    age,
                    rank() over(partition by user_id order by active_time) rank_time

                from test_five_active
                group by active_time,user_id,age   
            ) a
        ) b
        group by b.user_id,b.age,b.diff
        having count(*) >=2
    ) c
    group by c.user_id,c.age
) d;

==================================== 第六题 ===============================
请用sql写出所有用户中在今年10月份第一次购买商品的金额，
表ordertable字段（购买用户：userid，金额：money，购买时间：paymenttime(格式：2017-10-01)，订单id：orderid）

create table test_six_ordertable
(
    `userid` string COMMENT '购买用户',
    `money` decimal(10,2) COMMENT '金额',
    `paymenttime` string COMMENT '购买时间',
    `orderid` string COMMENT '订单id'
)
row format delimited fields terminated by '\t';

--插入数据
insert into table test_six_ordertable values('1',1,'2017-09-01','1');
insert into table test_six_ordertable values('2',2,'2017-09-02','2');
insert into table test_six_ordertable values('3',3,'2017-09-03','3');
insert into table test_six_ordertable values('4',4,'2017-09-04','4');

insert into table test_six_ordertable values('3',5,'2017-10-05','5');
insert into table test_six_ordertable values('6',6,'2017-10-06','6');
insert into table test_six_ordertable values('1',7,'2017-10-07','7');
insert into table test_six_ordertable values('8',8,'2017-10-09','8');
insert into table test_six_ordertable values('6',6,'2017-10-16','60');
insert into table test_six_ordertable values('1',7,'2017-10-17','70');

-- 写出所有用户中在今年10月份第一次购买商品的金额
select
    userid,
    `money`,
    paymenttime,
    orderid
from
(
    select
        userid,
        `money`,
        paymenttime,
        orderid,
        rank() over(partition by userid order by paymenttime) rank_time
    from test_six_ordertable
    where date_format(paymenttime,'yyyy-MM') = '2017-10'
) a
where rank_time=1;


==================================== 第七题 ===============================
--现有图书管理数据库的三个数据模型如下：

--图书（数据表名：BOOK）
--序号    字段名称     字段描述       字段类型
--1       BOOK_ID     总编号         文本
--2       SORT        分类号         文本
--3       BOOK_NAME   书名           文本
--4       WRITER      作者           文本
--5       OUTPUT      出版单位       文本
--6       PRICE       单价           数值（保留小数点后2位）

--读者（数据表名：READER）
--序号      字段名称        字段描述    字段类型
--1       READER_ID       借书证号         文本
--2       COMPANY         单位            文本
--3       NAME            姓名             文本
--4       SEX             性别          文本
--5       GRADE           职称          文本
--6       ADDR            地址          文本
--
--借阅记录（数据表名：BORROW LOG）
--序号      字段名称        字段描述        字段类型
--1        READER_ID      借书证号            文本
--2       BOOK_D          总编号             文本
--3       BORROW_ATE      借书日期            日期


--（1）创建图书管理库的图书、读者和借阅三个基本表的表结构。请写出建表语句。
--图书
create table test_seven_BOOK
(
    BOOK_ID String COMMENT '总编号',
    SORT String COMMENT '分类号',
    BOOK_NAME String COMMENT '书名',
    WRITER String COMMENT '作者',
    OUTPUT String COMMENT '出版单位',
    PRICE decimal(10,2) COMMENT '单价'
)
row format delimited fields terminated by '\t';

--读者
create table test_seven_READER
(  
    READER_ID String COMMENT '借书证号',
    COMPANY String COMMENT '单位',
    NAME String COMMENT '姓名',
    SEX String COMMENT '性别',
    GRADE String COMMENT '职称',
    ADDR String COMMENT '地址'
)
row format delimited fields terminated by '\t';

--借阅记录
create table test_seven_BORROW_LOG
(   
    READER_ID String COMMENT '借书证号',
    BOOK_D String COMMENT '总编号',
    BORROW_ATE date COMMENT '借书日期'
)
row format delimited fields terminated by '\t';

-- 插入数据
insert into table test_seven_book values ('1001','A1','Java','James Gosling','sun','11');
insert into table test_seven_book values ('1002','A2','linux','Linus Benedict Torvalds','sun','22');
insert into table test_seven_book values ('1003','A3','Java3','James Gosling3','sun3','33');
insert into table test_seven_book values ('1004','A4','Java4','James Gosling4','sun4','44');
insert into table test_seven_book values ('1005','B1','Java5','James Gosling5','sun','55');
insert into table test_seven_book values ('1006','C1','Java6','James Gosling6','sun5','66');
insert into table test_seven_book values ('1007','D1','Java7','James Gosling7','sun6','77');
insert into table test_seven_book values ('1008','E1','Java8','James Gosling4','sun3','88');
insert into table test_seven_reader values ('7','buu',decode(binary('李大帅'),'utf-8'),'man','lay1','beijing4');
insert into table test_seven_reader values ('2','buu2','苏大强','man','lay2','beijing2');
insert into table test_seven_reader values ('3','buu2','李二胖','woman','lay3','beijing3');
insert into table test_seven_reader values ('4','buu3','王三涛','man','lay4','beijing4');
insert into table test_seven_reader values ('5','buu4','刘四虎','woman','lay5','beijing1');
insert into table test_seven_reader values ('6','buu','宋冬野','woman','lay6','beijing5');
insert into table test_seven_borrow_log values ('1','1002','2019-06-01');
insert into table test_seven_borrow_log values ('1','1003','2019-06-02');
insert into table test_seven_borrow_log values ('1','1006','2019-06-03');
insert into table test_seven_borrow_log values ('2','1001','2019-06-04');
insert into table test_seven_borrow_log values ('3','1002','2019-06-05');
insert into table test_seven_borrow_log values ('4','1005','2019-06-06');
insert into table test_seven_borrow_log values ('5','1003','2019-06-06');
insert into table test_seven_borrow_log values ('3','1006','2019-06-07');
insert into table test_seven_borrow_log values ('2','1003','2019-06-03');
insert into table test_seven_borrow_log values ('3','1008','2019-06-03');
insert into table test_seven_borrow_log values ('1','1002','2019-06-04');
--（2）找出姓李的读者姓名（NAME）和所在单位（COMPANY）。
select name,company from test_seven_reader where name like '李%';
--（3）查找“高等教育出版社”的所有图书名称（BOOK_NAME）及单价（PRICE）,结果按单价降序排序。
select BOOK_NAME,PRICE from test_seven_book order by PRICE desc;
--（4）查找价格介于10元和20元之间的图书种类(SORT）出版单位（OUTPUT）和单价（PRICE）,结果按出版单位（OUTPUT）和单价（PRICE）升序排序。
select SORT,OUTPUT,PRICE from test_seven_book where PRICE between 10 and 20 order by OUTPUT,PRICE asc;

--（5）查找所有借了书的读者的姓名（NAME）及所在单位（COMPANY）。
select
    rd.name,
    rd.COMPANY
from
(
select
    READER_ID
from test_seven_borrow_log
group by READER_ID
) t1
join 
test_seven_reader rd
on t1.READER_ID = rd.READER_ID; 
--（6）求”科学出版社”图书的最高单价、最低单价、平均单价。
select
    max(PRICE) max,
    min(PRICE) min,
    avg(PRICE) avg
from
test_seven_book;
--（7）找出当前至少借阅了2本图书（大于等于2本）的读者姓名及其所在单位。
select
   rd.READER_ID,
   rd.name,
   rd.COMPANY 
from
(
    select
        READER_ID,
        count(*) num
    from test_seven_BORROW_LOG
    group by READER_ID
    having count(*) >= 2
) t1
join
test_seven_reader rd
on t1.READER_ID = rd.READER_ID;

--（8）考虑到数据安全的需要,需定时将“借阅记录”中数据进行备份,
-- 请使用一条SQL语句,在备份用户bak下创建与“借阅记录”表结构完全一致的数据表BORROW_LOG_BAK.
--井且将“借阅记录”中现有数据全部复制到BORROW_l0G_BAK中。
create table BORROW_LOG_BAK
(
    READER_ID String COMMENT '借书证号',
    BOOK_D String COMMENT '总编号',
    BORROW_ATE date COMMENT '借书日期'
)
as select * from test_seven_BORROW_LOG;

--（9）现在需要将原Oracle数据库中数据迁移至Hive仓库,
--请写出“图书”在Hive中的建表语句（Hive实现,提示：列分隔符|；数据表数据需要外部导入：分区分别以month＿part、day＿part 命名）
create table test_seven_book_oracle (
    book_id string COMMENT '总编号',
    sort string COMMENT '分类号',
    book_name string COMMENT '书名',
    writer string COMMENT '作者',
    output string COMMENT '出版单位',
    price decimal(10,2) COMMENT '单价'
)
PARTITIONED BY (month string,day string)
row format delimited fields terminated by '|';

--（10）Hive中有表A,现在需要将表A的月分区　201505　中　user＿id为20000的user＿dinner字段更新为bonc8920,
--  其他用户user＿dinner字段数据不变,请列出更新的方法步骤。
--（Hive实现,提示：Hlive中无update语法,请通过其他办法进行数据更新）
create table tmp_A as select * from A where user_id<>20000 and month_part=201505;
insert into table tmp_A partition(month_part=’201505’) values(20000,其他字段,bonc8920);
insert overwrite table A partition(month_part=’201505’) select * from tmp_A where month_part=201505;





==================================== 第八题 ===============================
-- 有一个线上服务器访问日志格式如下（用sql答题）
--        时间                   接口                           ip地址
-- 2016-11-09 11：22：05    /api/user/login                  110.23.5.33
-- 2016-11-09 11：23：10    /api/user/detail                 57.3.2.16
-- .....
-- 2016-11-09 23：59：40    /api/user/login                  200.6.5.166
-- 求11月9号下午14点（14-15点），访问api/user/login接口的top10的ip地址

create table test_eight_serverlog
(
    server_time string COMMENT '时间',
    server_api  string comment '接口',
    server_ip string COMMENT 'ip地址'
)
row format delimited fields terminated by '\t';

insert into table test_eight_serverlog values ('2016-11-09 11:22:05','/api/user/login','110.23.5.33');
insert into table test_eight_serverlog values ('2016-11-09 11:23:10','/api/user/detail','57.3.2.16');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.161');
insert into table test_eight_serverlog values ('2016-11-09 14:22:05','/api/user/login','110.23.5.32');
insert into table test_eight_serverlog values ('2016-11-09 14:23:10','/api/user/detail','57.3.2.13');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.164');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.165');
insert into table test_eight_serverlog values ('2016-11-09 14:22:05','/api/user/login','110.23.5.36');
insert into table test_eight_serverlog values ('2016-11-09 14:23:10','/api/user/detail','57.3.2.17');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.168');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.168');
insert into table test_eight_serverlog values ('2016-11-09 14:22:05','/api/user/login','110.23.5.32');
insert into table test_eight_serverlog values ('2016-11-09 14:23:10','/api/user/detail','57.3.2.13');
insert into table test_eight_serverlog values ('2016-11-09 14:59:40','/api/user/login','200.6.5.164');
insert into table test_eight_serverlog values ('2016-11-09 15:22:05','/api/user/login','110.23.5.33');
insert into table test_eight_serverlog values ('2016-11-09 15:23:10','/api/user/detail','57.3.2.16');
insert into table test_eight_serverlog values ('2016-11-09 15:59:40','/api/user/login','200.6.5.166');


select
    server_ip,
    count(*) visit_time 
from test_eight_serverlog
where date_format(server_time,'yyyy-MM-dd HH')='2016-11-09 14' 
and server_api = '/api/user/login'
group by server_ip
order by visit_time desc;

==================================== 第九题 ===============================
--第9题
-- 有一个充值日志表如下：
-- CREATE TABLE `credit log` 
-- (
--     `dist_id` int（11）DEFAULT NULL COMMENT '区组id',
--     `account` varchar（100）DEFAULT NULL COMMENT '账号',
--     `money` int(11) DEFAULT NULL COMMENT '充值金额',
--     `create_time` datetime DEFAULT NULL COMMENT '订单时间'
-- )ENGINE=InnoDB DEFAUILT CHARSET-utf8
-- 请写出SQL语句,查询充值日志表2015年7月9号每个区组下充值额最大的账号,要求结果：
-- 区组id,账号,金额,充值时间
--建表
create table test_nine_credit_log(
    dist_id string COMMENT '区组id',
    account string COMMENT '账号',
    `money` decimal(10,2) COMMENT '充值金额',
    create_time string COMMENT '订单时间'
)
row format delimited fields terminated by '\t';

--插入数据
insert into table test_nine_credit_log values ('1','11',100006,'2019-01-02 13:00:01');
insert into table test_nine_credit_log values ('1','12',110000,'2019-01-02 13:00:02');
insert into table test_nine_credit_log values ('1','13',102000,'2019-01-02 13:00:03');
insert into table test_nine_credit_log values ('1','14',100300,'2019-01-02 13:00:04');
insert into table test_nine_credit_log values ('1','15',100040,'2019-01-02 13:00:05');
insert into table test_nine_credit_log values ('1','18',110000,'2019-01-02 13:00:02');
insert into table test_nine_credit_log values ('1','16',100005,'2019-01-03 13:00:06');
insert into table test_nine_credit_log values ('1','17',180000,'2019-01-03 13:00:07');


insert into table test_nine_credit_log values ('2','21',100800,'2019-01-02 13:00:11');
insert into table test_nine_credit_log values ('2','22',100030,'2019-01-02 13:00:12');
insert into table test_nine_credit_log values ('2','23',100000,'2019-01-02 13:00:13');
insert into table test_nine_credit_log values ('2','24',100010,'2019-01-03 13:00:14');
insert into table test_nine_credit_log values ('2','25',100070,'2019-01-03 13:00:15');
insert into table test_nine_credit_log values ('2','26',100800,'2019-01-02 15:00:11');

insert into table test_nine_credit_log values ('3','31',106000,'2019-01-02 13:00:08');
insert into table test_nine_credit_log values ('3','32',100400,'2019-01-02 13:00:09');
insert into table test_nine_credit_log values ('3','33',100030,'2019-01-02 13:00:10');
insert into table test_nine_credit_log values ('3','34',100003,'2019-01-02 13:00:20');
insert into table test_nine_credit_log values ('3','35',100020,'2019-01-02 13:00:30');
insert into table test_nine_credit_log values ('3','36',100500,'2019-01-02 13:00:40');
insert into table test_nine_credit_log values ('3','37',106000,'2019-01-03 13:00:50');
insert into table test_nine_credit_log values ('3','38',100800,'2019-01-03 13:00:59');

--查询充值日志表2019年1月2号每个区组下充值额最大的账号,要求结果：区组id,账号,金额,充值时间
select
    aaa.dist_id,
    aaa.account,
    aaa.`money`,
    aaa.create_time,
    aaa.money_rank
from
(
    select
        dist_id,
        account,
        `money`,
        create_time,
        dense_rank() over(partition by dist_id order by `money` desc) money_rank   -- dense_rank最完美,因为不仅可以求第一多,而且还可以求第二多,第三多...
    from test_nine_credit_log
    where date_format(create_time,'yyyy-MM-dd') = '2019-01-02'
) aaa
where money_rank = 1;

-- 第二种写法,不用开窗函数
with 
tmp_max_money as(
    select 
        dist_id,
        max(`money`) max
    from test_nine_credit_log
    where date_format(create_time,'yyyy-MM-dd')='2019-01-02'
    group by dist_id
)
select 
    cl.dist_id dist_id,cl.account acount,cl.money money,cl.create_time create_time
from test_nine_credit_log cl 
left join tmp_max_money mm 
on cl.dist_id=mm.dist_id
where cl.money=mm.max and date_format(create_time,'yyyy-MM-dd')='2019-01-02';

==================================== 第十题 ===============================
--第10题
-- 有一个账号表如下,请写出SQL语句,查询各自区组的money排名前十的账号（分组取前10）
-- CREATE TABIE `account` 
-- (
--     `dist_id` int（11）
--     DEFAULT NULL COMMENT '区组id',
--     `account` varchar（100）DEFAULT NULL COMMENT '账号' ,
--     `gold` int（11）DEFAULT NULL COMMENT '金币' 
--     PRIMARY KEY （`dist_id`,`account_id`）,
-- ）ENGINE=InnoDB DEFAULT CHARSET-utf8
-- 替换成hive表
drop table if exists `test_ten_account`;
create table `test_ten_account`(
    `dist_id` string COMMENT '区组id',
    `account` string COMMENT '账号',
    `gold` bigint COMMENT '金币'
)
row format delimited fields terminated by '\t';

insert into table test_ten_account values ('1','11',100006);
insert into table test_ten_account values ('1','12',110000);
insert into table test_ten_account values ('1','13',102000);
insert into table test_ten_account values ('1','14',100300);
insert into table test_ten_account values ('1','15',100040);
insert into table test_ten_account values ('1','18',110000);
insert into table test_ten_account values ('1','16',100005);
insert into table test_ten_account values ('1','17',180000);

insert into table test_ten_account values ('2','21',100800);
insert into table test_ten_account values ('2','22',100030);
insert into table test_ten_account values ('2','23',100000);
insert into table test_ten_account values ('2','24',100010);
insert into table test_ten_account values ('2','25',100070);
insert into table test_ten_account values ('2','26',100800);

insert into table test_ten_account values ('3','31',106000);
insert into table test_ten_account values ('3','32',100400);
insert into table test_ten_account values ('3','33',100030);
insert into table test_ten_account values ('3','34',100003);
insert into table test_ten_account values ('3','35',100020);
insert into table test_ten_account values ('3','36',100500);
insert into table test_ten_account values ('3','37',106000);
insert into table test_ten_account values ('3','38',100800);

select
    dist_id,
    account,
    gold,
    gold_rank
from
(
    select
        `dist_id`,
        `account`,
        `gold`,
        dense_rank() over(partition by dist_id order by gold desc) gold_rank
    from test_ten_account
) tmp
where gold_rank <= 3;

==================================== 第十一题 ===============================
-- 第11题
-- 1）有三张表分别为会员表（member）销售表（sale）退货表（regoods）
-- （1）会员表有字段memberid（会员id,主键）credits（积分）；
-- （2）销售表有字段memberid（会员id,外键）购买金额（MNAccount）；
-- （3）退货表中有字段memberid（会员id,外键）退货金额（RMNAccount）；
-- 2）业务说明：
-- （1）销售表中的销售记录可以是会员购买,也可是非会员购买。（即销售表中的memberid可以为空）
-- （2）销售表中的一个会员可以有多条购买记录
-- （3）退货表中的退货记录可以是会员,也可是非会员4、一个会员可以有一条或多条退货记录
-- 查询需求：分组查出销售表中所有会员购买金额,同时分组查出退货表中所有会员的退货金额,
--  把会员id相同的购买金额-退款金额得到的结果更新到表会员表中对应会员的积分字段（credits）
-- 建表
--会员表
drop table if exists test_eleven_member;
create table test_eleven_member(
    memberid string COMMENT '会员id',
    credits bigint COMMENT '积分'
)
row format delimited fields terminated by '\t';
--销售表
drop table if exists test_eleven_sale;
create table test_eleven_sale(
    memberid string COMMENT '会员id',
    MNAccount decimal(10,2) COMMENT '购买金额'
)
row format delimited fields terminated by '\t';
--退货表
drop table if exists test_eleven_regoods;
create table test_eleven_regoods(
    memberid string COMMENT '会员id',
    RMNAccount decimal(10,2) COMMENT '退货金额'
)
row format delimited fields terminated by '\t';

insert into table test_eleven_member values('1001',0);
insert into table test_eleven_member values('1002',0);
insert into table test_eleven_member values('1003',0);
insert into table test_eleven_member values('1004',0);
insert into table test_eleven_member values('1005',0);
insert into table test_eleven_member values('1006',0);
insert into table test_eleven_member values('1007',0);

insert into table test_eleven_sale values('1001',5000);
insert into table test_eleven_sale values('1002',4000);
insert into table test_eleven_sale values('1003',5000);
insert into table test_eleven_sale values('1004',6000);
insert into table test_eleven_sale values('1005',7000);
insert into table test_eleven_sale values('1004',3000);
insert into table test_eleven_sale values('1002',6000);
insert into table test_eleven_sale values('1001',2000);
insert into table test_eleven_sale values('1004',3000);
insert into table test_eleven_sale values('1006',3000);
insert into table test_eleven_sale values(NULL,1000);
insert into table test_eleven_sale values(NULL,1000);
insert into table test_eleven_sale values(NULL,1000);
insert into table test_eleven_sale values(NULL,1000);

insert into table test_eleven_regoods values('1001',1000);
insert into table test_eleven_regoods values('1002',1000);
insert into table test_eleven_regoods values('1003',1000);
insert into table test_eleven_regoods values('1004',1000);
insert into table test_eleven_regoods values('1005',1000);
insert into table test_eleven_regoods values('1002',1000);
insert into table test_eleven_regoods values('1001',1000);
insert into table test_eleven_regoods values('1003',1000);
insert into table test_eleven_regoods values('1002',1000);
insert into table test_eleven_regoods values('1005',1000);
insert into table test_eleven_regoods values(NULL,1000);
insert into table test_eleven_regoods values(NULL,1000);
insert into table test_eleven_regoods values(NULL,1000);
insert into table test_eleven_regoods values(NULL,1000);

-- 分组查出销售表中所有会员购买金额,同时分组查出退货表中所有会员的退货金额,
-- 把会员id相同的购买金额-退款金额得到的结果更新到表会员表中对应会员的积分字段（credits）
with
tmp_member as
(  
    select memberid,sum(credits) credits
    from test_eleven_member
    group by memberid
),
tmp_sale as 
(
    select memberid,sum(MNAccount) MNAccount
    from test_eleven_sale
    group by memberid
),
tmp_regoods as 
(
    select memberid,sum(RMNAccount) RMNAccount
    from test_eleven_regoods
    group by memberid
)
insert overwrite table test_eleven_member
select 
    t1.memberid,
    sum(t1.creadits)+sum(t1.MNAccount)-sum(t1.RMNAccount) credits
from
(
    select 
        memberid,
        credits,
        0 MNAccount,
        0 RMNAccount
    from tmp_member
    union all
    select 
        memberid,
        0 credits,
        MNAccount,
        0 RMNAccount
    from tmp_sale
    union all
    select 
        memberid,
        0 credits,
        0 MNAccount,
        RMNAccount
    from tmp_regoods
) t1
where t1.memberid is not NULL 
group by t1.memberid
---------------------第2种写法-用left join--------------------------
insert overwrite table test_eleven_member
select
    t3.memberid,
    sum(t3.credits) credits
from
(
    select 
        t1.memberid,
        t1.MNAccount - NVL(t2.RMNAccount,0) credits
    from
    (
        select
            memberid,
            sum(MNAccount) MNAccount
        from test_eleven_sale
        group by memberid
    ) t1
    left join
    (
        select
            memberid,
            sum(RMNAccount) RMNAccount
        from test_eleven_regoods
        group by memberid
    )t2
    on t1.memberid = t2.memberid
    where t1.memberid is not NULL

    union all

    select 
        memberid,
        credits
    from test_eleven_member
) t3
group by t3.memberid;

==================================== 第十二题 ===============================
--第12题 百度
--现在有三个表student（学生表）、course(课程表)、score（成绩单）,结构如下：
--建表
create table test_twelve_student
(
    id bigint comment '学号',
    name string comment '姓名',
    age bigint comment '年龄'
)
row format delimited fields terminated by '\t';

create table test_twelve_course
(
    cid string comment '课程号,001/002格式',
    cname string comment '课程名'
)
row format delimited fields terminated by '\t';

Create table test_twelve_score
(
    id bigint comment '学号',
    cid string comment '课程号',
    score bigint comment '成绩'
)
row format delimited fields terminated by '\t';


--插入数据
insert into table test_twelve_student values (1001,'wsl1',21);
insert into table test_twelve_student values (1002,'wsl2',22);
insert into table test_twelve_student values (1003,'wsl3',23);
insert into table test_twelve_student values (1004,'wsl4',24);
insert into table test_twelve_student values (1005,'wsl5',25);

insert into table test_twelve_course values ('001','math');
insert into table test_twelve_course values ('002','English');
insert into table test_twelve_course values ('003','Chinese');
insert into table test_twelve_course values ('004','music');

insert into table test_twelve_score values (1001,'004',10);
insert into table test_twelve_score values (1002,'003',21);
insert into table test_twelve_score values (1003,'002',32);
insert into table test_twelve_score values (1004,'001',43);
insert into table test_twelve_score values (1005,'003',54);
insert into table test_twelve_score values (1001,'002',65);
insert into table test_twelve_score values (1002,'004',76);
insert into table test_twelve_score values (1003,'002',77);
insert into table test_twelve_score values (1001,'004',48);
insert into table test_twelve_score values (1002,'003',39);


--其中score中的id、cid,分别是student、course中对应的列请根据上面的表结构,回答下面的问题
--1）请将本地文件（/home/users/test/20190301.csv）文件,加载到分区表score的20190301分区中,并覆盖之前的数据
load data local inpath '/home/users/test/20190301.csv' overwrite into table test_twelve_score partition(event_day='20190301');
--2）查出平均成绩大于60分的学生的姓名、年龄、平均成绩
select
    stu.name,
    stu.age,
    t1.avg_score
from
test_twelve_student stu
join
(
    select
        id,
        avg(score) avg_score
    from test_twelve_score
    group by id
) t1
on t1.id = stu.id
where avg_score > 60;
--3）查出没有'001'课程成绩的学生的姓名、年龄
select
    stu.name,
    stu.age
from
test_twelve_student stu
join
(
    select
        id
    from test_twelve_score
    where cid != 001
    group by id
) t1
on stu.id = t1.id;
--4）查出有'001'\'002'这两门课程下,成绩排名前3的学生的姓名、年龄
select
    stu.name,
    stu.age
from
(
    select
        id,
        cid,
        score,
        rank() over(partition by cid order by score desc) ran
    from 
    test_twelve_score
    where cid = 001 or cid = 002
) t1
join test_twelve_student stu
on t1.id = stu.id
where ran <= 3;


--5）创建新的表score_20190317,并存入score表中20190317分区的数据
create table score_20190317
as select * from test_twelve_score where dt = '20190317';
--6）如果上面的score_20190317score表中,uid存在数据倾斜,请进行优化,查出在20190101-20190317中,学生的姓名、年龄、课程、课程的平均成绩
select
    stu.name,
    stu.age,
    cou.cname,
    t1.avg_score

from
(
    select 
        id,
        cid,
        avg(score) avg_score
    from test_twelve_score
    group by id,cid
    where dt >= '20190101' and dt <= '20190317'
) t1
left join test_twelve_student stu on t1.id = stu.id
left join test_twelve_course cou on t1.cid = cou.cid
--7）描述一下union和union all的区别,以及在mysql和HQL中用法的不同之处？

union会对数据进行排序去重，union all不会排序去重。
HQL中要求union或union all操作时必须保证select 集合的结果相同个数的列，并且每个列的类型是一样的。

--8）简单描述一下lateral view语法在HQL中的应用场景,并写一个HQL实例
-- 比如一个学生表为：
-- 学号  姓名  年龄  成绩（语文|数学|英语）
-- 001   张三  16     90，80，95
-- 需要实现效果：
-- 学号  成绩
-- 001 90
-- 001 80
-- 001 95


create table student(
`id` string,
`name` string,
`age` int,
`scores` array<string>
)
row format delimited fields terminated by '\t'
collection items terminated by ',';


select
    id,
    score
from
student lateral view explode(scores) tmp_score as score;


