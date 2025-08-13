<h1>Frps服务端一键配置脚本，最新版本：0.63.0</h1>
<p><em>Frp 是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 tcp, http, https 等协议类型，并且 web 服务支持根据域名进行路由转发。</em></p>
<ul>
  <li>详情：fatedier (<a href="https://github.com/fatedier/frp" target="_blank">https://github.com/fatedier/frp</a>)</li>
  <li>此脚本原作者：clangcn (<a href="https://github.com/clangcn/onekey-install-shell" target="_blank">https://github.com/clangcn/onekey-install-shell</a>)</li>
</ul>
<h2><a id="user-content-frps-onekey-install-shell" aria-hidden="true" href="https://github.com/lj47312/frp#frp"></a>Frp</h2>
<h3><a id="user-content-install安装" aria-hidden="true" href="https://github.com/lj47312/frp#install安装"></a>Install（安装）</h3>
<h4><a id="user-content-github" aria-hidden="true" href="https://github.com/lj47312/frp#github"></a>Github</h4>
<div>
  <pre>wget --no-check-certificate https://github.itzmx.com/lj47312/frp/master/frps.sh -O ./frps.sh &amp;&amp; chmod 700 ./frps.sh &amp;&amp; ./frps.sh install</pre>
</div>
<h4><a id="user-content-aliyun" aria-hidden="true" href="https://github.com/lj47312/frp#aliyun"></a>Gitee</h4>
<div>
  <pre>wget --no-check-certificate https://gitee.com/lj47312/frp/raw/main/frps.sh -O ./frps.sh &amp;&amp; chmod 700 ./frps.sh &amp;&amp; ./frps.sh install</pre>
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
