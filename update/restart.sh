############################################################
## @auth: pengfei.cheng 2015-08-18
## @desc: 项目部署 重启tomcat
############################################################

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf

echo " [`date`] 传入参数的个数为 [$#] $1 $2"

#### usage
function usage(){
    echo " *** Usage(root): $0 user [version] "
    echo " ***       $0 bill"
    echo " ***       $0 bill 0.0.1 "
    echo " *** Usage(not root): $0 [version] "
    echo " ***       $0 0.0.1 "
    echo " ***       $0 "
}

#### 当为 root 用户时执行
function root_exec(){
    user_name=""
    if [ $# -eq 1 -o $# -eq 2 ]; then
        echo " [`date`] parameter number is $#, ok."
        user_name=$1
        version=$2
        su - $user_name <<EOF
        /bin/sh kael/update/restart.sh $version;
EOF
    else
        echo " [`date`] *** ERROR *** parameter number is $#."
        usage
        exit 100
    fi

}

#### restart / 重启执行
function user_exec(){
    kaelDir=$(cd "$mydir/../"; pwd)
    mserviceDir=$kaelDir/mservice
    echo " INFO  : kael dir : $kaelDir, mservice dir : $mserviceDir"

    version=$1

    cd $mydir
    docsDir=$ENV_HOME/apps/docs
    #### 重启服务
    ## 判断是什么类型的服务: Judge the service type: mservice or tomcat
    echo " INFO  : cd $docsDir"
    cd $docsDir
    jarNum=$(ls *.jar | wc -l)

    # mservice (jar)
    if [ $jarNum -gt 0 ];then 
        echo " INFO  : restart mserivce ..."
        sh $mserviceDir/bin/mservice.sh restart $version
    # tomcat (war)
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
}

## main
curr_user=$(whoami)
echo " [`date`] current user is [$curr_user]."
if [ $curr_user == "root" ];then
    root_exec $@
else
    user_exec $@
fi

