local service = {}
service.__index = function(self, key)
  if rawget(service, key) then 
    return rawget(service, key)
  end

  local rawValue = rawget(self, key)
  if rawValue ~= nil then 
    return rawValue 
  end

  local children = rawget(self, "Children")
  if children then 
    for _, child in ipairs(children) do 
      if child.Name == key then 
        return child 
      end
    end
  end

  return
end

setmetatable(service, {
    __call = function(self, name: string)
      return self.new(name)
    end
})

function service.new(name: string)
  local self = setmetatable({}, service)
  self.Name = name 
  self.Folder = name
  self.Children = {}

  if isfolder and makefolder then 
    if not isfolder(name) then 
      makefolder(name)
    end
  end

  return self 
end

function service:Mkchild(name: string)
  local fullpath = `{self.Folder}/{name}`

  if isfolder and makefolder then 
    if not isfolder(fullpath) then 
      makefolder(fullpath)
    end
  end

  local child = setmetatable({}, service)
  child.Name = name 
  child.Parent = self
  child.Folder = fullpath
  child.Children = {}

  table.insert(self.Children, child)
  return child
end

function service:Mkdir(paths: {string})
  for _, path in ipairs(paths) do 
    local parts = string.split(path, "/")
    local current = self 

    for _, part in ipairs(parts) do 
      if part ~= "" then 
        local foundChild = nil 

        if current.Children then 
          for _, child in ipairs(current.Children) do 
            if child.Name == part then 
              foundChild = child 
              break 
            end
          end
        end

        if foundChild then 
          current = foundChild 
        else
          current = current:Mkchild(part)
        end
      end
    end
  end
end

function service:Wrfile(name: string, content: string)
  local fullpath = `{self.Folder}/{name}`

  if isfile and writefile then 
    if not isfile(fullpath) then 
      writefile(fullpath, content or "")
    end
  end

  local file = {}
  file.Name = name
  file.Parent = self
  file.Source = content or ""

  table.insert(self.Children, file)
  return file 
end
  
return service

function import(path, url: string?, name: string?)
  if not path and url then 
    return loadstring(game:HttpGet(url))()
  end
  
  local current = nil
  
  if type(path) == "string" then 
    local parts = string.split(path, "/")
    current = service
    
    for _, part in ipairs(parts) do 
      current = current[part]
      if not current then return end 
    end
  else
    current = path
  end

  if path and path.Source then 
    return path.Source
  elseif current.Source then 
    return current.Source 
  end
  
  if name and current.Children then 
    for _, child in ipairs(current.Children) do
      if child.Name == name and child.Source then
        return child.Source
      end
    end
  end
        
  if url and name then 
    local ok, res = pcall(function()
        return game:HttpGet(url)
      end)

    if ok and res then 
      local file = current:Wrfile(name, res)
      return file.Source
    else 
      return 
    end
  end 

  return current
end