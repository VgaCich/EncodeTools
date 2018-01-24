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

function GetParam(Lines, ParamName, To)
  local From = Lines.CurLine + 1
  To = FindLine(Lines, To, From) or #Lines
  From = FindLine(Lines, ParamName .. ":", From)
  if From and (From <= To) then
    return Lines[From]:match("^[%s%+|]*" .. ParamName .. ":%s*(.-)%s*$")
  end
end

File = arg[1] or ""

if not FileExists(File) then
  print("Invalid or no file specified")
  print("Usage: lua "..arg[0].." <MKV file>")
  os.exit()
end

FileInfo = Execute("mkvinfo --ui-language en \"" .. File .. "\"")
FileInfo.FindLine = FindLine
FileInfo.GetParam = GetParam
Tracks = {}
FileInfo.CurLine = FileInfo:FindLine("Segment tracks", 1)
while FileInfo.CurLine and (FileInfo.CurLine <= #FileInfo) do
  FileInfo.CurLine = FileInfo:FindLine("A track", FileInfo.CurLine + 1)
  if FileInfo.CurLine then
    table.insert(Tracks, {
      Name = FileInfo:GetParam("Name", "A track") or "";
      Number = FileInfo:GetParam("Track number", "A track"):match("(%d+).*") or "";
      Type = FileInfo:GetParam("Track type", "A track") or "";
      UID = FileInfo:GetParam("Track UID", "A track") or "";
      Language = FileInfo:GetParam("Language", "A track") or "";
      Codec = FileInfo:GetParam("Codec ID", "A track") or "";
    })
  end
end

print(File .. ":")
for _, Track in ipairs(Tracks) do
  print("Track #" .. Track.Number .. ": Name=" .. Track.Name .. "; Lang=" .. Track.Language .. "; Type=" .. Track.Type)
end
print()