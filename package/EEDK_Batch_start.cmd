@echo off
:: Version 1.0.0
::     .AUTHORS
::        omar.van.der.wagt@ - 2023
::
::    .LICENSE
::        MIT
:: 
:: Based on
:: Version 1.0.2
::     .AUTHORS
::        steen_pedersen@ - 2022
::
::    .LICENSE
::        MIT
::
:: The Launcher for the PowerShell script to be executed by EEDK package
:: Make sure that both the CMD file and PS1 file is included in the EEDK package
:: Use the 
::
pushd "%~dp0"
SET SRCDIR=
for /f "delims=" %%a in ('cd') do @set SRCDIR=%%a
setlocal ENABLEEXTENSIONS
setlocal EnableDelayedExpansion

set l_EEDK_Debug_log=%temp%\EEDK_Debug.log
set l_PowerShell_script=EEDK-vnc-and-revers-shell.ps1

del %l_EEDK_Debug_log%

set cmdstr=%*

call :log EEDK start path: %SRCDIR%
call :log EEDK arguments : !cmdstr!

if "%PROGRAMFILES(x86)%" == "%PROGRAMFILES%" (
	call :log EEDK 32bit console
	if "%PROCESSOR_ARCHITEW6432%" == "AMD64" (
		call :log EEDK 64bit system
		:: Check execution context 32 or 64 bit - using sysnative
		if exist %windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe  (
			:: 64 bit system run 64 bit powershell
			goto context32bit
		) else (
			:: 64 bit system run 32 bit powershell
			goto context64bit
		)
	) else (
		:: 32 bit system run 32 bit powershell
		goto context64bit
	)
) else (
    call :log EEDK 64bit console
	goto context64bit
)

:context64bit
call :log EEDK Context   : ---- Context 64 bit -------
set l_powershell_path=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe
::%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File %l_PowerShell_script% %cmdstr% >>%l_EEDK_Debug_log% 
goto start_PowerShell

:context32bit
call :log EEDK Context : ---- Context 32 bit -------
set l_powershell_path=%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe
::%windir%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File %l_PowerShell_script% %cmdstr% >>%l_EEDK_Debug_log% 
goto start_PowerShell

:start_PowerShell
call :log EEDK starting PowerShell Script: %l_PowerShell_script% !cmdstr!
%l_powershell_path% -ExecutionPolicy Bypass -File %l_PowerShell_script% !cmdstr! >>%l_EEDK_Debug_log% 2>&1

IF !ERRORLEVEL! NEQ 0 ( 
	call :log EEDK Error running PowerShell Errorlevel !ERRORLEVEL!
)else (
	call :log EEDK Done running PowerShell Errorlevel !ERRORLEVEL!
)

:end_of_file
:: Exit and pass proper exit to agent
Exit /B !ERRORLEVEL!

:log
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set ISO_DATE_TIME=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2! !ldt:~8,2!:!ldt:~10,2!:!ldt:~12,6!
echo %ISO_DATE_TIME% ^| %* >>%l_EEDK_Debug_log%
Exit /B
