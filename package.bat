@echo off

CALL _release.bat

REM ...and pack it into a zip
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('release', 'ITB-ModLoader-#.#.#.zip'); }"

REM Delete release directory
RMDIR /q /s release
