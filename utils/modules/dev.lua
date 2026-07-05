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

return Dev