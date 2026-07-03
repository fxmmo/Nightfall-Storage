local Get = {}
Get.__index = Get

local hub_assets = "Nightfall/assets"

function Get:Image(v)
  v = v or {}
  
  local name = v.Name or "image.png"
  local path = v.Path or hub_assets
  local url = v.Url

  local fullpath = path.. "/" ..name or hub_assets.. "/" ..name
  local data = game:HttpGet(url)
  
    warn("'Url' not provided")
    return false
  end

  if not (isfile and isfolder and makefolder and writefile and getcustomasset) then
    warn("Ur exploit ins't supported")
    return false 
  end

  local ok, result = pcall(function()
    if not isfolder("Nightfall") then
        makefolder("Nightfall")
      end

      if not isfolder(path) then
        makefolder(path)
      end

      if not isfile(fullpath) then
        writefile(fullpath, data)
      end

      return getcustomasset(fullpath)
    end)

  if not ok then
    warn("Incorrect or invalid url: " ..tostring(result))
    return false
  end

  return result 
end

return Get
