### 功能

**一键部署如下应用:**

* `mongo单节点`
* `redis单节点`
* `redis集群`
* `mysql单节点`
* `nginx`
* `miniconda`
* `git`
* `supervisor`
* `clash`

### 所需环境

```shell
curl -fsSL https://get.docker.com | sh # 安装docker
```

### 启动

```shell
docker compose up -d  # compose.yaml目录下执行
```

### 测试命令

```shell
mongo -uroot -proot  # mongodb://root:root@localhost:27017 
redis-cli
redis-cli -c -p 7000
mysql -h127.0.0.1 -uroot -proot
```
```python
import requests

r = requests.get('https://google.com', proxies={"https": "127.0.0.1:3456"})
print(r.text)

# 浏览器设置好代理即可访问外网
```
