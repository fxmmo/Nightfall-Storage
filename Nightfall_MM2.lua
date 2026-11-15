local app = loadstring(game:HttpGet("https://raw.githubusercontent.com/fxmmo/Nightfall-Storage/refs/heads/main/utils/modules/app.lua"))()
local wind = import("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")

local root = app("Nightfall")
local dir = root:mkdir({
  "src/assets/hub/themes",
  "src/configs/saves",
  "src/modules"
})

local translator = import("https://raw.githubusercontent.com/72msreal-pixel/WindUI/refs/heads/main/Modules.luau")
local lang_controller = translator:Install(wind)

wind:Localization({
  Enabled = true,
  DefaultLanguage = "en",
  SouceLanguage = "en",
  TranslateUnkeyed = true,
  Notifications = false,
  NoTranslations = {
    "Nightfall"
  },
  AutoTranslate = true
})

local rstorage = game:GetService("ReplicatedStorage")
local mktplace = game:GetService("MarketplaceService")
local players = game:GetService("Players")
local http = game:GetService("HttpService")
local run = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local uis = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local teleport_service = game:GetService("TeleportService")
local sound_service = game:GetService("SoundService")
local debris = game:GetService("Debris")

local player = players.LocalPlayer
local game_name = tostring(mktplace:GetProductInfo(game.PlaceId).Name)

local var = {
  visual = {
    esp = false,
    esp_style = "Filled",
    names = false,
    lines = false,
    gun = false,
    coins = false,
    xray = false,
    xray_level = .7,
    fullbright = false,
    fog = false,
    fog_density = .5
  },
  aim = {
    enabled = false,
    style = "Silent",
    part = "Head",
    fov = 150,
    show_fov = true,
    prediction = 5,
    only_sheriff = true,
    ignore_walls = false
  },
  sheriff = {
    mode = "Normal",
    part = "Torso",
    auto_gun = false
  },
  murderer = {
    hitbox = false,
    hitbox_size = 8,
    hitbox_show = false,
    aura = false,
    aura_range = 14
  },
  player = {
    walkspeed_enabled = false,
    walkspeed = 16,
    jump_enabled = false,
    jump = 50,
    fov = 70,
    noclip = false,
    fly = false,
    fly_speed = 60,
    infinite_jump = false,
    anti_fling = false,
    spinbot = false,
    spin_speed = 20
  },
  farm = {
    enabled = false,
    speed = 28,
    mode = "Teleport",
    position = "Normal",
    avoid = true,
    reset_on_full = true,
    black_screen = false,
    no_render = false,
    hop = false,
    hop_players = 6,
    hop_timer = 300,
    prestige = false
  },
  teleport = {
    board = "Board 1",
    auto_vote = false
  },
  buttons = {
    size = 64,
    shape = "Circle",
    color = { 255, 255, 255 },
    show = {},
    pos = {},
    keys = {
      aimlock = "Q",
      shoot = "G",
      get_gun = "H",
      throw_knife = "J",
      noclip = "N",
      fly = "F",
      xray = "X"
    }
  },
  configs = {
    notify = true,
    notify_volume = .5,
    transparent = false,
    key_toggle = ""
  }
}

local system = {}
local save_folder = root.src.configs.saves
local save_queued = false

function system.save()
  if not save_folder or save_queued then
    return
  end

  save_queued = true
  task.delay(.5, function()
    save_queued = false
    pcall(function()
      save_folder:wrfile("mm2.json", var, true)
    end)
  end)
end

function system.load(d, s)
  if type(s) ~= "table" then
    return
  end

  for k, v in pairs(s) do
    if type(v) == "table" and type(d[k]) == "table" then
      system.load(d[k], v)
    else
      d[k] = v
    end
  end
end

local save_file = "Nightfall/src/configs/saves/mm2.json"
if isfile and isfile(save_file) then
  local ok, res = pcall(function()
    return http:JSONDecode(readfile(save_file))
  end)
  if ok then
    system.load(var, res)
  else
    print(res)
  end
end

local util, roles, world, esp, aim, sheriff, murderer, move, tp, farm, buttons, light = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}

local alive = true
local connections = {}
local round = { active = false, coins = false }
local has_drawing = Drawing ~= nil and type(Drawing.new) == "function"
local has_touch = type(firetouchinterest) == "function"

local env = getgenv()
env.NF_MM2 = (env.NF_MM2 or 0) + 1
local run_id = env.NF_MM2

function util.running()
  return alive and env.NF_MM2 == run_id
end

function util.bind(section, key, after)
  return function(value)
    section[key] = value
    if after then
      after(value)
    end
    system.save()
  end
end

function util.connect(signal, callback)
  local connection
  connection = (signal.Connect or signal.connect)(signal, function(...)
    if env.NF_MM2 ~= run_id then
      connection:Disconnect()
      return
    end

    return callback(...)
  end)
  table.insert(connections, connection)
  return connection
end

local seen_errors = {}

function util.loop(interval, callback)
  task.spawn(function()
    while util.running() do
      local ok, err = xpcall(callback, debug.traceback)
      if not ok then
        local message = tostring(err)
        if not seen_errors[message] then
          seen_errors[message] = true
          warn("[Nightfall] " .. message)
        end
      end
      task.wait(interval)
    end
  end)
end

function util.notify(content, duration, failed)
  if not var.configs.notify then
    return
  end

  pcall(function()
    local sound = Instance.new("Sound")
    sound.SoundId = failed and "rbxassetid://17208372272" or "rbxassetid://18886652611"
    sound.Volume = var.configs.notify_volume
    sound.Parent = sound_service
    sound:Play()
    debris:AddItem(sound, 3)
  end)

  pcall(function()
    wind:Notify({
      Title = "Nightfall",
      Content = content,
      Duration = duration or 2,
      Icon = "bell"
    })
  end)
end

function util.me()
  local char = player.Character
  return char, char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

function util.part(char, name)
  if name == "Torso" then
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
  end

  return char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart")
end

function util.color(values)
  return Color3.fromRGB(values[1] or 255, values[2] or 255, values[3] or 255)
end

function util.set_ui(element, value)
  if element then
    pcall(function()
      element:Set(value)
    end)
  end
end

roles.cache = {}

function roles.entry(target)
  local data = roles.cache[target.Name] or roles.cache[tostring(target.UserId)] or roles.cache[target.UserId]
  return type(data) == "table" and data or nil
end

function roles.of(target)
  local entry = roles.entry(target)

  if entry and entry.Role then
    return entry.Role == "Hero" and "Sheriff" or entry.Role, entry.Dead == true
  end

  local char = target.Character
  local pack = target:FindFirstChildOfClass("Backpack")

  if (char and char:FindFirstChild("Knife")) or (pack and pack:FindFirstChild("Knife")) then
    return "Murderer", false
  end

  if (char and char:FindFirstChild("Gun")) or (pack and pack:FindFirstChild("Gun")) then
    return "Sheriff", false
  end

  return nil, false
end

function roles.alive(target)
  local char = target.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")

  if not hum or hum.Health <= 0 or not char:FindFirstChild("HumanoidRootPart") then
    return false
  end

  local _, dead = roles.of(target)
  return not dead
end

function roles.find(role)
  for _, target in ipairs(players:GetPlayers()) do
    if roles.of(target) == role and roles.alive(target) then
      return target
    end
  end
end

function roles.label()
  local role = roles.of(player)
  return role or (round.active and "Spectating" or "Lobby")
end

local map_cache = { map = nil, at = 0 }

function world.map()
  local now = os.clock()

  if map_cache.map and map_cache.map.Parent and now - map_cache.at < 1 then
    return map_cache.map
  end

  map_cache.at = now
  map_cache.map = nil

  for _, child in ipairs(workspace:GetChildren()) do
    if (child:IsA("Model") or child:IsA("Folder"))
      and not child.Name:find("Lobby")
      and not players:GetPlayerFromCharacter(child)
      and child:FindFirstChild("CoinContainer", true) then
      map_cache.map = child
      break
    end
  end

  return map_cache.map
end

function world.coin_container()
  local map = world.map()
  if not map then
    return nil
  end

  return map:FindFirstChild("CoinContainer")
    or map:FindFirstChild("CandyContainer")
    or map:FindFirstChild("CoinContainer", true)
    or map:FindFirstChild("CandyContainer", true)
end

local function visible_part(part)
  return part:IsA("BasePart") and part.Transparency < .99
end

function world.coin_ok(coin)
  if not coin.Parent or (coin.Name ~= "Coin_Server" and coin.Name ~= "Candy_Server") then
    return false
  end

  if coin:GetAttribute("Collected") == true then
    return false
  end

  local visual = coin:FindFirstChild("CoinVisual")
  if not visual then
    return true
  end

  if visual:GetAttribute("Collected") == true then
    return false
  end

  if visible_part(visual) then
    return true
  end

  for _, object in ipairs(visual:GetDescendants()) do
    if visible_part(object) then
      return true
    end
  end

  return false
end

function world.gun_drop()
  return workspace:FindFirstChild("GunDrop")
end

