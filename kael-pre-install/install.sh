#!/bin/sh
############################################################
## @auth: pengfei.cheng 2015-08-17
## @desc: Environment pre-install , 项目部署前环境安装
############################################################
## 2016-10-12, pengfei.cheng, 修改:base(): 可自定义用户组名称，默认app

# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
# 引入配置文件
source $mydir/sys.conf
# 引入通用方法
source $mydir/lib/common.sh

## sleep time space，安装包之间时间间隔
SLEEP_TIME=3
## tomcat 默认http端口号
TOMCAT_HTTP_PORT_DEFAULT=8080

## base dir, 基础目录，默认为/home目录
base_home=
## 工程标识, 如 portal
project_name=
## 需要创建的用户名
user=
## 用户组
group_default=app
group=
## 环境目录; 默认为运行程序的 Home 目录
env_home=
## 源码包存放目录
src_dir=$mydir/src
## 配置文件模板位置
conf_tpl_dir=$mydir/conf_tpl
## tomcat 端口号
tomcat_http_port=

## Function 方法区

#### Judge it is `root` of current invoke environment, it will exit if not root; 判断当前执行用户是否为 root 用户, 若非 root 用户执行直接退出
function is_root(){
    curr_user=`whoami`
    log "The invoking current user is $curr_user"
    if [ "root" != "$curr_user" ]; then
        log " *** Error: Current user is not root, please change to root user and invoke it again..."
        exit 101
    fi
}

## 初始化操作
function init(){
    log " ===> init() ..."
    sh $mydir/init.sh
    sh $mydir/../update/init.sh
}

#### base install 基础安装,创建用户和基础目录
function base (){
    log " Begin to init the user environment..."
    ###### create user  创建用户
    read -p " >>Please input the environment base directory, default[/home] ; 请输入环境基础目录,默认目录为[/home]: " base_home
    if [ -z "$base_home" ]; then
        base_home="/home"
    fi
    log " will to use $base_home as base directory."

    while :
    do
        read -p " >>Please input the project identification name, it is very important, system can not guess it; 请输入项目工程的标识,此项必须输入,系统无法给出默认值 : " project_name
        if [ -n "$project_name" ]; then
            break
        fi
    done

    log "==> to create user group. "
    read -p " >>Please input linux user group , default is [$group_default]: 请输入需要创建的用户组, 默认为[$group_default] : " group
    if [ -z "$group" ]; then
        group=$group_default
    fi
    log "==> to create user. "
    read -p " >>Please input linux username , default is [$project_name]: 请输入需要创建的用户名, 默认为[$project_name] : " user
    if [ -z "$user" ]; then
        user=$project_name
    fi
    log " will to use user [$user], group [$group]"
    log " [exec] groupadd $group"
    groupadd $group
    log " [exec] useradd -d $base_home/$user -m -g $group $user "
    useradd -d $base_home/$user -m -g $group $user

    ###### mkdir base directory 创建基础目录
    env_home=$(cat /etc/passwd | egrep "^$user:" | awk -F":" '{ print $6 }')
    log "Environment home directory is $env_home"
    log "Create dir apps : $env_home/apps $env_home/src $env_home/apps/docs $env_home/apps/logs"
    mkdir -p $env_home/apps $env_home/src $env_home/apps/docs $env_home/apps/logs
    log "chown -R $user.$group $env_home"
    chown -R "$user"."$group" "$env_home"
    
    sleep $SLEEP_TIME
}

## base mop_up task: baes安装扫尾工作
function base_mop_up(){
    log "Begin to handle the mop-up: 开始处理扫尾工作."
    log "chown -R $user.$group $env_home"
    chown -R "$user"."$group" "$env_home"
}

## nginx install
source $mydir/lib/nginx.sh

