## install nginx
NGINX_CODE_NO_SOURCE=111
NGINX_CODE_NO_PCRE=112
NGINX_CODE_NO_ZLIB=113
NGINX_CODE_NO_CACHE_PURGE=114
function nginx(){
    log "Begin to install Nginx..."
    nginx_home=/usr/local/nginx
    #### judge nginx is installed ?
    log " Judge Nginx is installed ???"
    if [ -d "$java_home" ]; then
        log " nginx is installed , ignore it ..."
        $nginx_home/sbin/nginx -V
        return
    fi

    #### judge nginx source file exist? 探测当前源文件目录包中是否有 nginx 安装包
    log " Exec : cd $src_dir"
    cd $src_dir
    nginx_name=$(ls *nginx*.tar.gz 2>/dev/null | sort -r | head -1)
    pcre_name=$(ls *pcre*.tar.gz 2>/dev/null | sort -r | head -1)
    zlib_name=$(ls *zlib*.tar.gz 2>/dev/null | sort -r | head -1)
    cache_purge_name=$(ls *ngx_cache_purge*.tar.gz 2>/dev/null | sort -r | head -1)

    ## nginx
    nginx_source_dir=
    if [ -z "$nginx_name" ]; then
        log "There is no nginx source package exist in $src_dir, exit install process..." ERROR
        exit $NGINX_CODE_NO_SOURCE
    else
        nginx_source_dir=${nginx_name/.tar.gz/}
        log " [Exec]: tar -xzvf $nginx_name ..."
        tar -xzvf "$nginx_name"
        #log "$nginx_source_dir" DEBUG
    fi
    configure_params="--prefix=$nginx_home --with-file-aio --with-http_ssl_module --with-http_sub_module --with-http_flv_module --with-http_stub_status_module"
    ## pcre
    pcre_source_dir=
    if [ -z "$pcre_name" ]; then
        log "There is no pcre source package exist in $src_dir ."
        pcre_continue="Y"
        read -p " >> is continue? [Y/N]: " pcre_continue
        if [ "$pcre_continue" != "Y" ] || [ "$pcre_continue" != "y" ]; then
            exit $NGINX_CODE_NO_PCRE
        fi
    else
        pcre_source_dir=${pcre_name/.tar.gz/}
        log " [Exec]: tar -xzvf $pcre_name ..."
        tar -xzvf "$pcre_name"
        configure_params="$configure_params --with-pcre=$src_dir/$pcre_source_dir"
    fi
    ## zlib 
    zlib_source_dir=
    if [ -z "$zlib_name" ]; then
        log "There is no zlib source package exist in $src_dir ."
        zlib_continue="Y"
        read -p " >> is continue? [Y/N]: " zlib_continue
        if [ "$zlib_continue" != "Y" ] || [ "$zlib_continue" != "y" ]; then
            exit $NGINX_CODE_NO_ZLIB
        fi
    else
        zlib_source_dir=${zlib_name/.tar.gz/}
        log " [Exec]: tar -xzvf $zlib_name ..."
        tar -xzvf "$zlib_name"
        configure_params="$configure_params --with-zlib=$src_dir/$zlib_source_dir"
    fi
    ## cache_purge 
    cache_purge_source_dir=
    if [ -z "$cache_purge_name" ]; then
        log "There is no cache_purge source package exist in $src_dir ."
        cache_purge_continue="Y"
        read -p " >> is continue? [Y/N]: " cache_purge_continue
        if [ "$cache_purge_continue" != "Y" ] || [ "$cache_purge_continue" != "y" ]; then
            exit $NGINX_CODE_NO_CACHE_PURGE
        fi
    else
        cache_purge_source_dir=${cache_purge_name/.tar.gz/}
        log " [Exec]: tar -xzvf $cache_purge_name ..."
        tar -xzvf "$cache_purge_name"
        configure_params="$configure_params --add-module=$src_dir/$cache_purge_source_dir"
    fi

    ## install
    log " [Exec]: cd $nginx_source_dir ..."
    cd $nginx_source_dir
    pwd
    log " [Exec]: ./configure $configure_params ..."
    ./configure $configure_params
    log " [Exec]: make && make install ..."
    make && make install

    ## handle config file
    log "cp -f $conf_tpl_dir/nginx/nginx.conf $nginx_home/conf/" EXEC
    cp -f $conf_tpl_dir/nginx/nginx.conf $nginx_home/conf/
    log "mkdir -p $nginx_home/conf/sites $nginx_home/conf/crt"
    mkdir -p $nginx_home/conf/sites $nginx_home/conf/crt
   
    ## end 
    sleep $SLEEP_TIME
}
