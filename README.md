<h1>Frps服务端一键配置脚本，最新版本：0.63.0</h1>
<p><em>Frp 是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 tcp, http, https 等协议类型，并且 web 服务支持根据域名进行路由转发。</em></p>
<ul>
  <li>详情：fatedier (<a href="https://github.com/fatedier/frp" target="_blank">https://github.com/fatedier/frp</a>)</li>
  <li>此脚本原作者：clangcn (<a href="https://github.com/clangcn/onekey-install-shell" target="_blank">https://github.com/clangcn/onekey-install-shell</a>)</li>
</ul>
<h2><a id="user-content-frps-onekey-install-shell" aria-hidden="true" href="https://github.com/lj47312/frp#frp"></a>Frp</h2>
<h3><a id="user-content-install安装" aria-hidden="true" href="https://github.com/lj47312/frp#install安装"></a>Frps服务端Install（安装）</h3>
<h4><a id="user-content-github" aria-hidden="true" href="https://github.com/lj47312/frp#github"></a>Github</h4>
<div>
  <pre>wget --no-check-certificate https://github.itzmx.com/lj47312/frp/master/frps.sh -O ./frps.sh &amp;&amp; chmod 700 ./frps.sh &amp;&amp; ./frps.sh install</pre>
</div>
<h4><a id="user-content-aliyun" aria-hidden="true" href="https://github.com/lj47312/frp#aliyun"></a>Gitee</h4>
<div>
  <pre>wget --no-check-certificate https://gitee.com/lj47312/frp/raw/main/frps.sh -O ./frps.sh &amp;&amp; chmod 700 ./frps.sh &amp;&amp; ./frps.sh install</pre>
</div>
<h3><a id="user-content-install安装" aria-hidden="true" href="https://github.com/lj47312/frp#install安装"></a>Frpc客户端Install（安装）</h3>
<h4><a id="user-content-github" aria-hidden="true" href="https://github.com/lj47312/frp#github"></a>Github</h4>
<div>
  <pre>wget --no-check-certificate https://github.itzmx.com/lj47312/frp/master/frpc.sh -O ./frpc.sh &amp;&amp; chmod 700 ./frpc.sh &amp;&amp; ./frpc.sh install</pre>
</div>
<h4><a id="user-content-aliyun" aria-hidden="true" href="https://github.com/lj47312/frp#aliyun"></a>Gitee</h4>
<div>
  <pre>wget --no-check-certificate https://gitee.com/lj47312/frp/raw/main/frpc.sh -O ./frps.sh &amp;&amp; chmod 700 ./frpc.sh &amp;&amp; ./frpc.sh install</pre>
</div>
<h3><a id="user-content-uninstall卸载" aria-hidden="true" href="https://github.com/lj47312/frp#uninstall卸载"></a>Uninstall（卸载）</h3>
<div>
  <pre>./frps.sh uninstall</pre>
</div>
<h3><a id="user-content-update更新" aria-hidden="true" href="https://github.com/lj47312/frp#update更新"></a>Update（更新）</h3>
<div>
  <pre>./frps.sh update</pre>
</div>
<h3><a id="user-content-server-management服务管理器" aria-hidden="true" href="https://github.com/lj47312/frp#server-management服务管理器"></a>Server management（服务管理器）</h3>
<div>
  <pre>Usage: /etc/init.d/frps {start|stop|restart|status|config|version}</pre>
</div>

修改Frpc配置（Frps 配置文件位置: /usr/local/frps/frps.toml）
先修改 frpc.toml 文件，确保格式及配置正确无误！文件位置：/usr/local/frpc/frpc.toml
~~~bash
vi /usr/local/frpc/frpc.toml
~~~

启动Frpc、更新、强制重装（Frps 同理）
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
sudo ./frpc.sh reinstall     # 强制重新安装（Frps 不支持）
~~~

快捷命令（Frps 同理）
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
