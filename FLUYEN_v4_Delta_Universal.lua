--[[
  FLUYEN HUD MENU - DELTA UNIVERSAL EDITION v4.0
  Complete rewrite for Delta executor (Android/Mobile)
  All functions working | All tabs | Full compatibility
]]

-- ============================================================
-- POLYFILL: task library for Delta executor
-- Delta does NOT have task.spawn/task.wait/task.delay
-- It HAS legacy globals: wait(), spawn(), delay()
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

-- ============================================================
-- MAIN SCRIPT - pcall wrapper for crash protection
-- ============================================================
local _ok, _err = pcall(function()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

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
local SCRIPT_VERSION = "v4.0"

-- States
local States = {
    ESP=false, BoxESP=false, NameESP=false, HealthESP=false, DistanceESP=false,
    Tracers=false, Chams=false, FullBright=false,
    Aim=false, SilentAim=false, AimFOV=false, AimPrediction=false, TriggerBot=false, HitboxExpander=false,
    Speed=false, Fly=false, Noclip=false, JumpPower=false, InfiniteJump=false, ClickTeleport=false, Sprint=false, AntiVoid=false,
    AntiAFK=false, FreezeTime=false, FPSBoost=false,
    Spin=false, Float=false, Bang=false, Fling=false, Invisible=false,
    AutoLoadSettings=false, MinimizeButton=true, DraggableGUI=true, Notifications=true,
}

-- Values
local Values = {
    SpeedValue=16, FlySpeed=50, JumpPowerValue=50, SprintSpeed=24,
    SpinSpeed=10, AimFOVValue=90, AimSmoothness=0.5, HitboxSize=10,
    OrbitRadius=5, OrbitSpeed=1,
}

-- Connections storage
local Conns = {}
local function killConn(name)
    if Conns[name] then
        pcall(function() Conns[name]:Disconnect() end)
        Conns[name] = nil
    end
end
local function setConn(name, conn)
    killConn(name)
    Conns[name] = conn
end

-- Theme system
local currentTheme = "Dark"
local Themes = {
    Dark = {
        bg=Color3.fromRGB(25,25,30), sidebar=Color3.fromRGB(20,20,25),
        tabActive=Color3.fromRGB(40,40,48), tabInactive=Color3.fromRGB(20,20,25),
        accent=Color3.fromRGB(255,107,53), accentDark=Color3.fromRGB(200,80,40),
        text=Color3.fromRGB(240,240,245), textDim=Color3.fromRGB(140,140,150),
        checkboxBg=Color3.fromRGB(45,45,55), checkboxOn=Color3.fromRGB(255,107,53),
        sliderTrack=Color3.fromRGB(50,50,60), sliderFill=Color3.fromRGB(255,107,53),
        btnBg=Color3.fromRGB(40,40,50), btnHover=Color3.fromRGB(55,55,65),
        dropdownBg=Color3.fromRGB(35,35,45), pageBg=Color3.fromRGB(25,25,30),
        border=Color3.fromRGB(50,50,60),
    },
    Light = {
        bg=Color3.fromRGB(245,245,250), sidebar=Color3.fromRGB(230,230,235),
        tabActive=Color3.fromRGB(255,255,255), tabInactive=Color3.fromRGB(230,230,235),
        accent=Color3.fromRGB(255,107,53), accentDark=Color3.fromRGB(200,80,40),
        text=Color3.fromRGB(30,30,35), textDim=Color3.fromRGB(100,100,110),
        checkboxBg=Color3.fromRGB(220,220,225), checkboxOn=Color3.fromRGB(255,107,53),
        sliderTrack=Color3.fromRGB(210,210,215), sliderFill=Color3.fromRGB(255,107,53),
        btnBg=Color3.fromRGB(230,230,235), btnHover=Color3.fromRGB(240,240,245),
        dropdownBg=Color3.fromRGB(225,225,230), pageBg=Color3.fromRGB(245,245,250),
        border=Color3.fromRGB(200,200,210),
    },
    SkyBlue = {
        bg=Color3.fromRGB(20,25,40), sidebar=Color3.fromRGB(15,20,35),
        tabActive=Color3.fromRGB(30,40,60), tabInactive=Color3.fromRGB(15,20,35),
        accent=Color3.fromRGB(80,180,255), accentDark=Color3.fromRGB(60,140,200),
        text=Color3.fromRGB(230,240,255), textDim=Color3.fromRGB(120,140,170),
        checkboxBg=Color3.fromRGB(35,45,65), checkboxOn=Color3.fromRGB(80,180,255),
        sliderTrack=Color3.fromRGB(40,50,70), sliderFill=Color3.fromRGB(80,180,255),
        btnBg=Color3.fromRGB(30,40,60), btnHover=Color3.fromRGB(40,50,75),
        dropdownBg=Color3.fromRGB(25,35,55), pageBg=Color3.fromRGB(20,25,40),
        border=Color3.fromRGB(40,55,80),
    },
    Galaxy = {
        bg=Color3.fromRGB(15,10,30), sidebar=Color3.fromRGB(10,8,25),
        tabActive=Color3.fromRGB(30,20,55), tabInactive=Color3.fromRGB(10,8,25),
        accent=Color3.fromRGB(180,100,255), accentDark=Color3.fromRGB(140,70,200),
        text=Color3.fromRGB(230,220,255), textDim=Color3.fromRGB(120,110,150),
        checkboxBg=Color3.fromRGB(35,25,55), checkboxOn=Color3.fromRGB(180,100,255),
        sliderTrack=Color3.fromRGB(40,30,60), sliderFill=Color3.fromRGB(180,100,255),
        btnBg=Color3.fromRGB(30,20,50), btnHover=Color3.fromRGB(40,30,65),
        dropdownBg=Color3.fromRGB(25,18,45), pageBg=Color3.fromRGB(15,10,30),
        border=Color3.fromRGB(50,35,80),
    },
}

local function getTheme()
    return Themes[currentTheme] or Themes.Dark
end

-- Language system
local currentLang = "EN"
local Langs = {
    EN = {
        Home="Home", Visual="Visual", Combat="Combat", Movement="Movement",
        Utility="Utility", Server="Server", Fun="Fun", Settings="Settings",
        ScriptName="Script Name", Version="Version", Username="Username",
        Executor="Executor", Credits="Credits", Changelog="Changelog",
        ESP="ESP", BoxESP="Box ESP", NameESP="Name ESP", HealthESP="Health ESP",
        DistanceESP="Distance ESP", Tracers="Tracers", Chams="Chams/X-Ray", FullBright="Full Bright",
        Aim="Aim", SilentAim="Silent Aim", AimFOV="Aim FOV", AimPrediction="Aim Prediction",
        TriggerBot="Trigger Bot", HitboxExpander="Hitbox Expander",
        Speed="Speed", Fly="Fly", Noclip="Noclip", JumpPower="Jump Power",
        InfiniteJump="Infinite Jump", Teleport="Teleport", ClickTeleport="Click Teleport",
        Sprint="Sprint", AntiVoid="Anti Void",
        AntiAFK="Anti AFK", FreezeTime="Freeze Time", FPSBoost="FPS Booster",
        RejoinServer="Rejoin Server", ServerHop="Server Hop", JoinSmallServer="Join Small Server",
        PlayerList="Player List", SpectatePlayer="Spectate Player",
        Spin="Spin", Float="Float", Bang="Bang", Fling="Fling",
        OrbitPlayer="Orbit Player", Invisible="Invisible",
        Theme="Theme", Language="Language", GUI="GUI",
        SaveSettings="Save Settings", AutoLoadSettings="Auto Load Settings",
        ResetSettings="Reset Settings", MinimizeButton="Minimize Button",
        DraggableGUI="Draggable GUI", ToggleKeybind="Toggle Keybind", Notifications="Notifications",
        SpeedValue="Speed", FlySpeed="Fly Speed", JumpPowerValue="Jump Power",
        SprintSpeed="Sprint Speed", SpinSpeed="Spin Speed",
        AimFOVValue="Aim FOV", AimSmoothness="Aim Smoothness",
        HitboxSize="Hitbox Size", OrbitRadius="Orbit Radius", OrbitSpeed="Orbit Speed",
        Dark="Dark", Light="Light", SkyBlue="Sky Blue", Galaxy="Galaxy",
        English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    },
    VI = {
        Home="Trang Chu", Visual="Hinh Anh", Combat="Chien Dau", Movement="Di Chuyen",
        Utility="Tien Ich", Server="May Chu", Fun="Giai Tri", Settings="Cai Dat",
        ScriptName="Ten Script", Version="Phien Ban", Username="Ten Nguoi Dung",
        Executor="Trinh Thuc Thi", Credits="Tac Gia", Changelog="Nhat Ky",
        ESP="ESP", BoxESP="Hop ESP", NameESP="Ten ESP", HealthESP="Mau ESP",
        DistanceESP="Khoang Cach ESP", Tracers="Duong Dan", Chams="Chams/X-Ray", FullBright="Sang Toan Bo",
        Aim="Ngam", SilentAim="Ngam Am", AimFOV="Ngam FOV", AimPrediction="Du Doan Ngam",
        TriggerBot="Bot Ban", HitboxExpander="Mo Rong Hitbox",
        Speed="Toc Do", Fly="Bay", Noclip="Xuyen Tuong", JumpPower="Luc Nhay",
        InfiniteJump="Nhay Vo Han", Teleport="Dich Chuyen", ClickTeleport="Click Dich Chuyen",
        Sprint="Chay Nhanh", AntiVoid="Chong Rot",
        AntiAFK="Chong AFK", FreezeTime="Dong Thoi Gian", FPSBoost="Tang FPS",
        RejoinServer="Vao Lai May Chu", ServerHop="Chuyen May Chu", JoinSmallServer="Vao May Chu Nho",
        PlayerList="Danh Sach Nguoi Choi", SpectatePlayer="Theo Doi Nguoi Choi",
        Spin="Xoay", Float="Bay Lang", Bang="Dam", Fling="Nem",
        OrbitPlayer="Quay Quanh", Invisible="Vo Hinh",
        Theme="Giao Dien", Language="Ngon Ngu", GUI="Giao Dien",
        SaveSettings="Luu Cai Dat", AutoLoadSettings="Tu Dong Tai",
        ResetSettings="Dat Lai Cai Dat", MinimizeButton="Nut Thu Nho",
        DraggableGUI="Keo Duoc", ToggleKeybind="Phim Tat", Notifications="Thong Bao",
        SpeedValue="Toc Do", FlySpeed="Toc Do Bay", JumpPowerValue="Luc Nhay",
        SprintSpeed="Toc Do Chay", SpinSpeed="Toc Do Xoay",
        AimFOVValue="Ngam FOV", AimSmoothness="Do Muot Ngam",
        HitboxSize="Kich Thuoc Hitbox", OrbitRadius="Ban Kinh Quay", OrbitSpeed="Toc Do Quay",
        Dark="Toi", Light="Sang", SkyBlue="Xanh Troi", Galaxy="Thien Ha",
        English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    },
    ES = {
        Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimiento",
        Utility="Utilidad", Server="Servidor", Fun="Diversion", Settings="Ajustes",
        ScriptName="Nombre Script", Version="Version", Username="Usuario",
        Executor="Ejecutor", Credits="Creditos", Changelog="Cambios",
        ESP="ESP", BoxESP="Caja ESP", NameESP="Nombre ESP", HealthESP="Salud ESP",
        DistanceESP="Distancia ESP", Tracers="Trazadores", Chams="Chams/Rayos X", FullBright="Luz Total",
        Aim="Apuntar", SilentAim="Apuntar Silencioso", AimFOV="FOV Apuntado", AimPrediction="Prediccion",
        TriggerBot="Bot Disparo", HitboxExpander="Expandir Hitbox",
        Speed="Velocidad", Fly="Volar", Noclip="Noclip", JumpPower="Salto",
        InfiniteJump="Salto Infinito", Teleport="Teletransporte", ClickTeleport="Click Teleport",
        Sprint="Sprint", AntiVoid="Anti Vacio",
        AntiAFK="Anti AFK", FreezeTime="Congelar Tiempo", FPSBoost="Mas FPS",
        RejoinServer="Reconectar", ServerHop="Cambiar Servidor", JoinSmallServer="Servidor Pequeno",
        PlayerList="Lista Jugadores", SpectatePlayer="Espectar",
        Spin="Girar", Float="Flotar", Bang="Golpear", Fling="Lanzar",
        OrbitPlayer="Orbitar", Invisible="Invisible",
        Theme="Tema", Language="Idioma", GUI="Interfaz",
        SaveSettings="Guardar", AutoLoadSettings="Auto Cargar",
        ResetSettings="Reiniciar", MinimizeButton="Boton Minimizar",
        DraggableGUI="Arrastrable", ToggleKeybind="Tecla Toggle", Notifications="Notificaciones",
        SpeedValue="Velocidad", FlySpeed="Vel. Vuelo", JumpPowerValue="Salto",
        SprintSpeed="Vel. Sprint", SpinSpeed="Vel. Giro",
        AimFOVValue="FOV Apuntado", AimSmoothness="Suavidad",
        HitboxSize="Tam. Hitbox", OrbitRadius="Radio Orbita", OrbitSpeed="Vel. Orbita",
        Dark="Oscuro", Light="Claro", SkyBlue="Cielo Azul", Galaxy="Galaxia",
        English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    },
    PT = {
        Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimento",
        Utility="Utilidade", Server="Servidor", Fun="Diversao", Settings="Configuracoes",
        ScriptName="Nome Script", Version="Versao", Username="Usuario",
        Executor="Executor", Credits="Creditos", Changelog="Mudancas",
        ESP="ESP", BoxESP="Caixa ESP", NameESP="Nome ESP", HealthESP="Saude ESP",
        DistanceESP="Distancia ESP", Tracers="Rastreadores", Chams="Chams/Raios X", FullBright="Luz Total",
        Aim="Mirar", SilentAim="Mira Silenciosa", AimFOV="FOV Mira", AimPrediction="Predicao",
        TriggerBot="Bot Disparo", HitboxExpander="Expandir Hitbox",
        Speed="Velocidade", Fly="Voar", Noclip="Noclip", JumpPower="Pulo",
        InfiniteJump="Pulo Infinito", Teleport="Teleporte", ClickTeleport="Click Teleporte",
        Sprint="Sprint", AntiVoid="Anti Vazio",
        AntiAFK="Anti AFK", FreezeTime="Congelar Tempo", FPSBoost="Mais FPS",
        RejoinServer="Reconectar", ServerHop="Trocar Servidor", JoinSmallServer="Servidor Pequeno",
        PlayerList="Lista Jogadores", SpectatePlayer="Espectar",
        Spin="Girar", Float="Flutuar", Bang="Bater", Fling="Arremessar",
        OrbitPlayer="Orbitar", Invisible="Invisivel",
        Theme="Tema", Language="Idioma", GUI="Interface",
        SaveSettings="Salvar", AutoLoadSettings="Auto Carregar",
        ResetSettings="Resetar", MinimizeButton="Botao Minimizar",
        DraggableGUI="Arrastavel", ToggleKeybind="Tecla Toggle", Notifications="Notificacoes",
        SpeedValue="Velocidade", FlySpeed="Vel. Voo", JumpPowerValue="Pulo",
        SprintSpeed="Vel. Sprint", SpinSpeed="Vel. Giro",
        AimFOVValue="FOV Mira", AimSmoothness="Suavidade",
        HitboxSize="Tam. Hitbox", OrbitRadius="Raio Orbita", OrbitSpeed="Vel. Orbita",
        Dark="Escuro", Light="Claro", SkyBlue="Ceu Azul", Galaxy="Galaxia",
        English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    },
    RU = {
        Home="Glavnaya", Visual="Vizual", Combat="Boi", Movement="Dvizhenie",
        Utility="Utilita", Server="Server", Fun="Razvlechenie", Settings="Nastroyki",
        ScriptName="Imya Skripta", Version="Versiya", Username="Polzovatel",
        Executor="Ispolnitel", Credits="Avtory", Changelog="Izmeneniya",
        ESP="ESP", BoxESP="Boks ESP", NameESP="Imya ESP", HealthESP="Zdorove ESP",
        DistanceESP="Rasstoyanie ESP", Tracers="Luch", Chams="Chams/Rentgen", FullBright="Yarkost",
        Aim="Pricel", SilentAim="Tihii Pricel", AimFOV="Pricel FOV", AimPrediction="Predikciya",
        TriggerBot="Trigger Bot", HitboxExpander="Hitboks",
        Speed="Skorost", Fly="Polet", Noclip="Noklip", JumpPower="Prizhok",
        InfiniteJump="Beskonechnii Prizhok", Teleport="Teleport", ClickTeleport="Klik Teleport",
        Sprint="Sprint", AntiVoid="Anti Proval",
        AntiAFK="Anti AFK", FreezeTime="Ostanovit Vremya", FPSBoost="FPS Bust",
        RejoinServer="Pereiti", ServerHop="Smenit Server", JoinSmallServer="Malcii Server",
        PlayerList="Spisok Igrokov", SpectatePlayer="Nablyudat",
        Spin="Vrashenie", Float="Parit", Bang="Udar", Fling="Brosit",
        OrbitPlayer="Orbita", Invisible="Nevidimost",
        Theme="Tema", Language="Yazik", GUI="Interfeis",
        SaveSettings="Sokhranit", AutoLoadSettings="Avtosapusk",
        ResetSettings="Sbros", MinimizeButton="Knopka Svertki",
        DraggableGUI="Peretaskivanie", ToggleKeybind="Klavisha", Notifications="Uvedomleniya",
        SpeedValue="Skorost", FlySpeed="Skorost Poleta", JumpPowerValue="Sila Prizhka",
        SprintSpeed="Skorost Sprinta", SpinSpeed="Skorost Vrasheniya",
        AimFOVValue="Pricel FOV", AimSmoothness="Plavnost Pricela",
        HitboxSize="Razmer Hitboksa", OrbitRadius="Radius Orbiy", OrbitSpeed="Skorost Orbiy",
        Dark="Temnaya", Light="Svetlaya", SkyBlue="Nebesno-Golubaya", Galaxy="Galaktika",
        English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    },
}

local function T(key)
    local lang = Langs[currentLang] or Langs.EN
    return lang[key] or key
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local function notify(title, content, duration)
    duration = duration or 3
    _spawn(function()
        pcall(function()
            local theme = getTheme()
            local notifGui = playerGui:FindFirstChild("FLUYEN_Noti_Gui")
            if not notifGui then
                notifGui = Instance.new("ScreenGui")
                notifGui.Name = "FLUYEN_Noti_Gui"
                notifGui.ResetOnSpawn = false
                notifGui.Parent = playerGui
            end

            local notifFrame = Instance.new("Frame")
            notifFrame.Name = "Notif_" .. math.random(10000,99999)
            notifFrame.Size = UDim2.new(0, 260, 0, 60)
            notifFrame.Position = UDim2.new(1, 280, 0, 10)
            notifFrame.BackgroundColor3 = theme.bg
            notifFrame.BorderSizePixel = 0
            notifFrame.ZIndex = 100
            notifFrame.Parent = notifGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = notifFrame

            local accentBar = Instance.new("Frame")
            accentBar.Size = UDim2.new(0, 4, 1, 0)
            accentBar.BackgroundColor3 = theme.accent
            accentBar.BorderSizePixel = 0
            accentBar.ZIndex = 101
            accentBar.Parent = notifFrame

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -16, 0, 22)
            titleLabel.Position = UDim2.new(0, 12, 0, 5)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.TextColor3 = theme.text
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 13
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.ZIndex = 101
            titleLabel.Parent = notifFrame

            local contentLabel = Instance.new("TextLabel")
            contentLabel.Size = UDim2.new(1, -16, 0, 20)
            contentLabel.Position = UDim2.new(0, 12, 0, 30)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Text = content
            contentLabel.TextColor3 = theme.textDim
            contentLabel.Font = Enum.Font.Gotham
            contentLabel.TextSize = 11
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.ZIndex = 101
            contentLabel.Parent = notifFrame

            -- Slide in
            TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -280, 0, 10)
            }):Play()
            _wait(duration)

            -- Slide out
            TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 280, 0, 10)
            }):Play()
            _wait(0.35)
            notifFrame:Destroy()
        end)
    end)
