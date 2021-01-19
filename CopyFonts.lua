--[[
Copies fonts to per-episode folders

Fonts list: list of per-episode entries
<<<
Episode title
Font name 1
Font name 2
...
<empty line>
>>>
   
Prepare with command:
del fonts.txt && for %i in (*.ass) do @echo %~ni>>fonts.txt && ListFonts.lua "%i">>fonts.txt && echo.>>fonts.txt

Fonts map: list of per-font entries
<<<
Font name
font filename 1
font filename 2
...
<empty line>
>>>   
]]

function FileExists(FileName)
  local F = io.open(FileName)
  if F then
    io.close(F)
    return true
  else
    return false
  end
end

function Trim(s)
  return s:match("^%s*(.-)%s*$")
end

function table.empty(t)
  for _, _ in pairs(t) do
    return false
  end
  return true
end

function LoadList(Name)
  local Res, Item, Title = {}, {}, true
  for l in io.lines(Name) do
    if Trim(l) == "" then
      if not table.empty(Item) then
        table.insert(Res, Item)
        Item = {}
      end
      Title = true
    else
      if Title then
        Item.Title = Trim(l)
        Title = false
      else
        table.insert(Item, Trim(l))
      end
    end
  end
  if not table.empty(Item) then
    table.insert(Res, Item)
  end
  return Res
end

function FindItem(List, Title)
  Title = Title:lower()
  for _, Item in ipairs(List) do
    if Item.Title:lower() == Title then
      return Item
    end
  end
  return nil
end

if not arg[1] then
  print("Fonts copier")
  print("Usage: CopyFonts.lua <fonts list> <fonts map>")
  os.exit()
end

if not FileExists(arg[1]) or not FileExists(arg[2] or "") then
  print("Invalid file(s) specified")
  os.exit()
end

Fonts = LoadList(arg[1])
Map = LoadList(arg[2])

for i, Item in ipairs(Fonts) do
  print(Item.Title)
  os.execute('md "' .. Item.Title ..'"')
  for _, Font in ipairs(Item) do
    print(Font)
    local Files = FindItem(Map, Font)
    if Files then
      for _, File in ipairs(Files) do
        os.execute('copy "' .. File .. '" "' .. Item.Title .. '"') 
      end
    end
  end
  print()
end

print("Done")