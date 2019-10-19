---
title: Hexo搭建个人博客
---
github为每个账户提供了一个免费的二级域名{username}.github.io，只需要在仓库{username}.github.io.git中编写代码就能自动实现网页的解析。使用Hexo能通过markdown文件实现博客内容的编写与发布，下面是Ubuntu1904下Hexo的搭建过程，其他环境同理。

### 环境安装
```bash
sudo apt update -y
# 安装新版node.js
sudo apt-get --purge remove nodejs
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install nodejs
sudo apt install -y ruby python python-pip
pip install npm
# 更新npm到最新
sudo npm install npm@latest -g
sudo npm install -g cnpm --registry=https://registry.npm.taobao.org
sudo cnpm install -g hexo-cli
mkdir blog
cd blog
# Hexo生成博客
sudo hexo init
# 安装git部署插件
cnpm install --save hexo-deployer-git
# 设置_config.yml
vim _config.yml
# 下载主题，修改_config.yml更换主题
git clone http://github.com/litten/hexo-theme-yilia.git themes/yilia
mkdir theme/yilia/source/img # 添加头像
# 清理Hexo
hexo clean
# 重新生成
hexo g
# 重新启动server，通过localhost:4000预览
hexo s
# 部署到github
sudo hexo d
```

```yml
# _config.xml文件设置
deploy:
  type: git
  repo: git@github.com:tiankx1003/tiankx1003.github.io.git # 个人仓库路径
  branch: master # 默认

# 修改主题
theme: yilia

# 设置头像
avatar: /img/header.jpg
```
