set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0
if %errorlevel% neq 0 goto reportError


echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\bindbc\sdl\codegen.obj >obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\bindbc\sdl\config.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\bindbc\sdl\package.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\assert_.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\asyncio.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\atomic.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\audio.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\bits.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\blendmode.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\camera.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\clipboard.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\cpuinfo.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\dialogue.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\endian.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\error.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\events.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\filesystem.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\gamepad.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\gesture.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\gpu.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\guid.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\haptic.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\hidapi.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\hints.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\init.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\iostream.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\joystick.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\keyboard.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\keycode.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\loadso.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\locale.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\log.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\main.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\messagebox.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\metal.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\misc.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\mouse.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\mutex.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\package.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\pen.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\pixels.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\platform.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\power.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\process.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\properties.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\rect.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\render.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\scancode.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\sensor.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\stdinc.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\storage.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\surface.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\system.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\thread.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\time.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\timer.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\touch.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\tray.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\version_.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\video.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl\vulkan.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl_image.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl_mixer.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl_net.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl_shadercross.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source\sdl_ttf.obj >>obj\debug\bindbc-sdl\bindbc-sdl.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\bindbc-sdl\bindbc-sdl.lnkdep ldc2 -lib -oq -od="obj\debug\bindbc-sdl" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source" -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-common\1.0.5\bindbc-common\source" -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source" -d-version=Have_bindbc_sdl -d-version=Have_bindbc_common -d-version=Have_bindbc_loader -of=lib\BindBC_SDL.lib @obj\debug\bindbc-sdl\bindbc-sdl.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\BindBC_SDL.lib (echo lib\BindBC_SDL.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\BindBC_SDL.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
