---
title: Vundle & zsh
tags: Linux
---
### 安装oh-my-zsh
```bash
sudo yum install -y zsh
# curl方式安装
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# wget方式安装
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
vim ~/.zshrc
# 修该主题为agnoster
# zsh设置为默认
sudo usermod -s /bin/zsh tian
```

### 问题解决
1. 报错: Failed to connect to github.com
 * 解决: `ssh -T git@github.com`
2. 报错: Failed to connect to raw.githubusercontent.com port 443: Connection refused
 * 解决: `sudo yum install redis`


### 安装Vundle
```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
sudo vim /etc/vimrc
:VundleInstall
```

### 配置vimrc
```conf
set nocompatible
filetype off
" run dir
set rtp+=~/.vim/bundle/Vundle.vim
" vundle init
call vundle#begin()
" always first
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
call vundle#end() "required
set laststatus=2 "always display statusbar
let g:airline_powerline_fonts=1 "powerline font
let g:airline#extensions#tabline#enabled = 1 " 显示窗口tab和buffer
```