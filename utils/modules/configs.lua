local Configs = {}
Configs.__index = Configs

local http = game:GetService("HttpService")
local data = {}

local hub_folder = "Nightfall/settings"

function Configs:Get(key)
  return data[key]
end

function Configs:Set(key, value)
  data[key] = value 
end

function Configs:Load(file)
  local save_file = hub_folder.. "/" ..file
  if not (isfolder and isfile and readfile) then
    warn("Ur exploit isn't supported")
    return false
  end

  if not isfolder(hub_folder) then
    warn("'" ..hub_folder.. "' not found")
    return false
  end

  if not isfile(save_file) then
    warn("'" ..save_file.. "' not found")
    return false 
  end

  local ok, decode = pcall(function()
    return http:JSONDecode(readfile(save_file))
    end)

  if not ok then
    warn("Failed to decode config: " ..tostring(decode))
    return false 
  end

  if type(decode) ~= "Table" then
    warn("Invalid config format")
    return false
  end
  
  data = decode
  return true
end

function Configs:Save(file)
  local save_file = hub_folder.. "/" ..file
  if not (isfolder and makefolder and isfile and writefile) then
    warn("Ur exploit isn't supported")
    return false
  end

  if not isfolder(hub_folder) then
    makefolder(hub_folder)
  end

  local ob, encode = pcall(function()
    return http:JSONEncode(data)
    end)

  if not ob then
    warn("Failed to encode config: " ..tostring(encode))
    return false
  end

  local oc, err = pcall(writefile, save_file, encode)
  if not oc then 
    warn("Failed to write config: " ..tostring(err))
    return false
  end
  
  return true 
end

return Configs