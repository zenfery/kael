#!/bin/sh
###############
## Common function
##############

## 日志打印
#### $1 - 日志内容
#### $2 - 日志级别 DEBUG(默认); WARN(警告); ERROR(错误)
function log(){
    case $2 in
        ERROR)
            echo " [`date +'%Y-%m-%d %H:%M:%S'`] *** error :: $1"
            ;;
        WARN)
            echo " [`date +'%Y-%m-%d %H:%M:%S'`] --- warn :: $1"
            ;;
        EXEC)
            echo " [`date +'%Y-%m-%d %H:%M:%S'`] --> exec :: $1"
            ;;
        *)
            echo " [`date +'%Y-%m-%d %H:%M:%S'`] $1"
            ;;
    esac
}
