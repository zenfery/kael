############################################################
## @auth: pengfei.cheng 2015-08-18
## @desc: 项目部署
############################################################

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf
cd $mydir

## 参数处理
version=$1
package_name=""
upload_dir="$HOME/upload"
release="$mydir/release"

echo " [`date`] 传入参数的个数为 [$#] $1 $2"

#### usage
function usage(){
    echo " *** Usage(root): $0 user [version] "
    echo " ***       $0 bill"
    echo " ***       $0 bill bill-0.0.1.jar "
    echo " *** Usage(not root): $0 [version] "
    echo " ***       $0 0.0.1 "
    echo " ***       $0 "
}

#### 当为 root 用户时执行
function root_exec(){
    user_name=""
    group_name=""
    mkdir -p $upload_dir
    if [ $# -eq 1 ]; then
        echo " [`date`] parameter number is $#, ok."
        user_name=$1
        package_num=$( ls $upload_dir/* | wc -l )
        echo " [`date`] package num is $package_num"
        if [ $package_num -eq 1 ];then
            package_name=$(ls $upload_dir/*)
            package_name=${package_name##*/}
        else
            echo " [`date`] * WARN * package[$upload_dir/*] is 0 or more than 1. "
        fi
    elif [ $# -eq 2 ]; then
        echo " [`date`] parameter number is $#, ok."
        user_name=$1
        package_name_prefix="$1-$2"
        package_file=$( ls $upload_dir/$package_name_prefix* )
        if [ -z "$package_file" ]; then
            echo "** error ** The $1:$2 not found. 你指定的 $1:$2 找不到，请查找原因后重试."
            exit 104
        else
            package_name=${package_file##*/}
        fi
    else
        echo " [`date`] parameter number is $#."
        usage
        exit 100
    fi
    echo "==> params user_name = $user_name, package_name=$package_name ."


    #### begin to deploy
    if [ ! -z "$package_name" ]; then
        ## 判断将要部署的用户是否存在? judge the deploy user exist?
        id $user_name
        if [ $? -eq 0 ];then
            group_name=$(id -gn $user_name)
        else
            echo " [`date`] *** ERROR *** user [$user_name] is not exist.."
            exit 100
        fi
        ## 判断将要部署的 程序包是否存在? judge the deploy package exist?
        if [ ! -f "$upload_dir/$package_name" ];then
            echo " [`date`] * WARN * package [$upload_dir/$package_name] is not exist not in root user.."
        else
            ## begin to deploy
            user_home_dir=$(cat /etc/passwd | egrep "^$user_name:" | awk -F":" '{ print $6 }')
            echo " [`date`] we will to deploy the package[$package_name] to user[$user_name]($user_home_dir), group[$group_name]."
            release_dir="$user_home_dir/kael/update/release/"
            rm -f "$user_home_dir/kael/update/release/*"
            if [ ! -d "$release_dir" ]; then
                mkdir -p $release_dir
            fi
            mv $upload_dir/$package_name $release_dir
            chown -R $user_name.$group_name $release_dir
        fi
    fi

    #su - $user_name -s /bin/sh kael/update/deploy.sh
    su - $user_name <<EOF
    /bin/sh kael/update/deploy.sh;
EOF

}


##### 搜索需要部署的程序包 Search the package to deploy
function search_package(){
    if [ -z "$version" ];then
        echo " WARN  : project version is not given, program will search $release directory for the package... "
        echo " DEBUG : cd $release "
        cd $release
        ## 先判断是否有war包
        warNum=$(ls *.war | wc -l)
        if [ $warNum -eq 1 ];then
            package_name=$(ls *.war)
        elif [ $warNum -eq 0 ];then
            echo " INFO : there are $warNum war package, it will to check jar package..."
            jarNum=$(ls *.jar | wc -l)
            if [ $jarNum -eq 1 ];then
                package_name=$(ls *.jar)
            else
                echo " *** WARN : there are $jarNum jar package, please check it..."
                exit 100
            fi
        else 
            echo " *** WARN : there are $warNum war package, please check it..."
            exit 100
        fi  
    else
        echo " INFO : project version is $version "
        package_name=$PROJECT_NAME-$version.war
        if [ ! -f "$release/$package_name" ];then
            echo " INFO  : given package $version war package [$package_name] is not exists, to find jar packgage..."
            package_name=$PROJECT_NAME-$version.jar
        fi
    fi
    echo " INFO : project package name is: $package_name "
    if [ -z "$package_name" -o ! -f "$release/$package_name" ];then
        echo " *** ERROR : $release/$package_name is null or is not exist."
        exit 100
    fi
    cd $mydir
    sleep $EXEC_SLEEP_INTERVAL
}

#### 部署及备份程序
function deploy_backup(){
    timestamp=$(date +'%Y%m%d%H%M%S')
    echo " INFO  : current invoke timestamp : $timestamp"
    if [[ $package_name == *.jar ]];then
        echo " INFO  : Attempt to delete the same $package_name if exists."
        rm -f $ENV_HOME/apps/docs/$package_name
        echo " INFO  : deploy new package [$package_name]."
        cp $release/$package_name $ENV_HOME/apps/docs/
    else
        echo " INFO : mv $ENV_HOME/apps/docs/$PROJECT_NAME $ENV_HOME/apps/docs/$PROJECT_NAME.$timestamp.system "
        mv $ENV_HOME/apps/docs/$PROJECT_NAME $ENV_HOME/apps/docs/$PROJECT_NAME.$timestamp.system
        
        echo " INFO : search [jar] command exist???"
        type jar 
        if [ $? -eq 0 ]; then
            echo " INFO : [jar] commnad exist, use it."
            mkdir -p "$ENV_HOME/apps/docs/$PROJECT_NAME"
            cd $ENV_HOME/apps/docs/$PROJECT_NAME
            jar -xvf $release/$package_name
        else
            echo " INFO : [jar] oommand is not exist, use [unzip] instead it."
            echo " INFO : unpack: unzip $release/$package_name -d $ENV_HOME/apps/docs/$PROJECT_NAME "
            unzip $release/$package_name -d $ENV_HOME/apps/docs/$PROJECT_NAME
        fi
    fi 
    echo $timestamp > $mydir/backup.ts
    
    echo " DEBUG : mkdir -p $mydir/backup "
    mkdir -p $mydir/backup
    echo " INFO : mv $release/$package_name $mydir/backup/ "
    mv $release/$package_name $mydir/backup/

    cd $mydir
    sleep $EXEC_SLEEP_INTERVAL
}

#### 重启服务
# function restart(){
#     sh $mydir/restart.sh
#     cd $mydir
# }

#### 删除过期备份程序
function delete(){
    timestampOld1=$(date -d'1 month ago' +'%Y%m') #上月
    timestampOld2=$(date -d'1 week ago' +'%Y%m%d') #上周一天
    echo " INFO : delete $ENV_HOME/apps/docs/$PROJECT_NAME*.$timestampOld1""*"" $ENV_HOME/apps/docs/$PROJECT_NAME*.$timestampOld2""*"
    rm -rf "$ENV_HOME/apps/docs/$PROJECT_NAME*.$timestampOld1""*"" $ENV_HOME/apps/docs/$PROJECT_NAME*.$timestampOld2""*"
}

## main
curr_user=$(whoami)
echo " [`date`] current user is [$curr_user]."
if [ $curr_user == "root" ];then
    root_exec $@
else
    search_package
    deploy_backup
    #restart
    delete
fi