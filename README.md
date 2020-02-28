# kael
Linux 平台下部署管理 Java Web(war包) / J2SE(jar包) 项目的工具包。


## 1、你现在所处的环境是否适合使用 kael ?
- 如果你所在的公司是一个创业公司。  
- 如果你所在的团队是公司里的一个小团队，公司并没有一个统一且完善的运维平台供各团队（部门）使用。
- 你是一个运维，每天有大量的重复性工作：
   - 安装一个基础的 Java 运行环境。
   - 将 Java 发布包（jar/war）包上传至服务器，并部署启动。
   - 一台机器上部署多个 Java 项目，你经常要处理不同的项目之间相互影响的问题。
   - 在某些糟糕的情况下，你需要回退至某个历史版本。
- 如果你自己尝试做一个小项目（或者是一个测试项目，或个人项目），需要快速部署到 Linux 下。

如果你处在以上情况（不仅限于此），但是没有容器化 docker 的想法或技术能力，那么你可以尝试一下 kael 来帮助你摆脱烦恼。


## 2、组件介绍
kael 由几个不同作用的主要组件构成，以下为不同组件的基本功能介绍：
- **kael-pre-install**。安装软件包的基础运行环境，如安装程序 nginx、tomcat、jdk，创建程序运行用户，规划程序运行的环境目录（程序包发布目录、日志运行目录、常用工具包目录等）。
- **update**。软件运维全生命周期：打包、上传、分发、发布、启停。
   - **package.sh**。用于 java 打包。支持从 svn 更新代码，并打包。
   - **deploy.sh**。将打好的包，部署至程序运行的正确目录。
   - **restart.sh**。重启程序。若程序未运行，直接启动。
- **mservice**。独立 jar 包启停工具。（最初是团队转向微服务架构时，为了管理使用spring boot/spring cloud开发的jar包）
   - **bin/mservice.sh**。启动、重启、停止 jar 包程序。


## 3、设计思路
部署软件采用 nginx + java 的方式来运行。一台 Linux 主机上部署一个 nginx，但是可以同时部署多个 java 应用，每个 java 应用之间使用 linux 用户隔离。

多数情况下，工具包里的各个小工具（脚本），既可以在 linux 非root用户下执行操作，也可以在 root下执行操作，在 root 下控制指定用户下 java 应用的行为。

## 4、各组件操作指南

### 4.1、预安装工具 kael-pre-install 使用指南
安装基础运行环境。在发布项目包之前，需要 Linux 用户以及 Java 环境。

#### 4.1.1、下载 kael 安装包。
下载 kael 安装包，必须使用 root 用户下载，建议目录：/root/kael。
```bash
git clone https://github.com/zenfery/kael.git
sh kael/kael-pre-install/init.sh
```
#### 4.1.2、安装
安装命令如下：`sh kael/kael-pre-install/install.sh [type]`
**type** 的可取值范围如下：
- **-**。即不带参数的情况，安装基础的用户环境。
- **nginx**。单独安装 nginx 应用。
- **mservice**。安装 jar 包类型应该环境，比如 SpringBoot 类应用。
- **web**。安装 Tomcat 应用环境。
不同的 type 需要将对应的安装包上传至 `kael-pre-install/src/` 目录下。所需要的安装包如下：
type     | 安装包
:-       |  :-:
nginx    | nginx-1.10.1.tar.gz <br/> pcre-7.9.tar.gz <br/> zlib-1.2.3.tar.gz <br> ngx_cache_purge-2.3.tar.gz
mservice | jdk-8u77-linux-x64.tar.gz
web      | jdk-8u77-linux-x64.tar.gz <br/> apache-tomcat-8.0.30.tar.gz

  *注：安装包版本根据实际需要选择。*

安装示例：
```bash
cd kael/kael-pre-install/
sh install.sh mservice
```

### 4.2、微服务工具 mservice 使用指南
#### 4.2.1、 环境检查
- jre/jdk 。执行命令 ` java -version` 检查。