## Install jdk 安装JDK
#### You must put the jdk setup package into `src` direcotry; 在安装之前需要将 jdk 的安装包放置于 src 目录中
#### If it has more than one jdk source package, use the high version ; 如果目录中存在多个jdk版本, 那么将使用高版本，若不存在，提示是否忽略
function jdk(){
    java_home=$env_home/apps/jdk
    #### judge jdk is installed ?
    log " Judge jdk is installed ???"
    if [ -d "$java_home" ]; then
        log " jdk is installed , ignore it ..."
        $java_home/bin/java -version
        return
    fi
    #### judge jdk source file exist? 探测当前源文件目录包中是否有 jdk 安装包
    log " Exec : cd $src_dir"
    cd $src_dir
    jdk_name=$(ls *jdk*.tar.gz 2>/dev/null | sort -r | head -1)

    #### if it is not exits, try download it form ftp ; 若不存在尝试从 ftp 服务器上下载
    if [ -z "$jdk_name" ]; then
        log " ** Warn: there is no jdk source package exits...; 源码包目录中不存在 jdk 安装包..."

        log " Try to download jdk from ftp service $FTP_HOST "
        log " There has ${#FTP_JDK_FILES[*]} jdk version on ftp server ; Ftp 服务器上包含 ${#FTP_JDK_FILES[*]} 个 jdk 版本: "
        jdk_version=
        if [ 1 -lt ${#FTP_JDK_FILES[*]} ]; then
            for key in ${!FTP_JDK_FILES[*]}; do
                log "    $key -> ${FTP_JDK_FILES[$key]}"
            done
            read -p " >> Please Select suitable version to setup.请选择合适的版本来安装 : " jdk_version
        fi
        jdk_pack_name=${FTP_JDK_FILES[$jdk_version]}
        log " You Select the jdk version is [$jdk_version] -> $jdk_pack_name ."
        jdk_pack_file_path="ftp://$FTP_HOST$FTP_JDK_DIR/$jdk_pack_name"
        log " The jdk ftp address is $jdk_pack_file_path; jdk 的 ftp 下载地址为: $jdk_pack_file_path ..."
        log " wget $jdk_pack_file_path"
        wget $jdk_pack_file_path
    fi

    #### ensure the jdk package ok? 再次确定jdk包文件是否正常
    jdk_name=$(ls *jdk*.tar.gz 2>/dev/null | sort -r | head -1)
    if [ -z "$jdk_name" ]; then
        read -p " Select:  I/i) Ignore 忽略不存在; Default) Exit >> " is_ignore
        is_ignore=$(echo $is_ignore | tr "A-Z" "a-z")
        if [ "i" != "$is_ignore" ]; then
            log "exit; 程序退出!!!"
            exit 102
        else
            log "You ignore this, continue ; 你忽略了此警告，安装程序将继续执行 ... "
        fi
    else
        log "Detect jdk source package is $jdk_name ..."
        mkdir -p $java_home
        log "tar -xzvf $jdk_name -C $env_home/apps/jdk --strip-components=1"
        tar -xzf $jdk_name -C $env_home/apps/jdk --strip-components=1
        ##### set the environment
        echo "\
export JAVA_HOME=$java_home
export JRE_HOME=$java_home/jre
export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH
             " >> $base_home/$user/.bash_profile
    fi
    log "chown -R $user.$group $env_home"
    chown -R "$user"."$group" "$env_home"
    cd -
    sleep $SLEEP_TIME
}

#### Install Tomcat
function tomcat(){
    local tmp_app_name=tomcat
    tomcat_home=$env_home/apps/tomcat
    log " Exec : cd $src_dir"
    cd $src_dir
    tomcat_name=$(ls *tomcat*.tar.gz 2>/dev/null | sort -r | head -1)

    ###### if it is not exits, try download it form ftp ; 若不存在尝试从 ftp 服务器上下载
    if [ -z "$tomcat_name" ]; then
        log " ** Warn: there is no $tmp_app_name source package exits...; 源码包目录中不存在 $tmp_app_name 安装包..."

        log " Try to download $tmp_app_name from ftp service $FTP_HOST "
        log " There has ${#FTP_TOMCAT_FILES[*]} version on ftp server ; Ftp 服务器上包含 ${#FTP_TOMCAT_FILES[*]} 个 $tmp_app_name 版本: "
        local tmp_version=
        if [ 1 -lt ${#FTP_TOMCAT_FILES[*]} ]; then
            for key in ${!FTP_TOMCAT_FILES[*]}; do
                log "    $key -> ${FTP_TOMCAT_FILES[$key]}"
            done
            read -p " >> Please Select suitable version to setup.请选择合适的版本来安装 : " tmp_version
        fi
        local tmp_pack_name=${FTP_TOMCAT_FILES[$tmp_version]}
        log " You Select the $tmp_app_name version is [$tmp_version] -> $tmp_pack_name ."
        local tmp_pack_file_path="ftp://$FTP_HOST$FTP_TOMCAT_DIR/$tmp_pack_name"
        log " The $tmp_app_name ftp address is $tmp_pack_file_path; $tmp_app_name 的 ftp 下载地址为: $tmp_pack_file_path ..."
        log " wget $tmp_pack_file_path"
        wget $tmp_pack_file_path
    fi


    ###### ensure the $tmp_app_name package ok? 再次确定 $tmp_app_name 包文件是否正常?
    tomcat_name=$(ls *tomcat*.tar.gz 2>/dev/null | sort -r | head -1)
    if [ -z "$tomcat_name" ]; then
        log " ** Warn: there is no tomcat source package exits...; 源码包目录中不存在 tomcat 安装包..."
        read -p " Select:  I/i) Ignore 忽略不存在; Default) Exit >> " is_ignore
        is_ignore=$(echo $is_ignore | tr "A-Z" "a-z")
        if [ "i" != "$is_ignore" ]; then
            log "exit; 程序退出!!!"
            exit 102
        else
            log "You ignore this, continue ; 你忽略了此警告，安装程序将继续执行 ... "
        fi
    else
        log "Detect tomcat source package is $tomcat_name ..."
        mkdir -p $tomcat_home
        log "tar -xzvf $tomcat_name -C $tomcat_home --strip-components=1"
        tar -xzf $tomcat_name -C $tomcat_home --strip-components=1
        #### create setenv.sh
        log "touch $tomcat_home/bin/setenv.sh"
        touch $tomcat_home/bin/setenv.sh
        echo "\
CATALINA_OUT=$env_home/apps/logs/catalina.out
        " > $tomcat_home/bin/setenv.sh
        #### set server.xml
        ###### 判断server.xml 模板文件是否存在
        ######## 获取tomcat的主版本号
        tomcat_major_version=$(echo "$tomcat_name" | sed -e 's/apache-tomcat-//g' | cut -c 1)
        if [ -n $tomcat_major_version ]; then
            tomcat_server_file_tpl=$conf_tpl_dir/server-${tomcat_major_version}.xml
        fi
        log "tomcat template configure file is : $tomcat_server_file_tpl ..."
        tomcat_server_file=$tomcat_home/conf/server.xml
        tomcat_shutdown_port=
        local tomcat_http_port_suffix=
        if [ -f "$tomcat_server_file_tpl" ]; then
            log " gain the last bit of tomcat http port, it shoud be one bit and in [0-9], such as 8, then the port is 8088; if you input is null, use default 8080, 提示用户输入一位数字，如果输入的是 8，那么端口号为 8088 ."
            while :
            do
                read -p " >> Please input the last bit for tomcat listener http port, Default http port is $TOMCAT_HTTP_PORT_DEFAULT, last bit is [${TOMCAT_HTTP_PORT_DEFAULT: (${#TOMCAT_HTTP_PORT_DEFAULT}-1)}] >> " tomcat_http_port_suffix
                if [ -z "$tomcat_http_port_suffix" ]; then
                    tomcat_http_port=$TOMCAT_HTTP_PORT_DEFAULT
                    break
                elif [ $tomcat_http_port_suffix -ge 0 ] && [ $tomcat_http_port_suffix -le 9 ]; then
                    tomcat_http_port="808$tomcat_http_port_suffix"
                    break
                else
                    log " You inut the number $tomcat_http_port_suffix is illegal." WARN
                fi
            done
            log "The tomcat use http port $tomcat_http_port "
            tomcat_shutdown_port="8${tomcat_http_port:(${#tomcat_http_port}-1)}05"
            log "The tomcat use shutdown port $tomcat_shutdown_port "

            log "Begain to create server.xml..."
            cat "$tomcat_server_file_tpl" | sed -e "s:@@TOMCAT_SHUTDOWN_PORT@@:${tomcat_shutdown_port}:g"  | sed -e "s:@@TOMCAT_HTTP_PORT@@:${tomcat_http_port}:g" | sed -e "s:@@TOMCAT_ACCESS_DIR@@:${env_home}/apps/logs:g " | sed -e "s:@@PROJECT_HOME@@:${env_home}/apps/docs/${project_name}:g " > ${tomcat_server_file}
            log "The tomcat config file 'server.xml' is exist.."
        else
            log "The tomcat config file 'server.xml' is not exist.." ERROR
        fi
    fi
    log "chown -R $user.$group $env_home"
    chown -R "$user"."$group" "$env_home"
    cd -
    sleep $SLEEP_TIME
}

function tools() {
    log "Begin to install required tools..."
    log "Create kael directory: mkdir -p $env_home/kael"
    mkdir -p "$env_home/kael"
    cd "$mydir"
    for item in `ls ../`
    do
    	if [ "$item" != "$APP_NAME" ]; then
            log " -> copy $item tool to $env_home/kael .."
            cp -r "$mydir/../$item" "$env_home/kael/"
        fi
    done

    ## 初始化普通 Web 项目环境
    if [ -d "$env_home/kael/update" ]; then
        log "init web env"
        sh "$env_home/kael/update/init.sh" "$project_name"
    fi
}

## main
function main(){
    log "Welcome to use the $APP_AAME [$VERSION] tools, We believe you will like it..."
    is_root

    init
    
    case $1 in
        nginx )
            nginx
            ;;
        mservice )
            base
            jdk
            tools
            base_mop_up
            ;;
        web )
            base
            jdk
            tomcat
            tools
            base_mop_up
            ;;
        * )
            base
            ;;
    esac
    log "Finish to invoke the $APP_NAME [$VERSION] tools, Tks for use it..."
}

main $@
