############################################################
## @auth: pengfei.cheng 2017-03-28
## @desc: show current version
############################################################

# curr directory
mydir=$(cd "$(dirname "$0")"; pwd)
source $mydir/conf/env.conf
source $mydir/../conf/sys.conf

echo " kael-update version is [$VERSION] ..."
