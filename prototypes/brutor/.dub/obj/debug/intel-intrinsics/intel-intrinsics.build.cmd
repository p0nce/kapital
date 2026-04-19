set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0

echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\avx2intrin.d >obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\avxintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\bmi2intrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\emmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\internals.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\math.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\mmx.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\nmmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\package.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\pmmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\shaintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\smmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\tmmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\types.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
echo C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source\inteli\xmmintrin.d >>obj\debug\intel-intrinsics\intel-intrinsics.build.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\intel-intrinsics\intel-intrinsics.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\intel-intrinsics\intel-intrinsics.json" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_intel_intrinsics -c -od=obj/debug/intel-intrinsics @obj\debug\intel-intrinsics\intel-intrinsics.build.rsp
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\intel-intrinsics.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
