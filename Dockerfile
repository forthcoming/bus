from ubuntu:latest
label author="zgt" mail="212956978@qq.com"
run apt update && apt install -y iputils-ping vim git curl make gcc supervisor mysql-server
env ROOTPATH=/root
workdir $ROOTPATH

### 安装miniconda ###
run curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
run bash miniconda.sh -b -u -p miniconda3
run rm -rf miniconda.sh
run miniconda3/bin/conda init bash
run echo CONDA=$ROOTPATH/miniconda3/bin/ >> ~/.bashrc
run echo 'export PATH=$CONDA:$PATH' >> ~/.bashrc

### 安装redis ###
run curl https://download.redis.io/redis-stable.tar.gz -o redis-stable.tar.gz
run tar xzf redis-stable.tar.gz
run cd redis-stable && make PREFIX=$ROOTPATH/redis install && mv redis.conf $ROOTPATH/redis
run rm -rf redis-stable redis-stable.tar.gz
run echo REDIS=$ROOTPATH/redis/bin/ >> ~/.bashrc
run echo 'export PATH=$REDIS:$PATH' >> ~/.bashrc

### 部署redis集群 ###
run ["/bin/bash", "-c", "mkdir -p redis_cluster/{7000,7001,7002,7003,7004,7005}"]
copy cnf/redis/redis_cluster.conf $ROOTPATH/redis_cluster/redis.conf
run sed 's/PORT_NUMBER/7000/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7000/redis.conf
run sed 's/PORT_NUMBER/7001/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7001/redis.conf
run sed 's/PORT_NUMBER/7002/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7002/redis.conf
run sed 's/PORT_NUMBER/7003/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7003/redis.conf
run sed 's/PORT_NUMBER/7004/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7004/redis.conf
run sed 's/PORT_NUMBER/7005/g' $ROOTPATH/redis_cluster/redis.conf >> $ROOTPATH/redis_cluster/7005/redis.conf
run rm -rf $ROOTPATH/redis_cluster/redis.conf
run $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7000/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7001/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7002/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7003/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7004/redis.conf;\
    $ROOTPATH/redis/bin/redis-server $ROOTPATH/redis_cluster/7005/redis.conf;\
    $ROOTPATH/redis/bin/redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1 --cluster-yes

### 部署mysql主从 ###
run ["/bin/bash", "-c", "mkdir -p mysql_master_replica/{master,replica}"]
copy cnf/mysql/mysqld_master.cnf $ROOTPATH/mysql_master_replica/master/mysqld.cnf
copy cnf/mysql/mysqld_replica.cnf $ROOTPATH/mysql_master_replica/replica/mysqld.cnf


### 配置supervisor ###
copy cnf/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# cmd ["supervisord" "-c" "/etc/supervisor/supervisord.conf"]