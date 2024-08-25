@rem OneDrive Complete uninstaller batch process for Windows 10/11.
@rem Run as administrator to completely delete all OneDrive components and files.
@rem Written by TERRA Operative - 2020/03/02.
@rem Feel free to distribute freely as long as you leave this entire file unchanged and intact,
@rem and if you do make changes and adaptions, don't be a dick about not attributing where due.
@rem And most importantly, peace out and keep it real.

@echo OFF

@REM Set variables for coloured text
SETLOCAL EnableDelayedExpansion
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)

   echo ------Windows 10/11 OneDrive Uninstaller ------
   echo.
   
@rem This code block detects if the script is being running with admin privileges. If it isn't it pauses and then quits.
NET SESSION >nul 2>&1
IF %ERRORLEVEL% EQU 0 (

   echo            检测到管理员身份权限运行
   echo.
) ELSE (

   echo.
   call :colorEcho 0C "########### 错误提示：需要管理员权限 #############"
   echo.
   call :colorEcho 0C "#"
   call :colorEcho 07 " 此脚本必须以管理员身份运行才能正常工作 "  
   call :colorEcho 0C " #"
   echo.
   call :colorEcho 0C "#"
   call :colorEcho 07 " 若您在双击图标后看到这个提示,请重新打开 "
   call :colorEcho 0C " #"
   echo.
   call :colorEcho 0C "#"
   call :colorEcho 07 " 然后右键单击图标并选择“以管理员身份运行” "
   call :colorEcho 0C "#"
   echo.
   call :colorEcho 0C "#############################################"
   echo.
   echo.

   PAUSE
   EXIT /B 1
)

   echo -----------------------------------------------
   call :colorEcho 0C "                温馨提示： "
   echo.
   call :colorEcho 0C "           此脚本将完全且永久地 "
   echo.
   call :colorEcho 0C "           从计算机上删除OneDrive "
   echo.
   call :colorEcho 0C "           请确保所有OneDrive文档 "   
   echo.
   call :colorEcho 0C "           已在本地存储的完全恢复 "
   echo.
   call :colorEcho 0C "           在继续之前记得备份文件 "   
   echo.
   echo -----------------------------------------------
   echo.

   SET /P M=  按“Y”继续，或按任何其他键退出。 
   if %M% ==Y goto PROCESSKILL
   if %M% ==y goto PROCESSKILL

   EXIT /B 1


@rem The following is based on info from here written by 'LK':
@rem https://techjourney.net/disable-or-uninstall-onedrive-completely-in-windows-10/


@rem Terminate any OneDrive process
:PROCESSKILL
   echo.
   echo Terminating OneDrive process.
   
taskkill /f /im OneDrive.exe


@rem Detect if OS is 32 or 64 bit
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT

if %OS%==32BIT GOTO 32BIT
if %OS%==64BIT GOTO 64BIT


@rem Uninstall OneDrive app
:32BIT
   echo.
   echo This is a 32-bit operating system.
   echo Removing OneDrive setup files.
   
%SystemRoot%\System32\OneDriveSetup.exe /uninstall
GOTO CLEAN

:64BIT
   echo.
   echo This is a 64-bit operating system.
   echo Removing OneDrive setup files.
   
%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall
GOTO CLEAN


@rem Clean and remove OneDrive remnants
:CLEAN
   echo.
   echo Removing remaining OneDrive folders.
   
   rd "%UserProfile%\OneDrive" /s /q
   rd "%LocalAppData%\Microsoft\OneDrive" /s /q
   rd "%ProgramData%\Microsoft OneDrive" /s /q
   rd "C:\OneDriveTemp" /s /q
   del "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /s /f /q
   
   echo.
   call :colorEcho 0C "如果在此处看到“拒绝访问”错误，请重新启动并再次运行此批处理文件"
   echo.
   echo.
   echo “系统找不到指定的文件”错误没有问题，这意味着文件已经不存在了。
   echo.


@rem Delete and remove OneDrive in file explorer folder tree registry key
   echo -----------------------------------------------
   echo.
   echo Removing OneDrive registry keys.
   
   REG Delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
   REG Delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
   REG ADD "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /d "0" /t REG_DWORD /f

   echo.
   echo.
   echo 系统找不到指定的注册表项或值。
   echo 出现错误是正常的，这意味着注册表项已经不存在。
   echo.
   echo -----------------------------------------------
   echo.
   echo OneDrive卸载和清理已完成.
   echo.

   PAUSE
   echo So long and thanks for all the fish...
   PING -n 2 127.0.0.1>nul
   EXIT /B 1

  
@rem Settings for text colour

:colorEcho
echo off
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1i
