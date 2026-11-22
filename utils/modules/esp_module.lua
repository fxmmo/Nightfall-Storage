local cloneref = cloneref or function(object)
  return object
end

local players = cloneref(game:GetService("Players"))
local run = cloneref(game:GetService("RunService"))
local uis = cloneref(game:GetService("UserInputService"))
local core_gui = cloneref(game:GetService("CoreGui"))

local player = players.LocalPlayer
local env = getgenv and getgenv() or _G
local has_drawing = Drawing ~= nil and type(Drawing.new) == "function"

local ESP = {
  Version = "1.0.0",
  Supported = { Drawing = has_drawing },
  instances = {}
}
ESP.__index = ESP

local defaults = {
  Enabled = true,
  Name = true,
  Distance = true,
  Box = true,
  Tracer = true,
  Outline = true,
  Chams = true,
  IncludeSelf = false,
  HideDead = true,
  MaxDistance = 3000,
  MaxHighlights = 31,
  DistanceScale = .28,
  DistanceSuffix = "m",
  TextSize = 13,
  Font = 2,
  TracerOrigin = "Bottom",
  TracerTarget = "Bottom",
  TracerThickness = 1,
  BoxThickness = 1,
  BoxBorder = true,
  BoxRatio = .55,
  MinBoxSize = 6,
  FillTransparency = .5,
  OutlineTransparency = 0,
  DefaultColor = Color3.fromRGB(255, 255, 255),
  Filter = nil
}

local function resolve(value, ...)
  if type(value) == "function" then
    local ok, result = pcall(value, ...)
    if ok then
      return result
    end
    return nil
  end

  return value
end

local function passes(callback, ...)
  if type(callback) ~= "function" then
    return true
  end

  local ok, result = pcall(callback, ...)
  return not ok or result ~= false
end

local function wanted(settings, options, key)
  return settings[key] ~= false and options[key] ~= false
end

local function part_of(object)
  if object:IsA("BasePart") then
    return object
  end

  if object:IsA("Model") then
    return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
  end

  return nil
end

local function measure(entry)
  local target = entry.target
  entry.measured = os.clock()

  if target:IsA("Model") then
    local ok, cframe, size = pcall(function()
      return target:GetBoundingBox()
    end)

    if ok and size.Y > 0 then
      entry.size = size
      entry.offset = cframe.Position.Y - target:GetPivot().Position.Y
    end

    entry.humanoid = target:FindFirstChildOfClass("Humanoid")
  elseif target:IsA("BasePart") then
    entry.size = target.Size
    entry.offset = 0
    entry.humanoid = nil
  end

  entry.part = part_of(entry.options.Adornee or target)
end

local function make_folder()
  local folder = Instance.new("Folder")
  folder.Name = "NF_ESP"

  local ok, parent = pcall(function()
    return gethui and gethui() or core_gui
  end)

  local placed = pcall(function()
    folder.Parent = ok and parent or core_gui
  end)

  if not placed or not folder.Parent then
    folder.Parent = workspace
  end

  return folder
end

function ESP.new(overrides)
  local self = setmetatable({}, ESP)

  self.Settings = {}
  for key, value in pairs(defaults) do
    self.Settings[key] = value
  end
  for key, value in pairs(overrides or {}) do
    self.Settings[key] = value
  end

  self.entries = {}
  self.handles = {}
  self.folder = make_folder()
  self.ranked = 0
  self.alive = true
  self.errors = {}

  self.render = run.RenderStepped:Connect(function()
    local ok, err = xpcall(self._step, debug.traceback, self)

    if not ok then
      local message = tostring(err)

      if not self.errors[message] then
        self.errors[message] = true
        warn("[Nightfall ESP] " .. message)
      end
    end
  end)

  table.insert(ESP.instances, self)
  return self
end

function ESP:Add(target, options)
  if not self.alive or typeof(target) ~= "Instance" or not target:IsA("PVInstance") then
    return nil
  end

  local existing = self.entries[target]
  if existing then
    self:Update(target, options)
    return existing
  end

  local entry = {
    target = target,
    options = options or {},
    draw = {},
    size = Vector3.new(4, 5, 1),
    offset = 0,
    measured = 0,
    allowed = true,
    distance = math.huge
  }

  entry.ancestry = target.AncestryChanged:Connect(function()
    if not target:IsDescendantOf(game) then
      self:Remove(target)
    end
  end)

  self.entries[target] = entry
  measure(entry)

  return entry