function world.lobby_cframe()
  local lobby = workspace:FindFirstChild("Lobby")
  local spawns = lobby and lobby:FindFirstChild("Spawns")

  if spawns then
    local list = {}
    for _, spawn_point in ipairs(spawns:GetChildren()) do
      if spawn_point:IsA("BasePart") then
        table.insert(list, spawn_point)
      end
    end

    if #list > 0 then
      return list[math.random(1, #list)].CFrame + Vector3.new(0, 3.5, 0)
    end
  end

  return lobby and lobby:GetPivot() + Vector3.new(0, 5, 0)
end

function world.arena_cframe()
  local map = world.map()
  if not map then
    return nil
  end

  local spawns = map:FindFirstChild("Spawns")
  if spawns then
    local list = {}
    for _, spawn_point in ipairs(spawns:GetChildren()) do
      if spawn_point:IsA("BasePart") then
        table.insert(list, spawn_point)
      end
    end

    if #list > 0 then
      return list[math.random(1, #list)].CFrame + Vector3.new(0, 3.5, 0)
    end
  end

  local container = world.coin_container()
  return container and container:GetPivot() + Vector3.new(0, 5, 0)
end

function world.vote_pads()
  for _, name in ipairs({ "Lobby", "NormalLobby", "SummerLobby", "HalloweenLobby", "ChristmasLobby", "EasterLobby" }) do
    local lobby = workspace:FindFirstChild(name)
    local pads = lobby and lobby:FindFirstChild("VotePads")
    if pads then
      return pads
    end
  end

  return workspace:FindFirstChild("VotePads", true)
end

function world.pad_votes(pad)
  local gui = pad:FindFirstChild("VoteInfoGui")
  local container = gui and gui:FindFirstChild("Container")
  local label = container and container:FindFirstChild("Votes")

  if label and label:IsA("TextLabel") then
    return tonumber(label.Text:match("%d+")) or 0
  end

  return 0
end

function world.pad_cframe(pad)
  local part = pad and pad:FindFirstChild("Pad")
  return part and part:IsA("BasePart") and part.CFrame + Vector3.new(0, 3, 0)
end

function world.safezone()
  if world.platform and world.platform.Parent then
    return world.platform
  end

  local part = Instance.new("Part")
  part.Name = "NF_Safezone"
  part.Anchored = true
  part.Size = Vector3.new(80, 2, 80)
  part.Position = Vector3.new(0, 6000, 0)
  part.Material = Enum.Material.SmoothPlastic
  part.Color = Color3.fromRGB(40, 40, 60)
  part.Parent = workspace
  world.platform = part

  return part
end

function tp.to(cframe)
  local char, _, hrp = util.me()

  if char and hrp and cframe then
    hrp.AssemblyLinearVelocity = Vector3.zero
    char:PivotTo(cframe)
    return true
  end

  return false
end

function tp.role(role)
  local target = roles.find(role)
  local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

  if not hrp then
    util.notify(role .. " not found", 2, true)
    return
  end

  tp.to(hrp.CFrame * CFrame.new(0, 0, 4))
end

function tp.player(name)
  local target = players:FindFirstChild(name)
  local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

  if hrp then
    tp.to(hrp.CFrame * CFrame.new(0, 0, 4))
  else
    util.notify("Select a player", 2, true)
  end
end

function tp.take_gun()
  local drop = world.gun_drop()
  local _, _, hrp = util.me()

  if not drop or not hrp then
    util.notify("No dropped gun", 2, true)
    return false
  end

  if has_touch then
    pcall(function()
      firetouchinterest(hrp, drop, 0)
      firetouchinterest(hrp, drop, 1)
    end)
    return true
  end

  local previous = hrp.CFrame
  tp.to(drop.CFrame + Vector3.new(0, 3, 0))
  task.wait(.3)
  tp.to(previous)
  return true
end

function tp.safezone()
  tp.to(world.safezone().CFrame + Vector3.new(0, 4, 0))
end

function tp.lobby()
  if not tp.to(world.lobby_cframe()) then
    util.notify("Lobby not found", 2, true)
  end
end

function tp.arena()
  if not tp.to(world.arena_cframe()) then
    util.notify("No active map", 2, true)
  end
end

function tp.board()
  local pads = world.vote_pads()
  local pad = pads and pads:FindFirstChild("VotePad" .. var.teleport.board:match("%d"))

  if not tp.to(world.pad_cframe(pad)) then
    util.notify("Voting board not found", 2, true)
  end
end

tp.voted_at = 0

function tp.vote()
  local pads = world.vote_pads()
  if not pads then
    return
  end

  local best, best_votes = nil, -1
  for _, pad in ipairs(pads:GetChildren()) do
    local votes = world.pad_votes(pad)
    if world.pad_cframe(pad) and votes > best_votes then
      best, best_votes = pad, votes
    end
  end

  local _, _, hrp = util.me()
  if best and hrp then
    local previous = hrp.CFrame
    tp.to(world.pad_cframe(best))
    task.wait(1.5)
    tp.to(previous)
  end
end

local role_colors = {
  Murderer = Color3.fromRGB(255, 60, 60),
  Sheriff = Color3.fromRGB(60, 130, 255),
  Innocent = Color3.fromRGB(80, 255, 120)
}

esp.items = {}
esp.coin_tags = {}
esp.xray_parts = {}
esp.xray_map = nil

function esp.make_highlight(parent)
  local highlight = Instance.new("Highlight")
  highlight.Name = "NF_ESP"
  highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  highlight.Adornee = parent
  highlight.Parent = parent
  return highlight
end

function esp.make_tag(adornee, parent, size)
  local gui = Instance.new("BillboardGui")
  gui.Name = "NF_Tag"
  gui.AlwaysOnTop = true
  gui.Size = size
  gui.StudsOffset = Vector3.new(0, 3, 0)
  gui.Adornee = adornee
  gui.Parent = parent

  local label = Instance.new("TextLabel")
  label.Name = "Label"
  label.Size = UDim2.fromScale(1, 1)
  label.BackgroundTransparency = 1
  label.Font = Enum.Font.GothamBold
  label.TextSize = 13
  label.TextStrokeTransparency = 0
  label.TextColor3 = Color3.new(1, 1, 1)
  label.Parent = gui

  return gui, label
end

function esp.clear(target)
  local item = esp.items[target]
  if not item then
    return
  end

  for _, key in ipairs({ "highlight", "tag" }) do
    if item[key] then
      pcall(function()
        item[key]:Destroy()
      end)
    end
  end

  if item.line then
    pcall(function()
      item.line:Remove()
    end)
  end

  esp.items[target] = nil
end

function esp.update()
  local wanted = var.visual.esp or var.visual.names or var.visual.lines
  local _, _, origin = util.me()

  for _, target in ipairs(players:GetPlayers()) do
    if target ~= player then
      local char = target.Character
      local active = wanted and char and roles.alive(target)

      if active then
        local item = esp.items[target]
        if not item then
          item = {}
          esp.items[target] = item
        end

        local role = roles.of(target) or "Innocent"
        local color = role_colors[role] or role_colors.Innocent
        item.color = color

        if var.visual.esp then
          if not item.highlight or item.highlight.Parent ~= char then
            if item.highlight then
              item.highlight:Destroy()
            end
            item.highlight = esp.make_highlight(char)
          end

          item.highlight.FillColor = color
          item.highlight.OutlineColor = color
          item.highlight.FillTransparency = var.visual.esp_style == "Filled" and .45 or 1
          item.highlight.OutlineTransparency = 0
        elseif item.highlight then
          item.highlight:Destroy()
          item.highlight = nil
        end

        if var.visual.names then
          local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
          if not item.tag or item.tag.Parent ~= char then
            if item.tag then
              item.tag:Destroy()
            end
            item.tag, item.label = esp.make_tag(head, char, UDim2.fromOffset(140, 40))
          end

          local hrp = char:FindFirstChild("HumanoidRootPart")
          local distance = origin and hrp and (origin.Position - hrp.Position).Magnitude or 0
          item.label.Text = string.format("%s\n[%s] %dm", target.DisplayName, role, distance)
          item.label.TextColor3 = color
        elseif item.tag then
          item.tag:Destroy()
          item.tag = nil
        end

        if var.visual.lines and has_drawing then
          if not item.line then
            item.line = Drawing.new("Line")
            item.line.Thickness = 1.5
            item.line.Transparency = 1
          end
        elseif item.line then
          item.line:Remove()
          item.line = nil
        end
      else
        esp.clear(target)
      end
    end
  end
end

function esp.render()
  local camera = workspace.CurrentCamera
  local view = camera.ViewportSize

  for target, item in pairs(esp.items) do
    if item.line then
      local char = target.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")

      if hrp then
        local point, visible = camera:WorldToViewportPoint(hrp.Position)
        item.line.From = Vector2.new(view.X / 2, view.Y)
        item.line.To = Vector2.new(point.X, point.Y)
        item.line.Color = item.color or Color3.new(1, 1, 1)
        item.line.Visible = visible
      else
        item.line.Visible = false
      end
    end
  end
end

function esp.world()
  local drop = world.gun_drop()

  if var.visual.gun and drop then
    if not esp.gun or esp.gun.Parent ~= drop then
      if esp.gun then
        esp.gun:Destroy()
      end
      if esp.gun_tag then
        esp.gun_tag:Destroy()
      end

      esp.gun = esp.make_highlight(drop)
      esp.gun.FillColor = Color3.fromRGB(255, 220, 0)
      esp.gun.OutlineColor = Color3.fromRGB(255, 220, 0)
      esp.gun.FillTransparency = .3

      local tag, label = esp.make_tag(drop, drop, UDim2.fromOffset(80, 24))
      label.Text = "Gun"
      label.TextColor3 = Color3.fromRGB(255, 220, 0)
      esp.gun_tag = tag
    end
  elseif esp.gun then
    esp.gun:Destroy()
    esp.gun = nil

    if esp.gun_tag then
      esp.gun_tag:Destroy()
      esp.gun_tag = nil
    end
  end

  if var.visual.coins then
    farm.index()
    local count = 0

    for coin in pairs(farm.coins) do
      if coin.Parent and world.coin_ok(coin) then
        count += 1

        if count <= 60 and not esp.coin_tags[coin] then
          local gui = Instance.new("BillboardGui")
          gui.Name = "NF_Coin"
          gui.AlwaysOnTop = true
          gui.Size = UDim2.fromOffset(8, 8)
          gui.Adornee = coin
          gui.Parent = coin

          local dot = Instance.new("Frame")
          dot.Size = UDim2.fromScale(1, 1)
          dot.BackgroundColor3 = Color3.fromRGB(255, 210, 40)
          dot.BorderSizePixel = 0
          dot.Parent = gui

          local corner = Instance.new("UICorner")
          corner.CornerRadius = UDim.new(1, 0)
          corner.Parent = dot

          esp.coin_tags[coin] = gui
        end
      end
    end

    for coin, gui in pairs(esp.coin_tags) do
      if not coin.Parent or not world.coin_ok(coin) then
        gui:Destroy()
        esp.coin_tags[coin] = nil
      end
    end
  elseif next(esp.coin_tags) then
    for coin, gui in pairs(esp.coin_tags) do
      gui:Destroy()
      esp.coin_tags[coin] = nil
    end
  end

  if var.visual.xray then
    local map = world.map()
    if map and esp.xray_map ~= map then
      esp.xray(true)
    end
  end
end

function esp.xray_part(object)
  if object:IsA("BasePart") and object.Name ~= "Coin_Server" and object.Name ~= "Candy_Server" and object.Transparency < 1 then
    esp.xray_parts[object] = true
    object.LocalTransparencyModifier = var.visual.xray_level
  end
end

function esp.xray(state)
  if esp.xray_conn then
    esp.xray_conn:Disconnect()
    esp.xray_conn = nil
  end

  for part in pairs(esp.xray_parts) do
    if part.Parent then
      part.LocalTransparencyModifier = 0
    end
    esp.xray_parts[part] = nil
  end

  esp.xray_map = nil

  local map = world.map()
  if state and map then
    esp.xray_map = map

    for _, object in ipairs(map:GetDescendants()) do
      esp.xray_part(object)
    end

    esp.xray_conn = map.DescendantAdded:Connect(function(object)
      if var.visual.xray then
        esp.xray_part(object)
      end
    end)
  end
end

function esp.xray_level()
  for part in pairs(esp.xray_parts) do
    if part.Parent then
      part.LocalTransparencyModifier = var.visual.xray_level
    end
  end
end

light.saved = nil
light.fog = nil

function light.apply()
  if var.visual.fullbright then
    if not light.saved then
      light.saved = {
        Brightness = lighting.Brightness,
        ClockTime = lighting.ClockTime,
        GlobalShadows = lighting.GlobalShadows,
        Ambient = lighting.Ambient,
        OutdoorAmbient = lighting.OutdoorAmbient
      }
    end

    lighting.Brightness = 2
    lighting.ClockTime = 14
    lighting.GlobalShadows = false
    lighting.Ambient = Color3.fromRGB(178, 178, 178)
    lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
  elseif light.saved then
    for property, value in pairs(light.saved) do
      lighting[property] = value
    end
    light.saved = nil
  end

  if var.visual.fog then
    if not light.fog then
      light.fog = { FogStart = lighting.FogStart, FogEnd = lighting.FogEnd, FogColor = lighting.FogColor }
    end

    lighting.FogStart = 0
    lighting.FogEnd = 1500 - var.visual.fog_density * 1300
    lighting.FogColor = Color3.fromRGB(150, 150, 170)
  elseif light.fog then
    for property, value in pairs(light.fog) do
      lighting[property] = value
    end
    light.fog = nil
  end
end

aim.locked = false
aim.circle = nil

function aim.center()
  local camera = workspace.CurrentCamera

  if uis.TouchEnabled and not uis.MouseEnabled then
    return camera.ViewportSize / 2
  end

  return uis:GetMouseLocation()
end

function aim.clear(part)
  local camera = workspace.CurrentCamera
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances = { player.Character, part.Parent }
  params.IgnoreWater = true

  local origin = camera.CFrame.Position
  return workspace:Raycast(origin, part.Position - origin, params) == nil
end

function aim.pick()
  local role = roles.of(player)

  if var.aim.only_sheriff and role ~= "Sheriff" then
    return nil
  end

  local camera = workspace.CurrentCamera
  local center = aim.center()
  local best, best_distance = nil, var.aim.fov

  for _, target in ipairs(players:GetPlayers()) do
    if target ~= player and roles.alive(target) then
      local target_role = roles.of(target)
      local wanted = role == "Murderer" and target_role ~= "Murderer" or role ~= "Murderer" and target_role == "Murderer"

      if wanted then
        local part = util.part(target.Character, var.aim.part)

        if part then
          local point, visible = camera:WorldToViewportPoint(part.Position)

          if visible then
            local distance = (Vector2.new(point.X, point.Y) - center).Magnitude

            if distance < best_distance and (var.aim.ignore_walls or aim.clear(part)) then
              best, best_distance = part, distance
            end
          end
        end
      end
    end
  end

  return best
end

function aim.predict(part)
  local hrp = part.Parent:FindFirstChild("HumanoidRootPart")
  local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.zero

  if velocity.Magnitude > 65 then
    velocity = velocity.Unit * 65
  end

  local ping = math.clamp(player:GetNetworkPing(), .02, .22)
  return part.Position + velocity * (ping * .9 + var.aim.prediction * .01)
end

function aim.render()
  local camera = workspace.CurrentCamera

  if has_drawing then
    if var.aim.enabled and var.aim.show_fov then
      if not aim.circle then
        aim.circle = Drawing.new("Circle")
        aim.circle.Thickness = 1
        aim.circle.NumSides = 64
        aim.circle.Filled = false
        aim.circle.Transparency = 1
        aim.circle.Color = Color3.new(1, 1, 1)
      end

      aim.circle.Radius = var.aim.fov
      aim.circle.Position = aim.center()
      aim.circle.Visible = true
    elseif aim.circle then
      aim.circle.Visible = false
    end
  end

  if var.aim.enabled and var.aim.style == "Aimlock" and aim.locked then
    local part = aim.pick()

    if part then
      camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, aim.predict(part)), .4)
    end
  end
end

sheriff.last = 0

function sheriff.gun()
  local char = player.Character
  local pack = player:FindFirstChildOfClass("Backpack")
  return (char and char:FindFirstChild("Gun")) or (pack and pack:FindFirstChild("Gun"))
end

function sheriff.shoot()
  local char, hum, hrp = util.me()
  local gun = sheriff.gun()

  if not gun or not hum or not hrp then
    util.notify("You don't have the gun", 2, true)
    return false
  end

  if os.clock() - sheriff.last < .4 then
    return false
  end

  local target = roles.find("Murderer")
  local part = target and target.Character and util.part(target.Character, var.sheriff.part)

  if not part then
    util.notify("Murderer not found", 2, true)
    return false
  end

  if gun.Parent ~= char then
    pcall(function()
      hum:EquipTool(gun)
    end)
    task.wait(.05)
    gun = char:FindFirstChild("Gun") or gun
  end

  local shoot = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Shoot", true)
  if not shoot or not shoot:IsA("RemoteEvent") then
    return false
  end

  local point = aim.predict(part)
  local origin = var.sheriff.mode == "Behind Walls" and CFrame.new(point + Vector3.new(0, 1.2, 0)) or CFrame.lookAt(hrp.Position, point)
  local ok = pcall(function()
    shoot:FireServer(origin, CFrame.new(point))
  end)

  sheriff.last = os.clock()
  return ok
end

function sheriff.grab()
  if not var.sheriff.auto_gun or sheriff.gun() or not world.gun_drop() then
    return
  end

  if roles.of(player) == "Murderer" or not roles.alive(player) then
    return
  end

  if has_touch then
    tp.take_gun()
  end
end

murderer.saved = {}
murderer.last = 0

function murderer.knife()
  local char = player.Character
  local pack = player:FindFirstChildOfClass("Backpack")
  return (char and char:FindFirstChild("Knife")) or (pack and pack:FindFirstChild("Knife"))
end

function murderer.equip(knife)
  local char, hum = util.me()

  if knife.Parent ~= char and hum then
    pcall(function()
      hum:EquipTool(knife)
    end)
    task.wait(.05)
  end

  return char and char:FindFirstChild("Knife") or knife
end

function murderer.nearest(limit)
  local _, _, hrp = util.me()
  if not hrp then
    return nil
  end

  local best, best_distance = nil, limit or math.huge

  for _, target in ipairs(players:GetPlayers()) do
    if target ~= player and roles.alive(target) and roles.of(target) ~= "Murderer" then
      local root_part = target.Character:FindFirstChild("HumanoidRootPart")
      local distance = (root_part.Position - hrp.Position).Magnitude

      if distance < best_distance then
        best, best_distance = root_part, distance
      end
    end
  end

  return best
end

function murderer.throw()
  if roles.of(player) ~= "Murderer" then
    util.notify("You must be the murderer", 2, true)
    return false
  end

  local knife = murderer.knife()
  if not knife then
    return false
  end

  local part = aim.pick() or murderer.nearest()
  if not part then
    util.notify("No target", 2, true)
    return false
  end

  knife = murderer.equip(knife)

  local events = knife:FindFirstChild("Events") or knife:WaitForChild("Events", 1)
  local thrown = events and events:FindFirstChild("KnifeThrown")
  if not thrown or not thrown:IsA("RemoteEvent") then
    util.notify("Knife remote not found", 2, true)
    return false
  end

  local handle = knife:FindFirstChild("Handle")
  local point = aim.predict(part)
  local origin = handle and handle.CFrame or CFrame.new(point)

  return pcall(function()
    thrown:FireServer(origin, CFrame.new(point))
  end)
end

function murderer.stab(target_root)
  local knife = murderer.knife()
  if not knife then
    return
  end

  knife = murderer.equip(knife)

  local stab = knife:FindFirstChild("Stab")
  local handle = knife:FindFirstChild("Handle")

  pcall(function()
    knife:Activate()

    if stab and stab:IsA("RemoteEvent") then
      stab:FireServer("Slash")
    end

    if handle and has_touch then
      firetouchinterest(handle, target_root, 0)
      firetouchinterest(handle, target_root, 1)
    end
  end)
end

function murderer.aura()
  if not var.murderer.aura or roles.of(player) ~= "Murderer" or not roles.alive(player) then
    return
  end

  local _, _, hrp = util.me()
  if not hrp then
    return
  end

  for _, target in ipairs(players:GetPlayers()) do
    if target ~= player and roles.alive(target) and roles.of(target) ~= "Murderer" then
      local root_part = target.Character:FindFirstChild("HumanoidRootPart")

      if (root_part.Position - hrp.Position).Magnitude <= var.murderer.aura_range then
        murderer.stab(root_part)
        return
      end
    end
  end
end

function murderer.hitbox()
  local active = var.murderer.hitbox and roles.of(player) == "Murderer"
  local size = Vector3.new(var.murderer.hitbox_size, var.murderer.hitbox_size, var.murderer.hitbox_size)

  for _, target in ipairs(players:GetPlayers()) do
    local char = target ~= player and target.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp then
      if active then
        if not murderer.saved[hrp] then
          murderer.saved[hrp] = {
            Size = hrp.Size,
            CanCollide = hrp.CanCollide,
            Transparency = hrp.Transparency,
            Massless = hrp.Massless
          }
        end

        local transparency = var.murderer.hitbox_show and .6 or 1

        if hrp.Size ~= size then
          hrp.Size = size
        end

        hrp.CanCollide = false
        hrp.Massless = true
        hrp.Transparency = transparency
      elseif murderer.saved[hrp] then
        for property, value in pairs(murderer.saved[hrp]) do
          hrp[property] = value
        end
        murderer.saved[hrp] = nil
      end
    end
  end

  if not active then
    for hrp in pairs(murderer.saved) do
      if not hrp.Parent then
        murderer.saved[hrp] = nil
      end
    end
  end
end

move.parts = {}
move.default_speed = 16
move.speed_set = false
move.jump_set = false
move.fov_set = false

function move.track(char)
  move.parts = {}

  if move.conn then
    move.conn:Disconnect()
  end

  for _, object in ipairs(char:GetDescendants()) do
    if object:IsA("BasePart") then
      table.insert(move.parts, object)
    end
  end

  move.conn = char.DescendantAdded:Connect(function(object)
    if object:IsA("BasePart") then
      table.insert(move.parts, object)
    end
  end)
end

function move.fly_stop()
  if move.fly_velocity then
    move.fly_velocity:Destroy()
    move.fly_velocity = nil

    local _, hum = util.me()
    if hum then
      hum.PlatformStand = false
    end
  end
end

function move.fly(hum, hrp)
  local camera = workspace.CurrentCamera

  if not move.fly_velocity or move.fly_velocity.Parent ~= hrp then
    move.fly_stop()
    move.fly_velocity = Instance.new("BodyVelocity")
    move.fly_velocity.MaxForce = Vector3.one * 1e9
    move.fly_velocity.Velocity = Vector3.zero
    move.fly_velocity.Parent = hrp
  end

  hum.PlatformStand = true

  local speed = var.player.fly_speed
  local look = camera.CFrame.LookVector
  local direction = hum.MoveDirection
  local velocity = Vector3.zero

  if direction.Magnitude > 0 then
    local flat = Vector3.new(look.X, 0, look.Z)
    local forward = flat.Magnitude > 0 and direction:Dot(flat.Unit) or 0
    velocity = direction.Unit * speed + Vector3.new(0, look.Y * forward * speed, 0)
  end

  if uis:IsKeyDown(Enum.KeyCode.Space) then
    velocity += Vector3.new(0, speed, 0)
  elseif uis:IsKeyDown(Enum.KeyCode.LeftControl) then
    velocity -= Vector3.new(0, speed, 0)
  end

  move.fly_velocity.Velocity = velocity
end

function move.step(dt)
  local char, hum, hrp = util.me()
  local camera = workspace.CurrentCamera

  if hum then
    if var.player.walkspeed_enabled then
      if not move.speed_set then
        move.speed_set = true
        move.default_speed = hum.WalkSpeed
      end

      hum.WalkSpeed = var.player.walkspeed
    elseif move.speed_set then
      move.speed_set = false
      hum.WalkSpeed = move.default_speed
    end

    if var.player.jump_enabled then
      move.jump_set = true
      hum.UseJumpPower = true
      hum.JumpPower = var.player.jump
    elseif move.jump_set then
      move.jump_set = false
      hum.JumpPower = 50
    end
  end

  if var.player.fov ~= 70 or move.fov_set then
    move.fov_set = var.player.fov ~= 70
    camera.FieldOfView = var.player.fov
  end

  if var.player.noclip then
    for index = 1, #move.parts do
      local part = move.parts[index]
      if part.CanCollide then
        part.CanCollide = false
      end
    end
  end

  if hum and hrp and var.player.fly then
    move.fly(hum, hrp)
  elseif move.fly_velocity then
    move.fly_stop()
  end

  if hrp and var.player.spinbot then
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(var.player.spin_speed), 0)
  end

  if hrp and var.player.anti_fling then
    local velocity = hrp.AssemblyLinearVelocity
    local flat = Vector3.new(velocity.X, 0, velocity.Z)

    if flat.Magnitude > 130 and not var.player.fly and not var.farm.enabled then
      hrp.AssemblyLinearVelocity = Vector3.zero
      hrp.AssemblyAngularVelocity = Vector3.zero
    end
  end
end

function move.others()
  if not var.player.anti_fling then
    return
  end

  for _, target in ipairs(players:GetPlayers()) do
    local char = target ~= player and target.Character

    if char then
      for _, object in ipairs(char:GetDescendants()) do
        if object:IsA("BasePart") and object.CanCollide then
          object.CanCollide = false
        end
      end
    end
  end
end

farm.coins = {}
farm.done = {}
farm.saved = {}
farm.container = nil
farm.bag = 0
farm.max = 0
farm.total = 0
farm.started = os.clock()
farm.full = false
farm.reset_done = false
farm.running = false
farm.low_since = nil

function farm.track(object)
  if object:IsA("BasePart") and (object.Name == "Coin_Server" or object.Name == "Candy_Server") then
    farm.coins[object] = true
  end
end

function farm.index()
  local container = world.coin_container()

  if container == farm.container then
    return container
  end

  if farm.added then
    farm.added:Disconnect()
    farm.removed:Disconnect()
    farm.added, farm.removed = nil, nil
  end

  farm.container = container
  table.clear(farm.coins)

  if not container then
    return nil
  end

  for _, object in ipairs(container:GetDescendants()) do
    farm.track(object)
  end

  farm.added = container.DescendantAdded:Connect(farm.track)
  farm.removed = container.DescendantRemoving:Connect(function(object)
    farm.coins[object] = nil
  end)

  return container
end

function farm.reset_round()
  table.clear(farm.done)
  farm.bag = 0
  farm.full = false
  farm.reset_done = false
end

function farm.on_start()
  farm.reset_round()
end

function farm.on_end()
  farm.release()
  farm.reset_round()
end

function farm.release()
  if farm.tween then
    farm.tween:Cancel()
    farm.tween = nil
  end

  for part, collide in pairs(farm.saved) do
    if part.Parent then
      part.CanCollide = collide
    end
    farm.saved[part] = nil
  end

  local _, _, hrp = util.me()
  if hrp and hrp.Anchored then
    hrp.Anchored = false
  end

  farm.held = nil
end

function farm.hold(char, hrp, under)
  if farm.held ~= char then
    farm.held = char

    for _, part in ipairs(char:GetDescendants()) do
      if part:IsA("BasePart") and part.CanCollide then
        farm.saved[part] = true
        part.CanCollide = false
      end
    end
  end

  if hrp.Anchored ~= under then
    hrp.Anchored = under
  end
end

function farm.point(coin, under)
  if not under then
    return coin.Position
  end

  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances = { coin, player.Character }

  local hit = workspace:Raycast(coin.Position, Vector3.new(0, -20, 0), params)
  local floor = hit and hit.Position.Y or coin.Position.Y - 3

  return Vector3.new(coin.Position.X, floor - 4, coin.Position.Z)
end

function farm.valid(coin, hrp)
  return util.running()
    and var.farm.enabled
    and round.active
    and round.coins
    and not farm.full
    and coin.Parent ~= nil
    and hrp.Parent ~= nil
    and world.coin_ok(coin)
end

function farm.nearest(hrp)
  farm.index()

  local threat
  if var.farm.avoid and roles.of(player) ~= "Murderer" then
    local target = roles.find("Murderer")
    threat = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
  end

  local now = os.clock()
  local best, best_distance = nil, math.huge

  for coin in pairs(farm.coins) do
    if coin.Parent and (farm.done[coin] or 0) < now and world.coin_ok(coin) then
      if not (threat and (threat.Position - coin.Position).Magnitude < 28) then
        local distance = (hrp.Position - coin.Position).Magnitude

        if distance < best_distance then
          best, best_distance = coin, distance
        end
      end
    end
  end

  return best
end

function farm.touch(char, hrp, coin, under)
  hrp.CFrame = CFrame.new(farm.point(coin, under))

  if has_touch then
    local head = char:FindFirstChild("Head")

    pcall(function()
      if head then
        firetouchinterest(head, coin, 0)
        firetouchinterest(head, coin, 1)
      end

      firetouchinterest(hrp, coin, 0)
      firetouchinterest(hrp, coin, 1)
    end)
  end

  local stamp = os.clock()
  while os.clock() - stamp < .5 and farm.valid(coin, hrp) do
    run.Heartbeat:Wait()
  end

  farm.done[coin] = os.clock() + (world.coin_ok(coin) and 1.5 or 5)
end

function farm.go(char, hrp, coin)
  local under = var.farm.position == "Under"
  local target = farm.point(coin, under)
  local speed = math.max(var.farm.speed, 1)

  farm.hold(char, hrp, under)

  if var.farm.mode == "Tween" then
    local tween = tween_service:Create(
      hrp,
      TweenInfo.new(math.max((target - hrp.Position).Magnitude / speed, .03), Enum.EasingStyle.Linear),
      { CFrame = CFrame.new(target) }
    )

    farm.tween = tween
    tween:Play()

    while tween.PlaybackState == Enum.PlaybackState.Playing do
      if not farm.valid(coin, hrp) then
        tween:Cancel()
        break
      end
      run.Heartbeat:Wait()
    end

    farm.tween = nil
  else
    local last = os.clock()

    while farm.valid(coin, hrp) do
      local now = os.clock()
      local step = math.max(3, speed * math.min(now - last, .12) * 1.35)
      local offset = target - hrp.Position
      last = now

      hrp.AssemblyLinearVelocity = Vector3.zero

      if offset.Magnitude <= step then
        break
      end

      hrp.CFrame = CFrame.new(hrp.Position + offset.Unit * step)
      run.Heartbeat:Wait()
    end
  end

  if farm.valid(coin, hrp) then
    farm.touch(char, hrp, coin, under)
  end
end

function farm.cycle()
  local char, hum, hrp = util.me()
  local entry = roles.entry(player)

  if not (round.active and round.coins and entry and not entry.Dead and hrp and hum and hum.Health > 0) then
    farm.release()
    task.wait(.3)
    return
  end

  if farm.full then
    farm.release()

    if var.farm.reset_on_full and not farm.reset_done then
      farm.reset_done = true
      hum.Health = 0
    end

    task.wait(.5)
    return
  end

  local coin = farm.nearest(hrp)

  if not coin then
    farm.release()
    task.wait(.2)
    return
  end

  farm.go(char, hrp, coin)
end

function farm.run()
  if farm.running then
    return
  end

  farm.running = true

  task.spawn(function()
    while util.running() and var.farm.enabled do
      local ok, err = xpcall(farm.cycle, debug.traceback)

      if not ok then
        local message = tostring(err)
        if not seen_errors[message] then
          seen_errors[message] = true
          warn("[Nightfall] " .. message)
        end
        task.wait(.5)
      end

      task.wait(.03)
    end

    farm.running = false
    farm.release()
  end)
end

function farm.set(state)
  var.farm.enabled = state
  system.save()

  if state then
    farm.started = os.clock()
    farm.run()
  else
    farm.release()
  end
end

function farm.screen(state)
  if state then
    if not farm.cover or not farm.cover.Parent then
      local gui = Instance.new("ScreenGui")
      gui.Name = "NF_FarmScreen"
      gui.IgnoreGuiInset = true
      gui.ResetOnSpawn = false
      gui.DisplayOrder = 10000

      local frame = Instance.new("Frame")
      frame.Size = UDim2.fromScale(1, 1)
      frame.BackgroundColor3 = Color3.new(0, 0, 0)
      frame.BorderSizePixel = 0
      frame.Parent = gui

      local label = Instance.new("TextLabel")
      label.Size = UDim2.fromScale(1, 1)
      label.BackgroundTransparency = 1
      label.Font = Enum.Font.GothamBold
      label.TextSize = 22
      label.TextColor3 = Color3.new(1, 1, 1)
      label.Parent = frame

      gui.Parent = player:WaitForChild("PlayerGui")
      farm.cover, farm.cover_label = gui, label
    end

    farm.cover.Enabled = true
  elseif farm.cover then
    farm.cover.Enabled = false
  end
end

function farm.render(state)
  pcall(function()
    run:Set3dRenderingEnabled(not state)
  end)
end

function farm.stats()
  local elapsed = os.clock() - farm.started
  local per_hour = elapsed > 5 and math.floor(farm.total / elapsed * 3600) or 0

  return string.format(
    "State: %s\nBag: %d/%d\nCollected: %d\nRate: %d/h\nRunning: %dm",
    var.farm.enabled and (farm.full and "Bag full" or "Farming") or "Off",
    farm.bag,
    farm.max,
    farm.total,
    per_hour,
    elapsed / 60
  )
end

function farm.hop()
  if farm.hopping then
    return
  end

  farm.hopping = true

  task.spawn(function()
    local ok, servers = pcall(function()
      local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", game.PlaceId)
      return http:JSONDecode(game:HttpGet(url)).data
    end)

    local best

    if ok and type(servers) == "table" then
      for _, server in ipairs(servers) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 and server.playing > var.farm.hop_players then
          if not best or server.playing > best.playing then
            best = server
          end
        end
      end
    end

    if best then
      util.notify("Hopping to a new server", 3)
      pcall(function()
        teleport_service:TeleportToPlaceInstance(game.PlaceId, best.id, player)
      end)
    else
      util.notify("No server found", 3, true)
    end

    task.wait(30)
    farm.hopping = false
  end)
end

function farm.prestige()
  local remotes = rstorage:FindFirstChild("Remotes")
  local inventory = remotes and remotes:FindFirstChild("Inventory")
  local prestige = inventory and inventory:FindFirstChild("Prestige")

  if prestige and prestige:IsA("RemoteEvent") then
    prestige:FireServer()
  end
end

task.spawn(function()
  local remotes = rstorage:WaitForChild("Remotes", 15)
  local gameplay = remotes and remotes:WaitForChild("Gameplay", 15)
  local modules = rstorage:FindFirstChild("Modules")
  local current = modules and modules:FindFirstChild("CurrentRoundClient")

  if current then
    local ok, result = pcall(require, current)

    if ok and type(result) == "table" and type(result.PlayerData) == "table" then
      roles.cache = result.PlayerData
      round.active = next(roles.cache) ~= nil
      round.coins = round.active
    end
  end

  if not gameplay then
    return
  end

  local changed = gameplay:FindFirstChild("PlayerDataChanged")
  if changed then
    util.connect(changed.OnClientEvent, function(cache)
      if type(cache) ~= "table" then
        return
      end

      roles.cache = cache

      if next(cache) == nil then
        round.active = false
        round.coins = false
        farm.on_end()
      end
    end)
  end

  local started = gameplay:FindFirstChild("RoundStart")
  if started then
    util.connect(started.OnClientEvent, function(_, cache)
      roles.cache = type(cache) == "table" and cache or {}
      round.active = true
      round.coins = false
      farm.on_start()
    end)
  end

  local coins = gameplay:FindFirstChild("CoinsStarted")
  if coins then
    util.connect(coins.OnClientEvent, function(info)
      round.coins = round.active and type(info) == "table" and (info.Coin ~= nil or info.Candy ~= nil)
    end)
  end

  local collected = gameplay:FindFirstChild("CoinCollected")
  if collected then
    util.connect(collected.OnClientEvent, function(kind, first, second)
      if kind ~= "Coin" and kind ~= "Candy" then
        return
      end

      first, second = tonumber(first), tonumber(second)

      if first and second then
        farm.bag, farm.max = math.min(first, second), math.max(first, second)
        farm.full = farm.max > 0 and farm.bag >= farm.max
      else
        farm.bag += 1
      end

      farm.total += 1
    end)
  end
end)

buttons.order = { "aimlock", "shoot", "get_gun", "throw_knife", "noclip", "fly", "xray" }
buttons.refs = {}
buttons.frames = {}
buttons.edit = false
buttons.drag = nil

buttons.specs = {
  aimlock = {
    name = "Aimlock",
    label = "Aim",
    get = function()
      return aim.locked
    end,
    set = function(value)
      aim.locked = value
    end
  },
  shoot = {
    name = "Shoot Murderer",
    label = "Shoot",
    press = function()
      return sheriff.shoot()
    end
  },
  get_gun = {
    name = "Get Gun",
    label = "Gun",
    press = function()
      return tp.take_gun()
    end
  },
  throw_knife = {
    name = "Throw Knife",
    label = "Knife",
    press = function()
      return murderer.throw()
    end
  },
  noclip = {
    name = "Noclip",
    label = "Clip",
    get = function()
      return var.player.noclip
    end,
    set = function(value)
      var.player.noclip = value
      system.save()
    end
  },
  fly = {
    name = "Fly",
    label = "Fly",
    get = function()
      return var.player.fly
    end,
    set = function(value)
      var.player.fly = value
      system.save()
    end
  },
  xray = {
    name = "XRay",
    label = "XRay",
    get = function()
      return var.visual.xray
    end,
    set = function(value)
      var.visual.xray = value
      esp.xray(value)
      system.save()
    end
  }
}

function buttons.screen()
  if buttons.gui and buttons.gui.Parent then
    return buttons.gui
  end

  local gui = Instance.new("ScreenGui")
  gui.Name = "NF_MM2_Buttons"
  gui.ResetOnSpawn = false
  gui.IgnoreGuiInset = true
  gui.DisplayOrder = 50
  gui.Parent = player:WaitForChild("PlayerGui")
  buttons.gui = gui

  return gui
end

function buttons.default(id)
  local size = var.buttons.size
  local view = workspace.CurrentCamera.ViewportSize
  local index = table.find(buttons.order, id) - 1
  local rows = math.max(1, math.floor((view.Y - 140) / (size + 10)))
  local column, row = math.floor(index / rows), index % rows

  return view.X - size - 24 - column * (size + 10), 90 + row * (size + 10)
end

function buttons.style(id)
  local frame = buttons.frames[id]
  if not frame then
    return
  end

  local spec = buttons.specs[id]
  local size = var.buttons.size
  local color = util.color(var.buttons.color)
  local on = spec.get == nil or spec.get()
  local tint = on and color or color:Lerp(Color3.new(0, 0, 0), .55)

  frame.button.Size = UDim2.fromOffset(size, size)
  frame.title.TextSize = math.floor(size * .3)
  frame.title.Text = buttons.edit and "drag" or spec.label

  if var.buttons.shape == "Circle" then
    frame.button.Image = "rbxassetid://97166444"
    frame.button.BackgroundTransparency = 1
    frame.button.ImageColor3 = tint
    frame.corner.CornerRadius = UDim.new(0, 0)
    frame.stroke.Enabled = false
  else
    frame.button.Image = ""
    frame.button.BackgroundTransparency = .35
    frame.button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.corner.CornerRadius = UDim.new(0, 10)
    frame.stroke.Color = tint
    frame.stroke.Enabled = true
  end
end

function buttons.build(id)
  local spec = buttons.specs[id]
  local button = Instance.new("ImageButton")
  button.Name = id
  button.ScaleType = Enum.ScaleType.Stretch
  button.AutoButtonColor = true
  button.Parent = buttons.screen()

  local title = Instance.new("TextLabel")
  title.Size = UDim2.fromScale(1, 1)
  title.BackgroundTransparency = 1
  title.Font = Enum.Font.SourceSansBold
  title.TextColor3 = Color3.new(1, 1, 1)
  title.TextStrokeColor3 = Color3.new(0, 0, 0)
  title.TextStrokeTransparency = 0
  title.Parent = button

  local corner = Instance.new("UICorner")
  corner.Parent = button

  local stroke = Instance.new("UIStroke")
  stroke.Thickness = 2
  stroke.Parent = button

  local saved = var.buttons.pos[id]
  local x, y

  if type(saved) == "table" and saved[1] then
    x, y = saved[1], saved[2]
  else
    x, y = buttons.default(id)
  end

  button.Position = UDim2.fromOffset(x, y)

  button.InputBegan:Connect(function(input)
    local kind = input.UserInputType

    if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
      return
    end

    if buttons.edit then
      buttons.drag = {
        id = id,
        input = input,
        offset = Vector2.new(input.Position.X, input.Position.Y) - button.AbsolutePosition
      }
    else
      buttons.fire(id)
    end
  end)

  button.InputEnded:Connect(function(input)
    if buttons.drag and buttons.drag.input == input then
      buttons.drag = nil
      system.save()
    end
  end)

  buttons.frames[id] = { button = button, title = title, corner = corner, stroke = stroke }
  buttons.style(id)
end

function buttons.sync()
  for _, id in ipairs(buttons.order) do
    local wanted = var.buttons.show[id] == true
    local frame = buttons.frames[id]

    if wanted and not frame then
      buttons.build(id)
    elseif not wanted and frame then
      frame.button:Destroy()
      buttons.frames[id] = nil
    end
  end
end

function buttons.refresh()
  for id in pairs(buttons.frames) do
    buttons.style(id)
  end
end

function buttons.fire(id)
  local spec = buttons.specs[id]

  if spec.press then
    spec.press()
    return
  end

  spec.set(not spec.get())
  util.set_ui(buttons.refs[id], spec.get())
  buttons.refresh()
end

function buttons.customize(state)
  buttons.edit = state
  buttons.sync()
  buttons.refresh()

  if state and next(buttons.frames) == nil then
    util.notify("Enable a button first", 3, true)
  end
end

function buttons.reset()
  table.clear(var.buttons.pos)
  system.save()

  for id, frame in pairs(buttons.frames) do
    local x, y = buttons.default(id)
    frame.button.Position = UDim2.fromOffset(x, y)
  end
end

util.connect(uis.InputChanged, function(input)
  local drag = buttons.drag

  if drag and (input == drag.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
    local frame = buttons.frames[drag.id]

    if frame then
      local at = Vector2.new(input.Position.X, input.Position.Y) - drag.offset
      var.buttons.pos[drag.id] = { at.X, at.Y }
      frame.button.Position = UDim2.fromOffset(at.X, at.Y)
    end
  end
end)

util.connect(uis.InputBegan, function(input, processed)
  if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
    return
  end

  local key = input.KeyCode.Name

  for id, bound in pairs(var.buttons.keys) do
    if bound == key and buttons.specs[id] then
      buttons.fire(id)
    end
  end
end)

util.connect(uis.JumpRequest, function()
  if not var.player.infinite_jump then
    return
  end

  local _, hum = util.me()
  if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
  end
end)

util.connect(players.PlayerRemoving, function(target)
  esp.clear(target)
end)

util.connect(player.CharacterAdded, move.track)
if player.Character then
  move.track(player.Character)
end

util.connect(run.Heartbeat, move.step)

util.connect(run.RenderStepped, function()
  aim.render()

  if has_drawing then
    esp.render()
  end
end)

util.loop(.25, esp.update)
util.loop(.5, esp.world)
util.loop(.5, murderer.hitbox)
util.loop(.15, murderer.aura)
util.loop(.25, move.others)
util.loop(.5, sheriff.grab)

util.loop(2, function()
  if var.teleport.auto_vote and not round.active and os.clock() - tp.voted_at > 25 then
    tp.voted_at = os.clock()
    tp.vote()
  end
end)

util.loop(5, function()
  if var.farm.hop and #players:GetPlayers() <= var.farm.hop_players then
    farm.low_since = farm.low_since or os.clock()

    if os.clock() - farm.low_since >= var.farm.hop_timer then
      farm.hop()
    end
  else
    farm.low_since = nil
  end
end)

local prestige_at = 0

util.loop(2, function()
  if var.farm.prestige and os.clock() - prestige_at > 10 then
    prestige_at = os.clock()
    farm.prestige()
  end
end)

if hookmetamethod and getnamecallmethod and checkcaller and newcclosure then
  local original
  original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if getnamecallmethod() == "FireServer" and var.aim.enabled and var.aim.style == "Silent"
      and env.NF_MM2 == run_id and not checkcaller() and typeof(self) == "Instance" then
      local name = self.Name

      if name == "Shoot" or name == "KnifeThrown" then
        local part = aim.pick()

        if part then
          local args = table.pack(...)
          local point = aim.predict(part)

          if typeof(args[2]) == "CFrame" then
            args[2] = CFrame.new(point)

            if name == "Shoot" and var.sheriff.mode == "Behind Walls" then
              args[1] = CFrame.new(point + Vector3.new(0, 1.2, 0))
            end

            return original(self, table.unpack(args, 1, args.n))
          end
        end
      end
    end

    return original(self, ...)
  end))
