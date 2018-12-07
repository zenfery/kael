#!/bin/bash
#mail:xiangyun.jiang@chinacache.com
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf


#########部分参数处理#######

#########使用方法########
function usage(){
    echo -e  "\033[43;35m 使用方法如下：以下参数支持版本号\033[0m \n" 
    echo -e  "\033[43;35m ****** usage(root):$0 all \033[0m \n"
    echo -e  "\033[43;35m ******             $0 $1 $2 \033[0m \n"
    echo -e  "\033[43;35m ******usage(not root):$0 \033[0m \n"
    echo -e  "\033[43;35m *****                 $0 $1 \033[0m \n"

}
######root执行时#######
function root_exec(){
    user_name=$1
    version=$2
    file=$mydir/conf/users
    if [ ! -f $file ];then
        echo "*****error *****:the $file  is not exit"
        exit 3
    fi


    if [ -z "$user_name" ];then
        echo " *** error *** : the input user_name is null, exit"
        usage
        exit 200
    fi

    ## not all
    if [ "all" != "$user_name" ];then
        id $user_name >& /dev/null
        if [ $? -ne 0 ];then
            echo " *** error ***: the user[$user_name] is not exist, exit!!!"
            exit 201
        fi
        
        su - $user_name <<EOF
        /bin/sh kael/update/pull.sh $version;
EOF
    ## all
    else
        for user_name in $(cat $mydir/conf/users);do
            /bin/sh $mydir/pull.sh $user_name
        done
    fi

}


##########非root用户执行时#########
function no_root_exec(){
    service=$PROJECT_NAME
    if [ -z "$service" ];then
        echo " *** error *** service name is null, exit."
        exit 100
    fi

    version=$1
    if [ -z "$version" ];then
        version_url=$PACKAGE_STORE_URL_PREFIX/$service/version-latest
        echo "=> it will fetch the package version from url : $version_url"
        version=`curl $version_url`
        if [ -z "$version" ]; then
            echo " *** error *** version is null, exit."
            exit 101
        fi
    fi

    type_url=$PACKAGE_STORE_URL_PREFIX/$service/type
    echo "=> it will fetch the package type from url : $type_url"
    packae_type=`curl $type_url`
    if [ -z "$package_type" ]; then
        package_type=jar
    fi
    
    ## download package
    package_name=$service-$version.$package_type
    echo "=> the package_name is : $package_name"
    package_url=$PACKAGE_STORE_URL_PREFIX/$service/$package_name
    echo "=> the package_url is : $package_url"
    wget -SO /home/$(whoami)/kael/update/release/$package_name $package_url 
    find /home/$(whoami)/kael/update/release/ -name "*.jar" -size 0 -exec rm -f {} \;
    
    groupname=$(id -gn $(whoami))
    chown -R $(whoami).$groupname /home/$(whoami)/kael/update/release

}

#########
current_user=$(whoami)
if [ $current_user = "root" ];then
   root_exec $@
else
   no_root_exec $@
fi