end

function ESP:Update(target, options)
  local entry = self.entries[target]

  if entry and options then
    for key, value in pairs(options) do
      entry.options[key] = value
    end

    entry.measured = 0
  end

  return entry
end

function ESP:Get(target)
  return self.entries[target]
end

function ESP:Has(target)
  return self.entries[target] ~= nil
end

function ESP:Remove(target)
  local entry = self.entries[target]
  if not entry then
    return
  end

  self.entries[target] = nil

  if entry.ancestry then
    entry.ancestry:Disconnect()
  end

  if entry.highlight then
    pcall(function()
      entry.highlight:Destroy()
    end)
  end

  if entry.billboard then
    pcall(function()
      entry.billboard:Destroy()
    end)
  end

  for _, object in pairs(entry.draw) do
    pcall(function()
      object:Remove()
    end)
  end
end

function ESP:Clear()
  for target in pairs(self.entries) do
    self:Remove(target)
  end
end

function ESP:SetEnabled(state)
  self.Settings.Enabled = state
end

function ESP:_hide(entry)
  if entry.highlight then
    entry.highlight.Enabled = false
  end

  if entry.billboard then
    entry.billboard.Enabled = false
  end

  for _, object in pairs(entry.draw) do
    object.Visible = false
  end
end

function ESP:_hide_2d(entry)
  for _, object in pairs(entry.draw) do
    object.Visible = false
  end

  if entry.billboard then
    entry.billboard.Enabled = false
  end
end

function ESP:_object(entry, key, kind, setup)
  local object = entry.draw[key]

  if not object then
    object = Drawing.new(kind)
    setup(object)
    entry.draw[key] = object
  end

  return object
end

function ESP:_highlight(entry, settings, options, color)
  local chams = wanted(settings, options, "Chams")
  local outline = wanted(settings, options, "Outline")
  local highlight = entry.highlight

  if not (chams or outline) or not entry.allowed then
    if highlight then
      highlight.Enabled = false
    end
    return
  end

  if not highlight or not highlight.Parent then
    highlight = Instance.new("Highlight")
    highlight.Name = "NF_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = self.folder
    entry.highlight = highlight
  end

  local adornee = options.Adornee or entry.target
  if highlight.Adornee ~= adornee then
    highlight.Adornee = adornee
  end

  local fill = resolve(options.FillColor, entry.target, entry) or color
  local line = resolve(options.OutlineColor, entry.target, entry) or color

  highlight.FillColor = fill
  highlight.OutlineColor = line
  highlight.FillTransparency = chams and (options.FillTransparency or settings.FillTransparency) or 1
  highlight.OutlineTransparency = outline and (options.OutlineTransparency or settings.OutlineTransparency) or 1
  highlight.Enabled = true
end

function ESP:_label(entry, settings, options, distance)
  local text = resolve(options.Name, entry.target, entry)

  if type(text) ~= "string" then
    local owner = options.Player
    text = owner and owner.DisplayName or entry.target.Name
  end

  if wanted(settings, options, "Distance") then
    text = string.format("%s [%d%s]", text, distance * settings.DistanceScale, settings.DistanceSuffix)
  end

  return text
end

function ESP:_fallback_name(entry, settings, text, color)
  local gui = entry.billboard

  if not gui then
    gui = Instance.new("BillboardGui")
    gui.Name = "NF_Name"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(220, 24)
    gui.StudsOffset = Vector3.new(0, entry.size.Y / 2 + 1.5, 0)

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.Parent = gui

    gui.Parent = self.folder
    entry.billboard = gui
  end

  if entry.part and gui.Adornee ~= entry.part then
    gui.Adornee = entry.part
  end

  gui.Enabled = entry.part ~= nil
  gui.Label.Text = text
  gui.Label.TextColor3 = color
  gui.Label.TextSize = settings.TextSize
end

function ESP:_origin(settings, viewport)
  local origin = settings.TracerOrigin

  if origin == "Center" then
    return viewport / 2
  elseif origin == "Top" then
    return Vector2.new(viewport.X / 2, 0)
  elseif origin == "Mouse" then
    return uis:GetMouseLocation()
  end

  return Vector2.new(viewport.X / 2, viewport.Y)
