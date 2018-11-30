#!/bin/bash
#mail:xiangyun.jiang@chinacache.com
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)

source $mydir/conf/env.conf
####判断文件是否存在
if [ -f /tmp/mservice.txt ];then
    echo "file is exit"
else
   touch  /tmp/mservice.txt
fi
#####当前用户为root，并且参数=all时########
if [ `whoami` = "root" ] && [ $1 == "all" ];then
    for i in $(cat /tmp/mservice.txt);
    do
    groupname=$(id -gn $i)
    echo $groupname
    type=`curl $PACKAGE_STORE_URL_PREFIX/$i/type`
    version=`curl  $PACKAGE_STORE_URL_PREFIX/$i/version-latest`
    fullname_4=$i-$version.$type
    wget -SO /home/$i/kael/update/release/$fullname_4  $PACKAGE_STORE_URL_PREFIX/$i/$fullname_4
    chown -R $i.$username /home/$i/kael/update/release
    find /home/$i/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
    done
#########当前用户为root时#######
elif [ `whoami` = "root" ];then
    echo "user is root"
    type=`curl $PACKAGE_STORE_URL_PREFIX/$1/type`
    version=`curl  $PACKAGE_STORE_URL_PREFIX/$1/version-latest`
    fullname=$1-$version.$type
    echo $fullname
    groupname=$(id -gn $1)
    if [ $2 ];then
        type=`curl $PACKAGE_STORE_URL_PREFIX/$1/type`
        fullname_2=$1-$2.$type
        wget -SO /home/$1/kael/update/release/$fullname_2 $PACKAGE_STORE_URL_PREFIX/$1/$fullname_2
        chown -R $1.$groupname /home/$1/kael/update/release
        find /home/$1/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
    else
        type=`curl $PACKAGE_STORE_URL_PREFIX/$1/type`
        fullname_3=$1-$version.$type
        wget -SO /home/$1/kael/update/release/$fullname_3 $PACKAGE_STORE_URL_PREFIX/$1/$fullname_3
        chown -R $1.$groupname /home/$1/kael/update/release
        find /home/$1/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
    fi
##########当前用户非root时###########
elif [ `whoami` != "root" ];then
    type=`curl $PACKAGE_STORE_URL_PREFIX/$(whoami)/type`
    groupname=$(id -gn $(whoami))
    full_package=$(whoami)-.$type
        if [ $1 ];then
            type=`curl $PACKAGE_STORE_URL_PREFIX/$(whoami)/type`
            fullname_1=$(whoami)-$1.$type
            wget -SO /home/$(whoami)/kael/update/release/$fullname_1  $PACKAGE_STORE_URL_PREFIX/$(whoami)/$fullname_1
            chown -R $(whoami).$groupname /home/$(whoami)/kael/update/release
            find /home/$(whoami)/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
        else
             type=`curl $PACKAGE_STORE_URL_PREFIX/$(whoami)/type`
             version1=`curl  $PACKAGE_STORE_URL_PREFIX/$(whoami)/version-latest`
             fullname_7=$(whoami)-$version1.$type
             wget -SO /home/$(whoami)/kael/update/release/$fullname_7  $PACKAGE_STORE_URL_PREFIX/$(whoami)/$fullname_7
             chown -R $(whoami).$groupname /home/$(whoami)/kael/update/release
             find /home/$(whoami)/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
        fi
else
        echo  "user is not root"
        exit 0

fi

