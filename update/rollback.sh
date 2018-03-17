############################################################
## @auth: pengfei.cheng 2015-08-18
## @desc: 回退
############################################################

# 部署环境根目录，一般为HOME目录
ENV_HOME="$HOME"
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)

source $mydir/conf/env.conf


if [ $jarNum -gt 0 ];then # mservice
    echo " INFO  : rollback mserivce ..."
    if [ -z "$DOCS_HOME" ]; then
        DOCS_HOME=$ENV_HOME/apps/docs
    fi
    
    if [ -z "$JARFILE" ]; then
        jar_num=$( ls $DOCS_HOME/*.jar | wc -l )
        if [ $jar_num -eq 1 ]; then
            echo "[`date`] Detect jar file number is $jar_num, more than 0 , it will fetch the highest version jar ... "
            JARFILE=$( ls -l $DOCS_HOME/*.jar | awk '{print $NF}' | sort -r  | head -1 )
        elif [ $jar_num -gt 1 ]; then
            echo "[`date`] Detect jar file number is $jar_num, more than 0 , it will fetch the highest version jar ... "
            JARFILE=$( ls -l $DOCS_HOME/*.jar | awk '{print $NF}' | sort -r  | head -1 )
            echo " rollback is delete the highest version $JARFILE"
            rm -f $JARFILE
        else
            echo "[`date`] *** Error ::: There is no jar file exist in $DOCS_HOME ..."
            exit 100
        fi
    fi

else
    #### 将最近备份的工程回退回去
    timstampFile="$mydir/backup.ts"
    
    timestamp=$(cat "$timstampFile")
    echo " INFO : rollback id : $timestamp "
    currDir="$ENV_HOME/apps/docs/$PROJECT_NAME"
    rollbackDir="$ENV_HOME/apps/docs/$PROJECT_NAME.$timestamp.system"
    echo " INFO : rollback file is :$rollbackDir"
    if [ -z "$timestamp" -o ! -d "$rollbackDir" ]; then
        echo " WARN : there is no package for rollback, please check it..."
        exit 100
    fi
    
    echo " INFO : delete current pack : rm -rf $currDir "
    rm -rf $currDir
    echo " INFO : move backup pack to live : mv $rollbackDir $currDir ..."
    mv $rollbackDir $currDir
    echo " INFO : clean timestamp: rm -f $timstampFile "
    rm -f $timstampFile
fi

#### 重启
sh $mydir/restart.sh
