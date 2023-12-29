FROM ubuntu:latest
LABEL author="zgt" mail="212956978@qq.com"
ENV DEBIAN_FRONTEND=noninteractive
ENV ROOTPATH=/root
WORKDIR $ROOTPATH
RUN apt update;\
    apt -f install;\
    apt install -y iputils-ping net-tools vim git curl make gcc supervisor nginx tor privoxy;\
    rm -rf /var/lib/apt/lists/*
RUN ["/bin/bash", "-c", "mkdir -p data/{redis_cluster/{7000,7001,7002,7003,7004,7005},redis}"]

### 配置vim ###
RUN echo 'set encoding=utf-8' >> /etc/vim/vimrc;\
    echo 'set nu' >> /etc/vim/vimrc

### 安装miniconda ###
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh;\
    bash miniconda.sh -b -u -p miniconda3;\
    rm -rf miniconda.sh;\
    miniconda3/bin/conda init bash;\
    echo CONDA=$ROOTPATH/miniconda3/bin/ >> ~/.bashrc;\
    echo 'export PATH=$CONDA:$PATH' >> ~/.bashrc

### 安装redis ###
RUN curl https://download.redis.io/redis-stable.tar.gz -o redis-stable.tar.gz;\
    tar xzf redis-stable.tar.gz;\
    cd redis-stable;\
    make PREFIX=$ROOTPATH/redis install;\
    rm -rf ../redis-stable*;\
    echo REDIS=$ROOTPATH/redis/bin/ >> ~/.bashrc;\
    echo 'export PATH=$REDIS:$PATH' >> ~/.bashrc
COPY cnf/redis/redis.conf $ROOTPATH/redis/redis.conf

### 部署redis集群 ###
RUN ["/bin/bash", "-c", "mkdir -p redis_cluster/{7000,7001,7002,7003,7004,7005}"]
COPY cnf/redis/redis_cluster.conf $ROOTPATH/redis_cluster/redis.conf
RUN sed 's/PORT_NUMBER/7000/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7000/redis.conf;\
    sed 's/PORT_NUMBER/7001/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7001/redis.conf;\
    sed 's/PORT_NUMBER/7002/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7002/redis.conf;\
    sed 's/PORT_NUMBER/7003/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7003/redis.conf;\
    sed 's/PORT_NUMBER/7004/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7004/redis.conf;\
    sed 's/PORT_NUMBER/7005/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7005/redis.conf;\
    rm -rf $ROOTPATH/redis_cluster/redis.conf

### 配置nginx ###
RUN openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/nginx/nginx.key -out /etc/nginx/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
COPY cnf/nginx/nginx.conf /etc/nginx/nginx.conf

### 安装clash ###
# wget https://github.com/zzzgydi/clash-verge/releases/download/v1.3.8/clash-verge_1.3.8_amd64.deb -O clash.deb
COPY app/clash-1.3.8.deb clash.deb
RUN dpkg -i clash.deb;\
    rm -rf clash.deb;\
    mkdir /etc/clash
# wget https://github.com/aiboboxx/clashfree/raw/main/clash.yml
COPY cnf/clash/clash.yaml /etc/clash/clash.yaml
# 下载最新配置文件,应为可能无法访问报错导致RUN失败,所以用"|| :"使命令总是成功
RUN git clone https://github.com/aiboboxx/clashfree.git && mv clashfree/clash.yml /etc/clash/clash.yaml || :;\
    rm -rf clashfree

### 配置tor+privoxy ###
COPY cnf/tor/torrc /etc/tor/torrc
COPY cnf/privoxy/config /etc/privoxy/config

### 启动服务 ###
COPY cnf/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY start.sh start.sh
CMD ["/bin/bash","start.sh"]


# FROM: 指定基础镜像,Dockerfile必须以FROM指令开头
# LABEL: 将元数据添加到镜像中,通过docker inspect查看,可以在一行上指定多个标签
# RUN: 默认/bin/sh -c on Linux or cmd /S /C on Windows,使用如RUN ["/bin/bash", "-c", "echo hello"]更改shell类型
# WORKDIR: 为RUN、CMD、ENTRYPOINT、COPY和ADD指令设置工作目录
# COPY: 复制宿主机文件到容器中
# VOLUME: 创建一个具有指定名称的装载点,自动与本机某个目录关联,可通过docker inspect查看
# CMD: 镜像启动时运行的命令,一个Dockerfile只能有一条CMD指令,如果用户指定了镜像运行的参数,则会覆盖CMD指令(ENTRYPOINT不会被覆盖),只有运行前台程序容器才不会退出
# ENV: 将环境变量＜key＞设置为＜value＞,该变量可在所有后续指令中使用,容器运行时也能够以环境变量的形式被使用,ARG创建的变量只在镜像构建过程中可见
# 以#开头的行视为注释,除非该行是有效的解析器指令,行中其他任何位置的#标记都被视为参数
# Dockerfile指令按从上到下顺序执行,每条指令都会创建一个新的镜像层并对镜像进行提交,每层之间相互独立,cd只在所在层生效
