local Get = {}
Get.__index = Get

local hub_assets = "Nightfall/assets"

function Get:Image(v)
  v = v or {}
  
  local name = v.Name or "image.png"
  local path = v.Path or hub_assets
  local url = v.Url
  local fullpath = path.. "/" ..name
  
  if not url or type(url) ~= "string" then
    warn("'Url' not provided")
    return false
  end

  local data
  local ok, err = pcall(function()
      return game:HttpGet(url)
    end)

  if ok and err then
    data = err
  else
    warn("Failed to load 'data': " ..tostring(err))
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

  if ok and result then
    return result
  end

  return url
end

function Get:Video(v)
  v = v or {}

  local name = v.Name
  local path = v.Path
  local url = v.Url

  if not url then
    warn("'Url' not provided")
    return false
  end
  --I'll finish this later
end
return Get
