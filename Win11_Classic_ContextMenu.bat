@chcp 65001    
@cls 
@title Windows11 右键菜单替换程序
@echo off

net session >nul 2>&1
if %errorLevel% == 0 (
   
    goto :menu
) else (
  
    echo Set UAC = CreateObject^("Shell.Application"^)>"%temp%\elevate.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~f0""", "", "runas", 1 >>"%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
  
)

:menu
cls
echo.------------------------------------------------------------------------------------------------
echo.Win11的右键菜单非常难用，极大的降低了我们的工作效率，
echo.这个脚本来帮助大家快速的修改Windows11的右键菜单样式。
echo.
echo.【1】将右键菜单修改为Win10样式 
echo.【2】将右键菜单恢复为Win11样式 
echo.【3】退出
echo.------------------------------------------------------------------------------------------------
:CHO
set choice=
set /p choice= 请选择要执行的操作：
IF NOT "%Choice%"=="" SET Choice=%Choice:~0,1%
if /i "%choice%"=="1" goto a
if /i "%choice%"=="2" goto b
if /i "%choice%"=="3" exit
echo.选择无效，请重新输入,按任意键重新选择
pause >nul
goto menu

:a
cls
@echo.进行修改为Win10菜单样式的操作，请保存好重要的工作程序。
@reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
goto c

:b
cls
@echo.进行Windows11菜单回滚操作，请保存好重要的工作程序。
@reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /va /f
goto c

:c
echo.重启资源管理器，请按任意键执行。
@taskkill /f /im explorer.exe
@start explorer.exe
cls
@echo.已执行完成，程序即将退出。
@timeout /t 5