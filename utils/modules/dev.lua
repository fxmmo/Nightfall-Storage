local http = game:GetService("HttpService")
local _cache = {}
local _highlights = {}

local Dev = {}

function Dev:Init(z)
  local path = z.Path
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
    self:Init({
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

function Dev:Import(url)
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
    self:Init({Path = path})
  end

  local ok, result = pcall(function()
    if not isfile(full_path) then
      local data = game:HttpGet(url)
       writefile(full_path, data)
        task.wait(.2)
    end
      
      return getcustomasset(full_path)
  end)

  if ok and result then
    return result
  end

  return url
end

function Dev:GetVideo(obj)
  local name = obj.Name or "video.mp4"
  local path = obj.Path or "Nightfall/assets"
  local url = obj.Url
  local full_path = `{path}/{name}`

  if not (isfolder and isfile and writefile and getcustomasset) then
    return false
  end

  if not isfolder(path) then
    self:Init({Path = path})
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

function Dev:Clock()
    local time = DateTime.now():ToLocalTime()
    local hour = time.Hour

    if hour >= 5 and hour < 12 then
        return "Good morning"
    elseif hour >= 12 and hour < 18 then
        return "Good afternoon"
    else
        return "Good evening"
    end
end

Dev.Visual = {
  Apply = {
    Highlight = function(obj)
      local name = obj.Name 
      local color = obj.Color 
      local target = obj.Target 
      local group = obj.Group 

      local h = _highlights["group"] or target:FindFirstChild(name)

      if not h then 
        h = Instance.new("Highlight")
        h.Name = name 
        h.Parent = target 
        table.insert(_highlights, h)
      end

      h.FillColor = color 
      h.OutlineColor = color 
      h.FillTransparency = obj.Transparency or 0.8
      h.OutlineTransparency = 0 
      h.Adornee = target 
      h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      h.Enabled = true
      return h
    end
  },
  Clear = {
    Highlight = function(group)
      local reg = _highlights[group]
      if not reg then 
        return 
      end

      for _, h in ipairs(reg) do 
        if h then 
          h:Destroy()
        end
      end
      
      table.clear(reg) 
    end
  }
}

return Dev