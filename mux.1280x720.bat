@echo off
setlocal ENABLEEXTENSIONS

if "%vlang%"=="" set vlang=jpn
if "%alang%"=="" set alang=jpn
if "%outdir%"=="" set outdir=..
set debug=
if "%1"=="-d" set debug=echo

for /F "tokens=2 delims=." %%d in ("%~n0") do set dim=%%d
if "%dim%" == "" goto :eof

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