end

local theme_url = "https://raw.githubusercontent.com/fxmmo/Nightfall-Storage/refs/heads/main/assets/theme/default.lua"
local icon_url = "https://raw.githubusercontent.com/fxmmo/Nightfall-Storage/refs/heads/main/assets/hub/own.png"

pcall(function()
  local chunk = loadstring(game:HttpGet(theme_url))
  setfenv(chunk, setmetatable({ wind = wind }, { __index = getfenv() }))

  local theme = chunk()
  wind:AddTheme(theme)
  wind:SetTheme(theme.Name)
end)

local tabs = {}
local window = wind:CreateWindow({
  Title = "Nightfall",
  Icon = icon_url,
  Author = "",
  Folder = "Nightfall",
  HideSearchBar = false,
  NewElements = true,
  User = {
    Enabled = true,
    Callback = function()
      tabs.Home:Select()
    end
  },
  OpenButton = {
    Enabled = true,
    Icon = icon_url,
    Draggable = true,
    StrokeThickness = 0,
    OnlyMobile = false
  }
})

local tags = {}
tags.game = window:Tag({
  Title = game_name
})

tabs.Home = window:Tab({
  Title = "Home",
  Icon = "house"
})
tabs.Combat = window:Tab({
  Title = "Combat",
  Icon = "crosshair"
})
tabs.Visual = window:Tab({
  Title = "Visual",
  Icon = "eye"
})
tabs.Player = window:Tab({
  Title = "Player",
  Icon = "user"
})
tabs.Teleports = window:Tab({
  Title = "Teleports",
  Icon = "navigation"
})
tabs.Farm = window:Tab({
  Title = "Farm",
  Icon = "coins"
})
tabs.divide = window:Divider()
tabs.Configs = window:Tab({
  Title = "Configs",
  Icon = "settings"
})

