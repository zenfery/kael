#!/bin/sh

curr_user=$(whoami)
echo " [`date`] current user is [$curr_user]."
if [ $curr_user != "root" ];then
    echo "* WARN: this script was not executed by root user."
    exit 444
fi

## Base Directory
mydir=$(cd "$(dirname "$0")"; pwd)
echo "[`date`] Current directory : $mydir"

project_home=$(cd "$mydir/..";pwd)
echo "[`date`] Project home directory : $project_home "

## Load config
JAVA_HOME=""
source $project_home/nginx/config
source $project_home/../conf/sys.conf
echo "==> NGINX_HOME: $NGINX_HOME"
echo "==> NGINX_SITES_DIR: $NGINX_SITES_DIR"
echo "==> NGINX_SBIN: $NGINX_SBIN"

## usage:
echo ">>> usage: $0 <cmd> <conf_name> <gray_name>"
echo "    * param desc:"
echo "      - cmd: start|recover|clear"
echo "      - conf_name: nginx config name; example, the conf_name of openapi.conf is openapi."
echo "      - gray_name: nginx gray name; example, the gray_name of openapi.gray.1 is 1."
echo "    * example:"
echo "      - $0 start openapi 2"
echo "      - $0 recover openapi"

cmd=$1
conf_name=$2
gray_name=$3
if [ -z "$cmd" -o -z "$conf_name" ];then
    echo "*** error: please input cmd or conf_name."
    exit 404
fi

fsn=`date +%Y%m%d%H%M%S`
sn=`date +%Y%m%d`
echo "==> gray sn: $sn, fsn: $fsn"
ori_conf_file_name=${conf_name}.conf
bakup_file_name="${conf_name}.${sn}"
fbakup_file_name="${conf_name}.fbak.${fsn}"
echo "==> bakup_file_name: $bakup_file_name"
if [ $cmd = "start" ];then ## 开始灰度
    ## 强制每次备份,避免大的异常
    cp $NGINX_SITES_DIR/$ori_conf_file_name $NGINX_SITES_DIR/$fbakup_file_name
    ## bakup ori config file
    if [ ! -f "$NGINX_SITES_DIR/$bakup_file_name" ];then
        echo "mv $NGINX_SITES_DIR/${ori_conf_file_name} $NGINX_SITES_DIR/$bakup_file_name"
        mv $NGINX_SITES_DIR/$ori_conf_file_name $NGINX_SITES_DIR/$bakup_file_name
    fi

    gray_conf_name="${conf_name}.gray.${gray_name}"
    echo "cp $NGINX_SITES_DIR/$gray_conf_name $NGINX_SITES_DIR/${ori_conf_file_name}"
    cp $NGINX_SITES_DIR/$gray_conf_name $NGINX_SITES_DIR/${ori_conf_file_name}
    
    echo "$NGINX_SBIN -s reload"
    $NGINX_SBIN -s reload
elif [ $cmd = "recover" ];then
    echo "mv $NGINX_SITES_DIR/$bakup_file_name $NGINX_SITES_DIR/${ori_conf_file_name}"
    mv $NGINX_SITES_DIR/$bakup_file_name $NGINX_SITES_DIR/${ori_conf_file_name}

    echo "$NGINX_SBIN -s reload"
    $NGINX_SBIN -s reload
elif [ $cmd = "clear" ];then
    echo "rm -f $NGINX_SITES_DIR/${conf_name}.fbak.*"
    rm -f $NGINX_SITES_DIR/${conf_name}.fbak.*
else
    echo "*** error: the param $cmd is not supported."
fi