--[made by harve & 11phhs]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if env.PrestigeV1 and env.PrestigeV1.Unload then
    pcall(function()
        env.PrestigeV1:Unload()
    end)
end

local IDS = {
    Button = 80066181348863,
    Pumpkin = 91532206722872,
    Music = 108626632719375,
    Logo = 132729378030405,
    Wallpaper = 122419979458694,
    Notify = 133118130342644,
    Intro = 113232781731862,
    Main = 135962296175199,
    Player = 132353928218632,
    Visuals = 136812801080702,
    Misc = 92721198018554,
    Settings = 77932102403882,
    Cursor = 133503646419192,
    Rain = 95747911382442,
}

local Sounds = {
    Hover = "rbxasset://sounds/clickfast.wav",
    Click = "rbxassetid://7322736504",
}

local function asset(id)
    return "rbxassetid://" .. tostring(id)
end

local W, H = 780, 500
local SUBW = 108
local TABW, TABH = 54, 46
local ROWH = 38

local Library = {
    HudToggles = {},
    Flags = {},
    Options = {},
    Connections = {},
    Tabs = {},
    Current = nil,
}

local Default = {
    Accent = Color3.fromRGB(255, 132, 38),
    Background = Color3.fromRGB(13, 12, 17),
    Surface = Color3.fromRGB(21, 20, 27),
    Text = Color3.fromRGB(238, 235, 242),
}

local Theme = {
    Accent = Default.Accent,
    Background = Default.Background,
    Surface = Default.Surface,
    Text = Default.Text,
    Font = Enum.Font.GothamMedium,
    TextScale = 1,
}

local function deriveTheme()
    Theme.Element = Theme.Surface:Lerp(Theme.Text, 0.07)
    Theme.SubText = Theme.Text:Lerp(Theme.Background, 0.45)
    Theme.Off = Theme.Surface:Lerp(Theme.Text, 0.2)
    Theme.Stroke = Theme.Surface:Lerp(Theme.Text, 0.16)
end
deriveTheme()

local gui = Instance.new("ScreenGui")
gui.Name = HttpService:GenerateGUID(false)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

do
    local ok = pcall(function()
        if type(gethui) == "function" then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local cleanups = {}
local function onUnload(fn)
    table.insert(cleanups, fn)
end

local autoScale, fitScale = 1, 1
local function measure()
    local v = gui.AbsoluteSize
    if v.X < 50 or v.Y < 50 then
        return
    end
    fitScale = math.max(0.3, math.min((v.X - 8) / W, (v.Y - 8) / H))
    autoScale = math.clamp(math.min(1, math.min((v.X - 24) / W, (v.Y - 24) / H)), 0.35, 1)
end
measure()

local function targetScale()
    local user = (Library.Flags.UIScale or 100) / 100
    return math.clamp(autoScale * user, 0.3, fitScale)
end

local function tween(inst, time, props, style, dir)
    if time <= 0 then
        for k, v in pairs(props) do
            inst[k] = v
        end
        return nil
    end
    local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function new(class, props)
    local inst = Instance.new(class)
    local parent = nil
    for k, v in pairs(props) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local themed, themeFns, texts = {}, {}, {}

local function themeBind(inst, prop, key)
    table.insert(themed, {inst, prop, key})
    inst[prop] = Theme[key]
end

local function onTheme(fn)
    table.insert(themeFns, fn)
end

local function applyTheme()
    deriveTheme()
    for i = #themed, 1, -1 do
        local e = themed[i]
        if e[1].Parent then
            e[1][e[2]] = Theme[e[3]]
        else
            table.remove(themed, i)
        end
    end
    for i = #texts, 1, -1 do
        local e = texts[i]
        if e.inst.Parent then
            e.inst.Font = Theme.Font
            e.inst.TextSize = math.max(8, math.floor(e.size * Theme.TextScale + 0.5))
        else
            table.remove(texts, i)
        end
    end
    for _, fn in ipairs(themeFns) do
        pcall(fn)
    end
end

local function corner(inst, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius), Parent = inst})
end

local function stroke(inst, key, thickness, transparency)
    local s = new("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
    themeBind(s, "Color", key or "Stroke")
    return s
end

local function textObj(class, props, colorKey)
    props.BorderSizePixel = 0
    if props.BackgroundTransparency == nil then
        props.BackgroundTransparency = 1
    end
    props.Font = Theme.Font
    props.TextSize = props.TextSize or 14
    if class == "TextButton" then
        props.AutoButtonColor = false
    end
    local base = props.TextSize
    local inst = new(class, props)
    inst.TextSize = math.max(8, math.floor(base * Theme.TextScale + 0.5))
    table.insert(texts, {inst = inst, size = base})
    if colorKey then
        themeBind(inst, "TextColor3", colorKey)
    end
    return inst
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function pointer(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(input.Position.X, input.Position.Y)
    end
    return UserInputService:GetMouseLocation()
end

local touchPos = nil
local activeMove, activeEnd, activeScroll
local function startDrag(lockInst, onMove, onEnd, initial)
    activeMove = onMove
    activeEnd = onEnd
    activeScroll = nil
    if lockInst then
        local sf = lockInst:FindFirstAncestorOfClass("ScrollingFrame")
        if sf then
            sf.ScrollingEnabled = false
            activeScroll = sf
        end
    end
    if initial then
        onMove(pointer(initial))
    end
end

local function stopDrag()
    if not activeMove then
        return
    end
    local finish = activeEnd
    if activeScroll then
        activeScroll.ScrollingEnabled = true
    end
    activeMove, activeEnd, activeScroll = nil, nil, nil
    if finish then
        finish()
    end
end

connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchPos = Vector2.new(input.Position.X, input.Position.Y)
    end
    if activeMove and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        activeMove(pointer(input))
    end
end)

connect(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchPos = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        touchPos = nil
    end
    if isPress(input) then
        stopDrag()
    end
end)

local function playSound(id, volume, speed)
    local vol = volume * ((Library.Flags.EffectsVolume or 60) / 100)
    if vol <= 0 then
        return
    end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol
    s.PlaybackSpeed = speed or 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
    end)
    task.delay(8, function()
        if s.Parent then
            s:Destroy()
        end
    end)
end

local lastHover = 0
local function hoverFx()
    local now = os.clock()
    if now - lastHover < 0.07 then
        return
    end
    lastHover = now
    if Library.Flags.HoverSound ~= false then
        playSound(Sounds.Hover, 0.16, 1.9 + math.random() * 0.4)
    end
end

local function clickFx()
    if Library.Flags.HoverSound ~= false then
        playSound(Sounds.Click, 0.55, 1)
    end
end

local scrim = new("TextButton", {
    Name = "Scrim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    Modal = false,
    ZIndex = 1,
    Visible = false,
    Parent = gui,
})
local function scrimTarget()
    return 1 - (Library.Flags.ScrimDarkness or 55) / 100
end

local bgLayer = new("Frame", {
    Name = "Pumpkins",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
    Visible = false,
    Parent = gui,
})

local pumpkins = {}
local fxAlpha = 0

local function screenSize()
    local v = gui.AbsoluteSize
    if v.X < 50 or v.Y < 50 then
        return Vector2.new(1280, 720)
    end
    return v
end

local function placePumpkin(p, first)
    local v = screenSize()
    p.x = math.random() * v.X
    if first then
        p.y = math.random() * v.Y
    else
        p.y = -p.size - math.random(0, 140)
    end
end

for i = 1, 26 do
    local depth = math.random()
    local size = math.floor(18 + depth * 42)
    local img = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Image = asset(IDS.Pumpkin),
        Rotation = math.random(0, 360),
        ZIndex = 1 + math.floor(depth * 10),
        Parent = bgLayer,
    })
    local p = {
        inst = img,
        size = size,
        speed = 34 + depth * 80,
        sway = 8 + math.random() * 24,
        phase = math.random() * 6.28,
        spin = math.random(-40, 40),
        base = 0.6 - depth * 0.45,
        x = 0,
        y = 0,
    }
    placePumpkin(p, true)
    pumpkins[i] = p
end

local trailLayer = new("Frame", {
    Name = "Trail",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 60,
    Parent = gui,
})
local drops = {}
local lastMouse = nil
local carry = 0

local function spawnDrop(x, y)
    if #drops >= 120 then
        return
    end
    local size = math.random(14, 26)
    local f = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromOffset(x, y),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = asset(IDS.Rain),
        ImageTransparency = 0.05,
        Rotation = math.random(-25, 25),
        Parent = trailLayer,
    })
    table.insert(drops, {
        f = f,
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 60,
        vy = math.random(20, 90),
        life = 0.7 + math.random() * 0.6,
        age = 0,
        spin = math.random(-70, 70),
    })
end

local cursor = new("ImageLabel", {
    Name = "Crosshair",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(36, 36),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    Image = asset(IDS.Cursor),
    ImageTransparency = 1,
    ZIndex = 100,
    Visible = false,
    Parent = gui,
})
local cursorScale = new("UIScale", {Scale = 1, Parent = cursor})
local cursorActive = false
local cursorAlpha = 0
local prevIcon, prevBehavior = true, Enum.MouseBehavior.Default

local function enterCursor()
    if cursorActive then
        return
    end
    cursorActive = true
    prevIcon = UserInputService.MouseIconEnabled
    prevBehavior = UserInputService.MouseBehavior
end

local function exitCursor()
    if not cursorActive then
        return
    end
    cursorActive = false
    local restore = Library.Flags.RestoreLock == true
    pcall(function()
        if restore and prevBehavior == Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = prevIcon
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    end)
end

function Library:FixMouse()
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

RunService:BindToRenderStep("PrestigeCursor", Enum.RenderPriority.Last.Value, function(dt)
    local show = cursorActive and Library.Flags.Crosshair ~= false and UserInputService.MouseEnabled
    if cursorActive then
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        UserInputService.MouseIconEnabled = not show and prevIcon or false
    end
    local target = show and 1 or 0
    cursorAlpha = cursorAlpha + (target - cursorAlpha) * (1 - math.exp(-dt * 20))
    if cursorAlpha < 0.02 and target == 0 then
        cursor.Visible = false
    else
        cursor.Visible = true
        cursor.ImageTransparency = 1 - cursorAlpha
        local m = UserInputService:GetMouseLocation()
        cursor.Position = UDim2.fromOffset(m.X, m.Y)
    end
end)

connect(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and cursorActive then
        tween(cursorScale, 0.1, {Scale = 0.75}, Enum.EasingStyle.Quad)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        tween(cursorScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
    end
end)

local windowScale
local holder = new("Frame", {
    Name = "Holder",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    ZIndex = 5,
    Parent = gui,
})
windowScale = new("UIScale", {Scale = 1, Parent = holder})

local shadowA = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(0, 10),
    Size = UDim2.fromOffset(W + 46, H + 46),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = holder,
})
corner(shadowA, 36)
local shadowB = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(0, 6),
    Size = UDim2.fromOffset(W + 16, H + 16),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = holder,
})
corner(shadowB, 24)

local window = new("CanvasGroup", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(W, H),
    BorderSizePixel = 0,
    GroupTransparency = 1,
    Visible = false,
    Parent = holder,
})
themeBind(window, "BackgroundColor3", "Background")
corner(window, 18)

local wallpaper = new("ImageLabel", {
    Name = "Wallpaper",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = asset(IDS.Wallpaper),
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.15,
    ZIndex = 1,
    Parent = window,
})

local dim = new("Frame", {
    Name = "Dim",
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    BackgroundTransparency = 0.5,
    ZIndex = 2,
    Parent = window,
})
themeBind(dim, "BackgroundColor3", "Background")

local topGlow = new("Frame", {
    Name = "TopGlow",
    Size = UDim2.new(1, 0, 0, 220),
    BorderSizePixel = 0,
    BackgroundTransparency = 0,
    ZIndex = 3,
    Parent = window,
})
themeBind(topGlow, "BackgroundColor3", "Accent")
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.86),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = topGlow,
})

local topbar = new("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundTransparency = 1,
    ZIndex = 10,
    Parent = window,
})

local headLine = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 55),
    Size = UDim2.new(1, -48, 0, 1),
    BorderSizePixel = 0,
    Parent = topbar,
})
themeBind(headLine, "BackgroundColor3", "Accent")
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = headLine,
})

new("ImageLabel", {
    Position = UDim2.fromOffset(20, 12),
    Size = UDim2.fromOffset(32, 32),
    BackgroundTransparency = 1,
    Image = asset(IDS.Logo),
    ScaleType = Enum.ScaleType.Fit,
    Parent = topbar,
})

local title = textObj("TextLabel", {
    Position = UDim2.fromOffset(60, 0),
    Size = UDim2.new(0, 200, 1, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true,
    TextSize = 20,
    Text = "Prestige V1",
    Parent = topbar,
}, "Text")
local function setTitle()
    title.Text = 'Prestige <font color="#' .. Theme.Accent:ToHex() .. '">V1</font>'
end
onTheme(setTitle)
setTitle()

local closeBtn = textObj("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -18, 0.5, 0),
    Size = UDim2.fromOffset(30, 30),
    BackgroundTransparency = 1,
    Text = "×",
    TextSize = 24,
    Parent = topbar,
}, "SubText")
corner(closeBtn, 15)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)

local profile = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -58, 0.5, 0),
    Size = UDim2.fromOffset(230, 40),
    BackgroundTransparency = 1,
    Parent = topbar,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = profile,
})

local names = new("Frame", {
    LayoutOrder = 1,
    Size = UDim2.fromOffset(176, 36),
    BackgroundTransparency = 1,
    Parent = profile,
})
textObj("TextLabel", {
    Position = UDim2.fromOffset(0, 2),
    Size = UDim2.new(1, 0, 0, 17),
    Text = LocalPlayer.DisplayName,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 14,
    Parent = names,
}, "Text")
textObj("TextLabel", {
    Position = UDim2.fromOffset(0, 19),
    Size = UDim2.new(1, 0, 0, 15),
    Text = "@" .. LocalPlayer.Name,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 12,
    Parent = names,
}, "SubText")

local avatar = new("ImageLabel", {
    LayoutOrder = 2,
    Size = UDim2.fromOffset(36, 36),
    BackgroundTransparency = 0,
    Parent = profile,
})
themeBind(avatar, "BackgroundColor3", "Element")
corner(avatar, 18)
stroke(avatar, "Accent", 2, 0)

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and img then
        avatar.Image = img
    end
end)

local pageHolder = new("Frame", {
    Name = "Pages",
    Position = UDim2.fromOffset(20, 110),
    Size = UDim2.new(1, -40, 1, -110),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 6,
    Parent = window,
})

local pageFade = new("Frame", {
    Name = "PageFade",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 110),
    BorderSizePixel = 0,
    ZIndex = 8,
    Parent = window,
})
themeBind(pageFade, "BackgroundColor3", "Background")
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.08),
    }),
    Parent = pageFade,
})

local dockShadow = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -8),
    Size = UDim2.fromOffset(200, 70),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ZIndex = 19,
    Parent = window,
})
corner(dockShadow, 30)

local dock = new("Frame", {
    Name = "Dock",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -14),
    Size = UDim2.fromOffset(200, 58),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex = 20,
    Parent = window,
})
themeBind(dock, "BackgroundColor3", "Surface")
corner(dock, 26)
stroke(dock, "Stroke", 1, 0.2)

local dockInd = new("Frame", {
    Position = UDim2.fromOffset(10, 6),
    Size = UDim2.fromOffset(TABW, TABH),
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 20,
    Parent = dock,
})
themeBind(dockInd, "BackgroundColor3", "Accent")
corner(dockInd, 20)
stroke(dockInd, "Accent", 1, 0.55)

local dockDivider = new("Frame", {
    Position = UDim2.fromOffset(0, 17),
    Size = UDim2.fromOffset(1, 24),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 21,
    Parent = dock,
})
themeBind(dockDivider, "BackgroundColor3", "Stroke")

local dockW = 200
local function layoutDock()
    local x = 10
    local seenBottom = false
    dockDivider.Visible = false
    for i, tab in ipairs(Library.Tabs) do
        if tab.Bottom and not seenBottom and i > 1 then
            seenBottom = true
            x = x + 4
            dockDivider.Position = UDim2.fromOffset(x, 17)
            dockDivider.Visible = true
            x = x + 9
        end
        tab.X = x
        tab.Button.Position = UDim2.fromOffset(x, 6)
        x = x + TABW + 4
    end
    dockW = x - 4 + 10
    dock.Size = UDim2.fromOffset(dockW, 58)
    dockShadow.Size = UDim2.fromOffset(dockW + 14, 72)
end

local tip = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 1),
    Size = UDim2.fromOffset(80, 26),
    Position = UDim2.fromOffset(W / 2, H - 80),
    BorderSizePixel = 0,
    GroupTransparency = 1,
    ZIndex = 22,
    Parent = window,
})
themeBind(tip, "BackgroundColor3", "Surface")
corner(tip, 13)
stroke(tip, "Stroke", 1, 0.2)
local tipLabel = textObj("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    Text = "",
    TextSize = 12,
    ZIndex = 23,
    Parent = tip,
}, "Text")

local function showTip(tab)
    tipLabel.Text = tab.Name
    tip.Size = UDim2.fromOffset(math.max(58, #tab.Name * 8 + 26), 26)
    tip.Position = UDim2.fromOffset(W / 2 - dockW / 2 + tab.X + TABW / 2, H - 80)
    tween(tip, 0.18, {GroupTransparency = 0})
end

local function hideTip()
    tween(tip, 0.18, {GroupTransparency = 1})
end

local edge = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 30,
    Parent = window,
})
corner(edge, 18)
local edgeStroke = stroke(edge, "Accent", 1.5, 0)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.88),
        NumberSequenceKeypoint.new(1, 0.4),
    }),
    Parent = edgeStroke,
})

local holderPos = Vector2.new(0, 0)
local holderGoal = Vector2.new(0, 0)

local function clampGoal(p)
    local v = gui.AbsoluteSize
    return Vector2.new(math.clamp(p.X, 80, math.max(80, v.X - 80)), math.clamp(p.Y, 60, math.max(60, v.Y - 60)))
end

local function centerHolder()
    local v = gui.AbsoluteSize
    holderGoal = Vector2.new(v.X / 2, v.Y / 2)
    holderPos = holderGoal
    holder.Position = UDim2.fromOffset(holderPos.X, holderPos.Y)
end
centerHolder()

topbar.InputBegan:Connect(function(input)
    if not isPress(input) then
        return
    end
    local start = pointer(input)
    local origin = holderGoal
    startDrag(nil, function(pos)
        holderGoal = clampGoal(origin + (pos - start))
    end)
end)

local windowVisible = false
local openToken = 0
local music = new("Sound", {
    Name = "PrestigeMusic",
    SoundId = asset(IDS.Music),
    Looped = true,
    Volume = 0,
    Parent = SoundService,
})
local musicToken = 0

connect(music.Ended, function()
    if windowVisible and Library.Flags.MusicEnabled ~= false and Library.Flags.MusicLoop ~= false then
        music.TimePosition = 0
        music:Play()
    end
end)

local function musicOn()
    if Library.Flags.MusicEnabled == false then
        return
    end
    musicToken = musicToken + 1
    if not music.IsPlaying then
        if music.IsPaused then
            music:Resume()
        else
            music:Play()
        end
    end
    tween(music, 0.8, {Volume = (Library.Flags.MusicVolume or 40) / 100}, Enum.EasingStyle.Quad)
end

local function musicOff()
    musicToken = musicToken + 1
    local token = musicToken
    tween(music, 0.4, {Volume = 0}, Enum.EasingStyle.Quad)
    task.delay(0.42, function()
        if musicToken == token then
            music:Pause()
        end
    end)
end

function Library:Open()
    if windowVisible then
        return
    end
    windowVisible = true
    openToken = openToken + 1
    window.Visible = true
    scrim.Visible = true
    enterCursor()
    scrim.Modal = true
    tween(scrim, 0.45, {BackgroundTransparency = scrimTarget()}, Enum.EasingStyle.Quad)
    window.Position = UDim2.fromOffset(0, 18)
    windowScale.Scale = targetScale() * 0.9
    tween(window, 0.4, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)})
    tween(windowScale, 0.55, {Scale = targetScale()}, Enum.EasingStyle.Back)
    tween(shadowA, 0.5, {BackgroundTransparency = 0.84})
    tween(shadowB, 0.5, {BackgroundTransparency = 0.72})
    musicOn()
end

function Library:Close()
    if not windowVisible then
        return
    end
    windowVisible = false
    openToken = openToken + 1
    local token = openToken
    hideTip()
    if Library.CloseModeMenu then
        Library.CloseModeMenu()
    end
    scrim.Modal = false
    tween(scrim, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
    exitCursor()
    tween(window, 0.28, {GroupTransparency = 1, Position = UDim2.fromOffset(0, 12)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(windowScale, 0.28, {Scale = targetScale() * 0.94}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(shadowA, 0.25, {BackgroundTransparency = 1})
    tween(shadowB, 0.25, {BackgroundTransparency = 1})
    musicOff()
    task.delay(0.3, function()
        if not windowVisible and openToken == token then
            window.Visible = false
            scrim.Visible = false
        end
    end)
end

function Library:Toggle()
    if windowVisible then
        Library:Close()
    else
        Library:Open()
    end
end

closeBtn.MouseEnter:Connect(function()
    tween(closeBtn, 0.2, {BackgroundTransparency = 0.15})
    hoverFx()
end)
closeBtn.MouseLeave:Connect(function()
    tween(closeBtn, 0.25, {BackgroundTransparency = 1})
end)
closeBtn.MouseButton1Click:Connect(function()
    clickFx()
    Library:Close()
end)

local notifyHolder = new("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 340, 1, -40),
    BackgroundTransparency = 1,
    ZIndex = 50,
    Parent = gui,
})
local notifyScale = new("UIScale", {Scale = autoScale, Parent = notifyHolder})
new("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = notifyHolder,
})

local notifyColors = {
    Success = Color3.fromRGB(96, 214, 142),
    Warning = Color3.fromRGB(255, 190, 70),
    Error = Color3.fromRGB(240, 92, 92),
}

local notifyId = 0
function Library:Notify(cfg)
    cfg = cfg or {}
    notifyId = notifyId + 1
    local duration = cfg.Duration or 3.5
    local tint = notifyColors[cfg.Type] or Theme.Accent

    local container = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = notifyId,
        Parent = notifyHolder,
    })
    local card = new("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 360, 0, 0),
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Parent = container,
    })
    themeBind(card, "BackgroundColor3", "Surface")
    corner(card, 16)
    stroke(card, "Stroke", 1, 0.25)

    local glow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BorderSizePixel = 0,
        BackgroundColor3 = tint,
        Parent = card,
    })
    new("UIGradient", {
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = glow,
    })

    local iconBox = new("Frame", {
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(38, 38),
        BackgroundColor3 = tint,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(iconBox, 12)
    new("UIStroke", {Color = tint, Transparency = 0.6, Thickness = 1, Parent = iconBox})
    new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Image = asset(IDS.Logo),
        ScaleType = Enum.ScaleType.Fit,
        Parent = iconBox,
    })

    local body = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 13),
        PaddingBottom = UDim.new(0, 22),
        PaddingLeft = UDim.new(0, 64),
        PaddingRight = UDim.new(0, 16),
        Parent = body,
    })
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body})
    textObj("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Text = cfg.Title or "Prestige V1",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 15,
        LayoutOrder = 1,
        Parent = body,
    }, "Text")
    textObj("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = cfg.Content or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextSize = 13,
        LayoutOrder = 2,
        Parent = body,
    }, "SubText")

    local track = new("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -10),
        Size = UDim2.new(1, -32, 0, 3),
        BackgroundColor3 = tint,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(track, 2)
    local progress = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = tint,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(progress, 2)

    playSound(asset(IDS.Notify), 0.6, 1)
    tween(card, 0.55, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}, Enum.EasingStyle.Back)
    tween(progress, duration, {Size = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not container.Parent then
            return
        end
        tween(card, 0.4, {Position = UDim2.new(0, 360, 0, 0), GroupTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.35)
        if not container.Parent then
            return
        end
        local h = container.AbsoluteSize.Y / math.max(notifyScale.Scale, 0.01)
        container.AutomaticSize = Enum.AutomaticSize.None
        container.Size = UDim2.new(1, 0, 0, h)
        tween(container, 0.3, {Size = UDim2.new(1, 0, 0, 0)})
        task.wait(0.32)
        container:Destroy()
    end)
end

local Tab = {}
Tab.__index = Tab
local SubTab = {}
SubTab.__index = SubTab
local Section = {}
Section.__index = Section

local currentPage = nil
local function showPage(sub, dir)
    dir = dir or 1
    local old = currentPage
    if old == sub then
        return
    end
    currentPage = sub
    if old then
        local p = old.Page
        tween(p, 0.2, {GroupTransparency = 1, Position = UDim2.fromOffset(-dir * 30, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.22, function()
            if currentPage ~= old then
                p.Visible = false
            end
        end)
    end
    local np = sub.Page
    np.Visible = true
    np.GroupTransparency = 1
    np.Position = UDim2.fromOffset(dir * 30, 0)
    tween(np, 0.5, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)})
end

local function setSubBar(tab, show)
    local bar = tab.SubBar
    if show then
        bar.Visible = true
        bar.Position = UDim2.new(0.5, 0, 0, 72)
        bar.GroupTransparency = 1
        tween(bar, 0.4, {GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0, 66)})
    else
        tween(bar, 0.2, {GroupTransparency = 1})
        task.delay(0.22, function()
            if Library.Current ~= tab then
                bar.Visible = false
            end
        end)
    end
end

local dockIndReady = false
local function moveDockInd(tab)
    dockInd.Visible = true
    if not dockIndReady then
        dockIndReady = true
        dockInd.Position = UDim2.fromOffset(tab.X, 6)
    else
        tween(dockInd, 0.45, {Position = UDim2.fromOffset(tab.X, 6)}, Enum.EasingStyle.Back)
    end
end

function Tab:Render()
    local active = Library.Current == self
    local color = Theme.SubText
    if active then
        color = Theme.Accent
    elseif self.Hover then
        color = Theme.Text
    end
    local size = (self.Hover or active) and 27 or 24
    tween(self.Icon, 0.25, {ImageColor3 = color, Size = UDim2.fromOffset(size, size)}, Enum.EasingStyle.Back)
end

function Tab:Select()
    if Library.Current == self then
        return
    end
    local old = Library.Current
    local dir = (old and self.Index < old.Index) and -1 or 1
    Library.Current = self
    if old then
        setSubBar(old, false)
    end
    setSubBar(self, true)
    moveDockInd(self)
    for _, t in ipairs(Library.Tabs) do
        t:Render()
    end
    local sub = self.Current or self.SubTabs[1]
    if sub then
        sub:Select(dir)
    end
end

function SubTab:Render()
    local active = self.Tab.Current == self
    local color = Theme.SubText
    if active then
        color = Theme.Text
    elseif self.Hover then
        color = Theme.Text:Lerp(Theme.SubText, 0.4)
    end
    tween(self.Button, 0.25, {TextColor3 = color})
end

function SubTab:Select(dir)
    local tab = self.Tab
    tab.Current = self
    for _, s in ipairs(tab.SubTabs) do
        s:Render()
    end
    local pos = UDim2.fromOffset((self.Index - 1) * SUBW + 4, 4)
    if tab.IndicatorReady then
        tween(tab.Indicator, 0.45, {Position = pos}, Enum.EasingStyle.Back)
    else
        tab.IndicatorReady = true
        tab.Indicator.Position = pos
    end
    tab.Indicator.Visible = true
    showPage(self, dir)
end

function Library:AddTab(name, icon, bottom)
    local tab = setmetatable({
        Name = name,
        SubTabs = {},
        Hover = false,
        Bottom = bottom and true or false,
        Index = #Library.Tabs + 1,
        X = 10,
    }, Tab)
    local btn = new("TextButton", {
        Name = name,
        Size = UDim2.fromOffset(TABW, TABH),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 21,
        Parent = dock,
    })
    tab.Button = btn
    tab.Icon = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Image = asset(icon),
        ImageColor3 = Theme.SubText,
        ZIndex = 22,
        Parent = btn,
    })

    local sub = new("CanvasGroup", {
        Name = name,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 66),
        Size = UDim2.fromOffset(SUBW + 8, 36),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 10,
        Parent = window,
    })
    themeBind(sub, "BackgroundColor3", "Surface")
    corner(sub, 18)
    stroke(sub, "Stroke", 1, 0.3)
    tab.SubBar = sub
    tab.Indicator = new("Frame", {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(SUBW, 28),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 11,
        Parent = sub,
    })
    themeBind(tab.Indicator, "BackgroundColor3", "Accent")
    corner(tab.Indicator, 14)
    stroke(tab.Indicator, "Accent", 1, 0.55)

    btn.MouseEnter:Connect(function()
        tab.Hover = true
        tab:Render()
        showTip(tab)
        hoverFx()
    end)
    btn.MouseLeave:Connect(function()
        tab.Hover = false
        tab:Render()
        hideTip()
    end)
    btn.MouseButton1Click:Connect(function()
        clickFx()
        tab:Select()
    end)
    onTheme(function()
        tab:Render()
    end)
    table.insert(Library.Tabs, tab)
    layoutDock()
    if #Library.Tabs == 1 then
        tab:Select()
    else
        tab:Render()
    end
    return tab
