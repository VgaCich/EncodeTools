function FileExists(FileName)
  local F = io.open(FileName)
  if F then
    io.close(F)
    return true
  else
    return false
  end
end

function Execute(Cmd)
  local Output, Results = io.popen(Cmd), {}
  for Line in Output:lines() do
    table.insert(Results, Line)
  end
  io.close(Output)
  return Results
end

function FindLine(Lines, Line, From)
  while From < #Lines do
    if Lines[From]:find("^[%s%+|]*" .. Line .. ".*$") then
      return From
    else
      From = From + 1
    end
  end
end

function GetParam(Lines, ParamName, From, To)
  To = FindLine(Lines, To, From) or #Lines
  From = FindLine(Lines, ParamName .. ":", From)
  if From and (From <= To) then
    return Lines[From]:match("^[%s%+|]*" .. ParamName .. ":%s*(.-)%s*$")
  end
end

Names = {}
function Names:GetUnique(Name)
  if self[Name] then
    self[Name] = self[Name] + 1
    Name = Name .. "[" .. self[Name] .. "]"
  end
  self[Name] = 0
  return Name
end

function RemoveForbiddenChars(s)
  return (s:gsub('[%/%\\%:%*%?%"%<%>%|]', "_"))
end

print("MKV Subtitles Extractor")
print("Usage: lua "..arg[0].." <MKV file> [output dir]")

File = arg[1] or ""
Dir = arg[2] or ""
if (#Dir > 0) and (Dir[-1] ~= "\\") then Dir = Dir .. "\\" end

if not FileExists(File) then
  print("Invalid or no file specified")
  os.exit()
end

FileInfo = Execute("mkvinfo --ui-language en \"" .. File .. "\"")
FileInfo.FindLine = FindLine
FileInfo.GetParam = GetParam
Tracks = {}
CurLine = FileInfo:FindLine("Segment tracks", 1)
while CurLine and (CurLine <= #FileInfo) do
  CurLine = FileInfo:FindLine("A track", CurLine+1)
  if CurLine then
    table.insert(Tracks, {
      Name = FileInfo:GetParam("Name", CurLine+1, "A track");
      Number = FileInfo:GetParam("Track number", CurLine+1, "A track");
      Type = FileInfo:GetParam("Track type", CurLine+1, "A track");
      UID = FileInfo:GetParam("Track UID", CurLine+1, "A track");
      CodecID = FileInfo:GetParam("Codec ID", CurLine+1, "A track");
    })
  end
end

SubtitleExt = {
  ["S_TEXT/UTF8"] = ".srt";
  ["S_TEXT/SSA"]  = ".ssa";
  ["S_TEXT/ASS"]  = ".ass";
  ["S_VOBSUB"]    = ".idx";
  ["S_HDMV/PGS"]  = ".sup";
}

print(File)
BaseName = File:match(".-([^\\/]-)%.?[^%.\\/]*$") .. "."
for i, Track in ipairs(Tracks) do
  if Track.Type == "subtitles" then
    Cmd = Cmd or "mkvextract tracks \"" .. File .. "\" "
    local TID = Track.Number:match(".*mkvextract:%s*(%d*).-")
    local Name = Names:GetUnique(RemoveForbiddenChars(Track.Name or tostring(i))) .. (SubtitleExt[Track.CodecID] or ".sub")
    Cmd = Cmd .. "\"" .. TID .. ":" .. Dir .. BaseName .. Name .. "\" "
  end
end

if Cmd then
  os.execute(Cmd)
else
  print("No subtitles found")
end