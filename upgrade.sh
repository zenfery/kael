#!/bin/bash
#mail:*******
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/sys.conf

KAEL_GITHUB_URL=https://github.com/zenfery/kael.git

######root执行时#######
function root_exec(){

    user_name=$1 # give user

    if [ -z "$user_name" ]; then
        ## bakup old kael
        echo "==> Begin to Bakup old kael. old version below: "
        sh $mydir/version.sh

        kael_tmp="$mydir/../kael.upgrade.tmp"
        cp -rf $mydir/../kael $kael_tmp
        
        ## Download the latest version of kael from github
        echo "==> Begin to clone kael from github."
        cd $mydir/../
        rm -rf $mydir/
        git clone $KAEL_GITHUB_URL
        
        ## copy conf
        echo "==> Begin to recover kael config file."
        echo "==> cp -r $kael_tmp/update/conf/* $mydir/update/conf/"
        cp -rf $kael_tmp/update/conf/* $mydir/update/conf/
        echo "==> cp -r $kael_tmp/mservice/conf/* $mydir/mservice/conf/"
        cp -rf $kael_tmp/mservice/conf/* $mydir/mservice/conf/

        echo "==> cp -r $kael_tmp/kael-pre-install/src/* $mydir/kael-pre-install/src/"
        cp -r $kael_tmp/kael-pre-install/src/* $mydir/kael-pre-install/src/

        ## clear tmp
        rm -rf $kael_tmp
    else
        group_name=""
        id $user_name
        if [ $? -eq 0 ];then
            group_name=$(id -gn $user_name)
            user_home_dir=$(cat /etc/passwd | egrep "^$user_name:" | awk -F":" '{ print $6 }')
            echo "==> it will to upgrade the $user_home_dir/kael/"

            user_kael_tmp=$user_home_dir/kael.upgrade.tmp
            cp -rf $user_home_dir/kael $user_kael_tmp

            echo "==> copy the kael from root to $user_name"
            for item in `ls $mydir/`
            do
                if [ "$item" != "kael-pre-install" ]; then
                    echo " -> copy $item tool to $user_home_dir/kael .."
                    cp -rf "$mydir/$item" "$user_home_dir/kael/"
                fi
            done

            echo "==> Begin to recover kael config file."
            echo "==> cp -rf $user_kael_tmp/update/conf/* $user_home_dir/kael/update/conf/"
            cp -rf $user_kael_tmp/update/conf/* $user_home_dir/kael/update/conf/
            echo "==> cp -rf $user_kael_tmp/mservice/conf/* $user_home_dir/kael/mservice/conf/"
            cp -rf $user_kael_tmp/mservice/conf/* $user_home_dir/kael/mservice/conf/

            chown -R "$user_name"."$group_name" "$user_home_dir/kael"

            rm -rf $user_kael_tmp

        else
            echo " [`date`] *** ERROR *** user [$user_name] is not exist.."
            exit 100
        fi
    fi
}

#########
current_user=$(whoami)
if [ $current_user = "root" ];then
   root_exec $@
else
   echo " *** warn *** ::: the command can not exec in not root..."
fi