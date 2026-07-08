local http = game:GetService("HttpService")
local _cache = {}

local Dev = {}

function Dev:New(file_configs)
  local path = file_configs.Path 
  
  if not (isfolder and makefolder) then
    return false
  end

  if not isfolder(path) then
    makefolder(path)
  end
  
  return path
end

function Dev:Save(x)
  local name = x.Name 
  local path = x.Path
  local data = x.Data 

  local full_path = `{path}/{name}`

  if not (isfolder and isfile and writefile) then
    return false
  end
  
  if not isfolder(path) and not isfile(full_path) then
    self:New({
        Path = path
    })
    return true
  end
  
  local dds 
  local ok, result = pcall(function()
      return http:JSONEncode(data)
    end)

  if ok and result then
    dds = result 
    writefile(full_path, dds)
  end

  return false
end

function Dev:Load(y)
  local name = y.Name 
  local path = y.Path 

  local full_path = `{path}/{name}`

  if not (isfolder and isfile and readfile) then
    return false
  end

  if isfolder(path) and isfile(full_path) then
    local sts
    local ok, result = pcall(function()
      return http:JSONDecode(readfile(full_path))
    end)

    if ok and result then
      sts = result
      return sts
    end
  end
end

function Dev:Require(url)
  if _cache[url] then 
    return _cache[url]
  end
  
  local ok, result = pcall(function()
      return loadstring(game:HttpGet(url))()
    end)

  if ok and result then
    _cache[url] = result
    return result 
  end

  return nil
end

function Dev:GetImage(image)
  local name = image.Name
  local path = image.Path 
  local url = image.Url 

  if not (isfolder and isfile and writefile) then 
    return false
  end

  if not isfolder(path) then
    Dev:New({
        Path = path
      })
  end

  local img
  local ok, result = pcall(function()
      return loadstring(game:HttpGet(url))()
    end)

  if ok and result then
    writefile(`{path}{name}`, img)
    return true 
  end

  if not ok then
    readfile(`{path}{name}`)
    return true
  end
  
  return nil
end
  
return Dev