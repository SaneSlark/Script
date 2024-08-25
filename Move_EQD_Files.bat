@echo off
setlocal enabledelayedexpansion

:: 创建目录 EQD，如果目录已存在则不会有影响
if not exist EQD md EQD

:: 直接在 for 循环中处理 dir 命令的输出
for /f "delims=" %%i in ('dir *.eqd /s /b') do (
    move "%%i" EQD
)

:: 输出完成信息并提示用户按任意键退出
echo Files moved to EQD directory.
pause
