local http = game:GetService("HttpService")
local _cache = {}

local Dev = {}

function Dev:Int(file_configs)
  local path = file_configs.Path
  
  if not (isfolder and makefolder) then
    return false
  end

  if not isfolder(path) then 
    makefolder(path)
  end
    
  return true
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
    self:Int({
        Path = path
    })
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
  local name = image.Name or "image.png"
  local path = image.Path or "Nightfall/assets"
  local url = image.Url
  local full_path = `{path}/{name}`

  if not url then
    return false
  end

  if not (isfolder and isfile and writefile and getcustomasset) then
    return false
  end

  if not isfolder(path) then
    self:Int({Path = path})
  end

  local ok, result = pcall(function()
    if not isfile(full_path) then
      local data = game:HttpGet(url)
      writefile(full_path, data)
    end
    return getcustomasset(full_path)
  end)

  if ok and result then
    return result
  end

  return url
end

function Dev:GetVideo(video)
  local name = video.Name or "video.mp4"
  local path = video.Path or "Nightfall/assets"
  local url = video.Url
  local full_path = `{path}/{name}`

  if not (isfolder and isfile and writefile and getcustomasset) then
    return false
  end

  if not isfolder(path) then
    self:Int({Path = path})
  end

  local ok, result = pcall(function()
    if not isfile(full_path) then
      if not url then
        return false
      end
      local data = game:HttpGet(url)
      writefile(full_path, data)
    end
    return getcustomasset(full_path)
  end)

  if ok and result then
    return result
  end

  if not url then
    return false
  end

  return url
end

return Dev