end

local function column(parent, order)
    local c = new("Frame", {
        Size = UDim2.new(0.5, -7, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parent,
    })
    new("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = c})
    return c
end

function Tab:AddSubTab(name)
    local index = #self.SubTabs + 1
    local sub = setmetatable({Name = name, Tab = self, Index = index, LeftCount = 0, RightCount = 0, Hover = false}, SubTab)
    self.SubBar.Size = UDim2.fromOffset(index * SUBW + 8, 36)
    self.Indicator.Size = UDim2.fromOffset(SUBW, 28)
    local btn = textObj("TextButton", {
        Name = name,
        Position = UDim2.fromOffset((index - 1) * SUBW + 4, 4),
        Size = UDim2.fromOffset(SUBW, 28),
        BackgroundTransparency = 1,
        Text = name,
        TextSize = 13,
        ZIndex = 12,
        Parent = self.SubBar,
    }, "SubText")
    sub.Button = btn

    local page = new("CanvasGroup", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = pageHolder,
    })
    local scroll = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = page,
    })
    themeBind(scroll, "ScrollBarImageColor3", "Accent")
    new("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 100),
        Parent = scroll,
    })
    local cols = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = scroll,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = cols,
    })
    sub.Page = page
    sub.Left = column(cols, 1)
    sub.Right = column(cols, 2)

    btn.MouseEnter:Connect(function()
        sub.Hover = true
        sub:Render()
        hoverFx()
    end)
    btn.MouseLeave:Connect(function()
        sub.Hover = false
        sub:Render()
    end)
    btn.MouseButton1Click:Connect(function()
        clickFx()
        local old = self.Current
        if old ~= sub then
            local dir = (old and sub.Index < old.Index) and -1 or 1
            sub:Select(dir)
        end
    end)
    onTheme(function()
        sub:Render()
    end)
    table.insert(self.SubTabs, sub)
    sub:Render()
    if index == 1 and Library.Current == self then
        sub:Select(1)
    end
    return sub
end

function SubTab:AddSection(titleText, side)
    local col
    if side == "Right" then
        col = self.Right
    elseif side == "Left" then
        col = self.Left
    else
        col = (self.LeftCount <= self.RightCount) and self.Left or self.Right
    end
    if col == self.Left then
        self.LeftCount = self.LeftCount + 1
    else
        self.RightCount = self.RightCount + 1
    end
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self.LeftCount + self.RightCount,
        Parent = col,
    })
    new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap})
    local head = textObj("TextLabel", {
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.fromOffset(4, 0),
        Text = titleText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 14,
        LayoutOrder = 0,
        Parent = wrap,
    }, "Accent")
    new("UIPadding", {PaddingLeft = UDim.new(0, 4), Parent = head})
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = wrap,
    })
    themeBind(box, "BackgroundColor3", "Surface")
    corner(box, 14)
    stroke(box, "Stroke", 1, 0.35)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = box,
    })
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box})
    return setmetatable({Box = box, Count = 0}, Section)
end

local function newRow(section, height, solid)
    section.Count = section.Count + 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = solid and 0.35 or 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = section.Count,
        Parent = section.Box,
    })
    themeBind(row, "BackgroundColor3", solid and "Element" or "Text")
    corner(row, 10)
    row:SetAttribute("Rest", solid and 0.35 or 1)
    row:SetAttribute("Hover", solid and 0.15 or 0.93)
    return row
end

local function hitButton(row, height)
    return new("TextButton", {
        Name = "Hit",
        Size = UDim2.new(1, 0, 0, height or ROWH),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2,
        Parent = row,
    })
end

local function bindRow(row, hit)
    hit.MouseEnter:Connect(function()
        tween(row, 0.2, {BackgroundTransparency = row:GetAttribute("Hover")})
        hoverFx()
    end)
    hit.MouseLeave:Connect(function()
        tween(row, 0.28, {BackgroundTransparency = row:GetAttribute("Rest")})
    end)
end

local function rowLabel(row, text, width)
    return textObj("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, width or -70, 0, ROWH),
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 14,
        Parent = row,
    }, "Text")
end

local function commit(obj, cfg, silent)
    if obj.Flag then
        Library.Flags[obj.Flag] = obj.Value
    end
    if obj.Listeners then
        for _, fn in ipairs(obj.Listeners) do
            pcall(fn, obj.Value)
        end
    end
    if not silent and cfg.Callback then
        task.spawn(pcall, cfg.Callback, obj.Value)
    end
end

local function register(obj)
    obj.Default = obj.Value
    if obj.Flag then
        Library.Flags[obj.Flag] = obj.Value
        Library.Options[obj.Flag] = obj
    end
end

local newKeyButton
do
    local listening = nil
    local keybinds = {}

    local function inputName(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Unknown then
                return nil
            end
            return input.KeyCode.Name
        elseif t == Enum.UserInputType.MouseButton2 then
            return "MouseButton2"
        elseif t == Enum.UserInputType.MouseButton3 then
            return "MouseButton3"
        end
        return nil
    end

    local function keyDisplay(name)
        if name == nil or name == "None" or name == "" then
            return "None"
        end
        return (tostring(name):gsub("MouseButton", "MB"))
    end

    local function cancelListening()
        if listening then
            local l = listening
            listening = nil
            l.cancel()
        end
    end

    local function keyConflict(entry)
        if entry.Value == "None" then
            return nil
        end
        for _, other in ipairs(keybinds) do
            if other ~= entry and other.Value == entry.Value then
                return other
            end
        end
        return nil
    end

    local modeMenu = nil
    local modeNames = {"Toggle", "Hold", "Always"}

    local function closeModeMenu()
        local m = modeMenu
        if not m then
            return
        end
        modeMenu = nil
        tween(m.Card, 0.2, {GroupTransparency = 1, Position = m.Card.Position + UDim2.fromOffset(0, -6)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.24, function()
            m.Root:Destroy()
        end)
    end
    Library.CloseModeMenu = closeModeMenu

    local function openModeMenu(box, current, onPick)
        closeModeMenu()
        local scale = math.max(windowScale.Scale, 0.1)
        local view = gui.AbsoluteSize
        local width, height = 108, 100
        local root = new("Frame", {
            Name = "ModeMenu",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 80,
            Parent = gui,
        })
        local catcher = new("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 80,
            Parent = root,
        })
        local ax = box.AbsolutePosition.X + box.AbsoluteSize.X
        local ay = box.AbsolutePosition.Y + box.AbsoluteSize.Y + 6 * scale
        if ay + height * scale > view.Y - 8 then
            ay = box.AbsolutePosition.Y - 6 * scale - height * scale
        end
        ax = math.clamp(ax, width * scale + 8, math.max(view.X - 8, width * scale + 8))
        local goal = UDim2.fromOffset(ax, ay)
        local card = new("CanvasGroup", {
            AnchorPoint = Vector2.new(1, 0),
            Position = goal + UDim2.fromOffset(0, -8),
            Size = UDim2.fromOffset(width, height),
            BorderSizePixel = 0,
            GroupTransparency = 1,
            ZIndex = 81,
            Parent = root,
        })
        themeBind(card, "BackgroundColor3", "Surface")
        corner(card, 12)
        stroke(card, "Stroke", 1, 0.1)
        new("UIScale", {Scale = scale, Parent = card})
        local currentIdx = table.find(modeNames, current) or 1
        local hl = new("Frame", {
            Position = UDim2.fromOffset(5, 5 + (currentIdx - 1) * 30),
            Size = UDim2.new(1, -10, 0, 28),
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 82,
            Parent = card,
        })
        themeBind(hl, "BackgroundColor3", "Accent")
        corner(hl, 8)
        stroke(hl, "Accent", 1, 0.55)
        for i, name in ipairs(modeNames) do
            local b = textObj("TextButton", {
                Position = UDim2.fromOffset(5, 5 + (i - 1) * 30),
                Size = UDim2.new(1, -10, 0, 28),
                Text = name,
                TextSize = 13,
                ZIndex = 83,
                Parent = card,
            }, "SubText")
            b.TextColor3 = i == currentIdx and Theme.Accent or Theme.SubText
            b.MouseEnter:Connect(function()
                hoverFx()
                tween(hl, 0.22, {Position = UDim2.fromOffset(5, 5 + (i - 1) * 30)}, Enum.EasingStyle.Quint)
                tween(b, 0.15, {TextColor3 = i == currentIdx and Theme.Accent or Theme.Text})
            end)
            b.MouseLeave:Connect(function()
                tween(b, 0.2, {TextColor3 = i == currentIdx and Theme.Accent or Theme.SubText})
            end)
            b.MouseButton1Click:Connect(function()
                clickFx()
                pcall(onPick, name)
                closeModeMenu()
            end)
        end
        catcher.MouseButton1Click:Connect(closeModeMenu)
        catcher.MouseButton2Click:Connect(closeModeMenu)
        modeMenu = {Root = root, Card = card}
        tween(card, 0.32, {GroupTransparency = 0, Position = goal}, Enum.EasingStyle.Quint)
    end

    newKeyButton = function(parent, entry, opts)
        entry.Value = entry.Value or "None"
        entry.Down = false
        local cfg = opts.Cfg or {}
        local z = opts.Z or 3
        local box = new("Frame", {
            AnchorPoint = opts.Anchor,
            Position = opts.Position,
            Size = opts.Size,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = z,
            Parent = parent,
        })
        themeBind(box, "BackgroundColor3", "Background")
        corner(box, opts.Radius or 8)
        local outline = stroke(box, "Stroke", 1, 0)
        local btn = textObj("TextButton", {
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = opts.TextSize or 12,
            ZIndex = z + 1,
            Parent = box,
        })
        local isListening = false
        local boundAt = 0

        local function render()
            if isListening then
                btn.Text = "..."
                btn.TextColor3 = Theme.Accent
                outline.Color = Theme.Accent
            else
                btn.Text = keyDisplay(entry.Value)
                if entry.Value == "None" then
                    btn.TextColor3 = Theme.SubText
                elseif entry.Mode and entry.Mode ~= "Toggle" then
                    btn.TextColor3 = Theme.Accent
                else
                    btn.TextColor3 = Theme.Text
                end
                outline.Color = Theme.Stroke
            end
        end

        function entry:Set(value, silent)
            value = tostring(value or "None")
            if value == "" then
                value = "None"
            end
            entry.Value = value
            entry.Down = false
            render()
            commit(entry, cfg, silent)
        end

        btn.MouseEnter:Connect(hoverFx)
        btn.MouseButton1Click:Connect(function()
            clickFx()
            if isListening then
                cancelListening()
                return
            end
            cancelListening()
            isListening = true
            render()
            listening = {
                cancel = function()
                    isListening = false
                    render()
                end,
                fn = function(name)
                    isListening = false
                    boundAt = os.clock()
                    if name == "Escape" then
                        render()
                    elseif name == "Backspace" or name == "Delete" then
                        entry:Set("None")
                    else
                        entry:Set(name)
                        local other = keyConflict(entry)
                        if other then
                            Library:Notify({
                                Title = "Keybind",
                                Content = keyDisplay(name) .. " is also bound to " .. tostring(other.Name or "another keybind"),
                                Duration = 3,
                                Type = "Warning",
                            })
                        end
                    end
                end,
            }
        end)

        if opts.OnMode then
            btn.MouseButton2Click:Connect(function()
                if os.clock() - boundAt < 0.4 then
                    return
                end
                clickFx()
                cancelListening()
                openModeMenu(box, entry.Mode or "Toggle", opts.OnMode)
            end)
        end

        entry.Refresh = render
        onTheme(render)
        render()
        table.insert(keybinds, entry)
        return entry
    end

    connect(UserInputService.InputBegan, function(input, processed)
        local name = inputName(input)
        if not name then
            return
        end
        if listening then
            local l = listening
            listening = nil
            l.fn(name)
            return
        end
        if processed then
            return
        end
        for _, kb in ipairs(keybinds) do
            if kb.Value == name then
                kb.Down = true
                if kb.Press then
                    task.spawn(pcall, kb.Press)
                end
            end
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        local name = inputName(input)
        if not name then
            return
        end
        for _, kb in ipairs(keybinds) do
            if kb.Value == name and kb.Down then
                kb.Down = false
                if kb.Release then
                    task.spawn(pcall, kb.Release)
                end
            end
        end
    end)

    function Library:IsHeld(flag)
        local opt = Library.Options[flag]
        return opt ~= nil and opt.Down == true
    end
end

function Section:AddLabel(text)
    self.Count = self.Count + 1
    local obj = {}
    local label = textObj("TextLabel", {
        Size = UDim2.new(1, -16, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextSize = 13,
        LayoutOrder = self.Count,
        Parent = self.Box,
    }, "SubText")
    new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = label})
    function obj:Set(value)
        label.Text = tostring(value)
    end
    return obj
end

function Section:AddGroup(source, test)
    test = test or function(v)
        return v == true
    end
    self.Count = self.Count + 1
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = self.Count,
        Visible = false,
        Parent = self.Box,
    })
    local inner = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = wrap,
    })
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner})

    local state = false
    local token = 0
    local function apply(open, instant)
        if open == state then
            return
        end
        state = open
        token = token + 1
        local mine = token
        if open then
            wrap.Visible = true
            if instant then
                wrap.AutomaticSize = Enum.AutomaticSize.Y
                return
            end
            wrap.AutomaticSize = Enum.AutomaticSize.None
            wrap.Size = UDim2.new(1, 0, 0, 0)
            task.spawn(function()
                task.wait()
                if token ~= mine or not state then
                    return
                end
                local goal = inner.AbsoluteSize.Y / math.max(windowScale.Scale, 0.01)
                if goal < 1 then
                    wrap.AutomaticSize = Enum.AutomaticSize.Y
                    return
                end
                tween(wrap, 0.35, {Size = UDim2.new(1, 0, 0, goal)})
                task.wait(0.37)
                if token == mine and state then
                    wrap.AutomaticSize = Enum.AutomaticSize.Y
                end
            end)
        else
            local h = wrap.AbsoluteSize.Y / math.max(windowScale.Scale, 0.01)
            wrap.AutomaticSize = Enum.AutomaticSize.None
            wrap.Size = UDim2.new(1, 0, 0, h)
            if instant then
                wrap.Size = UDim2.new(1, 0, 0, 0)
                wrap.Visible = false
                return
            end
            tween(wrap, 0.3, {Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.32, function()
                if token == mine and not state then
                    wrap.Visible = false
                end
            end)
        end
    end

    source.Listeners = source.Listeners or {}
    table.insert(source.Listeners, function(value)
        apply(test(value) and true or false, false)
    end)
    apply(test(source.Value) and true or false, true)

    return setmetatable({Box = inner, Count = 0}, Section)
end

function Section:AddButton(cfg)
    local row = newRow(self, ROWH, true)
    local hit = hitButton(row)
    bindRow(row, hit)
    textObj("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        Text = cfg.Name,
        TextSize = 14,
        Parent = row,
    }, "Text")
    hit.MouseButton1Click:Connect(function()
        clickFx()
        row.BackgroundColor3 = Theme.Accent
        row.BackgroundTransparency = 0.1
        tween(row, 0.5, {BackgroundColor3 = Theme.Element, BackgroundTransparency = row:GetAttribute("Hover")})
        if cfg.Callback then
            task.spawn(pcall, cfg.Callback)
        end
    end)
    return {}
end

function Section:AddToggle(cfg)
    local obj = {Value = cfg.Default and true or false, Flag = cfg.Flag, NoSave = cfg.NoSave}
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    local hasKey = cfg.Keybind ~= nil and cfg.Keybind ~= false
    rowLabel(row, cfg.Name, hasKey and -134 or -66)
    local keyEntry = nil
    if hasKey then
        local modeEntry = {Value = "Toggle", Flag = cfg.Flag and (cfg.Flag .. "Mode") or nil, NoSave = cfg.NoSave}
        keyEntry = {
            Name = cfg.Name,
            Value = type(cfg.Keybind) == "string" and cfg.Keybind or "None",
            Flag = cfg.Flag and (cfg.Flag .. "Key") or nil,
            NoSave = cfg.NoSave,
            Mode = "Toggle",
            Press = function()
                if keyEntry.Mode == "Toggle" then
                    obj:Set(not obj.Value)
                elseif keyEntry.Mode == "Hold" then
                    obj:Set(true)
                end
            end,
            Release = function()
                if keyEntry.Mode == "Hold" then
                    obj:Set(false)
                end
            end,
        }
        function modeEntry:Set(value)
            if value ~= "Toggle" and value ~= "Hold" and value ~= "Always" then
                value = "Toggle"
            end
            modeEntry.Value = value
            keyEntry.Mode = value
            if modeEntry.Flag then
                Library.Flags[modeEntry.Flag] = value
            end
            if keyEntry.Refresh then
                keyEntry.Refresh()
            end
            if value == "Always" then
                if not obj.Value then
                    obj:Set(true)
                end
            elseif value == "Hold" and not keyEntry.Down and obj.Value then
                obj:Set(false)
            end
        end
        newKeyButton(row, keyEntry, {
            Anchor = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -60, 0, ROWH / 2),
            Size = UDim2.fromOffset(56, 22),
            Z = 4,
            TextSize = 11,
            Radius = 7,
            OnMode = function(mode)
                modeEntry:Set(mode)
            end,
        })
        register(keyEntry)
        register(modeEntry)
        obj.Key = keyEntry
    end
    local pill = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0, ROWH / 2),
        Size = UDim2.fromOffset(40, 22),
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(pill, 11)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = pill,
    })
    corner(knob, 8)
    local function render(animate)
        local t = animate and 0.3 or 0
        tween(pill, t, {BackgroundColor3 = obj.Value and Theme.Accent or Theme.Off})
        tween(knob, t, {Position = obj.Value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, Enum.EasingStyle.Back)
    end
    function obj:Set(value, silent)
        value = value and true or false
        if keyEntry and keyEntry.Mode == "Always" then
            value = true
        end
        obj.Value = value
        render(true)
        commit(obj, cfg, silent)
    end
    hit.MouseButton1Click:Connect(function()
        clickFx()
        obj:Set(not obj.Value)
    end)
    onTheme(function()
        render(false)
    end)
    render(false)
    register(obj)
    if cfg.Hud then
        obj.HudName = cfg.HudName or cfg.Name
        table.insert(Library.HudToggles, obj)
    end
    return obj
end

function Section:AddSlider(cfg)
    local min, max = cfg.Min or 0, cfg.Max or 100
    local inc = cfg.Increment or 1
    local suffix = cfg.Suffix
    if suffix == nil then
        suffix = "%"
    end
    local obj = {Flag = cfg.Flag, NoSave = cfg.NoSave}
    obj.Value = math.clamp(cfg.Default or min, min, max)
    local row = newRow(self, 52)
    local hit = hitButton(row, 52)
    bindRow(row, hit)
    textObj("TextLabel", {
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -92, 0, 20),
        Text = cfg.Name,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 14,
        Parent = row,
    }, "Text")
    local valueLabel = textObj("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 6),
        Size = UDim2.fromOffset(70, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 13,
        Parent = row,
    }, "SubText")
    local bar = new("Frame", {
        Position = UDim2.new(0, 12, 0, 37),
        Size = UDim2.new(1, -24, 0, 5),
        BorderSizePixel = 0,
        Parent = row,
    })
    themeBind(bar, "BackgroundColor3", "Off")
    corner(bar, 3)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = bar,
    })
    themeBind(fill, "BackgroundColor3", "Accent")
    corner(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(13, 13),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = bar,
    })
    corner(knob, 7)
    local function render(animate)
        local a = (obj.Value - min) / (max - min)
        local t = animate and 0.12 or 0
        tween(fill, t, {Size = UDim2.new(a, 0, 1, 0)}, Enum.EasingStyle.Quad)
        tween(knob, t, {Position = UDim2.new(a, 0, 0.5, 0)}, Enum.EasingStyle.Quad)
        valueLabel.Text = tostring(obj.Value) .. suffix
    end
    function obj:Set(value, silent)
        value = tonumber(value)
        if not value then
            return
        end
        value = math.clamp(math.floor(value / inc + 0.5) * inc, min, max)
        value = tonumber(string.format("%.3f", value))
        obj.Value = value
        render(true)
        commit(obj, cfg, silent)
    end
    hit.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        tween(knob, 0.18, {Size = UDim2.fromOffset(18, 18)}, Enum.EasingStyle.Back)
        startDrag(row, function(pos)
            local a = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            obj:Set(min + (max - min) * a)
        end, function()
            tween(knob, 0.22, {Size = UDim2.fromOffset(13, 13)}, Enum.EasingStyle.Quad)
        end, input)
    end)
    render(false)
    register(obj)
    return obj
end

function Section:AddDropdown(cfg)
    local multi = cfg.Multi and true or false
    local options = cfg.Options or {}
    local obj = {Flag = cfg.Flag, NoSave = cfg.NoSave, Open = false}
    if multi then
        obj.Value = {}
        if type(cfg.Default) == "table" then
            for _, name in ipairs(cfg.Default) do
                table.insert(obj.Value, name)
            end
        end
    else
        obj.Value = cfg.Default
    end
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    rowLabel(row, cfg.Name, -190)
    local valueLabel = textObj("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -32, 0, 0),
        Size = UDim2.new(0, 150, 0, ROWH),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 13,
        Parent = row,
    }, "SubText")
    local arrow = textObj("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -18, 0, ROWH / 2),
        Size = UDim2.fromOffset(16, 16),
        Text = "›",
        TextSize = 20,
        Parent = row,
    }, "SubText")
    local list = new("ScrollingFrame", {
        Position = UDim2.fromOffset(6, ROWH + 4),
        Size = UDim2.new(1, -12, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = row,
    })
    themeBind(list, "ScrollBarImageColor3", "Accent")
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
    local buttons = {}
    local function listHeight()
        return math.min(#options, 6) * 28
    end
    local function openHeight()
        return ROWH + 4 + listHeight() + 8
    end
    local function isSelected(name)
        if multi then
            return table.find(obj.Value, name) ~= nil
        end
        return obj.Value == name
    end
    local function renderValue()
        if multi then
            local picked = {}
            for _, name in ipairs(options) do
                if table.find(obj.Value, name) then
                    table.insert(picked, name)
                end
            end
            valueLabel.Text = #picked == 0 and "None" or table.concat(picked, ", ")
        else
            valueLabel.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
        end
        for name, b in pairs(buttons) do
            local selected = isSelected(name)
            tween(b.Label, 0.18, {TextColor3 = selected and Theme.Accent or Theme.SubText})
            tween(b.Mark, 0.18, {BackgroundTransparency = selected and 0 or 1})
        end
    end
    local function setOpen(state)
        obj.Open = state
        tween(row, 0.35, {Size = UDim2.new(1, 0, 0, state and openHeight() or ROWH)})
        tween(arrow, 0.3, {Rotation = state and 90 or 0})
    end
    local function build()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("GuiButton") then
                c:Destroy()
            end
        end
        table.clear(buttons)
        for i, name in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = list,
            })
            themeBind(b, "BackgroundColor3", "Surface")
            corner(b, 8)
            local lab = textObj("TextLabel", {
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.new(1, -18, 1, 0),
                Text = name,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextSize = 13,
                Parent = b,
            }, "SubText")
            local mark = new("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 4, 0.5, 0),
                Size = UDim2.fromOffset(3, 12),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = b,
            })
            themeBind(mark, "BackgroundColor3", "Accent")
            corner(mark, 2)
            b.MouseEnter:Connect(function()
                tween(b, 0.15, {BackgroundTransparency = 0.45})
                hoverFx()
            end)
            b.MouseLeave:Connect(function()
                tween(b, 0.2, {BackgroundTransparency = 1})
            end)
            b.MouseButton1Click:Connect(function()
                clickFx()
                if multi then
                    local picked, found = {}, false
                    for _, n in ipairs(obj.Value) do
                        if n == name then
                            found = true
                        else
                            table.insert(picked, n)
                        end
                    end
                    if not found then
                        table.insert(picked, name)
                    end
                    obj:Set(picked)
                else
                    obj:Set(name)
                    setOpen(false)
                end
            end)
            buttons[name] = {Label = lab, Mark = mark}
        end
        list.Size = UDim2.new(1, -12, 0, listHeight())
    end
    function obj:Set(value, silent)
        if multi then
            local picked = {}
            if type(value) == "table" then
                for _, name in ipairs(value) do
                    if table.find(options, name) then
                        table.insert(picked, name)
                    end
                end
            end
            obj.Value = picked
        else
            if value ~= nil and not table.find(options, value) then
                value = nil
            end
            obj.Value = value
        end
        renderValue()
        commit(obj, cfg, silent)
    end
    function obj:Refresh(newOptions)
        options = newOptions
        build()
        obj:Set(obj.Value, true)
        if obj.Open then
            tween(row, 0.25, {Size = UDim2.new(1, 0, 0, openHeight())})
        end
    end
    hit.MouseButton1Click:Connect(function()
        clickFx()
        setOpen(not obj.Open)
    end)
    onTheme(renderValue)
    build()
    renderValue()
    register(obj)
    return obj
