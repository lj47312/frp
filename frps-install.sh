#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
###export###
export PATH
export FRPS_VER=0.63.0
export FRPS_INIT="https://raw.githubusercontent.com/lj47312/frp/main/frps.init"
export aliyun_download_url="https://gitee.com/lj47312/frp/releases/download"
export github_download_url="https://github.com/fatedier/frp/releases/download"
#======================================================================
#   支持系统:  CentOS Debian 或 Ubuntu (32bit/64bit)
#   说明:  这个脚本是自动在Linux上安装frps服务
#   原作者 : Clang
#   汉化修复者 : lj47312
#======================================================================
program_name="frps"
version="210505"
str_program_dir="/usr/local/${program_name}"
program_init="/etc/init.d/${program_name}"
program_config_file="frps.ini"
ver_file="/tmp/.frp_ver.sh"
str_install_shell="https://raw.githubusercontent.com/lj47312/frp/main/frps-install.sh"
shell_update(){
    fun_clangcn "clear"
    echo "检查shell脚本的更新..."
    remote_shell_version=`wget  -qO- ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${remote_shell_version} ]; then
        if [[ "${version}" != "${remote_shell_version}" ]];then
            echo -e "${COLOR_GREEN}找到新版本，立即更新!!!${COLOR_END}"
            echo
            echo -n "外壳更新 ..."
            if ! wget -N  -qO $0 ${str_install_shell}; then
                echo -e " [${COLOR_RED}失败${COLOR_END}]"
                echo
                exit 1
            else
                chmod +x install-frps.sh
                echo -e " [${COLOR_GREEN}成功${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}请重新运行${COLOR_END} ${COLOR_PINK}$0 ${clang_action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}
fun_clangcn(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+------------------------------------------------------------+"
    echo "|   frps用于Linux服务器, 原作者 Clang ，汉化修复者 lj47312   |" 
    echo "|      这个脚本是自动在Linux上安装frps服务                   |"
    echo "+------------------------------------------------------------+"
    echo ""
}
fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
# 检查用户是否为root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_clangcn
        echo "错误:此脚本必须以root身份运行!" 1>&2
        exit 1
    fi
}
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
# 检查OS系统
checkos(){
    if  grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "不支持当前操作系统，请重新安装操作系统并重试!"
        exit 1
    fi
}
# 获取版本
getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}
# CentOS版本
centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}
# 检查操作系统32位或64位
check_os_bit(){
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
    fi
}
check_centosversion(){
if centosversion 5; then
    echo "不支持 CentOS 5.x, 请换成 CentOS 6,7 或 Debian 或 Ubuntu 再试一次."
    exit 1
fi
}
# 禁用selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}
pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]];then
        echo -e "${COLOR_GREEN} 安装支持包...${COLOR_END}"
        if [ "${OS}" == 'CentOS' ]; then
            yum install -y wget psmisc net-tools
        else
            apt-get -y update && apt-get -y install wget psmisc net-tools
        fi
    fi
}
# 随机密码
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
}
fun_getServer(){
    def_server_url="github"
    echo ""
    echo -e "请选择 ${program_name} 下载 url:"
    echo -e "[1].aliyun "
    echo -e "[2].github (默认)"
    read -e -p "输入您的选择 (1, 2 或退出. 默认 [${def_server_url}]): " set_server_url
    [ -z "${set_server_url}" ] && set_server_url="${def_server_url}"
    case "${set_server_url}" in
        1|[Aa][Ll][Ii][Yy][Uu][Nn])
            program_download_url=${aliyun_download_url}
            ;;
        2|[Gg][Ii][Tt][Hh][Uu][Bb])
            program_download_url=${github_download_url}
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            program_download_url=${aliyun_download_url}
            ;;
    esac
    echo    "-----------------------------------"
    echo -e "       您选择: ${COLOR_YELOW}${set_server_url}${COLOR_END}    "
    echo    "-----------------------------------"
}
fun_getVer(){
    echo -e "正在加载网络版本 ${program_name}, 请等待..."
    program_latest_filename="frp_${FRPS_VER}_linux_${ARCHS}.tar.gz"
    program_latest_file_url="${program_download_url}/v${FRPS_VER}/${program_latest_filename}"
    if [ -z "${program_latest_filename}" ]; then
        echo -e "${COLOR_RED}加载网络版本失败!!!${COLOR_END}"
    else
        echo -e "${program_name} 最新版本文件 ${COLOR_GREEN}${program_latest_filename}${COLOR_END}"
    fi
}
fun_download_file(){
    # 下载
    if [ ! -s ${str_program_dir}/${program_name} ]; then
        rm -fr ${program_latest_filename} frp_${FRPS_VER}_linux_${ARCHS}
        if ! wget  -q ${program_latest_file_url} -O ${program_latest_filename}; then
            echo -e " ${COLOR_RED}失败${COLOR_END}"
            exit 1
        fi
        tar xzf ${program_latest_filename}
        mv frp_${FRPS_VER}_linux_${ARCHS}/frps ${str_program_dir}/${program_name}
        rm -fr ${program_latest_filename} frp_${FRPS_VER}_linux_${ARCHS}
    fi
    chown root:root -R ${str_program_dir}
    if [ -s ${str_program_dir}/${program_name} ]; then
        [ ! -x ${str_program_dir}/${program_name} ] && chmod 755 ${str_program_dir}/${program_name}
    else
        echo -e " ${COLOR_RED}失败${COLOR_END}"
        exit 1
    fi
}
function __readINI() {
 INIFILE=$1; SECTION=$2; ITEM=$3
 _readIni=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE`
echo ${_readIni}
}
# 检查端口
fun_check_port(){
    port_flag=""
    strCheckPort=""
    input_port=""
    port_flag="$1"
    strCheckPort="$2"
    if [ ${strCheckPort} -ge 1 ] && [ ${strCheckPort} -le 65535 ]; then
        checkServerPort=`netstat -ntulp | grep "\b:${strCheckPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}错误:${COLOR_END} 端口 ${COLOR_GREEN}${strCheckPort}${COLOR_END} is ${COLOR_PINK}used${COLOR_END},查看相关端口:"
            netstat -ntulp | grep "\b:${strCheckPort}\b"
            fun_input_${port_flag}_port
        else
            input_port="${strCheckPort}"
        fi
    else
        echo "输入错误！请输入正确的端口号."
        fun_input_${port_flag}_port
    fi
}
fun_check_number(){
    num_flag=""
    strMaxNum=""
    strCheckNum=""
    input_number=""
    num_flag="$1"
    strMaxNum="$2"
    strCheckNum="$3"
    if [ ${strCheckNum} -ge 1 ] && [ ${strCheckNum} -le ${strMaxNum} ]; then
        input_number="${strCheckNum}"
    else
        echo "输入错误！请输入正确的端口号."
        fun_input_${num_flag}
    fi
}
# 输入配置数据
fun_input_bind_port(){
    def_server_port="44444"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}bind_port${COLOR_END} [1-65535]"
    read -e -p "(默认服务端口: ${def_server_port}):" serverport
    [ -z "${serverport}" ] && serverport="${def_server_port}"
    fun_check_port "bind" "${serverport}"
}
fun_input_bind_udp_port(){
    def_bind_udp_port="44445"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}bind_udp_port${COLOR_END} [1-65535]"
    read -e -p "(默认UDP服务端口 : ${def_bind_udp_port}):" input_bind_udp_port
    [ -z "${input_bind_udp_port}" ] && input_bind_udp_port="${def_bind_udp_port}"
    fun_check_port "bind_udp" "${input_bind_udp_port}"
}
fun_input_dashboard_port(){
    def_dashboard_port="22222"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}dashboard_port${COLOR_END} [1-65535]"
    read -e -p "(默认 : ${def_dashboard_port}):" input_dashboard_port
    [ -z "${input_dashboard_port}" ] && input_dashboard_port="${def_dashboard_port}"
    fun_check_port "dashboard" "${input_dashboard_port}"
}
fun_input_vhost_http_port(){
    def_vhost_http_port="47301"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}vhost_http_port${COLOR_END} [1-65535]"
    read -e -p "(默认 : ${def_vhost_http_port}):" input_vhost_http_port
    [ -z "${input_vhost_http_port}" ] && input_vhost_http_port="${def_vhost_http_port}"
    fun_check_port "vhost_http" "${input_vhost_http_port}"
}
fun_input_vhost_https_port(){
    def_vhost_https_port="47302"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}vhost_https_port${COLOR_END} [1-65535]"
    read -e -p "(默认 : ${def_vhost_https_port}):" input_vhost_https_port
    [ -z "${input_vhost_https_port}" ] && input_vhost_https_port="${def_vhost_https_port}"
    fun_check_port "vhost_https" "${input_vhost_https_port}"
}
fun_input_log_max_days(){
    def_max_days="30" 
    def_log_max_days="1"
    echo ""
    echo -e "请输入 ${program_name} ${COLOR_GREEN}log_max_days${COLOR_END} [1-${def_max_days}]"
    read -e -p "(默认 : ${def_log_max_days} day):" input_log_max_days
    [ -z "${input_log_max_days}" ] && input_log_max_days="${def_log_max_days}"
    fun_check_number "log_max_days" "${def_max_days}" "${input_log_max_days}"
}
fun_input_max_pool_count(){
    def_max_pool="200"
    def_max_pool_count="50"
    echo ""
    echo -e "请输入 ${program_name} ${COLOR_GREEN}max_pool_count${COLOR_END} [1-${def_max_pool}]"
    read -e -p "(默认 : ${def_max_pool_count}):" input_max_pool_count
    [ -z "${input_max_pool_count}" ] && input_max_pool_count="${def_max_pool_count}"
    fun_check_number "max_pool_count" "${def_max_pool}" "${input_max_pool_count}"
}
fun_input_dashboard_user(){
    def_dashboard_user="lj47312"
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}dashboard_user${COLOR_END}"
    read -e -p "(默认 : ${def_dashboard_user}):" input_dashboard_user
    [ -z "${input_dashboard_user}" ] && input_dashboard_user="${def_dashboard_user}"
}
fun_input_dashboard_pwd(){
    def_dashboard_pwd=`fun_randstr 8`
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}dashboard_pwd${COLOR_END}"
    read -e -p "(默认 : ${def_dashboard_pwd}):" input_dashboard_pwd
    [ -z "${input_dashboard_pwd}" ] && input_dashboard_pwd="${def_dashboard_pwd}"
}
fun_input_token(){
    def_token=`fun_randstr 16`
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}token${COLOR_END}"
    read -e -p "(默认 : ${def_token}):" input_token
    [ -z "${input_token}" ] && input_token="${def_token}"
}
fun_input_subdomain_host(){
    def_subdomain_host=${defIP}
    echo ""
    echo -n -e "请输入 ${program_name} ${COLOR_GREEN}subdomain_host${COLOR_END}"
    read -e -p "(默认 : ${def_subdomain_host}):" input_subdomain_host
    [ -z "${input_subdomain_host}" ] && input_subdomain_host="${def_subdomain_host}"
}

pre_install_clang(){
    fun_clangcn
    echo -e "检查您的服务器设置,请稍等..."
    disable_selinux
    if [ -s ${str_program_dir}/${program_name} ] && [ -s ${program_init} ]; then
        echo "${program_name} 已安装!"
    else
        clear
        fun_clangcn
        fun_getServer
        fun_getVer
        echo -e "加载服务器IP, 请稍等..."
        defIP=$(wget -qO- ip.clang.cn | sed -r 's/\r//')
        echo -e "服务器IP:${COLOR_GREEN}${defIP}${COLOR_END}"
        echo -e "————————————————————————————————————————————"
        echo -e "     ${COLOR_RED}请输入服务器设置:${COLOR_END}"
        echo -e "————————————————————————————————————————————"
        fun_input_bind_port
        [ -n "${input_port}" ] && set_bind_port="${input_port}"
        echo -e "${program_name} bind_port: ${COLOR_YELOW}${set_bind_port}${COLOR_END}"
        echo -e ""
 		fun_input_bind_udp_port
        [ -n "${input_port}" ] && set_bind_udp_port="${input_port}"
        echo -e "${program_name} bind_udp_port: ${COLOR_YELOW}${set_bind_udp_port}${COLOR_END}"
        echo -e ""
        fun_input_vhost_http_port
        [ -n "${input_port}" ] && set_vhost_http_port="${input_port}"
        echo -e "${program_name} vhost_http_port: ${COLOR_YELOW}${set_vhost_http_port}${COLOR_END}"
        echo -e ""
        fun_input_vhost_https_port
        [ -n "${input_port}" ] && set_vhost_https_port="${input_port}"
        echo -e "${program_name} vhost_https_port: ${COLOR_YELOW}${set_vhost_https_port}${COLOR_END}"
        echo -e ""
        fun_input_dashboard_port
        [ -n "${input_port}" ] && set_dashboard_port="${input_port}"
        echo -e "${program_name} dashboard_port: ${COLOR_YELOW}${set_dashboard_port}${COLOR_END}"
        echo -e ""
        fun_input_dashboard_user
        [ -n "${input_dashboard_user}" ] && set_dashboard_user="${input_dashboard_user}"
        echo -e "${program_name} dashboard_user: ${COLOR_YELOW}${set_dashboard_user}${COLOR_END}"
        echo -e ""
        fun_input_dashboard_pwd
        [ -n "${input_dashboard_pwd}" ] && set_dashboard_pwd="${input_dashboard_pwd}"
        echo -e "${program_name} dashboard_pwd: ${COLOR_YELOW}${set_dashboard_pwd}${COLOR_END}"
        echo -e ""
        fun_input_token
        [ -n "${input_token}" ] && set_token="${input_token}"
        echo -e "${program_name} token: ${COLOR_YELOW}${set_token}${COLOR_END}"
        echo -e ""
        fun_input_subdomain_host
        [ -n "${input_subdomain_host}" ] && set_subdomain_host="${input_subdomain_host}"
        echo -e "${program_name} subdomain_host: ${COLOR_YELOW}${set_subdomain_host}${COLOR_END}"
        echo -e ""
        fun_input_max_pool_count
        [ -n "${input_number}" ] && set_max_pool_count="${input_number}"
        echo -e "${program_name} max_pool_count: ${COLOR_YELOW}${set_max_pool_count}${COLOR_END}"
        echo -e ""
        echo -e "请选择 ${COLOR_GREEN}log_level${COLOR_END}"
        echo    "1: info"
        echo    "2: warn"
        echo    "3: error (默认)"
        echo    "4: debug"    
        echo    "-------------------------"
        read -e -p "输入您的选择 (1, 2, 3, 4 或退出. 默认 [3]): " str_log_level
        case "${str_log_level}" in
            1|[Ii][Nn][Ff][Oo])
                str_log_level="info"
                ;;
            2|[Ww][Aa][Rr][Nn])
                str_log_level="warn"
                ;;
            3|[Ee][Rr][Rr][Oo][Rr])
                str_log_level="error"
                ;;
            4|[Dd][Ee][Bb][Uu][Gg])
                str_log_level="debug"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_level="error"
                ;;
        esac
        echo -e "log_level: ${COLOR_YELOW}${str_log_level}${COLOR_END}"
        echo -e ""
        fun_input_log_max_days
        [ -n "${input_number}" ] && set_log_max_days="${input_number}"
        echo -e "${program_name} log_max_days: ${COLOR_YELOW}${set_log_max_days}${COLOR_END}"
        echo -e ""
        echo -e "请选择 ${COLOR_GREEN}log_file${COLOR_END}"
        echo    "1: 开启 (默认)"
        echo    "2: 关闭"
        echo "-------------------------"
        read -e -p "输入您的选择 (1, 2 或退出. 默认 [1]): " str_log_file
        case "${str_log_file}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                str_log_file="./frps.log"
                str_log_file_flag="enable"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                str_log_file="/dev/null"
                str_log_file_flag="disable"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_file="./frps.log"
                str_log_file_flag="enable"
                ;;
        esac
        echo -e "log_file: ${COLOR_YELOW}${str_log_file_flag}${COLOR_END}"
        echo -e ""
        echo -e "请选择 ${COLOR_GREEN}tcp_mux${COLOR_END}"
        echo    "1: 开启 (默认)"
        echo    "2: 关闭"
        echo "-------------------------"         
        read -e -p "输入您的选择 (1, 2 或退出. 默认 [1]): " str_tcp_mux
        case "${str_tcp_mux}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                set_tcp_mux="true"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                set_tcp_mux="false"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                set_tcp_mux="true"
                ;;
        esac
        echo -e "tcp_mux: ${COLOR_YELOW}${set_tcp_mux}${COLOR_END}"
        echo -e ""
        echo -e "请选择 ${COLOR_GREEN}kcp support${COLOR_END}"
        echo    "1: 开启 (默认)"
        echo    "2: 关闭"
        echo "-------------------------"  
        read -e -p "输入您的选择 (1, 2 或退出. 默认 [1]): " str_kcp
        case "${str_kcp}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                set_kcp="true"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                set_kcp="false"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                set_kcp="true"
                ;;
        esac
        echo -e "kcp支持: ${COLOR_YELOW}${set_kcp}${COLOR_END}"
        echo -e ""

        echo "============== 检查输入 =============="
        echo -e "You Server IP      : ${COLOR_GREEN}${defIP}${COLOR_END}"
        echo -e "Bind port          : ${COLOR_GREEN}${set_bind_port}${COLOR_END}"
        echo -e "Bind UDP port      : ${COLOR_GREEN}${set_bind_udp_port}${COLOR_END}"        
        echo -e "kcp support        : ${COLOR_GREEN}${set_kcp}${COLOR_END}"
        echo -e "vhost http port    : ${COLOR_GREEN}${set_vhost_http_port}${COLOR_END}"
        echo -e "vhost https port   : ${COLOR_GREEN}${set_vhost_https_port}${COLOR_END}"
        echo -e "Dashboard port     : ${COLOR_GREEN}${set_dashboard_port}${COLOR_END}"
        echo -e "Dashboard user     : ${COLOR_GREEN}${set_dashboard_user}${COLOR_END}"
        echo -e "Dashboard password : ${COLOR_GREEN}${set_dashboard_pwd}${COLOR_END}"
        echo -e "token              : ${COLOR_GREEN}${set_token}${COLOR_END}"
        echo -e "subdomain_host     : ${COLOR_GREEN}${set_subdomain_host}${COLOR_END}"
        echo -e "tcp_mux            : ${COLOR_GREEN}${set_tcp_mux}${COLOR_END}"
        echo -e "Max Pool count     : ${COLOR_GREEN}${set_max_pool_count}${COLOR_END}"
        echo -e "Log level          : ${COLOR_GREEN}${str_log_level}${COLOR_END}"
        echo -e "Log max days       : ${COLOR_GREEN}${set_log_max_days}${COLOR_END}"
        echo -e "Log file           : ${COLOR_GREEN}${str_log_file_flag}${COLOR_END}"
        echo "=============================================="
        echo ""
        echo "按任意键开始安装...或按Ctrl+c取消安装并退出"

        char=`get_char`
        install_program_server_clang
    fi
}
# ====== install server ======
install_program_server_clang(){
    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo "${program_name} install path:$PWD"

    echo -n "config file for ${program_name} ..."
# Config file
if [[ "${set_kcp}" == "false" ]]; then
cat > ${str_program_dir}/${program_config_file}<<-EOF
# [common] 完整的配置参数
[common]
# 必须包含IPv6的文字地址或主机名。
# 方括号内，如 "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
bind_addr = 0.0.0.0
bind_port = ${set_bind_port}
# UDP穿透服务器的服务端口定义
bind_udp_port = ${set_bind_udp_port}
# KCP用来给UDP端口加速的服务端口，可以和上面的UDP服务端口bind_port相同
# 如果没有设置KCP加速，请注释此行
#kcp_bind_port = ${set_bind_port}
# 只有当dashboard_port端口被设置时，后台查看面板才可用
dashboard_port = ${set_dashboard_port}
# 后台查看面板有用的目录(仅用于调试模式)
dashboard_user = ${set_dashboard_user}
dashboard_pwd = ${set_dashboard_pwd}
# assets_dir = ./static
vhost_http_port = ${set_vhost_http_port}
vhost_https_port = ${set_vhost_https_port}
# 制台或真实的logFile路径，例如./frps.log
log_file = ${str_log_file}
# 跟踪、调试、信息、警告、错误
log_level = ${str_log_level}
log_max_days = ${set_log_max_days}
# 身份验证令牌
token = ${set_token}
# 如果子域名主机不是空的，则可以在frpc的配置文件中键入HTTP或HTTPS时设置子域。
subdomain_host = ${set_subdomain_host}
# 只允许frpc使用指定的端口，如果您不设置任何设置，则不会有任何限制。
#allow_ports = 1-65535
# 每个客户端最大连接数，如超过最大连接数，将不连接
max_pool_count = ${set_max_pool_count}
# 如果使用TCP流复用，则默认为true
tcp_mux = ${set_tcp_mux}
EOF
else
cat > ${str_program_dir}/${program_config_file}<<-EOF
# [common] 完整的配置参数
[common]
# 必须包含IPv6的文字地址或主机名。
# 方括号内，如 "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
bind_addr = 0.0.0.0
bind_port = ${set_bind_port}
# UDP穿透服务器的服务端口定义
bind_udp_port = ${set_bind_udp_port}
# KCP用来给UDP端口加速的服务端口，可以和上面的UDP服务端口bind_port相同
# 如果没有设置KCP加速，请注释此行
kcp_bind_port = ${set_bind_port}
# 只有当dashboard_port端口被设置时，后台查看面板才可用
dashboard_port = ${set_dashboard_port}
# 后台查看面板有用的目录(仅用于调试模式)
dashboard_user = ${set_dashboard_user}
dashboard_pwd = ${set_dashboard_pwd}
# assets_dir = ./static
vhost_http_port = ${set_vhost_http_port}
vhost_https_port = ${set_vhost_https_port}
# console or real logFile path like ./frps.log
log_file = ${str_log_file}
# 跟踪、调试、信息、警告、错误
log_level = ${str_log_level}
log_max_days = ${set_log_max_days}
# 身份验证令牌
token = ${set_token}
# 如果子域名主机不是空的，则可以在frpc的配置文件中键入HTTP或HTTPS时设置子域。
subdomain_host = ${set_subdomain_host}
# 只允许frpc使用指定的端口，如果您不设置任何设置，则不会有任何限制。
#allow_ports = 1-65535
# 每个客户端最大连接数，如超过最大连接数，将不连接
max_pool_count = ${set_max_pool_count}
# 如果使用TCP流复用，则默认为true
tcp_mux = ${set_tcp_mux}
EOF
fi
    echo " 完成"

    echo -n "下载 ${program_name} ..."
    rm -f ${str_program_dir}/${program_name} ${program_init}
    fun_download_file
    echo " 完成"
    echo -n "下载 ${program_init}..."
    if [ ! -s ${program_init} ]; then
        if ! wget  -q ${FRPS_INIT} -O ${program_init}; then
            echo -e " ${COLOR_RED}失败${COLOR_END}"
            exit 1
        fi
    fi
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    echo " 完成"

    echo -n "设置 ${program_name} 启动..."
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x ${program_init}
        chkconfig --add ${program_name}
    else
        chmod +x ${program_init}
        update-rc.d -f ${program_name} defaults
    fi
    echo " 完成"
    [ -s ${program_init} ] && ln -s ${program_init} /usr/bin/${program_name}
    ${program_init} start
    fun_clangcn
    #install successfully
    echo ""
    echo "祝贺 你, ${program_name} 安装完成!"
    echo "================================================"
    echo -e "You Server IP      : ${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Bind port          : ${COLOR_GREEN}${set_bind_port}${COLOR_END}"
    echo -e "Bind UDP port      : ${COLOR_GREEN}${set_bind_udp_port}${COLOR_END}"
    echo -e "KCP support        : ${COLOR_GREEN}${set_kcp}${COLOR_END}"
    echo -e "vhost http port    : ${COLOR_GREEN}${set_vhost_http_port}${COLOR_END}"
    echo -e "vhost https port   : ${COLOR_GREEN}${set_vhost_https_port}${COLOR_END}"
    echo -e "Dashboard port     : ${COLOR_GREEN}${set_dashboard_port}${COLOR_END}"
    echo -e "token              : ${COLOR_GREEN}${set_token}${COLOR_END}"
    echo -e "subdomain_host     : ${COLOR_GREEN}${set_subdomain_host}${COLOR_END}"
    echo -e "tcp_mux            : ${COLOR_GREEN}${set_tcp_mux}${COLOR_END}"
    echo -e "Max Pool count     : ${COLOR_GREEN}${set_max_pool_count}${COLOR_END}"
    echo -e "Log level          : ${COLOR_GREEN}${str_log_level}${COLOR_END}"
    echo -e "Log max days       : ${COLOR_GREEN}${set_log_max_days}${COLOR_END}"
    echo -e "Log file           : ${COLOR_GREEN}${str_log_file_flag}${COLOR_END}"
    echo "================================================"
    echo -e "${program_name} Dashboard     : ${COLOR_GREEN}http://${set_subdomain_host}:${set_dashboard_port}/${COLOR_END}"
    echo -e "Dashboard user     : ${COLOR_GREEN}${set_dashboard_user}${COLOR_END}"
    echo -e "Dashboard password : ${COLOR_GREEN}${set_dashboard_pwd}${COLOR_END}"
    echo "================================================"
    echo ""
    echo -e "${program_name} status manage : ${COLOR_PINKBACK_WHITEFONT}${program_name}${COLOR_END} {${COLOR_GREEN}start|stop|restart|status|config|version${COLOR_END}}"
    echo -e "Example:"
    echo -e "启动: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}start${COLOR_END}"
    echo -e "停止: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}stop${COLOR_END}"
    echo -e "重启: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}restart${COLOR_END}"
    exit 0
}
############################### configure ##################################
configure_program_server_clang(){
    if [ -s ${str_program_dir}/${program_config_file} ]; then
        vi ${str_program_dir}/${program_config_file}
    else
        echo "${program_name} 找不到配置文件!"
        exit 1
    fi
}
############################### 卸载 ##################################
uninstall_program_server_clang(){
    fun_clangcn
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== 卸载 ${program_name} =============="
        str_uninstall="n"
        echo -n -e "${COLOR_YELOW}你想卸载?${COLOR_END}"
        read -e -p "[Y/N]:" str_uninstall
        case "${str_uninstall}" in
        [yY]|[yY][eE][sS])
        echo ""
        echo "您选择 [Yes], 按任意键继续."
        str_uninstall="y"
        char=`get_char`
        ;;
        *)
        echo ""
        str_uninstall="n"
        esac
        if [ "${str_uninstall}" == 'n' ]; then
            echo "您选择 [No],脚本退出!"
        else
            checkos
            ${program_init} stop
            if [ "${OS}" == 'CentOS' ]; then
                chkconfig --del ${program_name}
            else
                update-rc.d -f ${program_name} remove
            fi
            rm -f ${program_init} /var/run/${program_name}.pid /usr/bin/${program_name}
            rm -fr ${str_program_dir}
            echo "${program_name} 卸载成功!"
        fi
    else
        echo "${program_name} 不安装!"
    fi
    exit 0
}
############################### update ##################################
update_config_clang(){
    if [ ! -r "${str_program_dir}/${program_config_file}" ]; then
        echo "配置文件 ${str_program_dir}/${program_config_file} 找不到."
    else
        search_dashboard_user=`grep "dashboard_user" ${str_program_dir}/${program_config_file}`
        search_dashboard_pwd=`grep "dashboard_pwd" ${str_program_dir}/${program_config_file}`
        search_kcp_bind_port=`grep "kcp_bind_port" ${str_program_dir}/${program_config_file}`
        search_tcp_mux=`grep "tcp_mux" ${str_program_dir}/${program_config_file}`
        search_token=`grep "privilege_token" ${str_program_dir}/${program_config_file}`
        search_allow_ports=`grep "privilege_allow_ports" ${str_program_dir}/${program_config_file}`
        if [ -z "${search_dashboard_user}" ] || [ -z "${search_dashboard_pwd}" ] || [ -z "${search_kcp_bind_port}" ] || [ -z "${search_tcp_mux}" ] || [ ! -z "${search_token}" ] || [ ! -z "${search_allow_ports}" ];then
            echo -e "${COLOR_GREEN}需要更新配置文件，现在设置:${COLOR_END}"
            echo ""
            if [ ! -z "${search_token}" ];then
                sed -i "s/privilege_token/token/" ${str_program_dir}/${program_config_file}
            fi
            if [ -z "${search_dashboard_user}" ] && [ -z "${search_dashboard_pwd}" ];then
                def_dashboard_user_update="lj47312"
                read -e -p "请输入 dashboard_user (默认: ${def_dashboard_user_update}):" set_dashboard_user_update
                [ -z "${set_dashboard_user_update}" ] && set_dashboard_user_update="${def_dashboard_user_update}"
                echo "${program_name} dashboard_user: ${set_dashboard_user_update}"
                echo ""
                def_dashboard_pwd_update=`fun_randstr 8`
                read -e -p "请输入 dashboard_pwd (默认: ${def_dashboard_pwd_update}):" set_dashboard_pwd_update
                [ -z "${set_dashboard_pwd_update}" ] && set_dashboard_pwd_update="${def_dashboard_pwd_update}"
                echo "${program_name} dashboard_pwd: ${set_dashboard_pwd_update}"
                echo ""
                sed -i "/dashboard_port =.*/a\dashboard_user = ${set_dashboard_user_update}\ndashboard_pwd = ${set_dashboard_pwd_update}\n" ${str_program_dir}/${program_config_file}
            fi
            if [ -z "${search_kcp_bind_port}" ];then 
                echo -e "${COLOR_GREEN}请选择kcp支持${COLOR_END}"
                echo "1: 开启 (默认)"
                echo "2: 关闭"
                echo "-------------------------"  
                read -e -p "输入您的选择 (1, 2 或退出. 默认 [1]): " str_kcp
                case "${str_kcp}" in
                    1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                        set_kcp="true"
                        ;;
                    0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                        set_kcp="false"
                        ;;
                    [eE][xX][iI][tT])
                        exit 1
                        ;;
                    *)
                        set_kcp="true"
                        ;;
                esac
                echo "kcp支持: ${set_kcp}"
                def_kcp_bind_port=( $( __readINI ${str_program_dir}/${program_config_file} common bind_port ) )
                if [[ "${set_kcp}" == "false" ]]; then
                    sed -i "/^bind_port =.*/a\# 用于KCP协议的UDP端口, 它可以和 'bind_port'\n# 如果未设置, kcp是关闭的在 frps\n#kcp_bind_port = ${def_kcp_bind_port}\n" ${str_program_dir}/${program_config_file}
                else
                    sed -i "/^bind_port =.*/a\# 用于KCP协议的UDP端口, 它可以和 'bind_port'\n# 如果未设置, kcp是关闭的在 frps\nkcp_bind_port = ${def_kcp_bind_port}\n" ${str_program_dir}/${program_config_file}
                fi
            fi
            if [ -z "${search_tcp_mux}" ];then
                echo "# 请选择 tcp_mux "
                echo "1: 开启 (默认)"
                echo "2: 关闭"
                echo "-------------------------"  
                read -e -p "输入您的选择 (1, 2 或退出. 默认 [1]): " str_tcp_mux
                case "${str_tcp_mux}" in
                    1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                        set_tcp_mux="true"
                        ;;
                    0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                        set_tcp_mux="false"
                        ;;
                    [eE][xX][iI][tT])
                        exit 1
                        ;;
                    *)
                        set_tcp_mux="true"
                        ;;
                esac
                echo "tcp_mux: ${set_tcp_mux}"
                sed -i "/^privilege_mode = true/d" ${str_program_dir}/${program_config_file}
                sed -i "/^token =.*/a\# 如果使用TCP流复用, 默认是 true\ntcp_mux = ${set_tcp_mux}\n" ${str_program_dir}/${program_config_file}
            fi
            if [ ! -z "${search_allow_ports}" ];then
                sed -i "s/privilege_allow_ports/allow_ports/" ${str_program_dir}/${program_config_file}
            fi
        fi
        verify_dashboard_user=`grep "^dashboard_user" ${str_program_dir}/${program_config_file}`
        verify_dashboard_pwd=`grep "^dashboard_pwd" ${str_program_dir}/${program_config_file}`
        verify_kcp_bind_port=`grep "kcp_bind_port" ${str_program_dir}/${program_config_file}`
        verify_tcp_mux=`grep "^tcp_mux" ${str_program_dir}/${program_config_file}`
        verify_token=`grep "privilege_token" ${str_program_dir}/${program_config_file}`
        verify_allow_ports=`grep "privilege_allow_ports" ${str_program_dir}/${program_config_file}`
        if [ ! -z "${verify_dashboard_user}" ] && [ ! -z "${verify_dashboard_pwd}" ] && [ ! -z "${verify_kcp_bind_port}" ] && [ ! -z "${verify_tcp_mux}" ] && [ -z "${verify_token}" ] && [ -z "${verify_allow_ports}" ];then
            echo -e "${COLOR_GREEN}成功更新配置文件!!!${COLOR_END}"
        else
            echo -e "${COLOR_RED}更新配置文件错误!!!${COLOR_END}"
        fi
    fi
}
update_program_server_clang(){
    fun_clangcn "clear"
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== 更新 ${program_name} =============="
        update_config_clang
        checkos
        check_centosversion
        check_os_bit
    fun_get_version
        remote_init_version=`wget  -qO- ${FRPS.INIT} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' ${program_init} | cut -d\" -f2`
        install_shell=${strPath}
        if [ ! -z ${remote_init_version} ];then
            if [[ "${local_init_version}" != "${remote_init_version}" ]];then
                echo "========== 更新 ${program_name} ${program_init} =========="
                if ! wget  ${FRPS_INIT} -O ${program_init}; then
                    echo "下载失败 ${program_name}.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}${program_init} 更新成功 !!!${COLOR_END}"
                fi
            fi
        fi
        [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
        echo -e "正在加载的网络版本 ${program_name}, 请等待..."
     fun_getServer
        fun_getVer >/dev/null 2>&1
        local_program_version=`${str_program_dir}/${program_name} --version`
        echo -e "${COLOR_GREEN}${program_name}  本地版本 ${local_program_version}${COLOR_END}"
        echo -e "${COLOR_GREEN}${program_name} 远程版本 ${FRPS_VER}${COLOR_END}"
        if [[ "${local_program_version}" != "${FRPS_VER}" ]];then
            echo -e "${COLOR_GREEN}找到新版本，立即更新!!!${COLOR_END}"
            ${program_init} stop
            sleep 1
            rm -f /usr/bin/${program_name} ${str_program_dir}/${program_name}
     fun_download_file
            if [ "${OS}" == 'CentOS' ]; then
                chmod +x ${program_init}
                chkconfig --add ${program_name}
            else
                chmod +x ${program_init}
                update-rc.d -f ${program_name} defaults
            fi
            [ -s ${program_init} ] && ln -s ${program_init} /usr/bin/${program_name}
            [ ! -x ${program_init} ] && chmod 755 ${program_init}
            ${program_init} start
            echo "${program_name} version `${str_program_dir}/${program_name} --version`"
            echo "${program_name} 更新成功!"
        else
                echo -e "无需更新 !!!${COLOR_END}"
        fi
    else
        echo "${program_name} 不安装!"
    fi
    exit 0
}
clear
strPath=`pwd`
rootness
fun_set_text_color
checkos
check_centosversion
check_os_bit
pre_install_packs
shell_update
# 初始化
action=$1
[  -z $1 ]
case "$action" in
install)
    pre_install_clang 2>&1 | tee /root/${program_name}-install.log
    ;;
config)
    configure_program_server_clang
    ;;
uninstall)
    uninstall_program_server_clang 2>&1 | tee /root/${program_name}-uninstall.log
    ;;
update)
    update_program_server_clang 2>&1 | tee /root/${program_name}-update.log
    ;;
*)
    fun_clangcn
    echo "参数错误! [${action} ]"
    echo "用法: `基础 $0` {install|uninstall|update|config}"
    RET_VAL=1
    ;;
esac
