FROM ubuntu:latest
LABEL author="zgt" mail="212956978@qq.com"
ENV DEBIAN_FRONTEND=noninteractive
ENV ROOTPATH=/root
WORKDIR $ROOTPATH
RUN apt update && apt install -y iputils-ping vim git curl make gcc supervisor mysql-server

### 配置vim ###
RUN echo 'set encoding=utf-8' >> /etc/vim/vimrc
RUN echo 'set nu' >> /etc/vim/vimrc

### 安装miniconda ###
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
RUN bash miniconda.sh -b -u -p miniconda3
RUN rm -rf miniconda.sh
RUN miniconda3/bin/conda init bash
RUN echo CONDA=$ROOTPATH/miniconda3/bin/ >> ~/.bashrc
RUN echo 'export PATH=$CONDA:$PATH' >> ~/.bashrc

### 安装redis ###
RUN curl https://download.redis.io/redis-stable.tar.gz -o redis-stable.tar.gz
RUN tar xzf redis-stable.tar.gz
RUN cd redis-stable && make PREFIX=$ROOTPATH/redis install
COPY cnf/redis/redis.conf $ROOTPATH/redis/redis.conf
RUN rm -rf redis-stable redis-stable.tar.gz
RUN echo REDIS=$ROOTPATH/redis/bin/ >> ~/.bashrc
RUN echo 'export PATH=$REDIS:$PATH' >> ~/.bashrc

### 部署redis集群 ###
RUN ["/bin/bash", "-c", "mkdir -p redis_cluster/{7000,7001,7002,7003,7004,7005}"]
COPY cnf/redis/redis_cluster.conf $ROOTPATH/redis_cluster/redis.conf
RUN sed 's/PORT_NUMBER/7000/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7000/redis.conf
RUN sed 's/PORT_NUMBER/7001/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7001/redis.conf
RUN sed 's/PORT_NUMBER/7002/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7002/redis.conf
RUN sed 's/PORT_NUMBER/7003/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7003/redis.conf
RUN sed 's/PORT_NUMBER/7004/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7004/redis.conf
RUN sed 's/PORT_NUMBER/7005/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7005/redis.conf
RUN rm -rf $ROOTPATH/redis_cluster/redis.conf
RUN $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7000/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7001/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7002/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7003/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7004/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7005/redis.conf;\
    $ROOTPATH/redis/bin/redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1 --cluster-yes

### 部署mysql主从 ###
RUN ["/bin/bash", "-c", "mkdir -p mysql_master_replica/{master,replica}"]
COPY cnf/mysql/mysqld_master.cnf $ROOTPATH/mysql_master_replica/master/mysqld.cnf
COPY cnf/mysql/mysqld_replica.cnf $ROOTPATH/mysql_master_replica/replica/mysqld.cnf

RUN ["/bin/bash", "-c", "mkdir -p data/{mysql,redis_cluster/{7000,7001,7002,7003,7004,7005},redis}"]

### 配置supervisor(supervisord须以前台进程运行) ###
COPY cnf/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
CMD ["supervisord","-c","/etc/supervisor/supervisord.conf"]

