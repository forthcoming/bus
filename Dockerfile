FROM ubuntu:latest
LABEL author="zgt" mail="212956978@qq.com"
ENV DEBIAN_FRONTEND=noninteractive
ENV ROOTPATH=/root
WORKDIR $ROOTPATH
RUN apt update;\
    apt install -y iputils-ping vim git curl make gcc supervisor nginx;\
    rm -rf /var/lib/apt/lists/*
RUN ["/bin/bash", "-c", "mkdir -p data/{redis_cluster/{7000,7001,7002,7003,7004,7005},redis}"]

### 配置vim ###
RUN echo 'set encoding=utf-8' >> /etc/vim/vimrc
RUN echo 'set nu' >> /etc/vim/vimrc

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
    rm -rf redis-stable redis-stable.tar.gz;\
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

### 启动服务 ###
COPY cnf/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY start.sh start.sh
CMD ["/bin/bash","start.sh"]
