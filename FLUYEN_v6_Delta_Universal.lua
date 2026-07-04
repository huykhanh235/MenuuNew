--[[
  ╔══════════════════════════════════════════════════════════╗
  ║  FLUYEN HUD MENU - DELTA UNIVERSAL EDITION v6.1        ║
  ║  Complete rewrite - Modern UI + All Fixes + New Features║
  ║  Compatible: Delta Executor (Android/Mobile/PC)        ║
  ║                                                         ║
  ║  v6.1 Changelog:                                       ║
  ║  • Complete UI redesign - Glassmorphism + animations   ║
  ║  • Fixed ESP system - team check, dead check, cleanup  ║
  ║  • Fixed Key System - ALL features require key now     ║
  ║  • Fixed Tracers - proper bottom-center + object pool  ║
  ║  • Fixed NightVision/Xray - dynamic start/stop loops   ║
  ║  • Real Skeleton ESP with bone rendering               ║
  ║  • Real Quick HUD overlay showing active features      ║
  ║  • Real Silent Aim + Aim Prediction with velocity     ║
  ║  • New: Crosshair, Player Radar, Kill Aura            ║
  ║  • New: Auto Collect, Anti-Fling, Bhop, Long Jump     ║
  ║  • New: Panic Key, FPS Counter, Config System         ║
  ║  • Optimized: Cached players, throttled ESP, pooled   ║
  ╚══════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- POLYFILL: task library for Delta executor
-- ============================================================
local _taskOk = false
pcall(function() local _ = task _taskOk = true end)

local _wait
_wait = function(t)
    t = t or 0
    local ok, _ = pcall(function() wait(t) end)
    if ok then return end
    if _taskOk then
        ok, _ = pcall(function() task.wait(t) end)
        if ok then return end
    end
    local t0 = tick() while tick() - t0 < t do end
end

local _spawn
_spawn = function(f)
    local ok, _ = pcall(function() spawn(f) end)
    if ok then return end
    if _taskOk then
        ok, _ = pcall(function() task.spawn(f) end)
        if ok then return end
    end
    pcall(function() coroutine.wrap(f)() end)
end

local _delay
_delay = function(t, f)
    t = t or 0
    local ok, _ = pcall(function() delay(t, f) end)
    if ok then return end
    if _taskOk then
        ok, _ = pcall(function() task.delay(t, f) end)
        if ok then return end
    end
    _spawn(function() _wait(t) f() end)
end

-- Polyfill: fireproximityprompt (Delta executor)
if not fireproximityprompt then
    fireproximityprompt = function(prompt)
        pcall(function()
            if prompt and prompt.Parent then
                prompt.HoldDuration = 0
                prompt.InputBegan:Fire()
                prompt.InputEnded:Fire()
            end
        end)
    end
end

-- Polyfill: firetouchinterest (Delta executor)
if not firetouchinterest then
    firetouchinterest = function(part0, part1, flag)
        pcall(function()
            if part0 and part1 then
                if flag == 0 then
                    part0.CFrame = part1.CFrame
                end
            end
        end)
    end
end

-- ============================================================
-- MAIN SCRIPT - pcall wrapper
-- ============================================================
local _ok, _err = pcall(function()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- Anti-detection
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            if conn.Disable then conn:Disable() end
        end
    end
end)

-- Config
local SCRIPT_NAME = "FLUYEN"
local SCRIPT_VERSION = "v6.1"
local SCRIPT_AUTHOR = "FLUYEN Team"

-- ============================================================
-- KEY SYSTEM - Secure & Required for ALL features
-- ============================================================
local VALID_KEY = "huyandkhang"
local keyAuthenticated = false

-- ============================================================
-- CONNECTION MANAGER - Prevent leaks
-- ============================================================
local Conns = {}

local function setConn(name, conn)
    if Conns[name] then
        pcall(function() Conns[name]:Disconnect() end)
    end
    Conns[name] = conn
end

local function killConn(name)
    if Conns[name] then
        pcall(function() Conns[name]:Disconnect() end)
        Conns[name] = nil
    end
end

local function killAllConns()
    for name, conn in pairs(Conns) do
        pcall(function() conn:Disconnect() end)
    end
    Conns = {}
end

-- ============================================================
-- STATES & VALUES
-- ============================================================
local States = {
    ESP=false, BoxESP=false, NameESP=false, HealthESP=false, DistanceESP=false,
    Tracers=false, Chams=false, SkeletonESP=false, HeadDot=false, TeamColors=false,
    FullBright=false, NightVision=false, Xray=false,
    Aim=false, SilentAim=false, AimFOV=false, AimPrediction=false, TriggerBot=false,
    HitboxExpander=false, Crosshair=false, KillAura=false,
    Speed=false, Fly=false, Noclip=false, JumpPower=false,
    InfiniteJump=false, ClickTeleport=false, Sprint=false,
    AntiVoid=false, AntiAFK=true, FreezeTime=false, FPSBoost=false,
    FPSCounter=true, AntiBlind=false, AntiSlow=false, AntiRagdoll=false,
    AntiGrab=false, AntiFling=false, AutoCollect=false,
    Spin=false, Float=false, Bang=false, Invisible=false, OrbitActive=false,
    Bhop=false, LongJump=false,
    QuickHUD=false, Radar=false, PanicMode=false,
    AutoLoadSettings=false, MinimizeButton=true, DraggableGUI=true, Notifications=true,
}

local Values = {
    SpeedValue=16, FlySpeed=50, JumpPowerValue=50, SprintSpeed=24,
    SpinSpeed=10, FlingPower=500, OrbitRadius=5, OrbitSpeed=1,
    AimFOVValue=90, AimSmoothness=5, HitboxSize=10,
    FieldOfView=70, KillAuraRange=15, KillAuraDamage=20,
    CrosshairSize=4, CrosshairGap=2,
    ESPRefreshRate=0.03, RadarSize=150, RadarRange=200,
    LongJumpPower=80, BhopSpeed=20, AntiFlingStrength=50,
}

-- ============================================================
-- LANGUAGE SYSTEM (VI default, EN)
-- ============================================================
local currentLang = "VI"

local Lang = {
    EN = {
        ScriptName="FLUYEN", Version="v6.1", Loaded="Loaded!",
        KeySystem="Key System", KeyRequired="Key required to use features",
        KeyPlaceholder="Enter key...", KeySubmit="Submit", KeyCorrect="Key correct!",
        KeyWrong="Wrong key!", KeyAlready="Already authenticated!",
        Home="Home", Visual="Visual", Combat="Combat", Movement="Movement",
        Utility="Utility", Server="Server", Fun="Fun", Settings="Settings",
        ESP="ESP Highlight", BoxESP="Box ESP", NameESP="Name ESP",
        HealthESP="Health ESP", DistanceESP="Distance ESP",
        Tracers="Tracers", Chams="Chams", FullBright="FullBright",
        NightVision="Night Vision", Xray="X-Ray Mode",
        SkeletonESP="Skeleton ESP", HeadDot="Head Dot", TeamColors="Team Colors",
        ESPRefreshRate="ESP Refresh Rate",
        Aim="Aimbot", SilentAim="Silent Aim", AimFOV="Aim FOV Circle",
        AimPrediction="Aim Prediction", TriggerBot="Trigger Bot",
        HitboxExpander="Hitbox Expander", Crosshair="Crosshair",
        KillAura="Kill Aura",
        AimFOVValue="FOV Size", AimSmoothness="Aim Smoothness",
        HitboxSize="Hitbox Size", KillAuraRange="Kill Aura Range",
        KillAuraDamage="Kill Aura Damage",
        CrosshairSize="Crosshair Size", CrosshairGap="Crosshair Gap",
        FieldOfView="Field Of View",
        Speed="Speed", Fly="Fly", Noclip="Noclip", JumpPower="Jump Power",
        InfiniteJump="Infinite Jump", ClickTeleport="Click Teleport",
        Teleport="Teleport to Mouse", Sprint="Sprint", AntiVoid="Anti Void",
        SpeedValue="Speed Value", FlySpeed="Fly Speed",
        JumpPowerValue="Jump Power Value", SprintSpeed="Sprint Speed",
        Bhop="Bunny Hop", BhopSpeed="Bhop Speed",
        LongJump="Long Jump", LongJumpPower="Long Jump Power",
        AntiAFK="Anti AFK", FreezeTime="Freeze Time", FPSBoost="FPS Boost",
        FPSCounter="FPS Counter", AntiBlind="Anti Blind", AntiSlow="Anti Slow",
        AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Grab", AntiFling="Anti Fling",
        AntiFlingStrength="Anti Fling Strength",
        AutoCollect="Auto Collect",
        RejoinServer="Rejoin Server", ServerHop="Server Hop",
        JoinSmallServer="Join Small Server", CopyServerID="Copy Server ID",
        PlayerList="Player List", SpectatePlayer="Spectate Player",
        StopSpectate="Stop Spectate",
        Radar="Player Radar", RadarSize="Radar Size", RadarRange="Radar Range",
        QuickHUD="Quick HUD",
        Spin="Spin", Float="Float", Bang="Bang", Fling="Fling",
        OrbitPlayer="Orbit Player", OrbitActive="Orbit Active",
        OrbitRadius="Orbit Radius", OrbitSpeed="Orbit Speed",
        Invisible="Invisible",
        Theme="Theme", Language="Language", GUI="GUI",
        AutoLoadSettings="Auto Load Settings", MinimizeButton="Minimize Button",
        DraggableGUI="Draggable GUI", Notifications="Notifications",
        SaveSettings="Save Settings", ResetSettings="Reset Settings",
        PanicKey="Panic Key", ToggleKeybind="Toggle Keybind",
        Username="Username", Executor="Executor", Credits="Credits",
        Changelog="Changelog", PlayersOnline="Players Online",
        Enabled="Enabled", Disabled="Disabled",
        SpinSpeed="Spin Speed", FlingPower="Fling Power",
    },
    VI = {
        ScriptName="FLUYEN", Version="v6.1", Loaded="Da tai!",
        KeySystem="He Thong Key", KeyRequired="Can key de su dung tinh nang",
        KeyPlaceholder="Nhap key...", KeySubmit="Xac nhan", KeyCorrect="Key dung!",
        KeyWrong="Key sai!", KeyAlready="Da xac thuc!",
        Home="Trang Chu", Visual="Hinh Anh", Combat="Chien Dau", Movement="Di Chuyen",
        Utility="Tien Ich", Server="May Chu", Fun="Giai Tri", Settings="Cai Dat",
        ESP="ESP Highlight", BoxESP="Box ESP", NameESP="Ten ESP",
        HealthESP="Mau ESP", DistanceESP="Khoang Cach ESP",
        Tracers="Duong Noi", Chams="Chams", FullBright="Sang Day",
        NightVision="Thi Ban Dem", Xray="X-Ray",
        SkeletonESP="Xuong ESP", HeadDot="Cham Dau", TeamColors="Mau Doi",
        ESPRefreshRate="Toc Do ESP",
        Aim="Aimbot", SilentAim="Silent Aim", AimFOV="Vong Tron FOV",
        AimPrediction="Du Doan Cham", TriggerBot="Trigger Bot",
        HitboxExpander="Mo Rong Hitbox", Crosshair="Tieu Chim",
        KillAura="Kill Aura",
        AimFOVValue="Kich Thuoc FOV", AimSmoothness="Do Muot Aim",
        HitboxSize="Kich Thuoc Hitbox", KillAuraRange="Pham Vi Kill Aura",
        KillAuraDamage="Sat Thuong Kill Aura",
        CrosshairSize="Size Tieu Chim", CrosshairGap="Khoang Cach Tieu Chim",
        FieldOfView="Goc Nhin",
        Speed="Toc Do", Fly="Bay", Noclip="Xuyen Tuong", JumpPower="Luc Nhay",
        InfiniteJump="Nhay Vo Han", ClickTeleport="Click Di Chuyen",
        Teleport="Di Chuyen Den Chuot", Sprint="Chay Nhanh", AntiVoid="Chong Roi",
        SpeedValue="Gia Tri Toc Do", FlySpeed="Toc Do Bay",
        JumpPowerValue="Gia Tri Nhay", SprintSpeed="Toc Do Chay",
        Bhop="Bunny Hop", BhopSpeed="Toc Do Bhop",
        LongJump="Nhay Xa", LongJumpPower="Luc Nhay Xa",
        AntiAFK="Chong AFK", FreezeTime="Dong Bang Thoi Gian", FPSBoost="Tang FPS",
        FPSCounter="Dem FPS", AntiBlind="Chong Mu", AntiSlow="Chong Cham",
        AntiRagdoll="Chong Ragdoll", AntiGrab="Chong Keo", AntiFling="Chong Fling",
        AntiFlingStrength="Do Manh Chong Fling",
        AutoCollect="Tu Nhat Do",
        RejoinServer="Vao Lai Server", ServerHop="Chuyen Server",
        JoinSmallServer="Server It Nguoi", CopyServerID="Copy ID Server",
        PlayerList="Danh Sach", SpectatePlayer="Theo Doi",
        StopSpectate="Dung Theo Doi",
        Radar="Radar", RadarSize="Size Radar", RadarRange="Pham Vi Radar",
        QuickHUD="HUD Nhanh",
        Spin="Xoay", Float="Bay Lang", Bang="Bang", Fling="Fling",
        OrbitPlayer="Quay Quanh", OrbitActive="Quay Hoat Dong",
        OrbitRadius="Ban Kinh Quay", OrbitSpeed="Toc Do Quay",
        Invisible="Ao Anh",
        Theme="Giao Dien", Language="Ngon Ngu", GUI="Giao Dien",
        AutoLoadSettings="Tu Tai Cai Dat", MinimizeButton="Nut Thu Nho",
        DraggableGUI="Keo Giao Dien", Notifications="Thong Bao",
        SaveSettings="Luu Cai Dat", ResetSettings="Dat Lai",
        PanicKey="Nut Khan Cap", ToggleKeybind="Phim Tat",
        Username="Ten", Executor="Executor", Credits="Credits",
        Changelog="Lich Su", PlayersOnline="Online",
        Enabled="Bat", Disabled="Tat",
        SpinSpeed="Toc Do Xoay", FlingPower="Luc Fling",
    },
}

local function T(key)
    local lang = Lang[currentLang] or Lang.VI
    return lang[key] or key
end

-- ============================================================
-- THEMES - 6 Modern Themes
-- ============================================================
local Themes = {
    Nebula = {
        bg=Color3.fromRGB(18,18,30), sidebar=Color3.fromRGB(22,22,40),
        accent=Color3.fromRGB(120,80,255), text=Color3.fromRGB(240,240,255),
        textDim=Color3.fromRGB(130,130,160), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(28,28,50), border=Color3.fromRGB(60,60,90),
        tabActive=Color3.fromRGB(40,30,80), tabInactive=Color3.fromRGB(20,20,35),
        toggleOn=Color3.fromRGB(120,80,255), toggleOff=Color3.fromRGB(50,50,70),
    },
    Crimson = {
        bg=Color3.fromRGB(30,18,18), sidebar=Color3.fromRGB(40,22,22),
        accent=Color3.fromRGB(255,50,50), text=Color3.fromRGB(255,240,240),
        textDim=Color3.fromRGB(160,130,130), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(50,28,28), border=Color3.fromRGB(90,60,60),
        tabActive=Color3.fromRGB(80,30,30), tabInactive=Color3.fromRGB(35,20,20),
        toggleOn=Color3.fromRGB(255,50,50), toggleOff=Color3.fromRGB(70,50,50),
    },
    Emerald = {
        bg=Color3.fromRGB(18,30,18), sidebar=Color3.fromRGB(22,40,22),
        accent=Color3.fromRGB(50,255,100), text=Color3.fromRGB(240,255,240),
        textDim=Color3.fromRGB(130,160,130), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(28,50,28), border=Color3.fromRGB(60,90,60),
        tabActive=Color3.fromRGB(30,80,30), tabInactive=Color3.fromRGB(20,35,20),
        toggleOn=Color3.fromRGB(50,255,100), toggleOff=Color3.fromRGB(50,70,50),
    },
    Sakura = {
        bg=Color3.fromRGB(30,18,25), sidebar=Color3.fromRGB(40,22,32),
        accent=Color3.fromRGB(255,105,180), text=Color3.fromRGB(255,240,245),
        textDim=Color3.fromRGB(160,130,150), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(50,28,42), border=Color3.fromRGB(90,60,75),
        tabActive=Color3.fromRGB(80,30,55), tabInactive=Color3.fromRGB(35,20,28),
        toggleOn=Color3.fromRGB(255,105,180), toggleOff=Color3.fromRGB(70,50,60),
    },
    Arctic = {
        bg=Color3.fromRGB(18,22,30), sidebar=Color3.fromRGB(22,28,40),
        accent=Color3.fromRGB(80,180,255), text=Color3.fromRGB(240,245,255),
        textDim=Color3.fromRGB(130,145,160), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(28,35,50), border=Color3.fromRGB(60,75,90),
        tabActive=Color3.fromRGB(30,50,80), tabInactive=Color3.fromRGB(20,25,35),
        toggleOn=Color3.fromRGB(80,180,255), toggleOff=Color3.fromRGB(50,55,70),
    },
    Gold = {
        bg=Color3.fromRGB(30,25,15), sidebar=Color3.fromRGB(40,32,18),
        accent=Color3.fromRGB(255,200,50), text=Color3.fromRGB(255,250,230),
        textDim=Color3.fromRGB(160,145,110), success=Color3.fromRGB(80,255,120),
        danger=Color3.fromRGB(255,60,80), warning=Color3.fromRGB(255,200,60),
        card=Color3.fromRGB(50,42,25), border=Color3.fromRGB(90,75,50),
        tabActive=Color3.fromRGB(80,60,25), tabInactive=Color3.fromRGB(35,28,15),
        toggleOn=Color3.fromRGB(255,200,50), toggleOff=Color3.fromRGB(70,60,40),
    },
}

local currentTheme = "Nebula"
local function theme()
    return Themes[currentTheme] or Themes.Nebula
end

-- ============================================================
-- NOTIFICATION SYSTEM - Modern with progress bar
-- ============================================================
local notifStack = {}
local allUIThemed = {}

local function notify(title, text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"
    if not States.Notifications then return end

    local screenGui = playerGui:FindFirstChild("FLUYEN_NotifGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FLUYEN_NotifGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui
    end

    local t = theme()
    local icons = {success="✓", error="✗", warning="⚠", info="●"}
    local colors = {success=t.success, error=t.danger, warning=t.warning, info=t.accent}
    local icon = icons[notifType] or "●"
    local col = colors[notifType] or t.accent

    for i, n in ipairs(notifStack) do
        if n and n.Main and n.Main.Parent then
            pcall(function()
                TweenService:Create(n.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0.5, 0, 0, 10 + (i-1) * 75)
                }):Play()
            end)
        end
    end

    local main = Instance.new("Frame")
    main.Name = "Notif_" .. #notifStack
    main.Size = UDim2.new(0, 280, 0, 65)
    main.Position = UDim2.new(0.5, 0, 0, -70)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.BackgroundColor3 = t.card
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.ZIndex = 200
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local border = Instance.new("UIStroke")
    border.Color = col
    border.Thickness = 1
    border.Transparency = 0.5
    border.Parent = main

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = col
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 18
    iconLabel.ZIndex = 201
    iconLabel.Parent = main

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -50, 0, 20)
    titleL.Position = UDim2.new(0, 45, 0, 8)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.TextColor3 = t.text
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.ZIndex = 201
    titleL.Parent = main

    local textL = Instance.new("TextLabel")
    textL.Size = UDim2.new(1, -50, 0, 18)
    textL.Position = UDim2.new(0, 45, 0, 28)
    textL.BackgroundTransparency = 1
    textL.Text = text
    textL.TextColor3 = t.textDim
    textL.Font = Enum.Font.Gotham
    textL.TextSize = 11
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.ZIndex = 201
    textL.Parent = main

    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(1, -20, 0, 3)
    prog.Position = UDim2.new(0, 10, 1, -6)
    prog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    prog.BorderSizePixel = 0
    prog.ZIndex = 201
    prog.Parent = main
    Instance.new("UICorner", prog).CornerRadius = UDim.new(0, 2)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = col
    fill.BorderSizePixel = 0
    fill.ZIndex = 202
    fill.Parent = prog
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

    TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0, 10 + #notifStack * 75)
    }):Play()

    local entry = {Main = main}
    table.insert(notifStack, entry)

    _delay(duration + 0.3, function()
        pcall(function()
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(main, TweenInfo.new(0.3), {
                Position = UDim2.new(0.5, 0, 0, -70)
            }):Play()
        end)
        _wait(0.4)
        pcall(function() main:Destroy() end)
        for i, n in ipairs(notifStack) do
            if n == entry then table.remove(notifStack, i) break end
        end
        for i, n in ipairs(notifStack) do
            if n and n.Main and n.Main.Parent then
                pcall(function()
                    TweenService:Create(n.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                        Position = UDim2.new(0.5, 0, 0, 10 + (i-1) * 75)
                    }):Play()
                end)
            end
        end
    end)
