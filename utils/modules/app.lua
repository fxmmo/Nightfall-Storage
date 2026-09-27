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

function service:Find(path: string)
  local current = self 

  for _, part in ipairs(string.split(path, "/")) do 
    if part ~= "" then 
      local nextChild = nil 

      for _, child in ipairs(current.Children) do 
        if child.Name == part then
          nextChild = child
          break 
        end
      end

      if not nextChild then 
        return nil 
      end

      current = nextChild
    end
  end
  return current
end

function service:Resolve(path: string)
  local current = self 

  for _, part in ipairs(string.split(path, "/")) do
    if part ~= "" then 
      local foundChild = nil 

      for _, child in ipairs(current.Children) do 
        if child.Name == part then 
          foundChild = child 
          break
        end
      end

      current = foundChild or self:Mkchild(part)
    end
  end
  return current
end
      
function service:RunSource(source: string)
  if type(source) ~= "string" or source == "" then 
    return nil 
  end

  local ok, res = pcall(loadstring(source))
  if not ok then 
    return nil, res
  end 

  return res 
end

getgenv().import = function(path, url: string?, name: string?)
  local current = service

  if type(path) == "string" and path ~= "" then 
    current = service:Resolve(path)
    if not current then return nil, "invalid path" end
  end

  if url and name then 
    local ok, res = pcall(function()
      return game:HttpGet(url)
      end)

    if not ok and type(res) ~= "string" then 
      return nil
    end

    local file = current:Wrfile(name, res)
    local result, err = current:RunSource(res)
    if not result and err then 
      return nil, err
    end
    return result
  end

  if name and current and current.Children then 
    for _, child in ipairs(current.Children) do
      if child.Name == name and child.Source then 
        local result, err = current:RunSource(child.Source)
        if not result and err then 
          return nil, err
        end
        return result
      end
    end
  end

  if current and current.Source then 
    local result, err = current:RunSource(current.Source)
    if not result and err then 
      return nil, err
    end
    return result
  end

  if type(path) == "string" and path:sub(1, 4) == "http" then 
    local ok, content = pcall(function()
      return game:HttpGet(path)
    end)

    if not ok or type(content) ~= "string" then 
      return nil, "failed  o fetch url"
    end

    local result, err = current:RunSource(content)
    if not result and err then 
      return nil, err
    end
    return result
  end

  return current
end 

return service