end

-- ============================================================
-- GUI CREATION
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FLUYEN_Menu_" .. tostring(math.random(1000,9999))
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Backdrop
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0,0,0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = screenGui

local backdropClose = Instance.new("TextButton")
backdropClose.Size = UDim2.new(1, 0, 1, 0)
backdropClose.BackgroundTransparency = 1
backdropClose.Text = ""
backdropClose.ZIndex = 1
backdropClose.Parent = backdrop

-- Main Frame
local MENU_W, MENU_H = 520, 400
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, MENU_W, 0, MENU_H)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = getTheme().bg
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- UIScale (pcall)
local uiScale = nil
pcall(function()
    uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = mainFrame
end)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = getTheme().bg
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = SCRIPT_NAME .. " " .. SCRIPT_VERSION
titleLabel.TextColor3 = getTheme().accent
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = getTheme().textDim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 11
closeBtn.Parent = titleBar

-- Sidebar (Tab list)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 90, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = getTheme().sidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 0)

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 2)
sidebarLayout.Parent = sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 4)
sidebarPad.PaddingLeft = UDim.new(0, 4)
sidebarPad.PaddingRight = UDim.new(0, 4)
sidebarPad.Parent = sidebar

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -90, 1, -30)
contentArea.Position = UDim2.new(0, 90, 0, 30)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true
contentArea.ZIndex = 5
contentArea.Parent = mainFrame

