@echo off
setlocal

:: 查找 Git Bash
set "GITBASH="
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files\Git\bin\bash.exe"
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set "GITBASH=C:\Program Files (x86)\Git\bin\bash.exe"
) else (
    for /f "delims=" %%i in ('where git 2^>nul') do (
        set "GIT_PATH=%%~dpi"
    )
    if defined GIT_PATH (
        set "GITBASH=%GIT_PATH%..\bin\bash.exe"
    )
)

if not defined GITBASH (
    echo [!] 找不到 Git Bash，请先安装 Git for Windows
    echo     https://git-scm.com/download/win
    exit /b 1
)

"%GITBASH%" "%~dp0wuji-sync.sh" %*
