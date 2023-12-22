set -ex   # e: 若指令传回值不等于0,则立即退出shell(默认继续执行后面命令); x:执行指令后,会先显示该指令及所下的参数
supervisord -c /etc/supervisor/supervisord.conf
while true
do
    sleep 2 #  保证supervisord启动完成
    process_num=$(supervisorctl status rc: | grep -c RUNNING)
    if [ "$process_num" != 6 ];
    then
        echo 'wait redis cluster start'
    elif /root/redis/bin/redis-cli -c -p 7000 cluster info | grep cluster_state | grep -q ok;
    then
        echo 'redis cluster is complete'
        break
    else
        /root/redis/bin/redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 --cluster-replicas 1 --cluster-yes
    fi
done
sleep infinity
