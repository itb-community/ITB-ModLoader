@echo off

IF EXIST release (
	RMDIR /q /s release
)
MKDIR release

COPY /V lua5.1.dll release\lua5.1.dll
COPY /V lua5.1.dll.bak release\lua5.1.dll.bak
COPY /V opengl32.dll release\opengl32.dll
COPY /V SDL2.dll release\SDL2.dll
COPY /V SDL2.dll.bak release\SDL2.dll.bak
COPY /V uninstall.bat release\uninstall.bat
XCOPY mods release\mods /s /e /i
XCOPY scripts release\scripts /s /e /i
XCOPY resources release\resources /s /e /i
