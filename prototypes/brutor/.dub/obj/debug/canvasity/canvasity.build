set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\canvasity\canvasity.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\canvasity\canvasity.json" -I="C:\Users\guill\AppData\Local\dub\packages\canvasity\1.0.7\canvasity\source" -I="C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -I="C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source" -I="C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source" -d-version=Have_canvasity -d-version=Have_colors -d-version=Have_dplug_core -d-version=Have_gamut -d-version=Have_intel_intrinsics -d-version=Have_numem -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_miniz -c -od=obj/debug/canvasity C:\Users\guill\AppData\Local\dub\packages\canvasity\1.0.7\canvasity\source\canvasity.d
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\canvasity.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
