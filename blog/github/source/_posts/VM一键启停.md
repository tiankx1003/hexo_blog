---
title: VM一键启停脚本
tags: Batch Script
---

添加vmware workstation的安装目录到环境变量
```powershell
# 测试配置
vmrun
# 回显如下内容表示配置正确
vmrun version 1.17.0 build-14665864
Usage: vmrun [AUTHENTICATION-FLAGS] COMMAND [PARAMETERS]
```

##### 启动脚本
 * 文件路径改为指定虚拟机*.vmx文件绝对路径即可

```powershell
@echo off & setlocal enabledelayedexpansion
echo "Start Hadoop Cluster..."
vmrun -T ws start "C:\vmware\hadoop101\hadoop102.vmx" nogui
vmrun -T ws start "C:\vmware\hadoop102\hadoop103.vmx" nogui
vmrun -T ws start "C:\vmware\hadoop103\hadoop104.vmx" nogui
```

##### 关机脚本
 * 更改vmlist.txt内容可以关闭指定虚拟机

```powershell
@echo off & setlocal enabledelayedexpansion
echo "Shutdown Hadoop Cluster..."
# 把当前运行的虚拟机列表写入到文本中
vmrun list > vmlist.txt
for %%i in (vmlist.txt) do (
    set "f=%%i"
    for /f "usebackq delims=" %%j in ("!f!") do set/a n+=1
    for /f "delims=" %%m in ('"type "!f!"|more /E +1 & cd. 2^>!f!"') do(
        set/a x+=1&if !x! leq !n! echo;%%m>>!f!
    ) 
    set/a n=0,x=0
)
for /f "delims=" %%a in (vmlist.txt) do (
     vmrun -T ws stop "%%a" nogui
)
del /F /Q vmlist.txt
```