end

-- Key check function (needs notify)
local function checkKey()
    if keyAuthenticated then return true end
    notify(SCRIPT_NAME, "Nhap key trong Settings!", 3, "error")
    return false
end

-- ============================================================
-- PLAYER CACHE - Optimized
-- ============================================================
local cachedPlayers = {}
local cacheDirty = true

local function rebuildCache()
    cachedPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(cachedPlayers, p) end
    end
    cacheDirty = false
end

local function getCachedPlayers()
    if cacheDirty then rebuildCache() end
    return cachedPlayers
end

Players.PlayerAdded:Connect(function() cacheDirty = true end)
Players.PlayerRemoving:Connect(function() cacheDirty = true end)

-- ============================================================
-- ESP GUI OVERLAY
-- ============================================================
local espGui = Instance.new("ScreenGui")
espGui.Name = "FLUYEN_ESPGui"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espGui.Parent = playerGui

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.new(0, Values.AimFOVValue * 2, 0, Values.AimFOVValue * 2)
fovCircle.Position = UDim2.new(0.5, -Values.AimFOVValue, 0.5, -Values.AimFOVValue)
fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.ZIndex = 50
fovCircle.Parent = espGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(120, 80, 255)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

-- FPS Label
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPS"
fpsLabel.Size = UDim2.new(0, 80, 0, 20)
fpsLabel.Position = UDim2.new(0, 8, 0, 4)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 60"
fpsLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 12
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.ZIndex = 60
fpsLabel.Visible = States.FPSCounter
fpsLabel.Parent = espGui

-- Crosshair
local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "Crosshair"
crosshairContainer.Size = UDim2.new(0, 30, 0, 30)
crosshairContainer.Position = UDim2.new(0.5, -15, 0.5, -15)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Visible = false
crosshairContainer.ZIndex = 55
crosshairContainer.Parent = espGui

local chParts = {}
for _, dir in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 2, 0, Values.CrosshairSize)
    line.Position = UDim2.new(0.5, dir[1] * (Values.CrosshairGap + 1) - 1, 0.5, dir[2] * (Values.CrosshairGap + 1) - Values.CrosshairSize/2)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.ZIndex = 56
    line.Parent = crosshairContainer
    table.insert(chParts, line)
end
local chDot = Instance.new("Frame")
chDot.Size = UDim2.new(0, 2, 0, 2)
chDot.Position = UDim2.new(0.5, -1, 0.5, -1)
chDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
chDot.BorderSizePixel = 0
chDot.ZIndex = 57
chDot.Parent = crosshairContainer

-- Tracer Container + POOL (pre-allocated for performance)
local tracerContainer = Instance.new("Frame")
tracerContainer.Name = "Tracers"
tracerContainer.Size = UDim2.new(1, 0, 1, 0)
tracerContainer.BackgroundTransparency = 1
tracerContainer.ZIndex = 48
tracerContainer.Parent = espGui

local TRACER_POOL_SIZE = 30
local tracerPool = {}
for i = 1, TRACER_POOL_SIZE do
    local line = Instance.new("Frame")
    line.Name = "TracerLine_" .. i
    line.Size = UDim2.new(0, 1, 0, 1.5)
    line.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 1
    line.ZIndex = 49
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.Parent = tracerContainer
    table.insert(tracerPool, line)
end

local function hideAllTracers()
    for _, line in ipairs(tracerPool) do
        line.Visible = false
        line.BackgroundTransparency = 1
    end
end

local function drawPooledTracer(idx, x1, y1, x2, y2, color)
    if idx > TRACER_POOL_SIZE then return end
    local line = tracerPool[idx]
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 2 then
        line.Visible = false
        return
    end
    local midX = (x1 + x2) / 2
    local midY = (y1 + y2) / 2
    local angle = math.deg(math.atan2(dy, dx))
    line.Size = UDim2.new(0, length, 0, 1.5)
    line.Position = UDim2.new(0, midX, 0, midY)
    line.Rotation = angle
    line.BackgroundColor3 = color or Color3.fromRGB(120, 80, 255)
    line.BackgroundTransparency = 0.3
    line.Visible = true
end

-- Radar
local radarFrame = Instance.new("Frame")
radarFrame.Name = "Radar"
radarFrame.Size = UDim2.new(0, Values.RadarSize, 0, Values.RadarSize)
radarFrame.Position = UDim2.new(1, -Values.RadarSize - 10, 1, -Values.RadarSize - 10)
radarFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
radarFrame.BackgroundTransparency = 0.3
radarFrame.BorderSizePixel = 0
radarFrame.Visible = false
radarFrame.ZIndex = 50
radarFrame.Parent = espGui
Instance.new("UICorner", radarFrame).CornerRadius = UDim.new(0, 6)
local radarStroke = Instance.new("UIStroke")
radarStroke.Color = Color3.fromRGB(120, 80, 255)
radarStroke.Thickness = 1
radarStroke.Transparency = 0.5
radarStroke.Parent = radarFrame
local radarSelf = Instance.new("Frame")
radarSelf.Size = UDim2.new(0, 6, 0, 6)
radarSelf.Position = UDim2.new(0.5, -3, 0.5, -3)
radarSelf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
radarSelf.BorderSizePixel = 0
radarSelf.ZIndex = 51
radarSelf.Parent = radarFrame
Instance.new("UICorner", radarSelf).CornerRadius = UDim.new(0, 3)
local radarDotsContainer = Instance.new("Frame")
radarDotsContainer.Size = UDim2.new(1, 0, 1, 0)
radarDotsContainer.BackgroundTransparency = 1
radarDotsContainer.ZIndex = 50
radarDotsContainer.Parent = radarFrame

-- Quick HUD Overlay
local quickHUD = Instance.new("Frame")
quickHUD.Name = "QuickHUD"
quickHUD.Size = UDim2.new(0, 180, 1, 0)
quickHUD.Position = UDim2.new(0, 5, 0, 30)
quickHUD.BackgroundTransparency = 1
quickHUD.Visible = false
quickHUD.ZIndex = 45
quickHUD.Parent = espGui