local Home = {}
Home.Paragraph = {}
Home.Discord = tabs.Home:Section({
  Title = "Discord",
  Desc = "Our discord server",
  Icon = "",
  Opened = true
})
Home.Paragraph[1] = Home.Discord:Paragraph({
  Title = "Discord Server",
  Image = "",
  Buttons = {
    {
      Title = "Copy invite",
      Icon = "link",
      Callback = function()
        if setclipboard then
          setclipboard("https://discord.gg/fbza6EJz")
          util.notify("Invite copied", 2)
        end
      end
    }
  }
})
Home.Profile = tabs.Home:Section({
  Title = "Profile",
  Icon = "",
  Opened = true
})
Home.Paragraph[2] = Home.Profile:Paragraph({
  Title = `Hello, {player.DisplayName}`,
  Desc = `Name: {player.Name}\nUserId: {player.UserId}\nAge: {player.AccountAge}\nExecutor: {(identifyexecutor and identifyexecutor())}`,
  Image = ""
})
Home.Info = tabs.Home:Section({
  Title = "Info",
  Icon = "",
  Opened = true
})
Home.Paragraph[3] = Home.Info:Paragraph({
  Title = "Role: Lobby"
})

local Combat = {}
Combat.Aim = tabs.Combat:Section({
  Title = "Aim",
  Icon = "",
  Opened = true
})
Combat.Aim:Toggle({
  Title = "Aim",
  Desc = "Silent aim redirects your shots. Aimlock moves the camera.",
  Value = var.aim.enabled,
  Callback = util.bind(var.aim, "enabled")
})
Combat.Aim:Dropdown({
  Title = "Aim Style",
  Values = { "Silent", "Aimlock" },
  Value = var.aim.style,
  Callback = util.bind(var.aim, "style")
})
Combat.Aim:Dropdown({
  Title = "Aim Part",
  Values = { "Head", "HumanoidRootPart", "Torso" },
  Value = var.aim.part,
  Callback = util.bind(var.aim, "part")
})
Combat.Aim:Slider({
  Title = "FOV Size",
  Step = 5,
  Value = {
    Min = 50,
    Max = 400,
    Default = var.aim.fov
  },
  Callback = util.bind(var.aim, "fov")
})
Combat.Aim:Slider({
  Title = "Prediction Strength",
  Step = 1,
  Value = {
    Min = 0,
    Max = 20,
    Default = var.aim.prediction
  },
  Callback = util.bind(var.aim, "prediction")
})
Combat.Aim:Toggle({
  Title = "Show FOV",
  Value = var.aim.show_fov,
  Callback = util.bind(var.aim, "show_fov")
})
Combat.Aim:Toggle({
  Title = "Only Aim While Sheriff",
  Value = var.aim.only_sheriff,
  Callback = util.bind(var.aim, "only_sheriff")
})
Combat.Aim:Toggle({
  Title = "Ignore Walls",
  Value = var.aim.ignore_walls,
  Callback = util.bind(var.aim, "ignore_walls")
})

