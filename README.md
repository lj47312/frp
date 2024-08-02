## Frpc客户端管理脚本
Frp 是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 tcp, http, https 等协议类型，并且 web 服务支持根据域名进行路由转发。

* 详情：fatedier (https://github.com/fatedier/frp)</br>
* 脚本原作者：clangcn (https://github.com/clangcn/onekey-install-shell)</br>
* 本脚本完全使用MvsCode(https://github.com/MvsCode/frps-onekey )的frps.init代码修改而成，供frpc使用。

### 操作方法
#### 一、安装Frpc客户端
~~~bash
curl -L https://raw.githubusercontent.com/KuwiNet/frpc/master/frpc_install.sh -o frpc_install.sh && chmod +x frpc_install.sh && ./frpc_install.sh
~~~

#### 二、修改Frpc配置
先修改 frpc.toml 文件，确保格式及配置正确无误！文件位置：/usr/local/frpc/frpc.toml
~~~bash
vi /usr/local/frpc/frpc.toml
~~~

#### 三、启动Frpc、查看状态
~~~bash
sudo systemctl start frpc
~~~
~~~basj
sudo systemctl restart frpc
~~~
~~~bash
sudo systemctl status frpc
~~~
