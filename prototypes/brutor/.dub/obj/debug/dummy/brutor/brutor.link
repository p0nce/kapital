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


echo obj/debug/dummy/brutor\..\source\brutor\avatar.obj >obj\debug\dummy\brutor\brutor.link.rsp
echo obj/debug/dummy/brutor\..\source\brutor\combat.obj >>obj\debug\dummy\brutor\brutor.link.rsp
echo obj/debug/dummy/brutor\..\source\brutor\dice.obj >>obj\debug\dummy\brutor\brutor.link.rsp
echo obj/debug/dummy/brutor\..\source\brutor\game.obj >>obj\debug\dummy\brutor\brutor.link.rsp
echo obj/debug/dummy/brutor\..\source\brutor\package.obj >>obj\debug\dummy\brutor\brutor.link.rsp
echo obj/debug/dummy/brutor\..\source\main.obj >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\turtle.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\BindBC_SDL.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\BindBC_Common.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\BindBC_Loader.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\canvasity.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\dplug_canvas.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\colors.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\dplug_graphics.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\dplug_core.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\dplug_math.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\gamut.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\stb_image_resize2-d.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\godot-math.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\numem.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\text-mode.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\intel-intrinsics.lib >>obj\debug\dummy\brutor\brutor.link.rsp
echo D:\kapital\prototypes\brutor\.dub\lib\miniz.lib >>obj\debug\dummy\brutor\brutor.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\dummy\brutor\brutor.lnkdep ldc2 -m64 -g -d-debug -op -w -I="..\source" -I="C:\Users\guill\AppData\Local\dub\packages\turtle\0.1.4\turtle\source" -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-sdl\2.3.4\bindbc-sdl\source" -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-common\1.0.5\bindbc-common\source" -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source" -I="C:\Users\guill\AppData\Local\dub\packages\canvasity\1.0.7\canvasity\source" -I="C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -I="C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source" -I="C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\graphics" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\math" -I="C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source" -I="C:\Users\guill\AppData\Local\dub\packages\godot-math\0.0.5\godot-math\source" -I="C:\Users\guill\AppData\Local\dub\packages\text-mode\1.1.16\text-mode\source" -J="C:\Users\guill\AppData\Local\dub\packages\turtle\0.1.4\turtle\resources" -d-version=Have_brutor -d-version=Have_turtle -d-version=Have_bindbc_sdl -d-version=Have_canvasity -d-version=Have_colors -d-version=Have_dplug_canvas -d-version=Have_godot_math -d-version=Have_text_mode -d-version=Have_bindbc_common -d-version=Have_bindbc_loader -d-version=Have_dplug_core -d-version=Have_gamut -d-version=Have_intel_intrinsics -d-version=Have_numem -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_miniz -d-version=Have_dplug_graphics -d-version=Have_dplug_math -d-version=Have_stb_image_resize2_d -of=D:\kapital\prototypes\brutor\brutor.exe -L/PDB:"obj\debug\dummy\brutor\brutor.pdb"   @obj\debug\dummy\brutor\brutor.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist D:\kapital\prototypes\brutor\brutor.exe (echo D:\kapital\prototypes\brutor\brutor.exe not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building D:\kapital\prototypes\brutor\brutor.exe failed (error code %DISPERR%)!
exit /B %ERR%

:noError