Combat.Sheriff = tabs.Combat:Section({
  Title = "Sheriff",
  Icon = "",
  Opened = true
})
Combat.Sheriff:Button({
  Title = "Shoot Murderer",
  Callback = function()
    sheriff.shoot()
  end
})
Combat.Sheriff:Dropdown({
  Title = "Shoot Mode",
  Values = { "Normal", "Behind Walls" },
  Value = var.sheriff.mode,
  Callback = util.bind(var.sheriff, "mode")
})
Combat.Sheriff:Dropdown({
  Title = "Shoot Part",
  Values = { "Head", "HumanoidRootPart", "Torso" },
  Value = var.sheriff.part,
  Callback = util.bind(var.sheriff, "part")
})
Combat.Sheriff:Toggle({
  Title = "Auto Grab Gun",
  Desc = "Takes the dropped gun without teleporting",
  Value = var.sheriff.auto_gun,
  Callback = util.bind(var.sheriff, "auto_gun")
})
Combat.Sheriff:Button({
  Title = "Get Gun",
  Callback = function()
    tp.take_gun()
  end
})

Combat.Murderer = tabs.Combat:Section({
  Title = "Murderer",
  Icon = "",
  Opened = true
})
Combat.Murderer:Button({
  Title = "Throw Knife",
  Callback = function()
    murderer.throw()
  end
})
Combat.Murderer:Toggle({
  Title = "Knife Aura",
  Desc = "Stabs players inside the range",
  Value = var.murderer.aura,
  Callback = util.bind(var.murderer, "aura")
})
Combat.Murderer:Slider({
  Title = "Aura Range",
  Step = 1,
  Value = {
    Min = 5,
    Max = 30,
    Default = var.murderer.aura_range
  },
  Callback = util.bind(var.murderer, "aura_range")
})
Combat.Murderer:Toggle({
  Title = "Hitbox Expander",
  Value = var.murderer.hitbox,
  Callback = util.bind(var.murderer, "hitbox")
})
Combat.Murderer:Slider({
  Title = "Hitbox Size",
  Step = 1,
  Value = {
    Min = 2,
    Max = 40,
    Default = var.murderer.hitbox_size
  },
  Callback = util.bind(var.murderer, "hitbox_size")
})
Combat.Murderer:Toggle({
  Title = "Show Hitboxes",
  Value = var.murderer.hitbox_show,
  Callback = util.bind(var.murderer, "hitbox_show")
})

