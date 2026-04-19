set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0

echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\coders.d >obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\horizontals.d >>obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\package.d >>obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\simd.d >>obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\types.d >>obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source\stb_image_resize2\verticals.d >>obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\stb_image_resize2-d\stb_image_resize2-d.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\stb_image_resize2-d\stb_image_resize2-d.json" -I="C:\Users\guill\AppData\Local\dub\packages\stb_image_resize2-d\1.0.1\stb_image_resize2-d\source" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -d-version=Have_stb_image_resize2_d -d-version=Have_intel_intrinsics -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -c -od=obj/debug/stb_image_resize2-d @obj\debug\stb_image_resize2-d\stb_image_resize2-d.build.rsp
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\stb_image_resize2-d.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
