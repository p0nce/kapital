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


echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\bc7enc16.obj >obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\bmpenc.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\ctypes.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\gif.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\j40.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\jpegload.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\lz4.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\msf_gif.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\qoi.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\qoi10b.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\qoi2avg.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\qoiplane.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\sqz.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\stb_image_write.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\stbdec.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\codecs\tga.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\internals\binop.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\internals\cstring.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\internals\errors.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\internals\types.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\bmp.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\dds.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\gif.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\jpeg.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\jxl.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\png.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\qoi.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\qoix.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\sqz.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugins\tga.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\image.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\io.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\package.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\plugin.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\scanline.obj >>obj\debug\gamut\gamut.link.rsp
echo C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source\gamut\types.obj >>obj\debug\gamut\gamut.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps obj\debug\gamut\gamut.lnkdep ldc2 -lib -oq -od="obj\debug\gamut" -m64 -g -d-debug -op -w -I="C:\Users\guill\AppData\Local\dub\packages\gamut\3.3.5\gamut\source" -I="C:\Users\guill\AppData\Local\dub\packages\intel-intrinsics\1.14.2\intel-intrinsics\source" -I="C:\Users\guill\AppData\Local\dub\packages\miniz\0.0.3\miniz\source" -d-version=encodePNG -d-version=decodeJPEG -d-version=decodePNG -d-version=decodeQOI -d-version=decodeQOIX -d-version=decodeSQZ -d-version=Have_gamut -d-version=Have_intel_intrinsics -d-version=Have_miniz -of=lib\gamut.lib @obj\debug\gamut\gamut.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist lib\gamut.lib (echo lib\gamut.lib not created! && goto reportError)

goto noError

:reportError
set ERR=%ERRORLEVEL%
set DISPERR=%ERR%
if %ERR% LSS -65535 set DISPERR=0x%=EXITCODE%
echo Building lib\gamut.lib failed (error code %DISPERR%)!
exit /B %ERR%

:noError
