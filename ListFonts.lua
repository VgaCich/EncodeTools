function FileExists(FileName)
  local F = io.open(FileName)
  if F then
    io.close(F)
    return true
  else
    return false
  end
end


FileName = arg[1] or ""

if not FileExists(FileName) then
  print("Invalid or no file specified")
  print("Usage: lua "..arg[0].." <SSA/ASS file>")
  os.exit()
end

fonts = {};

function fonts:add(font)
  for _, l in ipairs(self) do
    if l == font then
      return
    end
  end
  table.insert(self, font)
end

for line in io.lines(FileName) do
  local font = line:match("^%s*Style%s*:%s*[^,]*,%s*([^,]*).*$")-- or line:match("^%s*Dialogue%s*:.*\\fn([^\\}]*)[\\}].*")
  if font then
    fonts:add(font)
  elseif line:match("^%s*Dialogue%s*:.*\\fn") then
    for font in line:gmatch("\\fn([^\\}]*)[\\}]") do
      fonts:add(font)
    end
  end
end

for _, l in ipairs(fonts) do
  print(l)
end