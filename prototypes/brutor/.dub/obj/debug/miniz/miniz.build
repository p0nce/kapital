set PATH=d:\d\ldc2-1.41.0-windows-multilib\bin;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX86\x64;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;%PATH%
set LIB=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\lib\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.26100.0\um\x64
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\
set VCTOOLSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.29.30133\
set VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\
set WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
set WindowsSdkVersion=10.0.26100.0
set UniversalCRTSdkDir=C:\Program Files (x86)\Windows Kits\10\
set UCRTVersion=10.0.26100.0
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\miniz\miniz.dep ldc2 -m64 -g -d-debug -op -w -X -Xf="obj\debug\miniz\miniz.json" -I="C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source" -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_miniz -c -od=obj/debug/miniz C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source\miniz.d
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\miniz.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