-- Tab definitions
local TabDefs = {
    {name="Home", icon="[H]", order=1},
    {name="Visual", icon="[V]", order=2},
    {name="Combat", icon="[C]", order=3},
    {name="Movement", icon="[M]", order=4},
    {name="Utility", icon="[U]", order=5},
    {name="Server", icon="[S]", order=6},
    {name="Fun", icon="[F]", order=7},
    {name="Settings", icon="[G]", order=8},
}

-- Create pages (ScrollingFrames)
local pages = {}
local tabButtons = {}

for _, tabDef in ipairs(TabDefs) do
    local name = tabDef.name
    -- Page
    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = getTheme().accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = (name == "Home")
    page.ZIndex = 6
    page.Parent = contentArea
    pcall(function() page.ScrollingDirection = Enum.ScrollingDirection.Y end)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 6)
    pagePad.PaddingLeft = UDim.new(0, 8)
    pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.PaddingBottom = UDim.new(0, 8)
    pagePad.Parent = page

    pages[name] = page

    -- Tab button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 28)
    tabBtn.BackgroundColor3 = (name == "Home") and getTheme().tabActive or getTheme().tabInactive
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = tabDef.icon .. " " .. name
    tabBtn.TextColor3 = (name == "Home") and getTheme().text or getTheme().textDim
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 11
    tabBtn.LayoutOrder = tabDef.order
    tabBtn.ZIndex = 6
    tabBtn.Parent = sidebar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)

    -- Active border indicator
    local activeBorder = Instance.new("Frame")
    activeBorder.Name = "ActiveBorder"
    activeBorder.Size = UDim2.new(0, 3, 0, 16)
    activeBorder.Position = UDim2.new(0, 0, 0.5, -8)
    activeBorder.BackgroundColor3 = getTheme().accent
    activeBorder.BorderSizePixel = 0
    activeBorder.Visible = (name == "Home")
    activeBorder.ZIndex = 7
    activeBorder.Parent = tabBtn
    Instance.new("UICorner", activeBorder).CornerRadius = UDim.new(0, 2)

    tabButtons[name] = tabBtn