#### 4.2.2、配置文件修改
配置文件为：`kael/mservice/conf/mservice.conf`  
配置参数含义：
- **JAVA_HOME** : (可选) JAVA_HOME，默认为依环境配置。
- **ENV_HOME** : (可选) 项目部署的根目录，与 update 中的 ENV_HOME 一致。默认为 $HOME。
- **JAVA_OPTS** : (可选) JAVA运行参数。
- **DOCS_HOME** : (可选) 程序包最终运行部署的目录。默认为 $ENV_HOME/apps/docs。
- **LOG_ENABLE** : (可选) 是否使用脚本收集控制台日志输出。默认为开启，如需关闭设置为 false。
- **LOG_FOLDER** : (可选) 日志打印目录。默认为 $ENV_HOME/apps/logs。
- **LOG_FILENAME** : (可选) 日志打印的文件。默认为 $LOG_FOLDER/logs/${APP_NAME}.log
- **APP_NAME** : (可选) 应用程序名称。默认从发布目录中自动探测。

配置示例：
   ```bash
   ENV_HOME=$HOME
   LOG_ENABLE=false
   JAVA_OPTS=" -Dspring.profiles.active=test -Dserver.port=9700 "
   ```
*注意: 安装完 mservice 环境，记得根据实际情况修改这两个运行参数：spring.profiles.active、server.port。*

#### 4.2.3、命令执行
   *目前只支持运行用户（非root）运行。*  

语法：`sh kael/mservice/bin/mservice.sh start|stop|restart|status [<version>]`
   ```bash
   ## 以下命令均在 test 用户下执行

   # 启动服务 test
   sh mservice.sh start
   # 启动服务 test 的 1.0 版本
   sh mservice.sh start 1.0

   # 停止服务 test
   sh mservice stop

   # 重启服务 test
   sh mservice.sh restart
   sh mservice.sh restart 1.0

   # 查看服务状态
   sh mservice.sh status
   ```


### 4.3、升级发布工具 update 使用指南
#### 4.3.1、 环境检查
某些工具需要一些依赖才能正常执行。
- （package.sh 依赖）svn 客户端工具。此工具为 **package.sh** 工具从 svn 上下载最新代码时使用。 执行命令 ` svn --version ` 检查是否正常安装。若未安装可参考以下命令：
   ```bash
   # centos
   yum install subversion -y
   ```
- （package.sh 依赖）maven客户端。此工具为 **package.sh** 工具构建打包java项目时使用。

#### 4.3.2、配置文件修改
配置文件为 ` kael/update/conf/env.conf`。

配置参数解释:
- **EVN_HOME** : 项目部署运行环境的根目录，多数情况下设置为运行用户的 HOME 目录。
- **PROJECT_NAME** : 项目的名称，多数情况下与用户的名称一致。
- **SVN_DIR** : 项目的 SVN 地址。（package.sh 依赖）
- **SVN_USER** : 项目的 SVN 用户。（package.sh 依赖）
- **SVN_ENABLED** : 项目是否启用SVN。（package.sh 依赖）
- **GIT_DIR** : 项目的 GIT 地址。（package.sh 依赖）
- **GIT_BRANCH** : 项目的 GIT 分支。（package.sh 依赖）
- **GIT_USER** : 项目的 GIT 用户。（package.sh 依赖）
- **GIT_PASS** : 项目的 GIT 密码。（package.sh 依赖）
- **GIT_ENABLED** : 项目是否启用GIT。（package.sh 依赖）
- **MVN_PROFILE** : mvn 命令打包时，使用的 Profile，若设置为 test，则 `mvn clean package -Ptest`。
- **EXEC_SLEEP_INTERVAL** : 多步执行时，时间停顿，方便执行人员查看。

示例：
   ```bash
   ENV_HOME="$HOME"
   PROJECT_NAME=project-name

   SVN_DIR="https://192.168.2.100/svn/trunk/test"
   SVN_USER="user"
   SVN_PASS="password"
   MVN_PROFILE="common"

   EXEC_SLEEP_INTERVAL=1
   ```

