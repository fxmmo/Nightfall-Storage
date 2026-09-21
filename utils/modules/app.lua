local service = {}
service.__index = service

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

function service:Mkchild(parent: string, name: string)
  local fullpath = `{parent}/{name}`
  
  if isfolder and makefolder then 
    if not isfolder(fullpath) then 
      makefolder(fullpath)
    end
  end

  local child = setmetatable({}, service)
  child.Name = name 
  child.Parent = parent
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
        local exists = false 
        for _, child in ipairs(current.Children) do 
          if child.Name == part then 
            current = child 
            exists = true 
            break
          end
        end

        if not exists then 
          current = current:Mkchild(part)
        end
      end
    end
  end
end

function service:Wrfile(parent: string, name: string, content: string)
  local fullpath = `{parent}/{name}`

  if isfile and writefile then 
    if not isfile(fullpath) then 
      writefile(fullpath, content)
    end
  end

  local file = {}
  file.Name = name
  file.Parent = parent
  file.Source = readfile(fullpath)

  return file 
end

return service