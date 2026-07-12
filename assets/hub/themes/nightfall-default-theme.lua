local Theme = {}

function Theme:Get()
  return {
    Name = "nightfall-default-theme",

    Primary = Color3.fromHex("#a78bfa"),
    White = Color3.new(1,1,1),
    Black = Color3.new(0,0,0),

    Dialog = Color3.fromHex("#1a1040"),
    
    Background = Color3.fromHex("#0f0c29"),
    BackgroundTransparency = 0,
    Hover = Color3.fromHex("#e2e8f0"),

    PanelBackground = Color3.new(1,1,1),
    PanelBackgroundTransparency = .95,

    WindowBackground = Color3.fromHex("#0f0c29"),

    WindowShadow = Color3.new(0,0,0),

    WindowTopbarTitle = Color3.fromHex("#e2e8f0"),
    WindowTopbarAuthor = Color3.fromHex("#a78bfa"),
    WindowTopbarIcon = Color3.fromHex("#a78bfa"),
    WindowTopbarButtonIcon = Color3.fromHex("#a78bfa"),

    WindowSearchBarBackground = Color3.fromHex("#0d0d1a"),

    TabBackground = Color3.fromHex("#e2e8f0"),
    TabBackgroundHover = Color3.fromHex("#e2e8f0"),
    TabBackgroundHoverTransparency = .97,
    TabBackgroundActive = Color3.fromHex("#7c3aed"),
    TabBackgroundActiveTransparency = 0.80,
    TabText = Color3.fromHex("#e2e8f0"),
    TabTextTransparency = 0.3,
    TabTextTransparencyActive = 0,
    TabTitle = Color3.fromHex("#e2e8f0"),
    TabIcon = Color3.fromHex("#a78bfa"),
    TabIconTransparency = 0.4,
    TabIconTransparencyActive = 0.05,
    TabBorderTransparency = 1,
    TabBorderTransparencyActive = 0.65,
    TabBorder = Color3.fromHex("#7c3aed"),

    ElementBackground = Color3.fromHex("#e2e8f0"),
    ElementBackgroundTransparency = .93,
    --ElementBackgroundHover = Wind.Creator:AddColor("ElementBackground", "#a78bfa", 1/10),
    ElementTitle = Color3.fromHex("#e2e8f0"),
    ElementDesc = Color3.fromHex("#a78bfa"),
    ElementIcon = Color3.fromHex("#a78bfa"),

    PopupBackground = Color3.fromHex("#0d0d1a"),
    PopupBackgroundTransparency = "BackgroundTransparency",
    PopupTitle = Color3.fromHex("#e2e8f0"),
    PopupContent = Color3.fromHex("#e2e8f0"),
    PopupIcon = Color3.fromHex("#a78bfa"),

    DialogBackground = Color3.fromHex("#1a1040"),
    DialogBackgroundTransparency = "BackgroundTransparency",
    DialogTitle = Color3.fromHex("#e2e8f0"),
    DialogContent = Color3.fromHex("#e2e8f0"),
    DialogIcon = Color3.fromHex("#a78bfa"),

    Toggle = Color3.fromHex("#4c1d95"),
    ToggleBar = Color3.fromHex("#ffffff"),

    Checkbox = Color3.fromHex("#7c3aed"),
    CheckboxIcon = Color3.new(1,1,1),
    CheckboxBorder = Color3.fromHex("#a78bfa"),
    CheckboxBorderTransparency = .60,

    SliderIcon = Color3.fromHex("#a78bfa"),
    Slider = Color3.fromHex("#7c3aed"),
    SliderThumb = Color3.fromHex("#e2e8f0"),
    SliderIconFrom = Color3.fromHex("#a78bfa"),
    SliderIconTo = Color3.fromHex("#4c1d95"),

    Tooltip = Color3.fromHex("#1a1040"),
    TooltipText = Color3.fromHex("#e2e8f0"),
    TooltipSecondary = Color3.fromHex("#7c3aed"),
    TooltipSecondaryText = Color3.new(1,1,1),

    TabSectionIcon = Color3.fromHex("#a78bfa"),

    SectionIcon = Color3.fromHex("#a78bfa"),
    SectionExpandIcon = Color3.fromHex("#e2e8f0"),
    SectionExpandIconTransparency = .3,
    SectionBox = Color3.fromHex("#7c3aed"),
    SectionBoxTransparency = .90,
    SectionBoxBorder = Color3.fromHex("#7c3aed"),
    SectionBoxBorderTransparency = .65,
    SectionBoxBackground = Color3.fromHex("#1a1040"),
    SectionBoxBackgroundTransparency = .90,

    SearchBarBorder = Color3.fromHex("#7c3aed"),
    SearchBarBorderTransparency = .60,

    Notification = Color3.fromHex("#0d0d1a"),
    NotificationTitle = Color3.fromHex("#e2e8f0"),
    NotificationTitleTransparency = 0,
    NotificationContent = Color3.fromHex("#a78bfa"),
    NotificationContentTransparency = .2,
    NotificationDuration = Color3.fromHex("#7c3aed"),
    NotificationDurationTransparency = .80,
    NotificationBorder = Color3.fromHex("#7c3aed"),
    NotificationBorderTransparency = .60,

    DropdownTabBorder = Color3.fromHex("#7c3aed"),

    LabelBackground = Color3.fromHex("#1a1040"),
    LabelBackgroundTransparency = .90,
  }
end

return Theme