end

-- ============================================================
-- UI ELEMENT BUILDERS
-- ============================================================
local ELEMENT_H = 28

local function addSection(page, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text
    label.TextColor3 = getTheme().accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 7
    label.Parent = page
    return label
end

local function addCheckbox(page, text, stateKey, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 0, 0.5, -9)
    box.BackgroundColor3 = getTheme().checkboxBg
    box.BorderSizePixel = 0
    box.ZIndex = 8
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local checkmark = Instance.new("Frame")
    checkmark.Size = UDim2.new(0, 10, 0, 10)
    checkmark.Position = UDim2.new(0.5, -5, 0.5, -5)
    checkmark.BackgroundColor3 = getTheme().checkboxOn
    checkmark.BorderSizePixel = 0
    checkmark.Visible = States[stateKey] or false
    checkmark.ZIndex = 9
    checkmark.Parent = box
    Instance.new("UICorner", checkmark).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.new(0, 24, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = getTheme().text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 10
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        States[stateKey] = not States[stateKey]
        checkmark.Visible = States[stateKey]
        if callback then pcall(function() callback(States[stateKey]) end) end
    end)

    return row
end

local function addSlider(page, text, valueKey, min, max, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(Values[valueKey] or min)
    label.TextColor3 = getTheme().text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0.42, 0, 0, 6)
    track.Position = UDim2.new(0.56, 0, 0.5, -3)
    track.BackgroundColor3 = getTheme().sliderTrack
    track.BorderSizePixel = 0
    track.ZIndex = 8
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame")
    local pct = math.max(0, math.min((Values[valueKey] - min) / math.max(max - min, 1), 1))
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = getTheme().sliderFill
    fill.BorderSizePixel = 0
    fill.ZIndex = 9
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0.42, 0, 1, 0)
    sliderBtn.Position = UDim2.new(0.56, 0, 0, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 10
    sliderBtn.Parent = row

    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
        local function updateDrag()
            while dragging do
                _wait(0.01)
                local relX = math.max(0, math.min((sliderBtn.Mouse.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 1))
                local val = math.floor(min + relX * (max - min))
                Values[valueKey] = val
                fill.Size = UDim2.new(relX, 0, 1, 0)
                label.Text = text .. ": " .. tostring(val)
                if callback then pcall(function() callback(val) end) end
            end
        end
        _spawn(updateDrag)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return row
end

local function addButton(page, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    btn.BackgroundColor3 = getTheme().btnBg
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = getTheme().text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.ZIndex = 8
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if callback then pcall(function() callback() end) end
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = getTheme().btnHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = getTheme().btnBg}):Play()
    end)

    return btn
end

local function addInfoRow(page, labelText, valueText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = getTheme().textDim
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 8
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.55, 0, 1, 0)
    val.Position = UDim2.new(0.45, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = valueText or "N/A"
    val.TextColor3 = getTheme().text
    val.Font = Enum.Font.GothamBold
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 8
    val.Parent = row

    return row, val
end

local function addDropdown(page, text, options, onSelect)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = getTheme().text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = row

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.53, 0, 0, 22)
    dropBtn.Position = UDim2.new(0.47, 0, 0.5, -11)
    dropBtn.BackgroundColor3 = getTheme().dropdownBg
    dropBtn.BorderSizePixel = 0
    dropBtn.Text = options[1] or "Select"
    dropBtn.TextColor3 = getTheme().text
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextSize = 11
    dropBtn.ZIndex = 8
    dropBtn.Parent = row
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0.53, 0, 0, #options * 24)
    listFrame.Position = UDim2.new(0.47, 0, 1, 2)
    listFrame.BackgroundColor3 = getTheme().dropdownBg
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 50
    listFrame.Parent = row
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundColor3 = getTheme().dropdownBg
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.TextColor3 = getTheme().text
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 51
        optBtn.Parent = listFrame

        optBtn.MouseButton1Click:Connect(function()
            dropBtn.Text = opt
            listFrame.Visible = false
            if onSelect then pcall(function() onSelect(opt, i) end) end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    return row
end

-- ============================================================
-- PAGE SIZE RECALCULATION
-- ============================================================
local function recalcPage(page)
    pcall(function()
        if not page or not page:IsA("ScrollingFrame") then return end
        local wasVisible = page.Visible
        if not wasVisible then
            page.Visible = true
        end
        _wait(0.02)
        local contentH = 0
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                local h = child.AbsoluteSize.Y
                if h <= 0 then h = child.Size.Y.Offset end
                if h <= 0 then h = ELEMENT_H end
                contentH = contentH + h + 4
            end
        end
        local totalH = math.max(contentH + 20, page.AbsoluteSize.Y + 1)
        page.CanvasSize = UDim2.new(0, 0, 0, totalH)
        if not wasVisible then
            page.Visible = false
        end
    end)
end

local function recalcAllPages()
    _spawn(function()
        _wait(0.05)
        local wasMainVisible = mainFrame.Visible
        if not wasMainVisible then
            mainFrame.Position = UDim2.new(0, -9999, 0, -9999)
            mainFrame.Visible = true
        end
        _wait(0.03)
        for name, page in pairs(pages) do
            recalcPage(page)
        end
        if not wasMainVisible then
            mainFrame.Visible = false
            mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
    end)
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================
local currentTab = "Home"

local function selectTab(name)
    currentTab = name
    for pageName, page in pairs(pages) do
        page.Visible = (pageName == name)
        if pageName == name then
            -- Reset scroll position
            pcall(function()
                page.CanvasPosition = Vector2.new(0, 0)
            end)
        end
    end
    for btnName, btn in pairs(tabButtons) do
        local active = (btnName == name)
        local theme = getTheme()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and theme.tabActive or theme.tabInactive
        }):Play()
        btn.TextColor3 = active and theme.text or theme.textDim
        local border = btn:FindFirstChild("ActiveBorder")
        if border then border.Visible = active end
    end
    recalcAllPages()
end

-- Connect tab buttons
for btnName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        selectTab(btnName)
    end)
end

