---
title: MySQL基础
tags: DataBase
---
## PREFACE

### 1.用途
持久化数据到本地
结构化查询
方便管理

### 2.相关概念
DB, DBMS, SQL

### 3.数据库存储的特点
数据放到表中，表放到库中
一个数据库可以有多个表，表有一个名字用来标识自己，表名具有唯一性
表具有一些特性，用来定义数据在表中如何存储，类似于JAVA中Class的设计
表由列组成，也可成为字段，所有表都是由一个或多个列组成，每一列类似JAVA中的属性
表中的数据是按行存储，每一行类似JAVA中的对象

MySQL产品介绍，安装，服务启停，登录与退出（略）

常见命令和语法规范
```sql
show databases;
use [database_name];
show tables;
show tables from|in [database_name];
create table [table_name] (
    col1 type1, col2 type2
);
desc [table_name];
select version();
select * from [table_name];
```
```bash
mysql --version
mysql -V
```

### 4.MySQL语法规范
1. 不区分大小写，但是建议关键字大写，表明、小写
2. 每条命令最好用分号结尾
3. 每条命令根据需要可以进行缩进和换行
4. 注释，使用`#`或`--`做单行注释，`/*...*/`做多行注释


## DQL
 * Data Query Language 数据查询语言

### 1.基础查询
```sql
select col1, col2 from tab;
```
特点：
1. 通过select查询出的结果，是一个虚拟的表格，不是真实存在
2. 要查询的东西，可以是常量值，也可以是表达式、字段、函数



### 2.条件查询
 * 根据条件过滤原始表的数据，查询到想要的数据

```sql
select col1, col2
from tab
where [conditions]
```

1. 条件表达式
```sql
where col1 >= 1000
```
条件运算符：`> < >= <= != <>`

2. 逻辑表达式
```sql
where col1 >= 1000 && col2 <= 2000
```

and (&&) 如果两个条件同时成立，结果为true，反之为false
or (||) 两个条件只要有一个成立，结果为true，反之为false
not (!) 如果条件成立，则not后为false，否则为true

3. 模糊查询
```sql
where col1 like 'a%'
```

### 3.排序查询
```sql
order by cols|expressions|functions|alias
```

### 4.常见函数

1. 单行函数
字符函数

functions | descriptions
:-|:-
concat | 拼接
substr | 截取字符串
upper | 转换为大写
lower | 转换为小写
trim | 去前后指定的空格和字符
ltrim | 去左边的空格
rtrim | 去右边的空格
replace | 替换
lpad | 左填充
rpad | 右填充
instr | 返回子串第一次出现的索引
length | 获取字节个数


数字函数

functions | descriptions
:-|:-
round | 四舍五入
rand | 随机数
floor | 向下取整
ceil | 向下取整
mod | 取余
truncate | 截断

日期函数

functions | descriptions
:-|:-
now | 当前系统日期+时间
curdate | 当前系统日期
curtime | 当前系统时间
str_to_date | 将字符转换成日期
date_format | 将七日转换成字符


流程控制函数

functions | descriptions
:-|:-
if | 处理双分支
case-when-then | 处理多分支

其他函数

functions | descriptions
:-|:-
version | 版本
database | 当前库
user | 当前用户

2. 分组函数

functions | descriptions
:- | :-
sum | 求和
max | 最大值
min | 最小值
avg | 平均值
count | 计数

   * 以上五个分组函数都忽略null，除了`count(*)`
   * sum和avg一般用于处理数值型，max、min、count可以处理任何数据类型
   * 都可以搭配`distinct`使用，用于统计去重后的结果
   * count的参数可以支持字段名和常量值
   * 建议使用`count(*)`

### 5.分组查询
```sql
select col1, col2
from tab
group by group_col
```

**特点**
1. 可以按单个字段分组
2. 和分组函数一同查询的字段最好是分组后的字段
3. 分组筛选
   针对的表位置关键字
   分组前筛选：原始表`group by`的前面`where`
   分组后筛选：分组后的结果集`group by`的后面`having`
