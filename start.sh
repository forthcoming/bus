set -x
supervisord -c /etc/supervisor/supervisord.conf
while true
do
    sleep .5
    process_num=$(supervisorctl status rc: | grep -c RUNNING)
    if [ "$process_num" != 6 ]
    then
        echo 'wait redis cluster start'
    elif /root/redis/bin/redis-cli -c -p 7000 cluster info | grep cluster_state | grep -q ok  # -q:静默输出,$?代表上一条命令执行是否成功,0成功非0失败
    then
        echo 'redis cluster is complete'
        break
    else  # 已经初始化过集群,但刚启动还未加载好时,状态未fail,再执行一遍create也没事
        /root/redis/bin/redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1 --cluster-yes
    fi
done
sleep infinity
