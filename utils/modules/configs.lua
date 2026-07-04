local http = game:GetService("HttpService")
local hub_folder = 'Nightfall/settings'

local System = {}

function System.new()
  if not (isfolder and makefolder) then
    return false
  end

  if not isfolder(hub_folder) then
    makefolder(hub_folder)
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

  local dds
  local file_to_load = `{path}/{name}` or `{hub_folder}/{name}`
  local ok, result = pcall(function()
      return http:JSONDecode(readfile(file_to_load))
    end)

  if ok and result then
    if typeof(result) ~= "table" then
      return false
    else
      dds = result
    end
  end
