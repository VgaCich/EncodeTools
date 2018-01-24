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

function GetParam(Lines, ParamName, From)
  From = FindLine(Lines, ParamName .. ":", From)
  if From then
    return Lines[From]:match("^[%s%+|]*" .. ParamName .. ":%s*(.-)%s*$")
  else
    return ""
  end
end

if not arg[1] then
  print("MKV Attachments Lister")
  print("Usage: lua "..arg[0].." <MKV file>")
  os.exit()
end

File = arg[1]

if not FileExists(File) then
  print("Invalid file specified")
  os.exit()
end

FileInfo = Execute("mkvinfo --ui-language en \"" .. File .. "\"")
FileInfo.FindLine = FindLine
FileInfo.GetParam = GetParam
Attachments = {}
CurLine = FileInfo:FindLine("Attachments", 1)
while CurLine and (CurLine <= #FileInfo) do
  CurLine = FileInfo:FindLine("Attached", CurLine+1)
  if CurLine then
    table.insert(Attachments, {Name = FileInfo:GetParam("File name", CurLine); ID = FileInfo:GetParam("File UID", CurLine)})
  end
end

print(File .. ":")
for i, Attach in ipairs(Attachments) do
  print("Attachment #" .. i .. ":" .. Attach.Name .. " (UID: " .. Attach.ID .. ")")
end
print();