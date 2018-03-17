############################################################
## @auth: pengfei.cheng 2015-08-17
## @desc: 项目打包
############################################################

# 部署环境根目录，一般为HOME目录
ENV_HOME="$HOME"
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)

source $mydir/conf/env.conf

sh $mydir/package.sh 2>&1
sh $mydir/deploy.sh 2>&1
