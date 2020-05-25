#!/bin/bash

#fonts color
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"  # 蓝色字体
}


if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
fi

function install_trojan(){
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" == "SELINUX=enforcing" ]; then
    blue "======================================================================="
    blue "检测到SELinux为开启状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
    blue "======================================================================="
    read -p "是否现在重启 ?请输入 [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "VPS 重启中..."
	    reboot
	fi
    exit
fi
if [ "$CHECK" == "SELINUX=permissive" ]; then
    blue "======================================================================="
    blue "检测到SELinux为宽容状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
    blue "======================================================================="
    read -p "是否现在重启 ?请输入 [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "VPS 重启中..."
	    reboot
	fi
    exit
fi
if [ "$release" == "centos" ]; then
    if  [ -n "$(grep ' 6\.' /etc/bluehat-release)" ] ;then
    blue "==============="
    blue "当前系统不受支持"
    blue "==============="
    exit
    fi
    if  [ -n "$(grep ' 5\.' /etc/bluehat-release)" ] ;then
    blue "==============="
    blue "当前系统不受支持"
    blue "==============="
    exit
    fi
    systemctl stop firewalld
    systemctl disable firewalld
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
elif [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    blue "==============="
    blue "当前系统不受支持"
    blue "==============="
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    blue "==============="
    blue "当前系统不受支持"
    blue "==============="
    exit
    fi
    systemctl stop ufw
    systemctl disable ufw
    apt-get update
fi
$systemPackage -y install  nginx wget unzip zip curl tar >/dev/null 2>&1
systemctl enable nginx.service
blue "======================="
blue "请输入绑定到本VPS的域名"
blue "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
	blue "=========================================="
	blue "       域名解析正常，开始安装trojan"
	blue "=========================================="
	sleep 1s
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	#设置伪装站
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget https://github.com/V2RaySSR/Trojan/raw/master/web.zip
    	unzip web.zip
	systemctl restart nginx.service
	#申请https证书
	mkdir /usr/src/trojan-cert
	curl https://get.acme.sh | sh
	~/.acme.sh/acme.sh  --issue  -d $your_domain  --webroot /usr/share/nginx/html/
    	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
	if test -s /usr/src/trojan-cert/fullchain.cer; then
        cd /usr/src
	wget https://github.com/trojan-gfw/trojan/releases/download/v1.15.1/trojan-1.15.1-linux-amd64.tar.xz
	tar xf trojan-1.*
	#下载trojan客户端
	wget https://github.com/atrandys/trojan/raw/master/trojan-cli.zip
	unzip trojan-cli.zip
	cp /usr/src/trojan-cert/fullchain.cer /usr/src/trojan-cli/fullchain.cer
	trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
	cat > /usr/src/trojan-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
	rm -rf /usr/src/trojan/server.conf
	cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/trojan-cert/fullchain.cer",
        "key": "/usr/src/trojan-cert/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
	cd /usr/src/trojan-cli/
	zip -q -r trojan-cli.zip /usr/src/trojan-cli/
	trojan_path=$(cat /dev/urandom | head -1 | md5sum | head -c 16)
	mkdir /usr/share/nginx/html/${trojan_path}
	mv /usr/src/trojan-cli/trojan-cli.zip /usr/share/nginx/html/${trojan_path}/
	#增加启动脚本
	
cat > ${systempwd}trojan.service <<-EOF
[Unit]  
Description=trojan  
After=network.target  
   
[Service]  
Type=simple  
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/usr/src/trojan/trojan -c "/usr/src/trojan/server.conf"  
ExecReload=  
ExecStop=/usr/src/trojan/trojan  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target
EOF

	chmod +x ${systempwd}trojan.service
	systemctl start trojan.service
	systemctl enable trojan.service
	blue "======================================================================"
	blue "Trojan已安装完成，请使用以下链接下载trojan客户端，此客户端已配置好所有参数"
	blue "1、复制下面的链接，在浏览器打开，下载客户端"
	blue "http://${your_domain}/$trojan_path/trojan-cli.zip"
	blue "请记录下面规则网址"
	blue "http://${your_domain}/trojan.txt"
	blue "2、将下载的压缩包解压，打开文件夹，打开start.bat即打开并运行Trojan客户端"
	blue "3、打开stop.bat即关闭Trojan客户端"
	blue "4、Trojan客户端需要搭配浏览器插件使用，例如switchyomega等"
	blue "======================================================================"
	else
        blue "================================"
	blue "https证书没有申请成果，本次安装失败"
	blue "================================"
	fi
	
else
	blue "================================"
	blue "域名解析地址与本VPS IP地址不一致"
	blue "本次安装失败，请确保域名解析正常"
	blue "================================"
fi
}

function remove_trojan(){
    blue "================================"
    blue "即将卸载trojan"
    blue "同时卸载安装的nginx"
    blue "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    if [ "$release" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y nginx
    fi
    rm -rf /usr/src/trojan*
    rm -rf /usr/share/nginx/html/*
    blue "=============="
    blue "trojan删除完毕"
    blue "=============="
}

function bbr_boost_sh(){
    bash <(curl -L -s -k "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh")
}

start_menu(){
    clear
    blue " ===================================="
    blue " Trojan 一键安装自动脚本      "
    blue " 系统：centos7+/debian9+/ubuntu16.04+"
    blue " 网站：https://wx0716.com              "
    blue " ===================================="
    echo
    blue " ===================================="
    blue " 1. 一键安装 Trojan"
    blue " ===================================="
    blue " 2. 安装 4 IN 1 BBRPLUS加速脚本"
    blue " ===================================="
    blue " 3. 一键卸载 Trojan"
    blue " ===================================="
    blue " 0. 退出脚本"
    blue " ===================================="
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    bbr_boost_sh 
    ;;
    3)
    remove_trojan
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    blue "请输入正确数字"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu
