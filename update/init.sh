#!/bin/sh
############################################################
## @auth: jie.sun 2016-08-19
## @desc: 初始化普通 Web 项目环境
############################################################

## 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)

if [ -n "$1" ]; then
    project_name="$1"
fi

## 修改 env.conf 中的 PROJECT_NAME
if [ -f "$mydir/conf/env.conf" ] && [ -n "$project_name" ]; then
    echo " [`date +'%Y-%m-%d %H:%M:%S'`] change PROJECT_NAME in env.conf to $project_name"
    sed -i "s/@@PROJECT_NAME@@/$project_name/g" "$mydir/conf/env.conf"
fi
