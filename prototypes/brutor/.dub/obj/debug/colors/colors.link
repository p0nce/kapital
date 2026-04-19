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


echo C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source\colors\colorspace.obj >obj\debug\colors\colors.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source\colors\conversions.obj >>obj\debug\colors\colors.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source\colors\package.obj >>obj\debug\colors\colors.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source\colors\parser.obj >>obj\debug\colors\colors.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source\colors\types.obj >>obj\debug\colors\colors.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\colors\colors.lnkdep ldc2 -lib -oq -od="obj\debug\colors" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\colors\0.0.4\colors\source" -d-version=Have_colors -of=lib\colors.lib @obj\debug\colors\colors.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\colors.lib (echo lib\colors.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\colors.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
