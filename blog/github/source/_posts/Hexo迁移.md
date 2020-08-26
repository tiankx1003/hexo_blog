---
title: Hexo迁移报错解决
---
Hexo基于 Ubuntu20.04 LTS on Windows 1909

### 1. melody主题翻页button乱码与图片不显示不能同时解决

![](Hexo迁移/compare.png)

```sh
cnpm install --save hexo-renderer-pug hexo-generator-feed hexo-generator-sitemap hexo-browsersync hexo-generator-archive
cnpm install https://github.com/CodeFalling/hexo-asset-image --save
```

### 2. hexo d 部署报错

因为权限问题使用root账户部署，所以不只是上传当前用户的公钥

**root用户**的id_rsa.pub添加到github的SSH keys