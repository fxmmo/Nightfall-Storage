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

