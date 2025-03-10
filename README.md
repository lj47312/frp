## Frpc客户端管理脚本
Frp 是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 tcp, http, https 等协议类型，并且 web 服务支持根据域名进行路由转发。

* 详情：fatedier (https://github.com/fatedier/frp)</br>
* 脚本原作者：clangcn (https://github.com/clangcn/onekey-install-shell)</br>
* frpc.init脚本原作者：MvsCode(https://github.com/MvsCode/frps-onekey )，由frps.init代码修改，供frpc使用。

### 操作方法
#### 一、安装Frpc客户端
~~~bash
curl -LO https://raw.githubusercontent.com/KuwiNet/frpc-onekey/master/frpc.sh && chmod +x frpc.sh && ./frpc.sh
~~~

#### 二、修改Frpc配置
先修改 frpc.toml 文件，确保格式及配置正确无误！文件位置：/usr/local/frpc/frpc.toml
~~~bash
vi /usr/local/frpc/frpc.toml
~~~

#### 三、启动Frpc、更新、强制重装
~~~bash
sudo systemctl start frpc    # 启动服务
~~~
~~~bash
sudo systemctl restart frpc  # 重启服务
~~~
~~~bash
sudo systemctl status frpc   # 查看状态
~~~
~~~bash
sudo ./frpc.sh update        # 自动检测更新
~~~
~~~bash
sudo ./frpc.sh uninstall     # 卸载
~~~
~~~bash
sudo ./frpc.sh reinstall     # 强制重新安装
~~~

#### 四、快捷命令
~~~bash
frpc start     # 启动服务
~~~
~~~bash
frpc restart   # 重启服务
~~~
~~~bash
frpc stop      # 停止服务
~~~
~~~bash
frpc status    # 查看状态
~~~
~~~bash
frpc version   # 查看版本
~~~
~~~bash
frpc config    # 编辑配置
~~~
~~~bash
用法: frpc {start|stop|restart|status|config|version}
~~~
