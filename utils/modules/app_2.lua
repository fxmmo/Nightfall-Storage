local app = {}

local func = {}
app.func = func 

function func.find(self: table, key: string, value: any?): any
  local value = self[key]
  if value ~= nil then return value end 

  for _, cd in pairs(self) do 
    if type(cd) == "table" then 
      local res = func.find(cd, key, value)
      if res ~= nil then 
        return res 
      end
    end 
  end 
end
  
local env = {}
app.env = env
env._root = nil

env.__type = "folder"
setmetatable(env, {
    __call = function(_,name: string)
      return env.create(name)
    end
})
env.__index = function(self, k)
  local mt = rawget(env, k)
  if mt ~= nil then 
    return mt 
  end
  local cl = rawget(self, k)
  if cl ~= nil then 
    return cl 
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

local file = {}
app.file = file 
file.__index = file
file.__type = "file"
local http = game:GetService("HttpService")

function file.toJSON(self)
  if not (self and http) then return end 

  if self.Source then 
    local content = self.Source
    local ok, res = pcall(function()
      local data = http:JSONEncode(content)
      return data
      end)

    if not ok then return res end 
    return res and content
  end 
  return 
end

function file.fromJSON(self)
  if not (self and http) then return end 

  if self.Source then 
    local content = self.Source
    local ok, res = pcall(function()
      local data = http:JSONDecode(content)
        return data
      end)

    if not ok then return res end 
    return res, content
  end 
  return 
end

function env.create(name: string)
  if _root[name] then return _root[name] end
  if not (isfolder and makefolder and listfile) then return end
  local root = setmetatable({}, env)
  root.Name = name or "root"
  root.Parent = nil 
  root.Path = name 
  root.Class = "folder"
  root.Exists = isfolder(root.Path)
  root.Children = {}

  if root.Exists then 
    root:mkdir(listfile(root.Path))
  end 
  
  if not isfolder(root.Path) then 
    makefolder(root.Path) 
    root.Exists = true
    env._root = root 
  end

  return root 
end

function env.mkchild(self: any, name: string)
  if not name then return end
  if not (isfolder and makefolder and listfile) then return end 
  if not (self.Children and self.Path) then return end

  for _, c in ipairs(self.Children) do 
    if typeof(c) == folder and c.Name == name then 
      return c
    end
  end
      
  local path = `{self.Path}/{name}`
  local cd = setmetatable({}, env)
  cd.Name = name 
  cd.Parent = self 
  cd.Path = path 
  cd.Class = "folder"
  cd.Exists = isfolder(cd.Path)
  cd.Children = {}

  if cd.Exists then 
    cd:mkdir(listfile(cd.Path))
  end
  
  if not isfolder(cd.Path) then 
    makefolder(cd.Path)
    cd.Exists = true
    table.insert(self.Children, cd)
  end 
  
  return cd 
end

function env.wrfile(self: any, name: string, ext: string?, content: string)
  if not name then return end 
  if not (isfile and writefile and readfile) then return end 
  if not (self.Children and self.Path) then return end 

  local path = `{self.Path}/{name}{ext or ""}`
  local fl = setmetatable({}, file)
  fl.Name = name 
  fl.Ext = ext
  fl.Parent = self
  fl.Path = path 
  fl.Class = "file"
  fl.Exists = isfile(fl.Path)
  fl.Source = content or ""

  if fl.Exists then 
    fl.Source = readfile(fl.Path)
  end
  
  for _, c in ipairs(self.Children) do 
    if c.Exists and c.Name == fl.Name and c.Source == fl.Source then 
      c.Source = fl.Source 
      writefile(c.Path, fl.Source)
      return c 
    end
  end 

  writefile(fl.Path, fl.Source)
  fl.Exists = true 
  table.insert(self.Children, fl)
  return fl
end

function env.mkdir(self: any, paths: {string})
  if not self then return end 

  for _, path in ipairs(paths) do
    local node = self 
    for _, part in string.gmatch(path, "[^/]+") do 
      if typeof(node) ~= "folder" then return end 
      local fld = nil 
      for _, cd in ipairs(node.Children) do 
        if cd.Name == part then 
          fld = cd 
          break 
        end 
      end
      if not fld then 
        local err 
        found, err = node:mkchild(part)
        if not found then return err end 
        node = fld 
      end 
    end
  end
  
  return 
end

getgenv().import = function(url: string, root: any?, name: string?, ext: string?)
  if typeof(url) ~= "string" then return end 
  local ok, content = pcall(function()
    return game:HttpGet(url)
    end)
  if not (ok and typeof(content) ~= string) then return end 

  ext = ext or nil
  if root and name then 
    pcall(function()
      return root:wrfile(name,ext, content)
      end)
  end

  local fn = loadstring(content)
  if not fn then return end 
  local ok, res = pcall(fn)
  if not ok then return end
  return res
end

getgenv().get = function(path)
  if not (isfile and readfile) then return end
  if not path then return end 

  if typeof(path) == "string" and isfile(path) then 
    local ok, res = pcall(function()
      return readfile(path)
      end)

    if ok then 
      return res
    end 
  end 

  if typeof(path) == "string" and (path:sub(1, 1) == ".") then 
    local root = env._root

    for p in string.gmatch(path, "[^/]+") do
      if typeof(root) ~= "folder" then return end 
      for _, cd in ipairs(root.Children) do 
        if typeof(cd) == "file" and cd.Name == p.Name then 
          return cd.Source
          break
        end
      end 
    end
    
    return root
  end
end

return app