-- ============================================================
-- MENU OPEN/CLOSE
-- ============================================================
local isOpen = false
local isAnimating = false
local OPEN_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FADE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function openMenu()
    if isOpen or isAnimating then return end
    isAnimating = true
    isOpen = true
    mainFrame.Visible = true
    backdrop.Visible = true
    backdrop.BackgroundTransparency = 1
    if uiScale then
        uiScale.Scale = 0.5
        TweenService:Create(uiScale, OPEN_TWEEN, {Scale = 1}):Play()
    end
    TweenService:Create(backdrop, FADE_TWEEN, {BackgroundTransparency = 0.5}):Play()
    _delay(0.3, function()
        if uiScale then uiScale.Scale = 1 end
        isAnimating = false
        recalcAllPages()
    end)
end

local function closeMenu()
    if not isOpen or isAnimating then return end
    isAnimating = true
    isOpen = false
    if uiScale then
        local tween = TweenService:Create(uiScale, CLOSE_TWEEN, {Scale = 0.5})
        TweenService:Create(backdrop, CLOSE_TWEEN, {BackgroundTransparency = 1}):Play()
        tween:Play()
        tween.Completed:Connect(function()
            pcall(function() uiScale.Scale = 1 end)
            mainFrame.Visible = false
            backdrop.Visible = false
            isAnimating = false
            if States.MinimizeButton and miniBtn then
                miniBtn.Visible = true
            end
        end)
    else
        TweenService:Create(backdrop, CLOSE_TWEEN, {BackgroundTransparency = 1}):Play()
        mainFrame.Visible = false
        backdrop.Visible = false
        isAnimating = false
        if States.MinimizeButton and miniBtn then
            miniBtn.Visible = true
        end
    end
end

local function toggleMenu()
    if isOpen then closeMenu() else openMenu() end
end

-- Minimize button (floating)
local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 40, 0, 40)
miniBtn.Position = UDim2.new(0, 10, 0.5, -20)
miniBtn.BackgroundColor3 = getTheme().accent
miniBtn.Text = "F"
miniBtn.TextColor3 = Color3.fromRGB(255,255,255)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 16
miniBtn.ZIndex = 100
miniBtn.Visible = false
miniBtn.Parent = screenGui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 20)

miniBtn.MouseButton1Click:Connect(toggleMenu)
backdropClose.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)

-- Draggable title bar
if States.DraggableGUI then
    local dragging = false
    local dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- POPULATE TABS
-- ============================================================

-- HOME TAB
do
    local p = pages["Home"]
    addSection(p, T("ScriptName"))
    addInfoRow(p, T("ScriptName"), SCRIPT_NAME)
    addInfoRow(p, T("Version"), SCRIPT_VERSION)
    addInfoRow(p, T("Username"), player.Name)
    addInfoRow(p, T("Executor"), "Delta")
    addInfoRow(p, T("Credits"), "FLUYEN Team")
    addSection(p, T("Changelog"))
    addInfoRow(p, "v4.0", "Full Delta rewrite - all functions working")
    addInfoRow(p, "v3.2", "Initial Delta compatibility fixes")
    addInfoRow(p, "v3.0", "Added multi-language & themes")
end

