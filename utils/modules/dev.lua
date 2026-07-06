local http = game:GetService("HttpService")

local Dev = {}

function Dev:New(file_configs)
  local name = file_configs.Name 
  local path = file_configs.Path 
  
  local full_path = `{path}/{name}`
  
  if not (isfolder and isfile and makefolder and writefile) then
    return false
  end

  local save_file = full_path

  if not isfolder(save_file) then
    makefolder(path)
    if not isfile(name) then
      writefile(full_path, "{}")
    end
  end
  
  return full_path
end

function Dev:Save(x)
  local name = x.Name 
  local path = x.Path
  local data = x.Data 

  local full_path = `{path}/{name}`

  if not (isfolder and isfile and writefile) then
    return false
  end
  
  if not isfolder(path) and not isfile(name) then
    Dev:New({
        Name = name,
        Path = path
    })
  else
    local dds 
    local ok, result = pcall(function()
        return http:JSONEncode(data)
      end)

    if ok and result then
      dds = result 
      writefile(full_path, dds)
    end
  end
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
  
return Dev