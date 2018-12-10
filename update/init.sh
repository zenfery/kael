#!/bin/sh
############################################################
## @auth: jie.sun 2016-08-19
## @desc: 初始化 update 工具
##        （1）更新 env.conf 中的 PROJECT_NAME 为传入的参数
##        （2）若 release 目录不存在，则自动创建
############################################################

## 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)

# 创建缺失的目录
echo " create release 目录"
mkdir -p $mydir/release

# 更新 PROJECT_NAME
if [ -n "$1" ]; then
    project_name="$1"

    ## 修改 env.conf 中的 PROJECT_NAME
    if [ -f "$mydir/conf/env.conf" ] && [ -n "$project_name" ]; then
        echo " [`date +'%Y-%m-%d %H:%M:%S'`] change PROJECT_NAME in env.conf to $project_name"
        sed -i "s/@@PROJECT_NAME@@/$project_name/g" "$mydir/conf/env.conf"
    fi
fi


