local highlights_group = {}

local Apply = {}

function Apply:Highlight(obj)
  local name = obj.Name or "Highlight"
  local color = obj.Color or Color3.fromRGB(12,243,236)
  local target = obj.Target
  local group = obj.Group

  local transparency = obj.Transparency

  if not (target and group) then
    return false
  end

  local h = target:FindFirstChild(name)
    if not h then
        h = Instance.new("Highlight")
        h.Name = name
        h.Parent = target
        table.insert(highlights_group[group], h)
    end

    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = obj.transparency
    h.OutlineTransparency = 0
    h.Enabled = true
    h.Adornee = target
    return h
end

function Apply:ClearHighlight(group)
    local reg = highlights_group[group]
    if not reg then return end

    for i = #reg, 1, -1 do
        local h = reg[i]
        if h and h.Parent then
            h:Destroy()
        end
        reg[i] = nil
    end
end