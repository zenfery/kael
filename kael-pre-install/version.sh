#!/bin/sh
############################################################
## @auth: pengfei.cheng 2015-08-17
## @desc: 查看版本
############################################################

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
# 引入配置文件
source $mydir/sys.conf
source $mydir/../conf/sys.conf
# 引入通用方法
source $mydir/lib/common.sh

log " kael-pre-install version $VERSION"
