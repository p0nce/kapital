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


echo C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source\bindbc\loader\codegen.obj >obj\debug\bindbc-loader\bindbc-loader.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source\bindbc\loader\package.obj >>obj\debug\bindbc-loader\bindbc-loader.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source\bindbc\loader\sharedlib.obj >>obj\debug\bindbc-loader\bindbc-loader.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source\bindbc\loader\system.obj >>obj\debug\bindbc-loader\bindbc-loader.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\bindbc-loader\bindbc-loader.lnkdep ldc2 -lib -oq -od="obj\debug\bindbc-loader" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\bindbc-loader\1.1.5\bindbc-loader\source" -d-version=Have_bindbc_loader -of=lib\BindBC_Loader.lib @obj\debug\bindbc-loader\bindbc-loader.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\BindBC_Loader.lib (echo lib\BindBC_Loader.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\BindBC_Loader.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
