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


echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\angularblit.obj >obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\colorblit.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\ellipticalblit.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\gradient.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\linearblit.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\misc.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\package.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas\dplug\canvas\rasterizer.obj >>obj\debug\dplug_canvas\dplug_canvas.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\dplug_canvas\dplug_canvas.lnkdep ldc2 -lib -oq -od="obj\debug\dplug_canvas" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\canvas" -I="C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\graphics" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\math" -I="C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source" -I="C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source" -I="C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source" -I="C:\Users\guill\AppData\Local\dub\packages\godot-math\0.0.5\godot-math\source" -d-version=Have_dplug_canvas -d-version=Have_colors -d-version=Have_dplug_core -d-version=Have_dplug_graphics -d-version=Have_dplug_math -d-version=Have_godot_math -d-version=Have_intel_intrinsics -d-version=Have_numem -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_gamut -d-version=Have_stb_image_resize2_d -d-version=Have_miniz -of=lib\dplug_canvas.lib @obj\debug\dplug_canvas\dplug_canvas.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\dplug_canvas.lib (echo lib\dplug_canvas.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\dplug_canvas.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