local Visual = {}
Visual.ESP = tabs.Visual:Section({
  Title = "ESP",
  Icon = "",
  Opened = true
})
Visual.ESP:Toggle({
  Title = "Player ESP",
  Value = var.visual.esp,
  Callback = util.bind(var.visual, "esp")
})
Visual.ESP:Dropdown({
  Title = "ESP Style",
  Values = { "Filled", "Outline" },
  Value = var.visual.esp_style,
  Callback = util.bind(var.visual, "esp_style")
})
Visual.ESP:Toggle({
  Title = "Nametags",
  Value = var.visual.names,
  Callback = util.bind(var.visual, "names")
})
Visual.ESP:Toggle({
  Title = "Lines",
  Desc = "Requires the Drawing API",
  Value = var.visual.lines,
  Callback = util.bind(var.visual, "lines")
})
Visual.ESP:Space()
Visual.ESP:Toggle({
  Title = "Gun ESP",
  Value = var.visual.gun,
  Callback = util.bind(var.visual, "gun")
})
Visual.ESP:Toggle({
  Title = "Coin ESP",
  Value = var.visual.coins,
  Callback = util.bind(var.visual, "coins")
})

Visual.World = tabs.Visual:Section({
  Title = "World",
  Icon = "",
  Opened = true
})
buttons.refs.xray = Visual.World:Toggle({
  Title = "XRay",
  Value = var.visual.xray,
  Callback = function(value)
    buttons.specs.xray.set(value)
    buttons.refresh()
  end
})
Visual.World:Slider({
  Title = "XRay Transparency",
  Step = .05,
  Value = {
    Min = .1,
    Max = .95,
    Default = var.visual.xray_level
  },
  Callback = util.bind(var.visual, "xray_level", esp.xray_level)
})
Visual.World:Toggle({
  Title = "Fullbright",
  Value = var.visual.fullbright,
  Callback = util.bind(var.visual, "fullbright", light.apply)
})
Visual.World:Toggle({
  Title = "Fog",
  Value = var.visual.fog,
  Callback = util.bind(var.visual, "fog", light.apply)
})
Visual.World:Slider({
  Title = "Fog Density",
  Step = .05,
  Value = {
    Min = .1,
    Max = 1,
    Default = var.visual.fog_density
  },
  Callback = util.bind(var.visual, "fog_density", light.apply)
})