#### 4.3.3、命令执行
命令位置：`kael/update/`。

- **package.sh** 打包。打好的程序包会置于运行用户的目录 `~/kael/update/release`下：
   ```shell
   # 项目用户执行
   sh package.sh
   ```

- **deploy.sh** 部署，运行部署后，程序包将会部署至运行用户的 `~/apps/docs` 目录下：
   - root 用户执行语法：` sh deploy.sh <user> [<version>] `，user为 linux 用户，version 为 程序版本。
      ```bash
      # 部署项目 test
      sh deploy.sh test

      # 部署项目 test 的 1.0 版本
      sh deploy.sh test 1.0
      ```
   - 非 root 用户执行语法：`sh deploy.sh [<version>]`
      ```bash
      # 部署项目 test，在 test 用户下执行
      sh deploy.sh

      # 部署项目 test 的 1.0 版本，在 test 用户下执行
      sh deploy.sh 1.0
      ```

- **restart.sh** 启停。
   - root 用户执行语法：` sh restart.sh <user> [<version>]`。
      ```bash
      # 重启项目test
      sh restart.sh test

      # 重启项目 test 的 1.0 版本
      sh restart.sh test 1.0
      ```
   - 非root用户执行语法：`sh restart.sh [<version>]`
      ```bash
      #重启项目test，在test用户执行
      sh restart.sh

      #重启项目 test的 1.0 版本，在test用户下执行
      sh restart.sh 1.0
      ```

### 4.4、灰度升级工具 gray
#### 4.4.1 nginx服务器的灰度
基于 nginx 的灰度发布，一般会采用根据 cookie 或 ip 来进行灰度发布；如果每次上线都由运维来修改配置文件来进行灰度的话，不方便，并且增加了出错的概率。此灰度工具，仅仅是将修改配置文件的工作交由脚本来完成，避免手动带来的风险。

配置文件为 ` kael/gray/nginx/config`。

配置参数解释:
- **NGINX_HOME** : nginx 的安装目录。如: /usr/local/nginx。
- **NGINX_SITES_DIR** : nginx 的所有配置文件目录。如: ${NGINX_HOME}/conf/sites。
- **NGINX_SBIN** : nginx 的执行文件。如: ${NGINX_HOME}/sbin/nginx。

命令执行：` kael/gray/nginx/gray.sh <cmd> <conf_name> [<gray_name>]`。
   - **cmd** : 取值范围 start | recover | clear 。
      - start : 开始灰度。
      - recover : 结束灰度。恢复到原始状态。
      - clear : 程序为了保险起见，会生成一些强制的备份文件。如果确定是安全的话，可以执行此命令，将其删除。

   在使用灰度工具之前，需要提前准备发即将要灰度的配置文件。比如，需要灰度的配置文件为: nginx/conf/sites/test.conf，灰度配置文件可以有多个，如：nginx/conf/sites/test.gray.0，nginx/conf/sites/test.gray.import。那么 conf_name 则为 test，gray_name 即为 0 和 import。

   命令示例：
   ```bash
      # 针对 test 灰度 0
      sh gray/nginx/gray.sh start test 0
      # 针对 test 灰度 import
      sh gray/nginx/gray.sh start test import
      # 结束灰度
      sh gray/nginx/gray.sh recover test
      # 清理强制备份的配置文件
      sh gray/nginx/gray.sh clear test
   ```

## 5、 版本升级
kael 工具包从 2.4 开始支持一鍵升级新版本。升级请先升级 root 用户下的 kael 工具包，再升级相应用户下。

  ```bash
  # 查看当前版本
  sh kael/version.sh

  # 升级root下的版本
  su - root
  sh kael/upgrade.sh

  # 升级用户 test 下的版本(在root用户下执行)
  su - root
  sh kael/upgrade.sh test
  ```
