############################################################
## @auth: pengfei.cheng 2015-08-17
## @desc: 项目打包
############################################################
## 2015-10-13, pengfei.cheng, 增加前端打包gulp
## 2017-03-17, pengfei.cheng, 增加 jar 包的打包支持；支持无 pack 程序的mvn web项目打包
############################################################

# 部署环境根目录，一般为HOME目录
ENV_HOME="$HOME"
# 当前脚本目录
mydir=$(cd "$(dirname "$0")"; pwd)
work="$mydir/work"
release="$mydir/release"

source $mydir/conf/env.conf

echo " DEBUG : current user\`s home directory: $ENV_HOME"
echo " DEBUG : current directory: $mydir"

istUpdate=0 # 判断是否有代码库更新

function git_pull(){
    #### 从GIT上更新主干程序
    # 判断是否有work directory:
    echo " INFO  : ******************************** begin update git ******************** "
    istUpdate=0
    if [ -d "$work" ]; then
        echo " INFO  : work directory [$work] exists, git pull..."
        echo " DEBUG : cd $work"
        cd "$work"
        echo " INFO  : git pull [$GIT_DIR][$GIT_BRANCH] to [$work]..."
        if [ -n "$(git branch | grep $GIT_BRANCH)" ]; then
            echo "  DEBUG : local branch $GIT_BRANCH  exits, git chechout $GIT_BRANCH  "
            git checkout $GIT_BRANCH
        else
            echo "  DEBUG : local branch $GIT_BRANCH not exist, git checkout -b $GIT_BRANCH"
            git checkout -b $GIT_BRANCH
        fi
        git fetch origin $GIT_BRANCH
        isUpdate=$[$(git diff $GIT_BRANCH..origin/$GIT_BRANCH --name-only | wc -l)]
        git merge origin/$GIT_BRANCH
    else
        echo " INFO  : work directory [$work] is not exists, create it by clone..."
        echo " INFO  : git clone [$GIT_DIR][$GIT_BRANCH] to [$work]..."
        if [ -z "$GIT_USER" ] || [ -z "$GIT_PASS" ]; then
            echo " DEBUG : git clone -b $GIT_BRANCH $GIT_DIR $work with input or SSH pass"
            git clone -b $GIT_BRANCH $GIT_DIR $work
        else
            echo " DEBUG : git clone -b $GIT_BRANCH ${GIT_DIR/:\/\//://$GIT_USER:$GIT_PASS@} $work with url pass"
            git clone -b $GIT_BRANCH ${GIT_DIR/:\/\//://$GIT_USER:$GIT_PASS@} $work
        fi
        isUpdate=1
    fi
}

function svn_pull(){ 
    #### 从SVN上更新主干程序
    # 判断是否有work directory:
    echo " INFO  : ******************************** begin update svn ******************** " 
    isUpdate=0 # 判断是否有代码库更新
    if [ -d "$work" ]; then
        echo " INFO  : work directory [$work] exists, svn update..."
        echo " DEBUG : cd $work"
        cd "$work"
        echo " INFO  : svn update [$SVN_DIR] to [$work]..."
        echo " DEBUG : svn --non-interactive --trust-server-cert up --username $SVN_USER --password $SVN_PASS"
        isUpdate=$[$(svn --non-interactive --trust-server-cert up --username "$SVN_USER" --password "$SVN_PASS" | wc -l)-1]
    else
        echo " INFO  : work directory [$work] is not exists, create it..."
        echo " INFO  : create : mkdir -p $work ..."
        mkdir -p "$work"
        echo " DEBUG : cd $work"
        cd "$work"
        echo " INFO  : svn checkout [$SVN_DIR] to [$work]..."
        isUpdate=$[$(svn --non-interactive --trust-server-cert --username "$SVN_USER" --password "$SVN_PASS" co "$SVN_DIR" ./ | wc -l)-1]
    fi
}

if [ $GIT_ENABLED -eq 1 ]
then
    git_pull
fi

if [ $SVN_ENABLED -eq 1 ]
then
    svn_pull
fi

echo " DEBUG : cd $mydir"
cd $mydir

echo " DEBUG : isUpdate = $isUpdate "
#### maven package 
isPackageSucc=-1 #判断打包是否成功 0为成功
#isUpdate=1 
#isPackageSucc=0 #判断打包是否成功 0为成功
if [ $isUpdate -le 0 ];then
    echo " INFO  : svn has not update, do nothing... "
else
    echo " INFO  : svn has update... "
    echo " INFO  : ******************************** begin to package  ******************** "
    echo " DEBUG : cd $work"
    cd "$work"
    ## judge pack command exists?
    if [ -f "pack" ]; then
        echo " INFO  : pack command exists, do:  sh pack $MVN_PROFILE"
        sh pack $MVN_PROFILE
    else
        echo " INFO  : invoke maven: mvn clean package -P$MVN_PROFILE -Dmaven.test.skip=true"
        mvn clean package -P$MVN_PROFILE -Dmaven.test.skip=true
        echo " DEBUG : maven invoke result : $?"
    fi
    #echo " INFO  : ******************************** begin gulp  ******************** "
    #echo " DEBUG : cd $work"
    #cd "$work"
    #echo " INFO  : cnpm install"
    #cnpm install
    #echo " INFO  : gulp test "
    #gulp test
    #
    #echo " INFO  : ******************************** begin maven package ******************** "
    #echo " DEBUG : cd $work"
    #cd "$work"
    #echo " INFO  : mvn -s $MVN_SETTINGS clean package -P$MVN_PROFILE -Dmaven.test.skip=true "
    #mvn -s "$MVN_SETTINGS" clean package -P$MVN_PROFILE -Dmaven.test.skip=true
    #echo " DEBUG : maven invoke result : $?"
    #exit 1
    isPackageSucc="$?"
    echo " DEBUG : cd $mydir "
    cd $mydir
fi
echo " DEBUG : isPackageSucc = $isPackageSucc "

#### move package to correct dir
#isPackageSucc=0 #判断打包是否成功 0为成功
if [ $isPackageSucc -eq 0 ];then
    echo " INFO  : ******************************** move package ******************** "
    packageName="$(ls $work/target/*.war)$(ls $work/$PROJECT_NAME/target/*.war)"
    if [ -z "$packageName" ]; then
        packageName="$(ls $work/target/*.jar)$(ls $work/$PROJECT_NAME/target/*.jar)"
    fi
    echo " DEBUG : package program name is : $packageName "
    echo " INFO  : copy package file to $release "
    if [ ! -d "$release" ]; then
        echo " INFO  : [$release] dir is not exists, create it..."
        mkdir -p $release
    fi
    cp $packageName $release/
fi
