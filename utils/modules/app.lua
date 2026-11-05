--!strict
local service = {}
local file = {}
file.__index = file
service.file = file

local http = game:GetService("HttpService")
local roots = {}

local function runSource(src: string): (boolean, any)
    local fn, err = loadstring(src)
    if not fn then return false, err end
    return pcall(fn)
end

local function resolve(root: any, path: string): any
    local node = root
    for part in string.gmatch(path, "[^/]+") do
        local found = nil
        for _, child in ipairs(node.Children or {}) do
            if child.Name == part then
                found = child
                break
            end
        end
        if not found then return nil end
        node = found
    end
    return node
end

local function assetFrom(node: any): (any, any)
    if not getcustomasset then return nil, "getcustomasset unsupported" end
    if node.Type ~= "file" then return nil, "not a file" end
    local ok, res = pcall(getcustomasset, node.Path)
    if not ok then return nil, res end
    return res
end

setmetatable(service, {
    __call = function(_, name: string)
        return service.create(name)
    end,
})

service.__index = function(self, k)
    if rawget(service, k) then
        return rawget(service, k)
    end
    local raw = rawget(self, k)
    if raw ~= nil then
        return raw
    end
    local children = rawget(self, "Children")
    if children then
        for _, child in ipairs(children) do
            if child.Name == k then
                return child
            end
        end
    end
    return nil
end

function file.read(self: any): (any, any)
    if not self then return nil, "no file" end
    if (self.Source == nil or self.Source == "") and isfile and readfile and isfile(self.Path) then
        local ok, res = pcall(readfile, self.Path)
        if not ok then return nil, res end
        self.Source = res
    end
    if self.Type ~= "file" or not self.Source then return nil, "no source" end
    if self.Encode then
        local ok, res = pcall(http.JSONDecode, http, self.Source)
        if not ok then return nil, res end
        return res
    end
    return self.Source
end

function file.add(self: any, content: string): boolean
    self.Source = (self.Source or "") .. content
    return true
end

function service.create(name: string): (any, any)
    if roots[name] then return roots[name] end
    if not (isfolder and makefolder) then return nil, "filesystem unsupported" end
    local self = setmetatable({}, service)
    self.Name = name
    self.Path = name
    self.Type = "folder"
    self.Parent = nil
    self.Children = {}
    if not isfolder(name) then makefolder(name) end
    roots[name] = self
    return self
end

function service.mkchild(self: any, name: string): (any, any)
    if not (isfolder and makefolder) then return nil, "filesystem unsupported" end
    local path = self.Path .. "/" .. name
    local child = setmetatable({}, service)
    child.Name = name
    child.Path = path
    child.Type = "folder"
    child.Parent = self
    child.Children = {}
    if not isfolder(path) then makefolder(path) end
    table.insert(self.Children, child)
    return child
end

function service.wrfile(self: any, name: string, content: any, json: boolean?): (any, any)
    local path = self.Path .. "/" .. name
    local data = content
    if json then
        local ok, res = pcall(http.JSONEncode, http, content)
        if not ok then return nil, res end
        data = res
    end
    if writefile then
        local ok, res = pcall(writefile, path, data)
        if not ok then return nil, res end
    end
    for _, c in ipairs(self.Children) do
        if c.Name == name and c.Type == "file" then
            c.Source = data
            c.Encode = json or false
            return c
        end
    end
    local newFile = setmetatable({}, file)
    newFile.Name = name
    newFile.Path = path
    newFile.Type = "file"
    newFile.Parent = self
    newFile.Source = data or ""
    newFile.Encode = json or false
    table.insert(self.Children, newFile)
    return newFile
end

function service.mkdir(self: any, paths: {string}): (boolean, any)
    for _, path in ipairs(paths) do
        local node: any = self
        for part in string.gmatch(path, "[^/]+") do
            if node.Type ~= "folder" then
                return false, "parent is not a folder"
            end
            local found = nil
            for _, child in ipairs(node.Children) do
                if child.Name == part then
                    found = child
                    break
                end
            end
            if not found then
                local err
                found, err = node:mkchild(part)
                if not found then return false, err end
            end
            node = found
        end
    end
    return true, nil
end

getgenv().import = function(url: string?, path: string?, name: string?, asset: boolean?): any
    local crt: any = nil

    if type(path) == "string" and path ~= "" then
        local rootName = string.match(path, "^[^/]+")
        local root, err = service.create(rootName)
        if not root then return nil, err end
        local rest = string.match(path, "^[^/]+/(.+)$")
        if rest then
            local okDir, errDir = root:mkdir({ rest })
            if not okDir then return nil, errDir end
            crt = resolve(root, rest)
            if not crt then return nil, "path not found" end
        else
            crt = root
        end
    else
        crt = path
    end

    if url and crt and name then
        local ok, res = pcall(game.HttpGet, game, url)
        if not ok then return nil, res end
        local f, err = crt:wrfile(name, res)
        if not f then return nil, err end
        if asset then return assetFrom(f) end
        local okRun, out = runSource(f.Source)
        if not okRun then return nil, out end
        return out
    end

    if type(url) == "string" and url:sub(1, 4) == "http" then
        local ok, res = pcall(game.HttpGet, game, url)
        if not ok then return nil, res end
        if asset then return nil, "asset import needs a path and name" end
        local okRun, out = runSource(res)
        if not okRun then return nil, out end
        return out
    end

    if crt and crt.Type == "file" then
        if asset then return assetFrom(crt) end
        return crt:read()
    end

    if name and crt and crt.Children then
        for _, child in ipairs(crt.Children) do
            if child.Name == name and child.Type == "file" then
                if asset then return assetFrom(child) end
                local data, err = child:read()
                if not data then return nil, err end
                if type(data) ~= "string" then return data end
                local okRun, out = runSource(data)
                if not okRun then return nil, out end
                return out
            end
        end
        return nil, "not found"
    end

    return crt
end

return service