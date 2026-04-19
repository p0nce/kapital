set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0

echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\binrange.d >obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\btree.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\file.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\fpcontrol.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\lockedqueue.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\map.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\math.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\nogc.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\package.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\profiler.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\random.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\ringbuf.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\runtime.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\sharedlib.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\string.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\sync.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\thread.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\traits.d >>obj\debug\dplug_core\dplug_core.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core\dplug\core\vec.d >>obj\debug\dplug_core\dplug_core.build.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\dplug_core\dplug_core.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\dplug_core\dplug_core.json" -I="C:\Users\guill\AppData\Local\dub\packages\dplug\16.4.6\dplug\core" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -d-version=Have_dplug_core -d-version=Have_intel_intrinsics -d-version=Have_numem -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -c -od=obj/debug/dplug_core @obj\debug\dplug_core\dplug_core.build.rsp
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\dplug_core.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