end

function Section:AddTextbox(cfg)
    local obj = {Value = cfg.Default or "", Flag = cfg.Flag, NoSave = cfg.NoSave}
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    rowLabel(row, cfg.Name, -150)
    local holderBox = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0, ROWH / 2),
        Size = UDim2.fromOffset(130, 26),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = row,
    })
    themeBind(holderBox, "BackgroundColor3", "Background")
    corner(holderBox, 8)
    local outline = stroke(holderBox, "Stroke", 1, 0)
    local box = textObj("TextBox", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Text = obj.Value,
        PlaceholderText = cfg.Placeholder or "",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 13,
        ZIndex = 4,
        Parent = holderBox,
    }, "Text")
    themeBind(box, "PlaceholderColor3", "SubText")
    box.Focused:Connect(function()
        tween(outline, 0.2, {Color = Theme.Accent})
    end)
    box.FocusLost:Connect(function()
        tween(outline, 0.25, {Color = Theme.Stroke})
        obj:Set(box.Text)
    end)
    function obj:Set(value, silent)
        obj.Value = tostring(value or "")
        box.Text = obj.Value
        commit(obj, cfg, silent)
    end
    register(obj)
    return obj
end

function Section:AddKeybind(cfg)
    local obj = {
        Name = cfg.Name,
        Value = cfg.Default or "None",
        Flag = cfg.Flag,
        NoSave = cfg.NoSave,
        Press = cfg.OnPress,
        Release = cfg.OnRelease,
    }
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    rowLabel(row, cfg.Name, -112)
    newKeyButton(row, obj, {
        Anchor = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0, ROWH / 2),
        Size = UDim2.fromOffset(94, 26),
        Z = 3,
        TextSize = 12,
        Cfg = cfg,
    })
    register(obj)
    return obj
end

local rainbow = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})

function Section:AddColorPicker(cfg)
    local obj = {Value = cfg.Default or Color3.new(1, 1, 1), Flag = cfg.Flag, NoSave = cfg.NoSave, Open = false}
    local h, s, v = obj.Value:ToHSV()
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    rowLabel(row, cfg.Name, -60)
    local swatch = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0, ROWH / 2),
        Size = UDim2.fromOffset(36, 20),
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(swatch, 7)
    stroke(swatch, "Stroke", 1, 0)
    local panel = new("Frame", {
        Position = UDim2.fromOffset(8, ROWH + 4),
        Size = UDim2.new(1, -16, 0, 156),
        BackgroundTransparency = 1,
        Parent = row,
    })
    local svBox = new("Frame", {
        Size = UDim2.new(1, 0, 0, 104),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = panel,
    })
    corner(svBox, 8)
    local white = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
        Parent = white,
    })
    local black = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
        Rotation = 90,
        Parent = black,
    })
    local svCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = svBox,
    })
    corner(svCursor, 6)
    new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Parent = svCursor})
    local svHit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = svBox,
    })
    local hueBar = new("Frame", {
        Position = UDim2.fromOffset(0, 112),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(hueBar, 6)
    new("UIGradient", {Color = rainbow, Parent = hueBar})
    local hueCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = hueBar,
    })
    corner(hueCursor, 3)
    new("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.5, Parent = hueCursor})
    local hueHit = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 8),
        Position = UDim2.fromOffset(0, -4),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = hueBar,
    })
    local inputs = new("Frame", {
        Position = UDim2.fromOffset(0, 132),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = inputs,
    })
    local function inputBox(order, width, placeholder)
        local frame = new("Frame", {
            Size = UDim2.fromOffset(width, 24),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = inputs,
        })
        themeBind(frame, "BackgroundColor3", "Background")
        corner(frame, 7)
        stroke(frame, "Stroke", 1, 0)
        local box = textObj("TextBox", {
            Size = UDim2.fromScale(1, 1),
            Text = "",
            PlaceholderText = placeholder,
            ClearTextOnFocus = false,
            TextSize = 12,
            Parent = frame,
        }, "Text")
        themeBind(box, "PlaceholderColor3", "SubText")
        return box
    end
    local hexBox = inputBox(1, 84, "#FFFFFF")
    local rBox = inputBox(2, 50, "R")
    local gBox = inputBox(3, 50, "G")
    local bBox = inputBox(4, 50, "B")
    local function refresh()
        h = math.clamp(h, 0, 0.999)
        local c = Color3.fromHSV(h, s, v)
        obj.Value = c
        swatch.BackgroundColor3 = c
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        hexBox.Text = "#" .. c:ToHex():upper()
        rBox.Text = tostring(math.floor(c.R * 255 + 0.5))
        gBox.Text = tostring(math.floor(c.G * 255 + 0.5))
        bBox.Text = tostring(math.floor(c.B * 255 + 0.5))
    end
    function obj:Set(value, silent)
        if typeof(value) ~= "Color3" then
            return
        end
        h, s, v = value:ToHSV()
        refresh()
        commit(obj, cfg, silent)
    end
    local function setOpen(state)
        obj.Open = state
        tween(row, 0.38, {Size = UDim2.new(1, 0, 0, state and (ROWH + 4 + 156 + 8) or ROWH)})
    end
    hit.MouseButton1Click:Connect(function()
        clickFx()
        setOpen(not obj.Open)
    end)
    svHit.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        startDrag(row, function(pos)
            s = math.clamp((pos.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
            v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
            refresh()
            commit(obj, cfg)
        end, nil, input)
    end)
    hueHit.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        startDrag(row, function(pos)
            h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
            refresh()
            commit(obj, cfg)
        end, nil, input)
    end)
    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:match("^#?(%x%x%x%x%x%x)$")
        if hex then
            local ok, c = pcall(Color3.fromHex, hex)
            if ok then
                obj:Set(c)
                return
            end
        end
        refresh()
    end)
    local function channelBox(box, channel)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then
                n = math.clamp(math.floor(n), 0, 255)
                local c = obj.Value
                local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
                if channel == 1 then
                    r = n
                elseif channel == 2 then
                    g = n
                else
                    b = n
                end
                obj:Set(Color3.fromRGB(r, g, b))
            else
                refresh()
            end
        end)
    end
    channelBox(rBox, 1)
    channelBox(gBox, 2)
    channelBox(bBox, 3)
    refresh()
    register(obj)
    return obj
end

function Section:AddGradient(cfg)
    local cols = {}
    local objs = {}
    for i = 1, 3 do
        cols[i] = (cfg.Defaults and cfg.Defaults[i]) or Color3.new(1, 1, 1)
    end
    local selected = nil
    local h, s, v = 0, 0, 1
    local row = newRow(self, ROWH)
    local hit = hitButton(row)
    bindRow(row, hit)
    rowLabel(row, cfg.Name, -150)

    local preview = new("Frame", {
        Position = UDim2.new(0, 12, 0, ROWH - 6),
        Size = UDim2.new(1, -24, 0, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = row,
    })
    corner(preview, 2)
    local previewGrad = new("UIGradient", {Parent = preview})

    local swatches = {}
    for i = 1, 3 do
        local sw = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12 - (3 - i) * 36, 0, 6),
            Size = UDim2.fromOffset(30, 20),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 4,
            Parent = row,
        })
        corner(sw, 6)
        swatches[i] = {Button = sw, Stroke = stroke(sw, "Stroke", 1.5, 0)}
    end

    local panel = new("Frame", {
        Position = UDim2.fromOffset(8, ROWH + 4),
        Size = UDim2.new(1, -16, 0, 156),
        BackgroundTransparency = 1,
        Parent = row,
    })
    local svBox = new("Frame", {
        Size = UDim2.new(1, 0, 0, 104),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = panel,
    })
    corner(svBox, 8)
    local white = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
        Parent = white,
    })
    local black = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
        Rotation = 90,
        Parent = black,
    })
    local svCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = svBox,
    })
    corner(svCursor, 6)
    new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Parent = svCursor})
    local svHit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = svBox,
    })
    local hueBar = new("Frame", {
        Position = UDim2.fromOffset(0, 112),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(hueBar, 6)
    new("UIGradient", {Color = rainbow, Parent = hueBar})
    local hueCursor = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = hueBar,
    })
    corner(hueCursor, 3)
    new("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.5, Parent = hueCursor})
    local hueHit = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 8),
        Position = UDim2.fromOffset(0, -4),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = hueBar,
    })
    local inputs = new("Frame", {
        Position = UDim2.fromOffset(0, 132),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = inputs,
    })
    local function inputBox(order, width, placeholder)
        local frame = new("Frame", {
            Size = UDim2.fromOffset(width, 24),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = inputs,
        })
        themeBind(frame, "BackgroundColor3", "Background")
        corner(frame, 7)
        stroke(frame, "Stroke", 1, 0)
        local box = textObj("TextBox", {
            Size = UDim2.fromScale(1, 1),
            Text = "",
            PlaceholderText = placeholder,
            ClearTextOnFocus = false,
            TextSize = 12,
            Parent = frame,
        }, "Text")
        themeBind(box, "PlaceholderColor3", "SubText")
        return box
    end
    local hexBox = inputBox(1, 84, "#FFFFFF")
    local rBox = inputBox(2, 50, "R")
    local gBox = inputBox(3, 50, "G")
    local bBox = inputBox(4, 50, "B")

    local function renderSwatches()
        for i, sw in ipairs(swatches) do
            sw.Button.BackgroundColor3 = cols[i]
            sw.Stroke.Color = (selected == i) and Theme.Accent or Theme.Stroke
        end
        previewGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, cols[1]),
            ColorSequenceKeypoint.new(0.5, cols[2]),
            ColorSequenceKeypoint.new(1, cols[3]),
        })
    end

    local function refreshPanel()
        h = math.clamp(h, 0, 0.999)
        local c = Color3.fromHSV(h, s, v)
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        hexBox.Text = "#" .. c:ToHex():upper()
        rBox.Text = tostring(math.floor(c.R * 255 + 0.5))
        gBox.Text = tostring(math.floor(c.G * 255 + 0.5))
        bBox.Text = tostring(math.floor(c.B * 255 + 0.5))
    end

    local function applyHSV(silent)
        if not selected then
            return
        end
        h = math.clamp(h, 0, 0.999)
        local c = Color3.fromHSV(h, s, v)
        cols[selected] = c
        objs[selected].Value = c
        refreshPanel()
        renderSwatches()
        commit(objs[selected], cfg, silent)
    end

    for i = 1, 3 do
        local o = {Value = cols[i], Flag = cfg.Flag and (cfg.Flag .. i) or nil, NoSave = cfg.NoSave}
        function o:Set(value, silent)
            if typeof(value) ~= "Color3" then
                return
            end
            cols[i] = value
            o.Value = value
            if selected == i then
                h, s, v = value:ToHSV()
                refreshPanel()
            end
            renderSwatches()
            commit(o, cfg, silent)
        end
        objs[i] = o
    end

    for i, sw in ipairs(swatches) do
        sw.Button.MouseEnter:Connect(hoverFx)
        sw.Button.MouseButton1Click:Connect(function()
            clickFx()
            if selected == i then
                selected = nil
            else
                selected = i
                h, s, v = cols[i]:ToHSV()
                refreshPanel()
            end
            renderSwatches()
            tween(row, 0.38, {Size = UDim2.new(1, 0, 0, selected and (ROWH + 4 + 156 + 8) or ROWH)})
        end)
    end

    svHit.InputBegan:Connect(function(input)
        if not isPress(input) or not selected then
            return
        end
        startDrag(row, function(pos)
            s = math.clamp((pos.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
            v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
            applyHSV()
        end, nil, input)
    end)
    hueHit.InputBegan:Connect(function(input)
        if not isPress(input) or not selected then
            return
        end
        startDrag(row, function(pos)
            h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
            applyHSV()
        end, nil, input)
    end)
    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:match("^#?(%x%x%x%x%x%x)$")
        if hex and selected then
            local ok, c = pcall(Color3.fromHex, hex)
            if ok then
                objs[selected]:Set(c)
                return
            end
        end
        refreshPanel()
    end)
    local function channelBox(box, channel)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n and selected then
                n = math.clamp(math.floor(n), 0, 255)
                local c = cols[selected]
                local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
                if channel == 1 then
                    r = n
                elseif channel == 2 then
                    g = n
                else
                    b = n
                end
                objs[selected]:Set(Color3.fromRGB(r, g, b))
            else
                refreshPanel()
            end
        end)
    end
    channelBox(rBox, 1)
    channelBox(gBox, 2)
    channelBox(bBox, 3)

    onTheme(renderSwatches)
    renderSwatches()
    refreshPanel()
    for i = 1, 3 do
        register(objs[i])
    end
    return objs
end

local Configs = {}
local Store = env.PrestigeStore or {}
env.PrestigeStore = Store
local userKey = tostring(LocalPlayer.UserId)
Store[userKey] = Store[userKey] or {Configs = {}, Autoload = ""}

local hasFs = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function"
    and type(delfile) == "function"
local rootFolder = "PrestigeV1"
local userFolder = rootFolder .. "/" .. userKey
local cfgFolder = userFolder .. "/configs"
local autoFile = userFolder .. "/autoload.txt"

if hasFs then
    for _, p in ipairs({rootFolder, userFolder, cfgFolder}) do
        if not isfolder(p) then
            pcall(makefolder, p)
        end
    end
end

local function cleanName(n)
    local out = tostring(n or ""):gsub("[^%w%-_ ]", "")
    out = out:gsub("^%s+", "")
    out = out:gsub("%s+$", "")
    return out
end

local function encodeValue(value)
    if typeof(value) == "Color3" then
        return {__color = {value.R, value.G, value.B}}
    end
    return value
end

local function decodeValue(value)
    if type(value) == "table" and value.__color then
        return Color3.new(value.__color[1], value.__color[2], value.__color[3])
    end
    return value
end

function Configs.List()
    local out = {}
    if hasFs then
        local ok, files = pcall(listfiles, cfgFolder)
        if ok and type(files) == "table" then
            for _, f in ipairs(files) do
                local name = tostring(f):match("([^/\\]+)%.json$")
                if name then
                    table.insert(out, name)
                end
            end
        end
    else
        for name in pairs(Store[userKey].Configs) do
            table.insert(out, name)
        end
    end
    table.sort(out)
    return out
end

function Configs.Save(name)
    name = cleanName(name)
    if name == "" then
        return false, "Enter a config name"
    end
    local data = {}
    for flag, opt in pairs(Library.Options) do
        if not opt.NoSave and Library.Flags[flag] ~= nil then
            data[flag] = encodeValue(Library.Flags[flag])
        end
    end
    local okEncode, json = pcall(HttpService.JSONEncode, HttpService, data)
    if not okEncode then
        return false, "Could not encode config"
    end
    if hasFs then
        local ok = pcall(writefile, cfgFolder .. "/" .. name .. ".json", json)
        if not ok then
            return false, "Could not write file"
        end
    else
        Store[userKey].Configs[name] = json
    end
    return true, name
end

function Configs.Load(name)
    name = cleanName(name)
    if name == "" then
        return false, "Select a config"
    end
    local raw
    if hasFs then
        local path = cfgFolder .. "/" .. name .. ".json"
        if not isfile(path) then
            return false, "Config not found"
        end
        local ok, res = pcall(readfile, path)
        if not ok then
            return false, "Could not read file"
        end
        raw = res
    else
        raw = Store[userKey].Configs[name]
    end
    if not raw then
        return false, "Config not found"
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data) ~= "table" then
        return false, "Config is corrupted"
    end
    for flag, value in pairs(data) do
        local opt = Library.Options[flag]
        if opt and not opt.NoSave then
            pcall(opt.Set, opt, decodeValue(value), false)
        end
    end
    return true, name
end

function Configs.Delete(name)
    name = cleanName(name)
    if name == "" then
        return false, "Select a config"
    end
    if hasFs then
        local path = cfgFolder .. "/" .. name .. ".json"
        if not isfile(path) then
            return false, "Config not found"
        end
        pcall(delfile, path)
    else
        Store[userKey].Configs[name] = nil
    end
    return true, name
end

function Configs.GetAutoload()
    if hasFs then
        if isfile(autoFile) then
            local ok, res = pcall(readfile, autoFile)
            if ok then
                return cleanName(res)
            end
        end
        return ""
    end
    return Store[userKey].Autoload or ""
end

function Configs.SetAutoload(name)
    name = cleanName(name)
    if hasFs then
        pcall(writefile, autoFile, name)
    else
        Store[userKey].Autoload = name
    end
end

local fontNames = {
    "GothamMedium", "Gotham", "GothamBold", "GothamBlack", "SourceSans", "SourceSansSemibold", "SourceSansBold",
    "Ubuntu", "Code", "Arcade", "Fantasy", "Highway", "SciFi", "Roboto", "RobotoMono", "Montserrat", "Nunito",
    "Oswald", "Creepster", "Bangers", "Michroma", "Jura", "Sarpanch", "TitilliumWeb", "PatrickHand", "FredokaOne",
    "LuckiestGuy", "Cartoon", "Antique", "Bodoni", "Garamond", "Merriweather", "Arimo",
}
local validFonts = {}
for _, n in ipairs(fontNames) do
    local ok, f = pcall(function()
        return Enum.Font[n]
    end)
    if ok and f then
        table.insert(validFonts, n)
    end
end

local toggleBtn = new("ImageButton", {
    Name = "ToggleButton",
    Position = UDim2.new(0, 18, 0.5, -27),
    Size = UDim2.fromOffset(54, 54),
    BackgroundTransparency = 1,
    Image = asset(IDS.Button),
    AutoButtonColor = false,
    ZIndex = 30,
    Visible = false,
    Parent = gui,
})
local togglePop = new("UIScale", {Scale = 1, Parent = toggleBtn})

toggleBtn.MouseEnter:Connect(function()
    tween(togglePop, 0.2, {Scale = 1.1}, Enum.EasingStyle.Back)
end)
toggleBtn.MouseLeave:Connect(function()
    tween(togglePop, 0.25, {Scale = 1})
end)
toggleBtn.InputBegan:Connect(function(input)
    if not isPress(input) then
        return
    end
    local start = pointer(input)
    local origin = Vector2.new(toggleBtn.AbsolutePosition.X, toggleBtn.AbsolutePosition.Y)
    local moved = false
    tween(togglePop, 0.12, {Scale = 0.92})
    startDrag(nil, function(pos)
        local delta = pos - start
        if delta.Magnitude > 6 then
            moved = true
        end
        if moved then
            local v = gui.AbsoluteSize
            local sz = toggleBtn.AbsoluteSize
            local np = origin + delta
            toggleBtn.Position = UDim2.fromOffset(math.clamp(np.X, 0, v.X - sz.X), math.clamp(np.Y, 0, v.Y - sz.Y))
        end
    end, function()
        tween(togglePop, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
        if not moved then
            clickFx()
            Library:Toggle()
        end
    end)
end)

local function applyScale()
    if windowVisible then
        tween(windowScale, 0.2, {Scale = targetScale()})
    end
end

local function applyWallpaper()
    wallpaper.ImageTransparency = 1 - (Library.Flags.WallpaperOpacity or 85) / 100
    dim.BackgroundTransparency = 1 - (Library.Flags.WallpaperDim or 50) / 100
end

connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
    measure()
    notifyScale.Scale = autoScale
    applyScale()
    holderGoal = clampGoal(holderGoal)
end)

local clock = 0
connect(RunService.Heartbeat, function(dt)
    clock = clock + dt

    if (holderPos - holderGoal).Magnitude > 0.1 then
        holderPos = holderPos:Lerp(holderGoal, 1 - math.exp(-dt * 16))
        holder.Position = UDim2.fromOffset(holderPos.X, holderPos.Y)
    end

    local pumpkinTarget = (windowVisible and Library.Flags.Pumpkins ~= false) and 1 or 0
    fxAlpha = fxAlpha + (pumpkinTarget - fxAlpha) * (1 - math.exp(-dt * 4))
    if fxAlpha < 0.01 and pumpkinTarget == 0 then
        bgLayer.Visible = false
    else
        bgLayer.Visible = true
        local v = screenSize()
        for _, p in ipairs(pumpkins) do
            p.y = p.y + p.speed * dt
            if p.y > v.Y + p.size then
                placePumpkin(p, false)
            end
            p.inst.Position = UDim2.fromOffset(p.x + math.sin(clock * 0.8 + p.phase) * p.sway, p.y)
            p.inst.Rotation = p.inst.Rotation + p.spin * dt
            p.inst.ImageTransparency = 1 - (1 - p.base) * fxAlpha
        end
    end

    local rainOn = Library.Flags.MouseRain ~= false and (windowVisible or Library.Flags.RainMenuOnly == false)
    local pos = touchPos
    if not pos and UserInputService.MouseEnabled then
        pos = UserInputService:GetMouseLocation()
    end
    if rainOn and pos and lastMouse then
        local dist = (pos - lastMouse).Magnitude
        if dist > 0.5 then
            carry = carry + dist
            local n = 0
            while carry >= 16 and n < 4 do
                carry = carry - 16
                n = n + 1
                local p = lastMouse:Lerp(pos, math.random())
                spawnDrop(p.X + (math.random() - 0.5) * 6, p.Y + 10)
            end
            if n >= 4 then
                carry = 0
            end
        end
    end
    lastMouse = pos

    for i = #drops, 1, -1 do
        local d = drops[i]
        d.age = d.age + dt
        if d.age >= d.life then
            d.f:Destroy()
            table.remove(drops, i)
        else
            d.vy = d.vy + 1500 * dt
            d.x = d.x + d.vx * dt
            d.y = d.y + d.vy * dt
            local a = d.age / d.life
            d.f.Position = UDim2.fromOffset(d.x, d.y)
            d.f.Rotation = d.f.Rotation + d.spin * dt
            d.f.ImageTransparency = 0.05 + a * a * 0.95
        end
    end
end)

