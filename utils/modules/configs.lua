local http = game:GetService("HttpService")
local hub_folder = 'Nightfall/settings'

local System = {}

function System:Load(file)
  file_to_load = `{hub_folder}/{file}`
  
  