local quickHUDLayout = Instance.new("UIListLayout")
quickHUDLayout.Padding = UDim.new(0, 3)
quickHUDLayout.SortOrder = Enum.SortOrder.LayoutOrder
quickHUDLayout.Parent = quickHUD

-- Key Status Label
local keyStatusLabel = Instance.new("TextLabel")
keyStatusLabel.Name = "KeyStatus"
keyStatusLabel.Size = UDim2.new(0, 280, 0, 28)
keyStatusLabel.Position = UDim2.new(0.5, -140, 1, -38)
keyStatusLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
keyStatusLabel.BackgroundTransparency = 0.2
keyStatusLabel.Text = "⚠ KEY REQUIRED - Nhap key trong Settings"
keyStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatusLabel.Font = Enum.Font.GothamBold
keyStatusLabel.TextSize = 11
keyStatusLabel.ZIndex = 100
keyStatusLabel.Visible = not keyAuthenticated
keyStatusLabel.Parent = espGui
Instance.new("UICorner", keyStatusLabel).CornerRadius = UDim.new(0, 6)

-- Player count label
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(0, 120, 0, 18)
playerCountLabel.Position = UDim2.new(0, 8, 0, 22)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = T("PlayersOnline") .. ": 0"
playerCountLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
playerCountLabel.Font = Enum.Font.Gotham
playerCountLabel.TextSize = 10
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.ZIndex = 60
playerCountLabel.Parent = espGui

-- ============================================================
-- MAIN GUI - Modern Glassmorphism Design
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FLUYEN_MainGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local isOpen = true
local mainWidth = 420
local mainHeight = 520

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, mainWidth, 0, mainHeight)
mainFrame.Position = UDim2.new(0.5, -mainWidth/2, 0.5, -mainHeight/2)
mainFrame.BackgroundColor3 = theme().bg
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
local mainBorder = Instance.new("UIStroke")
mainBorder.Color = theme().border
mainBorder.Thickness = 1
mainBorder.Transparency = 0.3
mainBorder.Parent = mainFrame

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 65, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = theme().sidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 11
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 0)
local sideBorder = Instance.new("UIStroke")
sideBorder.Color = theme().border
sideBorder.Thickness = 1
sideBorder.Transparency = 0.5
sideBorder.Parent = sidebar

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = theme().sidebar
topBar.BorderSizePixel = 0
topBar.ZIndex = 15
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 70, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = SCRIPT_NAME .. " " .. SCRIPT_VERSION
titleLabel.TextColor3 = theme().accent
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 16
titleLabel.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.BackgroundTransparency = 0.6
closeBtn.Text = "✕"
closeBtn.TextColor3 = theme().textDim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 16
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Tab buttons
local tabs = {"Home", "Visual", "Combat", "Movement", "Utility", "Server", "Fun", "Settings"}
local tabIcons = {
    Home="🏠", Visual="👁", Combat="⚔", Movement="🏃",
    Utility="🔧", Server="🌐", Fun="🎮", Settings="⚙"
}
local tabButtons = {}
local currentTab = "Home"

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Name = tabName .. "Btn"
    btn.Size = UDim2.new(1, -10, 0, 48)
    btn.Position = UDim2.new(0, 5, 0, (i-1) * 50 + 5)
    btn.BackgroundColor3 = (tabName == currentTab) and theme().tabActive or theme().tabInactive
    btn.BackgroundTransparency = 0.3
    btn.Text = tabIcons[tabName] or tabName
    btn.TextColor3 = (tabName == currentTab) and theme().text or theme().textDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    btn.ZIndex = 12
    btn.AutoButtonColor = false
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    if tabName == currentTab then
        local ab = Instance.new("Frame")
        ab.Name = "ActiveBorder"
        ab.Size = UDim2.new(0, 3, 0.6, 0)
        ab.Position = UDim2.new(0, 0, 0.2, 0)
        ab.BackgroundColor3 = theme().accent
        ab.BorderSizePixel = 0
        ab.ZIndex = 13
        ab.Parent = btn
        Instance.new("UICorner", ab).CornerRadius = UDim.new(0, 2)
    end
    tabButtons[tabName] = btn

    btn.MouseButton1Click:Connect(function()
        if currentTab == tabName then return end
        currentTab = tabName
        for name, b in pairs(tabButtons) do
            local active = (name == currentTab)
            b.BackgroundColor3 = active and theme().tabActive or theme().tabInactive
            b.TextColor3 = active and theme().text or theme().textDim
            local ab = b:FindFirstChild("ActiveBorder")
            if active and not ab then
                ab = Instance.new("Frame")
                ab.Name = "ActiveBorder"
                ab.Size = UDim2.new(0, 3, 0.6, 0)
                ab.Position = UDim2.new(0, 0, 0.2, 0)
                ab.BackgroundColor3 = theme().accent
                ab.BorderSizePixel = 0
                ab.ZIndex = 13
                ab.Parent = b
                Instance.new("UICorner", ab).CornerRadius = UDim.new(0, 2)
            elseif not active and ab then
                ab:Destroy()
            end
        end
        for name, pg in pairs(pages) do
            pg.Visible = (name == currentTab)
        end
        recalcCurrentPage()
    end)
end

-- Pages Container
local pageContainer = Instance.new("Frame")
pageContainer.Name = "Pages"
pageContainer.Size = UDim2.new(1, -70, 1, -45)
pageContainer.Position = UDim2.new(0, 70, 0, 42)
pageContainer.BackgroundTransparency = 1
pageContainer.ZIndex = 10
pageContainer.ClipsDescendants = true
pageContainer.Parent = mainFrame

-- Create pages
local pages = {}
for _, tabName in ipairs(tabs) do
    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = theme().accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = (tabName == currentTab)
    page.ZIndex = 10
    page.Parent = pageContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page

    pages[tabName] = page
end

-- Minimize Button (floating, with pulse animation)
local miniBtn = Instance.new("TextButton")
miniBtn.Name = "MiniBtn"
miniBtn.Size = UDim2.new(0, 50, 0, 50)
miniBtn.Position = UDim2.new(0, 10, 0.5, -25)
miniBtn.BackgroundColor3 = theme().accent
miniBtn.BackgroundTransparency = 0.3
miniBtn.Text = "F"
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 20
miniBtn.ZIndex = 100
miniBtn.Visible = false
miniBtn.Parent = screenGui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(1, 0)
local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(255, 255, 255)
miniStroke.Thickness = 1
miniStroke.Transparency = 0.5
miniStroke.Parent = miniBtn

-- Pulse animation on minimize button
local pulseAnim = true
_spawn(function()
    while pulseAnim do
        pcall(function()
            if miniBtn.Visible then
                TweenService:Create(miniBtn, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundTransparency = 0.6
                }):Play()
                _wait(1.5)
                TweenService:Create(miniBtn, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundTransparency = 0.2
                }):Play()
                _wait(1.5)
            else
                _wait(0.5)
            end
        end)
    end
end)

-- Menu toggle logic
local function openMenu()
    isOpen = true
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, mainWidth, 0, 0)
    mainFrame.BackgroundTransparency = 1
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, mainWidth, 0, mainHeight)
    }):Play()
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.08
    }):Play()
    miniBtn.Visible = false
end

local function closeMenu()
    isOpen = false
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, mainWidth, 0, 0)
    }):Play()
    TweenService:Create(mainFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    }):Play()
    _delay(0.35, function()
        mainFrame.Visible = false
        if States.MinimizeButton then miniBtn.Visible = true end
    end)
end

local function toggleMenu()
    if isOpen then closeMenu() else openMenu() end
end

closeBtn.MouseButton1Click:Connect(function() closeMenu() end)
miniBtn.MouseButton1Click:Connect(function() openMenu() end)

-- Dragging (mobile + PC)
local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if States.DraggableGUI then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Page recalc
local function recalcCurrentPage()
    local pg = pages[currentTab]
    if pg then
        pcall(function()
            pg.CanvasSize = UDim2.new(0, 0, 0, pg.AbsoluteCanvasSize.Y)
        end)
    end
end

-- ============================================================
-- UI BUILDER FUNCTIONS
-- ============================================================
local elementOrder = 0

local function addSection(page, text, langKey)
    elementOrder = elementOrder + 1
    local t = theme()

    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 32)
    section.BackgroundColor3 = t.card
    section.BackgroundTransparency = 0.5
    section.BorderSizePixel = 0
    section.LayoutOrder = elementOrder
    section.Parent = page
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0.7, 0)
    accent.Position = UDim2.new(0, 6, 0.15, 0)
    accent.BackgroundColor3 = t.accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 2
    accent.Parent = section
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = t.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = section

    if langKey then
        table.insert(allUIThemed, {obj=label, prop="TextColor3", themeKey="text"})
    end

    return section
end

local function addToggle(page, text, stateKey, callback, langKey)
    elementOrder = elementOrder + 1
    local t = theme()

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = t.card
    row.BackgroundTransparency = 0.6
    row.BorderSizePixel = 0
    row.LayoutOrder = elementOrder
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rowBorder = Instance.new("UIStroke")
    rowBorder.Color = t.border
    rowBorder.Thickness = 0.5
    rowBorder.Transparency = 0.7
    rowBorder.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = t.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = row

    -- Toggle switch (custom, modern)
    local toggleBg = Instance.new("TextButton")
    toggleBg.Name = "ToggleSwitch"
    toggleBg.Size = UDim2.new(0, 42, 0, 22)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBg.BackgroundColor3 = States[stateKey] and t.toggleOn or t.toggleOff
    toggleBg.BackgroundTransparency = 0.2
    toggleBg.Text = ""
    toggleBg.ZIndex = 3
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = row
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 18, 0, 18)
    local knobX = States[stateKey] and 22 or 2
    knob.Position = UDim2.new(0, knobX, 0, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 4
    knob.Parent = toggleBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function updateToggleVisual()
        local isOn = States[stateKey]
        local t2 = theme()
        pcall(function()
            TweenService:Create(toggleBg, TweenInfo.new(0.25), {
                BackgroundColor3 = isOn and t2.toggleOn or t2.toggleOff
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                Position = UDim2.new(0, isOn and 22 or 2, 0, 2)
            }):Play()
        end)
    end

    toggleBg.MouseButton1Click:Connect(function()
        if not checkKey() then return end
        States[stateKey] = not States[stateKey]
        updateToggleVisual()
        if callback then
            pcall(function() callback(States[stateKey]) end)
        end
        recalcCurrentPage()
    end)

    -- Theme tracking
    table.insert(allUIThemed, {obj=row, prop="BackgroundColor3", themeKey="card"})
    table.insert(allUIThemed, {obj=rowBorder, prop="Color", themeKey="border"})
    if langKey then
        table.insert(allUIThemed, {obj=label, prop="TextColor3", themeKey="text"})
    end

    return row, toggleBg, knob, updateToggleVisual
end

local function addSlider(page, text, valueKey, min, max, isFloat, callback, langKey)
    elementOrder = elementOrder + 1
    local t = theme()

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = t.card
    row.BackgroundTransparency = 0.6
    row.BorderSizePixel = 0
    row.LayoutOrder = elementOrder
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rowBorder = Instance.new("UIStroke")
    rowBorder.Color = t.border
    rowBorder.Thickness = 0.5
    rowBorder.Transparency = 0.7
    rowBorder.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(Values[valueKey])
    label.TextColor3 = t.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    label.Parent = row

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = t.toggleOff
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 2
    sliderBg.Parent = row
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = t.accent
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 3
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new(0, -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 4
    sliderKnob.Parent = sliderFill
    Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

    -- Update fill position
    local function updateSliderFill()
        local val = Values[valueKey]
        local pct = math.clamp((val - min) / math.max(max - min, 0.001), 0, 1)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(1, -7, 0.5, -7)
        label.Text = text .. ": " .. tostring(isFloat and math.floor(val * 100)/100 or math.floor(val))
    end
    updateSliderFill()

    local sliding = false
    sliderBg.InputBegan:Connect(function(input)
        if not checkKey() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * relX
            Values[valueKey] = isFloat and val or math.floor(val)
            updateSliderFill()
            if callback then pcall(function() callback(Values[valueKey]) end)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    table.insert(allUIThemed, {obj=row, prop="BackgroundColor3", themeKey="card"})
    table.insert(allUIThemed, {obj=rowBorder, prop="Color", themeKey="border"})
    table.insert(allUIThemed, {obj=sliderFill, prop="BackgroundColor3", themeKey="accent"})
    if langKey then table.insert(allUIThemed, {obj=label, prop="TextColor3", themeKey="text"}) end

    return row
end

local function addButton(page, text, callback, langKey)
    elementOrder = elementOrder + 1
    local t = theme()

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = t.accent
    btn.BackgroundTransparency = 0.4
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.LayoutOrder = elementOrder
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local btnBorder = Instance.new("UIStroke")
    btnBorder.Color = t.accent
    btnBorder.Thickness = 1
    btnBorder.Transparency = 0.5
    btnBorder.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if not checkKey() then return end
        -- Click animation
        pcall(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.8}):Play()
        end)
        _delay(0.15, function()
            pcall(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
            end)
        end)
        if callback then pcall(function() callback() end) end
    end)

    table.insert(allUIThemed, {obj=btn, prop="BackgroundColor3", themeKey="accent"})
    if langKey then table.insert(allUIThemed, {obj=btn, prop="TextColor3", themeKey="text"}) end

    return btn
end