4. 可以按多个字段分组，字段之间用逗号隔开
5. 可以支持排序
6. `having`后可以支持别名

### 6.多表连接查询
 * 如果连接条件忽略或者无效则会出现[笛卡尔积](https://baike.baidu.com/item/%E7%AC%9B%E5%8D%A1%E5%B0%94%E4%B9%98%E7%A7%AF/6323173?fromtitle=%E7%AC%9B%E5%8D%A1%E5%B0%94%E7%A7%AF&fromid=1434391&fr=aladdin)

1. 传统模式 等值非等值连接
   * 等值连接的结果为多个表的交集
   * n表连接，至少需要n-1个连接条件
   * 多个表部分主次，没有顺序要求
   * 一般为表起别名，提高可读性和性能

2. SQL99语法 通过join关键字连接
   含义：1999年退出的SQL语法
   支持：等值连接、非等值连接(内连接)、外连接、交叉连接
   优点：语句上，连接条件和筛选条件实现了分离，简洁明了

```sql
select cols
from tab1
[inner|left|right|cross] join tab2 on conditions
[inner|left|right|cross] join tab3 on conditions
where conditions
group by cols
having conditions
order by cols
```

3. 自连接

案例：查询员工名和直接上级的名称

col | type | desc
:-|:-|:-
employee_id | varchar(20) | 员工编号
last_name | varchar(20) | 员工名称
manager_id | varchar(20) | 直接上级编号

```sql
create table employees(
    employee_id varchar(20) comment '员工编号',
    last_name | varchar(20) comment '员工名称',
    manager_id | varchar(20) comment '直接上级编号'
);
```

```sql
-- SQL99
SELECT e.last_name,m.last_name
FROM employees e
JOIN employees m ON e.`manager_id`=m.`employee_id`;

-- SQL92
SELECT e.last_name,m.last_name
FROM employees e,employees m
WHERE e.`manager_id`=m.`employee_id`;
```

### 7.子查询

**含义：**
一条查询语句中又嵌套了另一条完整的select语句，其中被嵌套的select语句被称为子查询或内查询

**特点：**
1. 子查询都放在小括号内
2. 子查询可以放在from后面、select后面、where后面、having后面，但是一般放在条件的右侧
3. 子查询优先于主查询执行，主查询使用了子查询的执行结果
4. 子查询根据查询结果的行数不同非为以下两类：
   ①单行子查询
   结果集只有一行，一般搭配单行操作符使用：`> < = <> >= <=`
   ②多行子查询
   结果集有多行，一般搭配多行操作符使用：`any` `all` `in` `no in`
   in属于子查询结果中的任意一个就行
   any和all往往可以用其他查询代替

### 8.分页查询
 * 实际的web项目中需要根据用户的需求提交对应的分页查询SQL语句

```sql
select cols
from tab
where conditions
group by cols
having conditions
limit [start_index,] num
```

**特点：**
1. 起始条目索引从0开始
2. limit子句放在查询语句的最后
3. 公式`select cols from tab limit (page - 1) * size_per_page, size_per_page`
   每页显示条目数size_per_page, 要显示的页数 page

### 9.联合查询

```sql
select cols from tab1 where conditions
union [all]
select cols from tab2 where conditions
union [all]
select cols from tab3 where conditions
```

**特点：**
1. 多条查询语句的查询列数必须是一致的
2. 多条查询语句的查询的列类型几乎相同
3. `union`去重，`union all`不去重

## DML
 * Data Manipulate Language 数据操作语言
### 1.插入
```sql
insert into [tab(col1, col2, col3 ...)]
values(value1, value2, value3 ...);
```
1. 字段类型和值类型一致或兼容，而且一一对应
2. 可以为空的字段，可以不用插入值，或用null填充
3. 不可以为空的字段，必须插入值
4. 字段个数和值的个数必须一致
5. 字段忽略时，默认所有字段，且顺序和表汇总的存储顺序一致

### 2.修改
```sql
-- 单表
update tab set col1=new_value1, col2=new_value2 where conditions;
-- 多表
update tab1 t1, tab2 t2
set col1 = new_value1, col2 = new_value2
where join_conditions
and filter_conditions;
```

[-_-]: aa
[^_^]: aa
[>_<]: aa

### 3.删除
```sql
-- delete 单表
delete from tab [where conditions];
-- delete 多表
delete t1.cols, t2.cols
from tab1 t1, tab2 t2
where join_conditions
and filter_conditions;

-- trucate
truncate table tab;
```

**区别：**
1. truncate不能加where条件，delete可以
2. truncate的效率稍微高一些
3. 删除带自增长列的表后，如果再插入数据，truncate从1开始，delete从上次的断点开始
4. truncate删除不能回滚，delete删除可以回滚

## DDL
 * Data Define Languge 数据定义语言

### 1.库和表的管理

```sql
create database db_name;
drop database db_name;
```
```sql
create table [if not exists] tab(
    col1 type1,
    col2 type2
);

desc tab;

alter table tab add|modify|drop|change column col [type];
alter table tab change column col_name1 col_name2 type;
alter table tab rename [to] new_tab_name;
alter table tab modify column col type;
alter table tab add column col1 varchar(20) first;
alter table tab drop column col1;

drop table [if exists] tab;
```

### 2.常见数据类型
[MySQL数据类型](https://dev.mysql.com/doc/refman/8.0/en/data-types.html)

<!-- type | desc
:-|:- -->


### 3.常见约束

约束 | 描述
:-|:-
not null | 非空
default | 默认值
unique | 唯一
primary key | 主键
foreign key | 外键
check | 检查约束

 * *MySQL无检查约束但是语法不报错*


## TCL
 * Transaction Control Language 事务控制语言

### 1.含义
通过一组逻辑操作单元(一组DML)，将数据从一种状态切换到另一种状态

### 2.特点
原子性：要么都执行，要么都回滚
一致性：保证数据的状态操作前和操作后保持一致
隔离性：多个事务同时操作相同数据库的同一个数据时，一个事务的执行不受另外一个事务的干扰
持久性：一个事务一旦提交，则数据将持久化到本地，除非其他事务对其进行修改
 
 * *ACID*

### 3.相关步骤
1. 开启事务
2. 编写事务的一组逻辑操作单元(多条SQL语句)
3. 提交事务或回滚事务

<!-- TODO 具体步骤 -->

### 4.事务的分类
1. 隐式事务
   没有明显的开启和结束标志
   比如update、insert、delete语句本身就是一个事务
2. 显式事务
   具有明显的开启和结束标志

### 5.事务的隔离级别
 * 事务并发问题如何发生
 * 当多个事务同事操作一个数据库的相同数据时，事务的并发问题有哪些

几种事务并发问题
脏读：一个是事务读取到另个事务未提交的数据
不可重复读：同一个事务中，多次读取到的数据不一致
幻读：一个事务读取数据时，另外一个事务进行更新，导致第一个事务读取到了没有更新的数据

设置合适的隔离级别可以避免事务的并发问题
1. READ UNCOMMITTED
2. READ COMMITTED 可以避免脏读
3. REPEATABLE READ 可以避免脏读、不可重复读和一部分幻读
4. SERIALIZABLE可以避免脏读、不可重复读和幻读

```sql
set session|global transaction isolation level lv_name;
select @@tx_isolation;
```



## VIEW
 * 一张虚拟的表，一段封装好的DQL逻辑，一段记忆，不占用屋里空间

### 1.优点
1. SQL语句提高重用性，效率高
2. 和表实现分离，提高安全性


### 2.语法

```sql
create view vw_name as
query_block;

select * from vw where conditions;
insert into vw(col1, col2) values(value1, value2);
update vw set col1=value1 where conditions;

delete from vw where conditions;

create or replace view vw as
select cols from tab
where conditions;

alter view vw as
select cols from tab;

drop view vw1, vw2, vw3;
desc vw;
show create view vw;
```

<!-- TODO 视图的写入与删除数据？ -->



## PROCEDURE&FUNCTION
 * 一组预先编译的SQL语句的集合

### PROCEDURE
##### 优点
1. 提高了SQL语句的复用性，减少了开发压力
2. 提高了效率
3. 减少了传输次数

##### 分类
1. 无返回无参
2. 仅仅带in类型，无返回有参
3. 仅仅带out类型，又返回无参
4. 既带in又带out，有返回有参
5. 带inout，有返回有参

```sql
create procedure procd(in|out|inout param1 type1, param2 type2 ...)
begin
procedure_body
end
```

##### 注意事项
1. 需要设置新的结束标记

2. 存储过程种可以有多条SQL语句，如果仅有一条则可以省略begin和and

3. 参数前面的in out inout也表示了是否有参数或返回值

```sql
call procd；
```

### FUNCTION
```sql
create function func(param1 type1,param2 type2 ...) returns return_type
begin
func_body
end
```
```sql
select func(params);
```

函数和存储过程的区别
关键字，调用语法，返回值，应用场景
函数返回值为一个，存储过程可以有0个返回值，也可以有多个


## FLOWCONTROL

### 1.系统变量
##### 全局变量
 * 作用域针对所有会话(连接)，但不能跨重启

```sql
-- 查看所有全局变量
SHOW GLOBAL VARIABLES;
-- 查看满足条件的部分系统变量
SHOW GLOBAL VARIABLES LIKE '%char%';
-- 查看指定的系统变量的值
SELECT @@global.autocommit;
-- 为某个系统变量赋值
SET @@global.autocommit=0;
SET GLOBAL autocommit=0;
```

##### 会话变量
 * 作用域针对当前会话(连接)有效

```sql
-- 查看所有会话变量
SHOW SESSION VARIABLES;
-- 查看满足条件的部分会话变量
SHOW SESSION VARIABLES LIKE '%char%';
-- 查看指定的会话变量的值
SELECT @@autocommit;
SELECT @@session.tx_isolation;
-- 为某个会话变量赋值
SET @@session.tx_isolation='read-uncommitted';
SET SESSION tx_isolation='read-committed';
```

### 2.自定义变量

##### 用户变量
```sql
-- 声明并初始化
set @v1 = value1;
set @v2 := value2;
select @v3 := value3;
-- 赋值
set v1 = value1;
set v2 := value2;
select v3 := value3;
-- 使用表种的数据赋值
select col into v1
from tab;
-- 使用
select @v1;
```


##### 局部变量
```sql
-- 声明
declare v1 type [default value];
-- 赋值与用户变量相同
set v1 = value1;
set v2 := value2;
select v3 := value3;
-- 使用表种的数据赋值
select col into v1
from tab;
-- 使用
select v1;
```

二者的区别
作用域、定义位置、语法
用户变量当前会话的任何地方加`@`符号，不用指定类型
局部变量定义他的`BEGIN END`中`BEGIN END`的第一句一般不用加@，需要指定类型


### 3.分支

##### if
 * 可以用在任何位置
```sql
if(condition, value1, value2)
```

##### case
 * 可以用在任何位置
```sql
-- 类似于switch用法
case expression
when value1 then result1 -- 如果是语句，需要加分号
when value2 then result2 -- 如果是语句，需要加分号
...
else result
end [case] -- 如果放在begin end中需要加上case，如果放在select后面则不需要
```

<!-- 多重if用法？ -->

##### if-elseif
 * 只能用在`begin and`中
```sql
if case1 then expression1;
elseif case2 then expression2;
...
else expression;
end if;
```

**比较：**
if 简单双分支
case 等值判断的多分支
if-elseif 区间判断的多分支

### 4.循环

```sql
[label:] while loop_condition do
loop_body
end while [label];
```
 * 只能放在`begin end`里面
 * 如果搭配`leave`跳转语句，需要使用标签，否则可以不用标签(leave类似于break，可以跳出循环)

