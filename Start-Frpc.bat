@echo off
setlocal enabledelayedexpansion

set /p KEY_ID=<config

cd frpc

start "SakuraFrp Service" cmd /c "frpc_windows_amd64.exe -f !KEY_ID! > frpc.log"

cd ..
