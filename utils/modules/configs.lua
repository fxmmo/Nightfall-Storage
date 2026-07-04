local http = game:GetService("HttpService")
local hub_folder = 'Nightfall/settings'

local System = {}

function System.new(x)
  x = x or {}
  local path = x.Path
  
  if not (isfolder and isfile and makefolder and writefile) then
    return false
  end

  if not isfolder(hub_folder) then
    makefolder(hub_folder)
    return false
  end

  if not isfile(path) then
    writefile(path, "{}")
    return true
  end
end

function System:Load(y)
  y = y or {}
  local name = y.Name 
  local path = y.Path 

  if not (name and path) then
    return false
  end

  if not (isfile and isfolder) then
    return false
  end

  local file_to_load = `{path}/{name}` or `{hub_folder}/{name}`
  local ok, result = pcall(function()
      return http:JSONDecode(readfile(file_to_load))
    end)

  if ok and result then
    if typeof(result) ~= "table" then
      print(`A table está em um formato não compativel, {result}`,)
      return false
    else
      return result
    end
  end
  
  return false
end

return System