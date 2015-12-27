@echo off
setlocal

for /f "tokens=1-7 delims=~" %%i in ('mshta.exe "%~dp0\hta\batchman.hta"') do (
	set "srcdir=%%i"
	set "srcfile=%%j"
	set "include=%%k"
	set "hideconsole=%%l"
	set "completion=%%m"
	set "name=%%n"
	set "icofile=%%o"
)
if "%srcfile%"=="" goto :eof
set "distexe=%srcdir%\%name%.exe"
set "tmpfile=%temp%\%srcfile%"
copy /y %srcdir%\%srcfile% %tmpfile%

::HTA completion feedback
if "%completion%" == "true" (
	>>%tmpfile% echo(
	>>%tmpfile% echo :batchmanCompletion
	>>%tmpfile% echo start /wait "" mshta.exe "javascript:alert('%name% complete');close()"
	"%~dp0\bin\sed.exe" -e "s/goto *:eof/goto batchmanCompletion/g" <%tmpfile% >%tmpfile%_sed.tmp
	del /q /f %tmpfile% 2>nul >nul
	rename %tmpfile%_sed.tmp %srcfile%
	rem sed in-place does not fully work on windows (generates backup file no matter what)
)

:: Compress files
set "archive=%temp%\batchman_%name%.7z"
if "%include%" == "true" (
	start /b /wait "Compressing" "%~dp0\bin\7za.exe" a -y %archive% "%tmpfile%" "%srcdir%\*" -x!"%srcdir%\%srcfile%"
) else (
	start /b /wait "Compressing" "%~dp0\bin\7za.exe" a -y %archive% "%tmpfile%"
)

:: Create Config File
set "sfxconfig=%temp%\batchman-config.txt"
>%sfxconfig% echo ;!@Install@!UTF-8!
if "%hideconsole%" == "true" (
	>>%sfxconfig% echo RunProgram="hidcon:%srcfile%"
) else (
	>>%sfxconfig% echo ExecuteFile="%srcfile%"
)
>>%sfxconfig% echo Title="%name%"
>>%sfxconfig% echo ExtractTitle="%name%"
>>%sfxconfig% echo GUIFlags="2+8+512"
>>%sfxconfig% echo GUIMode="1"
>>%sfxconfig% echo ;!@InstallEnd@!

:: Create SFX
copy /y /b %~dp0\bin\7zsd_LZMA2.sfx + %sfxconfig% + %archive% %temp%\%name%.tmp

:: Overwrite if executable filename exists
if exist "%distexe%" del /q /f "%distexe%"

:: Add icon
if "%icofile%" == "false" set "icofile=%~dp0\bin\default_icon.ico"
copy /y %temp%\%name%.tmp %temp%\%name%.icx
start /b /wait "Resourcer" "%~dp0\bin\resourcer.exe" -op:add -src:"%temp%\%name%.icx" -type:icon -name:NAME -lang:1033 -file:"%icofile%"
copy /b /y %temp%\%name%.icx + %temp%\%name%.tmp %distexe%

:: Compress executable
start /b /wait "Compressing" "bin\upx.exe" -1 -q "%distexe%"

:: Cleaning
if exist %sfxconfig% del /q /f %sfxconfig%
if exist %temp%\%name%.icx del /q /f %temp%\%name%.icx
if exist %temp%\%name%.tmp del /q /f %temp%\%name%.tmp
if exist %archive% del /q /f %archive%
if exist %tmpfile% del /q /f %tmpfile%