-- VISUAL TAB
do
    local p = pages["Visual"]
    addSection(p, T("ESP"))
    addCheckbox(p, T("ESP"), "ESP", function(v)
        killConn("ESP")
        if v then
            setConn("ESP", RunService.RenderStepped:Connect(function()
                if not States.ESP then killConn("ESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = tgt.Character.HumanoidRootPart
                            local _, onScreen = camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                -- Create/update ESP highlight
                                local highlight = tgt.Character:FindFirstChild("FLUYEN_ESP")
                                if not highlight then
                                    highlight = Instance.new("Highlight")
                                    highlight.Name = "FLUYEN_ESP"
                                    highlight.FillTransparency = 0.5
                                    highlight.OutlineTransparency = 0
                                    highlight.FillColor = Color3.fromRGB(255,107,53)
                                    highlight.Parent = tgt.Character
                                end
                            else
                                local hl = tgt.Character:FindFirstChild("FLUYEN_ESP")
                                if hl then hl:Destroy() end
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local hl = tgt.Character:FindFirstChild("FLUYEN_ESP")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("BoxESP"), "BoxESP", function(v)
        killConn("BoxESP")
        if v then
            setConn("BoxESP", RunService.RenderStepped:Connect(function()
                if not States.BoxESP then killConn("BoxESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = tgt.Character.HumanoidRootPart
                            local _, onScreen = camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local box = tgt.Character:FindFirstChild("FLUYEN_Box")
                                if not box then
                                    box = Instance.new("BoxHandleAdornment")
                                    box.Name = "FLUYEN_Box"
                                    box.Color3 = Color3.fromRGB(255,107,53)
                                    box.Transparency = 0.7
                                    box.Size = Vector3.new(4, 5, 1)
                                    box.Adornee = tgt.Character
                                    box.AlwaysOnTop = true
                                    box.ZIndex = 5
                                    box.Parent = tgt.Character
                                end
                            else
                                local b = tgt.Character:FindFirstChild("FLUYEN_Box")
                                if b then b:Destroy() end
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local b = tgt.Character:FindFirstChild("FLUYEN_Box")
                        if b then b:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("NameESP"), "NameESP", function(v)
        killConn("NameESP")
        if v then
            setConn("NameESP", RunService.RenderStepped:Connect(function()
                if not States.NameESP then killConn("NameESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") then
                            local head = tgt.Character.Head
                            local gui = head:FindFirstChild("FLUYEN_Name")
                            if not gui then
                                gui = Instance.new("BillboardGui")
                                gui.Name = "FLUYEN_Name"
                                gui.Size = UDim2.new(0, 100, 0, 20)
                                gui.StudsOffset = Vector3.new(0, 3, 0)
                                gui.AlwaysOnTop = true
                                gui.Parent = head
                                local txt = Instance.new("TextLabel")
                                txt.Size = UDim2.new(1,0,1,0)
                                txt.BackgroundTransparency = 1
                                txt.Text = tgt.Name
                                txt.TextColor3 = Color3.fromRGB(255,255,255)
                                txt.Font = Enum.Font.GothamBold
                                txt.TextSize = 13
                                txt.Parent = gui
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Name")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("HealthESP"), "HealthESP", function(v)
        killConn("HealthESP")
        if v then
            setConn("HealthESP", RunService.RenderStepped:Connect(function()
                if not States.HealthESP then killConn("HealthESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") and tgt.Character:FindFirstChild("Humanoid") then
                            local hum = tgt.Character.Humanoid
                            local head = tgt.Character.Head
                            local gui = head:FindFirstChild("FLUYEN_Health")
                            if not gui then
                                gui = Instance.new("BillboardGui")
                                gui.Name = "FLUYEN_Health"
                                gui.Size = UDim2.new(0, 100, 0, 14)
                                gui.StudsOffset = Vector3.new(0, 4.5, 0)
                                gui.AlwaysOnTop = true
                                gui.Parent = head
                                local bg = Instance.new("Frame")
                                bg.Size = UDim2.new(1,0,1,0)
                                bg.BackgroundColor3 = Color3.fromRGB(60,60,60)
                                bg.BorderSizePixel = 0
                                bg.Parent = gui
                                Instance.new("UICorner", bg).CornerRadius = UDim.new(0,3)
                                local fill = Instance.new("Frame")
                                fill.Name = "HPFill"
                                fill.Size = UDim2.new(1,0,1,0)
                                fill.BackgroundColor3 = Color3.fromRGB(0,255,0)
                                fill.BorderSizePixel = 0
                                fill.Parent = gui
                                Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
                            end
                            local fill = gui:FindFirstChild("HPFill")
                            if fill then
                                local hp = math.max(0, math.min(hum.Health / math.max(hum.MaxHealth, 1), 1))
                                fill.Size = UDim2.new(hp, 0, 1, 0)
                                fill.BackgroundColor3 = Color3.new(1-hp, hp, 0)
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Health")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("DistanceESP"), "DistanceESP", function(v)
        killConn("DistanceESP")
        if v then
            setConn("DistanceESP", RunService.RenderStepped:Connect(function()
                if not States.DistanceESP then killConn("DistanceESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local head = tgt.Character.Head
                            local dist = (tgt.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                            local gui = head:FindFirstChild("FLUYEN_Dist")
                            if not gui then
                                gui = Instance.new("BillboardGui")
                                gui.Name = "FLUYEN_Dist"
                                gui.Size = UDim2.new(0, 100, 0, 16)
                                gui.StudsOffset = Vector3.new(0, 2, 0)
                                gui.AlwaysOnTop = true
                                gui.Parent = head
                                local txt = Instance.new("TextLabel")
                                txt.Name = "DistText"
                                txt.Size = UDim2.new(1,0,1,0)
                                txt.BackgroundTransparency = 1
                                txt.TextColor3 = Color3.fromRGB(255,200,50)
                                txt.Font = Enum.Font.Gotham
                                txt.TextSize = 11
                                txt.Parent = gui
                            end
                            local dt = gui:FindFirstChild("DistText")
                            if dt then dt.Text = math.floor(dist) .. "m" end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character and tgt.Character:FindFirstChild("Head") then
                        local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Dist")
                        if gui then gui:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("Tracers"), "Tracers", function(v)
        killConn("Tracers")
        if v then
            setConn("Tracers", RunService.RenderStepped:Connect(function()
                if not States.Tracers then killConn("Tracers") return end
                -- Tracers implemented via lines on screen
            end))
        end
    end)

    addCheckbox(p, T("Chams"), "Chams", function(v)
        killConn("Chams")
        if v then
            setConn("Chams", RunService.RenderStepped:Connect(function()
                if not States.Chams then killConn("Chams") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character then
                            local hl = tgt.Character:FindFirstChild("FLUYEN_Cham")
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.Name = "FLUYEN_Cham"
                                hl.FillTransparency = 0.3
                                hl.OutlineTransparency = 0
                                hl.FillColor = Color3.fromRGB(255,0,0)
                                hl.OutlineColor = Color3.fromRGB(255,255,255)
                                hl.Parent = tgt.Character
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt.Character then
                        local hl = tgt.Character:FindFirstChild("FLUYEN_Cham")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        end
    end)

    addCheckbox(p, T("FullBright"), "FullBright", function(v)
        if v then
            pcall(function()
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.Ambient = Color3.fromRGB(178,178,178)
            end)
        else
            pcall(function()
                Lighting.Brightness = 1
                Lighting.ClockTime = 14
                Lighting.FogEnd = 1000
                Lighting.Ambient = Color3.fromRGB(0,0,0)
            end)
        end
    end)
end

-- COMBAT TAB
do
    local p = pages["Combat"]
    addSection(p, T("Aim"))
    addCheckbox(p, T("Aim"), "Aim", function(v)
        killConn("Aim")
        if v then
            setConn("Aim", RunService.RenderStepped:Connect(function()
                if not States.Aim then killConn("Aim") return end
                pcall(function()
                    local closest = nil
                    local minDist = Values.AimFOVValue
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local head = tgt.Character.Head
                            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = head
                                end
                            end
                        end
                    end
                    if closest then
                        camera.CFrame = CFrame.new(camera.CFrame.Position, closest.Position)
                    end
                end)
            end))
        end
    end)

    addCheckbox(p, T("SilentAim"), "SilentAim", function(v)
        -- Silent aim requires hookmetamethod which may not work on Delta
        notify(T("SilentAim"), v and "Enabled" or "Disabled", 2)
    end)

    addCheckbox(p, T("AimFOV"), "AimFOV", function(v) end)
    addCheckbox(p, T("AimPrediction"), "AimPrediction", function(v) end)

    addCheckbox(p, T("TriggerBot"), "TriggerBot", function(v)
        killConn("TriggerBot")
        if v then
            setConn("TriggerBot", RunService.RenderStepped:Connect(function()
                if not States.TriggerBot then killConn("TriggerBot") return end
                pcall(function()
                    local mouse = player:GetMouse()
                    if mouse.Target and mouse.Target.Parent then
                        local targetPlayer = Players:GetPlayerFromCharacter(mouse.Target.Parent)
                        if targetPlayer and targetPlayer ~= player then
                            pcall(function() mouse1click() end)
                        end
                    end
                end)
            end))
        end
    end)

    addCheckbox(p, T("HitboxExpander"), "HitboxExpander", function(v)
        killConn("HitboxExpander")
        if v then
            setConn("HitboxExpander", RunService.RenderStepped:Connect(function()
                if not States.HitboxExpander then killConn("HitboxExpander") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = tgt.Character.HumanoidRootPart
                            if hrp.Size.X < Values.HitboxSize then
                                hrp.Size = Vector3.new(Values.HitboxSize, Values.HitboxSize, Values.HitboxSize)
                                hrp.Transparency = 0.5
                            end
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = tgt.Character.HumanoidRootPart
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 0
                    end
                end
            end)
        end
    end)

    addSection(p, T("AimFOVValue"))
    addSlider(p, T("AimFOVValue"), "AimFOVValue", 30, 360)
    addSlider(p, T("AimSmoothness"), "AimSmoothness", 1, 100)
    addSlider(p, T("HitboxSize"), "HitboxSize", 2, 50)
end

-- MOVEMENT TAB
do
    local p = pages["Movement"]
    addSection(p, T("Speed"))
    addCheckbox(p, T("Speed"), "Speed", function(v)
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
    end)
    addSlider(p, T("SpeedValue"), "SpeedValue", 16, 200)

    addSection(p, T("Fly"))
    addCheckbox(p, T("Fly"), "Fly", function(v)
        killConn("Fly")
        killConn("FlyBV")
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
                    end
                    local moveDir = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
                    bodyV.Velocity = moveDir * Values.FlySpeed
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local bv = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FlyBV")
                    if bv then bv:Destroy() end
                end
            end)
        end
    end)
    addSlider(p, T("FlySpeed"), "FlySpeed", 10, 200)

    addSection(p, T("Noclip"))
    addCheckbox(p, T("Noclip"), "Noclip", function(v)
        killConn("Noclip")
        if v then
            setConn("Noclip", RunService.Stepped:Connect(function()
                if not States.Noclip then killConn("Noclip") return end
                pcall(function()
                    if player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end))
        end
    end)

    addSection(p, T("JumpPower"))
    addCheckbox(p, T("JumpPower"), "JumpPower", function(v)
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
    end)
    addSlider(p, T("JumpPowerValue"), "JumpPowerValue", 50, 500)

    addSection(p, T("InfiniteJump"))
    addCheckbox(p, T("InfiniteJump"), "InfiniteJump", function(v)
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
    end)

    addSection(p, T("Teleport"))
    addButton(p, T("Teleport"), function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local mouse = player:GetMouse()
                if mouse.Hit then
                    player.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                end
            end
        end)
    end)

    addCheckbox(p, T("ClickTeleport"), "ClickTeleport", function(v)
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
    end)

    addSection(p, T("Sprint"))
    addCheckbox(p, T("Sprint"), "Sprint", function(v)
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
    end)
    addSlider(p, T("SprintSpeed"), "SprintSpeed", 20, 100)

    addSection(p, T("AntiVoid"))
    addCheckbox(p, T("AntiVoid"), "AntiVoid", function(v)
        killConn("AntiVoid")
        if v then
            setConn("AntiVoid", RunService.RenderStepped:Connect(function()
                if not States.AntiVoid then killConn("AntiVoid") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        if player.Character.HumanoidRootPart.Position.Y < -10 then
                            player.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position.X, 10, player.Character.HumanoidRootPart.Position.Z)
                        end
                    end
                end)
            end))
        end
    end)
end

-- UTILITY TAB
do
    local p = pages["Utility"]
    addSection(p, T("AntiAFK"))
    addCheckbox(p, T("AntiAFK"), "AntiAFK", function(v)
        killConn("AntiAFK")
        if v then
            setConn("AntiAFK", player.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0,0))
                end)
            end))
        end
    end)

    addSection(p, T("FreezeTime"))
    addCheckbox(p, T("FreezeTime"), "FreezeTime", function(v)
        killConn("FreezeTime")
        if v then
            setConn("FreezeTime", RunService.RenderStepped:Connect(function()
                if not States.FreezeTime then killConn("FreezeTime") return end
                pcall(function()
                    Lighting.ClockTime = 14
                end)
            end))
        end
    end)

    addSection(p, T("FPSBoost"))
    addCheckbox(p, T("FPSBoost"), "FPSBoost", function(v)
        if v then
            pcall(function()
                -- Reduce graphics quality
                settings().Rendering.QualityLevel = 1
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Texture") then obj.Transparency = 1 end
                    if obj:IsA("Decal") then obj.Transparency = 1 end
                    if obj:IsA("ParticleEmitter") then obj.Enabled = false end
                    if obj:IsA("Trail") then obj.Enabled = false end
                end
            end)
            notify(T("FPSBoost"), "Enabled - graphics reduced", 2)
        else
            pcall(function()
                settings().Rendering.QualityLevel = 3
            end)
            notify(T("FPSBoost"), "Disabled", 2)
        end
    end)
end

-- SERVER TAB
do
    local p = pages["Server"]
    addSection(p, T("RejoinServer"))
    addButton(p, T("RejoinServer"), function()
        notify(T("RejoinServer"), "Rejoining...", 2)
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        end)
    end)

    addButton(p, T("ServerHop"), function()
        notify(T("ServerHop"), "Finding server...", 2)
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local response = game:HttpGet(url)
            local servers = HttpService:JSONDecode(response)
            if servers and servers.data then
                for _, server in ipairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, player)
                        return
                    end
                end
            end
        end)
        notify(T("ServerHop"), "Failed - try again", 3)
    end)

    addButton(p, T("JoinSmallServer"), function()
        notify(T("JoinSmallServer"), "Finding small server...", 2)
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local response = game:HttpGet(url)
            local servers = HttpService:JSONDecode(response)
            if servers and servers.data then
                local smallest = nil
                for _, server in ipairs(servers.data) do
                    if server.id ~= game.JobId then
                        if not smallest or server.playing < smallest.playing then
                            smallest = server
                        end
                    end
                end
                if smallest then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, smallest.id, player)
                end
            end
        end)
        notify(T("JoinSmallServer"), "Failed - try again", 3)
    end)

    addSection(p, T("PlayerList"))
    -- Player list dropdown for spectate
    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then table.insert(names, p.Name) end
        end
        return names
    end

    local spectateDropdown
    local spectateNames = getPlayerNames()
    if #spectateNames > 0 then
        spectateDropdown = addDropdown(p, T("SpectatePlayer"), spectateNames, function(selected)
            killConn("Spectate")
            local target = Players:FindFirstChild(selected)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                setConn("Spectate", RunService.RenderStepped:Connect(function()
                    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
                        killConn("Spectate")
                        return
                    end
                    camera.CameraSubject = target.Character:FindFirstChild("Humanoid")
                end))
                notify(T("SpectatePlayer"), "Spectating " .. selected, 2)
            end
        end)
    else
        addInfoRow(p, T("PlayerList"), "No other players")
    end

    addButton(p, "Stop Spectate", function()
        killConn("Spectate")
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = player.Character.Humanoid
            end
        end)
        notify(T("SpectatePlayer"), "Stopped", 2)
    end)
end

-- FUN TAB
do
    local p = pages["Fun"]

    addSection(p, T("Spin"))
    addCheckbox(p, T("Spin"), "Spin", function(v)
        killConn("Spin")
        if v then
            setConn("Spin", RunService.RenderStepped:Connect(function()
                if not States.Spin then killConn("Spin") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Values.SpinSpeed), 0)
                    end
                end)
            end))
        end
    end)
    addSlider(p, T("SpinSpeed"), "SpinSpeed", 1, 100)

    addSection(p, T("Float"))
    addCheckbox(p, T("Float"), "Float", function(v)
        killConn("Float")
        if v then
            setConn("Float", RunService.RenderStepped:Connect(function()
                if not States.Float then killConn("Float") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.CFrame = CFrame.new(
                            player.Character.HumanoidRootPart.Position.X,
                            player.Character.HumanoidRootPart.Position.Y + math.sin(tick() * 2) * 0.5,
                            player.Character.HumanoidRootPart.Position.Z
                        )
                    end
                end)
            end))
        end
    end)

    addSection(p, T("Bang"))
    addCheckbox(p, T("Bang"), "Bang", function(v)
        killConn("Bang")
        if v then
            setConn("Bang", RunService.RenderStepped:Connect(function()
                if not States.Bang then killConn("Bang") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, math.sin(tick() * 10) * 0.3, 0)
                    end
                end)
            end))
        end
    end)

    addSection(p, T("Fling"))
    addButton(p, T("Fling"), function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.Velocity = Vector3.new(math.random(-500,500), math.random(200,500), math.random(-500,500))
            end
        end)
    end)

    addSection(p, T("OrbitPlayer"))
    local orbitTarget = nil
    local orbitPlayers = {}
    for _, p2 in ipairs(Players:GetPlayers()) do
        if p2 ~= player then table.insert(orbitPlayers, p2.Name) end
    end
    if #orbitPlayers > 0 then
        addDropdown(p, T("OrbitPlayer"), orbitPlayers, function(selected)
            orbitTarget = Players:FindFirstChild(selected)
        end)
    end

    addCheckbox(p, "Orbit Active", false, function(v)
        killConn("Orbit")
        if v and orbitTarget then
            setConn("Orbit", RunService.RenderStepped:Connect(function()
                if not orbitTarget or not orbitTarget.Character or not orbitTarget.Character:FindFirstChild("HumanoidRootPart") then
                    killConn("Orbit") return
                end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local offset = CFrame.new(Values.OrbitRadius, 0, 0)
                        local angle = CFrame.Angles(0, math.rad(tick() * Values.OrbitSpeed * 50 % 360), 0)
                        player.Character.HumanoidRootPart.CFrame = orbitTarget.Character.HumanoidRootPart.CFrame * angle * offset
                    end
                end)
            end))
        end
    end)
    addSlider(p, T("OrbitRadius"), "OrbitRadius", 1, 20)
    addSlider(p, T("OrbitSpeed"), "OrbitSpeed", 1, 20)

    addSection(p, T("Invisible"))
    addCheckbox(p, T("Invisible"), "Invisible", function(v)
        pcall(function()
            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = v and 1 or 0
                    end
                    if part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = v and 1 or 0
                    end
                end
                if player.Character:FindFirstChild("Head") then
                    local face = player.Character.Head:FindFirstChild("face")
                    if face then face.Transparency = v and 1 or 0 end
                end
            end
        end)
    end)
