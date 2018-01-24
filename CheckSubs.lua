function FileExists(FileName)
  local F = io.open(FileName)
  if F then
    io.close(F)
    return true
  else
    return false
  end
end

function CreateList()
  return setmetatable({}, {__index = table})
end

function ExtractFileExt(FileName)
  for i = FileName:len(), 1, -1 do
    if FileName:sub(i, i) == "." then
      return FileName:sub(i)
    end
  end
end

function LoadSSA(File)
  local Result = CreateList()
  for Line in File:lines() do
    Start, End, Text = Line:match("Dialogue:%s*%d*,(.-),(.-),.-,.-,.-,.-,.-,.-,(.*)")
    if Text then
      local SubLines = CreateList()
      SubLines.TimeStamp = Start .. " --> "..End
      for SubLine in Text:gmatch("([^\\]+)\\?N?") do
        SubLines:insert(SubLine)
      end
      Result:insert(SubLines)
    end    
  end
  return Result
end

function LoadSRT(File)
  local Result = CreateList()
  local SubLines = false
  for Line in File:lines() do
    if SubLines then
      if Line == "" then
        Result:insert(SubLines)
        SubLines = false
      else
        SubLines:insert(Line)
      end
    else
      local TimeStamp = Line:match("^%d+:%d+:%d+,%d+%s%-%->%s%d+:%d+:%d+,%d+$")
      if TimeStamp then
        SubLines = CreateList()
        SubLines.TimeStamp = TimeStamp
      end
    end
  end
  return Result
end

FileName = arg[1] or ""

if not FileExists(FileName) then
  print("Invalid or no file specified")
  print("Usage: lua "..arg[0].." <subtitle file>")
  os.exit()
end

File = io.open(FileName)

if (ExtractFileExt(FileName) == ".ssa") or (ExtractFileExt(FileName) == ".ass") then
  Subs = LoadSSA(File)
elseif ExtractFileExt(FileName) == ".srt" then
  Subs = LoadSRT(File)
else
  print("Unknown subtitle format")
  os.exit()
end

print("Intersecting messages in " .. FileName .. ":")

for i = 1, #Subs-1 do
  local Mark = false
  for _, l1 in ipairs(Subs[i]) do
    for _, l2 in ipairs(Subs[i+1]) do
      if l1 == l2 then
        Mark = true
      end
    end
  end
  if Mark then
    print(Subs[i].TimeStamp, Subs[i+1].TimeStamp)
  end
end

print()