local Player = {}
Player.Movement = tabs.Player:Section({
  Title = "Movement",
  Icon = "",
  Opened = true
})
Player.Movement:Toggle({
  Title = "Enable Walkspeed",
  Value = var.player.walkspeed_enabled,
  Callback = util.bind(var.player, "walkspeed_enabled")
})
Player.Movement:Slider({
  Title = "Walkspeed",
  Step = 1,
  Value = {
    Min = 0,
    Max = 120,
    Default = var.player.walkspeed
  },
  Callback = util.bind(var.player, "walkspeed")
})
Player.Movement:Toggle({
  Title = "Enable Jump Power",
  Value = var.player.jump_enabled,
  Callback = util.bind(var.player, "jump_enabled")
})
Player.Movement:Slider({
  Title = "Jump Power",
  Step = 1,
  Value = {
    Min = 0,
    Max = 200,
    Default = var.player.jump
  },
  Callback = util.bind(var.player, "jump")
})
Player.Movement:Toggle({
  Title = "Infinite Jump",
  Value = var.player.infinite_jump,
  Callback = util.bind(var.player, "infinite_jump")
})
Player.Movement:Slider({
  Title = "Field of View",
  Step = 1,
  Value = {
    Min = 30,
    Max = 120,
    Default = var.player.fov
  },
  Callback = util.bind(var.player, "fov")
})
Player.Movement:Space()
buttons.refs.noclip = Player.Movement:Toggle({
  Title = "Noclip",
  Value = var.player.noclip,
  Callback = function(value)
    buttons.specs.noclip.set(value)
    buttons.refresh()
  end
})
buttons.refs.fly = Player.Movement:Toggle({
  Title = "Fly",
  Value = var.player.fly,
  Callback = function(value)
    buttons.specs.fly.set(value)
    buttons.refresh()
  end
})
Player.Movement:Slider({
  Title = "Fly Speed",
  Step = 1,
  Value = {
    Min = 10,
    Max = 200,
    Default = var.player.fly_speed
  },
  Callback = util.bind(var.player, "fly_speed")
})

Player.Utils = tabs.Player:Section({
  Title = "Utilities",
  Icon = "",
  Opened = true
})
Player.Utils:Toggle({
  Title = "Anti Fling",
  Desc = "Disables collision with other players and clamps your velocity",
  Value = var.player.anti_fling,
  Callback = util.bind(var.player, "anti_fling")
})
Player.Utils:Toggle({
  Title = "Spinbot",
  Value = var.player.spinbot,
  Callback = util.bind(var.player, "spinbot")
})
Player.Utils:Slider({
  Title = "Spin Speed",
  Step = 1,
  Value = {
    Min = 1,
    Max = 90,
    Default = var.player.spin_speed
  },
  Callback = util.bind(var.player, "spin_speed")
})

local Teleports = {}
Teleports.Roles = tabs.Teleports:Section({
  Title = "Roles",
  Icon = "",
  Opened = true
})
Teleports.Roles:Button({
  Title = "TP to Murderer",
  Callback = function()
    tp.role("Murderer")
  end
})
Teleports.Roles:Button({
  Title = "TP to Sheriff",
  Callback = function()
    tp.role("Sheriff")
  end
})
Teleports.Roles:Button({
  Title = "TP to Gun",
  Callback = function()
    local drop = world.gun_drop()
    if drop then
      tp.to(drop.CFrame + Vector3.new(0, 3, 0))
    else
      util.notify("No dropped gun", 2, true)
    end
  end
})
Teleports.Places = tabs.Teleports:Section({
  Title = "Places",
  Icon = "",
  Opened = true
})
Teleports.Places:Button({
  Title = "TP to Safezone",
  Callback = tp.safezone
})
Teleports.Places:Button({
  Title = "TP to Lobby",
  Callback = tp.lobby
})
Teleports.Places:Button({
  Title = "TP to Game Arena",
  Callback = tp.arena
})
Teleports.Vote = tabs.Teleports:Section({
  Title = "Voting",
  Icon = "",
  Opened = true
})
Teleports.Vote:Dropdown({
  Title = "Voting Board",
  Values = { "Board 1", "Board 2", "Board 3" },
  Value = var.teleport.board,
  Callback = util.bind(var.teleport, "board")
})
Teleports.Vote:Button({
  Title = "TP to Voting Board",
  Callback = tp.board
})
Teleports.Vote:Toggle({
  Title = "Auto Map Vote",
  Desc = "Votes for the most voted map between rounds",
  Value = var.teleport.auto_vote,
  Callback = util.bind(var.teleport, "auto_vote")
})
Teleports.Players = tabs.Teleports:Section({
  Title = "Players",
  Icon = "",
  Opened = true
})

local selected_player = ""

local function player_names()
  local names = {}
  for _, target in ipairs(players:GetPlayers()) do
    if target ~= player then
      table.insert(names, target.Name)
    end
  end
  table.sort(names)
  return names