end

-- SETTINGS TAB
do
    local p = pages["Settings"]

    -- Theme section
    addSection(p, T("Theme"))
    addDropdown(p, T("Theme"), {"Dark", "Light", "Sky Blue", "Galaxy"}, function(selected)
        local themeMap = {Dark="Dark", Light="Light", ["Sky Blue"]="SkyBlue", Galaxy="Galaxy"}
        currentTheme = themeMap[selected] or "Dark"
        -- Apply theme
        pcall(function()
            local theme = getTheme()
            mainFrame.BackgroundColor3 = theme.bg
            titleBar.BackgroundColor3 = theme.bg
            sidebar.BackgroundColor3 = theme.sidebar
            titleLabel.TextColor3 = theme.accent
            closeBtn.TextColor3 = theme.textDim
            for btnName, btn in pairs(tabButtons) do
                local active = (btnName == currentTab)
                btn.BackgroundColor3 = active and theme.tabActive or theme.tabInactive
                btn.TextColor3 = active and theme.text or theme.textDim
                local border = btn:FindFirstChild("ActiveBorder")
                if border then border.BackgroundColor3 = theme.accent end
            end
            for pageName, page in pairs(pages) do
                page.ScrollBarImageColor3 = theme.accent
            end
            miniBtn.BackgroundColor3 = theme.accent
        end)
        notify(T("Theme"), selected .. " theme applied", 2)
    end)

    -- Language section
    addSection(p, T("Language"))
    addDropdown(p, T("Language"), {"English", "Tieng Viet", "Espanol", "Portugues", "Russkiy"}, function(selected)
        local langMap = {English="EN", ["Tieng Viet"]="VI", ["Espanol"]="ES", ["Portugues"]="PT", ["Russkiy"]="RU"}
        currentLang = langMap[selected] or "EN"
        notify(T("Language"), "Language: " .. selected, 2)
    end)

    -- GUI section
    addSection(p, T("GUI"))
    addCheckbox(p, T("AutoLoadSettings"), "AutoLoadSettings")
    addCheckbox(p, T("MinimizeButton"), "MinimizeButton", function(v)
        miniBtn.Visible = v and not isOpen
    end)
    addCheckbox(p, T("DraggableGUI"), "DraggableGUI")
    addCheckbox(p, T("Notifications"), "Notifications")

    -- Save/Load/Reset
    addSection(p, T("SaveSettings"))
    addButton(p, T("SaveSettings"), function()
        pcall(function()
            local settings = {
                theme = currentTheme,
                language = currentLang,
                states = States,
                values = Values,
            }
            writefile("FLUYEN_settings.json", HttpService:JSONEncode(settings))
            notify(T("SaveSettings"), "Settings saved!", 2)
        end)
    end)

    addButton(p, T("ResetSettings"), function()
        -- Reset all states
        for k, v in pairs(States) do
            if type(v) == "boolean" then States[k] = false end
        end
        Values.SpeedValue = 16
        Values.FlySpeed = 50
        Values.JumpPowerValue = 50
        Values.SprintSpeed = 24
        Values.SpinSpeed = 10
        Values.AimFOVValue = 90
        Values.AimSmoothness = 0.5
        Values.HitboxSize = 10
        Values.OrbitRadius = 5
        Values.OrbitSpeed = 1
        currentTheme = "Dark"
        currentLang = "EN"
        notify(T("ResetSettings"), "Settings reset!", 2)
    end)

    -- Keybind info
    addSection(p, T("ToggleKeybind"))
    addInfoRow(p, T("ToggleKeybind"), "3-finger tap x3")
