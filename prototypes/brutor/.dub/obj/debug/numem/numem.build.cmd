set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0

echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\atomic.d >obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\attributes.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\cpp.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\exception.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\hooks.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\lifetime.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\math.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\memory.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\meta.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\package.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\traits.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\types.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\casting.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\compiler.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\heap.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\lifetime.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\object.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\optional.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\package.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\rc.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\sorting.d >>obj\debug\numem\numem.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\volatile.d >>obj\debug\numem\numem.build.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\numem\numem.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\numem\numem.json" -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -d-version=Have_numem -c -od=obj/debug/numem @obj\debug\numem\numem.build.rsp
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\numem.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
