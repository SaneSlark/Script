@chcp 65001
@echo off
mode con cols=80 lines=20
title Windows 11 还原经典菜单(windows 11 Classic Context Menu)

:Menu
echo --------------------------------------------------------------------------
echo.
echo  Win11的右键菜单非常难用，极大的降低了我们的工作效率，
echo  这个脚本来帮助大家快速的修改Windows11的右键菜单样式。
echo.
echo 【1】将右键菜单修改为Win10样式（Restore Classic Context Menu）& echo.
echo 【2】将右键菜单恢复为Win11样式（Restore Default Context Menu）& echo.
echo 【3】重启资源管理器（Restart explorer.exe）& echo.
echo 【4】退出 & echo.
echo --------------------------------------------------------------------------

set "select="
set /p select= 输入数字，按回车继续（Type 1, 2, 3, or 4 then press ENTER） :
if "%select%"=="1" (goto CLASSIC)
if "%select%"=="2" (goto DEFAULT)
if "%select%"=="3" (goto RESTARTEXPLORER)
if "%select%"=="4" (goto EXIT)
cls & goto Menu

:CLASSIC
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f
goto restartExplorer

:DEFAULT
reg.exe delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f

:RESTARTEXPLORER
echo 重启资源管理器已设置生效，按任意键重启（enter any key to restart explorer.exe let set worked）& pause>nul
taskkill /f /im explorer.exe & start explorer.exe

:EXIT
echo 按任意键退出 & pause > nul & exit
