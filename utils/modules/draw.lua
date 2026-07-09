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

return Draw