do
    local hud = new("Frame", {
        Name = "ActiveList",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -24),
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 45,
        Parent = gui,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = hud,
    })

    local lines = {}
    local lastSig = ""
    local acc = 0

    local function keyText(obj)
        local k = obj.Key and obj.Key.Value
        if k and k ~= "None" and k ~= "" then
            return (tostring(k):gsub("MouseButton", "MB"))
        end
        return nil
    end

    local function rebuild()
        local entries = {}
        for _, obj in ipairs(Library.HudToggles) do
            local key = obj.Value == true and keyText(obj) or nil
            if key then
                table.insert(entries, {Name = obj.HudName, Key = key})
            end
        end
        local parts = {Theme.Accent:ToHex()}
        for _, e in ipairs(entries) do
            table.insert(parts, e.Name .. "=" .. e.Key)
        end
        local sig = table.concat(parts, "|")
        if sig ~= lastSig then
            lastSig = sig
            for _, l in ipairs(lines) do
                l:Destroy()
            end
            lines = {}
            for i, e in ipairs(entries) do
                table.insert(lines, textObj("TextLabel", {
                    Size = UDim2.fromOffset(0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    RichText = true,
                    Text = e.Name .. '  <font color="#' .. Theme.Accent:ToHex() .. '">[' .. e.Key .. ']</font>',
                    TextSize = 15,
                    TextStrokeTransparency = 0.45,
                    TextStrokeColor3 = Color3.new(0, 0, 0),
                    LayoutOrder = i,
                    ZIndex = 46,
                    Parent = hud,
                }, "Text"))
            end
        end
        hud.Visible = #lines > 0 and Library.Flags.HudEnabled ~= false and not (Library.Flags.HudHideInMenu == true and windowVisible)
        hud.Position = UDim2.new(0.5, 0, 1, -(Library.Flags.HudOffset or 24))
    end

    connect(RunService.Heartbeat, function(dt)
        acc = acc + dt
        if acc >= 0.1 then
            acc = 0
            pcall(rebuild)
        end
    end)
end

local mainTab = Library:AddTab("Main", IDS.Main)
local playerTab = Library:AddTab("Player", IDS.Player)
local visualsTab = Library:AddTab("Visuals", IDS.Visuals)
local miscTab = Library:AddTab("Misc", IDS.Misc)
local settingsTab = Library:AddTab("UI Settings", IDS.Settings, true)

local function demo(sub, id)
    local a = sub:AddSection("Example Section", "Left")
    a:AddToggle({Name = "Example Toggle", Flag = id .. "Toggle", Default = false, Keybind = true})
    a:AddSlider({Name = "Example Slider", Flag = id .. "Slider", Min = 0, Max = 100, Default = 50})
    a:AddDropdown({Name = "Example Select", Flag = id .. "Select", Options = {"Option 1", "Option 2", "Option 3"}, Default = "Option 1"})
    local b = sub:AddSection("More Examples", "Right")
    b:AddButton({Name = "Example Button", Callback = function()
        Library:Notify({Title = "Prestige V1", Content = "Button pressed", Duration = 2.5})
    end})
    b:AddKeybind({Name = "Example Keybind", Flag = id .. "Bind", Default = "None", OnPress = function()
        Library:Notify({Title = "Keybind", Content = "Key pressed", Duration = 1.5})
    end})
    b:AddTextbox({Name = "Example Textbox", Flag = id .. "Box", Placeholder = "Type here"})
    b:AddColorPicker({Name = "Example Color", Flag = id .. "Color", Default = Color3.fromRGB(255, 132, 38)})
    b:AddDropdown({Name = "Multi Select", Flag = id .. "Multi", Multi = true, Options = {"One", "Two", "Three", "Four"}, Default = {"One"}})
end

local aimSub = mainTab:AddSubTab("Aimbot")
local silentSub = mainTab:AddSubTab("Silent Aim")
local weaponsSub = nil
for _, entry in ipairs({{playerTab, "Player"}, {miscTab, "Misc"}}) do
    demo(entry[1]:AddSubTab("Test 1"), entry[2] .. "T1")
    if entry[2] == "Misc" then
        weaponsSub = entry[1]:AddSubTab("Weapons")
    else
        demo(entry[1]:AddSubTab("Test 2"), entry[2] .. "T2")
    end
end

Library.AimInfo = {Target = nil, Aimbot = nil}

local function buildAimbot(sub, silentSub)
    local F = Library.Flags
    local WHITE = Color3.new(1, 1, 1)
    local partMap = {
        ["Head"] = {"Head"},
        ["Torso"] = {"UpperTorso", "Torso"},
        ["Lower Torso"] = {"LowerTorso", "Torso"},
        ["Root"] = {"HumanoidRootPart"},
        ["Left Arm"] = {"LeftUpperArm", "Left Arm"},
        ["Right Arm"] = {"RightUpperArm", "Right Arm"},
        ["Left Hand"] = {"LeftHand", "Left Arm"},
        ["Right Hand"] = {"RightHand", "Right Arm"},
        ["Left Leg"] = {"LeftUpperLeg", "Left Leg"},
        ["Right Leg"] = {"RightUpperLeg", "Right Leg"},
        ["Left Foot"] = {"LeftFoot", "Left Leg"},
        ["Right Foot"] = {"RightFoot", "Right Leg"},
    }
    local partNames = {"Head", "Torso", "Lower Torso", "Root", "Left Arm", "Right Arm", "Left Hand", "Right Hand", "Left Leg", "Right Leg", "Left Foot", "Right Foot"}
    local hitOptions = {"Closest"}
    for _, n in ipairs(partNames) do
        table.insert(hitOptions, n)
    end
    local leftNames = {"Left Arm", "Left Hand", "Left Leg", "Left Foot"}
    local rightNames = {"Right Arm", "Right Hand", "Right Leg", "Right Foot"}
    local lowerNames = {"Lower Torso", "Root", "Left Leg", "Right Leg", "Left Foot", "Right Foot"}

    local function col(flag, fallback)
        local v = F[flag]
        if typeof(v) == "Color3" then
            return v
        end
        return fallback or WHITE
    end

    local aimFlags = {Hit = "AimHitPart", Jump = "AimJumpPart", Wall = "AimWall"}
    local silentFlags = {Hit = "SilentHitPart", Jump = "SilentJumpPart", Wall = "SilentWall"}

    local state = {
        Target = nil,
        Pick = 0,
        Acc = Vector2.new(0, 0),
        Warned = false,
        FovPos = nil,
        Radius = 150,
        Alpha = 0,
        C1 = nil,
        C2 = nil,
        C3 = nil,
    }

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    pcall(function()
        rayParams.RespectCanCollide = true
    end)

    local fovGui = new("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 980,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local parented = pcall(function()
        if type(gethui) == "function" then
            fovGui.Parent = gethui()
        else
            fovGui.Parent = CoreGui
        end
    end)
    if not parented or not fovGui.Parent then
        fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    local fov = new("Frame", {
        Name = "Fov",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(300, 300),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Parent = fovGui,
    })
    new("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = fov})
    local fovScale = new("UIScale", {Scale = 0.8, Parent = fov})
    local fovStroke = new("UIStroke", {
        Thickness = 2,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.new(1, 1, 1),
        Parent = fov,
    })
    local fovGrad = new("UIGradient", {Parent = fovStroke})

    local function findPart(char, name)
        local cands = partMap[name]
        if cands then
            for _, c in ipairs(cands) do
                local p = char:FindFirstChild(c)
                if p and p:IsA("BasePart") then
                    return p
                end
            end
        end
        return nil
    end

    local function alive(plr)
        local char = plr.Character
        if not char then
            return nil
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then
            return nil
        end
        return char, hum, root
    end

    local function hpPct(hum)
        return hum.Health / math.max(hum.MaxHealth, 1) * 100
    end

    local function visible(cam, part, char)
        local origin = cam.CFrame.Position
        local res = workspace:Raycast(origin, part.Position - origin, rayParams)
        return res == nil or res.Instance:IsDescendantOf(char)
    end

    local function anyVisible(cam, char, root)
        local head = char:FindFirstChild("Head")
        if head and visible(cam, head, char) then
            return true
        end
        return visible(cam, root, char)
    end

    local function isJumping(hum)
        if hum.FloorMaterial ~= Enum.Material.Air then
            return false
        end
        local st = hum:GetState()
        return st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall
    end

    local function choosePart(cam, char, hum, root, ref, flags)
        flags = flags or aimFlags
        local jumping = isJumping(hum)
        if jumping then
            local p = findPart(char, F[flags.Jump] or "Lower Torso")
            if p then
                return p
            end
        end
        local mode = F[flags.Hit] or "Closest"
        if mode ~= "Closest" then
            return findPart(char, mode) or root
        end
        local names = partNames
        local lateral = root.AssemblyLinearVelocity:Dot(cam.CFrame.RightVector)
        if jumping then
            names = lowerNames
        elseif lateral > 4 then
            names = leftNames
        elseif lateral < -4 then
            names = rightNames
        end
        local wall = F[flags.Wall] == true
        local best, bestD = nil, math.huge
        local function scan(list)
            for _, n in ipairs(list) do
                local p = findPart(char, n)
                if p then
                    local v, on = cam:WorldToViewportPoint(p.Position)
                    if on then
                        local d = (Vector2.new(v.X, v.Y) - ref).Magnitude
                        if d < bestD and (not wall or visible(cam, p, char)) then
                            best, bestD = p, d
                        end
                    end
                end
            end
        end
        scan(names)
        if not best and names ~= partNames then
            scan(partNames)
        end
        return best
    end

    local function acquire(cam, ref, fovCenter, radius, useFov)
        local best, bestD = nil, math.huge
        local minHp = F.AimHealthOn == true and (F.AimHealth or 0) or nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char, hum, root = alive(plr)
                if char and (not minHp or hpPct(hum) >= minHp) then
                    local v, on = cam:WorldToViewportPoint((char:FindFirstChild("Head") or root).Position)
                    if on then
                        local sp = Vector2.new(v.X, v.Y)
                        if not useFov or (sp - fovCenter).Magnitude <= radius then
                            local d = (sp - ref).Magnitude
                            if d < bestD and (F.AimWall ~= true or anyVisible(cam, char, root)) then
                                best, bestD = plr, d
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function aimAt(cam, part, dt, t, method, mouse)
        local pos = part.Position
        local human = (F.AimHuman or 0) / 100
        if human > 0 then
            local amp = human * math.max(part.Size.Magnitude * 0.35, 0.6) * 0.5
            pos = pos + Vector3.new(
                math.sin(t * 1.7) + 0.6 * math.sin(t * 3.1 + 1),
                math.sin(t * 2.3 + 2) + 0.5 * math.sin(t * 4.1),
                math.sin(t * 1.3 + 4)
            ) * amp
        end
        local smooth = (F.AimSmooth or 0) / 100
        local strength = (F.AimStrength or 100) / 100
        local alpha = 1
        if smooth > 0 then
            alpha = 1 - math.exp(-(2 + 48 * (1 - smooth) ^ 2) * dt)
        end
        alpha = alpha * strength
        if human > 0 then
            alpha = alpha * (1 - human * 0.45 * (0.5 + 0.5 * math.sin(t * 2.6)))
        end
        if alpha <= 0 then
            return
        end
        if method == "Mouse" and type(mousemoverel) ~= "function" then
            if not state.Warned then
                state.Warned = true
                Library:Notify({Title = "Aimbot", Content = "Mouse method is not supported here, using Camera", Duration = 3, Type = "Warning"})
            end
            method = "Camera"
        end
        if method == "Mouse" then
            local v = cam:WorldToViewportPoint(pos)
            if v.Z > 0 then
                state.Acc = state.Acc + (Vector2.new(v.X, v.Y) - mouse) * alpha
                local mx = state.Acc.X >= 0 and math.floor(state.Acc.X) or math.ceil(state.Acc.X)
                local my = state.Acc.Y >= 0 and math.floor(state.Acc.Y) or math.ceil(state.Acc.Y)
                if mx ~= 0 or my ~= 0 then
                    state.Acc = state.Acc - Vector2.new(mx, my)
                    pcall(mousemoverel, mx, my)
                end
            end
        else
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, pos), alpha)
        end
    end

    local function drawFov(dt, center, radius)
        local want = F.FovEnabled == true
        state.Alpha = state.Alpha + ((want and 1 or 0) - state.Alpha) * math.min(1, dt * 12)
        local a = state.Alpha
        if a < 0.01 and not want then
            if fov.Visible then
                fov.Visible = false
            end
            return
        end
        fov.Visible = true
        if not state.FovPos then
            state.FovPos = center
        end
        state.FovPos = state.FovPos:Lerp(center, 1 - math.exp(-dt * 26))
        state.Radius = state.Radius + (radius - state.Radius) * math.min(1, dt * 14)
        local ease = 1 - (1 - a) ^ 3
        fovScale.Scale = 0.8 + 0.2 * ease
        local d = state.Radius * 2
        fov.Size = UDim2.fromOffset(d, d)
        fov.Position = UDim2.fromOffset(state.FovPos.X, state.FovPos.Y)
        fovStroke.Thickness = F.FovThickness or 2
        fovStroke.Transparency = 1 - ease
        fov.BackgroundColor3 = col("FovFill")
        fov.BackgroundTransparency = F.FovFillOn ~= false and (1 - (1 - (F.FovFillTransparency or 90) / 100) * ease) or 1
        local c1, c2, c3 = col("FovOutline1"), col("FovOutline2"), col("FovOutline3")
        if c1 ~= state.C1 or c2 ~= state.C2 or c3 ~= state.C3 then
            state.C1, state.C2, state.C3 = c1, c2, c3
            fovGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.33, c2),
                ColorSequenceKeypoint.new(0.66, c3),
                ColorSequenceKeypoint.new(1, c1),
            })
        end
        fovGrad.Rotation = (os.clock() * 50) % 360
    end

    local function step(dt)
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local t = os.clock()
        local mine = LocalPlayer.Character
        rayParams.FilterDescendantsInstances = mine and {mine} or {}
        local mid = cam.ViewportSize / 2
        local mouse = UserInputService:GetMouseLocation()
        local method = F.AimMethod or "Camera"
        local ref = method == "Mouse" and mouse or mid
        local fovMode = F.FovMode or "Follow mouse"
        local radius = F.FovSize or 150
        local useFov = F.FovEnabled == true
        local fovCenter = mouse
        if fovMode == "Stay in middle" then
            fovCenter = mid
        elseif fovMode == "Follow target" then
            fovCenter = ref
        end
        local minHp = F.AimHealthOn == true and (F.AimHealth or 0) or nil
        local drawCenter = fovCenter
        local myHum = mine and mine:FindFirstChildOfClass("Humanoid")
        if F.AimEnabled == true and myHum and myHum.Health > 0 then
            if state.Target then
                local char, hum = alive(state.Target)
                if not char or (minHp and hpPct(hum) < minHp) then
                    state.Target = nil
                end
            end
            if t - state.Pick > 0.05 and (not state.Target or F.AimSticky ~= true) then
                state.Pick = t
                state.Target = acquire(cam, ref, fovCenter, radius, useFov)
            end
            local plr = state.Target
            if plr then
                local char, hum, root = alive(plr)
                if char then
                    local part = choosePart(cam, char, hum, root, ref)
                    local ok = part ~= nil
                    if ok and F.AimWall == true and not visible(cam, part, char) then
                        ok = false
                    end
                    if ok then
                        if fovMode == "Follow target" then
                            local v = cam:WorldToViewportPoint(part.Position)
                            if v.Z > 0 then
                                drawCenter = Vector2.new(v.X, v.Y)
                            end
                        end
                        aimAt(cam, part, dt, t, method, mouse)
                    elseif F.AimSticky ~= true then
                        state.Target = nil
                    end
                else
                    state.Target = nil
                end
            end
        else
            state.Target = nil
        end
        Library.AimInfo.Aimbot = (F.AimEnabled == true and state.Target) or nil
        drawFov(dt, drawCenter, radius)
    end

    RunService:BindToRenderStep("PrestigeAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
        pcall(step, dt)
    end)

    onUnload(function()
        pcall(function()
            RunService:UnbindFromRenderStep("PrestigeAim")
        end)
        fovGui:Destroy()
    end)

    local GuiService = game:GetService("GuiService")

    local function newFovFrame(name)
        local frame = new("Frame", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(300, 300),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = fovGui,
        })
        new("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = frame})
        local scale = new("UIScale", {Scale = 0.8, Parent = frame})
        local stroke = new("UIStroke", {
            Thickness = 2,
            Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.new(1, 1, 1),
            Parent = frame,
        })
        local grad = new("UIGradient", {Parent = stroke})
        return {Frame = frame, Scale = scale, Stroke = stroke, Grad = grad, Alpha = 0, Pos = nil, Radius = 150}
    end

    local sfov = newFovFrame("SilentFov")

    local S = {
        Active = false,
        Target = nil,
        Part = nil,
        Hit = CFrame.new(),
        X = 0,
        Y = 0,
        UnitRay = Ray.new(Vector3.new(), Vector3.new(0, 0, -1)),
        Loc = Vector2.new(),
        Rolled = true,
        LastRoll = 0,
        Render = false,
        Pick = 0,
        Real = LocalPlayer:GetMouse(),
        RealUi = UserInputService,
        Patched = {},
        Scanning = false,
        ScanAt = nil,
        LastScan = 0,
        LastTool = nil,
        Warned = false,
        C1 = nil,
        C2 = nil,
        C3 = nil,
    }

    local function rollHit()
        S.LastRoll = os.clock()
        S.Rolled = math.random(1, 100) <= (F.SilentChance or 100)
    end

    local function forward(real, k)
        local v = real[k]
        if type(v) == "function" then
            local box = {real}
            return function(_, ...)
                return v(box[1], ...)
            end
        end
        return v
    end

    S.Proxy = setmetatable({}, {
        __index = function(_, k)
            if S.Active and not S.Render then
                if k == "Hit" then
                    return S.Hit
                elseif k == "Target" then
                    return S.Part
                elseif k == "X" then
                    return S.X
                elseif k == "Y" then
                    return S.Y
                elseif k == "UnitRay" then
                    return S.UnitRay
                end
            end
            return forward(S.Real, k)
        end,
        __newindex = function(_, k, v)
            S.Real[k] = v
        end,
        __tostring = function()
            return "Mouse"
        end,
    })

    S.UiProxy = setmetatable({}, {
        __index = function(_, k)
            if S.Active and not S.Render and k == "GetMouseLocation" then
                return function()
                    return S.Loc
                end
            end
            return forward(S.RealUi, k)
        end,
        __newindex = function(_, k, v)
            S.RealUi[k] = v
        end,
        __tostring = function()
            return "UserInputService"
        end,
    })

    local getUp = (debug and debug.getupvalues) or getupvalues
    local setUp = (debug and debug.setupvalue) or setupvalue
    local isOwn = isexecutorclosure or is_synapse_function or checkclosure

    local function supported()
        return type(getgc) == "function" and type(getUp) == "function" and type(setUp) == "function"
    end

    local function patchRestore()
        for _, e in ipairs(S.Patched) do
            pcall(setUp, e[1], e[2], e[3])
        end
        S.Patched = {}
    end

    local function patchScan()
        if S.Scanning then
            return
        end
        if not supported() then
            if not S.Warned then
                S.Warned = true
                Library:Notify({Title = "Silent Aim", Content = "Needs getgc and debug.setupvalue, which this executor lacks", Duration = 4, Type = "Warning"})
            end
            return
        end
        S.Scanning = true
        task.spawn(function()
            local ok, gc = pcall(getgc, true)
            if ok and type(gc) == "table" then
                local targets = {{S.Real, S.Proxy}}
                if type(isOwn) == "function" then
                    table.insert(targets, {S.RealUi, S.UiProxy})
                end
                for i = 1, #gc do
                    local f = gc[i]
                    if type(f) == "function" then
                        local skip = false
                        if type(isOwn) == "function" then
                            local okx, mine = pcall(isOwn, f)
                            skip = okx and mine == true
                        end
                        if not skip then
                            local okU, ups = pcall(getUp, f)
                            if okU and type(ups) == "table" then
                                for idx, uv in pairs(ups) do
                                    for _, tg in ipairs(targets) do
                                        if uv == tg[1] and pcall(setUp, f, idx, tg[2]) then
                                            table.insert(S.Patched, {f, idx, tg[1]})
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if i % 2500 == 0 then
                        task.wait()
                    end
                end
            end
            S.Scanning = false
        end)
    end

    local function silentEligible(plr, hum)
        if F.SilentHealthOn == true and hpPct(hum) < (F.SilentHealth or 20) then
            return false
        end
        if F.SilentTeam == true and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
            return false
        end
        return true
    end

    local function silentAcquire(cam, mouse, center, radius)
        local best, bestD = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char, hum, root = alive(plr)
                if char and silentEligible(plr, hum) then
                    local v, on = cam:WorldToViewportPoint((char:FindFirstChild("Head") or root).Position)
                    if on then
                        local sp = Vector2.new(v.X, v.Y)
                        if (sp - center).Magnitude <= radius then
                            local d = (sp - mouse).Magnitude
                            if d < bestD and (F.SilentWall ~= true or anyVisible(cam, char, root)) then
                                best, bestD = plr, d
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local tline = new("Frame", {
        Name = "SilentLine",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(0, 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        Parent = fovGui,
    })
    local tlineGrad = new("UIGradient", {Parent = tline})
    local tdot = new("Frame", {
        Name = "SilentDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        Parent = fovGui,
    })
    new("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = tdot})
    local tlineState = {Alpha = 0, End = nil, C1 = nil, C2 = nil, C3 = nil}

    local function drawTargetLine(dt, cam, mouse, has, tpos)
        local want = F.SilentLine == true and has
        tlineState.Alpha = tlineState.Alpha + ((want and 1 or 0) - tlineState.Alpha) * math.min(1, dt * 14)
        local a = tlineState.Alpha
        if a < 0.01 and not want then
            tline.Visible = false
            tdot.Visible = false
            tlineState.End = nil
            return
        end
        if want then
            if tlineState.End then
                tlineState.End = tlineState.End:Lerp(tpos, 1 - math.exp(-dt * 30))
            else
                tlineState.End = tpos
            end
        end
        local stop = tlineState.End
        if not stop then
            return
        end
        local size = cam.ViewportSize
        local origin = mouse
        local mode = F.SilentLineOrigin or "Mouse"
        if mode == "Bottom" then
            origin = Vector2.new(size.X / 2, size.Y)
        elseif mode == "Center" then
            origin = size / 2
        elseif mode == "Top" then
            origin = Vector2.new(size.X / 2, 0)
        end
        local delta = stop - origin
        local thick = F.SilentLineThickness or 2
        tline.Visible = true
        tline.Size = UDim2.fromOffset(delta.Magnitude, thick)
        tline.Position = UDim2.fromOffset((origin.X + stop.X) / 2, (origin.Y + stop.Y) / 2)
        tline.Rotation = math.deg(math.atan2(delta.Y, delta.X))
        local transp = 1 - (1 - (F.SilentLineTransparency or 0) / 100) * a
        tline.BackgroundTransparency = transp
        local c1, c2, c3 = col("SilentLineColor1"), col("SilentLineColor2"), col("SilentLineColor3")
        if c1 ~= tlineState.C1 or c2 ~= tlineState.C2 or c3 ~= tlineState.C3 then
            tlineState.C1, tlineState.C2, tlineState.C3 = c1, c2, c3
            tlineGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.5, c2),
                ColorSequenceKeypoint.new(1, c3),
            })
        end
        if F.SilentDot == true then
            local ds = F.SilentDotSize or 8
            tdot.Visible = true
            tdot.Size = UDim2.fromOffset(ds, ds)
            tdot.Position = UDim2.fromOffset(stop.X, stop.Y)
            tdot.BackgroundColor3 = c3
            tdot.BackgroundTransparency = transp
        else
            tdot.Visible = false
        end
    end

    local function drawSilentFov(dt, center, radius)
        local want = F.SilentShowFov == true
        sfov.Alpha = sfov.Alpha + ((want and 1 or 0) - sfov.Alpha) * math.min(1, dt * 12)
        local a = sfov.Alpha
        if a < 0.01 and not want then
            if sfov.Frame.Visible then
                sfov.Frame.Visible = false
            end
            return
        end
        sfov.Frame.Visible = true
        if not sfov.Pos then
            sfov.Pos = center
        end
        sfov.Pos = sfov.Pos:Lerp(center, 1 - math.exp(-dt * 26))
        sfov.Radius = sfov.Radius + (radius - sfov.Radius) * math.min(1, dt * 14)
        local ease = 1 - (1 - a) ^ 3
        sfov.Scale.Scale = 0.8 + 0.2 * ease
        local d = sfov.Radius * 2
        sfov.Frame.Size = UDim2.fromOffset(d, d)
        sfov.Frame.Position = UDim2.fromOffset(sfov.Pos.X, sfov.Pos.Y)
        sfov.Stroke.Thickness = F.SilentFovThickness or 2
        sfov.Stroke.Transparency = 1 - ease
        sfov.Frame.BackgroundColor3 = col("SilentFovFill")
        if F.SilentFovFillOn ~= false then
            sfov.Frame.BackgroundTransparency = 1 - (1 - (F.SilentFovFillTransparency or 90) / 100) * ease
        else
            sfov.Frame.BackgroundTransparency = 1
        end
        local c1, c2, c3 = col("SilentFovOutline1"), col("SilentFovOutline2"), col("SilentFovOutline3")
        if c1 ~= S.C1 or c2 ~= S.C2 or c3 ~= S.C3 then
            S.C1, S.C2, S.C3 = c1, c2, c3
            sfov.Grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.33, c2),
                ColorSequenceKeypoint.new(0.66, c3),
                ColorSequenceKeypoint.new(1, c1),
            })
        end
        sfov.Grad.Rotation = (os.clock() * 50) % 360
    end

    local function silentStep(dt)
        local cam = workspace.CurrentCamera
        if not cam then
            S.Active = false
            return
        end
        local t = os.clock()
        local mine = LocalPlayer.Character
        local myHum = mine and mine:FindFirstChildOfClass("Humanoid")
        local mouse = UserInputService:GetMouseLocation()
        local radius = F.SilentFovSize or 120
        local center = mouse
        if F.SilentFovMode == "Stay in middle" then
            center = cam.ViewportSize / 2
        end
        S.Active = false
        local hasTarget = false
        if F.SilentEnabled ~= true then
            if #S.Patched > 0 then
                patchRestore()
            end
            S.LastTool = nil
        else
            local tool = mine and mine:FindFirstChildOfClass("Tool")
            if tool ~= S.LastTool then
                S.LastTool = tool
                S.ScanAt = t + 0.4
            end
            if t - S.LastScan > 6 then
                S.LastScan = t
                S.ScanAt = t
            end
            if S.ScanAt and t >= S.ScanAt then
                S.ScanAt = nil
                patchScan()
            end
        end
        if F.SilentEnabled == true and myHum and myHum.Health > 0 then
            rayParams.FilterDescendantsInstances = mine and {mine} or {}
            if S.Target then
                local tc, th = alive(S.Target)
                if not tc or not silentEligible(S.Target, th) then
                    S.Target = nil
                end
            end
            if t - S.Pick > 0.03 and (not S.Target or F.SilentSticky ~= true) then
                S.Pick = t
                S.Target = silentAcquire(cam, mouse, center, radius)
            end
            local plr = S.Target
            if plr then
                local char, hum, root = alive(plr)
                if char then
                    local part = choosePart(cam, char, hum, root, mouse, silentFlags)
                    if part and (F.SilentWall ~= true or visible(cam, part, char)) then
                        local pos = part.Position
                        local v = cam:WorldToViewportPoint(pos)
                        if v.Z > 0 then
                            local camPos = cam.CFrame.Position
                            S.Part = part
                            S.Hit = CFrame.new(pos)
                            S.Loc = Vector2.new(v.X, v.Y)
                            S.X = v.X
                            S.Y = v.Y - GuiService:GetGuiInset().Y
                            S.UnitRay = Ray.new(camPos, (pos - camPos).Unit)
                            if t - S.LastRoll > 0.2 then
                                rollHit()
                            end
                            S.Active = S.Rolled
                            hasTarget = true
                        end
                    end
                else
                    S.Target = nil
                end
            end
        else
            S.Target = nil
        end
        Library.AimInfo.Target = (S.Active and S.Target) or nil
        drawSilentFov(dt, center, radius)
        drawTargetLine(dt, cam, mouse, hasTarget, S.Loc)
    end

    connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            rollHit()
        end
    end)

    connect(LocalPlayer.CharacterAdded, function()
        S.ScanAt = os.clock() + 1.5
    end)

    connect(RunService.Stepped, function()
        S.Render = false
    end)

    RunService:BindToRenderStep("PrestigeSilentBegin", Enum.RenderPriority.First.Value, function()
        S.Render = true
    end)

    RunService:BindToRenderStep("PrestigeSilent", Enum.RenderPriority.Camera.Value + 1, function(dt)
        pcall(silentStep, dt)
    end)

    onUnload(function()
        S.Active = false
        patchRestore()
        pcall(function()
            RunService:UnbindFromRenderStep("PrestigeSilent")
            RunService:UnbindFromRenderStep("PrestigeSilentBegin")
        end)
    end)

    local sec = sub:AddSection("Aimbot", "Left")
    sec:AddToggle({Name = "Enable", HudName = "Aimbot", Flag = "AimEnabled", Default = false, Keybind = true, Hud = true})
    sec:AddDropdown({Name = "Method", Flag = "AimMethod", Options = {"Mouse", "Camera"}, Default = "Camera"})
    sec:AddDropdown({Name = "Hit Part", Flag = "AimHitPart", Options = hitOptions, Default = "Closest"})
    sec:AddDropdown({Name = "Jump Part", Flag = "AimJumpPart", Options = partNames, Default = "Lower Torso"})

    local set = sub:AddSection("Settings", "Left")
    set:AddToggle({Name = "Wallcheck", Flag = "AimWall", Default = true})
    set:AddToggle({Name = "Sticky Aim", Flag = "AimSticky", Default = false})
    local hpT = set:AddToggle({Name = "Health Check", Flag = "AimHealthOn", Default = false})
    local hpG = set:AddGroup(hpT)
    hpG:AddSlider({Name = "Min Health", Flag = "AimHealth", Min = 0, Max = 100, Default = 20})

    local tune = sub:AddSection("Tuning", "Right")
    tune:AddSlider({Name = "Smoothness", Flag = "AimSmooth", Min = 0, Max = 100, Default = 30})
    tune:AddSlider({Name = "Strength", Flag = "AimStrength", Min = 0, Max = 100, Default = 100})
    tune:AddSlider({Name = "Human Aim", Flag = "AimHuman", Min = 0, Max = 100, Default = 0})

    local fv = sub:AddSection("FOV", "Right")
    local fvT = fv:AddToggle({Name = "Enable FOV", HudName = "FOV", Flag = "FovEnabled", Default = false, Keybind = true, Hud = true})
    local fvG = fv:AddGroup(fvT)
    fvG:AddDropdown({Name = "Mode", Flag = "FovMode", Options = {"Follow mouse", "Follow target", "Stay in middle"}, Default = "Follow mouse"})
    fvG:AddSlider({Name = "Size", Flag = "FovSize", Min = 20, Max = 600, Default = 150, Suffix = "px"})
    fvG:AddSlider({Name = "Outline Thickness", Flag = "FovThickness", Min = 1, Max = 8, Default = 2, Suffix = "px"})
    fvG:AddGradient({Name = "Outline Gradient", Flag = "FovOutline", Defaults = {Color3.fromRGB(150, 60, 255), Color3.fromRGB(50, 120, 255), Color3.fromRGB(255, 255, 255)}})
    fvG:AddToggle({Name = "Fill FOV", Flag = "FovFillOn", Default = true})
    fvG:AddColorPicker({Name = "Fill Color", Flag = "FovFill", Default = Color3.fromRGB(150, 60, 255)})
    fvG:AddSlider({Name = "Fill Transparency", Flag = "FovFillTransparency", Min = 0, Max = 100, Default = 90})

    local ss = silentSub:AddSection("Silent Aim", "Left")
    ss:AddToggle({Name = "Enable", HudName = "Silent Aim", Flag = "SilentEnabled", Default = false, Keybind = true, Hud = true})
    ss:AddDropdown({Name = "Hit Part", Flag = "SilentHitPart", Options = hitOptions, Default = "Closest"})
    ss:AddDropdown({Name = "Jump Part", Flag = "SilentJumpPart", Options = partNames, Default = "Lower Torso"})
    ss:AddSlider({Name = "Hit Chance", Flag = "SilentChance", Min = 1, Max = 100, Default = 100})

    local sset = silentSub:AddSection("Settings", "Left")
    sset:AddToggle({Name = "Wallcheck", Flag = "SilentWall", Default = true})
    sset:AddToggle({Name = "Team Check", Flag = "SilentTeam", Default = false})
    sset:AddToggle({Name = "Sticky Target", Flag = "SilentSticky", Default = false})
    local shpT = sset:AddToggle({Name = "Health Check", Flag = "SilentHealthOn", Default = false})
    local shpG = sset:AddGroup(shpT)
    shpG:AddSlider({Name = "Min Health", Flag = "SilentHealth", Min = 0, Max = 100, Default = 20})

    local stg = silentSub:AddSection("Target", "Right")
    local stgT = stg:AddToggle({Name = "Target Line", HudName = "Target Line", Flag = "SilentLine", Default = false, Keybind = true, Hud = true})
    local stgG = stg:AddGroup(stgT)
    stgG:AddDropdown({Name = "Origin", Flag = "SilentLineOrigin", Options = {"Mouse", "Bottom", "Center", "Top"}, Default = "Mouse"})
    stgG:AddSlider({Name = "Thickness", Flag = "SilentLineThickness", Min = 1, Max = 6, Default = 2, Suffix = "px"})
    stgG:AddSlider({Name = "Transparency", Flag = "SilentLineTransparency", Min = 0, Max = 90, Default = 0})
    stgG:AddGradient({Name = "Line Gradient", Flag = "SilentLineColor", Defaults = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(50, 120, 255), Color3.fromRGB(150, 60, 255)}})
    local dotT = stgG:AddToggle({Name = "Target Dot", Flag = "SilentDot", Default = true})
    local dotG = stgG:AddGroup(dotT)
    dotG:AddSlider({Name = "Dot Size", Flag = "SilentDotSize", Min = 3, Max = 20, Default = 8, Suffix = "px"})

    local sf = silentSub:AddSection("FOV", "Right")
    sf:AddSlider({Name = "FOV Size", Flag = "SilentFovSize", Min = 20, Max = 600, Default = 120, Suffix = "px"})
    sf:AddDropdown({Name = "Mode", Flag = "SilentFovMode", Options = {"Follow mouse", "Stay in middle"}, Default = "Follow mouse"})
    local sfT = sf:AddToggle({Name = "Show FOV", HudName = "Silent FOV", Flag = "SilentShowFov", Default = false, Keybind = true, Hud = true})
    local sfG = sf:AddGroup(sfT)
    sfG:AddSlider({Name = "Outline Thickness", Flag = "SilentFovThickness", Min = 1, Max = 8, Default = 2, Suffix = "px"})
    sfG:AddGradient({Name = "Outline Gradient", Flag = "SilentFovOutline", Defaults = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(50, 120, 255), Color3.fromRGB(150, 60, 255)}})
    sfG:AddToggle({Name = "Fill FOV", Flag = "SilentFovFillOn", Default = true})
    sfG:AddColorPicker({Name = "Fill Color", Flag = "SilentFovFill", Default = Color3.fromRGB(50, 120, 255)})
    sfG:AddSlider({Name = "Fill Transparency", Flag = "SilentFovFillTransparency", Min = 0, Max = 100, Default = 90})
