@echo off
setlocal ENABLEEXTENSIONS

set vlang=jpn
set alang=jpn
set outdir=..
set dim=1280x720
set debug=

echo muxmkv 1.0
:argloop
if "%1" == "" goto :argend
set var=
if "%1" == "-d" set debug=echo & goto :argnext
if "%1" == "-h" call :help & goto :eof
if "%1" == "-o" set var=outdir
if "%1" == "-a" set var=alang
if "%1" == "-v" set var=vlang
if "%1" == "-r" set var=dim
if "%var%" == "" echo Unknown argument: "%1" & goto :argnext
set %var%=%2
shift /1
:argnext
shift /1
goto :argloop
:argend

if not "%debug%" == "" (
  echo vlang=%vlang%
  echo alang=%alang%
  echo outdir=%outdir%
  echo dim=%dim%
  echo debug=%debug%
)

for %%i in (*.mkv) do (
  set attachs=
  for %%j in ("%%~ni\*") do (
    set name=%%~nxj
    set file=%%~j
    setlocal ENABLEDELAYEDEXPANSION
    set attachs=!attachs! --attachment-mime-type "application/x-truetype-font" --attachment-name "!name!" --attach-file "!file!"
    for /F "delims=" %%v in ("!attachs!") DO (    
      endlocal
      set "attachs=%%v"
    )
  )
  set subs=
  set num=2
  for %%j in ("%%~ni.*.ass","%%~ni.*.srt") do (
    for /F "tokens=2,3 delims=." %%n in ("%%~j") do (
      set lang=eng 
      if /i not "%%o" == "ass" if /i not "%%o" == "srt" set lang=%%o 
      set name=%%n
      set file=%%j
      setlocal ENABLEDELAYEDEXPANSION
      if "!num!" == "2" set subs=!subs! --default-track 0:yes
      set subs=!subs! --language 0:!lang! --track-name "0:!name!" --forced-track 0:no -s 0 -D -A -T --no-global-tags --no-chapters "(" "!file!" ")"
      set islocal=yes
      for /F "delims=" %%v in ("!subs!") DO (    
        endlocal
        set "subs=%%v"
      )
      set /a num=num+1
    )
  )
  setlocal ENABLEDELAYEDEXPANSION
  set order=0:0
  set /a num=num-1
  for /l %%j in (1,1,!num!) do set order=!order!,%%j:0
  for /F "delims=" %%v in ("!order!") DO (    
    endlocal
    set "order=%%v"
  )
  set chaps=
  if exist "%%~ni.xml" set chaps=--chapter-language und --chapters "%%~ni.xml"
  set name=%%i
  set audio=%%~ni.aac

  setlocal ENABLEDELAYEDEXPANSION
  %debug% mkvmerge -o "!outdir!\!name!" --language 0:!vlang! --default-track 0:yes --forced-track 0:no --display-dimensions 0:%dim% -d 0 -A -S -T --no-global-tags --no-chapters "(" "!name!" ")" --language 0:!alang! --default-track 0:yes --forced-track 0:no -a 0 -D -S -T --no-global-tags --no-chapters "(" "!audio!" ")" !subs! --track-order !order! !attachs! !chaps!
  echo.
  endlocal
)

goto :eof
:help
echo Usage: %~n0 [options]
echo Options:
echo   -o ^<outdir^>          Set output path          Default: ..
echo   -a ^<lang^>            Set audio language       Default: jpn
echo   -v ^<lang^>            Set video language       Default: jpn
echo   -r ^<dim^>             Set video resolution     Default: 1280x720
echo   -h                     Show help
echo   -d                     Debug mode