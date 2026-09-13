local service = {}
service.__index = service

setmetatable(service, {
    __call = function(self, name: string)
      return self.new(name)
    end
})
  
function service.new(name: string)
  if isfolder and makefolder then 
    if not isfolder(name) then 
      makefolder(name)
    end
  end
  
  local self = setmetatable({}, service)
  self.Name = name 
  self.Folder = name 
  self.Children = {}

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
  child.Folder = fullpath
  child.Children = {}

  table.insert(self.Children, child)
  return child
end

function service:Mkdir(paths)
  for _, path in ipairs(paths) do
    local fullpath = `{self.Folder}/{path}`
    local child = string.split(fullpath, "/")
    local part_path = ""
      
    for i, part in ipairs(child) do 
        part_path = `{part_path}{(i > 1 and "/" or "")}{part}`
        self:Mkchild(part_path)
    end
  end
end
  
return service