end

buildAimbot(aimSub, silentSub)

local function buildWeapons(sub)
    local F = Library.Flags
    local SoundService = game:GetService("SoundService")
    local Debris = game:GetService("Debris")

    local sounds = {
        ["Rust Headshot"] = "138750331387064",
        ["Neverlose"] = "110168723447153",
        ["Bubble"] = "6534947588",
        ["Laser"] = "7837461331",
        ["Steve"] = "4965083997",
        ["Call of Duty"] = "5952120301",
        ["Bat"] = "3333907347",
        ["TF2 Critical"] = "296102734",
        ["Saber"] = "8415678813",
        ["Bameware"] = "3124331820",
        ["Money"] = "13956013041",
        ["Notif"] = "6696469190",
        ["Shutter"] = "10066921516",
        ["RIFK7"] = "9102080552",
        ["LazerBeam"] = "130791043",
        ["WindowsXPError"] = "160715357",
        ["TF2Hitsound"] = "3455144981",
        ["TF2Bat"] = "3333907347",
        ["BowHit"] = "1053296915",
        ["Bow"] = "3442683707",
        ["OSU"] = "7147454322",
        ["OneNN"] = "7349055654",
        ["Rust"] = "6565371338",
        ["TF2Pan"] = "3431749479",
        ["Mario"] = "5709456554",
        ["Bell"] = "6534947240",
        ["Pick"] = "1347140027",
        ["Pop"] = "198598793",
        ["Sans"] = "3188795283",
        ["Fart"] = "130833677",
        ["Big"] = "5332005053",
        ["Vine"] = "5332680810",
        ["Bruh"] = "4578740568",
        ["Skeet"] = "5633695679",
        ["Fatality"] = "6534947869",
        ["Bonk"] = "5766898159",
        ["Minecraft"] = "5869422451",
        ["Gamesense"] = "4817809188",
        ["Bamboo"] = "3769434519",
        ["Crowbar"] = "546410481",
        ["Weeb"] = "6442965016",
        ["Beep"] = "8177256015",
        ["Bambi"] = "8437203821",
        ["Stone"] = "3581383408",
        ["Old Fatality"] = "6607142036",
        ["Click"] = "8053704437",
        ["Ding"] = "7149516994",
        ["Snow"] = "6455527632",
        ["Osu"] = "7149255551",
        ["TF2"] = "2868331684",
        ["Slime"] = "6916371803",
        ["Among Us"] = "5700183626",
        ["One"] = "7380502345",
        ["BulletDeflect"] = "1657157666",
        ["Default"] = "330595293",
        ["UwU"] = "8679659744",
        ["Cod"] = "160432334",
        ["Blood SFX"] = "8164951181",
        ["Blood Burst"] = "3781479909",
        ["Blood Hit"] = "429400881",
    }
    local names = {}
    for name in pairs(sounds) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    table.insert(names, "Custom")

    local gunNames = {"[Double-Barrel SG]", "[Revolver]", "[TacticalShotgun]", "Any Tool"}

    local state = {
        Tool = nil,
        ToolConns = {},
        Ammo = nil,
        AmmoLast = nil,
        FireAt = -10,
        FireTool = nil,
        Pending = {},
        LastPlay = 0,
        Watch = {},
    }

    local function soundId()
        local pick = F.HitSoundSelect or "Default"
        if pick == "Custom" then
            local id = string.match(tostring(F.HitSoundCustom or ""), "%d+")
            return id
        end
        return sounds[pick]
    end

    local function play(force)
        local id = soundId()
        if not id then
            return
        end
        local now = os.clock()
        if not force and now - state.LastPlay < 0.06 then
            return
        end
        state.LastPlay = now
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxassetid://" .. id
        snd.Volume = (F.HitSoundVolume or 50) / 10
        snd.PlaybackSpeed = (F.HitSoundPitch or 100) / 100
        snd.Parent = SoundService
        snd:Play()
        Debris:AddItem(snd, 4)
    end

    local function gunAllowed(tool)
        if not tool then
            return false
        end
        local sel = F.HitSoundGuns
        if type(sel) ~= "table" then
            return true
        end
        if table.find(sel, "Any Tool") then
            return true
        end
        return table.find(sel, tool.Name) ~= nil
    end

    local function aimedAt(plr, char)
        local info = Library.AimInfo
        if info and (info.Target == plr or info.Aimbot == plr) then
            return true
        end
        local cam = workspace.CurrentCamera
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not cam or not root then
            return false
        end
        local m = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(m.X, m.Y)
        local dir = root.Position - ray.Origin
        if dir.Magnitude < 0.1 then
            return true
        end
        return ray.Direction:Dot(dir.Unit) > math.cos(math.rad(15))
    end

    local function window()
        local ping = 0
        pcall(function()
            ping = LocalPlayer:GetNetworkPing()
        end)
        return 0.3 + ping * 1.5
    end

    local function confirm(entry)
        if F.HitSoundEnabled ~= true then
            return
        end
        if not gunAllowed(state.FireTool) then
            return
        end
        local plr, char = entry.Plr, entry.Char
        if not plr.Parent or not char.Parent then
            return
        end
        if aimedAt(plr, char) then
            play(false)
        end
    end

    local function onFire()
        local now = os.clock()
        state.FireAt = now
        state.FireTool = state.Tool
        local keep = {}
        for _, e in ipairs(state.Pending) do
            if now - e.T <= 0.25 then
                confirm(e)
            end
        end
        state.Pending = keep
    end

    local function onDamage(plr, char)
        if F.HitSoundEnabled ~= true then
            return
        end
        local now = os.clock()
        local entry = {Plr = plr, Char = char, T = now}
        if now - state.FireAt <= window() and gunAllowed(state.FireTool) then
            confirm(entry)
        else
            table.insert(state.Pending, entry)
            if #state.Pending > 12 then
                table.remove(state.Pending, 1)
            end
        end
    end

    local function dropToolConns()
        for _, c in ipairs(state.ToolConns) do
            c:Disconnect()
        end
        state.ToolConns = {}
        state.Ammo = nil
        state.AmmoLast = nil
    end

    local function bindTool(tool)
        dropToolConns()
        state.Tool = tool
        if not tool then
            return
        end
        local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Ammo", true)
        if ammo and pcall(function()
            return ammo.Value
        end) and type(ammo.Value) == "number" then
            state.Ammo = ammo
            state.AmmoLast = ammo.Value
            table.insert(state.ToolConns, ammo:GetPropertyChangedSignal("Value"):Connect(function()
                local v = ammo.Value
                if state.AmmoLast and v < state.AmmoLast then
                    onFire()
                end
                state.AmmoLast = v
            end))
        else
            table.insert(state.ToolConns, tool.Activated:Connect(onFire))
        end
    end

    local function unwatch(plr)
        local w = state.Watch[plr]
        if w then
            for _, c in ipairs(w) do
                c:Disconnect()
            end
            state.Watch[plr] = nil
        end
    end

    local function watchChar(plr, char)
        unwatch(plr)
        local conns = {}
        state.Watch[plr] = conns
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 8)
            if not hum or state.Watch[plr] ~= conns then
                return
            end
            local last = hum.Health
            table.insert(conns, hum.HealthChanged:Connect(function(h)
                local d = last - h
                last = h
                if d > 0.01 then
                    onDamage(plr, char)
                end
            end))
            local fx = char:FindFirstChild("BodyEffects") or char:WaitForChild("BodyEffects", 3)
            local armor = fx and fx:FindFirstChild("Armor")
            if armor and type(armor.Value) == "number" then
                local alast = armor.Value
                table.insert(conns, armor:GetPropertyChangedSignal("Value"):Connect(function()
                    local v = armor.Value
                    local d = alast - v
                    alast = v
                    if d > 0.01 then
                        onDamage(plr, char)
                    end
                end))
            end
        end)
    end

    local function watchPlayer(plr)
        if plr == LocalPlayer then
            return
        end
        if plr.Character then
            watchChar(plr, plr.Character)
        end
        connect(plr.CharacterAdded, function(char)
            watchChar(plr, char)
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        watchPlayer(plr)
    end
    connect(Players.PlayerAdded, watchPlayer)
    connect(Players.PlayerRemoving, unwatch)

    connect(RunService.Heartbeat, function()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool ~= state.Tool then
            bindTool(tool)
        end
    end)

    onUnload(function()
        dropToolConns()
        for plr in pairs(state.Watch) do
            unwatch(plr)
        end
    end)

    local gunSet = {["[Double-Barrel SG]"] = true, ["[Revolver]"] = true, ["[TacticalShotgun]"] = true}
    local function isZeroName(name)
        local l = string.lower(name)
        return l:find("cooldown", 1, true) ~= nil or l:find("firerate", 1, true) ~= nil or l:find("fire_rate", 1, true) ~= nil
            or l:find("firedelay", 1, true) ~= nil or l:find("shootdelay", 1, true) ~= nil or l:find("shotdelay", 1, true) ~= nil
    end
    local rapid = {Vals = {}, Attrs = {}, AttrSeen = {}, Tabs = {}, TabSeen = {}, ScanAt = 0, GcAt = 0, Scanning = false, Active = false, LastBurst = 0}

    local function rapidScan(tool)
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("ValueBase") and isZeroName(d.Name) and rapid.Vals[d] == nil and type(d.Value) == "number" then
                rapid.Vals[d] = d.Value
            end
        end
        for name, value in pairs(tool:GetAttributes()) do
            local seen = rapid.AttrSeen[tool]
            if not seen then
                seen = {}
                rapid.AttrSeen[tool] = seen
            end
            if isZeroName(name) and not seen[name] and type(value) == "number" then
                seen[name] = true
                table.insert(rapid.Attrs, {tool, name, value})
            end
        end
    end

    local function rapidRestore()
        for inst, v in pairs(rapid.Vals) do
            if inst.Parent then
                pcall(function()
                    inst.Value = v
                end)
            end
        end
        for _, e in ipairs(rapid.Attrs) do
            if e[1].Parent then
                pcall(function()
                    e[1]:SetAttribute(e[2], e[3])
                end)
            end
        end
        for _, e in ipairs(rapid.Tabs) do
            pcall(function()
                e[1][e[2]] = e[3]
            end)
        end
        rapid.Vals = {}
        rapid.Attrs = {}
        rapid.AttrSeen = {}
        rapid.Tabs = {}
        rapid.TabSeen = {}
        rapid.Active = false
    end

    local gcZero = {"ShootingCooldown", "FireRate"}
    local gcCount = {"Pellets", "BulletCount", "BulletsPerShot", "ShotCount", "NumPellets"}

    local function gcScan()
        if rapid.Scanning or type(getgc) ~= "function" then
            return
        end
        rapid.Scanning = true
        task.spawn(function()
            local ok, gc = pcall(getgc, true)
            if ok and type(gc) == "table" then
                for i = 1, #gc do
                    local t = gc[i]
                    if type(t) == "table" and t ~= F and not rapid.TabSeen[t] then
                        local hit = false
                        for _, k in ipairs(gcZero) do
                            local v = rawget(t, k)
                            if type(v) == "number" then
                                hit = true
                                table.insert(rapid.Tabs, {t, k, v, "zero"})
                            end
                        end
                        if hit then
                            rapid.TabSeen[t] = true
                            for _, k in ipairs(gcCount) do
                                local v = rawget(t, k)
                                if type(v) == "number" then
                                    table.insert(rapid.Tabs, {t, k, v, "count"})
                                end
                            end
                        end
                    end
                    if i % 2500 == 0 then
                        task.wait()
                    end
                end
            end
            rapid.Scanning = false
        end)
    end

    local function rapidTools()
        local list = {}
        local char = LocalPlayer.Character
        local pack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if pack then
            for _, t in ipairs(pack:GetChildren()) do
                if t:IsA("Tool") and gunSet[t.Name] then
                    table.insert(list, t)
                end
            end
        end
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and gunSet[t.Name] then
                    table.insert(list, t)
                end
            end
        end
        return list
    end

    connect(RunService.Heartbeat, function()
        if F.RapidEnabled ~= true then
            if rapid.Active then
                rapidRestore()
            end
            return
        end
        rapid.Active = true
        local now = os.clock()
        local tools = rapidTools()
        if now - rapid.ScanAt > 1 then
            rapid.ScanAt = now
            for _, t in ipairs(tools) do
                rapidScan(t)
            end
        end
        if now - rapid.GcAt > 3 then
            rapid.GcAt = now
            gcScan()
        end
        local bullets = F.RapidShots or 25
        for _, e in ipairs(rapid.Tabs) do
            local want = e[4] == "zero" and 0 or math.max(e[3], bullets)
            if rawget(e[1], e[2]) ~= want then
                pcall(function()
                    e[1][e[2]] = want
                end)
            end
        end
        for inst in pairs(rapid.Vals) do
            if inst.Parent then
                if inst.Value ~= 0 then
                    inst.Value = 0
                end
            else
                rapid.Vals[inst] = nil
            end
        end
        for _, e in ipairs(rapid.Attrs) do
            if e[1].Parent and e[1]:GetAttribute(e[2]) ~= 0 then
                e[1]:SetAttribute(e[2], 0)
            end
        end
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool or not gunSet[tool.Name] then
            return
        end
        if windowVisible or UserInputService:GetFocusedTextBox() then
            return
        end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            for _ = 1, bullets do
                tool:Activate()
            end
        end
    end)

    onUnload(function()
        rapidRestore()
    end)

    local hs = sub:AddSection("Hit Sound", "Left")
    hs:AddToggle({Name = "Hit Sound", Flag = "HitSoundEnabled", Default = false, Keybind = true, Hud = true})
    hs:AddDropdown({Name = "Sound", Flag = "HitSoundSelect", Options = names, Default = "Default"})
    hs:AddTextbox({Name = "Custom Sound ID", Flag = "HitSoundCustom", Placeholder = "asset id"})
    hs:AddSlider({Name = "Volume", Flag = "HitSoundVolume", Min = 1, Max = 100, Default = 50})
    hs:AddSlider({Name = "Pitch", Flag = "HitSoundPitch", Min = 50, Max = 200, Default = 100})
    hs:AddButton({Name = "Preview Sound", Callback = function()
        play(true)
    end})

    local wp = sub:AddSection("Weapons", "Right")
    wp:AddDropdown({Name = "Play For", Flag = "HitSoundGuns", Multi = true, Options = gunNames, Default = {"[Double-Barrel SG]", "[Revolver]", "[TacticalShotgun]"}})

    local rf = sub:AddSection("Rapid Fire", "Right")
    rf:AddToggle({Name = "Rapid Fire", Flag = "RapidEnabled", Default = false, Keybind = true, Hud = true})
    rf:AddSlider({Name = "Bullets Per Shot", Flag = "RapidShots", Min = 1, Max = 100, Default = 25, Suffix = ""})
    rf:AddButton({Name = "Copy Gun Info", Callback = function()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then
            Library:Notify({Title = "Rapid Fire", Content = "Equip a gun first", Duration = 3, Type = "Warning"})
            return
        end
        local out = {"Tool: " .. tool.Name}
        local root = tool:GetFullName()
        for _, d in ipairs(tool:GetDescendants()) do
            local line = d.ClassName .. " " .. string.sub(d:GetFullName(), #root + 2)
            if d:IsA("ValueBase") then
                line = line .. " = " .. tostring(d.Value)
            end
            table.insert(out, line)
        end
        for name, value in pairs(tool:GetAttributes()) do
            table.insert(out, "Attribute " .. name .. " = " .. tostring(value))
        end
        local remotes = {}
        for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and #remotes < 80 then
                table.insert(remotes, d.ClassName .. " " .. d:GetFullName())
            end
        end
        table.insert(out, "Remotes:")
        for _, r in ipairs(remotes) do
            table.insert(out, r)
        end
        local text = table.concat(out, "\n")
        local copied = false
        if type(setclipboard) == "function" then
            copied = pcall(setclipboard, text)
        end
        print(text)
        Library:Notify({Title = "Rapid Fire", Content = copied and "Gun info copied to clipboard" or "Gun info printed to the console", Duration = 3, Type = "Success"})
    end})
end

local function buildVisuals(visualsTab)
    local F = Library.Flags
    local Lighting = game:GetService("Lighting")
    local WHITE = Color3.new(1, 1, 1)
    local BLACK = Color3.new(0, 0, 0)

    local function col(flag, fallback)
        local v = F[flag]
        if typeof(v) == "Color3" then
            return v
        end
        return fallback or WHITE
    end

    local function join(...)
        local out = {}
        for i = 1, select("#", ...) do
            out[i] = tostring((select(i, ...)))
        end
        return table.concat(out, "|")
    end

    local function sample(c1, c2, c3, t)
        t = math.clamp(t, 0, 1)
        if t < 0.5 then
            return c1:Lerp(c2, t * 2)
        end
        return c2:Lerp(c3, (t - 0.5) * 2)
    end

    local function cycle(c1, c2, c3, t)
        local p = t % 1
        if p < 1 / 3 then
            return c1:Lerp(c2, p * 3)
        elseif p < 2 / 3 then
            return c2:Lerp(c3, (p - 1 / 3) * 3)
        end
        return c3:Lerp(c1, (p - 2 / 3) * 3)
    end

    local function seq3(c1, c2, c3)
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(0.5, c2),
            ColorSequenceKeypoint.new(1, c3),
        })
    end

    local function destroyList(list)
        for _, o in ipairs(list) do
            pcall(function()
                o:Destroy()
            end)
        end
    end

    local function feetOffset(hum, root)
        if hum.RigType == Enum.HumanoidRigType.R6 then
            return 3
        end
        return root.Size.Y / 2 + hum.HipHeight
    end

    local espGui = new("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 990,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local parented = pcall(function()
        if type(gethui) == "function" then
            espGui.Parent = gethui()
        else
            espGui.Parent = CoreGui
        end
    end)
    if not parented or not espGui.Parent then
        espGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local espLayer = new("Frame", {
        Name = "Layer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = espGui,
    })
    local chamFolder = new("Folder", {Name = HttpService:GenerateGUID(false), Parent = espGui.Parent})
    local selfFolder = new("Folder", {Name = HttpService:GenerateGUID(false)})

    local esp = {}
    local seqs, sigs, vers = {}, {}, {}
    local espWasOn = false
    local sweepTimer = 0

    local fillImages = {
        ["Crying Angel"] = 94899736160869,
        ["Baby Angel"] = 130920013387994,
        ["Stick Man Angel"] = 135410146829409,
    }

    local function refresh(key, a, b, c)
        local sig = tostring(a) .. tostring(b) .. tostring(c)
        if sigs[key] ~= sig then
            sigs[key] = sig
            seqs[key] = seq3(a, b, c)
            vers[key] = (vers[key] or 0) + 1
        end
    end

    local function useSeq(e, key, grad, slot)
        slot = slot or key
        if e.Ver[slot] ~= vers[key] then
            e.Ver[slot] = vers[key]
            grad.Color = seqs[key]
        end
    end

    local function fillImageId()
        local sel = F.FillImage
        local id = fillImages[sel]
        if sel == "Custom" or not id then
            local n = tostring(F.FillCustomId or ""):match("%d+")
            if n then
                return asset(n)
            end
            return ""
        end
        return asset(id)
    end

    local function nameText(plr, wantUser, wantDisplay)
        if wantUser and wantDisplay then
            if plr.DisplayName == plr.Name then
                return plr.Name
            end
            return plr.DisplayName .. " (@" .. plr.Name .. ")"
        elseif wantDisplay then
            return plr.DisplayName
        elseif wantUser then
            return plr.Name
        end
        return ""
    end

    local cornerLayout = {
        {Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), true},
        {Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), false},
        {Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), true},
        {Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), false},
        {Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), true},
        {Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), false},
        {Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), true},
        {Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), false},
    }

    local function makeEntry(plr)
        local e = {Player = plr, Hp = 1, Ver = {}, Char = nil, Img = ""}
        e.Root = new("Frame", {
            Name = "Box",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(64, 96),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Parent = espLayer,
        })
        e.FillColor = new("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Visible = false,
            Parent = e.Root,
        })
        e.FillGrad = new("UIGradient", {Rotation = 90, Parent = e.FillColor})
        e.FillImg = new("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = "",
            Visible = false,
            Parent = e.Root,
        })
        e.Outline = new("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 2,
            Parent = e.Root,
        })
        e.Stroke = new("UIStroke", {
            Thickness = 1.5,
            Color = WHITE,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = e.Outline,
        })
        e.StrokeGrad = new("UIGradient", {Parent = e.Stroke})

        e.Corners = {}
        for i, layout in ipairs(cornerLayout) do
            local f = new("Frame", {
                AnchorPoint = layout[1],
                Position = layout[2],
                Size = UDim2.fromOffset(8, 2),
                BackgroundColor3 = WHITE,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 2,
                Parent = e.Root,
            })
            e.Corners[i] = {Frame = f, Grad = new("UIGradient", {Parent = f}), Horizontal = layout[3], Slot = "c" .. i}
        end

        e.HpBack = new("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(0, -3, 0, 0),
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = BLACK,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 3,
            Parent = e.Root,
        })
        new("UIStroke", {
            Thickness = 1,
            Color = BLACK,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = e.HpBack,
        })
        e.HpClip = new("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 4,
            Parent = e.HpBack,
        })
        e.HpFull = new("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 96),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            ZIndex = 4,
            Parent = e.HpClip,
        })
        e.HpGrad = new("UIGradient", {Rotation = 90, Parent = e.HpFull})

        e.Tag = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, 3),
            Size = UDim2.fromOffset(0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 5,
            Parent = e.Root,
        })
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = e.Tag,
        })
        e.NameLabel = new("TextLabel", {
            Size = UDim2.fromOffset(0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            Text = "",
            TextColor3 = WHITE,
            TextSize = 13,
            LayoutOrder = 1,
            Visible = false,
            ZIndex = 5,
            Parent = e.Tag,
        })
        e.NameGrad = new("UIGradient", {Parent = e.NameLabel})
        e.NameStroke = new("UIStroke", {Thickness = 1, Color = WHITE, Parent = e.NameLabel})
        e.NameStrokeGrad = new("UIGradient", {Parent = e.NameStroke})
        e.InfoLabel = new("TextLabel", {
            Size = UDim2.fromOffset(0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            Text = "",
            TextColor3 = WHITE,
            TextSize = 11,
            LayoutOrder = 2,
            Visible = false,
            ZIndex = 5,
            Parent = e.Tag,
        })
        e.InfoGrad = new("UIGradient", {Parent = e.InfoLabel})
        e.InfoStroke = new("UIStroke", {Thickness = 1, Color = BLACK, Parent = e.InfoLabel})

        e.Tracer = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(0, 1),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
            Visible = false,
            Parent = espLayer,
        })
        e.TracerGrad = new("UIGradient", {Parent = e.Tracer})

        e.Highlight = new("Highlight", {Enabled = false, Parent = chamFolder})
        return e
    end

    local function destroyEntry(e)
        pcall(function()
            e.Root:Destroy()
            e.Tracer:Destroy()
            e.Highlight:Destroy()
        end)
    end

    local function hideEntry(e)
        e.Root.Visible = false
        e.Tracer.Visible = false
        e.Highlight.Enabled = false
    end

    local function addPlayer(plr)
        if not esp[plr] then
            esp[plr] = makeEntry(plr)
        end
    end

    local function removePlayer(plr)
        local e = esp[plr]
        if e then
            esp[plr] = nil
            destroyEntry(e)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        addPlayer(plr)
    end
    connect(Players.PlayerAdded, addPlayer)
    connect(Players.PlayerRemoving, removePlayer)

    local function espStep(dt)
        local cam = workspace.CurrentCamera
        if not (F.ESPEnabled == true and cam) then
            if espWasOn then
                espWasOn = false
                for _, e in pairs(esp) do
                    hideEntry(e)
                end
            end
            return
        end
        espWasOn = true
        local t = os.clock()

        sweepTimer = sweepTimer + dt
        if sweepTimer > 1 then
            sweepTimer = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                addPlayer(plr)
            end
            for plr in pairs(esp) do
                if plr.Parent ~= Players then
                    removePlayer(plr)
                end
            end
        end

        refresh("Box", col("BoxColor1", BLACK), col("BoxColor2", WHITE), col("BoxColor3", BLACK))
        refresh("Fill", col("FillColor1"), col("FillColor2"), col("FillColor3"))
        refresh("NameText", col("NameText1"), col("NameText2"), col("NameText3"))
        refresh("NameStroke", col("NameOut1", BLACK), col("NameOut2", WHITE), col("NameOut3", BLACK))
        refresh("Info", col("InfoColor1"), col("InfoColor2"), col("InfoColor3"))
        refresh("Hp", col("HpColor1"), col("HpColor2"), col("HpColor3", BLACK))
        refresh("Tracer", col("TracerColor1"), col("TracerColor2"), col("TracerColor3"))

        local fit = F.ESPSizeMode ~= "Fixed"
        local fixedW = F.ESPWidth or 64
        local fixedH = F.ESPHeight or 96
        local pad = (F.ESPPad or 8) / 100
        local ratio = (F.ESPRatio or 52) / 100
        local minH = F.ESPMinH or 16
        local maxDist = F.ESPDistance or 2500
        local textSize = F.ESPTextSize or 13
        local camPos = cam.CFrame.Position
        local vp = cam.ViewportSize
        local boxOn = F.BoxEnabled == true
        local cornerStyle = F.BoxStyle == "Corners"
        local fillOn = F.FillEnabled == true
        local imageMode = F.FillType == "Image"
        local imageId = (fillOn and imageMode) and fillImageId() or ""
        local nameOn = F.NameEnabled == true
        local modes = F.NameMode
        local wantUser = type(modes) == "table" and table.find(modes, "Username") ~= nil
        local wantDisplay = type(modes) == "table" and table.find(modes, "Display") ~= nil
        local infoOn = F.InfoEnabled == true
        local hpOn = F.HealthEnabled == true
        local tracerOn = F.TracerEnabled == true
        local chamsOn = F.ChamsEnabled == true
        local gspeed = F.ESPGradSpeed or 60
        local spin = (t * gspeed) % 360
        local sway = math.sin(t * gspeed / 60) * 0.4
        local showSelf = F.ESPSelf == true
        local hideTeam = F.ESPTeam == true

        local chamSpeed = (F.ChamsSpeed or 30) / 100
        local cf1, cf2, cf3 = col("ChamsFill1"), col("ChamsFill2"), col("ChamsFill3")
        local co1, co2, co3 = col("ChamsOutline1"), col("ChamsOutline2"), col("ChamsOutline3")
        local chamFill, chamOut = cf1, co1
        if F.ChamsCycle ~= false then
            chamFill = cycle(cf1, cf2, cf3, t * chamSpeed)
            chamOut = cycle(co1, co2, co3, t * chamSpeed + 0.33)
        end

        for plr, e in pairs(esp) do
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            local ok = hum ~= nil and root ~= nil and hum.Health > 0
            if ok and plr == LocalPlayer and not showSelf then
                ok = false
            end
            if ok and hideTeam and plr ~= LocalPlayer and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
                ok = false
            end
            local dist = 0
            if ok then
                dist = (camPos - root.Position).Magnitude
                if dist > maxDist then
                    ok = false
                end
            end

            local hl = e.Highlight
            if ok and chamsOn then
                if hl.Adornee ~= char then
                    hl.Adornee = char
                end
                hl.Enabled = true
                hl.FillColor = chamFill
                hl.OutlineColor = chamOut
                hl.FillTransparency = (F.ChamsFillTransparency or 60) / 100
                hl.OutlineTransparency = (F.ChamsOutlineTransparency or 0) / 100
                hl.DepthMode = F.ChamsVisible == true and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            else
                hl.Enabled = false
            end

            local cx, cy, w, h = 0, 0, 0, 0
            if ok then
                if fit then
                    local head = char:FindFirstChild("Head")
                    local px, pz = root.Position.X, root.Position.Z
                    local topY = (head and (head.Position.Y + head.Size.Y / 2) or (root.Position.Y + 2.5)) + 0.1
                    local botY = root.Position.Y - feetOffset(hum, root)
                    local top = cam:WorldToViewportPoint(Vector3.new(px, topY, pz))
                    local bot = cam:WorldToViewportPoint(Vector3.new(px, botY, pz))
                    if top.Z <= 0 or bot.Z <= 0 then
                        ok = false
                    else
                        h = math.max(math.abs(bot.Y - top.Y) * (1 + pad), minH)
                        w = h * ratio
                        cx = (top.X + bot.X) / 2
                        cy = (top.Y + bot.Y) / 2
                    end
                else
                    local v = cam:WorldToViewportPoint(root.Position)
                    if v.Z <= 0 then
                        ok = false
                    else
                        cx, cy, w, h = v.X, v.Y, fixedW, fixedH
                    end
                end
            end

            if not ok then
                e.Root.Visible = false
                e.Tracer.Visible = false
            else
                w = math.floor(w + 0.5)
                h = math.floor(h + 0.5)
                local maxHp = math.max(hum.MaxHealth, 1)
                local frac = math.clamp(hum.Health / maxHp, 0, 1)
                if e.Char ~= char then
                    e.Char = char
                    e.Hp = frac
                end

                e.Root.Visible = true
                e.Root.Size = UDim2.fromOffset(w, h)
                e.Root.Position = UDim2.fromOffset(math.floor(cx + 0.5), math.floor(cy + 0.5))

                local boxAnim = F.BoxAnimate == true
                if boxOn and cornerStyle then
                    e.Outline.Visible = false
                    local len = math.max(6, math.floor(math.min(w, h) * 0.28))
                    local thick = math.max(1, math.floor((F.BoxThickness or 1.5) + 0.5))
                    for _, c in ipairs(e.Corners) do
                        c.Frame.Visible = true
                        if c.Horizontal then
                            c.Frame.Size = UDim2.fromOffset(len, thick)
                        else
                            c.Frame.Size = UDim2.fromOffset(thick, len)
                        end
                        useSeq(e, "Box", c.Grad, c.Slot)
                        c.Grad.Rotation = boxAnim and spin or 0
                    end
                elseif boxOn then
                    for _, c in ipairs(e.Corners) do
                        c.Frame.Visible = false
                    end
                    e.Outline.Visible = true
                    e.Stroke.Thickness = F.BoxThickness or 1.5
                    useSeq(e, "Box", e.StrokeGrad)
                    e.StrokeGrad.Rotation = boxAnim and spin or 0
                else
                    e.Outline.Visible = false
                    for _, c in ipairs(e.Corners) do
                        c.Frame.Visible = false
                    end
                end

                if fillOn then
                    e.FillColor.Visible = not imageMode
                    e.FillImg.Visible = imageMode
                    local ft = (F.FillTransparency or 50) / 100
                    if imageMode then
                        if e.Img ~= imageId then
                            e.Img = imageId
                            e.FillImg.Image = imageId
                        end
                        e.FillImg.ImageTransparency = ft
                        local fitMode = F.FillFit
                        if fitMode == "Crop" then
                            e.FillImg.ScaleType = Enum.ScaleType.Crop
                        elseif fitMode == "Fit" then
                            e.FillImg.ScaleType = Enum.ScaleType.Fit
                        else
                            e.FillImg.ScaleType = Enum.ScaleType.Stretch
                        end
                    else
                        e.FillColor.BackgroundTransparency = ft
                        useSeq(e, "Fill", e.FillGrad)
                        e.FillGrad.Rotation = (F.FillRotation or 90) + (F.FillAnimate == true and spin or 0)
                    end
                else
                    e.FillColor.Visible = false
                    e.FillImg.Visible = false
                end

                if hpOn then
                    local speed = F.HealthSpeed or 8
                    e.Hp = e.Hp + (frac - e.Hp) * (1 - math.exp(-dt * speed))
                    local right = F.HealthSide == "Right"
                    e.HpBack.Visible = true
                    e.HpBack.AnchorPoint = right and Vector2.new(0, 0) or Vector2.new(1, 0)
                    e.HpBack.Position = right and UDim2.new(1, 3, 0, 0) or UDim2.new(0, -3, 0, 0)
                    e.HpBack.Size = UDim2.new(0, F.HealthWidth or 4, 1, 0)
                    e.HpClip.Size = UDim2.new(1, 0, math.clamp(e.Hp, 0, 1), 0)
                    e.HpFull.Size = UDim2.new(1, 0, 0, h)
                    useSeq(e, "Hp", e.HpGrad)
                else
                    e.HpBack.Visible = false
                end

                local nameStr = ""
                if nameOn then
                    nameStr = nameText(plr, wantUser, wantDisplay)
                end
                local showName = nameStr ~= ""
                e.NameLabel.Visible = showName
                if showName then
                    e.NameLabel.Text = nameStr
                    e.NameLabel.TextSize = textSize
                    e.NameStroke.Thickness = F.NameStroke or 1
                    useSeq(e, "NameText", e.NameGrad)
                    useSeq(e, "NameStroke", e.NameStrokeGrad)
                    local nameAnim = F.NameAnimate == true and spin or 0
                    e.NameGrad.Rotation = nameAnim
                    e.NameStrokeGrad.Rotation = nameAnim
                end

                local infoStr = ""
                if infoOn then
                    local parts = {}
                    if F.InfoDistance == true then
                        table.insert(parts, math.floor(dist + 0.5) .. " st")
                    end
                    if F.InfoHealth == true then
                        table.insert(parts, math.floor(hum.Health) .. " HP")
                    end
                    if F.InfoTool == true then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then
                            table.insert(parts, tool.Name)
                        end
                    end
                    infoStr = table.concat(parts, "  |  ")
                end
                local showInfo = infoStr ~= ""
                e.InfoLabel.Visible = showInfo
                if showInfo then
                    e.InfoLabel.Text = infoStr
                    e.InfoLabel.TextSize = math.max(textSize - 2, 8)
                    useSeq(e, "Info", e.InfoGrad)
                    e.InfoGrad.Rotation = F.InfoAnimate == true and spin or 0
                end
                e.Tag.Visible = showName or showInfo

                if tracerOn then
                    local origin
                    local mode = F.TracerOrigin
                    if mode == "Top" then
                        origin = Vector2.new(vp.X / 2, 0)
                    elseif mode == "Center" then
                        origin = Vector2.new(vp.X / 2, vp.Y / 2)
                    elseif mode == "Mouse" then
                        origin = UserInputService:GetMouseLocation()
                    else
                        origin = Vector2.new(vp.X / 2, vp.Y)
                    end
                    local target = Vector2.new(cx, cy + h / 2)
                    local d = target - origin
                    local len = d.Magnitude
                    e.Tracer.Visible = len > 1
                    e.Tracer.Size = UDim2.fromOffset(len, F.TracerThickness or 1)
                    e.Tracer.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
                    e.Tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
                    e.Tracer.BackgroundTransparency = (F.TracerTransparency or 0) / 100
                    useSeq(e, "Tracer", e.TracerGrad)
                    e.TracerGrad.Offset = Vector2.new(F.TracerAnimate == true and sway or 0, 0)
                else
                    e.Tracer.Visible = false
                end
            end
        end
    end

    local function mkPart(shape, size, mat, transp, parent)
        return new("Part", {
            Shape = shape,
            Size = size,
            Material = mat,
            Transparency = transp,
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
            Parent = parent or selfFolder,
        })
    end

    local AURA_ASSET_IDS = {18515382827, 80960525975597, 112446670287992, 81561798538167, 85887901297813, 106192507657319}
    local auraStates = {}
    local auraLib = {Items = {}, Names = {}, State = "idle", Seeded = false}
    local auraDrop = nil

    local function clearAuraState(name)
        local s = auraStates[name]
        if s then
            destroyList(s.Objs)
            auraStates[name] = nil
        end
    end

    local function clearAuras()
        for name in pairs(auraStates) do
            clearAuraState(name)
        end
    end

    local function segLen(radius, count, arc)
        return (2 * math.pi * arc * radius / count) * 1.25
    end

    local function isFx(inst)
        return inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail")
    end

    local function hasFx(inst)
        if isFx(inst) then
            return true
        end
        for _, d in ipairs(inst:GetDescendants()) do
            if isFx(d) then
                return true
            end
        end
        return false
    end

    local function stripScripts(inst)
        local list = inst:GetDescendants()
        table.insert(list, inst)
        for _, d in ipairs(list) do
            if d:IsA("LuaSourceContainer") or d:IsA("Sound") then
                pcall(function()
                    d:Destroy()
                end)
            end
        end
    end

    local function fetchObjects(id)
        local objs = nil
        local ok, res = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)
        if ok and type(res) == "table" and #res > 0 then
            objs = res
        else
            local ok2, model = pcall(function()
                return game:GetService("InsertService"):LoadAsset(id)
            end)
            if ok2 and model then
                objs = {model}
            end
        end
        if not objs then
            return {}
        end
        for _, o in ipairs(objs) do
            stripScripts(o)
        end
        return objs
    end

    local function pickAuras(objs, st)
        local out = {}
        local genericNames = {
            dummy = true, rig = true, model = true, folder = true, character = true, aura = true,
            humanoid = true, noob = true, r6 = true, r15 = true, part = true, npc = true,
            handle = true, humanoidrootpart = true, meshpart = true, union = true, accessory = true, tool = true,
        }
        local function isGeneric(name)
            local lower = string.lower(name or "")
            return lower == "" or genericNames[lower] == true or lower:match("^dummy") ~= nil or lower:match("^rig") ~= nil
        end
        local function add(name, inst, topName)
            if isGeneric(name) and not isGeneric(topName) then
                name = topName
            end
            local final
            if isGeneric(name) then
                repeat
                    st.generic = st.generic + 1
                    final = "Aura " .. st.generic
                until not st.seen[final]
            else
                final = name
                local n = 1
                while st.seen[final] do
                    n = n + 1
                    final = name .. " " .. n
                end
            end
            st.seen[final] = true
            table.insert(out, {Name = final, Template = inst})
        end
        for _, top in ipairs(objs) do
            local node = top
            for _ = 1, 6 do
                local direct = false
                local kids = {}
                for _, k in ipairs(node:GetChildren()) do
                    if isFx(k) then
                        direct = true
                    elseif hasFx(k) then
                        table.insert(kids, k)
                    end
                end
                if direct or #kids == 0 then
                    add(node.Name, node, top.Name)
                    break
                end
                local descend = false
                if #kids == 1 and (kids[1]:IsA("Model") or kids[1]:IsA("Folder")) then
                    local inner = 0
                    local containers = true
                    for _, k in ipairs(kids[1]:GetChildren()) do
                        if hasFx(k) then
                            inner = inner + 1
                            if not (k:IsA("Model") or k:IsA("Folder")) then
                                containers = false
                            end
                        end
                    end
                    descend = inner >= 2 and containers
                end
                if descend then
                    node = kids[1]
                else
                    for _, k in ipairs(kids) do
                        add(k.Name, k, top.Name)
                    end
                    break
                end
            end
        end
        return out
    end

    local function loadAuras(force)
        if auraLib.State == "loading" or (auraLib.State == "ready" and not force) then
            return
        end
        auraLib.State = "loading"
        task.spawn(function()
            local results = {}
            local pending = #AURA_ASSET_IDS
            for i, id in ipairs(AURA_ASSET_IDS) do
                task.spawn(function()
                    results[i] = fetchObjects(id)
                    pending = pending - 1
                end)
            end
            local waited = 0
            while pending > 0 and waited < 200 do
                waited = waited + 1
                task.wait(0.1)
            end
            local st = {seen = {}, generic = 0}
            auraLib.Items = {}
            auraLib.Names = {}
            for i = 1, #AURA_ASSET_IDS do
                if results[i] then
                    for _, it in ipairs(pickAuras(results[i], st)) do
                        auraLib.Items[it.Name] = it.Template
                        table.insert(auraLib.Names, it.Name)
                    end
                end
            end
            auraLib.State = #auraLib.Names > 0 and "ready" or "failed"
            Library.AuraReady = true
            if auraDrop then
                auraDrop:Refresh(auraLib.Names)
                if not auraLib.Seeded and #auraLib.Names > 0 then
                    auraLib.Seeded = true
                    if type(F.AuraTypes) ~= "table" or #F.AuraTypes == 0 then
                        auraDrop:Set({auraLib.Names[1]}, true)
                    end
                end
            end
            if #auraLib.Names == 0 then
                Library:Notify({Title = "Aura", Content = "Could not load the aura assets", Duration = 3, Type = "Warning"})
            end
        end)
    end

    local bodyMap = {
        HumanoidRootPart = {"HumanoidRootPart"},
        Head = {"Head"},
        Torso = {"Torso", "UpperTorso"},
        UpperTorso = {"UpperTorso", "Torso"},
        LowerTorso = {"LowerTorso", "Torso"},
        ["Left Arm"] = {"Left Arm", "LeftUpperArm"},
        ["Right Arm"] = {"Right Arm", "RightUpperArm"},
        ["Left Leg"] = {"Left Leg", "LeftUpperLeg"},
        ["Right Leg"] = {"Right Leg", "RightUpperLeg"},
        LeftUpperArm = {"LeftUpperArm", "Left Arm"},
        LeftLowerArm = {"LeftLowerArm", "Left Arm"},
        LeftHand = {"LeftHand", "Left Arm"},
        RightUpperArm = {"RightUpperArm", "Right Arm"},
        RightLowerArm = {"RightLowerArm", "Right Arm"},
        RightHand = {"RightHand", "Right Arm"},
        LeftUpperLeg = {"LeftUpperLeg", "Left Leg"},
        LeftLowerLeg = {"LeftLowerLeg", "Left Leg"},
        LeftFoot = {"LeftFoot", "Left Leg"},
        RightUpperLeg = {"RightUpperLeg", "Right Leg"},
        RightLowerLeg = {"RightLowerLeg", "Right Leg"},
        RightFoot = {"RightFoot", "Right Leg"},
    }

    local function isBodyName(inst)
        return inst:IsA("BasePart") and bodyMap[inst.Name] ~= nil
    end

    local function isRigContainer(inst)
        if not (inst:IsA("Model") or inst:IsA("Folder")) then
            return false
        end
        if inst:FindFirstChildWhichIsA("Humanoid") then
            return true
        end
        local n = 0
        for _, k in ipairs(inst:GetChildren()) do
            if isBodyName(k) then
                n = n + 1
            end
        end
        return n >= 3
    end

    local function mapBodyPart(char, root, name)
        local cands = bodyMap[name]
        if cands then
            for _, c in ipairs(cands) do
                local p = char:FindFirstChild(c)
                if p and p:IsA("BasePart") then
                    return p
                end
            end
        end
        return root
    end

    local function mountEffects(template, ctx)
        local s = {Objs = {}, Parts = {}, Offset = ctx.offset or CFrame.new()}
        if template:IsA("Accessory") and ctx.dropAccessories then
            return s
        end
        local clone = template:Clone()
        local model = clone
        if not clone:IsA("Model") then
            model = new("Model", {})
            if clone:IsA("Folder") then
                for _, k in ipairs(clone:GetChildren()) do
                    k.Parent = model
                end
                clone:Destroy()
            else
                clone.Parent = model
            end
        end
        if ctx.dropAccessories then
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("Accessory") then
                    d:Destroy()
                end
            end
        end
        model.Name = HttpService:GenerateGUID(false)
        model.Parent = selfFolder
        table.insert(s.Objs, model)
        local anchor = new("Part", {
            Name = HttpService:GenerateGUID(false),
            Size = Vector3.new(0.2, 0.2, 0.2),
            Transparency = 1,
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
            Parent = selfFolder,
        })
        s.Anchor = anchor
        table.insert(s.Objs, anchor)
        if math.abs(ctx.size - 1) > 0.001 then
            pcall(function()
                model:ScaleTo(ctx.size)
            end)
        end
        local pivotCF = model:GetPivot()
        local rigs = {}
        if isRigContainer(model) then
            table.insert(rigs, model)
        end
        for _, d in ipairs(model:GetDescendants()) do
            if isRigContainer(d) then
                table.insert(rigs, d)
            end
        end
        local needed = {}
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Beam") or d:IsA("Trail") then
                if d.Attachment0 then
                    needed[d.Attachment0] = true
                end
                if d.Attachment1 then
                    needed[d.Attachment1] = true
                end
            end
        end
        local refCF = nil
        for _, rig in ipairs(rigs) do
            if not refCF then
                local rr = rig:FindFirstChild("HumanoidRootPart") or rig:FindFirstChild("Torso") or rig:FindFirstChild("UpperTorso")
                if rr and rr:IsA("BasePart") then
                    refCF = rr.CFrame
                end
            end
        end
        refCF = refCF or pivotCF
        local moved = {}
        local keepAcc = {
            [Enum.AccessoryType.Back] = true,
            [Enum.AccessoryType.Waist] = true,
            [Enum.AccessoryType.Shoulder] = true,
            [Enum.AccessoryType.Front] = true,
            [Enum.AccessoryType.Unknown] = true,
        }
        local bodyParts = {}
        for _, d in ipairs(model:GetDescendants()) do
            if isBodyName(d) then
                table.insert(bodyParts, d)
            end
        end
        for _, bp in ipairs(bodyParts) do
            local target = mapBodyPart(ctx.char, ctx.root, bp.Name)
            for _, c in ipairs(bp:GetDescendants()) do
                local keep = isFx(c) or c:IsA("Light") or c:IsA("Fire") or c:IsA("Smoke") or c:IsA("Sparkles")
                if not keep and c:IsA("Attachment") then
                    keep = needed[c] == true or hasFx(c)
                end
                if keep and not c:IsDescendantOf(target) then
                    local holder = c.Parent
                    if holder == bp or not (holder and holder:IsA("Attachment")) then
                        c.Parent = target
                        table.insert(moved, c)
                        table.insert(s.Objs, c)
                    end
                end
            end
        end
        for _, bp in ipairs(bodyParts) do
            if bp.Parent then
                bp:Destroy()
            end
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Humanoid") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic")
                or d:IsA("BodyColors") or d:IsA("CharacterMesh") or d:IsA("Animator")
                or d:IsA("HumanoidDescription") or (d:IsA("Decal") and d.Name == "face") then
                d:Destroy()
            end
        end
        for _, rig in ipairs(rigs) do
            if rig.Parent then
                for _, c in ipairs(rig:GetChildren()) do
                    if c:IsA("Accessory") and not (hasFx(c) or keepAcc[c.AccessoryType]) then
                        c:Destroy()
                    end
                end
            end
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Attachment") and not d.Parent:IsA("BasePart") then
                d.Parent = anchor
            elseif (isFx(d) or d:IsA("Light") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles"))
                and not (d.Parent:IsA("BasePart") or d.Parent:IsA("Attachment")) then
                d.Parent = anchor
            end
        end
        local parts = {}
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                table.insert(parts, d)
            end
        end
        for _, p in ipairs(parts) do
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            table.insert(s.Parts, {Part = p, Off = refCF:ToObjectSpace(p.CFrame)})
        end
        if #parts == 0 then
            model:Destroy()
        end
        if ctx.useColor then
            local seq = seq3(ctx.c1, ctx.c2, ctx.c3)
            local function paint(node)
                if isFx(node) then
                    node.Color = seq
                end
                for _, d in ipairs(node:GetDescendants()) do
                    if isFx(d) then
                        d.Color = seq
                    end
                end
            end
            paint(anchor)
            if model.Parent then
                paint(model)
            end
            for _, m in ipairs(moved) do
                paint(m)
            end
        end
        return s
    end

    local function followMount(s, base)
        local cf = base * s.Offset
        if s.Anchor then
            s.Anchor.CFrame = cf
        end
        for _, e in ipairs(s.Parts) do
            e.Part.CFrame = cf * e.Off
        end
    end

    local function auraStep(char, root, hum, t)
        local sel = F.AuraTypes
        if F.AuraEnabled ~= true or not root or type(sel) ~= "table" then
            clearAuras()
            return
        end
        local useColor = F.AuraCustomColor == true
        local ctx = {
            char = char,
            root = root,
            hum = hum,
            size = (F.AuraSize or 100) / 100,
            useColor = useColor,
            c1 = col("AuraColor1"),
            c2 = col("AuraColor2"),
            c3 = col("AuraColor3"),
        }
        local sig
        if useColor then
            sig = join(ctx.size, true, ctx.c1, ctx.c2, ctx.c3)
        else
            sig = join(ctx.size, false)
        end
        local want = {}
        for _, name in ipairs(sel) do
            want[name] = true
        end
        for name in pairs(auraStates) do
            if not want[name] then
                clearAuraState(name)
            end
        end
        local base = root.CFrame * CFrame.new(0, (F.AuraHeight or 0) / 10, 0)
        for name in pairs(want) do
            local template = auraLib.Items[name]
            if template then
                local s = auraStates[name]
                local stale = s ~= nil and (s.Sig ~= sig or s.Root ~= root)
                if not s or (stale and (s.Root ~= root or t - s.BuiltAt > 0.3)) then
                    clearAuraState(name)
                    s = mountEffects(template, ctx)
                    s.Sig = sig
                    s.Root = root
                    s.BuiltAt = t
                    auraStates[name] = s
                end
                followMount(s, base)
            end
        end
    end

    local wingAssets = {}
    local wings = {Mounts = {}, Objs = {}, Anims = {}, Root = nil, Sig = "", Warned = false}

    local function requestAsset(id)
        local e = wingAssets[id]
        if e then
            return e
        end
        e = {State = "loading", List = {}}
        wingAssets[id] = e
        task.spawn(function()
            local list = fetchObjects(id)
            e.List = list
            e.State = #list > 0 and "ready" or "failed"
        end)
        return e
    end

    local function clearWings()
        for _, info in ipairs(wings.Anims) do
            for _, tr in ipairs(info.Tracks) do
                pcall(function()
                    tr:Stop()
                end)
            end
        end
        destroyList(wings.Objs)
        for _, m in ipairs(wings.Mounts) do
            destroyList(m.Objs)
        end
        wings.Objs = {}
        wings.Mounts = {}
        wings.Anims = {}
        wings.Root = nil
        wings.Sig = ""
    end

    local function setupWingAnim(acc)
        local info = {Joints = {}, Tracks = {}, Speed = 0, Ready = false}
        local byPart = {}
        for _, d in ipairs(acc:GetDescendants()) do
            if d:IsA("Motor6D") and d.Name ~= "AccessoryWeld" and d.Part0 and d.Part1 then
                local j = {Joint = d, C0 = d.C0, Depth = 0, Side = 1}
                table.insert(info.Joints, j)
                byPart[d.Part1] = j
            end
        end
        for _, j in ipairs(info.Joints) do
            local depth = 0
            local cur = byPart[j.Joint.Part0]
            local guard = 0
            while cur and guard < 12 do
                depth = depth + 1
                guard = guard + 1
                cur = byPart[cur.Joint.Part0]
            end
            j.Depth = depth
        end
        return info
    end

    local function wearAccessories(template, ctx)
        local list = {}
        if template:IsA("Accessory") then
            table.insert(list, template)
        else
            for _, d in ipairs(template:GetDescendants()) do
                if d:IsA("Accessory") then
                    table.insert(list, d)
                end
            end
        end
        local skip = {
            [Enum.AccessoryType.Hat] = true,
            [Enum.AccessoryType.Hair] = true,
            [Enum.AccessoryType.Face] = true,
            [Enum.AccessoryType.Eyebrow] = true,
            [Enum.AccessoryType.Eyelash] = true,
            [Enum.AccessoryType.Neck] = true,
        }
        local count = 0
        for _, a in ipairs(list) do
            if not skip[a.AccessoryType] or hasFx(a) then
                local c = a:Clone()
                local ok = pcall(function()
                    ctx.hum:AddAccessory(c)
                end)
                if ok then
                    table.insert(wings.Objs, c)
                    table.insert(wings.Anims, setupWingAnim(c))
                    count = count + 1
                else
                    c:Destroy()
                end
            end
        end
        return count
    end

    local function buildWingSet(list, ctx, offset)
        for _, tmpl in ipairs(list) do
            local worn = wearAccessories(tmpl, ctx)
            ctx.dropAccessories = worn > 0
            ctx.offset = offset
            table.insert(wings.Mounts, mountEffects(tmpl, ctx))
        end
    end

    local function wingsStep(char, root, t)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if F.WingsEnabled ~= true or not char or not root or not hum then
            if wings.Root ~= nil or #wings.Objs > 0 or #wings.Mounts > 0 then
                clearWings()
            end
            return
        end
        local useAura = F.WingAura ~= false
        local body = requestAsset(7221933071)
        local fx = useAura and requestAsset(85253207361245) or nil
        if body.State == "loading" or (fx and fx.State == "loading") then
            return
        end
        if body.State == "failed" and not wings.Warned then
            wings.Warned = true
            Library:Notify({Title = "Angel Wings", Content = "Could not load the wings asset", Duration = 3, Type = "Warning"})
        end
        local sig = join(useAura)
        if wings.Root ~= root or wings.Sig ~= sig then
            clearWings()
            wings.Root = root
            wings.Sig = sig
            local ctx = {char = char, root = root, hum = hum, size = 1, useColor = false}
            buildWingSet(body.List, ctx, CFrame.new(0, 0.5, 0.55))
            if fx then
                buildWingSet(fx.List, ctx, CFrame.new())
            end
        end
        local base = root.CFrame
        for _, m in ipairs(wings.Mounts) do
            followMount(m, base)
        end
        local rate = (F.WingSpeed or 60) / 10
        local amp = math.rad(F.WingAmount or 25)
        local dt = math.clamp(t - (wings.LastT or t), 0, 0.1)
        wings.LastT = t
        local alpha = 1 - math.exp(-dt * 22)
        local look = root.CFrame.LookVector
        for _, info in ipairs(wings.Anims) do
            for _, j in ipairs(info.Joints) do
                local joint = j.Joint
                local p0, p1 = joint.Part0, joint.Part1
                if joint.Parent and p0 and p1 then
                    if not info.Ready then
                        local label = string.lower(joint.Name .. p1.Name)
                        local rel = root.CFrame:PointToObjectSpace(p1.Position).X
                        if math.abs(rel) > 0.08 then
                            j.Side = rel > 0 and 1 or -1
                        elseif label:find("left") then
                            j.Side = -1
                        elseif label:find("right") then
                            j.Side = 1
                        else
                            j.Side = 0
                        end
                    end
                    if j.Side ~= 0 then
                        local wave = math.sin(t * rate - j.Depth * 0.55)
                        local weight = j.Depth == 0 and 1 or 0.5
                        local axis = (p0.CFrame * j.C0):VectorToObjectSpace(look)
                        local target = j.C0 * CFrame.fromAxisAngle(axis, j.Side * wave * amp * weight)
                        joint.C0 = joint.C0:Lerp(target, alpha)
                    end
                end
            end
            info.Ready = true
        end
    end

    local hat = {Part = nil, Mesh = nil, Weld = nil, Light = nil, Head = nil}

    local function clearHat()
        if hat.Part then
            pcall(function()
                hat.Part:Destroy()
            end)
        end
        hat.Part = nil
        hat.Mesh = nil
        hat.Weld = nil
        hat.Light = nil
        hat.Head = nil
    end

    local hatMaterials = {
        Neon = Enum.Material.Neon,
        SmoothPlastic = Enum.Material.SmoothPlastic,
        Glass = Enum.Material.Glass,
        ForceField = Enum.Material.ForceField,
        Plastic = Enum.Material.Plastic,
    }

    local function buildHat(char, head)
        clearHat()
        local cone = Instance.new("Part")
        cone.Name = HttpService:GenerateGUID(false)
        cone.Size = Vector3.new(1, 1, 1)
        cone.Material = Enum.Material.Neon
        cone.Transparency = 0.2
        cone.Anchored = false
        cone.CanCollide = false
        cone.CanTouch = false
        cone.CanQuery = false
        cone.Massless = true
        cone.CastShadow = false
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://1033714"
        mesh.Scale = Vector3.new(1.7, 1.1, 1.7)
        mesh.Parent = cone
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = cone
        weld.C0 = CFrame.new(0, 0.9, 0)
        weld.Parent = cone
        local light = Instance.new("PointLight")
        light.Brightness = 0
        light.Range = 12
        light.Shadows = true
        light.Parent = cone
        cone.Parent = char
        hat.Part = cone
        hat.Mesh = mesh
        hat.Weld = weld
        hat.Light = light
        hat.Head = head
    end

    local function hatColorAt(mode, c1, c2, c3, t, speed)
        if mode == "Rainbow" then
            return Color3.fromHSV((t * speed * 0.2) % 1, 0.7, 1)
        elseif mode == "Cycle" then
            return cycle(c1, c2, c3, t * speed * 0.15)
        elseif mode == "Pulse" then
            return c1:Lerp(c2, (math.sin(t * speed * 0.6) + 1) / 2)
        elseif mode == "Gradient" then
            return sample(c1, c2, c3, (math.sin(t * speed * 0.4) + 1) / 2)
        end
        return c1
    end

    local function hatStep(char, t)
        local head = char and char:FindFirstChild("Head")
        if F.HatEnabled ~= true or not head then
            if hat.Part then
                clearHat()
            end
            return
        end
        if not hat.Part or not hat.Part.Parent or hat.Head ~= head or not hat.Part:IsDescendantOf(char) then
            buildHat(char, head)
        end
        local mode = F.HatColorMode or "Cycle"
        local speed = (F.HatColorSpeed or 30) / 30
        local c1, c2, c3 = col("HatColor1"), col("HatColor2"), col("HatColor3")
        local color = hatColorAt(mode, c1, c2, c3, t, speed)
        local part = hat.Part
        part.Color = color
        part.Material = hatMaterials[F.HatMaterial or "Neon"] or Enum.Material.Neon
        part.Transparency = (F.HatTransparency or 20) / 100
        local width = (F.HatWidth or 170) / 100
        local height = (F.HatHeight or 110) / 100
        local pulse = 1
        if F.HatPulseSize == true then
            pulse = 1 + math.sin(t * 3) * 0.06
        end
        hat.Mesh.Scale = Vector3.new(width * pulse, height, width * pulse)
        local bob = 0
        if F.HatBob == true then
            bob = math.sin(t * 2) * 0.08
        end
        local spin = t * (F.HatSpin or 0) / 30
        local tiltX = math.rad(F.HatTilt or 0)
        hat.Weld.C0 = CFrame.new(0, (F.HatOffset or 9) / 10 + bob, 0) * CFrame.Angles(tiltX, spin, 0)
        local light = hat.Light
        light.Brightness = (F.HatLightBrightness or 0) / 10
        light.Range = F.HatLightRange or 12
        light.Color = F.HatLightMatch ~= false and color or col("HatLightColor")
        light.Enabled = light.Brightness > 0
    end

    local halo = {Parts = {}, Sig = ""}

    local function clearHalo()
        destroyList(halo.Parts)
        halo.Parts = {}
        halo.Sig = ""
    end

    local function haloStep(char, t)
        local head = char and char:FindFirstChild("Head")
        if F.HaloEnabled ~= true or not head then
            if #halo.Parts > 0 then
                clearHalo()
            end
            return
        end
        local size = (F.HaloSize or 100) / 100
        local transp = (F.HaloTransparency or 10) / 100
        local segs = 40
        local radius = 1.2 * size
        local sig = join(size, transp)
        if sig ~= halo.Sig then
            clearHalo()
            halo.Sig = sig
            for _ = 1, segs do
                table.insert(halo.Parts, mkPart(Enum.PartType.Block, Vector3.new(segLen(radius, segs, 1), 0.12 * size, 0.12 * size), Enum.Material.Neon, transp))
            end
        end
        local c1, c2, c3 = col("HaloColor1"), col("HaloColor2"), col("HaloColor3")
        local speed = (F.HaloSpeed or 100) / 100
        local lift = (F.HaloHeight or 12) / 10
        local center = head.Position + Vector3.new(0, head.Size.Y / 2 + lift + math.sin(t * 1.6) * 0.08, 0)
        local ringCF = CFrame.new(center) * CFrame.Angles(math.sin(t * 1.1) * 0.06, t * speed * 0.8, math.cos(t * 0.9) * 0.06)
        local flowOn = F.HaloFlow ~= false
        for k, part in ipairs(halo.Parts) do
            local u = (k - 1) / segs
            local a = u * math.pi * 2
            part.CFrame = ringCF * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -a - math.pi / 2, 0)
            part.Color = flowOn and cycle(c1, c2, c3, u + t * 0.15) or sample(c1, c2, c3, u)
        end
    end

    local function selfStep()
        local t = os.clock()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and root and hum.Health > 0) then
            char = nil
            root = nil
        end
        local cam = workspace.CurrentCamera
        if cam and selfFolder.Parent ~= cam then
            selfFolder.Parent = cam
        end
        auraStep(char, root, hum, t)
        wingsStep(char, root, t)
        hatStep(char, t)
        haloStep(char, t)
    end

    local skyList = {"Sunset", "Dune Sky", "Dark Matter", "Minecraft", "Custom"}
    local skyIds = {
        ["Sunset"] = 82796424171704,
        ["Dune Sky"] = 138907351102721,
        ["Dark Matter"] = 110290405998332,
        ["Minecraft"] = 2758029221,
    }
    local faces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
    local skyObj = nil
    local skyToken = 0
    local skyCache = {}
    local hiddenSkies = {}

    local function currentSkyId()
        local sel = F.SkySelect
        if sel == "Custom" then
            return tostring(F.SkyCustomId or ""):match("%d+")
        end
        return skyIds[sel]
    end

    local function resolveSky(id)
        if skyCache[id] then
            return skyCache[id]
        end
        local result = nil
        local ok, objs = pcall(function()
            return game:GetObjects(asset(id))
        end)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                local sky = o:IsA("Sky") and o or o:FindFirstChildWhichIsA("Sky", true)
                if sky then
                    result = {Kind = "Sky", Sky = sky:Clone()}
                    break
                end
            end
            if not result then
                for _, o in ipairs(objs) do
                    local img = o:IsA("Decal") and o or o:FindFirstChildWhichIsA("Decal", true)
                    if img and img.Texture ~= "" then
                        result = {Kind = "Image", Image = img.Texture}
                        break
                    end
                end
            end
            for _, o in ipairs(objs) do
                pcall(function()
                    o:Destroy()
                end)
            end
        end
        if not result then
            result = {Kind = "Image", Image = asset(id)}
        end
        skyCache[id] = result
        return result
    end

    local function removeSky()
        skyToken = skyToken + 1
        if skyObj then
            skyObj:Destroy()
            skyObj = nil
        end
        for s in pairs(hiddenSkies) do
            pcall(function()
                s.Parent = Lighting
            end)
        end
        hiddenSkies = {}
    end

    local function applySky()
        skyToken = skyToken + 1
        local mine = skyToken
        local id = currentSkyId()
        if F.SkyEnabled ~= true or not id then
            removeSky()
            return
        end
        task.spawn(function()
            local res = resolveSky(id)
            if mine ~= skyToken then
                return
            end
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Sky") and c ~= skyObj then
                    hiddenSkies[c] = true
                    pcall(function()
                        c.Parent = nil
                    end)
                end
            end
            if skyObj then
                skyObj:Destroy()
                skyObj = nil
            end
            if res.Kind == "Sky" then
                skyObj = res.Sky:Clone()
            else
                skyObj = new("Sky", {})
                for _, face in ipairs(faces) do
                    skyObj[face] = res.Image
                end
            end
            skyObj.Name = HttpService:GenerateGUID(false)
            skyObj.StarCount = F.SkyStars or 3000
            skyObj.CelestialBodiesShown = F.SkySun ~= false
            skyObj.Parent = Lighting
        end)
    end

    connect(Lighting.ChildAdded, function(c)
        if F.SkyEnabled == true and c:IsA("Sky") and c ~= skyObj then
            hiddenSkies[c] = true
            task.defer(function()
                pcall(function()
                    c.Parent = nil
                end)
            end)
        end
    end)

    local skyDrop = nil
    local ContentProvider = game:GetService("ContentProvider")

    local function probeSky(id)
        local ok, objs = pcall(function()
            return game:GetObjects(asset(id))
        end)
        if not ok then
            return nil
        end
        local good = false
        if type(objs) == "table" then
            for _, o in ipairs(objs) do
                if o:IsA("Sky") or o:FindFirstChildWhichIsA("Sky", true) then
                    good = true
                elseif o:IsA("Decal") or o:IsA("Texture") or o:FindFirstChildWhichIsA("Decal", true) then
                    local img = o:IsA("Decal") and o or o:FindFirstChildWhichIsA("Decal", true)
                    if img and img.Texture ~= "" then
                        good = true
                    end
                end
            end
            for _, o in ipairs(objs) do
                pcall(function()
                    o:Destroy()
                end)
            end
        end
        if good then
            return true
        end
        local label = Instance.new("ImageLabel")
        label.Image = asset(id)
        local status = nil
        local loaded = pcall(function()
            ContentProvider:PreloadAsync({label}, function(_, s)
                status = s
            end)
        end)
        label:Destroy()
        if not loaded then
            return nil
        end
        return status == Enum.AssetFetchStatus.Success
    end

    local function pruneSkies()
        task.spawn(function()
            local keep = {}
            for _, name in ipairs(skyList) do
                if name ~= "Custom" and probeSky(skyIds[name]) ~= false then
                    table.insert(keep, name)
                end
            end
            table.insert(keep, "Custom")
            if #keep == #skyList or not skyDrop then
                return
            end
            skyList = keep
            skyDrop:Refresh(keep)
            if F.SkySelect == nil then
                skyDrop:Set(keep[1], true)
            end
            if F.SkyEnabled == true then
                applySky()
            end
        end)
    end

    local worldOrig = {}
    local function worldSet(prop, value, active)
        if active then
            if worldOrig[prop] == nil then
                worldOrig[prop] = Lighting[prop]
            end
            if Lighting[prop] ~= value then
                Lighting[prop] = value
            end
        elseif worldOrig[prop] ~= nil then
            Lighting[prop] = worldOrig[prop]
            worldOrig[prop] = nil
        end
    end

    local function worldStep()
        worldSet("ClockTime", F.TimeValue or 12, F.TimeLock == true)
        worldSet("Brightness", F.BrightnessValue or 2, F.BrightnessOn == true)
        worldSet("FogEnd", 1000000, F.NoFog == true)
        if F.SkyEnabled == true and skyObj and skyObj.Parent ~= Lighting then
            skyObj.Parent = Lighting
        end
    end

    local texPacks = {
        Minecraft = {
            Wood = "3258599312", WoodPlanks = "8676581022",
            Brick = "8558400252", Cobblestone = "5003953441",
            Concrete = "7341687607", DiamondPlate = "6849247561",
            Fabric = "118776397", Granite = "4722586771",
            Grass = "4722588177", Ice = "3823766459",
            Marble = "62967586", Metal = "62967586",
            Sand = "152572215",
        },
    }
    local texPackList = {"Minecraft"}
    local texFaces = {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Top, Enum.NormalId.Right, Enum.NormalId.Left}
    local tex = {Parts = {}, Token = 0, Conn = nil}

    local function texSkip(part)
        local cam = workspace.CurrentCamera
        if cam and part:IsDescendantOf(cam) then
            return true
        end
        local m = part.Parent
        while m and m ~= workspace do
            if m:FindFirstChildOfClass("Humanoid") then
                return true
            end
            m = m.Parent
        end
        return false
    end

    local function texApplyPart(part, map)
        if tex.Parts[part] or not part.Parent then
            return
        end
        local id = map[part.Material.Name]
        if not id or texSkip(part) then
            return
        end
        local tile = F.TexTile or 2
        local tint = F.TexTint ~= false
        local list = {}
        for _, face in ipairs(texFaces) do
            local t = Instance.new("Texture")
            t.Name = "PrestigeTexture"
            t.Texture = "rbxassetid://" .. id
            t.Face = face
            t.Color3 = tint and part.Color or Color3.new(1, 1, 1)
            t.Transparency = part.Transparency
            t.StudsPerTileU = tile
            t.StudsPerTileV = tile
            t.Parent = part
            table.insert(list, t)
        end
        tex.Parts[part] = {Orig = part.Material, List = list}
        part.Material = Enum.Material.SmoothPlastic
    end

    local function texRevert()
        tex.Token = tex.Token + 1
        if tex.Conn then
            tex.Conn:Disconnect()
            tex.Conn = nil
        end
        for part, e in pairs(tex.Parts) do
            for _, t in ipairs(e.List) do
                pcall(function()
                    t:Destroy()
                end)
            end
            if part.Parent then
                pcall(function()
                    part.Material = e.Orig
                end)
            end
        end
        tex.Parts = {}
    end

    local function texApply()
        texRevert()
        if F.TexEnabled ~= true then
            return
        end
        local map = texPacks[F.TexPack or "Minecraft"] or texPacks.Minecraft
        local mine = tex.Token
        tex.Conn = workspace.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then
                task.defer(function()
                    if mine == tex.Token and d.Parent then
                        pcall(texApplyPart, d, map)
                    end
                end)
            end
        end)
        task.spawn(function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if mine ~= tex.Token then
                    return
                end
                if d:IsA("BasePart") then
                    pcall(texApplyPart, d, map)
                    n = n + 1
                    if n % 250 == 0 then
                        task.wait()
                    end
                end
            end
        end)
    end

    local function texTile()
        local tile = F.TexTile or 2
        for _, e in pairs(tex.Parts) do
            for _, t in ipairs(e.List) do
                t.StudsPerTileU = tile
                t.StudsPerTileV = tile
            end
        end
    end

    local charState = {Id = nil, Busy = false}

    local function charResolve(text)
        local clean = string.gsub(tostring(text or ""), "%s+", "")
        if clean == "" then
            return nil
        end
        local n = tonumber(clean)
        if n and n > 0 then
            return math.floor(n)
        end
        local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, clean)
        if ok and type(id) == "number" then
            return id
        end
        return nil
    end

    local function charWeld(char, acc)
        local hum = char:FindFirstChildOfClass("Humanoid")
        local ok = false
        if hum then
            ok = pcall(function()
                hum:AddAccessory(acc)
            end)
        end
        if ok then
            return
        end
        local handle = acc:FindFirstChild("Handle")
        if not handle then
            acc:Destroy()
            return
        end
        local attName = nil
        for _, child in ipairs(handle:GetChildren()) do
            if child:IsA("Attachment") then
                attName = child.Name
                break
            end
        end
        acc.Parent = char
        if not attName then
            return
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("Attachment") and part.Name == attName and part.Parent ~= handle then
                for _, w in ipairs(handle:GetChildren()) do
                    if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("Motor6D") then
                        w:Destroy()
                    end
                end
                local weld = Instance.new("Weld")
                weld.Name = "AccessoryWeld"
                weld.Part0 = part.Parent
                weld.Part1 = handle
                weld.C0 = part.CFrame
                local handleAtt = handle:FindFirstChild(attName)
                weld.C1 = handleAtt and handleAtt.CFrame or CFrame.new()
                weld.Parent = handle
                return
            end
        end
    end

    local function charApply(userId)
        if charState.Busy then
            return false
        end
        local char = LocalPlayer.Character
        if not char or not char.Parent then
            Library:Notify({Title = "Char", Content = "No character to change", Duration = 3, Type = "Warning"})
            return false
        end
        charState.Busy = true
        local ok, appearance = pcall(Players.GetCharacterAppearanceAsync, Players, userId)
        if not ok or not appearance then
            charState.Busy = false
            Library:Notify({Title = "Char", Content = "Could not load that user's avatar", Duration = 3, Type = "Warning"})
            return false
        end
        if LocalPlayer.Character ~= char or not char.Parent then
            appearance:Destroy()
            charState.Busy = false
            return false
        end
        local keep = {}
        for _, o in ipairs(wings.Objs) do
            keep[o] = true
        end
        for _, v in ipairs(char:GetChildren()) do
            if (v:IsA("Accessory") and not keep[v]) or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                v:Destroy()
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            for _, d in ipairs(head:GetChildren()) do
                if d:IsA("Decal") then
                    d:Destroy()
                end
            end
        end
        local srcBC = appearance:FindFirstChildOfClass("BodyColors")
        if srcBC then
            local dstBC = char:FindFirstChildOfClass("BodyColors")
            if not dstBC then
                dstBC = Instance.new("BodyColors")
                dstBC.Parent = char
            end
            dstBC.HeadColor3 = srcBC.HeadColor3
            dstBC.TorsoColor3 = srcBC.TorsoColor3
            dstBC.LeftArmColor3 = srcBC.LeftArmColor3
            dstBC.RightArmColor3 = srcBC.RightArmColor3
            dstBC.LeftLegColor3 = srcBC.LeftLegColor3
            dstBC.RightLegColor3 = srcBC.RightLegColor3
        end
        for _, v in ipairs(appearance:GetChildren()) do
            if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                v:Clone().Parent = char
            end
        end
        if head then
            local srcFace = appearance:FindFirstChild("face", true)
            if srcFace and srcFace:IsA("Decal") then
                local existing = head:FindFirstChild("face")
                if existing then
                    existing:Destroy()
                end
                srcFace:Clone().Parent = head
            end
        end
        for _, v in ipairs(appearance:GetChildren()) do
            if v:IsA("Accessory") and v:FindFirstChild("Handle") then
                charWeld(char, v:Clone())
            end
        end
        appearance:Destroy()
        charState.Id = userId
        charState.Busy = false
        Library:Notify({Title = "Char", Content = "Applied avatar " .. tostring(userId), Duration = 3, Type = "Success"})
        return true
    end

    connect(LocalPlayer.CharacterAdded, function(char)
        if F.CharAuto == false or not charState.Id then
            return
        end
        task.wait(1)
        if LocalPlayer.Character == char then
            task.spawn(charApply, charState.Id)
        end
    end)

    connect(RunService.RenderStepped, function(dt)
        pcall(espStep, dt)
        pcall(selfStep)
        pcall(worldStep)
    end)

    onUnload(function()
        for plr in pairs(esp) do
            removePlayer(plr)
        end
        clearAuras()
        clearWings()
        clearHat()
        clearHalo()
        removeSky()
        texRevert()
        for prop, value in pairs(worldOrig) do
            pcall(function()
                Lighting[prop] = value
            end)
        end
        selfFolder:Destroy()
        chamFolder:Destroy()
        espGui:Destroy()
    end)

    local function grad(section, label, flag, a, b, c)
        return section:AddGradient({Name = label, Flag = flag, Defaults = {a, b, c}})
    end

    local P = Color3.fromRGB(150, 60, 255)
    local B = Color3.fromRGB(50, 120, 255)
    local K = Color3.new(0, 0, 0)
    local W = Color3.new(1, 1, 1)

    local pe = visualsTab:AddSubTab("Player ESP")

    local gen = pe:AddSection("General", "Left")
    gen:AddToggle({Name = "Enable ESP", Flag = "ESPEnabled", Default = false, Keybind = true, Hud = true})
    gen:AddToggle({Name = "Show Self", Flag = "ESPSelf", Default = false})
    gen:AddToggle({Name = "Hide Teammates", Flag = "ESPTeam", Default = false})
    local sizeMode = gen:AddDropdown({Name = "Box Size", Flag = "ESPSizeMode", Options = {"Fit Character", "Fixed"}, Default = "Fit Character"})
    local fitG = gen:AddGroup(sizeMode, function(v)
        return v ~= "Fixed"
    end)
    fitG:AddSlider({Name = "Box Padding", Flag = "ESPPad", Min = 0, Max = 30, Default = 8})
    fitG:AddSlider({Name = "Box Width", Flag = "ESPRatio", Min = 30, Max = 100, Default = 52})
    fitG:AddSlider({Name = "Minimum Height", Flag = "ESPMinH", Min = 10, Max = 60, Default = 16, Suffix = "px"})
    local fixedG = gen:AddGroup(sizeMode, function(v)
        return v == "Fixed"
    end)
    fixedG:AddSlider({Name = "ESP Width", Flag = "ESPWidth", Min = 30, Max = 140, Default = 64, Suffix = "px"})
    fixedG:AddSlider({Name = "ESP Height", Flag = "ESPHeight", Min = 40, Max = 220, Default = 96, Suffix = "px"})
    gen:AddSlider({Name = "Max Distance", Flag = "ESPDistance", Min = 100, Max = 5000, Default = 2500, Increment = 50, Suffix = " st"})
    gen:AddSlider({Name = "Text Size", Flag = "ESPTextSize", Min = 9, Max = 22, Default = 13, Suffix = "px"})
    gen:AddSlider({Name = "Gradient Speed", Flag = "ESPGradSpeed", Min = 10, Max = 360, Default = 60, Suffix = "°/s"})

    local box = pe:AddSection("Box", "Left")
    local boxT = box:AddToggle({Name = "Box ESP", Flag = "BoxEnabled", Default = true, Keybind = true, Hud = true})
    local boxG = box:AddGroup(boxT)
    boxG:AddDropdown({Name = "Style", Flag = "BoxStyle", Options = {"Full", "Corners"}, Default = "Full"})
    grad(boxG, "Gradient", "BoxColor", K, W, K)
    boxG:AddSlider({Name = "Thickness", Flag = "BoxThickness", Min = 1, Max = 4, Default = 1.5, Increment = 0.5, Suffix = "px"})
    boxG:AddToggle({Name = "Animate Gradient", Flag = "BoxAnimate", Default = true})

    local tag = pe:AddSection("Nametag", "Left")
    local tagT = tag:AddToggle({Name = "Nametag", Flag = "NameEnabled", Default = true, Keybind = true, Hud = true})
    local tagG = tag:AddGroup(tagT)
    tagG:AddDropdown({Name = "Show", Flag = "NameMode", Multi = true, Options = {"Username", "Display"}, Default = {"Display"}})
    grad(tagG, "Text Gradient", "NameText", W, W, W)
    grad(tagG, "Outline Gradient", "NameOut", K, W, K)
    tagG:AddSlider({Name = "Outline Thickness", Flag = "NameStroke", Min = 1, Max = 3, Default = 1, Increment = 0.5, Suffix = "px"})
    tagG:AddToggle({Name = "Animate Gradient", Flag = "NameAnimate", Default = false})

    local info = pe:AddSection("Info Text", "Left")
    local infoT = info:AddToggle({Name = "Info Text", Flag = "InfoEnabled", Default = false, Keybind = true, Hud = true})
    local infoG = info:AddGroup(infoT)
    infoG:AddToggle({Name = "Distance", Flag = "InfoDistance", Default = true})
    infoG:AddToggle({Name = "Health", Flag = "InfoHealth", Default = false})
    infoG:AddToggle({Name = "Held Tool", Flag = "InfoTool", Default = false})
    grad(infoG, "Text Gradient", "InfoColor", Color3.fromRGB(190, 190, 205), W, Color3.fromRGB(190, 190, 205))
    infoG:AddToggle({Name = "Animate Gradient", Flag = "InfoAnimate", Default = false})

    local fill = pe:AddSection("Fill", "Right")
    local fillT = fill:AddToggle({Name = "Box Fill", Flag = "FillEnabled", Default = false, Keybind = true, Hud = true})
    local fillG = fill:AddGroup(fillT)
    local fillType = fillG:AddDropdown({Name = "Fill Type", Flag = "FillType", Options = {"Color", "Image"}, Default = "Color"})
    local fillColors = fillG:AddGroup(fillType, function(v)
        return v == "Color"
    end)
    grad(fillColors, "Gradient", "FillColor", P, B, Color3.fromRGB(10, 10, 16))
    fillColors:AddSlider({Name = "Gradient Angle", Flag = "FillRotation", Min = 0, Max = 360, Default = 90, Suffix = "°"})
    fillColors:AddToggle({Name = "Animate Gradient", Flag = "FillAnimate", Default = false})
    local fillImgs = fillG:AddGroup(fillType, function(v)
        return v == "Image"
    end)
    fillImgs:AddDropdown({Name = "Image", Flag = "FillImage", Options = {"Crying Angel", "Baby Angel", "Stick Man Angel", "Custom"}, Default = "Crying Angel"})
    fillImgs:AddTextbox({Name = "Custom Image ID", Flag = "FillCustomId", Placeholder = "asset id"})
    fillImgs:AddDropdown({Name = "Image Fit", Flag = "FillFit", Options = {"Stretch", "Crop", "Fit"}, Default = "Stretch"})
    fillG:AddSlider({Name = "Transparency", Flag = "FillTransparency", Min = 0, Max = 100, Default = 50})

    local hp = pe:AddSection("Health Bar", "Right")
    local hpT = hp:AddToggle({Name = "Health Bar", Flag = "HealthEnabled", Default = true, Keybind = true, Hud = true})
    local hpG = hp:AddGroup(hpT)
    grad(hpG, "Gradient (Top > Bottom)", "HpColor", P, B, K)
    hpG:AddDropdown({Name = "Side", Flag = "HealthSide", Options = {"Left", "Right"}, Default = "Left"})
    hpG:AddSlider({Name = "Bar Width", Flag = "HealthWidth", Min = 2, Max = 8, Default = 4, Suffix = "px"})
    hpG:AddSlider({Name = "Animation Speed", Flag = "HealthSpeed", Min = 1, Max = 20, Default = 8, Suffix = ""})

    local tr = pe:AddSection("Tracers", "Right")
    local trT = tr:AddToggle({Name = "Tracers", Flag = "TracerEnabled", Default = false, Keybind = true, Hud = true})
    local trG = tr:AddGroup(trT)
    grad(trG, "Gradient", "TracerColor", W, B, P)
    trG:AddDropdown({Name = "Origin", Flag = "TracerOrigin", Options = {"Bottom", "Center", "Top", "Mouse"}, Default = "Bottom"})
    trG:AddSlider({Name = "Thickness", Flag = "TracerThickness", Min = 1, Max = 4, Default = 1, Increment = 0.5, Suffix = "px"})
    trG:AddSlider({Name = "Transparency", Flag = "TracerTransparency", Min = 0, Max = 90, Default = 10})
    trG:AddToggle({Name = "Animate Gradient", Flag = "TracerAnimate", Default = true})

    local ch = pe:AddSection("Chams", "Right")
    local chT = ch:AddToggle({Name = "Chams", Flag = "ChamsEnabled", Default = false, Keybind = true, Hud = true})
    local chG = ch:AddGroup(chT)
    grad(chG, "Fill Gradient", "ChamsFill", P, B, W)
    grad(chG, "Outline Gradient", "ChamsOutline", W, B, P)
    chG:AddToggle({Name = "Cycle Gradient", Flag = "ChamsCycle", Default = true})
    chG:AddSlider({Name = "Cycle Speed", Flag = "ChamsSpeed", Min = 5, Max = 100, Default = 30})
    chG:AddSlider({Name = "Fill Transparency", Flag = "ChamsFillTransparency", Min = 0, Max = 100, Default = 60})
    chG:AddSlider({Name = "Outline Transparency", Flag = "ChamsOutlineTransparency", Min = 0, Max = 100, Default = 0})
    chG:AddToggle({Name = "Visible Only", Flag = "ChamsVisible", Default = false})

    local se = visualsTab:AddSubTab("Self ESP")

    local au = se:AddSection("Aura", "Left")
    local auT = au:AddToggle({Name = "Aura", Flag = "AuraEnabled", Default = false, Keybind = true, Hud = true})
    local auG = au:AddGroup(auT)
    auraDrop = auG:AddDropdown({Name = "Auras", Flag = "AuraTypes", Multi = true, Options = {}, Default = {}})
    auG:AddSlider({Name = "Size", Flag = "AuraSize", Min = 30, Max = 300, Default = 100})
    auG:AddSlider({Name = "Height Offset", Flag = "AuraHeight", Min = -30, Max = 30, Default = 0, Suffix = ""})
    auG:AddToggle({Name = "Custom Color", Flag = "AuraCustomColor", Default = false})
    grad(auG, "Gradient", "AuraColor", P, B, W)
    auG:AddButton({Name = "Reload Auras", Callback = function()
        loadAuras(true)
    end})
    loadAuras()

    local aw = se:AddSection("Angel Wings", "Left")
    local awT = aw:AddToggle({Name = "Angel Wings", Flag = "WingsEnabled", Default = false, Keybind = true, Hud = true})
    local awG = aw:AddGroup(awT)
    awG:AddToggle({Name = "Wing Aura", Flag = "WingAura", Default = true})
    awG:AddSlider({Name = "Flap Speed", Flag = "WingSpeed", Min = 10, Max = 200, Default = 60, Suffix = ""})
    awG:AddSlider({Name = "Flap Amount", Flag = "WingAmount", Min = 0, Max = 60, Default = 25, Suffix = "°"})

    local ha = se:AddSection("Halo", "Left")
    local haT = ha:AddToggle({Name = "Halo", Flag = "HaloEnabled", Default = false, Keybind = true, Hud = true})
    local haG = ha:AddGroup(haT)
    grad(haG, "Gradient", "HaloColor", Color3.fromRGB(255, 240, 170), W, Color3.fromRGB(255, 200, 90))
    haG:AddToggle({Name = "Flow Colors", Flag = "HaloFlow", Default = true})
    haG:AddSlider({Name = "Size", Flag = "HaloSize", Min = 50, Max = 200, Default = 100})
    haG:AddSlider({Name = "Speed", Flag = "HaloSpeed", Min = 0, Max = 300, Default = 100})
    haG:AddSlider({Name = "Height", Flag = "HaloHeight", Min = 0, Max = 40, Default = 12, Suffix = ""})
    haG:AddSlider({Name = "Transparency", Flag = "HaloTransparency", Min = 0, Max = 95, Default = 10})

    local hatS = se:AddSection("China Hat", "Right")
    local hatT = hatS:AddToggle({Name = "China Hat", Flag = "HatEnabled", Default = false, Keybind = true, Hud = true})
    local hatG = hatS:AddGroup(hatT)
    hatG:AddDropdown({Name = "Color Mode", Flag = "HatColorMode", Options = {"Solid", "Cycle", "Rainbow", "Pulse", "Gradient"}, Default = "Cycle"})
    grad(hatG, "Colors", "HatColor", Color3.fromRGB(255, 105, 180), P, B)
    hatG:AddSlider({Name = "Color Speed", Flag = "HatColorSpeed", Min = 1, Max = 100, Default = 30, Suffix = ""})
    hatG:AddDropdown({Name = "Material", Flag = "HatMaterial", Options = {"Neon", "SmoothPlastic", "Plastic", "Glass", "ForceField"}, Default = "Neon"})
    hatG:AddSlider({Name = "Transparency", Flag = "HatTransparency", Min = 0, Max = 95, Default = 20})
    hatG:AddSlider({Name = "Width", Flag = "HatWidth", Min = 50, Max = 400, Default = 170})
    hatG:AddSlider({Name = "Height", Flag = "HatHeight", Min = 30, Max = 400, Default = 110})
    hatG:AddSlider({Name = "Height Offset", Flag = "HatOffset", Min = -20, Max = 30, Default = 9, Suffix = ""})
    hatG:AddSlider({Name = "Tilt", Flag = "HatTilt", Min = -45, Max = 45, Default = 0, Suffix = "°"})
    hatG:AddSlider({Name = "Spin Speed", Flag = "HatSpin", Min = 0, Max = 300, Default = 0, Suffix = ""})
    hatG:AddToggle({Name = "Bobbing", Flag = "HatBob", Default = false})
    hatG:AddToggle({Name = "Pulse Size", Flag = "HatPulseSize", Default = false})
    hatG:AddSlider({Name = "Light Brightness", Flag = "HatLightBrightness", Min = 0, Max = 100, Default = 0, Suffix = ""})
    hatG:AddSlider({Name = "Light Range", Flag = "HatLightRange", Min = 4, Max = 60, Default = 12, Suffix = ""})
    local lightMatch = hatG:AddToggle({Name = "Light Matches Hat", Flag = "HatLightMatch", Default = true})
    local lightG = hatG:AddGroup(lightMatch, function(v)
        return v ~= true
    end)
    lightG:AddColorPicker({Name = "Light Color", Flag = "HatLightColor", Default = Color3.fromRGB(255, 105, 180)})

    local wo = visualsTab:AddSubTab("World")

    local sk = wo:AddSection("Sky", "Left")
    local skT = sk:AddToggle({Name = "Custom Sky", Flag = "SkyEnabled", Default = false, Keybind = true, Hud = true, Callback = applySky})
    local skG = sk:AddGroup(skT)
    skyDrop = skG:AddDropdown({Name = "Sky", Flag = "SkySelect", Options = skyList, Default = "Sunset", Callback = applySky})
    skG:AddTextbox({Name = "Custom Sky ID", Flag = "SkyCustomId", Placeholder = "asset id", Callback = applySky})
    skG:AddSlider({Name = "Stars", Flag = "SkyStars", Min = 0, Max = 5000, Default = 3000, Increment = 100, Suffix = "", Callback = applySky})
    skG:AddToggle({Name = "Sun And Moon", Flag = "SkySun", Default = true, Callback = applySky})
    pruneSkies()

    local li = wo:AddSection("Lighting", "Right")
    local tlT = li:AddToggle({Name = "Time Lock", Flag = "TimeLock", Default = false, Keybind = true, Hud = true})
    local tlG = li:AddGroup(tlT)
    tlG:AddSlider({Name = "Clock Time", Flag = "TimeValue", Min = 0, Max = 24, Default = 12, Increment = 0.5, Suffix = "h"})
    local brT = li:AddToggle({Name = "Brightness Override", Flag = "BrightnessOn", Default = false, Keybind = true, Hud = true})
    local brG = li:AddGroup(brT)
    brG:AddSlider({Name = "Brightness", Flag = "BrightnessValue", Min = 0, Max = 10, Default = 2, Increment = 0.5, Suffix = ""})
    li:AddToggle({Name = "Remove Fog", Flag = "NoFog", Default = false, Keybind = true, Hud = true})

    local tp = wo:AddSection("Texture Packs", "Left")
    local tpT = tp:AddToggle({Name = "Texture Pack", Flag = "TexEnabled", Default = false, Keybind = true, Hud = true, Callback = texApply})
    local tpG = tp:AddGroup(tpT)
    tpG:AddDropdown({Name = "Pack", Flag = "TexPack", Options = texPackList, Default = "Minecraft", Callback = texApply})
    tpG:AddSlider({Name = "Tile Size", Flag = "TexTile", Min = 1, Max = 16, Default = 2, Suffix = " st", Callback = texTile})
    tpG:AddToggle({Name = "Tint With Part Color", Flag = "TexTint", Default = true, Callback = texApply})
    tpG:AddButton({Name = "Reapply Pack", Callback = texApply})

    local ch2 = visualsTab:AddSubTab("Char")
    local cs = ch2:AddSection("Avatar Changer", "Left")
    cs:AddTextbox({Name = "User ID", Flag = "CharUserId", Placeholder = "id or username"})
    cs:AddButton({Name = "Apply Avatar", Callback = function()
        local id = charResolve(F.CharUserId)
        if not id then
            Library:Notify({Title = "Char", Content = "Enter a valid user id first", Duration = 3, Type = "Warning"})
            return
        end
        charApply(id)
    end})
    cs:AddButton({Name = "Random Avatar", Callback = function()
        for _ = 1, 8 do
            if charApply(math.random(10000000, 500000000)) then
                return
            end
            task.wait(0.2)
        end
    end})
    cs:AddButton({Name = "Restore Mine", Callback = function()
        charApply(LocalPlayer.UserId)
    end})
    cs:AddToggle({Name = "Keep On Respawn", Flag = "CharAuto", Default = true})