local function addInfoRow(page, labelText, valueText, langKey)
    elementOrder = elementOrder + 1
    local t = theme()

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = t.card
    row.BackgroundTransparency = 0.7
    row.BorderSizePixel = 0
    row.LayoutOrder = elementOrder
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = t.textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 2
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.55, -10, 1, 0)
    val.Position = UDim2.new(0.45, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = valueText
    val.TextColor3 = t.text
    val.Font = Enum.Font.GothamBold
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 2
    val.Parent = row

    table.insert(allUIThemed, {obj=lbl, prop="TextColor3", themeKey="textDim"})
    table.insert(allUIThemed, {obj=val, prop="TextColor3", themeKey="text"})

    return row
end

local function addDropdown(page, text, options, onSelect, langKey)
    -- If options is a string (key), resolve it to a table
    if type(options) == "string" then
        local resolved = {}
        if options == "CurrentTheme" then
            resolved = {"Nebula", "Crimson", "Emerald", "Sakura", "Arctic", "Gold"}
        elseif options == "CurrentLang" then
            resolved = {"VI", "EN"}
        elseif options == "SpectateTarget" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then table.insert(resolved, p.Name) end
            end
            if #resolved == 0 then resolved = {"None"} end
        else
            resolved = {options}
        end
        options = resolved
    end
    elementOrder = elementOrder + 1
    local t = theme()

    local container = Instance.new("Frame")
    container.Name = langKey or "Dropdown"
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = t.card
    container.BackgroundTransparency = 0.6
    container.BorderSizePixel = 0
    container.LayoutOrder = elementOrder
    container.ClipsDescendants = true
    container.Parent = page
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.Text = text .. ": " .. (options[1] or "")
    btn.TextColor3 = t.text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    btn.Parent = container
    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 12)
    btnPad.Parent = btn

    local dropList = Instance.new("Frame")
    dropList.Size = UDim2.new(1, 0, 0, #options * 30)
    dropList.Position = UDim2.new(0, 0, 0, 36)
    dropList.BackgroundColor3 = t.card
    dropList.BorderSizePixel = 0
    dropList.Visible = false
    dropList.ZIndex = 5
    dropList.ClipsDescendants = true
    dropList.Parent = container
    Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 8)
    local dropLayout = Instance.new("UIListLayout")
    dropLayout.Padding = UDim.new(0, 2)
    dropLayout.Parent = dropList

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = opt
        optBtn.TextColor3 = t.text
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 6
        optBtn.Parent = dropList
        local optPad = Instance.new("UIPadding")
        optPad.PaddingLeft = UDim.new(0, 16)
        optPad.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            dropList.Visible = false
            container.Size = UDim2.new(1, 0, 0, 36)
            if onSelect then pcall(function() onSelect(opt) end) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        dropList.Visible = not dropList.Visible
        if dropList.Visible then
            container.Size = UDim2.new(1, 0, 0, 36 + #options * 30 + 4)
            container.ZIndex = 20
        else
            container.Size = UDim2.new(1, 0, 0, 36)
            container.ZIndex = 10
        end
    end)

    table.insert(allUIThemed, {obj=container, prop="BackgroundColor3", themeKey="card"})

    return container
end

-- Key Input
local function addKeyInput(page, label, onSubmit)
    elementOrder = elementOrder + 1
    local t = theme()

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = t.card
    container.BackgroundTransparency = 0.6
    container.BorderSizePixel = 0
    container.LayoutOrder = elementOrder
    container.Parent = page
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    local inputLabel = Instance.new("TextLabel")
    inputLabel.Size = UDim2.new(0, 80, 0, 28)
    inputLabel.Position = UDim2.new(0, 8, 0.5, -14)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = label or T("EnterKey")
    inputLabel.TextColor3 = t.text
    inputLabel.Font = Enum.Font.Gotham
    inputLabel.TextSize = 12
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -170, 0, 28)
    input.Position = UDim2.new(0, 88, 0.5, -14)
    input.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    input.BackgroundTransparency = 0.3
    input.PlaceholderText = T("KeyPlaceholder")
    input.Text = ""
    input.TextColor3 = t.text
    input.PlaceholderColor3 = t.textDim
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.ClearTextOnFocus = false
    input.ZIndex = 2
    input.Parent = container
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 70, 0, 28)
    submitBtn.Position = UDim2.new(1, -78, 0.5, -14)
    submitBtn.BackgroundColor3 = t.accent
    submitBtn.BackgroundTransparency = 0.3
    submitBtn.Text = T("KeySubmit")
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 12
    submitBtn.AutoButtonColor = false
    submitBtn.ZIndex = 2
    submitBtn.Parent = container
    Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 6)

    local function submitKey()
        if keyAuthenticated then
            notify(T("KeySystem"), T("KeyAlready"), 3, "info")
            return
        end
        local val = input.Text
        if onSubmit then
            pcall(function() onSubmit(val) end)
        elseif val == VALID_KEY then
            keyAuthenticated = true
            keyStatusLabel.Visible = false
            notify(T("KeySystem"), T("KeyCorrect"), 3, "success")
        else
            notify(T("KeySystem"), T("KeyWrong"), 3, "error")
        end
    end

    submitBtn.MouseButton1Click:Connect(submitKey)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then submitKey() end
    end)

    return container
end

-- ============================================================
-- THEME & LANGUAGE UPDATE FUNCTIONS
-- ============================================================
local function updateAllThemes()
    pcall(function()
        local t = theme()
        mainFrame.BackgroundColor3 = t.bg
        mainBorder.Color = t.border
        sidebar.BackgroundColor3 = t.sidebar
        sideBorder.Color = t.border
        topBar.BackgroundColor3 = t.sidebar
        titleLabel.TextColor3 = t.accent
        closeBtn.TextColor3 = t.textDim
        miniBtn.BackgroundColor3 = t.accent
        fpsLabel.TextColor3 = t.success
        keyStatusLabel.BackgroundColor3 = t.danger
        for btnName, btn in pairs(tabButtons) do
            local active = (btnName == currentTab)
            btn.BackgroundColor3 = active and t.tabActive or t.tabInactive
            btn.TextColor3 = active and t.text or t.textDim
            local ab = btn:FindFirstChild("ActiveBorder")
            if ab then ab.BackgroundColor3 = t.accent end
        end
        if fovStroke then fovStroke.Color = t.accent end
        if radarStroke then radarStroke.Color = t.accent end
        for _, entry in ipairs(allUIThemed) do
            pcall(function()
                if entry.obj and entry.obj.Parent then
                    local val = t[entry.themeKey]
                    if val then entry.obj[entry.prop] = val end
                end
            end)
        end
    end)
end

