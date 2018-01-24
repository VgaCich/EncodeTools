@echo off
setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

for /F "tokens=2 delims=." %%d in ("%~n0") do set dim=%%d
if "%dim%" == "" goto :eof

for %%i in (*.mkv) do (
  set attachs=
  for %%j in ("%%~ni\*") do (
    set attachs=!attachs! --attachment-mime-type "application/x-truetype-font" --attachment-name "%%~nxj" --attach-file "%%~j"
  )
  set subs=
  set num=2
  set order=0:0,1:0
  for %%j in ("%%~ni.*.ass") do (
    for /F "tokens=2 delims=." %%n in ("%%~j") do (
      if "!num!" == "2" set subs=!subs! --default-track 0:yes 
      set subs=!subs! --language 0:eng --track-name "0:%%n" --forced-track 0:no -s 0 -D -A -T --no-global-tags --no-chapters "(" "%%~ni.%%n.ass" ")"
      set order=!order!,!num!:0
      set /a num=num+1
    )
  )
  set chaps=
  if exist "%%~ni.xml" set chaps=--chapter-language und --chapters "%%~ni.xml"
  
  mkvmerge -o "..\%%i" --language 0:jpn --default-track 0:yes --forced-track 0:no --display-dimensions 0:%dim% -d 0 -A -S -T --no-global-tags --no-chapters "(" "%%i" ")" --language 0:jpn --default-track 0:yes --forced-track 0:no -a 0 -D -S -T --no-global-tags --no-chapters "(" "%%~ni.aac" ")" !subs! --track-order !order! !attachs! !chaps!
)