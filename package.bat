@echo off

IF EXIST release RMDIR /q /s release
MKDIR release

REM Copy required files into release directory...
COPY /V lua5.1.dll release\lua5.1.dll
COPY /V lua5.1-original.dll release\lua5.1-original.dll
COPY /V opengl32.dll release\opengl32.dll
COPY /V SDL2.dll release\SDL2.dll
COPY /V SDL2-original.dll release\SDL2-original.dll
COPY /V Cutils.dll release\Cutils.dll
COPY /V uninstall.bat release\uninstall.bat
XCOPY mods release\mods /s /e /i
XCOPY scripts release\scripts /s /e /i
XCOPY resources release\resources /s /e /i

REM ...and pack it into a zip
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('release', 'ITB-ModLoader-#.#.#.zip'); }"

REM Delete release directory
RMDIR /q /s release