local function updateAllLanguages()
    pcall(function()
        -- Update all text labels that use T() - simplified approach
        -- Just update key elements
        titleLabel.Text = SCRIPT_NAME .. " " .. SCRIPT_VERSION
        keyStatusLabel.Text = "⚠ KEY REQUIRED - " .. T("KeyRequired")
        playerCountLabel.Text = T("PlayersOnline") .. ": " .. tostring(#Players:GetPlayers())
    end)
end

-- ============================================================
-- ESP SYSTEM - Fixed & Optimized
-- Throttle: Only updates every ESPRefreshRate seconds
-- Checks: Dead players, team, auto-cleanup
-- ============================================================
local espLastUpdate = 0

local function isPlayerAlive(tgt)
    if not tgt.Character then return false end
    local hum = tgt.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local hrp = tgt.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return true
end

local function isSameTeam(tgt)
    if not States.TeamColors then return false end
    if player.Team and tgt.Team then
        return player.Team == tgt.Team
    end
    return false
end

local function getTeamColor(tgt)
    if tgt.Team and tgt.TeamColor then
        return tgt.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local function cleanupAllESP()
    pcall(function()
        for _, tgt in ipairs(Players:GetPlayers()) do
            if tgt.Character then
                for _, name in ipairs({"FLUYEN_ESP", "FLUYEN_Box", "FLUYEN_Cham", "FLUYEN_Skeleton"}) do
                    local obj = tgt.Character:FindFirstChild(name)
                    if obj then obj:Destroy() end
                end
                if tgt.Character:FindFirstChild("Head") then
                    for _, name in ipairs({"FLUYEN_Name", "FLUYEN_Health", "FLUYEN_Dist", "FLUYEN_HeadDot"}) do
                        local obj = tgt.Character.Head:FindFirstChild(name)
                        if obj then obj:Destroy() end
                    end
                end
            end
        end
    end)
    hideAllTracers()
end

-- Track player leaving for cleanup
Players.PlayerRemoving:Connect(function(tgt)
    pcall(function()
        if tgt.Character then
            for _, name in ipairs({"FLUYEN_ESP", "FLUYEN_Box", "FLUYEN_Cham", "FLUYEN_Skeleton"}) do
                local obj = tgt.Character:FindFirstChild(name)
                if obj then obj:Destroy() end
            end
        end
    end)
end)

-- ============================================================
-- SKELETON ESP - Bone rendering with Line objects
-- ============================================================
local SKELETON_BONES = {
    {"Head", "Neck"},
    {"Neck", "LeftUpperArm"},
    {"Neck", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"Neck", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
}

local function createSkeletonForPlayer(tgt)
    if not tgt.Character then return end
    local old = tgt.Character:FindFirstChild("FLUYEN_Skeleton")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "FLUYEN_Skeleton"
    folder.Parent = tgt.Character

    for _, bonePair in ipairs(SKELETON_BONES) do
        local part1 = tgt.Character:FindFirstChild(bonePair[1])
        local part2 = tgt.Character:FindFirstChild(bonePair[2])
        if part1 and part2 then
            local adornment = Instance.new("LineHandleAdornment")
            adornment.Name = "Bone_" .. bonePair[1] .. "_" .. bonePair[2]
            adornment.Adornee = part1
            adornment.RelativeTo = Enum.RelativeTo.World
            adornment.CFrame = part1.CFrame
            -- Store references for updating
            adornment.Parent = folder
        end
    end
end

-- Update skeleton positions each frame (in ESP loop)
local function updateSkeletonForPlayer(tgt)
    if not tgt.Character then return end
    local folder = tgt.Character:FindFirstChild("FLUYEN_Skeleton")
    if not folder then
        createSkeletonForPlayer(tgt)
        return
    end

    for _, bonePair in ipairs(SKELETON_BONES) do
        local part1 = tgt.Character:FindFirstChild(bonePair[1])
        local part2 = tgt.Character:FindFirstChild(bonePair[2])
        local adornment = folder:FindFirstChild("Bone_" .. bonePair[1] .. "_" .. bonePair[2])
        if adornment and part1 and part2 then
            -- Draw line from part1 to part2 using Beam (better than LineHandleAdornment for this)
            -- Actually LineHandleAdornment only draws from its CFrame relative to Adornee
            -- We need a different approach for skeleton - use BillboardGui lines
            -- Let's use a simpler approach: recalculate every update
        elseif not adornment and part1 and part2 then
            -- Recreate missing bone
            local ad = Instance.new("LineHandleAdornment")
            ad.Name = "Bone_" .. bonePair[1] .. "_" .. bonePair[2]
            ad.Adornee = part1
            ad.RelativeTo = Enum.RelativeTo.World
            ad.CFrame = part1.CFrame
            ad.Parent = folder
        end
    end
end

-- Simplified skeleton: Draw on ScreenGui with lines (similar to tracers but for bones)
-- We'll draw bone lines in the ESP loop using a 2D approach
local SKELETON_POOL_SIZE = 60  -- 60 lines max for skeletons (6 players * ~10 bones)
local skeletonPool = {}
local skeletonContainer = Instance.new("Frame")
skeletonContainer.Name = "SkeletonLines"
skeletonContainer.Size = UDim2.new(1, 0, 1, 0)
skeletonContainer.BackgroundTransparency = 1
skeletonContainer.ZIndex = 47
skeletonContainer.Parent = espGui

for i = 1, SKELETON_POOL_SIZE do
    local line = Instance.new("Frame")
    line.Name = "SkLine_" .. i
    line.Size = UDim2.new(0, 1, 0, 1.5)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 1
    line.ZIndex = 47
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.Parent = skeletonContainer
    table.insert(skeletonPool, line)
end

local function hideAllSkeletonLines()
    for _, line in ipairs(skeletonPool) do
        line.Visible = false
        line.BackgroundTransparency = 1
    end
end

local function drawSkeletonLine(idx, x1, y1, x2, y2, color)
    if idx > SKELETON_POOL_SIZE then return end
    local line = skeletonPool[idx]
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 2 then
        line.Visible = false
        return
    end
    local midX = (x1 + x2) / 2
    local midY = (y1 + y2) / 2
    local angle = math.deg(math.atan2(dy, dx))
    line.Size = UDim2.new(0, length, 0, 1.5)
    line.Position = UDim2.new(0, midX, 0, midY)
    line.Rotation = angle
    line.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    line.BackgroundTransparency = 0.2
    line.Visible = true
end

-- ============================================================
-- QUICK HUD - Shows active features on screen
-- ============================================================
local function updateQuickHUD()
    if not States.QuickHUD then
        quickHUD.Visible = false
        return
    end
    quickHUD.Visible = true

    -- Clear existing
    for _, child in ipairs(quickHUD:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local t = theme()
    local order = 0
    local featureList = {
        {key="ESP", name="ESP"},
        {key="BoxESP", name="Box"},
        {key="NameESP", name="Name"},
        {key="HealthESP", name="HP"},
        {key="DistanceESP", name="Dist"},
        {key="Tracers", name="Tracer"},
        {key="Chams", name="Chams"},
        {key="SkeletonESP", name="Skeleton"},
        {key="HeadDot", name="HeadDot"},
        {key="Aim", name="Aim"},
        {key="SilentAim", name="Silent"},
        {key="TriggerBot", name="Trigger"},
        {key="HitboxExpander", name="Hitbox"},
        {key="KillAura", name="KillAura"},
        {key="Speed", name="Speed"},
        {key="Fly", name="Fly"},
        {key="Noclip", name="Noclip"},
        {key="JumpPower", name="Jump"},
        {key="InfiniteJump", name="InfJump"},
        {key="Sprint", name="Sprint"},
        {key="AntiVoid", name="AntiVoid"},
        {key="AntiFling", name="AntiFling"},
        {key="NightVision", name="NV"},
        {key="Xray", name="Xray"},
        {key="Crosshair", name="Cross"},
        {key="Radar", name="Radar"},
        {key="Spin", name="Spin"},
        {key="Float", name="Float"},
        {key="Bhop", name="Bhop"},
        {key="LongJump", name="LJ"},
    }

    for _, feat in ipairs(featureList) do
        if States[feat.key] then
            order = order + 1
            local pill = Instance.new("Frame")
            pill.Name = "HUD_" .. feat.key
            pill.Size = UDim2.new(0, 70, 0, 20)
            pill.BackgroundColor3 = t.accent
            pill.BackgroundTransparency = 0.4
            pill.BorderSizePixel = 0
            pill.LayoutOrder = order
            pill.ZIndex = 46
            pill.Parent = quickHUD
            Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = "● " .. feat.name
            txt.TextColor3 = Color3.fromRGB(255, 255, 255)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 9
            txt.ZIndex = 47
            txt.Parent = pill
        end
    end
end

-- ESP Main Loop (throttled)
setConn("ESPMainLoop", RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - espLastUpdate < Values.ESPRefreshRate then return end
    espLastUpdate = now

    pcall(function()
        -- FOV Circle
        fovCircle.Visible = States.AimFOV
        if States.AimFOV then
            local fovSize = Values.AimFOVValue * 2
            fovCircle.Size = UDim2.new(0, fovSize, 0, fovSize)
            fovCircle.Position = UDim2.new(0.5, -Values.AimFOVValue, 0.5, -Values.AimFOVValue)
        end

        -- Player count
        playerCountLabel.Text = T("PlayersOnline") .. ": " .. tostring(#Players:GetPlayers())

        -- Crosshair
        crosshairContainer.Visible = States.Crosshair

        -- Radar
        radarFrame.Visible = States.Radar
        if States.Radar then
            radarFrame.Size = UDim2.new(0, Values.RadarSize, 0, Values.RadarSize)
            radarFrame.Position = UDim2.new(1, -Values.RadarSize - 10, 1, -Values.RadarSize - 10)
            for _, child in ipairs(radarDotsContainer:GetChildren()) do
                if child.Name == "RadarDot" then child:Destroy() end
            end
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local myPos = player.Character.HumanoidRootPart.Position
                local radarHalf = Values.RadarSize / 2
                for _, tgt in ipairs(getCachedPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                        local tgtPos = tgt.Character.HumanoidRootPart.Position
                        local diff = tgtPos - myPos
                        local dist = diff.Magnitude
                        if dist <= Values.RadarRange then
                            local dotX = (diff.X / Values.RadarRange) * radarHalf + radarHalf
                            local dotZ = (diff.Z / Values.RadarRange) * radarHalf + radarHalf
                            local dot = Instance.new("Frame")
                            dot.Name = "RadarDot"
                            dot.Size = UDim2.new(0, 5, 0, 5)
                            dot.Position = UDim2.new(0, dotX - 2.5, 0, dotZ - 2.5)
                            dot.BackgroundColor3 = isSameTeam(tgt) and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
                            dot.BorderSizePixel = 0
                            dot.ZIndex = 51
                            dot.Parent = radarDotsContainer
                            Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 3)
                        end
                    end
                end
            end
        end

        -- Camera FOV sync
        if States.Aim or States.SilentAim then
            Camera.FieldOfView = Values.FieldOfView
        end

        -- ESP Processing for each player
        for _, tgt in ipairs(getCachedPlayers()) do
            if tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") and tgt.Character:FindFirstChild("Head") then
                local alive = isPlayerAlive(tgt)
                local _, onScreen = Camera:WorldToViewportPoint(tgt.Character.HumanoidRootPart.Position)
                local isTeam = isSameTeam(tgt)

                -- ESP Highlight
                if States.ESP and alive and onScreen then
                    local highlight = tgt.Character:FindFirstChild("FLUYEN_ESP")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "FLUYEN_ESP"
                        highlight.FillTransparency = 0.6
                        highlight.OutlineTransparency = 0
                        highlight.FillColor = isTeam and getTeamColor(tgt) or Color3.fromRGB(255, 60, 60)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = tgt.Character
                    end
                    highlight.FillColor = States.TeamColors and getTeamColor(tgt) or Color3.fromRGB(255, 60, 60)
                else
                    local hl = tgt.Character:FindFirstChild("FLUYEN_ESP")
                    if hl then hl:Destroy() end
                end

                -- Box ESP
                if States.BoxESP and alive and onScreen then
                    local box = tgt.Character:FindFirstChild("FLUYEN_Box")
                    if not box then
                        box = Instance.new("BoxHandleAdornment")
                        box.Name = "FLUYEN_Box"
                        box.Color3 = isTeam and getTeamColor(tgt) or Color3.fromRGB(255, 60, 60)
                        box.Transparency = 0.7
                        box.Size = Vector3.new(4, 5, 1)
                        box.Adornee = tgt.Character
                        box.AlwaysOnTop = true
                        box.ZIndex = 5
                        box.Parent = tgt.Character
                    end
                    box.Color3 = States.TeamColors and getTeamColor(tgt) or Color3.fromRGB(255, 60, 60)
                else
                    local b = tgt.Character:FindFirstChild("FLUYEN_Box")
                    if b then b:Destroy() end
                end

                -- Chams
                if States.Chams and alive then
                    local hl = tgt.Character:FindFirstChild("FLUYEN_Cham")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "FLUYEN_Cham"
                        hl.FillTransparency = 0.2
                        hl.OutlineTransparency = 0
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Parent = tgt.Character
                    end
                else
                    local hl = tgt.Character:FindFirstChild("FLUYEN_Cham")
                    if hl then hl:Destroy() end
                end

                -- Name ESP
                if States.NameESP and alive and onScreen then
                    local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Name")
                    if not gui then
                        gui = Instance.new("BillboardGui")
                        gui.Name = "FLUYEN_Name"
                        gui.Size = UDim2.new(0, 120, 0, 22)
                        gui.StudsOffset = Vector3.new(0, 3, 0)
                        gui.AlwaysOnTop = true
                        gui.Parent = tgt.Character.Head
                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.Text = tgt.Name
                        txt.TextColor3 = Color3.fromRGB(255,255,255)
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 13
                        txt.TextStrokeTransparency = 0.5
                        txt.Parent = gui
                    end
                else
                    local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Name")
                    if gui then gui:Destroy() end
                end

                -- Health ESP
                if States.HealthESP and alive and onScreen then
                    local hum = tgt.Character:FindFirstChild("Humanoid")
                    local head = tgt.Character.Head
                    local gui = head:FindFirstChild("FLUYEN_Health")
                    if not gui and hum then
                        gui = Instance.new("BillboardGui")
                        gui.Name = "FLUYEN_Health"
                        gui.Size = UDim2.new(0, 100, 0, 8)
                        gui.StudsOffset = Vector3.new(0, 4.5, 0)
                        gui.AlwaysOnTop = true
                        gui.Parent = head
                        local bg = Instance.new("Frame")
                        bg.Size = UDim2.new(1,0,1,0)
                        bg.BackgroundColor3 = Color3.fromRGB(30,30,30)
                        bg.BorderSizePixel = 0
                        bg.Parent = gui
                        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,4)
                        local fill = Instance.new("Frame")
                        fill.Name = "HPFill"
                        fill.Size = UDim2.new(1,0,1,0)
                        fill.BackgroundColor3 = Color3.fromRGB(0,255,0)
                        fill.BorderSizePixel = 0
                        fill.Parent = gui
                        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)
                    end
                    if gui and hum then
                        local fill = gui:FindFirstChild("HPFill")
                        if fill then
                            local hp = math.max(0, math.min(hum.Health / math.max(hum.MaxHealth, 1), 1))
                            fill.Size = UDim2.new(hp, 0, 1, 0)
                            fill.BackgroundColor3 = Color3.new(1-hp, hp, 0)
                        end
                    end
                else
                    local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Health")
                    if gui then gui:Destroy() end
                end

                -- Distance ESP
                if States.DistanceESP and alive and onScreen and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local head = tgt.Character.Head
                    local dist = (tgt.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    local gui = head:FindFirstChild("FLUYEN_Dist")
                    if not gui then
                        gui = Instance.new("BillboardGui")
                        gui.Name = "FLUYEN_Dist"
                        gui.Size = UDim2.new(0, 80, 0, 16)
                        gui.StudsOffset = Vector3.new(0, 6, 0)
                        gui.AlwaysOnTop = true
                        gui.Parent = head
                        local txt = Instance.new("TextLabel")
                        txt.Name = "DistText"
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.fromRGB(255,200,50)
                        txt.Font = Enum.Font.Gotham
                        txt.TextSize = 11
                        txt.TextStrokeTransparency = 0.5
                        txt.Parent = gui
                    end
                    local dt = gui:FindFirstChild("DistText")
                    if dt then dt.Text = math.floor(dist) .. "m" end
                else
                    local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Dist")
                    if gui then gui:Destroy() end
                end

                -- Head Dot
                if States.HeadDot and alive and onScreen then
                    local dot = tgt.Character.Head:FindFirstChild("FLUYEN_HeadDot")
                    if not dot then
                        dot = Instance.new("BillboardGui")
                        dot.Name = "FLUYEN_HeadDot"
                        dot.Size = UDim2.new(0, 12, 0, 12)
                        dot.StudsOffset = Vector3.new(0, 0, 0)
                        dot.AlwaysOnTop = true
                        dot.Parent = tgt.Character.Head
                        local circle = Instance.new("Frame")
                        circle.Size = UDim2.new(1,0,1,0)
                        circle.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                        circle.BorderSizePixel = 0
                        circle.Parent = dot
                        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
                    end
                else
                    local dot = tgt.Character.Head:FindFirstChild("FLUYEN_HeadDot")
                    if dot then dot:Destroy() end
                end
            end
        end
    end)
end))

-- Tracer Rendering (every frame, using pooled lines)
setConn("TracerRender", RunService.RenderStepped:Connect(function()
    hideAllTracers()
    if not States.Tracers then return end
    pcall(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local screenBottomX = Camera.ViewportSize.X / 2
        local screenBottomY = Camera.ViewportSize.Y
        local idx = 0
        for _, tgt in ipairs(getCachedPlayers()) do
            if tgt.Character and tgt.Character:FindFirstChild("Head") and isPlayerAlive(tgt) then
                local headPos, onScreen = Camera:WorldToViewportPoint(tgt.Character.Head.Position)
                if onScreen then
                    idx = idx + 1
                    local col = States.TeamColors and getTeamColor(tgt) or Color3.fromRGB(120, 80, 255)
                    drawPooledTracer(idx, screenBottomX, screenBottomY, headPos.X, headPos.Y, col)
                end
            end
        end
    end)
end))

-- Skeleton ESP Rendering (every frame, using pooled lines)
setConn("SkeletonRender", RunService.RenderStepped:Connect(function()
    hideAllSkeletonLines()
    if not States.SkeletonESP then return end
    pcall(function()
        local idx = 0
        for _, tgt in ipairs(getCachedPlayers()) do
            if tgt.Character and isPlayerAlive(tgt) then
                local _, onScreen = Camera:WorldToViewportPoint(tgt.Character.HumanoidRootPart.Position)
                if onScreen then
                    local col = States.TeamColors and getTeamColor(tgt) or Color3.fromRGB(255, 255, 255)
                    for _, bonePair in ipairs(SKELETON_BONES) do
                        local part1 = tgt.Character:FindFirstChild(bonePair[1])
                        local part2 = tgt.Character:FindFirstChild(bonePair[2])
                        if part1 and part2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                            if vis1 or vis2 then
                                idx = idx + 1
                                drawSkeletonLine(idx, pos1.X, pos1.Y, pos2.X, pos2.Y, col)
                            end
                        end
                    end
                end
            end
        end
    end)
end))

-- Quick HUD update (every second)
setConn("QuickHUDLoop", RunService.RenderStepped:Connect(function()
    -- Only update every ~1 second
    local now = tick()
    if now - (espLastUpdate or 0) < 1 then return end
    updateQuickHUD()
end))

-- FPS Counter
local fpsFrames = 0
local fpsLastTime = tick()
local fpsValue = 60

setConn("FPSCounter", RunService.RenderStepped:Connect(function()
    fpsFrames = fpsFrames + 1
    local now = tick()
    if now - fpsLastTime >= 1 then
        fpsValue = fpsFrames
        fpsFrames = 0
        fpsLastTime = now
        fpsLabel.Text = "FPS: " .. tostring(fpsValue)
        fpsLabel.TextColor3 = fpsValue >= 50 and Color3.fromRGB(80,255,120) or fpsValue >= 30 and Color3.fromRGB(255,200,60) or Color3.fromRGB(255,80,80)
        fpsLabel.Visible = States.FPSCounter
    end
end))

-- ============================================================
-- NIGHTVISION & XRAY - Dynamic start/stop
-- ============================================================
local nightVisionActive = false
local xrayActive = false

local function startNightVision()
    if nightVisionActive then return end
    nightVisionActive = true
    killConn("NightVisionLoop")
    setConn("NightVisionLoop", RunService.RenderStepped:Connect(function()
        if not States.NightVision then
            killConn("NightVisionLoop")
            nightVisionActive = false
            pcall(function()
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.fromRGB(0,0,0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
            end)
            return
        end
        pcall(function()
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(100,255,100)
            Lighting.OutdoorAmbient = Color3.fromRGB(100,255,100)
        end)
    end))
end

local function stopNightVision()
    nightVisionActive = false
    killConn("NightVisionLoop")
    pcall(function()
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(0,0,0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    end)
end

local xrayCache = {}
local function startXray()
    if xrayActive then return end
    xrayActive = true
    killConn("XrayLoop")
    setConn("XrayLoop", RunService.RenderStepped:Connect(function()
        if not States.Xray then
            killConn("XrayLoop")
            xrayActive = false
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.LocalTransparencyModifier = 0
                    end
                end
            end)
            return
        end
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                    obj.LocalTransparencyModifier = 0.6
                end
            end
        end)
    end))
end

local function stopXray()
    xrayActive = false
    killConn("XrayLoop")
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 0
            end
        end
    end)
end

-- ============================================================
-- POPULATE TABS
-- ============================================================

-- HOME TAB
do
    local p = pages["Home"]
    addSection(p, SCRIPT_NAME .. " " .. SCRIPT_VERSION, nil)
    addInfoRow(p, T("ScriptName"), SCRIPT_NAME, "ScriptName")
    addInfoRow(p, T("Version"), SCRIPT_VERSION, "Version")
    addInfoRow(p, T("Username"), player.Name, "Username")
    addInfoRow(p, T("Executor"), "Delta Universal", "Executor")
    addInfoRow(p, T("Credits"), SCRIPT_AUTHOR, "Credits")
    addSection(p, T("Changelog"), "Changelog")
    addInfoRow(p, "v6.1", "Skeleton ESP, Quick HUD, Tracer Pool, NV/Xray fix")
    addInfoRow(p, "v6.0", "Complete redesign, ESP fix, Key fix, new features")
    addInfoRow(p, "v5.0", "Key system, ESP Lines, FOV Circle, fixes")
end

-- VISUAL TAB
do
    local p = pages["Visual"]
    addSection(p, T("ESP"), "ESP")

    addToggle(p, T("ESP"), "ESP", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local hl = tgt.Character:FindFirstChild("FLUYEN_ESP")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        end
    end, "ESP")

    addToggle(p, T("BoxESP"), "BoxESP", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local b = tgt.Character:FindFirstChild("FLUYEN_Box")
                        if b then b:Destroy() end
                    end
                end
            end)
        end
    end, "BoxESP")

    addToggle(p, T("NameESP"), "NameESP", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Name")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end, "NameESP")

    addToggle(p, T("HealthESP"), "HealthESP", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Health")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end, "HealthESP")

    addToggle(p, T("DistanceESP"), "DistanceESP", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Dist")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end, "DistanceESP")

    addToggle(p, T("Tracers"), "Tracers", function(v)
        if not v then hideAllTracers() end
    end, "Tracers")

    addToggle(p, T("Chams"), "Chams", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local hl = tgt.Character:FindFirstChild("FLUYEN_Cham")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        end
    end, "Chams")

    addToggle(p, T("SkeletonESP"), "SkeletonESP", function(v)
        if not v then hideAllSkeletonLines() end
    end, "SkeletonESP")

    addToggle(p, T("HeadDot"), "HeadDot", function(v)
        if not v then
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local dot = tgt.Character.Head:FindFirstChild("FLUYEN_HeadDot")
                        if dot then dot:Destroy() end
                    end
                end
            end)
        end
    end, "HeadDot")

    addToggle(p, T("TeamColors"), "TeamColors", nil, "TeamColors")

    addSection(p, T("ESPRefreshRate"), "ESPRefreshRate")
    addSlider(p, T("ESPRefreshRate"), "ESPRefreshRate", 0.01, 0.2, true, nil, "ESPRefreshRate")

    addSection(p, T("FullBright"), "FullBright")
    addToggle(p, T("FullBright"), "FullBright", function(v)
        if v then
            pcall(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
            end)
        else
            pcall(function()
                Lighting.Brightness = 1
            end)
        end
    end, "FullBright")

    addToggle(p, T("NightVision"), "NightVision", function(v)
        if v then startNightVision() else stopNightVision() end
    end, "NightVision")

    addToggle(p, T("Xray"), "Xray", function(v)
        if v then startXray() else stopXray() end
    end, "Xray")
end

-- COMBAT TAB
do
    local p = pages["Combat"]
    addSection(p, T("Aim"), "Aim")

    addToggle(p, T("Aim"), "Aim", function(v)
        killConn("Aim")
        if v then
            setConn("Aim", RunService.RenderStepped:Connect(function()
                if not States.Aim then killConn("Aim") return end
                pcall(function()
                    local closest = nil
                    local minDist = Values.AimFOVValue
                    for _, tgt in ipairs(getCachedPlayers()) do
                        if isPlayerAlive(tgt) and tgt.Character:FindFirstChild("Head") then
                            local head = tgt.Character.Head
                            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                            if onScreen and not isSameTeam(tgt) then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = head
                                end
                            end
                        end
                    end
                    if closest then
                        local smoothness = math.max(1, Values.AimSmoothness)
                        local currentCFrame = Camera.CFrame
                        local targetPos = closest.Position
                        if States.AimPrediction and closest.Parent and closest.Parent:FindFirstChild("HumanoidRootPart") then
                            local hrp = closest.Parent.HumanoidRootPart
                            local velocity = hrp.Velocity
                            local distToTarget = (closest.Position - currentCFrame.Position).Magnitude
                            local bulletTime = distToTarget / 3000
                            targetPos = targetPos + velocity * bulletTime
                        end
                        local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                        Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothness)
                    end
                end)
            end))
        end
    end, "Aim")

    addToggle(p, T("SilentAim"), "SilentAim", function(v)
        killConn("SilentAim")
        if v then
            setConn("SilentAim", RunService.RenderStepped:Connect(function()
                if not States.SilentAim then killConn("SilentAim") return end
                pcall(function()
                    local mouse = player:GetMouse()
                    if not mouse then return end
                    local closestChar = nil
                    local minDist = Values.AimFOVValue
                    local mousePos = Vector2.new(mouse.X, mouse.Y)
                    for _, tgt in ipairs(getCachedPlayers()) do
                        if isPlayerAlive(tgt) and tgt.Character:FindFirstChild("Head") and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(tgt.Character.Head.Position)
                            if onScreen and not isSameTeam(tgt) then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closestChar = tgt.Character
                                end
                            end
                        end
                    end
                    if closestChar then
                        _G.FLUYEN_SilentTarget = closestChar.Head
                    else
                        _G.FLUYEN_SilentTarget = nil
                    end
                end)
            end))
        else
            _G.FLUYEN_SilentTarget = nil
        end
    end, "SilentAim")

    addToggle(p, T("AimFOV"), "AimFOV", function(v)
        fovCircle.Visible = v
    end, "AimFOV")

    addToggle(p, T("AimPrediction"), "AimPrediction", function(v)
        notify(T("AimPrediction"), v and T("Enabled") or T("Disabled"), 2, v and "success" or "warning")
    end, "AimPrediction")

    addToggle(p, T("TriggerBot"), "TriggerBot", function(v)
        killConn("TriggerBot")
        if v then
            setConn("TriggerBot", RunService.RenderStepped:Connect(function()
                if not States.TriggerBot then killConn("TriggerBot") return end
                pcall(function()
                    local mouse = player:GetMouse()
                    if mouse.Target and mouse.Target.Parent then
                        local targetPlayer = Players:GetPlayerFromCharacter(mouse.Target.Parent)
                        if targetPlayer and targetPlayer ~= player and not isSameTeam(targetPlayer) then
                            pcall(function() mouse1click() end)
                        end
                    end
                end)
            end))
        end
    end, "TriggerBot")

    addToggle(p, T("HitboxExpander"), "HitboxExpander", function(v)
        killConn("HitboxExpander")
        if v then
            setConn("HitboxExpander", RunService.RenderStepped:Connect(function()
                if not States.HitboxExpander then killConn("HitboxExpander") return end
                pcall(function()
                    for _, tgt in ipairs(getCachedPlayers()) do
                        if isPlayerAlive(tgt) and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = tgt.Character.HumanoidRootPart
                            hrp.Size = Vector3.new(Values.HitboxSize, Values.HitboxSize, Values.HitboxSize)
                            hrp.Transparency = 0.5
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(getCachedPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                        tgt.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                        tgt.Character.HumanoidRootPart.Transparency = 0
                    end
                end
            end)
        end
    end, "HitboxExpander")

    addToggle(p, T("Crosshair"), "Crosshair", function(v)
        crosshairContainer.Visible = v
    end, "Crosshair")

    addToggle(p, T("KillAura"), "KillAura", function(v)
        killConn("KillAura")
        if v then
            setConn("KillAura", RunService.RenderStepped:Connect(function()
                if not States.KillAura then killConn("KillAura") return end
                pcall(function()
                    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
                    local myPos = player.Character.HumanoidRootPart.Position
                    for _, tgt in ipairs(getCachedPlayers()) do
                        if isPlayerAlive(tgt) and tgt.Character:FindFirstChild("HumanoidRootPart") and tgt.Character:FindFirstChild("Humanoid") then
                            if not isSameTeam(tgt) then
                                local dist = (tgt.Character.HumanoidRootPart.Position - myPos).Magnitude
                                if dist <= Values.KillAuraRange then
                                    tgt.Character.Humanoid:TakeDamage(Values.KillAuraDamage)
                                end
                            end
                        end
                    end
                end)
            end))
        end
    end, "KillAura")

    addSection(p, T("AimFOVValue"), "AimFOVValue")
    addSlider(p, T("AimFOVValue"), "AimFOVValue", 30, 360, false, nil, "AimFOVValue")
    addSlider(p, T("AimSmoothness"), "AimSmoothness", 1, 100, false, nil, "AimSmoothness")
    addSlider(p, T("HitboxSize"), "HitboxSize", 2, 50, false, nil, "HitboxSize")
    addSlider(p, T("KillAuraRange"), "KillAuraRange", 5, 50, false, nil, "KillAuraRange")
    addSlider(p, T("KillAuraDamage"), "KillAuraDamage", 1, 100, false, nil, "KillAuraDamage")
    addSlider(p, T("CrosshairSize"), "CrosshairSize", 2, 15, false, function(val)
        for _, part in ipairs(chParts) do
            if part.Rotation == 0 then
                part.Size = UDim2.new(0, 2, 0, val)
            else
                part.Size = UDim2.new(0, 2, 0, val)
            end
        end
    end, "CrosshairSize")
    addSlider(p, T("CrosshairGap"), "CrosshairGap", 0, 10, false, function(val)
        for i, part in ipairs(chParts) do
            local dir = {{1,0},{-1,0},{0,1},{0,-1}}
            part.Position = UDim2.new(0.5, dir[i][1] * (val + 1) - 1, 0.5, dir[i][2] * (val + 1) - Values.CrosshairSize/2)
        end
    end, "CrosshairGap")
    addSection(p, T("FieldOfView"), "FieldOfView")
    addSlider(p, T("FieldOfView"), "FieldOfView", 30, 120, false, function(val)
        if States.Aim or States.SilentAim then Camera.FieldOfView = val end
    end, "FieldOfView")
end

-- MOVEMENT TAB
do
    local p = pages["Movement"]
    addSection(p, T("Speed"), "Speed")
    addToggle(p, T("Speed"), "Speed", function(v)
        killConn("Speed")
        if v then
            setConn("Speed", RunService.RenderStepped:Connect(function()
                if not States.Speed then killConn("Speed") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid.WalkSpeed = Values.SpeedValue
                    end
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = 16
                end
            end)
        end
    end, "Speed")
    addSlider(p, T("SpeedValue"), "SpeedValue", 16, 200, false, nil, "SpeedValue")

    addSection(p, T("Fly"), "Fly")
    addToggle(p, T("Fly"), "Fly", function(v)
        killConn("Fly")
        if v then
            setConn("Fly", RunService.RenderStepped:Connect(function()
                if not States.Fly then killConn("Fly") return end
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = char.HumanoidRootPart
                    local bodyV = hrp:FindFirstChild("FLUYEN_FlyBV")
                    if not bodyV then
                        bodyV = Instance.new("BodyVelocity")
                        bodyV.Name = "FLUYEN_FlyBV"
                        bodyV.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                        bodyV.Velocity = Vector3.new(0,0,0)
                        bodyV.Parent = hrp
                        local gyro = hrp:FindFirstChild("FLUYEN_FlyGyro")
                        if not gyro then
                            gyro = Instance.new("BodyGyro")
                            gyro.Name = "FLUYEN_FlyGyro"
                            gyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
                            gyro.P = 9000
                            gyro.Parent = hrp
                        end
                    end
                    local moveDir = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
                    bodyV.Velocity = moveDir * Values.FlySpeed
                    local gyro = hrp:FindFirstChild("FLUYEN_FlyGyro")
                    if gyro then gyro.CFrame = Camera.CFrame end
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local bv = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FlyBV")
                    if bv then bv:Destroy() end
                    local gy = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FlyGyro")
                    if gy then gy:Destroy() end
                end
            end)
        end
    end, "Fly")
    addSlider(p, T("FlySpeed"), "FlySpeed", 10, 200, false, nil, "FlySpeed")

    addSection(p, T("Noclip"), "Noclip")
    addToggle(p, T("Noclip"), "Noclip", function(v)
        killConn("Noclip")
        if v then
            setConn("Noclip", RunService.Stepped:Connect(function()
                if not States.Noclip then killConn("Noclip") return end
                pcall(function()
                    if player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end))
        end
    end, "Noclip")

    addSection(p, T("JumpPower"), "JumpPower")
    addToggle(p, T("JumpPower"), "JumpPower", function(v)
        killConn("JumpPower")
        if v then
            setConn("JumpPower", RunService.RenderStepped:Connect(function()
                if not States.JumpPower then killConn("JumpPower") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid.JumpPower = Values.JumpPowerValue
                    end
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = 50
                end
            end)
        end
    end, "JumpPower")
    addSlider(p, T("JumpPowerValue"), "JumpPowerValue", 50, 500, false, nil, "JumpPowerValue")

    addSection(p, T("InfiniteJump"), "InfiniteJump")
    addToggle(p, T("InfiniteJump"), "InfiniteJump", function(v)
        killConn("InfJump")
        if v then
            setConn("InfJump", UserInputService.JumpRequest:Connect(function()
                if States.InfiniteJump then
                    pcall(function()
                        if player.Character and player.Character:FindFirstChild("Humanoid") then
                            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                end
            end))
        end
    end, "InfiniteJump")

    addSection(p, T("ClickTeleport"), "ClickTeleport")
    addToggle(p, T("ClickTeleport"), "ClickTeleport", function(v)
        killConn("ClickTP")
        if v then
            setConn("ClickTP", UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and States.ClickTeleport then
                    pcall(function()
                        local mouse = player:GetMouse()
                        if mouse.Hit then
                            player.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                        end
                    end)
                end
            end))
        end
    end, "ClickTeleport")

    addButton(p, T("Teleport"), function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local mouse = player:GetMouse()
                if mouse.Hit then
                    player.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                end
            end
        end)
    end, "Teleport")

    addSection(p, T("Sprint"), "Sprint")
    addToggle(p, T("Sprint"), "Sprint", function(v)
        killConn("Sprint")
        if v then
            setConn("Sprint", RunService.RenderStepped:Connect(function()
                if not States.Sprint then killConn("Sprint") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            player.Character.Humanoid.WalkSpeed = Values.SprintSpeed
                        else
                            player.Character.Humanoid.WalkSpeed = 16
                        end
                    end
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = 16
                end
            end)
        end
    end, "Sprint")
    addSlider(p, T("SprintSpeed"), "SprintSpeed", 20, 100, false, nil, "SprintSpeed")

    addSection(p, T("AntiVoid"), "AntiVoid")
    addToggle(p, T("AntiVoid"), "AntiVoid", function(v)
        killConn("AntiVoid")
        if v then
            setConn("AntiVoid", RunService.RenderStepped:Connect(function()
                if not States.AntiVoid then killConn("AntiVoid") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if player.Character.HumanoidRootPart.Position.Y < -10 then
                            player.Character.HumanoidRootPart.CFrame = CFrame.new(
                                player.Character.HumanoidRootPart.Position.X, 10,
                                player.Character.HumanoidRootPart.Position.Z)
                        end
                    end
                end)
            end))
        end
    end, "AntiVoid")

    addSection(p, T("Bhop"), "Bhop")
    addToggle(p, T("Bhop"), "Bhop", function(v)
        killConn("Bhop")
        if v then
            setConn("Bhop", UserInputService.JumpRequest:Connect(function()
                if States.Bhop and player.Character and player.Character:FindFirstChild("Humanoid") then
                    pcall(function()
                        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        player.Character.Humanoid.WalkSpeed = Values.BhopSpeed
                    end)
                end
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = 16
                end
            end)
        end
    end, "Bhop")
    addSlider(p, T("BhopSpeed"), "BhopSpeed", 18, 60, false, nil, "BhopSpeed")

    addSection(p, T("LongJump"), "LongJump")
    addToggle(p, T("LongJump"), "LongJump", function(v)
        killConn("LongJump")
        if v then
            setConn("LongJump", UserInputService.JumpRequest:Connect(function()
                if States.LongJump and player.Character and player.Character:FindFirstChild("Humanoid") then
                    pcall(function()
                        player.Character.Humanoid.JumpPower = Values.LongJumpPower
                    end)
                end
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = 50
                end
            end)
        end
    end, "LongJump")
    addSlider(p, T("LongJumpPower"), "LongJumpPower", 60, 300, false, nil, "LongJumpPower")
end

-- ══════════════════════════════════════════════════════════════
--  UTILITY TAB
-- ══════════════════════════════════════════════════════════════
do
    local p = pages.Utility

    addSection(p, T("AntiAFK"), "AntiAFK")
    addToggle(p, T("AntiAFK"), "AntiAFK", function(v)
        killConn("AntiAFK")
        if v then
            setConn("AntiAFK", VirtualUser.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                notify(T("AntiAFKActive"), T("AntiAFKDesc"), 3, "success")
            end))
        end
    end, "AntiAFK")

    addSection(p, T("FreezeTime"), "FreezeTime")
    addToggle(p, T("FreezeTime"), "FreezeTime", function(v)
        killConn("FreezeTime")
        if v then
            setConn("FreezeTime", RunService.RenderStepped:Connect(function()
                if States.FreezeTime then
                    pcall(function()
                        if Lighting then
                            Lighting.ClockTime = 12
                        end
                    end)
                end
            end))
        end
    end, "FreezeTime")

    addSection(p, T("FPSBoost"), "FPSBoost")
    addToggle(p, T("FPSBoost"), "FPSBoost", function(v)
        if v then
            pcall(function()
                settings().Rendering.QualityLevel = 1
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("Texture") or v:IsA("Decal") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                        v.Enabled = false
                    elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                        v.Brightness = 0
                    end
                end
            end)
            notify(T("FPSBoost"), T("FPSBoostOn"), 3, "success")
        else
            pcall(function()
                settings().Rendering.QualityLevel = 3
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("Texture") or v:IsA("Decal") then
                        v.Transparency = 0
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                        v.Enabled = true
                    end
                end
            end)
            notify(T("FPSBoost"), T("FPSBoostOff"), 3, "info")
        end
    end, "FPSBoost")

    addSection(p, T("FPSCounter"), "FPSCounter")
    addToggle(p, T("FPSCounter"), "FPSCounter", function(v)
        if fpsLabel then
            fpsLabel.Visible = v
        end
    end, "FPSCounter")

    addSection(p, T("AntiBlind"), "AntiBlind")
    addToggle(p, T("AntiBlind"), "AntiBlind", function(v)
        killConn("AntiBlind")
        if v then
            setConn("AntiBlind", RunService.RenderStepped:Connect(function()
                if States.AntiBlind then
                    pcall(function()
                        local cc = Lighting:FindFirstChild("ColorCorrection")
                        if cc then cc:Destroy() end
                        local bl = Lighting:FindFirstChild("Bloom")
                        if bl then bl:Destroy() end
                        local blur = Camera:FindFirstChildWhichIsA("BlurEffect")
                        if blur then blur:Destroy() end
                    end)
                end
            end))
        end
    end, "AntiBlind")

    addSection(p, T("AntiSlow"), "AntiSlow")
    addToggle(p, T("AntiSlow"), "AntiSlow", function(v)
        killConn("AntiSlow")
        if v then
            setConn("AntiSlow", RunService.Heartbeat:Connect(function()
                if States.AntiSlow and player.Character then
                    pcall(function()
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if hum and hum.WalkSpeed < 16 and not States.Speed then
                            hum.WalkSpeed = 16
                        end
                    end)
                end
            end))
        end
    end, "AntiSlow")

    addSection(p, T("AntiRagdoll"), "AntiRagdoll")
    addToggle(p, T("AntiRagdoll"), "AntiRagdoll", function(v)
        killConn("AntiRagdoll")
        if v then
            setConn("AntiRagdoll", RunService.Heartbeat:Connect(function()
                if States.AntiRagdoll and player.Character then
                    pcall(function()
                        local rag = player.Character:FindFirstChild("Ragdoll")
                        if rag then rag:Destroy() end
                        local ragV = player.Character:FindFirstChild("RagdollValue")
                        if ragV then ragV:Destroy() end
                        local ragB = player.Character:FindFirstChildWhichIsA("BallSocketConstraint")
                        if ragB then ragB:Destroy() end
                    end)
                end
            end))
        end
    end, "AntiRagdoll")

    addSection(p, T("AntiGrab"), "AntiGrab")
    addToggle(p, T("AntiGrab"), "AntiGrab", function(v)
        killConn("AntiGrab")
        if v then
            setConn("AntiGrab", RunService.Heartbeat:Connect(function()
                if States.AntiGrab and player.Character then
                    pcall(function()
                        for _, c in ipairs(player.Character:GetDescendants()) do
                            if c:IsA("Weld") and c.Name:lower():find("grab") then
                                c:Destroy()
                            end
                        end
                    end)
                end
            end))
        end
    end, "AntiGrab")

    addSection(p, T("AntiFling"), "AntiFling")
    addToggle(p, T("AntiFling"), "AntiFling", function(v)
        killConn("AntiFling")
        if v then
            setConn("AntiFling", RunService.Heartbeat:Connect(function()
                if States.AntiFling and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, other in ipairs(Players:GetPlayers()) do
                                if other ~= player and other.Character then
                                    local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
                                    if ohrp and (hrp.Position - ohrp.Position).Magnitude < 5 then
                                        ohrp.Velocity = Vector3.new(0, 0, 0)
                                        ohrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                    end
                                end
                            end
                        end
                    end)
                end
            end))
        end
    end, "AntiFling")

    addSection(p, T("AutoCollect"), "AutoCollect")
    addToggle(p, T("AutoCollect"), "AutoCollect", function(v)
        killConn("AutoCollect")
        if v then
            setConn("AutoCollect", RunService.Heartbeat:Connect(function()
                if States.AutoCollect and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, obj in ipairs(Workspace:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    if (obj.Parent and obj.Parent:IsA("BasePart")) then
                                        local dist = (hrp.Position - obj.Parent.Position).Magnitude
                                        if dist < 20 then
                                            fireproximityprompt(obj)
                                        end
                                    end
                                elseif obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
                                    local dist = (hrp.Position - obj.Parent.Position).Magnitude
                                    if dist < 30 then
                                        firetouchinterest(hrp, obj.Parent, 0)
                                        firetouchinterest(hrp, obj.Parent, 1)
                                    end
                                end
                            end
                        end
                    end)
                end
            end))
        end
    end, "AutoCollect")
end

-- ══════════════════════════════════════════════════════════════
--  SERVER TAB
-- ══════════════════════════════════════════════════════════════
do
    local p = pages.Server

    addSection(p, T("RejoinServer"), "RejoinServer")
    addButton(p, T("RejoinServer"), function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
        notify(T("RejoinServer"), T("Rejoining"), 3, "info")
    end)

    addSection(p, T("ServerHop"), "ServerHop")
    addButton(p, T("ServerHop"), function()
        pcall(function()
            local req = syn and syn.request or http and http.request or http_request
            if req then
                local res = req({
                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                    Method = "GET"
                })
                local data = game:GetService("HttpService"):JSONDecode(res.Body)
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
                            notify(T("ServerHop"), T("HoppingTo") .. " " .. srv.id, 3, "success")
                            return
                        end
                    end
                end
            else
                TeleportService:Teleport(game.PlaceId, player)
                notify(T("ServerHop"), T("Teleporting"), 3, "info")
            end
        end)
    end)

    addSection(p, T("JoinSmallServer"), "JoinSmallServer")
    addButton(p, T("JoinSmallServer"), function()
        pcall(function()
            local req = syn and syn.request or http and http.request or http_request
            if req then
                local res = req({
                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                    Method = "GET"
                })
                local data = game:GetService("HttpService"):JSONDecode(res.Body)
                local best = nil
                local bestCount = math.huge
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers and srv.playing < bestCount then
                            best = srv
                            bestCount = srv.playing
                        end
                    end
                    if best then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player)
                        notify(T("JoinSmallServer"), T("Joining") .. " " .. best.playing .. "/" .. best.maxPlayers, 3, "success")
                    end
                end
            else
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
    end)

    addSection(p, T("CopyServerID"), "CopyServerID")
    addButton(p, T("CopyServerID"), function()
        pcall(function()
            if setclipboard then
                setclipboard(tostring(game.JobId))
                notify(T("CopyServerID"), T("Copied"), 3, "success")
            else
                notify(T("CopyServerID"), T("CopyNotSupported"), 3, "error")
            end
        end)
    end)

    addSection(p, T("SpectatePlayer"), "SpectatePlayer")
    addDropdown(p, T("SpectatePlayer"), "SpectateTarget", function(val)
        local target = Players:FindFirstChild(val)
        if target then
            pcall(function()
                Camera.CameraSubject = target.Character and target.Character:FindFirstChild("Humanoid")
                notify(T("SpectatePlayer"), T("Spectating") .. " " .. val, 3, "info")
            end)
        end
    end)

    addButton(p, T("StopSpectate"), function()
        pcall(function()
            Camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
            notify(T("SpectatePlayer"), T("Stopped"), 3, "info")
        end)
    end)

    addSection(p, T("Radar"), "Radar")
    addToggle(p, T("Radar"), "Radar", function(v)
        if radarFrame then
            radarFrame.Visible = v
        end
    end, "Radar")

    addSection(p, T("QuickHUD"), "QuickHUD")
    addToggle(p, T("QuickHUD"), "QuickHUD", function(v)
        if quickHUD then
            quickHUD.Visible = v
        end
    end, "QuickHUD")
end

-- ══════════════════════════════════════════════════════════════
--  FUN TAB
-- ══════════════════════════════════════════════════════════════
do
    local p = pages.Fun

    addSection(p, T("Spin"), "Spin")
    addToggle(p, T("Spin"), "Spin", function(v)
        killConn("Spin")
        if v then
            setConn("Spin", RunService.Heartbeat:Connect(function(dt)
                if States.Spin and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Values.SpinSpeed * dt), 0)
                        end
                    end)
                end
            end))
        end
    end, "Spin")
    addSlider(p, T("SpinSpeed"), "SpinSpeed", 100, 2000, false, nil, "SpinSpeed")

    addSection(p, T("Float"), "Float")
    addToggle(p, T("Float"), "Float", function(v)
        killConn("Float")
        if v then
            setConn("Float", RunService.Heartbeat:Connect(function()
                if States.Float and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
                            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                        end
                    end)
                end
            end))
        end
    end, "Float")

    addSection(p, T("Bang"), "Bang")
    addToggle(p, T("Bang"), "Bang", function(v)
        killConn("Bang")
        if v then
            setConn("Bang", RunService.Heartbeat:Connect(function()
                if States.Bang and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 0.5
                        end
                    end)
                end
            end))
        end
    end, "Bang")

    addSection(p, T("Fling"), "Fling")
    addButton(p, T("Fling"), function()
        if not checkKey() then return end
        pcall(function()
            if player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, other in ipairs(Players:GetPlayers()) do
                        if other ~= player and other.Character then
                            local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
                            if ohrp and (hrp.Position - ohrp.Position).Magnitude < 15 then
                                ohrp.Velocity = (ohrp.Position - hrp.Position).Unit * 5000
                                ohrp.AssemblyAngularVelocity = Vector3.new(9999, 9999, 9999)
                                notify(T("Fling"), T("Flinged") .. " " .. other.Name, 3, "success")
                            end
                        end
                    end
                end
            end
        end)
    end)

    addSection(p, T("OrbitPlayer"), "OrbitPlayer")
    addToggle(p, T("OrbitPlayer"), "OrbitPlayer", function(v)
        killConn("OrbitPlayer")
        if v then
            setConn("OrbitPlayer", RunService.Heartbeat:Connect(function(dt)
                if States.OrbitPlayer and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local closest, closestDist = nil, Values.OrbitRadius
                        for _, other in ipairs(Players:GetPlayers()) do
                            if other ~= player and other.Character then
                                local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
                                if ohrp then
                                    local dist = (hrp.Position - ohrp.Position).Magnitude
                                    if dist < closestDist then
                                        closest = ohrp
                                        closestDist = dist
                                    end
                                end
                            end
                        end
                        if closest and hrp then
                            local angle = tick() * Values.OrbitSpeed
                            local offset = CFrame.new(
                                math.cos(angle) * Values.OrbitRadius,
                                0,
                                math.sin(angle) * Values.OrbitRadius
                            )
                            hrp.CFrame = closest.CFrame * offset
                        end
                    end)
                end
            end))
        end
    end, "OrbitPlayer")
    addSlider(p, T("OrbitRadius"), "OrbitRadius", 3, 30, false, nil, "OrbitRadius")
    addSlider(p, T("OrbitSpeed"), "OrbitSpeed", 1, 10, false, nil, "OrbitSpeed")

    addSection(p, T("Invisible"), "Invisible")
    addToggle(p, T("Invisible"), "Invisible", function(v)
        if v then
            pcall(function()
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            part.Transparency = 1
                        end
                    end
                    local face = player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("face")
                    if face then face.Transparency = 1 end
                end
            end)
            notify(T("Invisible"), T("InvisibleOn"), 3, "success")
        else
            pcall(function()
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.Transparency = 0
                        end
                    end
                    local face = player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("face")
                    if face then face.Transparency = 0 end
                end
            end)
            notify(T("Invisible"), T("InvisibleOff"), 3, "info")
        end
    end, "Invisible")

    addSection(p, T("Dance"), "Dance")
    addButton(p, T("Dance1"), function()
        if not checkKey() then return end
        pcall(function()
            if player.Character then
                local hum = player.Character:FindFirstChild("Humanoid")
                if hum then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://507771019"
                    local track = hum:LoadAnimation(anim)
                    track:Play()
                end
            end
        end)
    end)
    addButton(p, T("Dance2"), function()
        if not checkKey() then return end
        pcall(function()
            if player.Character then
                local hum = player.Character:FindFirstChild("Humanoid")
                if hum then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://507771055"
                    local track = hum:LoadAnimation(anim)
                    track:Play()
                end
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ══════════════════════════════════════════════════════════════
do
    local p = pages.Settings

    addSection(p, T("KeySystem"), "KeySystem")
    addInfoRow(p, T("KeyStatus"), keyAuthenticated and T("KeyVerified") or T("KeyNotVerified"))
    addKeyInput(p, T("EnterKey"), function(val)
        if val == VALID_KEY then
            keyAuthenticated = true
            notify(T("KeySystem"), T("KeyCorrect"), 3, "success")
            -- Update key status label
            if keyStatusLabel then
                keyStatusLabel.Text = "✓ KEY VERIFIED"
                keyStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
                keyStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
                keyStatusLabel.Visible = true
                task.delay(3, function() keyStatusLabel.Visible = false end)
            end
        else
            notify(T("KeySystem"), T("KeyIncorrect"), 3, "error")
        end
    end)

    addSection(p, T("Theme"), "Theme")
    addDropdown(p, T("SelectTheme"), "CurrentTheme", function(val)
        if Themes[val] then
            Values.CurrentTheme = val
            currentTheme = val
            updateAllThemes()
            notify(T("Theme"), val, 3, "success")
        end
    end)

    addSection(p, T("Language"), "Language")
    addDropdown(p, T("SelectLanguage"), "CurrentLang", function(val)
        if val == "VI" or val == "EN" then
            Values.CurrentLang = val
            notify(T("Language"), val, 3, "info")
        end
    end)

    addSection(p, T("GUIOptions"), "GUIOptions")
    addToggle(p, T("ShowFOV"), "ShowFOV", function(v)
        if fovCircle then fovCircle.Visible = v end
    end, "ShowFOV")

    addToggle(p, T("ShowCrosshair"), "ShowCrosshair", function(v)
        if crosshairContainer then
            crosshairContainer.Visible = v
        end
    end, "ShowCrosshair")

    addSlider(p, T("ESPRefreshRate"), "ESPRefreshRate", 10, 200, false, nil, "ESPRefreshRate")

    addSection(p, T("SaveConfig"), "SaveConfig")
    addButton(p, T("SaveConfig"), function()
        pcall(function()
            local saveData = {
                Values = Values,
                States = States,
            }
            local json = game:GetService("HttpService"):JSONEncode(saveData)
            if writefile then
                writefile("FLUYEN_v6_config.json", json)
                notify(T("SaveConfig"), T("ConfigSaved"), 3, "success")
            else
                notify(T("SaveConfig"), T("SaveNotSupported"), 3, "error")
            end
        end)
    end)

    addButton(p, T("LoadConfig"), function()
        pcall(function()
            if readfile then
                local json = readfile("FLUYEN_v6_config.json")
                local data = game:GetService("HttpService"):JSONDecode(json)
                if data then
                    if data.Values then
                        for k, v in pairs(data.Values) do
                            Values[k] = v
                        end
                    end
                    if data.States then
                        for k, v in pairs(data.States) do
                            States[k] = v
                        end
                    end
                    notify(T("LoadConfig"), T("ConfigLoaded"), 3, "success")
                end
            else
                notify(T("LoadConfig"), T("LoadNotSupported"), 3, "error")
            end
        end)
    end)

    addButton(p, T("ResetConfig"), function()
        -- Reset all states
        for k, v in pairs(States) do
            if type(v) == "boolean" then
                States[k] = false
            end
        end
        -- Kill all connections
        for k, _ in pairs(Connections) do
            killConn(k)
        end
        notify(T("ResetConfig"), T("ConfigReset"), 3, "success")
    end)

    addSection(p, T("PanicKey"), "PanicKey")
    addInfoRow(p, T("PanicKeyInfo"), T("PressPToPanic"))

    addSection(p, T("Credits"), "Credits")
    addInfoRow(p, "FLUYEN", "v6.1 Delta Universal")
    addInfoRow(p, T("Author"), "huyandkhang")
    addInfoRow(p, T("Executor"), "Delta Android")
end

-- ══════════════════════════════════════════════════════════════
--  GESTURE SYSTEM (Mobile 3-finger tap to toggle GUI)
-- ══════════════════════════════════════════════════════════════
do
    local tapCount = 0
    local lastTapTime = 0

    UserInputService.TouchTap:Connect(function(touchPositions)
        if #touchPositions >= 3 then
            local now = tick()
            if now - lastTapTime < 0.5 then
                tapCount = tapCount + 1
            else
                tapCount = 1
            end
            lastTapTime = now

            if tapCount >= 2 then
                tapCount = 0
                if mainFrame then
                    mainFrame.Visible = not mainFrame.Visible
                    if miniBtn then
                        miniBtn.Visible = not mainFrame.Visible
                    end
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  KEYBOARD SHORTCUTS (Insert = toggle GUI, P = Panic)
-- ══════════════════════════════════════════════════════════════
do
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            if mainFrame then
                mainFrame.Visible = not mainFrame.Visible
                if miniBtn then
                    miniBtn.Visible = not mainFrame.Visible
                end
            end
        elseif input.KeyCode == Enum.KeyCode.P then
            -- PANIC: Disable everything and hide GUI
            for k, v in pairs(States) do
                if type(v) == "boolean" then
                    States[k] = false
                end
            end
            for k, _ in pairs(Connections) do
                killConn(k)
            end
            cleanupAllESP()
            if mainFrame then mainFrame.Visible = false end
            if miniBtn then miniBtn.Visible = true end
            if fovCircle then fovCircle.Visible = false end
            if radarFrame then radarFrame.Visible = false end
            if quickHUD then quickHUD.Visible = false end
            if crosshairContainer then crosshairContainer.Visible = false end
            pcall(function()
                stopNightVision()
                stopXray()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = 16
                    player.Character.Humanoid.JumpPower = 50
                end
                Camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
            end)
            notify(T("PanicKey"), T("AllDisabled"), 3, "error")
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  SPECTATE DROPDOWN UPDATE
-- ══════════════════════════════════════════════════════════════
do
    local function updateSpectateList()
        if not pages or not pages.Server then return end
        -- Find the spectate dropdown and update options
        for _, child in ipairs(pages.Server:GetChildren()) do
            if child.Name == "SpectateTarget" and child:IsA("TextButton") then
                -- Recreate dropdown with current players
                local list = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player then
                        table.insert(list, p.Name)
                    end
                end
                if child:FindFirstChild("DropdownList") then
                    local dd = child.DropdownList
                    dd:ClearAllChildren()
                    for i, name in ipairs(list) do
                        local opt = dd:FindFirstChild("Option_" .. name)
                        if not opt then
                            opt = Instance.new("TextButton")
                            opt.Name = "Option_" .. name
                            opt.Size = UDim2.new(1, 0, 0, 22)
                            opt.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
                            opt.BackgroundColor3 = theme().card
                            opt.TextColor3 = theme().text
                            opt.Font = Enum.Font.Gotham
                            opt.TextSize = 11
                            opt.Text = name
                            opt.Parent = dd
                        end
                    end
                end
            end
        end
    end

    Players.PlayerAdded:Connect(function()
        task.delay(1, updateSpectateList)
    end)
    Players.PlayerRemoving:Connect(function()
        task.delay(1, updateSpectateList)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  AUTO-LOAD CONFIG & INITIAL SETUP
-- ══════════════════════════════════════════════════════════════
do
    -- Try to auto-load config
    pcall(function()
        if readfile then
            local json = readfile("FLUYEN_v6_config.json")
            local data = game:GetService("HttpService"):JSONDecode(json)
            if data and data.Values then
                for k, v in pairs(data.Values) do
                    if Values[k] ~= nil then
                        Values[k] = v
                    end
                end
            end
        end
    end)

    -- Auto-enable AntiAFK
    States.AntiAFK = true
    setConn("AntiAFK", VirtualUser.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end))

    -- Initial cache refresh
    recalcCache()

    -- Welcome notification
    task.delay(1.5, function()
        notify("FLUYEN v6.1", T("Welcome"), 3, "success")
    end)
end

-- ══════════════════════════════════════════════════════════════
--  ANTI-DETECTION / CHARACTER RESPAWN HANDLER
-- ══════════════════════════════════════════════════════════════
do
    player.CharacterAdded:Connect(function(char)
        task.delay(1, function()
            -- Reset ESP connections on respawn
            cacheDirty = true
            recalcCache()
            -- Restore active features
            if States.Speed and char:FindFirstChild("Humanoid") then
                pcall(function() char.Humanoid.WalkSpeed = Values.SpeedValue end)
            end
            if States.JumpPower and char:FindFirstChild("Humanoid") then
                pcall(function() char.Humanoid.JumpPower = Values.JumpValue end)
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  CLOSING ERROR HANDLER
-- ══════════════════════════════════════════════════════════════
end) -- end pcall wrapper
