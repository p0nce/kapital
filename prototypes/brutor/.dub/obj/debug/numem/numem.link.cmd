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


echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\atomic.obj >obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\attributes.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\cpp.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\exception.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\hooks.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\lifetime.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\math.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\memory.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\meta.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\package.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\traits.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\core\types.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\casting.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\compiler.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\heap.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\lifetime.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\object.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\optional.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\package.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\rc.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\sorting.obj >>obj\debug\numem\numem.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source\numem\volatile.obj >>obj\debug\numem\numem.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\numem\numem.lnkdep ldc2 -lib -oq -od="obj\debug\numem" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\numem\1.6.5\numem\source" -d-version=Have_numem -of=lib\numem.lib @obj\debug\numem\numem.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\numem.lib (echo lib\numem.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\numem.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
