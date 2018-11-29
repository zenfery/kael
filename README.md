# kael
Linux 平台下部署管理 Java Web(war包) / J2SE(jar包) 项目的工具包。


## 你现在所处的环境是否适合使用 kael ?
- 如果你所在的公司是一个创业公司。  
- 如果你所在的团队是公司里的一个小团队，公司并没有一个统一且完善的运维平台供各团队（部门）使用。
- 你是一个运维，每天有大量的重复性工作：
   - 安装一个基础的 Java 运行环境。
   - 将 Java 发布包（jar/war）包上传至服务器，并部署启动。
   - 一台机器上部署多个 Java 项目，你经常要处理不同的项目之间相互影响的问题。
   - 在某些糟糕的情况下，你需要回退至某个历史版本。
- 如果你自己尝试做一个小项目（或者是一个测试项目，或个人项目），需要快速部署到 Linux 下。

如果你处在以上情况（不仅限于此），但是没有容器化 docker 的想法或技术能力，那么你可以尝试一下 kael 来帮助你摆脱烦恼。


## 组件介绍
kael 由几个不同作用的主要组件构成，以下为不同组件的基本功能介绍：
- **kael-pre-install**。安装软件包的基础运行环境，如安装程序 nginx、tomcat、jdk，创建程序运行用户，规划程序运行的环境目录（程序包发布目录、日志运行目录、常用工具包目录等）。
- **update**。软件运维全生命周期：打包、上传、分发、发布、启停。
   - **package.sh**。用于 java 打包。支持从 svn 更新代码，并打包。
   - **deploy.sh**。将打好的包，部署至程序运行的正确目录。
   - **restart.sh**。重启程序。若程序未运行，直接启动。
- **mservice**。独立 jar 包启停工具。（最初是团队转向微服务架构时，为了管理使用spring boot/spring cloud开发的jar包）
   - **bin/mservice.sh**。启动、重启、停止 jar 包程序。


## 设计思路
部署软件采用 nginx + java 的方式来运行。一台 Linux 主机上部署一个 nginx，但是可以同时部署多个 java 应用，每个 java 应用之间使用 linux 用户隔离。

多数情况下，工具包里的各个小工具（脚本），既可以在 linux 用户下执行操作，也可以在 root下执行操作，在 root 下控制指定用户下 java 应用的行为。

## 各组件操作指南

### kael-pre-install 使用指南
安装基础运行环境。

### update 使用指南
#### 环境检查
某些工具需要一些依赖才能正常执行。
- （package.sh 依赖）svn 客户端工具。此工具为 **package.sh** 工具从 svn 上下载最新代码时使用。 执行命令 ` svn --version ` 检查是否正常安装。若未安装可参考以下命令：
   ```bash
   # centos 
   yum install subversion -y
   ```
- （package.sh 依赖）maven客户端。此工具为 **package.sh** 工具构建打包java项目时使用。

#### 配置文件修改
配置文件为 ` kael/update/conf/env.conf`。

配置文件参数解释:
- **EVN_HOME** : 项目部署运行环境的根目录，多数情况下设置为运行用户的 HOME 目录。
- **PROJECT_NAME** : 项目的名称，多数情况下与用户的名称一致。
- **SVN_DIR** : 项目的 SVN 地址。（package.sh 依赖）
- **SVN_USER** : 项目的 SVN 用户。（package.sh 依赖）
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

#### 命令执行
命令位置：`kael/update/`。

- **package.sh** 打包：
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