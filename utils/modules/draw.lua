local Draw = {}

local defaults = {
    Line = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255),
        From = Vector2.new(0, 0),
        To = Vector2.new(100, 100)
    },
    Text = {
        Visible = true,
        Transparency = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Size = 13,
        Center = false,
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Position = Vector2.new(0, 0),
        Text = "Text",
        Font = 2
    },
    Square = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = false,
        Position = Vector2.new(0, 0),
        Size = Vector2.new(50, 50)
    },
    Circle = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = false,
        NumSides = 30,
        Radius = 25,
        Position = Vector2.new(0, 0)
    },
    Triangle = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = false,
        PointA = Vector2.new(0, 0),
        PointB = Vector2.new(50, 0),
        PointC = Vector2.new(25, 50)
    }
}

local function apply(obj, props)
    for key, value in pairs(props) do
        obj[key] = value
    end
    return obj
end

local function create(class, props)
    local obj = Drawing.new(class)
    apply(obj, defaults[class] or {})
    apply(obj, props or {})
    return obj
end

function Draw:Line(props)
    return create("Line", props)
end

function Draw:Text(props)
    return create("Text", props)
end

function Draw:Square(props)
    return create("Square", props)
end

function Draw:Circle(props)
    return create("Circle", props)
end

function Draw:Triangle(props)
    return create("Triangle", props)
end

function Draw:Remove(obj)
    if obj and obj.Remove then
        obj:Remove()
    end
end

function Draw:Tracer(target, options)
    options = options or {}

    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = options.Color or Color3.fromRGB(255, 255, 255)
    line.Thickness = options.Thickness or 1
    line.Transparency = options.Transparency or 1

    local basePosition = options.From or Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)

    local connection
    connection = runService.RenderStepped:Connect(function()
        if not target or not target.Parent then
            line.Visible = false
            if connection then
                connection:Disconnect()
            end
            return
        end

        local part = target
        if target:IsA("Model") then
            part = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        end

        if not part then
            line.Visible = false
            return
        end

        local pos, onScreen = camera:WorldToViewportPoint(part.Position)

        if onScreen then
            line.From = basePosition
            line.To = Vector2.new(pos.X, pos.Y)
            line.Visible = true
        else
            line.Visible = false
        end
    end)

    function line:Destroy()
        if connection then
            connection:Disconnect()
        end
        self:Remove()
    end

    return line
end

return Draw