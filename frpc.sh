#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# fonts color

# variable
WORK_PATH=$(dirname $(readlink -f $0))
FRP_NAME=frpc
FRP_VERSION=0.61.2
FRP_PATH=/usr/local/frpc
PROXY_URL="https://ghfast.top/"

# 新增管理功能函数
manage_frpc() {
case "$1" in
start)
    systemctl start ${FRP_NAME} && echo "Service started" || echo "Start failed"
    ;;
restart)
    systemctl restart ${FRP_NAME} && echo "Service restarted" || echo "Restart failed"
    ;;
stop)
    systemctl stop ${FRP_NAME} && echo "Service stopped" || echo "Stop failed"
    ;;
status)
    systemctl status ${FRP_NAME} --no-pager
    ;;
version)
      ${FRP_PATH}/${FRP_NAME} -v
      ;;
update)
    NEW_VER=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d'"' -f4 | sed 's/v//')
    if [ "$NEW_VER" != "$FRP_VERSION" ];then
        sed -i "s/FRP_VERSION=.*/FRP_VERSION=${NEW_VER}/" $0
        echo "Updating to v${NEW_VER}..."
        $0 reinstall
    else
        echo "已经是最新版本"
    fi
    ;;
reinstall)
    systemctl stop ${FRP_NAME}
    rm -rf ${FRP_PATH}/${FRP_NAME}
    rm -rf ${FRP_PATH}/${FRP_NAME}.toml
    rm -rf /lib/systemd/system/frpc.service
    $0 install
    ;;
*)
    sudo ./frpc.sh
    ;;
esac
}

# 执行入口
if [ $# -gt 0 ]; then
  manage_frpc "$1"
  exit 0
fi

# check frpc
if [ -f "/usr/local/frpc/${FRP_NAME}" ] || [ -f "/usr/local/frpc/${FRP_NAME}.toml" ] || [ -f "/lib/systemd/system/${FRP_NAME}.service" ];then
    echo -e "${Green}=========================================================================${Font}"
    echo -e "${RedBG}当前已退出脚本.${Font}"
    echo -e "${Green}检查到服务器已安装${Font} ${Red}${FRP_NAME}${Font}"
    echo -e "${Green}更新${FRP_NAME}版本:${Font}"
    echo -e "${Red}sudo ./frpc.sh update${Font}"
    echo -e "${Green}=========================================================================${Font}"
    exit 0
fi

while ! test -z "$(ps -A | grep -w ${FRP_NAME})"; do
    FRPCPID=$(ps -A | grep -w ${FRP_NAME} | awk 'NR==1 {print $1}')
    kill -9 $FRPCPID
done

# check pkg
if type apt-get >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        apt-get install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        apt-get install curl -y
    fi
fi

if type yum >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        yum install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        yum install curl -y
    fi
fi

# check network
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")
PROXY_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "${PROXY_URL}")

# check arch
if [ $(uname -m) = "x86_64" ]; then
    PLATFORM=amd64
elif [ $(uname -m) = "aarch64" ]; then
    PLATFORM=arm64
elif [ $(uname -m) = "armv7" ]; then
    PLATFORM=arm
elif [ $(uname -m) = "armv7l" ]; then
    PLATFORM=arm
elif [ $(uname -m) = "armhf" ]; then
    PLATFORM=arm
fi

FILE_NAME=frp_${FRP_VERSION}_linux_${PLATFORM}

# download
if [ $GOOGLE_HTTP_CODE == "200" ]; then
    wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
else
    if [ $PROXY_HTTP_CODE == "200" ]; then
        wget -P ${WORK_PATH} ${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
    else
        echo -e "${Red}检测 GitHub Proxy 代理失效 开始使用官方地址下载${Font}"
        wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
    fi
fi
tar -zxvf ${FILE_NAME}.tar.gz

mkdir -p ${FRP_PATH}
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}

# configure frpc.toml
cat >${FRP_PATH}/${FRP_NAME}.toml <<EOF
serverAddr = "127.0.0.1"
serverPort = 7000
auth.method = "token"
auth.token = "afrp.net"

[[proxies]]
name = "000001.http"
type = "http"
localIP = "127.0.0.1"
localPort = 8000
subdomain = "www"
customDomains = ["*"]

[[proxies]]
name = "000002.https"
type = "https"
localIP = "127.0.0.1"
localPort = 8001
subdomain = "www"
customDomains = ["*"]

[[proxies]]
name = "000003.http"
type = "http"
localIP = "127.0.0.1"
localPort = 8000
subdomain = "www"
customDomains = ["*.afrp.net"]

[[proxies]]
name = "000004.https"
type = "https"
localIP = "127.0.0.1"
localPort = 8001
subdomain = "www"
customDomains = ["*.afrp.net"]
EOF

# configure systemd
cat >/lib/systemd/system/${FRP_NAME}.service <<EOF
[Unit]
Description=Frpc Server Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frpc/${FRP_NAME} -c /usr/local/frpc/${FRP_NAME}.toml

[Install]
WantedBy=multi-user.target
EOF

# finish install
systemctl daemon-reload
sudo systemctl start ${FRP_NAME}
sudo systemctl enable ${FRP_NAME}

# 下载 frpc.init
wget -N https://raw.githubusercontent.com/KuwiNet/frpc/master/frpc.init
mv frpc.init ./frpc.ini
chmod 755 ./frpc.ini

echo -e "${Green}====================================================================${Font}"
echo -e "${Green}安装成功,请先修改 ${FRP_NAME}.toml 文件,确保格式及配置正确无误!${Font}"
echo -e "${Red}vi /usr/local/frpc/${FRP_NAME}.toml${Font}"
echo -e "${Green}修改完毕后执行以下命令重启服务:${Font}"
echo -e "${Red}sudo systemctl restart ${FRP_NAME}${Font}"
echo -e "${Green}Ubuntu/Debian安装后创建快捷命令${Font}"
echo -e "${Red}sudo update-rc.d -f frpc defaults${Font}"
echo -e "${Green}CentOS/Redhat安装后创建快捷命令${Font}"
echo -e "${Red}chkconfig --add frpc${Font}"
echo -e "${Green}快捷命令${Font}"
echo -e "${Red}frpc start     # 启动服务${Font}"
echo -e "${Red}frpc restart   # 重启服务${Font}"
echo -e "${Red}frpc stop      # 停止服务${Font}"
echo -e "${Red}frpc status    # 查看状态${Font}"
echo -e "${Red}frpc version   # 查看版本${Font}"
echo -e "${Red}frpc config    # 查看配置${Font}"
echo -e "${Green}版本更新${Font}"
echo -e "${Red}sudo ./frpc.sh update     # 自动检测更新${Font}"
echo -e "${Red}sudo ./frpc.sh reinstall  # 强制重新安装${Font}"
echo -e "${Green}====================================================================${Font}"
