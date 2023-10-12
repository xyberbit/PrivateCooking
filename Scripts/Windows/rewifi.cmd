@echo off
:netsh wlan disconnect
:goto :test

:auto
for /f "usebackq tokens=3" %%i in (`netsh wlan show interfaces ^| find " SSID"`) do set ssid=%%i && goto :auto1
:auto1
if .%ssid% == . goto :user
echo Wifi connection '%ssid%' found! && goto :proc
echo No Wifi connection found!

:user
if .%1  == . goto :prof
set ssid=%1
echo User assigned Wifi network '%ssid%' applied!
goto :proc

:prof
for /f "usebackq tokens=5" %%i in (`netsh wlan show profiles ^| find "User Profile"`) do set ssid=%%i && goto :prof1
:prof1
if .%ssid%  == . goto :err
if "%ssid:~-1%" == " " set ssid=%ssid:~0,-1%
echo First Wifi profile network '%ssid%' applied!
goto :proc

:err
echo Failed to find any available Wifi network!
goto :exit

:proc
netsh wlan disconnect
timeout /t 5
netsh wlan connect %ssid%

:exit
timeout /t 15
exit