end

function ESP:_draw(entry, camera, viewport, now)
  local settings = self.Settings
  local target, options = entry.target, entry.options

  if not target.Parent then
    self:Remove(target)
    return
  end

  if options.Enabled == false
    or not passes(settings.Filter, target, entry)
    or not passes(options.Filter, target, entry) then
    self:_hide(entry)
    return
  end

  if not entry.part or not entry.part.Parent or now - entry.measured > .5 then
    measure(entry)
  end

  if settings.HideDead and entry.humanoid and entry.humanoid.Health <= 0 then
    self:_hide(entry)
    return
  end

  local anchor = options.Adornee or target
  local center = anchor:GetPivot().Position + Vector3.new(0, entry.offset, 0)
  local distance = (camera.CFrame.Position - center).Magnitude
  entry.distance = distance

  if distance > (options.MaxDistance or settings.MaxDistance) then
    self:_hide(entry)
    return
  end

  local color = resolve(options.Color, target, entry) or settings.DefaultColor

  self:_highlight(entry, settings, options, color)

  local want_box = wanted(settings, options, "Box")
  local want_tracer = wanted(settings, options, "Tracer")
  local want_name = wanted(settings, options, "Name")
  local text = want_name and self:_label(entry, settings, options, distance)

  if not has_drawing then
    if want_name then
      self:_fallback_name(entry, settings, text, color)
    elseif entry.billboard then
      entry.billboard.Enabled = false
    end
    return
  end

  if not (want_box or want_tracer or want_name) then
    self:_hide_2d(entry)
    return
  end

  local half = Vector3.new(0, entry.size.Y / 2, 0)
  local top = camera:WorldToViewportPoint(center + half)
  local bottom = camera:WorldToViewportPoint(center - half)

  if top.Z <= 0 or bottom.Z <= 0 then
    self:_hide_2d(entry)
    return
  end

  local height = math.max(bottom.Y - top.Y, settings.MinBoxSize)
  local ratio = options.BoxRatio

  if not ratio then
    if entry.humanoid then
      ratio = settings.BoxRatio
    else
      ratio = math.clamp(math.max(entry.size.X, entry.size.Z) / math.max(entry.size.Y, .05), .2, 3)
    end
  end

  local width = math.max(height * ratio, settings.MinBoxSize)
  local x = (top.X + bottom.X) / 2
  local y = (top.Y + bottom.Y) / 2
  local corner = Vector2.new(x - width / 2, y - height / 2)
  local span = Vector2.new(width, height)

  if want_box then
    local box = self:_object(entry, "box", "Square", function(object)
      object.Filled = false
      object.Transparency = 1
      object.ZIndex = 2
    end)

    box.Position = corner
    box.Size = span
    box.Color = color
    box.Thickness = settings.BoxThickness
    box.Visible = true

    if settings.BoxBorder then
      local border = self:_object(entry, "border", "Square", function(object)
        object.Filled = false
        object.Transparency = 1
        object.Color = Color3.new(0, 0, 0)
        object.ZIndex = 1
      end)

      border.Position = corner
      border.Size = span
      border.Thickness = settings.BoxThickness + 2
      border.Visible = true
    elseif entry.draw.border then
      entry.draw.border.Visible = false
    end
  else
    if entry.draw.box then
      entry.draw.box.Visible = false
    end
    if entry.draw.border then
      entry.draw.border.Visible = false
    end
  end

  if want_tracer then
    local tracer = self:_object(entry, "tracer", "Line", function(object)
      object.Transparency = 1
      object.ZIndex = 2
    end)

    local finish = settings.TracerTarget == "Center" and Vector2.new(x, y) or Vector2.new(x, y + height / 2)

    tracer.From = self:_origin(settings, viewport)
    tracer.To = finish
    tracer.Color = color
    tracer.Thickness = settings.TracerThickness
    tracer.Visible = true
  elseif entry.draw.tracer then
    entry.draw.tracer.Visible = false
  end

  if want_name then
    local label = self:_object(entry, "name", "Text", function(object)
      object.Center = true
      object.Outline = true
      object.Transparency = 1
      object.ZIndex = 3
    end)

    label.Text = text
    label.Size = settings.TextSize
    label.Font = settings.Font
    label.Color = color
    label.Position = Vector2.new(x, y - height / 2 - settings.TextSize - 3)
    label.Visible = true
  elseif entry.draw.name then
    entry.draw.name.Visible = false
  end
