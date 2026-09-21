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

function service:Mkchild(name: string)
  local fullpath = `{self.Folder}/{name}`

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

function service:Wrfile(parent: string, name: string, content: string)
  local fullpath = `{parent}/{name}`

  if isfile and writefile then 
    if not isfile(fullpath) then 
      writefile(fullpath, content or "")
    end
  end

  local file = {}
  file.Name = name
  file.Parent = parent
  file.Source = content or ""

  return file 
end

return service