end

Teleports.Dropdown = Teleports.Players:Dropdown({
  Title = "TP to Player",
  Values = player_names(),
  Callback = function(value)
    selected_player = value
    tp.player(value)
  end
})
Teleports.Players:Button({
  Title = "Refresh Player List",
  Callback = function()
    Teleports.Dropdown:Refresh(player_names())
  end
})

util.connect(players.PlayerAdded, function()
  task.delay(1, function()
    Teleports.Dropdown:Refresh(player_names())
  end)
end)

util.connect(players.PlayerRemoving, function()
  task.defer(function()
    Teleports.Dropdown:Refresh(player_names())
  end)
end)

local Farm = {}
Farm.Paragraph = {}
Farm.Coin = tabs.Farm:Section({
  Title = "Coin Farm",
  Icon = "",
  Opened = true
})
Farm.Paragraph[1] = Farm.Coin:Paragraph({
  Title = "State: Off"
})
Farm.Toggle = Farm.Coin:Toggle({
  Title = "Coin Farm",
  Value = var.farm.enabled,
  Callback = farm.set
})
Farm.Coin:Dropdown({
  Title = "Farm Mode",
  Values = { "Teleport", "Tween" },
  Value = var.farm.mode,
  Callback = util.bind(var.farm, "mode")
})
Farm.Coin:Dropdown({
  Title = "Farm Position",
  Values = { "Normal", "Under" },
  Value = var.farm.position,
  Callback = util.bind(var.farm, "position")
})
Farm.Coin:Slider({
  Title = "Farm Speed",
  Step = 1,
  Value = {
    Min = 10,
    Max = 120,
    Default = var.farm.speed
  },
  Callback = util.bind(var.farm, "speed")
})
Farm.Coin:Toggle({
  Title = "Avoid Murderer",
  Desc = "Skips coins close to the murderer",
  Value = var.farm.avoid,
  Callback = util.bind(var.farm, "avoid")
})
Farm.Coin:Toggle({
  Title = "Reset When Bag Is Full",
  Value = var.farm.reset_on_full,
  Callback = util.bind(var.farm, "reset_on_full")
})

Farm.Perf = tabs.Farm:Section({
  Title = "Performance",
  Icon = "",
  Opened = true
})
Farm.Perf:Toggle({
  Title = "Black Screen",
  Value = var.farm.black_screen,
  Callback = util.bind(var.farm, "black_screen", farm.screen)
})
Farm.Perf:Toggle({
  Title = "Disable 3D Rendering",
  Value = var.farm.no_render,
  Callback = util.bind(var.farm, "no_render", farm.render)
})

Farm.Server = tabs.Farm:Section({
  Title = "Server",
  Icon = "",
  Opened = true
})
Farm.Server:Toggle({
  Title = "Server Hop If Low Players",
  Value = var.farm.hop,
  Callback = util.bind(var.farm, "hop")
})
Farm.Server:Slider({
  Title = "Player Threshold",
  Step = 1,
  Value = {
    Min = 1,
    Max = 20,
    Default = var.farm.hop_players
  },
  Callback = util.bind(var.farm, "hop_players")
})
Farm.Server:Slider({
  Title = "Hop Timer (seconds)",
  Step = 10,
  Value = {
    Min = 30,
    Max = 900,
    Default = var.farm.hop_timer
  },
  Callback = util.bind(var.farm, "hop_timer")
})
Farm.Server:Button({
  Title = "Hop Now",
  Callback = farm.hop
})

Farm.Progress = tabs.Farm:Section({
  Title = "Progression",
  Icon = "",
  Opened = true
})
Farm.Progress:Toggle({
  Title = "Auto Prestige",
  Value = var.farm.prestige,
  Callback = util.bind(var.farm, "prestige")
})

local Configs = {}
Configs.Notify = tabs.Configs:Section({
  Title = "Notifications",
  Icon = "",
  Opened = true
})
Configs.Notify:Toggle({
  Title = "Notify",
  Value = var.configs.notify,
  Callback = util.bind(var.configs, "notify")
})
Configs.Notify:Slider({
  Title = "Notify Volume",
  Step = .1,
  Value = {
    Min = 0,
    Max = 3,
    Default = var.configs.notify_volume
  },
  Callback = util.bind(var.configs, "notify_volume")
})
Configs.Hub = tabs.Configs:Section({
  Title = "Hub",
  Icon = "",
  Opened = true
})
Configs.Hub:Toggle({
  Title = "Background Transparent",
  Value = var.configs.transparent,
  Callback = util.bind(var.configs, "transparent", function(b)
    window:ToggleTransparency(b)
  end)
})
Configs.Hub:Keybind({
  Title = "Key to toggle UI",
  Desc = "This will toggle the UI",
  Value = var.configs.key_toggle ~= "" and var.configs.key_toggle or "T",
  Callback = function(v)
    local ok, code = pcall(function()
      return Enum.KeyCode[v]
    end)

    if ok and code then
      var.configs.key_toggle = v
      window:SetToggleKey(code)
      system.save()
    end
  end
})
Configs.Buttons = tabs.Configs:Section({
  Title = "Buttons",
  Icon = "",
  Opened = true
})
Configs.Buttons:Toggle({
  Title = "Customize buttons",
  Desc = "Drag the on-screen buttons to move them",
  Value = false,
  Callback = buttons.customize
})
Configs.Buttons:Slider({
  Title = "Button size",
  Step = 1,
  Value = {
    Min = 36,
    Max = 120,
    Default = var.buttons.size
  },
  Callback = util.bind(var.buttons, "size", buttons.refresh)
})
Configs.Buttons:Dropdown({
  Title = "Button shape",
  Values = { "Circle", "Square" },
  Value = var.buttons.shape,
  Callback = util.bind(var.buttons, "shape", buttons.refresh)
})
Configs.Buttons:Colorpicker({
  Title = "Button color",
  Default = util.color(var.buttons.color),
  Callback = function(color)
    var.buttons.color = {
      math.floor(color.R * 255 + .5),
      math.floor(color.G * 255 + .5),
      math.floor(color.B * 255 + .5)
    }
    buttons.refresh()
    system.save()
  end
})
Configs.Buttons:Button({
  Title = "Reset button positions",
  Callback = buttons.reset
})

Configs.Keys = tabs.Configs:Section({
  Title = "Buttons and keybinds",
  Icon = "",
  Opened = true
})

for _, id in ipairs(buttons.order) do
  local spec = buttons.specs[id]

  Configs.Keys:Toggle({
    Title = spec.name .. " button",
    Value = var.buttons.show[id] == true,
    Callback = function(value)
      var.buttons.show[id] = value
      buttons.sync()
      system.save()
    end
  })

  Configs.Keys:Keybind({
    Title = spec.name .. " key",
    Value = var.buttons.keys[id] or "None",
    Callback = function(v)
      if type(v) == "string" and v ~= var.buttons.keys[id] and pcall(function()
        return Enum.KeyCode[v]
      end) then
        var.buttons.keys[id] = v
        system.save()
      end
    end
  })
end

lang_controller:AddDropdown(tabs.Configs, {
  Title = "Language"
})

util.loop(1, function()
  local text = `Role: {roles.label()}\nRound: {round.active and "Active" or "Idle"}\nCoins: {tostring(round.coins)}\nMap: {world.map() and world.map().Name or "None"}\nPlayers: {#players:GetPlayers()}`
  Home.Paragraph[3]:SetTitle(text)
  Farm.Paragraph[1]:SetTitle(farm.stats())

  if farm.cover_label and farm.cover and farm.cover.Enabled then
    farm.cover_label.Text = "Nightfall\n" .. farm.stats()
  end

  if var.visual.fullbright or var.visual.fog then
    light.apply()
  end

end)

if var.configs.transparent then
  window:ToggleTransparency(true)
end

if var.configs.key_toggle ~= "" then
  pcall(function()
    window:SetToggleKey(Enum.KeyCode[var.configs.key_toggle])
  end)
end

light.apply()
buttons.sync()

if var.visual.xray then
  task.delay(2, function()
    esp.xray(true)
  end)
end

if var.farm.black_screen then
  farm.screen(true)
end

if var.farm.no_render then
  farm.render(true)
end

if var.farm.enabled then
  farm.run()
end

window:OnDestroy(function()
  alive = false

  local steps = {
    function()
      workspace.CurrentCamera.FieldOfView = 70
    end,
    function()
      local _, hum = util.me()
      if hum then
        if move.speed_set then
          hum.WalkSpeed = move.default_speed
        end
        hum.PlatformStand = false
      end
    end,
    move.fly_stop,
    farm.release,
    function()
      farm.render(false)
    end,
    function()
      if farm.cover then
        farm.cover:Destroy()
      end
    end,
    function()
      if farm.added then
        farm.added:Disconnect()
        farm.removed:Disconnect()
      end
    end,
    function()
      var.visual.fullbright, var.visual.fog = false, false
      light.apply()
    end,
    function()
      esp.xray(false)
    end,
    function()
      for target in pairs(esp.items) do
        esp.clear(target)
      end

      for coin, gui in pairs(esp.coin_tags) do
        gui:Destroy()
        esp.coin_tags[coin] = nil
      end

      if esp.gun then
        esp.gun:Destroy()
      end

      if esp.gun_tag then
        esp.gun_tag:Destroy()
      end
    end,
    function()
      var.murderer.hitbox = false
      murderer.hitbox()
    end,
    function()
      if aim.circle then
        aim.circle:Remove()
      end
    end,
    function()
      if buttons.gui then
        buttons.gui:Destroy()
      end
    end,
    function()
      if world.platform then
        world.platform:Destroy()
      end
    end,
    function()
      for _, connection in ipairs(connections) do
        connection:Disconnect()
      end
      table.clear(connections)
    end
  }

  for _, step in ipairs(steps) do
    pcall(step)
  end
end)

util.notify("Welcome :)", 3)
