## 功能

**一键部署如下应用:**

* **mongo单节点**
* **redis单节点**
* **redis集群**
* **mysql单节点**
* **nginx**
* **miniconda**
* **supervisor**
* **clash**
* **tor**

## 环境准备

```shell
curl -fsSL https://get.docker.com | sh # 安装docker
```

## 启动

```shell
docker compose up -d  # compose.yaml目录下执行
```

## 测试

```shell
mongo -uroot -proot  # mongodb://root:root@localhost:27017 
```

```shell
redis-cli
```

```shell
redis-cli -c -p 7000
```

```shell
mysql -h127.0.0.1 -uroot -proot
```

```python
# 浏览器设置好代理即可访问外网
# clash: 7890是https代理,7891是http代理
# tor: 9050是socks5代理,shadowsocks也是socks5代理
# privoxy: 8118是https代理
# export https_proxy=http://127.0.0.1:7890;export http_proxy=http://127.0.0.1:7891; # 终端使用代理(或添加到~/.bashrc)

# socks5代理性能优于http(s)代理,有些应用只支持https,或者访问被墙的网站,需要将https代理转换成socks5代理给tor使用
# clash作为tor的后置代理,用于翻墙,privoxy作为tor的前置代理,将https代理转换为socks5代理

# privoxy主要配置如下:
# listen-address 0.0.0.0:8118 # 0.0.0.0意思是同一局域网下的其他设备都能使用该代理
# forward-socks5t / 127.0.0.1:9050 . # 将https代理转换成tor的socks5代理

import requests

# 测试clash
r = requests.get('https://google.com', proxies={"https": "127.0.0.1:7890"})
print(r.text)

# 测试tor
r = requests.get('https://httpbin.org/ip', proxies={"http": "socks5://127.0.0.1:9050"})
print(r.text)

# 测试privoxy
r = requests.get('https://check.torproject.org/?lang=zh_CN', proxies={"https": "127.0.0.1:8118"})
print(r.text)
```