end

buildWeapons(weaponsSub)
buildVisuals(visualsTab)

do
    local uiSub = settingsTab:AddSubTab("UI")
    local audioSub = settingsTab:AddSubTab("Audios")
    local cfgSub = settingsTab:AddSubTab("Config")
    local keySub = settingsTab:AddSubTab("Keybinds")

    local theme = uiSub:AddSection("Theme", "Left")
    theme:AddColorPicker({Name = "Accent Color", Flag = "UIAccent", Default = Default.Accent, Callback = function(c)
        Theme.Accent = c
        applyTheme()
    end})
    theme:AddColorPicker({Name = "Background Color", Flag = "UIBackground", Default = Default.Background, Callback = function(c)
        Theme.Background = c
        applyTheme()
    end})
    theme:AddColorPicker({Name = "Surface Color", Flag = "UISurface", Default = Default.Surface, Callback = function(c)
        Theme.Surface = c
        applyTheme()
    end})
    theme:AddColorPicker({Name = "Text Color", Flag = "UIText", Default = Default.Text, Callback = function(c)
        Theme.Text = c
        applyTheme()
    end})
    theme:AddDropdown({Name = "Font", Flag = "UIFont", Options = validFonts, Default = "GothamMedium", Callback = function(name)
        if not name then
            return
        end
        local ok, f = pcall(function()
            return Enum.Font[name]
        end)
        if ok and f then
            Theme.Font = f
            applyTheme()
        end
    end})
    theme:AddSlider({Name = "Text Size", Flag = "UITextSize", Min = 70, Max = 130, Default = 100, Callback = function(v)
        Theme.TextScale = v / 100
        applyTheme()
    end})
    theme:AddSlider({Name = "UI Size", Flag = "UIScale", Min = 60, Max = 130, Default = 100, Callback = function()
        applyScale()
        holderGoal = clampGoal(holderGoal)
    end})
    theme:AddSlider({Name = "Wallpaper Opacity", Flag = "WallpaperOpacity", Min = 0, Max = 100, Default = 85, Callback = applyWallpaper})
    theme:AddSlider({Name = "Wallpaper Dim", Flag = "WallpaperDim", Min = 0, Max = 100, Default = 50, Callback = applyWallpaper})
    theme:AddButton({Name = "Reset Theme", Callback = function()
        for _, key in ipairs({"UIAccent", "UIBackground", "UISurface", "UIText", "UIFont", "UITextSize", "UIScale", "WallpaperOpacity", "WallpaperDim"}) do
            local opt = Library.Options[key]
            if opt then
                opt:Set(opt.Default)
            end
        end
        Library:Notify({Title = "UI Settings", Content = "Theme reset to default", Duration = 2.5, Type = "Success"})
    end})

    local interface = uiSub:AddSection("Interface", "Right")
    interface:AddKeybind({Name = "Menu Key", Flag = "MenuKey", Default = "RightShift", OnPress = function()
        Library:Toggle()
    end})
    interface:AddToggle({Name = "Toggle Button", Flag = "ShowToggle", Default = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled, Callback = function(v)
        toggleBtn.Visible = v
    end})
    interface:AddSlider({Name = "Button Size", Flag = "ButtonSize", Min = 36, Max = 90, Default = 54, Suffix = "px", Callback = function(v)
        tween(toggleBtn, 0.2, {Size = UDim2.fromOffset(v, v)})
    end})
    interface:AddToggle({Name = "Falling Pumpkins", Flag = "Pumpkins", Default = true})
    interface:AddToggle({Name = "Custom Crosshair", Flag = "Crosshair", Default = true})
    interface:AddToggle({Name = "Restore Mouse Lock", Flag = "RestoreLock", Default = false})
    interface:AddButton({Name = "Fix Mouse", Callback = function()
        Library:FixMouse()
        Library:Notify({Title = "Mouse", Content = "Mouse unlocked", Duration = 2, Type = "Success"})
    end})
    interface:AddSlider({Name = "Crosshair Size", Flag = "CrosshairSize", Min = 20, Max = 80, Default = 36, Suffix = "px", Callback = function(v)
        cursor.Size = UDim2.fromOffset(v, v)
    end})
    interface:AddSlider({Name = "Background Darkness", Flag = "ScrimDarkness", Min = 0, Max = 90, Default = 55, Callback = function()
        if windowVisible then
            tween(scrim, 0.2, {BackgroundTransparency = scrimTarget()})
        end
    end})
    interface:AddToggle({Name = "Mouse Rain", Flag = "MouseRain", Default = true})
    interface:AddToggle({Name = "Rain Only In Menu", Flag = "RainMenuOnly", Default = true})
    interface:AddToggle({Name = "Click Sounds", Flag = "HoverSound", Default = true})
    interface:AddButton({Name = "Unload UI", Callback = function()
        Library:Unload()
    end})

    local songs = {
        {Name = "idk", Id = IDS.Music},
        {Name = "stalk your socials", Id = 96622114113241},
        {Name = "just wanna be loved", Id = 108781289909774},
    }
    local songNames, songIds = {}, {}
    for _, song in ipairs(songs) do
        table.insert(songNames, song.Name)
        songIds[song.Name] = song.Id
    end

    local songSection = audioSub:AddSection("Songs", "Left")
    songSection:AddDropdown({Name = "Song", Flag = "MusicSong", Options = songNames, Default = songNames[1], Callback = function(name)
        local id = name and songIds[name]
        if not id then
            return
        end
        local wasOn = windowVisible and Library.Flags.MusicEnabled ~= false
        music:Stop()
        music.SoundId = asset(id)
        music.TimePosition = 0
        if wasOn then
            musicOn()
        end
    end})

    local audio = audioSub:AddSection("Playback", "Right")
    audio:AddToggle({Name = "Background Music", Flag = "MusicEnabled", Default = true, Callback = function(v)
        if windowVisible then
            if v then
                musicOn()
            else
                musicOff()
            end
        end
    end})
    audio:AddToggle({Name = "Loop Music", Flag = "MusicLoop", Default = true, Callback = function(v)
        music.Looped = v
    end})
    audio:AddSlider({Name = "Music Volume", Flag = "MusicVolume", Min = 0, Max = 100, Default = 40, Callback = function(v)
        if windowVisible and music.IsPlaying then
            tween(music, 0.15, {Volume = v / 100}, Enum.EasingStyle.Quad)
        end
    end})
    audio:AddSlider({Name = "Effects Volume", Flag = "EffectsVolume", Min = 0, Max = 100, Default = 60})

    local manager = cfgSub:AddSection("Config Manager", "Left")
    manager:AddTextbox({Name = "Config Name", Flag = "ConfigName", Placeholder = "my config", NoSave = true})
    local listDrop = manager:AddDropdown({Name = "Saved Configs", Flag = "ConfigList", Options = Configs.List(), NoSave = true})

    local autoLabel

    local function refreshConfigs()
        listDrop:Refresh(Configs.List())
    end

    local function updateAutoLabel()
        local a = Configs.GetAutoload()
        autoLabel:Set("Autoload: " .. (a ~= "" and a or "none"))
    end

    local function report(ok, info, verb)
        if ok then
            Library:Notify({Title = "Config", Content = verb .. " " .. tostring(info), Duration = 2.5, Type = "Success"})
        else
            Library:Notify({Title = "Config", Content = tostring(info), Duration = 3, Type = "Error"})
        end
    end

    manager:AddButton({Name = "Create Config", Callback = function()
        local ok, info = Configs.Save(Library.Flags.ConfigName)
        report(ok, info, "Saved")
        if ok then
            refreshConfigs()
            listDrop:Set(info, true)
        end
    end})
    manager:AddButton({Name = "Load Selected", Callback = function()
        local ok, info = Configs.Load(Library.Flags.ConfigList)
        report(ok, info, "Loaded")
    end})
    manager:AddButton({Name = "Overwrite Selected", Callback = function()
        local ok, info = Configs.Save(Library.Flags.ConfigList)
        report(ok, info, "Overwrote")
    end})
    manager:AddButton({Name = "Delete Selected", Callback = function()
        local ok, info = Configs.Delete(Library.Flags.ConfigList)
        report(ok, info, "Deleted")
        if ok then
            refreshConfigs()
            updateAutoLabel()
        end
    end})
    manager:AddButton({Name = "Refresh List", Callback = refreshConfigs})

    local auto = cfgSub:AddSection("Autoload", "Right")
    autoLabel = auto:AddLabel("Autoload: none")
    auto:AddButton({Name = "Set Selected As Autoload", Callback = function()
        local name = Library.Flags.ConfigList
        if not name then
            Library:Notify({Title = "Config", Content = "Select a config first", Duration = 2.5, Type = "Warning"})
            return
        end
        Configs.SetAutoload(name)
        updateAutoLabel()
        Library:Notify({Title = "Config", Content = "Autoload set to " .. name, Duration = 2.5, Type = "Success"})
    end})
    auto:AddButton({Name = "Clear Autoload", Callback = function()
        Configs.SetAutoload("")
        updateAutoLabel()
        Library:Notify({Title = "Config", Content = "Autoload cleared", Duration = 2.5})
    end})

    local hudSection = keySub:AddSection("Active List", "Left")
    hudSection:AddToggle({Name = "Show Active List", Flag = "HudEnabled", Default = true})
    hudSection:AddToggle({Name = "Hide While Menu Open", Flag = "HudHideInMenu", Default = false})
    hudSection:AddSlider({Name = "Distance From Bottom", Flag = "HudOffset", Min = 8, Max = 240, Default = 24, Suffix = "px"})

    updateAutoLabel()
