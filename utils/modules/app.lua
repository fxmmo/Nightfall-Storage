local service = {}
setmetatable(service, {
    __call = function(self, name: string)
      return self.create(name)
    end
})
service.__index = function(self, k)
  if rawget(service, k) then 
    return rawget(service, k)
  end 

  local _raw = rawget(self, k)
  if _raw ~= nil then 
    return _raw 
  end

  local cdn = rawget(self, "Children")
  if cdn then 
    for _, cd in ipairs(cdn) do 
      if cd.Name == k then 
        return cd 
      end 
    end 
  end 
  
  return 
end

local http = game:GetService("HttpService")

function service.create(name: string)
  local self = setmetatable({}, service)
  self.Name = name
  self.Type = "Folder"
  self.Parent = nil
  self.Children = {}

  if isfolder and makefolder then 
    if not isfolder(name) then
      makefolder(name)
    end
  else
    return false
  end

  return self 
end

function service.mkchild(self, name: string)
  local path = `{self.Name}/{name}`

  local child = setmetatable({}, service)
  child.Name = name
  child.Type = "Folder"
  child.Parent = self 
  child.Children = {}
  
  if isfolder and makefolder then 
    if not isfolder(path) then
      makefolder(path)
    end
  else 
    return false 
  end

  table.insert(self.Children, child)
  return child
end

function service.wrfile(self, name: string, content: string?, json: boolean?)
  local path = `{self.Name}/{name}` 
  local data = content
  
  if writefile then 
    if json then 
      local ok, res = pcall(function()
        return http:JSONEncode(data)
        end)

      if ok and res then
        data = res
      else
        return false, "failed to encode"
      end
    end

    writefile(path, data)
  end

  for _, c in ipairs(self.Children) do 
    if c.Name == name and c.Type == "File" then 
      c.Source = data
      c.Encode = json
      return true, "file already exists"
    end
  end

  local file = setmetatable({}, file)
  file.Name = name
  file.Type = "File"
  file.Parent = self
  file.Source = data or ""
  file.Encode = json or false

  table.insert(self.Children, file)
  return file
end

function service.mkdir(self, paths: {string?})
  for _, path in ipairs(paths) do 
    local parts = string.split(path, "/")
    local crt = self

    for _, part in ipairs(parts) do 
      if part and part ~= "" then 
        local fc = nil 

        if crt.Type == "Folder" and crt.Children then 
          for _, child in ipairs(crt.Children) do 
            if child.Name == part then 
              fc = child 
              break 
            end
          end
        else
          return false, "Failed to create a child inside an object that is not a folder"
        end

        if fc then
          crt = fc 
        else
          crt = crt.mkchild(crt, part)
        end
      end
    end 
  end
  return false
end

local file = {}
file.__index = file 
service.file = file 

function file.read(self)
  if self.Encode then 
    local ok, res = pcall(function()
      return http:JSONDecode(self.Source)
      end)

    if ok and res then 
      return res 
    else
      return false, "failed to decode"
    end
  else 
    return self.Source 
  end
end

function file.add(self, content: string)
  self.Source ..= content
  return true 
end

getgenv().import = function(url: string?, path: string?, name: string?)
  local crt = nil 

  if type(url) == "string" and (url:sub(1, 4) == "http") then 
    local content = game:HttpGet(url)
    local ok, res = pcall(loadstring(content))

    if ok and res then 
      return res, true 
    else
      return false, "Failed to execute code from url"
    end
  end

  if type(path) == "string" and path ~= "" then 
    local parts = string.split(path, "/")
    crt = service 

    for _, part in ipairs(parts) do
      crt = crt[part] 
      if not crt then return false, "The object could not be found" end
    end 
  else
    crt = path 
  end

  if crt and crt.Source then 
    local data = crt.Source 
    if crt.Type == "File" then 
      data = crt.read()
    end
    
    return data 
  end

  if url and crt and name then 
    local ok, res = pcall(function()
      return game:HttpGet(url)
      end)

    if ok and res then 
      local file = crt.wrfile(name, res)
      local data = loadstring(file.Source)
      return data and data()
    end
  end

  if name and crt and crt.Children then 
    for _, cd in ipairs(crt.Children) do 
      if cd.Name == name and cd.Type == "File" and cd.Source then 
        local data = loadstring(cd.Source)
        return data and data()
    end
  end

  return crt, "Parameters not provided"
end

return service