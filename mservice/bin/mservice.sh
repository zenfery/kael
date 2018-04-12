#!/bin/sh

## Base Directory
mydir=$(cd "$(dirname "$0")"; pwd)
echo "[`date`] Current directory : $mydir"

project_home=$(cd "$mydir/..";pwd)
echo "[`date`] Project home directory : $project_home "

## Load config
JAVA_HOME=""
source $project_home/conf/mservice.conf
source $project_home/../conf/sys.conf

if [ -z "$ENV_HOME" ]; then
    ENV_HOME=$HOME
fi
echo " =====> DEBUG: ENV_HOME = $ENV_HOME, JAVA_HOME = $JAVA_HOME"

JAVA_CMD=
if [ -z "$JAVA_HOME" ]; then
    JAVA_HOME=$ENV_HOME/apps/jdk
    JAVA_CMD=$ENV_HOME/apps/jdk/bin/java
else
    JAVA_CMD=$JAVA_HOME/bin/java
fi

if [ -z "$DOCS_HOME" ]; then
    DOCS_HOME=$ENV_HOME/apps/docs
fi


input_version="$2"
echo "input_version: $input_version"
if [ -z "$JARFILE" ]; then
    jar_num=$( ls $DOCS_HOME/*.jar | wc -l )
    if [ $jar_num -gt 0 ]; then
        echo "[`date`] Detect jar file number is $jar_num, more than 0 , it will fetch the highest version jar ... "
        jarfiles=$( ls -l $DOCS_HOME/*.jar | awk '{print $NF}' )
        version="0"
        version_before="0.0.0.0"
        #version_number=0
        for jarfile in $jarfiles; do
            
            jarfile_name=$(basename $jarfile)
            if [ -n "$input_version" ];then
                break
            fi
            ver_curr=${jarfile_name%.*}
            ver_curr=${ver_curr##*-}
            version_temp=${version}

            app_name_temp=${jarfile_name%-*}
            echo "[`date`] one of the jar file is  : $jarfile , detect app name is [$app_name_temp], version is [$ver_curr], version_before is [$version]"
            ## compare version_before and ver_curr

            dot_count_curr=$(echo "$ver_curr" | awk -F '.' '{print NF-1}')
            if [ $dot_count_curr -eq 2 ]; then
                ver_curr_temp="$ver_curr"".0"
            elif [ $dot_count_curr -eq 1 ]; then
                ver_curr_temp="$ver_curr"".0.0"
            elif [ $dot_count_curr -eq 0 ]; then
                ver_curr_temp="$ver_curr"".0.0.0"
            fi

            dot_count_version=$(echo "$version_temp" | awk -F '.' '{print NF-1}')
            if [ $dot_count_version -eq 2 ]; then
                version_temp="$version_temp"".0"
            elif [ $dot_count_version -eq 1 ]; then
                version_temp="$version_temp"".0.0"
            elif [ $dot_count_version -eq 0 ]; then
                version_temp="$version_temp"".0.0.0"
            fi

            ver_curr_temp_arr=(${ver_curr_temp//./ })
            version_temp_arr=(${version_temp//./ })
            if [ ${ver_curr_temp_arr[0]} -gt ${version_temp_arr[0]} ]; then
                version=$ver_curr
                JARFILE="$jarfile"
                continue 
            elif [ ${ver_curr_temp_arr[0]} -eq ${version_temp_arr[0]} ]; then
                if [ ${ver_curr_temp_arr[1]} -gt ${version_temp_arr[1]} ]; then
                    version=$ver_curr
                    JARFILE="$jarfile"
                    continue 
                elif [ ${ver_curr_temp_arr[1]} -eq ${version_temp_arr[1]} ]; then
                    if [ ${ver_curr_temp_arr[2]} -gt ${version_temp_arr[2]} ]; then
                        version=$ver_curr
                        JARFILE="$jarfile"
                        continue
                    elif [ ${ver_curr_temp_arr[2]} -eq ${version_temp_arr[2]} ]; then
                        if [ ${ver_curr_temp_arr[3]} -gt ${version_temp_arr[3]} ]; then
                            version=$ver_curr
                            JARFILE="$jarfile"
                            continue
                        fi
                    fi
                fi
            fi

        done #end for

        echo "[`date`] the max version of jar file is  : [$version]"
        echo "[`date`] the correct jar file is  : [$JARFILE]"
    else
        echo "[`date`] *** Error ::: There is no jar file exist in $DOCS_HOME ..."
        exit 100
    fi
fi

if [ -z "$APP_NAME" ]; then
    jarfile_name=$( basename $JARFILE )
    APP_NAME=${jarfile_name%-*}
fi

if [ ! -z "$input_version" ];then
    JARFILE=$(dirname $JARFILE)"/$APP_NAME-$input_version.jar"
fi

if [ -z "$LOG_FOLDER" ]; then
    LOG_FOLDER=$ENV_HOME/apps/logs
fi
mkdir -p $LOG_FOLDER

if [ -z "$LOG_FILENAME" ]; then
    LOG_FILENAME=$APP_NAME.log
fi
touch $LOG_FOLDER/$LOG_FILENAME

echo "[`date`] Use config below : "
echo "[`date`] ::: ENV_HOME -> $ENV_HOME"
echo "[`date`] ::: JAVA_HOME -> $JAVA_HOME"
echo "[`date`] ::: JAVA_CMD -> $JAVA_CMD"
echo "[`date`] ::: DOCS_HOME -> $DOCS_HOME"
echo "[`date`] ::: JARFILE -> $JARFILE"
echo "[`date`] ::: APP_NAME -> $APP_NAME"
echo "[`date`] ::: LOG_FOLDER -> $LOG_FOLDER"
echo "[`date`] ::: LOG_FILENAME -> $LOG_FILENAME"

log_full_filename=$LOG_FOLDER/$LOG_FILENAME
if [ ! -d "$project_home/run" ];then
    mkdir -p $project_home/run
fi
PIDFILE=$project_home/run/mservice.pid
## start 启动
function start(){
    if [ -f $PIDFILE ]; then
        PID=`cat "$PIDFILE"`
        ps -p $PID >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            echo "mservice[$APP_NAME] appears to still be running with PID $PID. Start aborted."
            exit 1
        else
            echo "Removing/clearing stale PID file."
            rm -f "$PIDFILE" >/dev/null 2>&1
            if [ $? != 0 ]; then
                echo "Unable to remove or clear stale PID file. Start aborted."
                exit 1
            fi
        fi
    fi
    echo "Starting mservice $JARFILE ..."
    touch "$PIDFILE"
    echo " INFO : Exec: nohup $JAVA_CMD $JAVA_OPTS -jar $JARFILE 2>&1 >> $log_full_filename  &"
    nohup $JAVA_CMD $JAVA_OPTS -jar $JARFILE 2>&1 >> $log_full_filename  &
    echo $! > "$PIDFILE"
    echo " mservice $JARFILE started !!!"
}

## stop 停止
function stop(){
    sleep 1
    echo "Pid file : $PIDFILE"
    if [ -f "$PIDFILE" -a -s "$PIDFILE" ]; then
        PID=$(cat $PIDFILE)
    else
        PID=$(ps -ef| grep $JAVA_CMD | grep -v grep | grep $APP_NAME | cut -c 9-15)
    fi
    echo "Current stop pid is [ $PID ]"
    if [ -n "$PID" ]; then
        echo "Stopping ..."
        kill "$PID"
        local stop_count=0
        while [ -x "/proc/${PID}" -a $stop_count -lt 10 ]
        do
            stop_count=$(($stop_count+1))
            echo "Waiting for mservice $APP_NAME to shutdown ($stop_count) ..."
            sleep 1
        done

        ## force to stop
        ps -p $PID >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            echo "mservice[$APP_NAME] is not killed. to force kill -9 ..."
            kill -9 $PID
        fi
    else
        echo "* There is no $APP_NAME mservice running.."
    fi

    echo " mservice $APP_NAME stopped !!!"
}

function status(){
    echo "[`date`] mservice tools version [$VERSION], current application [$JARFILE]... "
    
}

## main
function main(){
    ## exec 执行
    case "$1" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            stop
            sleep 1
            start
            ;;
        status)
            status
            ;;
        *)
            echo "Please use start / stop / restart as first argument"
            ;;
    esac
}


main $@