end

function Library:Unload()
    for _, c in ipairs(Library.Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    for _, fn in ipairs(cleanups) do
        pcall(fn)
    end
    pcall(function()
        RunService:UnbindFromRenderStep("PrestigeCursor")
    end)
    exitCursor()
    pcall(function()
        music:Stop()
        music:Destroy()
    end)
    gui:Destroy()
    env.PrestigeV1 = nil
end

env.PrestigeV1 = Library

applyTheme()
applyWallpaper()
music.Looped = Library.Flags.MusicLoop ~= false
toggleBtn.Visible = Library.Flags.ShowToggle and true or false

task.spawn(function()
    local waited = 0
    while gui.AbsoluteSize.X < 50 and waited < 60 do
        waited = waited + 1
        task.wait()
    end
    measure()
    notifyScale.Scale = autoScale
    centerHolder()

    local backdrop = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 40,
        Parent = gui,
    })
    local introGlow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(560, 560),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 41,
        Parent = gui,
    })
    corner(introGlow, 280)
    new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.6),
        }),
        Parent = introGlow,
    })
    local glowScale = new("UIScale", {Scale = autoScale * 0.5, Parent = introGlow})
    local intro = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(460, 460),
        BackgroundTransparency = 1,
        Image = asset(IDS.Intro),
        ImageTransparency = 1,
        ZIndex = 42,
        Parent = gui,
    })
    local introScale = new("UIScale", {Scale = autoScale * 0.6, Parent = intro})

    tween(backdrop, 0.6, {BackgroundTransparency = 0.4})
    tween(introGlow, 0.9, {BackgroundTransparency = 0.9})
    tween(glowScale, 1.1, {Scale = autoScale}, Enum.EasingStyle.Quint)
    tween(intro, 0.6, {ImageTransparency = 0})
    tween(introScale, 0.9, {Scale = autoScale}, Enum.EasingStyle.Back)
    task.wait(0.9)
    tween(introScale, 1.4, {Scale = autoScale * 1.06}, Enum.EasingStyle.Sine)
    task.wait(1.3)
    tween(backdrop, 0.5, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
    tween(intro, 0.5, {ImageTransparency = 1}, Enum.EasingStyle.Quad)
    tween(introScale, 0.5, {Scale = autoScale * 1.25}, Enum.EasingStyle.Quad)
    tween(introGlow, 0.5, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
    tween(glowScale, 0.5, {Scale = autoScale * 1.4}, Enum.EasingStyle.Quad)
    task.wait(0.4)
    Library:Open()
    task.wait(0.15)
    backdrop:Destroy()
    intro:Destroy()
    introGlow:Destroy()

    local waitedAura = 0
    while not Library.AuraReady and waitedAura < 80 do
        waitedAura = waitedAura + 1
        task.wait(0.1)
    end
    local autoName = Configs.GetAutoload()
    if autoName ~= "" then
        local ok = Configs.Load(autoName)
        if ok then
            task.wait(0.6)
            Library:Notify({Title = "Config", Content = "Autoloaded " .. autoName, Duration = 2.5, Type = "Success"})
        end
    end
end)

return Library
