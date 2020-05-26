# Proxy

## 此仓库收集为备份仓库，以防丢失

### 脚本列表及使用方法

1. Aria2.sh

Aria2c一键安装脚本，详情介绍可访问官网：https://aria2.github.io

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/Aria2.sh && chmod +x Aria2.sh && bash Aria2.sh
```

2. MTProxy.sh

MTProxy一键安装脚本，此脚本主要功能为Telegram(电报群)的代理脚本。

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/MTProxy.sh && chmod +x MTProxy.sh && bash MTProxy.sh
```

3. BBR.sh

此脚本为给服务器安装BBR拥塞控制内核，安装此脚本能最大程度的利用网络剩余带宽，提高吞吐量。

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh
```

4. ss.sh

此脚本为安装代理协议Shadowsocks脚本

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/ss.sh && chmod +x ss.sh && bash ss.sh
```

5. ssr.sh

此脚本为安装代理协议Shadowsocks-R脚本

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/ssr.sh && chmod +x ssr.sh && bash ssr.sh
```

6. tcp.sh

此脚本为BBR四合一一键安装脚本，给你的服务器BBR升级版协议(分别为BBR魔改加速、锐速、BBR Plus、BBR原生加速)

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/tcp.sh && chmod +x tcp.sh && bash tcp.sh
```

7. sshPort.sh

此脚本为更改你服务器的默认安全端口，使之不再是服务器出厂设置的22端口，更改安全端口能有效避免暴力破解。

**使用方法：**

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/wx0716/Proxy/master/sshPort.sh && chmod +x sshPort.sh && bash sshPort.sh
```