############################################################
## @auth: pengfei.cheng 2015-08-18
## @desc: 项目部署 重启tomcat
############################################################
## 2017-03-17, pengfei.cheng, 支持mservice服务启动
############################################################

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf

kaelDir=$(cd "$mydir/../"; pwd)
mserviceDir=$kaelDir/mservice
echo " INFO  : kael dir : $kaelDir, mservice dir : $mserviceDir"

cd $mydir
docsDir=$ENV_HOME/apps/docs
#### 重启服务
## 判断是什么类型的服务: Judge the service type: mservice or tomcat
echo " INFO  : cd $docsDir"
cd $docsDir
jarNum=$(ls *.jar | wc -l)
if [ $jarNum -gt 0 ];then # mservice
    echo " INFO  : restart mserivce ..."
    sh $mserviceDir/bin/mservice.sh restart
else
    echo " INFO  : restart tomcat ..."
    # 查询进程是否存在
    tomcatPid=$(ps -ef| grep $ENV_HOME |grep tomcat| grep -v grep | awk '{print $2}')
    if [ ! -z "$tomcatPid" ]; then
        echo " DEBUG : cd $ENV_HOME/apps/tomcat/bin "
        cd $ENV_HOME/apps/tomcat/bin
        echo " INFO  : ./shutdown.sh "
        ./shutdown.sh
        sleep 3
        tomcatPid=$(ps -ef| grep $ENV_HOME |grep tomcat| grep -v grep | awk '{print $2}')
        if [ ! -z "$tomcatPid" ]; then
            echo " INFO : kill -9 $tomcatPid "
            kill -9 $tomcatPid
        fi
        echo " INFO  : tomcat is stop..."
    else
        echo " INFO  : there is no tomcat is running..."
    fi
    # 启动tomcat
    echo " DEBUG : cd $ENV_HOME/apps/tomcat/bin "
    cd $ENV_HOME/apps/tomcat/bin
    echo " INFO  : startup.sh "
    ./startup.sh
fi
cd $mydir

