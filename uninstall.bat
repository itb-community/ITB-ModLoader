@echo off

IF EXIST modloader.log DEL /q modloader.log
IF EXIST error.txt DEL /q error.txt
IF EXIST log.txt DEL /q log.txt
DEL /q lua5.1.dll
DEL /q opengl32.dll
DEL /q SDL2.dll
DEL /q Cutils.dll
DEL /q scripts\scripts.lua
IF EXIST resources\resource.dat.bak DEL /q resources\resource.dat
RMDIR /q /s resources\mods
RMDIR /q /s scripts\mod_loader
ECHO Done.

ECHO Restoring original game files...
REN lua5.1-original.dll lua5.1.dll
REN SDL2-original.dll SDL2.dll
IF EXIST resources\resource.dat.bak REN resources\resource.dat.bak resource.dat
REN scripts\scripts.lua.bak scripts.lua
ECHO Done.

REM Delete the batch file itself
(GOTO) 2>nul & DEL "%~f0"