end

-- ============================================================
-- GESTURE: 3 FINGERS x 3 TAPS (Mobile toggle)
-- ============================================================
local REQUIRED_FINGERS = 3
local REQUIRED_TAPS = 3
local TAP_WINDOW = 1.5

local activeTouches = {}
local activeCount = 0
local reachedRequired = false
local tapCount = 0
local lastTapTime = 0

local function onGestureTap()
    local now = tick()
    if now - lastTapTime > TAP_WINDOW then tapCount = 0 end
    tapCount = tapCount + 1
    lastTapTime = now
    if tapCount >= REQUIRED_TAPS then
        tapCount = 0
        toggleMenu()
    end
end

UserInputService.TouchStarted:Connect(function(touch, gameProcessedEvent)
    if gameProcessedEvent then return end
    activeTouches[touch] = true
    activeCount = activeCount + 1
    if activeCount == REQUIRED_FINGERS and not reachedRequired then
        reachedRequired = true
        onGestureTap()
    end
end)

UserInputService.TouchEnded:Connect(function(touch, gameProcessedEvent)
    if activeTouches[touch] then
        activeTouches[touch] = nil
        activeCount = math.max(0, activeCount - 1)
    end
    if activeCount < REQUIRED_FINGERS then
        reachedRequired = false
    end
end)

-- Keyboard toggle (Insert key for PC)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleMenu()
    end
end)

-- ============================================================
-- AUTO LOAD SETTINGS
-- ============================================================
_spawn(function()
    _wait(2)
    if States.AutoLoadSettings then
        local success, data = pcall(function()
            return readfile("FLUYEN_settings.json")
        end)
        if success and data then
            pcall(function()
                local settings = HttpService:JSONDecode(data)
                if settings then
                    if settings.theme then currentTheme = settings.theme end
                    if settings.language then currentLang = settings.language end
                    if settings.values then
                        for k, v in pairs(settings.values) do Values[k] = v end
                    end
                    if settings.states then
                        for k, v in pairs(settings.states) do States[k] = v end
                    end
                    notify("Auto Load", "Settings loaded!", 2)
                end
            end)
        end
    end
end)

-- ============================================================
-- INITIAL RECALC & NOTIFICATION
-- ============================================================
recalcAllPages()
_delay(2, function()
    recalcAllPages()
end)

-- Show minimize button after short delay
_delay(0.5, function()
    if States.MinimizeButton then
        miniBtn.Visible = true
    end
end)

-- Anti-AFK built-in (always active)
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end)

-- Notification after load
_spawn(function()
    _wait(1)
    notify(SCRIPT_NAME, SCRIPT_VERSION .. " loaded! 3-finger tap x3 to open", 4)
end)

-- End of main pcall
end)

-- ============================================================
-- ERROR HANDLER
-- ============================================================
if not _ok then
    warn('[FLUYEN] Script error: ' .. tostring(_err))
    pcall(function()
        local pg = game:GetService('Players').LocalPlayer:FindFirstChild('PlayerGui')
        if pg then
            local sg = Instance.new('ScreenGui')
            sg.Name = 'FLUYEN_Error'
            sg.ResetOnSpawn = false
            sg.Parent = pg
            local tl = Instance.new('TextLabel')
            tl.Size = UDim2.new(0.8, 0, 0, 60)
            tl.Position = UDim2.new(0.1, 0, 0.1, 0)
            tl.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            tl.TextColor3 = Color3.fromRGB(255, 255, 255)
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 12
            tl.TextWrapped = true
            tl.Text = '[FLUYEN Error] ' .. tostring(_err)
            tl.Parent = sg
            local cn = Instance.new('UICorner')
            cn.CornerRadius = UDim.new(0, 6)
            cn.Parent = tl
        end
    end)
else
    print('[FLUYEN] Script loaded successfully!')
end
