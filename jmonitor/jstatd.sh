#!/bin/sh
mydir=$(cd "$(dirname "$0")"; pwd)

hostname=$1
echo " input hostname: $hostname"
if [ -z "$hostname" ]; then
    echo " ERROR : the given hostname is null. exit it."
    exit 100
fi
port=$2
echo " input port: $port"
if [ -z "$port" ]; then
    echo " WARN : the given port is null. use default 1099 ."
    port=1099
fi

policy=$mydir/jstatd.all.policy
[ -w ${policy} ] && cat >${policy} <<'POLICY'
grant codebase "file:${java.home}/../lib/tools.jar" {
  permission java.security.AllPermission;
};
POLICY

echo " nohup jstatd -J-Djava.security.policy=${policy} -J-Djava.rmi.server.hostname=$hostname -p $port 2>&1 >> $mydir/jstatd.log & "
nohup jstatd -J-Djava.security.policy=${policy} -J-Djava.rmi.server.hostname=$hostname -p $port 2>&1 >> $mydir/jstatd.log &