end

function ESP:_rank(now)
  if now - self.ranked < .25 then
    return
  end

  self.ranked = now

  local list = {}
  for _, entry in pairs(self.entries) do
    table.insert(list, entry)
  end

  table.sort(list, function(a, b)
    return a.distance < b.distance
  end)

  local limit = self.Settings.MaxHighlights

  for index, entry in ipairs(list) do
    entry.allowed = index <= limit
  end
end

function ESP:_step()
  if not self.alive then
    return
  end

  local camera = workspace.CurrentCamera

  if not camera then
    return
  end

  if not self.Settings.Enabled then
    for _, entry in pairs(self.entries) do
      self:_hide(entry)
    end
    return
  end

  local now = os.clock()
  local viewport = camera.ViewportSize

  self:_rank(now)

  for _, entry in pairs(self.entries) do
    self:_draw(entry, camera, viewport, now)
  end
end

function ESP:TrackPlayers(configure)
  local handle = { connections = {}, added = {}, active = true }

  local function attach(target)
    if target == player and not self.Settings.IncludeSelf then
      return
    end

    local function spawn(char)
      if not handle.active or not char then
        return
      end

      local options = configure and configure(target, char)

      if options == false then
        return
      end

      options = options or {}

      if options.Name == nil then
        options.Name = target.DisplayName
      end

      options.Player = target
      self:Add(char, options)
      table.insert(handle.added, char)
    end

    table.insert(handle.connections, target.CharacterAdded:Connect(spawn))
    table.insert(handle.connections, target.CharacterRemoving:Connect(function(char)
      self:Remove(char)
    end))

    spawn(target.Character)
  end

  table.insert(handle.connections, players.PlayerAdded:Connect(attach))

  for _, target in ipairs(players:GetPlayers()) do
    attach(target)
  end

  function handle.Stop()
    handle.active = false

    for _, connection in ipairs(handle.connections) do
      connection:Disconnect()
    end

    for _, object in ipairs(handle.added) do
      self:Remove(object)
    end

    table.clear(handle.connections)
    table.clear(handle.added)
  end

  table.insert(self.handles, handle)
  return handle
end

function ESP:Watch(container, predicate, configure, deep)
  local handle = { connections = {}, added = {}, active = true }

  local function consider(object)
    if not handle.active or not object:IsA("PVInstance") then
      return
    end

    if predicate and not passes(predicate, object) then
      return
    end

    local ok, options = pcall(function()
      return configure and configure(object)
    end)

    if not ok or options == false then
      return
    end

    self:Add(object, options or {})
    table.insert(handle.added, object)
  end

  local signal = deep and container.DescendantAdded or container.ChildAdded
  table.insert(handle.connections, signal:Connect(consider))

  for _, object in ipairs(deep and container:GetDescendants() or container:GetChildren()) do
    consider(object)
  end

  function handle.Stop()
    handle.active = false

    for _, connection in ipairs(handle.connections) do
      connection:Disconnect()
    end

    for _, object in ipairs(handle.added) do
      self:Remove(object)
    end

    table.clear(handle.connections)
    table.clear(handle.added)
  end

  table.insert(self.handles, handle)
  return handle
end

function ESP:Destroy()
  if not self.alive then
    return
  end

  self.alive = false

  if self.render then
    self.render:Disconnect()
  end

  for _, handle in ipairs(self.handles) do
    pcall(handle.Stop)
  end

  self:Clear()

  if self.folder then
    self.folder:Destroy()
  end

  local index = table.find(ESP.instances, self)
  if index then
    table.remove(ESP.instances, index)
  end
end

function ESP.DestroyAll()
  for index = #ESP.instances, 1, -1 do
    pcall(ESP.instances[index].Destroy, ESP.instances[index])
  end
end

local previous = env.NF_ESP
if previous and previous ~= ESP and type(previous.DestroyAll) == "function" then
  pcall(previous.DestroyAll)
end

env.NF_ESP = ESP

return ESP