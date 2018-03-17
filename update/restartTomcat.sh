############################################################
## @auth: pengfei.cheng 2015-08-18
## @desc: 项目部署 重启tomcat
## @Notice: 此脚本不建议再使用，请使用 restart.sh 来代替
############################################################

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf

cd $mydir
echo " WARN  : this command is Deprecated, Please use restart.sh instead of it. 此脚本已经过时，使用 restart.sh 脚本来替代它."
#### 重启tomcat服务
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
cd $mydir
