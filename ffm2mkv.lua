function FileExists(FileName)
  local F = io.open(FileName)
  if F then
    io.close(F)
    return true
  else
    return false
  end
end

function table.empty(t)
  for _, _ in pairs(t) do
    return false
  end
  return true
end

function LoadFFM1(name)
  local Magic, Meta = true, true
  local Chap, Res = {}, {}
  for l in io.lines(name) do
    if Magic then
      if l ~= ";FFMETADATA1" then
        error("Not a FFMETADATA1 file")
      end
      Magic = false
    elseif Meta then
      if l == "[CHAPTER]" then
        Meta = false
      end
    else
      if l == "[CHAPTER]" then
        table.insert(Res, Chap)
        Chap = {}
      else
        k, v = l:match("(%w+)=(.*)")
        Chap[k:lower()] = v
      end
    end
  end
  if not table.empty(Chap) then
    table.insert(Res, Chap)
  end
  return Res
end

function GetTimebase(Timebase)
  local num, denom = Timebase:match("(%d*)/(%d*)")
  return tonumber(num) / tonumber(denom)
end

function ConvertTime(Time, Timebase)
  Time = Time * Timebase
  local H = math.floor(Time / 3600)
  Time = Time % 3600
  local M = math.floor(Time / 60)
  Time = Time % 60
  return string.format("%02d:%02d:%06.3f", H, M, Time)
end

math.randomseed(os.time())

UID = {
  Check = function(Self, UID)
    for i = 0, #Self do
      if Self[i] == UID then
        return false
      end
    end
    return true
  end,
  
  Get = function(Self)
    local Res
    repeat
      Res = math.random(0, 0xFFFFFF)
    until Self:Check(Res)
    table.insert(Self, Res)
    return Res
  end
}

Header = string.format([[<?xml version="1.0"?>
<!-- <!DOCTYPE Chapters SYSTEM "matroskachapters.dtd"> -->
<Chapters>
  <EditionEntry>
    <EditionFlagHidden>0</EditionFlagHidden>
    <EditionFlagDefault>0</EditionFlagDefault>
    <EditionUID>%d</EditionUID>
]], UID:Get())

Chapter = [[    <ChapterAtom>
      <ChapterUID>%d</ChapterUID>
      <ChapterFlagHidden>0</ChapterFlagHidden>
      <ChapterFlagEnabled>1</ChapterFlagEnabled>
      <ChapterTimeStart>%s</ChapterTimeStart>
      <ChapterDisplay>
        <ChapterString>%s</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
]]

Footer = [[  </EditionEntry>
</Chapters>]] 

if not arg[1] then
  print("FFMPEG FFMETADATA1 to mkvToolnix chapters converter")
  print("Usage: ffm2mkv.lua <metadata.txt> [chapters.xml]")
  os.exit()
end

if not FileExists(arg[1]) then
  print("Invalid file specified")
  os.exit()
end

Chaps = LoadFFM1(arg[1])

OutFile = io.open(arg[2] or arg[1]..".xml", "w+")

OutFile:write(Header)

for i, c in ipairs(Chaps) do
  OutFile:write(string.format(Chapter, UID:Get(), ConvertTime(c.start, GetTimebase(c.timebase)), c.title)) 
end

OutFile:write(Footer)
OutFile:close()

print("Done");