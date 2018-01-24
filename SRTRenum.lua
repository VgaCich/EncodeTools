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

FileName = arg[1] or ""

if not FileExists(FileName) then
  print("Invalid or no file specified")
  print("Usage: lua "..arg[0].." <SRT file>")
  os.exit()
end

script = CreateList();

for line in io.lines(FileName) do
  script:insert(line)
end

cnt = 1

for i, line in ipairs(script) do
  if line:match("^%d+$") then
    script[i] = tostring(cnt)
    cnt = cnt + 1
  end
end

file = io.open(FileName, "w")
for i, line in ipairs(script) do
  file:write(line .. "\n")
end

print("Done.")