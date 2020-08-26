---
title: Ubuntu安装配置MySQL
tags: Linux
---

```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
# 按照下述配置后即可登陆
mysql -uroot -p
```

```
#1
VALIDATE PASSWORD PLUGIN can be used to test passwords...
Press y|Y for Yes, any other key for No: N 

#2
Please set the password for root here...
New password: (输入密码)
Re-enter new password: (重复输入)

#3
By default, a MySQL installation has an anonymous user,
allowing anyone to log into MySQL without having to have
a user account created for them...
Remove anonymous users? (Press y|Y for Yes, any other key for No) : N 

#4
Normally, root should only be allowed to connect from
'localhost'. This ensures that someone cannot guess at
the root password from the network...
Disallow root login remotely? (Press y|Y for Yes, any other key for No) : Y 

#5
By default, MySQL comes with a database named 'test' that
anyone can access...
Remove test database and access to it? (Press y|Y for Yes, any other key for No) : N 

#6
Reloading the privilege tables will ensure that all changes
made so far will take effect immediately.
Reload privilege tables now? (Press y|Y for Yes, any other key for No) : Y 
```

### 问题解决


```bash
# 安装后第一次启动连接报错
# Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock'
sudo mkdir -p /var/run/mysqld
sudo chown mysql /var/run/mysqld/
sudo service mysql restart
```

```bash
# 重启mysql服务 No directory, logging in with HOME=/
ps -aux | grep mysql
sudo service mysql stop
sudo usermod -d /var/lib/mysql/ mysql
sudo service mysql start
sudo service mysql status
```

```bash
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf 
# 在[mysqld]添加skip-grant-tables可以不使用密码登陆mysql
```

