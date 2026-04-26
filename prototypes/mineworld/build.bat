@echo off
set CC=c:\raylib\w64devkit\bin\gcc.exe
set PATH=c:\raylib\w64devkit\bin;%PATH%
set RAYLIB=c:\raylib\raylib\src

%CC% src\main.c src\world.c src\chunk.c src\camera.c ^
  -I%RAYLIB% -I%RAYLIB%\external -Ivendor -Isrc ^
  -L%RAYLIB% -lraylib -lopengl32 -lgdi32 -lwinmm ^
  -std=c11 -O1 -o mineworld.exe 2>&1

if %errorlevel%==0 (echo Build OK) else (echo Build FAILED && exit /b 1)
mineworld.exe 
