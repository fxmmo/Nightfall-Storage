--!strict
local app = {}

local _cache = {}

local function log(...)
  local msg = table.pack(...)
  for i = 1, msg.n do 
    warn(`[Debug]: {msg[i]}`)
  end
  
  return false
end

function app:MakeDir(paths)
  for _, path in paths do 
    if isfolder and makefolder then 
      if not isfolder(path) then
        makefolder(path)
        return path 
      end 
    end 
    
  end 
end

function app:Import(src: string, path: string, name: string)
  if not (isfile and writefile and readfile) then 
    return false
  end

  local fullpath = `{path}/{name}`
  if isfile(fullpath) then 
    return loadstring(readfile(fullpath))()
  elseif _cache[src] then 
    return _cache[src]
  end

  local ok, res = pcall(function()
      return game:HttpGet(src)
    end)

  if ok and res then 
    local data = res 
    _cache[src] = data
    
    if path then 
      self:MakeDir({path})
      
      if not isfile(fullpath) then 
        writefile(fullpath, tostring(data))
        return loadstring(data)()
      end
    end
  else
    log("Error while attempting to download", res)
  end
end

return app