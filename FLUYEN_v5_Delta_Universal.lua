--[[
  FLUYEN HUD MENU - DELTA UNIVERSAL EDITION v5.0
  Complete rewrite for Delta executor (Android/Mobile)
  All functions working | All tabs | Full compatibility
  v5: ESP Lines, FOV Circle, Key System, Lag Fix, Language Fix, More Features
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
local SCRIPT_VERSION = "v5.1"

-- ============================================================
-- KEY SYSTEM - key = huyandkhang
-- ============================================================
local VALID_KEY = "huyandkhang"
local keyAuthenticated = false

local function checkKey()
    return keyAuthenticated
end

-- Try auto-load key from file
pcall(function()
    local saved = readfile("FLUYEN_key.txt")
    if saved == VALID_KEY then
        keyAuthenticated = true
    end
end)

-- ============================================================
-- STATES & VALUES
-- ============================================================
local States = {
    ESP=false, BoxESP=false, NameESP=false, HealthESP=false, DistanceESP=false,
    Tracers=false, Chams=false, FullBright=false, NightVision=false, Xray=false,
    Aim=false, SilentAim=false, AimFOV=false, AimPrediction=false, TriggerBot=false, HitboxExpander=false,
    Speed=false, Fly=false, Noclip=false, JumpPower=false, InfiniteJump=false, ClickTeleport=false, Sprint=false, AntiVoid=false,
    AntiAFK=true, FreezeTime=false, FPSBoost=false,
    AntiBlind=false, AntiSlow=false, AntiRagdoll=false, AntiGrab=false,
    Spin=false, Float=false, Bang=false, Fling=false, Invisible=false, OrbitActive=false,
    LowGravity=false, Freecam=false,
    AutoLoadSettings=false, MinimizeButton=true, DraggableGUI=true, Notifications=true,
}

local Values = {
    SpeedValue=16, FlySpeed=50, JumpPowerValue=50, SprintSpeed=24,
    SpinSpeed=10, AimFOVValue=90, AimSmoothness=5, HitboxSize=10,
    OrbitRadius=5, OrbitSpeed=1, FlingPower=500, FieldOfView=70,
    LowGravityValue=50,
}

-- Connections
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

-- ============================================================
-- THEME SYSTEM
-- ============================================================
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

-- ============================================================
-- LANGUAGE SYSTEM with live update tracking
-- ============================================================
local currentLang = "EN"
local Langs = {}
Langs.EN = {
    Home="Home", Visual="Visual", Combat="Combat", Movement="Movement",
    Utility="Utility", Server="Server", Fun="Fun", Settings="Settings",
    ScriptName="Script Name", Version="Version", Username="Username",
    Executor="Executor", Credits="Credits", Changelog="Changelog",
    ESP="ESP (Highlight)", BoxESP="Box ESP", NameESP="Name ESP", HealthESP="Health ESP",
    DistanceESP="Distance ESP", Tracers="Tracer Lines", Chams="Chams/X-Ray", FullBright="Full Bright",
    NightVision="Night Vision", Xray="X-Ray Mode",
    Aim="Aimbot", SilentAim="Silent Aim", AimFOV="Aim FOV Circle", AimPrediction="Aim Prediction",
    TriggerBot="Trigger Bot", HitboxExpander="Hitbox Expander",
    AimFOVValue="Aim FOV", AimSmoothness="Aim Smoothness", HitboxSize="Hitbox Size",
    Speed="Speed Hack", Fly="Fly", Noclip="Noclip", JumpPower="Jump Power",
    InfiniteJump="Infinite Jump", Teleport="Teleport to Cursor", ClickTeleport="Click Teleport",
    Sprint="Sprint (Shift)", AntiVoid="Anti Void",
    SpeedValue="Speed", FlySpeed="Fly Speed", JumpPowerValue="Jump Power", SprintSpeed="Sprint Speed",
    AntiAFK="Anti AFK", FreezeTime="Freeze Time", FPSBoost="FPS Booster",
    AntiBlind="Anti Blind", AntiSlow="Anti Slow", AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Grab",
    RejoinServer="Rejoin Server", ServerHop="Server Hop", JoinSmallServer="Join Small Server",
    PlayerList="Player List", SpectatePlayer="Spectate Player",
    Spin="Spin", Float="Float", Bang="Bang", Fling="Fling",
    OrbitPlayer="Orbit Player", Invisible="Invisible",
    LowGravity="Low Gravity", LowGravityValue="Gravity Level", Freecam="Freecam",
    Respawn="Respawn", TeleportToSpawn="Teleport to Spawn",
    SpinSpeed="Spin Speed", OrbitRadius="Orbit Radius", OrbitSpeed="Orbit Speed", FlingPower="Fling Power",
    Theme="Theme", Language="Language", GUI="GUI Settings",
    SaveSettings="Save Settings", AutoLoadSettings="Auto Load Settings",
    ResetSettings="Reset All Settings", MinimizeButton="Minimize Button",
    DraggableGUI="Draggable GUI", ToggleKeybind="Toggle Keybind", Notifications="Notifications",
    Dark="Dark", Light="Light", SkyBlue="Sky Blue", Galaxy="Galaxy",
    English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    Enabled="Enabled", Disabled="Disabled", Loaded="loaded! 3-finger tap x3",
    KeySystem="Key System", EnterKey="Enter Key", SubmitKey="Submit", KeyStatus="Key Status",
    KeyRequired="Key required to use features", KeyAccepted="Key accepted! All features unlocked",
    KeyWrong="Wrong key! Try again", FieldOfView="Field of View", PlayersOnline="Players Online",
    StopSpectate="Stop Spectate", OrbitActive="Orbit Active", FOVCircle="FOV Circle",
}
Langs.VI = {
    Home="Trang Chu", Visual="Hinh Anh", Combat="Chien Dau", Movement="Di Chuyen",
    Utility="Tien Ich", Server="May Chu", Fun="Giai Tri", Settings="Cai Dat",
    ScriptName="Ten Script", Version="Phien Ban", Username="Nguoi Dung",
    Executor="Trinh Thuc Thi", Credits="Tac Gia", Changelog="Nhat Ky",
    ESP="ESP (Toi Sang)", BoxESP="Hop ESP", NameESP="Ten ESP", HealthESP="Mau ESP",
    DistanceESP="Khoang Cach ESP", Tracers="Duong Esp", Chams="Chams/X-Ray", FullBright="Sang Toan Bo",
    NightVision="Thi Ban Dem", Xray="X-Ray",
    Aim="Tu Ngam", SilentAim="Ngam Am", AimFOV="Vong Ngam", AimPrediction="Du Doan",
    TriggerBot="Bot Ban", HitboxExpander="Mo Rong Hitbox",
    AimFOVValue="Ngam FOV", AimSmoothness="Do Muot", HitboxSize="Kich Thuoc Hitbox",
    Speed="Tang Toc", Fly="Bay", Noclip="Xuyen Tuong", JumpPower="Luc Nhay",
    InfiniteJump="Nhay Vo Han", Teleport="Dich Chuyen", ClickTeleport="Click Dich Chuyen",
    Sprint="Chay Nhanh (Shift)", AntiVoid="Chong Rot",
    SpeedValue="Toc Do", FlySpeed="Toc Do Bay", JumpPowerValue="Luc Nhay", SprintSpeed="Toc Do Chay",
    AntiAFK="Chong AFK", FreezeTime="Dong Thoi Gian", FPSBoost="Tang FPS",
    AntiBlind="Chong Mu", AntiSlow="Chong Cham", AntiRagdoll="Chong Nguoi Nhap", AntiGrab="Chong Keo",
    RejoinServer="Vao Lai", ServerHop="Chuyen May Chu", JoinSmallServer="May Chu Nho",
    PlayerList="Danh Sach", SpectatePlayer="Theo Doi",
    Spin="Xoay", Float="Bay Lang", Bang="Dam", Fling="Nem",
    OrbitPlayer="Quay Quanh", Invisible="Vo Hinh",
    LowGravity="Trong Luc Thap", LowGravityValue="Muc Trong Luc", Freecam="Cam Tu Do",
    Respawn="Hoi Sinh", TeleportToSpawn="Dich Den Sinh",
    SpinSpeed="Toc Do Xoay", OrbitRadius="Ban Kinh", OrbitSpeed="Toc Do Quay", FlingPower="Luc Nem",
    Theme="Giao Dien", Language="Ngon Ngu", GUI="Cai Dat GUI",
    SaveSettings="Luu", AutoLoadSettings="Tu Dong Tai",
    ResetSettings="Dat Lai", MinimizeButton="Nut Gop", DraggableGUI="Keo Duoc", ToggleKeybind="Phim Tat", Notifications="Thong Bao",
    Dark="Toi", Light="Sang", SkyBlue="Xanh Troi", Galaxy="Thien Ha",
    English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    Enabled="Bat", Disabled="Tat", Loaded="da tai! 3 ngon x3 lan",
    KeySystem="He Thong Key", EnterKey="Nhap Key", SubmitKey="Xac Nhan", KeyStatus="Trang Thai Key",
    KeyRequired="Can key de su dung", KeyAccepted="Key dung! Mo khoa tat ca",
    KeyWrong="Key sai! Thu lai", FieldOfView="Goc Nhin", PlayersOnline="Nguoi Choi Online",
    StopSpectate="Dung Theo Doi", OrbitActive="Quay Hoat Dong", FOVCircle="Vong FOV",
}
Langs.ES = {
    Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimiento",
    Utility="Utilidad", Server="Servidor", Fun="Diversion", Settings="Ajustes",
    ScriptName="Nombre", Version="Version", Username="Usuario",
    Executor="Ejecutor", Credits="Creditos", Changelog="Cambios",
    ESP="ESP (Resaltar)", BoxESP="Caja ESP", NameESP="Nombre ESP", HealthESP="Salud ESP",
    DistanceESP="Distancia ESP", Tracers="Lineas ESP", Chams="Chams/Rayos X", FullBright="Luz Total",
    NightVision="Vision Nocturna", Xray="Rayos X",
    Aim="Auto Apuntar", SilentAim="Apuntar Silencioso", AimFOV="Circulo FOV", AimPrediction="Prediccion",
    TriggerBot="Bot Disparo", HitboxExpander="Expandir Hitbox",
    AimFOVValue="FOV Apuntado", AimSmoothness="Suavidad", HitboxSize="Tam. Hitbox",
    Speed="Velocidad", Fly="Volar", Noclip="Noclip", JumpPower="Salto",
    InfiniteJump="Salto Infinito", Teleport="Teletransporte", ClickTeleport="Click Teleporte",
    Sprint="Sprint (Shift)", AntiVoid="Anti Vacio",
    SpeedValue="Velocidad", FlySpeed="Vel. Vuelo", JumpPowerValue="Salto", SprintSpeed="Vel. Sprint",
    AntiAFK="Anti AFK", FreezeTime="Congelar Tiempo", FPSBoost="Mas FPS",
    AntiBlind="Anti Ceguera", AntiSlow="Anti Lento", AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Agarre",
    RejoinServer="Reconectar", ServerHop="Cambiar Server", JoinSmallServer="Server Pequeno",
    PlayerList="Jugadores", SpectatePlayer="Espectar",
    Spin="Girar", Float="Flotar", Bang="Golpear", Fling="Lanzar",
    OrbitPlayer="Orbitar", Invisible="Invisible",
    LowGravity="Gravedad Baja", LowGravityValue="Nivel Gravedad", Freecam="Cam Libre",
    Respawn="Revivir", TeleportToSpawn="Teletransporte al Spawn",
    SpinSpeed="Vel. Giro", OrbitRadius="Radio Orbita", OrbitSpeed="Vel. Orbita", FlingPower="Fuerza Lanzar",
    Theme="Tema", Language="Idioma", GUI="Interfaz",
    SaveSettings="Guardar", AutoLoadSettings="Auto Cargar",
    ResetSettings="Reiniciar", MinimizeButton="Minimizar", DraggableGUI="Arrastrable", ToggleKeybind="Tecla Toggle", Notifications="Notificaciones",
    Dark="Oscuro", Light="Claro", SkyBlue="Cielo Azul", Galaxy="Galaxia",
    English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    Enabled="Activado", Disabled="Desactivado", Loaded="cargado! 3 dedos x3",
    KeySystem="Sistema Key", EnterKey="Ingresar Key", SubmitKey="Enviar", KeyStatus="Estado Key",
    KeyRequired="Key requerida para usar", KeyAccepted="Key aceptada! Desbloqueado",
    KeyWrong="Key incorrecta!", FieldOfView="Campo Vision", PlayersOnline="Jugadores Online",
    StopSpectate="Dejar Espectar", OrbitActive="Orbita Activa", FOVCircle="Circulo FOV",
}
Langs.PT = {
    Home="Inicio", Visual="Visual", Combat="Combate", Movement="Movimento",
    Utility="Utilidade", Server="Servidor", Fun="Diversao", Settings="Configuracoes",
    ScriptName="Nome", Version="Versao", Username="Usuario",
    Executor="Executor", Credits="Creditos", Changelog="Mudancas",
    ESP="ESP (Destacar)", BoxESP="Caixa ESP", NameESP="Nome ESP", HealthESP="Saude ESP",
    DistanceESP="Distancia ESP", Tracers="Linhas ESP", Chams="Chams/Raios X", FullBright="Luz Total",
    NightVision="Visao Noturna", Xray="Raios X",
    Aim="Auto Mirar", SilentAim="Mira Silenciosa", AimFOV="Circulo FOV", AimPrediction="Predicao",
    TriggerBot="Bot Disparo", HitboxExpander="Expandir Hitbox",
    AimFOVValue="FOV Mira", AimSmoothness="Suavidade", HitboxSize="Tam. Hitbox",
    Speed="Velocidade", Fly="Voar", Noclip="Noclip", JumpPower="Pulo",
    InfiniteJump="Pulo Infinito", Teleport="Teleporte", ClickTeleport="Click Teleporte",
    Sprint="Sprint (Shift)", AntiVoid="Anti Vazio",
    SpeedValue="Velocidade", FlySpeed="Vel. Voo", JumpPowerValue="Pulo", SprintSpeed="Vel. Sprint",
    AntiAFK="Anti AFK", FreezeTime="Congelar Tempo", FPSBoost="Mais FPS",
    AntiBlind="Anti Cegueira", AntiSlow="Anti Lento", AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Agarrar",
    RejoinServer="Reconectar", ServerHop="Trocar Server", JoinSmallServer="Server Pequeno",
    PlayerList="Jogadores", SpectatePlayer="Espectar",
    Spin="Girar", Float="Flutuar", Bang="Bater", Fling="Arremessar",
    OrbitPlayer="Orbitar", Invisible="Invisivel",
    LowGravity="Gravidade Baixa", LowGravityValue="Nivel Gravidade", Freecam="Cam Livre",
    Respawn="Renascer", TeleportToSpawn="Teleporte ao Spawn",
    SpinSpeed="Vel. Giro", OrbitRadius="Raio Orbita", OrbitSpeed="Vel. Orbita", FlingPower="Forca Arremesso",
    Theme="Tema", Language="Idioma", GUI="Interface",
    SaveSettings="Salvar", AutoLoadSettings="Auto Carregar",
    ResetSettings="Resetar", MinimizeButton="Minimizar", DraggableGUI="Arrastavel", ToggleKeybind="Tecla Toggle", Notifications="Notificacoes",
    Dark="Escuro", Light="Claro", SkyBlue="Ceu Azul", Galaxy="Galaxia",
    English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    Enabled="Ativado", Disabled="Desativado", Loaded="carregado! 3 dedos x3",
    KeySystem="Sistema Key", EnterKey="Inserir Key", SubmitKey="Enviar", KeyStatus="Status Key",
    KeyRequired="Key necessaria para usar", KeyAccepted="Key aceita! Desbloqueado",
    KeyWrong="Key errada!", FieldOfView="Campo Visao", PlayersOnline="Jogadores Online",
    StopSpectate="Parar Espectar", OrbitActive="Orbita Ativa", FOVCircle="Circulo FOV",
}
Langs.RU = {
    Home="Glavnaya", Visual="Vizual", Combat="Boi", Movement="Dvizhenie",
    Utility="Utilita", Server="Server", Fun="Razvlechenie", Settings="Nastroyki",
    ScriptName="Imya", Version="Versiya", Username="Polzovatel",
    Executor="Ispolnitel", Credits="Avtory", Changelog="Izmeneniya",
    ESP="ESP (Podsvetka)", BoxESP="Boks ESP", NameESP="Imya ESP", HealthESP="Zdorove ESP",
    DistanceESP="Rasstoyanie ESP", Tracers="Linii ESP", Chams="Chams/Rentgen", FullBright="Yarkost",
    NightVision="Nochnoe Zrenie", Xray="Rentgen",
    Aim="Avtopricel", SilentAim="Tihii Pricel", AimFOV="Krug FOV", AimPrediction="Predikciya",
    TriggerBot="Trigger Bot", HitboxExpander="Hitboks",
    AimFOVValue="Pricel FOV", AimSmoothness="Plavnost", HitboxSize="Razmer Hitboksa",
    Speed="Skorost", Fly="Polet", Noclip="Noklip", JumpPower="Prizhok",
    InfiniteJump="Beskonechnii Prizhok", Teleport="Teleport", ClickTeleport="Klik Teleport",
    Sprint="Sprint (Shift)", AntiVoid="Anti Proval",
    SpeedValue="Skorost", FlySpeed="Skorost Poleta", JumpPowerValue="Sila Prizhka", SprintSpeed="Skorost Sprinta",
    AntiAFK="Anti AFK", FreezeTime="Ostanovit Vremya", FPSBoost="FPS Bust",
    AntiBlind="Anti Slepota", AntiSlow="Anti Zamedlenie", AntiRagdoll="Anti Ragdoll", AntiGrab="Anti Hvatanie",
    RejoinServer="Pereiti", ServerHop="Smenit Server", JoinSmallServer="Malcii Server",
    PlayerList="Igroki", SpectatePlayer="Nablyudat",
    Spin="Vrashenie", Float="Parit", Bang="Udar", Fling="Brosit",
    OrbitPlayer="Orbita", Invisible="Nevidimost",
    LowGravity="Slabaya Gravitaciya", LowGravityValue="Uroven Gravitacii", Freecam="Svobodnaya Kamera",
    Respawn="Vozrodit", TeleportToSpawn="Teleport na Spawn",
    SpinSpeed="Skorost Vrasheniya", OrbitRadius="Radius Orbiy", OrbitSpeed="Skorost Orbiy", FlingPower="Sila Broska",
    Theme="Tema", Language="Yazik", GUI="Interfeis",
    SaveSettings="Sokhranit", AutoLoadSettings="Avtosapusk",
    ResetSettings="Sbros", MinimizeButton="Svertka", DraggableGUI="Peretaskivanie", ToggleKeybind="Klavisha", Notifications="Uvedomleniya",
    Dark="Temnaya", Light="Svetlaya", SkyBlue="Nebesno-Golubaya", Galaxy="Galaktika",
    English="English", Vietnamese="Tieng Viet", Spanish="Espanol", Portuguese="Portugues", Russian="Russkiy",
    Enabled="Vklucheno", Disabled="Otklyucheno", Loaded="zagruzhen! 3 palca x3",
    KeySystem="Sistema Key", EnterKey="Vvesti Key", SubmitKey="Otpravit", KeyStatus="Status Key",
    KeyRequired="Key neobhodima dlya ispolzovaniya", KeyAccepted="Key prinyata! Razblokirovano",
    KeyWrong="Nepravilnaya Key!", FieldOfView="Ugol Obzora", PlayersOnline="Igrokov Online",
    StopSpectate="Ostanovit Nablyudenie", OrbitActive="Orbita Aktivna", FOVCircle="Krug FOV",
}

local function T(key)
    local lang = Langs[currentLang] or Langs.EN
    return lang[key] or (Langs.EN[key] or key)
end

-- Track UI elements for live updates
local allUILabels = {} -- {obj, key} for language updates
local allUIThemed = {} -- {obj, prop, themeKey} for theme updates

local function trackLabel(obj, langKey)
    table.insert(allUILabels, {obj=obj, key=langKey})
end
local function trackThemed(obj, prop, themeKey)
    table.insert(allUIThemed, {obj=obj, prop=prop, themeKey=themeKey})
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
            Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 6)

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

            TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -280, 0, 10)
            }):Play()
            _wait(duration)

            TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 280, 0, 10)
            }):Play()
            _wait(0.35)
            notifFrame:Destroy()
        end)
    end)
end

-- ============================================================
-- ESP OVERLAY GUI (Tracer Lines + FOV Circle + Player Count)
-- ============================================================
local espGui = Instance.new("ScreenGui")
espGui.Name = "FLUYEN_ESP_Overlay"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 99
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
fovStroke.Color = Color3.fromRGB(255, 107, 53)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

-- Player Count Label
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCount"
playerCountLabel.Size = UDim2.new(0, 120, 0, 24)
playerCountLabel.Position = UDim2.new(0, 10, 0, 10)
playerCountLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
playerCountLabel.BackgroundTransparency = 0.5
playerCountLabel.Text = "Players: 0"
playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playerCountLabel.Font = Enum.Font.GothamBold
playerCountLabel.TextSize = 12
playerCountLabel.ZIndex = 50
playerCountLabel.Parent = espGui
Instance.new("UICorner", playerCountLabel).CornerRadius = UDim.new(0, 4)

-- FPS Counter Label
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPS"
fpsLabel.Size = UDim2.new(0, 80, 0, 24)
fpsLabel.Position = UDim2.new(0, 10, 0, 38)
fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fpsLabel.BackgroundTransparency = 0.5
fpsLabel.Text = "FPS: 60"
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 11
fpsLabel.ZIndex = 50
fpsLabel.Parent = espGui
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 4)

-- Tracer Lines container (we use Frames as lines)
local tracerContainer = Instance.new("Frame")
tracerContainer.Name = "Tracers"
tracerContainer.Size = UDim2.new(1, 0, 1, 0)
tracerContainer.BackgroundTransparency = 1
tracerContainer.ZIndex = 48
tracerContainer.Parent = espGui

-- Convergence point dot at top center of screen (where all tracer lines converge)
local tracerDot = Instance.new("Frame")
tracerDot.Name = "TracerDot"
tracerDot.Size = UDim2.new(0, 8, 0, 8)
tracerDot.Position = UDim2.new(0.5, -4, 0, -2)
tracerDot.BackgroundColor3 = Color3.fromRGB(255, 107, 53)
tracerDot.BorderSizePixel = 0
tracerDot.BackgroundTransparency = 0.2
tracerDot.ZIndex = 50
tracerDot.Visible = false
tracerDot.Parent = espGui
Instance.new("UICorner", tracerDot).CornerRadius = UDim.new(0, 4)

-- Key Status Label (always visible)
local keyStatusLabel = Instance.new("TextLabel")
keyStatusLabel.Name = "KeyStatus"
keyStatusLabel.Size = UDim2.new(0, 200, 0, 24)
keyStatusLabel.Position = UDim2.new(0.5, -100, 1, -34)
keyStatusLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
keyStatusLabel.BackgroundTransparency = 0.3
keyStatusLabel.Text = "KEY REQUIRED - Enter key in Settings"
keyStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatusLabel.Font = Enum.Font.GothamBold
keyStatusLabel.TextSize = 11
keyStatusLabel.ZIndex = 100
keyStatusLabel.Visible = not keyAuthenticated
keyStatusLabel.Parent = espGui
Instance.new("UICorner", keyStatusLabel).CornerRadius = UDim.new(0, 4)
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
trackThemed(titleBar, "BackgroundColor3", "bg")

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
trackThemed(titleLabel, "TextColor3", "accent")

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
trackThemed(closeBtn, "TextColor3", "textDim")

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 90, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = getTheme().sidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
sidebar.Parent = mainFrame
trackThemed(sidebar, "BackgroundColor3", "sidebar")

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
contentArea.BackgroundTransparency = 0.999
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

local pages = {}
local tabButtons = {}

for _, tabDef in ipairs(TabDefs) do
    local name = tabDef.name
    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 0.999
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = getTheme().accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = (name == "Home")
    page.ZIndex = 6
    page.Active = true
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

    -- Auto-recalculate page size when layout content changes
    pcall(function()
        local layout = page:FindFirstChild("UIListLayout")
        if layout then
            local lastRecalc = 0
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local now = tick()
                if now - lastRecalc > 0.1 then
                    lastRecalc = now
                    _delay(0.05, function()
                        pcall(function() recalcPage(page) end)
                    end)
                end
            end)
        end
    end)

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 28)
    tabBtn.BackgroundColor3 = (name == "Home") and getTheme().tabActive or getTheme().tabInactive
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = tabDef.icon .. " " .. T(name)
    tabBtn.TextColor3 = (name == "Home") and getTheme().text or getTheme().textDim
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 11
    tabBtn.LayoutOrder = tabDef.order
    tabBtn.ZIndex = 6
    tabBtn.Parent = sidebar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)
    trackThemed(tabBtn, "BackgroundColor3", (name == "Home") and "tabActive" or "tabInactive")
    trackLabel(tabBtn, name)

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
    trackThemed(activeBorder, "BackgroundColor3", "accent")

    tabButtons[name] = tabBtn
end
-- ============================================================
-- UI ELEMENT BUILDERS (Mobile-optimized)
-- ============================================================
local ELEMENT_H = 30

local function addSection(page, text, langKey)
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
    trackThemed(label, "TextColor3", "accent")
    if langKey then trackLabel(label, langKey) end
    return label
end

local function addCheckbox(page, text, stateKey, callback, langKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(0, 0, 0.5, -10)
    box.BackgroundColor3 = getTheme().checkboxBg
    box.BorderSizePixel = 0
    box.ZIndex = 8
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    trackThemed(box, "BackgroundColor3", "checkboxBg")

    local checkmark = Instance.new("Frame")
    checkmark.Size = UDim2.new(0, 12, 0, 12)
    checkmark.Position = UDim2.new(0.5, -6, 0.5, -6)
    checkmark.BackgroundColor3 = getTheme().checkboxOn
    checkmark.BorderSizePixel = 0
    checkmark.Visible = States[stateKey] or false
    checkmark.ZIndex = 9
    checkmark.Parent = box
    Instance.new("UICorner", checkmark).CornerRadius = UDim.new(0, 2)
    trackThemed(checkmark, "BackgroundColor3", "checkboxOn")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = getTheme().text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = row
    trackThemed(label, "TextColor3", "text")
    if langKey then trackLabel(label, langKey) end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 10
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        if not checkKey() then
            notify(T("KeySystem"), T("KeyRequired"), 3)
            return
        end
        States[stateKey] = not States[stateKey]
        checkmark.Visible = States[stateKey]
        if callback then pcall(function() callback(States[stateKey]) end) end
    end)

    return row, checkmark
end

local function addSlider(page, text, valueKey, min, max, isFloat, callback, langKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local displayVal = isFloat and string.format("%.1f", Values[valueKey] or min) or tostring(math.floor(Values[valueKey] or min))
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. displayVal
    label.TextColor3 = getTheme().text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 8
    label.Parent = row
    trackThemed(label, "TextColor3", "text")

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0.47, 0, 0, 8)
    track.Position = UDim2.new(0.52, 0, 0.5, -4)
    track.BackgroundColor3 = getTheme().sliderTrack
    track.BorderSizePixel = 0
    track.ZIndex = 8
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
    trackThemed(track, "BackgroundColor3", "sliderTrack")

    local pct = math.max(0, math.min((Values[valueKey] - min) / math.max(max - min, 0.01), 1))
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = getTheme().sliderFill
    fill.BorderSizePixel = 0
    fill.ZIndex = 9
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
    trackThemed(fill, "BackgroundColor3", "sliderFill")

    -- Slider knob for easier mobile dragging
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = getTheme().accent
    knob.BorderSizePixel = 0
    knob.ZIndex = 10
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
    trackThemed(knob, "BackgroundColor3", "accent")

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0.47, 0, 1, 0)
    sliderBtn.Position = UDim2.new(0.52, 0, 0, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 11
    sliderBtn.Parent = row

    local dragging = false

    local function updateSlider(inputPos)
        local relX = math.max(0, math.min((inputPos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 1))
        local val = min + relX * (max - min)
        if not isFloat then val = math.floor(val) end
        Values[valueKey] = val
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -7, 0.5, -7)
        local dv = isFloat and string.format("%.1f", val) or tostring(math.floor(val))
        label.Text = text .. ": " .. dv
        if callback then pcall(function() callback(val) end) end
    end

    sliderBtn.MouseButton1Down:Connect(function()
        if not checkKey() then
            notify(T("KeySystem"), T("KeyRequired"), 3)
            return
        end
        dragging = true
        -- Immediately update based on current input position
        local mousePos = UserInputService:GetMouseLocation()
        updateSlider(mousePos)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return row
end

local function addButton(page, text, callback, langKey)
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
    trackThemed(btn, "BackgroundColor3", "btnBg")
    trackThemed(btn, "TextColor3", "text")
    if langKey then trackLabel(btn, langKey) end

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

local function addInfoRow(page, labelText, valueText, langKey)
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
    trackThemed(lbl, "TextColor3", "textDim")
    if langKey then trackLabel(lbl, langKey) end

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
    trackThemed(val, "TextColor3", "text")

    return row, val
end

local function addDropdown(page, text, options, onSelect, langKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    row.BackgroundTransparency = 1
    row.ClipsDescendants = false
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
    trackThemed(label, "TextColor3", "text")

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
    trackThemed(dropBtn, "BackgroundColor3", "dropdownBg")

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

local function addKeyInput(page)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ELEMENT_H + 18)
    row.BackgroundTransparency = 1
    row.ZIndex = 7
    row.Parent = page

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, 0, 0, 24)
    box.Position = UDim2.new(0, 0, 0.5, -12)
    box.BackgroundColor3 = getTheme().dropdownBg
    box.BorderSizePixel = 0
    box.PlaceholderText = T("EnterKey")
    box.Text = ""
    box.TextColor3 = getTheme().text
    box.PlaceholderColor3 = getTheme().textDim
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.ZIndex = 8
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    trackThemed(box, "BackgroundColor3", "dropdownBg")
    trackThemed(box, "TextColor3", "text")

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.35, 0, 0, 24)
    submitBtn.Position = UDim2.new(0.63, 0, 0.5, -12)
    submitBtn.BackgroundColor3 = getTheme().accent
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = T("SubmitKey")
    submitBtn.TextColor3 = Color3.fromRGB(255,255,255)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 12
    submitBtn.ZIndex = 8
    submitBtn.Parent = row
    Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 4)
    trackThemed(submitBtn, "BackgroundColor3", "accent")

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 16)
    statusLabel.Position = UDim2.new(0, 0, 1, 2)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = keyAuthenticated and "✓ Key Accepted" or "✗ Key Required"
    statusLabel.TextColor3 = keyAuthenticated and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,50,50)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 8
    statusLabel.Parent = row

    submitBtn.MouseButton1Click:Connect(function()
        local input = box.Text
        if input == VALID_KEY then
            keyAuthenticated = true
            pcall(function() writefile("FLUYEN_key.txt", input) end)
            statusLabel.Text = "✓ Key Accepted"
            statusLabel.TextColor3 = Color3.fromRGB(0,255,0)
            keyStatusLabel.Visible = false
            notify(T("KeySystem"), T("KeyAccepted"), 4)
        else
            statusLabel.Text = "✗ Wrong Key!"
            statusLabel.TextColor3 = Color3.fromRGB(255,50,50)
            notify(T("KeySystem"), T("KeyWrong"), 3)
        end
    end)

    return row, box
end
-- ============================================================
-- PAGE SIZE RECALCULATION (LAG-OPTIMIZED)
-- Only recalculates the active page, not all pages
-- ============================================================
local function recalcPage(page)
    pcall(function()
        if not page or not page:IsA("ScrollingFrame") then return end
        -- Method 1: Use UIListLayout's absolute content size
        local layout = page:FindFirstChild("UIListLayout")
        local contentH = 0
        if layout then
            contentH = layout.AbsoluteContentSize.Y
        end
        -- Method 2: Fallback - iterate children
        if contentH <= 0 then
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                    local h = child.AbsoluteSize.Y
                    if h <= 0 then h = child.Size.Y.Offset end
                    if h <= 0 then h = ELEMENT_H end
                    contentH = contentH + h + 4
                end
            end
        end
        local padding = page:FindFirstChild("UIPadding")
        local padBottom = 0
        if padding then padBottom = padding.PaddingBottom.Offset end
        local pageH = page.AbsoluteSize.Y
        if pageH <= 0 then pageH = MENU_H - 30 end
        local totalH = math.max(contentH + 20 + padBottom, pageH + 1)
        page.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

local function recalcCurrentPage()
    recalcPage(pages[currentTab])
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
            pcall(function() page.CanvasPosition = Vector2.new(0, 0) end)
        end
    end
    for btnName, btn in pairs(tabButtons) do
        local active = (btnName == name)
        local theme = getTheme()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and theme.tabActive or theme.tabInactive
        }):Play()
        btn.TextColor3 = active and theme.text or theme.textDim
        local icon = ""
        for _, td in ipairs(TabDefs) do
            if td.name == btnName then icon = td.icon .. " " break end
        end
        btn.Text = icon .. T(btnName)
        local border = btn:FindFirstChild("ActiveBorder")
        if border then border.Visible = active end
    end
    -- Only recalc the active page (LAG FIX - was recalcAllPages before)
    _spawn(function()
        _wait(0.03)
        recalcCurrentPage()
    end)
end

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
    TweenService:Create(backdrop, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()
    _delay(0.3, function()
        if uiScale then uiScale.Scale = 1 end
        isAnimating = false
        recalcCurrentPage()
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
        if States.MinimizeButton and miniBtn then miniBtn.Visible = true end
    end
end

local function toggleMenu()
    if isOpen then closeMenu() else openMenu() end
end

-- Minimize button
local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 44, 0, 44)
miniBtn.Position = UDim2.new(0, 10, 0.5, -22)
miniBtn.BackgroundColor3 = getTheme().accent
miniBtn.Text = "F"
miniBtn.TextColor3 = Color3.fromRGB(255,255,255)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 18
miniBtn.ZIndex = 100
miniBtn.Visible = false
miniBtn.Parent = screenGui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 22)

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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- LIVE LANGUAGE & THEME UPDATE
-- ============================================================
local function updateAllLanguages()
    for _, entry in ipairs(allUILabels) do
        pcall(function()
            if entry.obj and entry.obj.Parent then
                -- Determine prefix based on parent
                local parentPage = entry.obj.Parent
                while parentPage and not parentPage:IsA("ScrollingFrame") do
                    parentPage = parentPage.Parent
                end
                -- For tab buttons, add icon prefix
                local isTabBtn = false
                for name, btn in pairs(tabButtons) do
                    if btn == entry.obj then
                        isTabBtn = true
                        local icon = ""
                        for _, td in ipairs(TabDefs) do
                            if td.name == name then icon = td.icon .. " " break end
                        end
                        entry.obj.Text = icon .. T(entry.key)
                        break
                    end
                end
                if not isTabBtn then
                    entry.obj.Text = T(entry.key)
                end
            end
        end)
    end
end

local function updateAllThemes()
    local theme = getTheme()
    pcall(function()
        mainFrame.BackgroundColor3 = theme.bg
        titleBar.BackgroundColor3 = theme.bg
        sidebar.BackgroundColor3 = theme.sidebar
        titleLabel.TextColor3 = theme.accent
        closeBtn.TextColor3 = theme.textDim
        miniBtn.BackgroundColor3 = theme.accent
        for pageName, page in pairs(pages) do
            page.ScrollBarImageColor3 = theme.accent
        end
    end)
    for _, entry in ipairs(allUIThemed) do
        pcall(function()
            if entry.obj and entry.obj.Parent then
                local val = theme[entry.themeKey]
                if val then
                    entry.obj[entry.prop] = val
                end
            end
        end)
    end
    -- Update tab buttons
    for btnName, btn in pairs(tabButtons) do
        local active = (btnName == currentTab)
        btn.BackgroundColor3 = active and theme.tabActive or theme.tabInactive
        btn.TextColor3 = active and theme.text or theme.textDim
        local border = btn:FindFirstChild("ActiveBorder")
        if border then border.BackgroundColor3 = theme.accent end
    end
    -- Update FOV circle
    if fovStroke then fovStroke.Color = theme.accent end
    -- Update tracer dot
    if tracerDot then tracerDot.BackgroundColor3 = theme.accent end
end
-- ============================================================
-- ESP SYSTEM: Tracer Lines, FOV Circle, Player Count, FPS Counter
-- ============================================================

-- FPS counter variables
local _lastFpsTick = 0
local _fpsAccum = 0
local _fpsTimeAccum = 0
local _currentFps = 60

-- FOV Circle updater
setConn("FOVUpdate", RunService.RenderStepped:Connect(function()
    pcall(function()
        fovCircle.Visible = States.AimFOV
        if States.AimFOV then
            local fovSize = Values.AimFOVValue * 2
            fovCircle.Size = UDim2.new(0, fovSize, 0, fovSize)
            fovCircle.Position = UDim2.new(0.5, -Values.AimFOVValue, 0.5, -Values.AimFOVValue)
        end

        -- Player count
        local count = #Players:GetPlayers()
        playerCountLabel.Text = T("PlayersOnline") .. ": " .. tostring(count)

        -- FPS counter (tick-based calculation)
        local now = tick()
        if _lastFpsTick and _lastFpsTick > 0 then
            local dt = now - _lastFpsTick
            if dt > 0 then
                _fpsAccum = _fpsAccum + 1
                _fpsTimeAccum = _fpsTimeAccum + dt
                if _fpsTimeAccum >= 0.5 then
                    _currentFps = math.floor(_fpsAccum / _fpsTimeAccum)
                    _fpsAccum = 0
                    _fpsTimeAccum = 0
                end
            end
        end
        _lastFpsTick = now
        fpsLabel.Text = "FPS: " .. tostring(_currentFps)
        if _currentFps >= 50 then
            fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        elseif _currentFps >= 30 then
            fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            fpsLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end

        -- Camera FOV sync
        if States.Aim or States.SilentAim then
            camera.FieldOfView = Values.FieldOfView
        end
    end)
end))

-- Tracer Lines system (draws lines from convergence point at TOP CENTER of screen to each player's HEAD)
local tracerLines = {}

local function clearTracers()
    for _, line in ipairs(tracerLines) do
        pcall(function() line:Destroy() end)
    end
    tracerLines = {}
end

local function drawLine(x1, y1, x2, y2, color)
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then return nil end
    local angle = math.atan2(dy, dx)

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, 1.5)
    line.Position = UDim2.new(0, x1, 0, y1)
    line.BackgroundColor3 = color or Color3.fromRGB(255, 107, 53)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.3
    line.ZIndex = 49
    line.Rotation = math.deg(angle)
    line.Parent = tracerContainer

    table.insert(tracerLines, line)
    return line
end

setConn("TracerRender", RunService.RenderStepped:Connect(function()
    clearTracers()
    tracerDot.Visible = States.Tracers
    if not States.Tracers then return end
    pcall(function()
        -- Convergence point: top center of screen
        local screenW = camera.ViewportSize.X
        local originX = screenW / 2
        local originY = 0  -- very top of screen
        for _, tgt in ipairs(Players:GetPlayers()) do
            if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") and tgt.Character:FindFirstChild("HumanoidRootPart") then
                local headPos, onScreen = camera:WorldToViewportPoint(tgt.Character.Head.Position)
                if onScreen then
                    drawLine(originX, originY, headPos.X, headPos.Y, Color3.fromRGB(255, 107, 53))
                end
            end
        end
    end)
end))
-- ============================================================
-- POPULATE TABS - Home, Visual, Combat
-- ============================================================

-- HOME TAB
do
    local p = pages["Home"]
    addSection(p, T("ScriptName"), "ScriptName")
    addInfoRow(p, T("ScriptName"), SCRIPT_NAME, "ScriptName")
    addInfoRow(p, T("Version"), SCRIPT_VERSION, "Version")
    addInfoRow(p, T("Username"), player.Name, "Username")
    addInfoRow(p, T("Executor"), "Delta", "Executor")
    addInfoRow(p, T("Credits"), "FLUYEN Team", "Credits")
    addSection(p, T("PlayersOnline"), "PlayersOnline")
    addInfoRow(p, T("PlayersOnline"), tostring(#Players:GetPlayers()), "PlayersOnline")
    addSection(p, T("Changelog"), "Changelog")
    addInfoRow(p, "v5.0", "Key system, ESP Lines, FOV Circle, all fixes")
    addInfoRow(p, "v4.0", "Full Delta rewrite - all functions working")
    addInfoRow(p, "v3.2", "Initial Delta compatibility fixes")
end

-- VISUAL TAB
do
    local p = pages["Visual"]
    addSection(p, T("ESP"), "ESP")

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
    end, "ESP")

    addCheckbox(p, T("BoxESP"), "BoxESP", function(v)
        killConn("BoxESP")
        if v then
            setConn("BoxESP", RunService.RenderStepped:Connect(function()
                if not States.BoxESP then killConn("BoxESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local _, onScreen = camera:WorldToViewportPoint(tgt.Character.HumanoidRootPart.Position)
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
    end, "BoxESP")

    addCheckbox(p, T("NameESP"), "NameESP", function(v)
        killConn("NameESP")
        if v then
            setConn("NameESP", RunService.RenderStepped:Connect(function()
                if not States.NameESP then killConn("NameESP") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("Head") then
                            local gui = tgt.Character.Head:FindFirstChild("FLUYEN_Name")
                            if not gui then
                                gui = Instance.new("BillboardGui")
                                gui.Name = "FLUYEN_Name"
                                gui.Size = UDim2.new(0, 100, 0, 20)
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
    end, "NameESP")

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
    end, "HealthESP")

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
    end, "DistanceESP")

    addCheckbox(p, T("Tracers"), "Tracers", nil, "Tracers")

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
    end, "Chams")

    addSection(p, T("FullBright"), "FullBright")
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
                Lighting.FogEnd = 1000
                Lighting.Ambient = Color3.fromRGB(0,0,0)
            end)
        end
    end, "FullBright")

    addCheckbox(p, T("NightVision"), "NightVision", function(v)
        killConn("NightVision")
        if v then
            setConn("NightVision", RunService.RenderStepped:Connect(function()
                if not States.NightVision then killConn("NightVision") return end
                pcall(function()
                    Lighting.Brightness = 3
                    Lighting.ClockTime = 14
                    Lighting.FogEnd = 100000
                    Lighting.Ambient = Color3.fromRGB(100,255,100)
                    Lighting.OutdoorAmbient = Color3.fromRGB(100,255,100)
                end)
            end))
        else
            pcall(function()
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.fromRGB(0,0,0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
            end)
        end
    end, "NightVision")

    addCheckbox(p, T("Xray"), "Xray", function(v)
        killConn("Xray")
        if v then
            setConn("Xray", RunService.RenderStepped:Connect(function()
                if not States.Xray then killConn("Xray") return end
                pcall(function()
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
                            obj.LocalTransparencyModifier = 0.6
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.LocalTransparencyModifier = 0
                    end
                end
            end)
        end
    end, "Xray")
end

-- COMBAT TAB
do
    local p = pages["Combat"]
    addSection(p, T("Aim"), "Aim")

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
                        local smoothness = math.max(1, Values.AimSmoothness)
                        local currentCFrame = camera.CFrame
                        local targetCFrame = CFrame.new(currentCFrame.Position, closest.Position)
                        camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothness)
                    end
                end)
            end))
        end
    end, "Aim")

    addCheckbox(p, T("SilentAim"), "SilentAim", function(v)
        notify(T("SilentAim"), v and T("Enabled") or T("Disabled"), 2)
    end, "SilentAim")

    addCheckbox(p, T("AimFOV"), "AimFOV", function(v)
        fovCircle.Visible = v
    end, "AimFOV")

    addCheckbox(p, T("AimPrediction"), "AimPrediction", function(v)
        notify(T("AimPrediction"), v and T("Enabled") or T("Disabled"), 2)
    end, "AimPrediction")

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
    end, "TriggerBot")

    addCheckbox(p, T("HitboxExpander"), "HitboxExpander", function(v)
        killConn("HitboxExpander")
        if v then
            setConn("HitboxExpander", RunService.RenderStepped:Connect(function()
                if not States.HitboxExpander then killConn("HitboxExpander") return end
                pcall(function()
                    for _, tgt in ipairs(Players:GetPlayers()) do
                        if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = tgt.Character.HumanoidRootPart
                            hrp.Size = Vector3.new(Values.HitboxSize, Values.HitboxSize, Values.HitboxSize)
                            hrp.Transparency = 0.5
                        end
                    end
                end)
            end))
        else
            pcall(function()
                for _, tgt in ipairs(Players:GetPlayers()) do
                    if tgt ~= player and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
                        tgt.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                        tgt.Character.HumanoidRootPart.Transparency = 0
                    end
                end
            end)
        end
    end, "HitboxExpander")

    addSection(p, T("AimFOVValue"), "AimFOVValue")
    addSlider(p, T("AimFOVValue"), "AimFOVValue", 30, 360, false, function(val)
        -- Update FOV circle size
    end, "AimFOVValue")
    addSlider(p, T("AimSmoothness"), "AimSmoothness", 1, 100, false, nil, "AimSmoothness")
    addSlider(p, T("HitboxSize"), "HitboxSize", 2, 50, false, nil, "HitboxSize")
    addSection(p, T("FieldOfView"), "FieldOfView")
    addSlider(p, T("FieldOfView"), "FieldOfView", 30, 120, false, function(val)
        camera.FieldOfView = val
    end, "FieldOfView")
end
-- ============================================================
-- POPULATE TABS - Movement, Utility
-- ============================================================

-- MOVEMENT TAB
do
    local p = pages["Movement"]
    addSection(p, T("Speed"), "Speed")

    addCheckbox(p, T("Speed"), "Speed", function(v)
        killConn("Speed")
        if v then
            setConn("Speed", RunService.RenderStepped:Connect(function()
                if not States.Speed then killConn("Speed") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid.WalkSpeed = Values.SpeedValue
                        -- CFrame backup: bypass anti-cheat speed caps
                        if player.Character:FindFirstChild("HumanoidRootPart") then
                            local hum = player.Character.Humanoid
                            if hum.MoveDirection.Magnitude > 0 then
                                local speedBoost = (Values.SpeedValue - 16) * 0.015
                                if speedBoost > 0 then
                                    local moveDir = hum.MoveDirection.Unit
                                    player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + moveDir * speedBoost
                                end
                            end
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
    end, "Speed")
    addSlider(p, T("SpeedValue"), "SpeedValue", 16, 200, false, nil, "SpeedValue")

    addSection(p, T("Fly"), "Fly")
    addCheckbox(p, T("Fly"), "Fly", function(v)
        killConn("Fly")
        if v then
            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    pcall(function() char.Humanoid.PlatformStand = true end)
                end
            end)
            setConn("Fly", RunService.RenderStepped:Connect(function()
                if not States.Fly then killConn("Fly") return end
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = char.HumanoidRootPart
                    local moveDir = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
                    if moveDir.Magnitude > 0 then
                        local newPos = hrp.CFrame.Position + moveDir.Unit * (Values.FlySpeed * 0.5)
                        hrp.CFrame = CFrame.new(newPos, newPos + camera.CFrame.LookVector)
                    end
                    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
                    pcall(function() hrp.Velocity = Vector3.new(0,0,0) end)
                end)
            end))
        else
            pcall(function()
                if player.Character then
                    if player.Character:FindFirstChild("HumanoidRootPart") then
                        local bv = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FlyBV")
                        if bv then bv:Destroy() end
                        local gy = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FlyGyro")
                        if gy then gy:Destroy() end
                    end
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum then pcall(function() hum.PlatformStand = false end) end
                end
            end)
        end
    end, "Fly")
    addSlider(p, T("FlySpeed"), "FlySpeed", 10, 200, false, nil, "FlySpeed")

    addSection(p, T("LowGravity"), "LowGravity")
    addCheckbox(p, T("LowGravity"), "LowGravity", function(v)
        if v then
            States.LowGravity = true
            pcall(function()
                workspace.Gravity = Values.LowGravityValue
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = Values.LowGravityValue * 2
                end
            end)
        else
            States.LowGravity = false
            pcall(function()
                workspace.Gravity = 196.2
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = 50
                end
            end)
        end
    end, "LowGravity")
    addSlider(p, T("LowGravityValue"), "LowGravityValue", 10, 200, false, function(val)
        if States.LowGravity then
            pcall(function()
                workspace.Gravity = val
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.JumpPower = val * 2
                end
            end)
        end
    end, "LowGravityValue")

    addSection(p, T("Freecam"), "Freecam")
    addCheckbox(p, T("Freecam"), "Freecam", function(v)
        killConn("Freecam")
        if v then
            States.Freecam = true
            pcall(function()
                camera.CameraType = Enum.CameraType.Scriptable
            end)
            setConn("Freecam", RunService.RenderStepped:Connect(function()
                if not States.Freecam then killConn("Freecam") return end
                pcall(function()
                    local speed = 1
                    local moveDir = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                    if moveDir.Magnitude > 0 then
                        camera.CFrame = camera.CFrame + moveDir.Unit * speed
                    end
                end)
            end))
        else
            States.Freecam = false
            pcall(function()
                camera.CameraType = Enum.CameraType.Custom
            end)
        end
    end, "Freecam")

    addSection(p, T("Noclip"), "Noclip")
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
    end, "Noclip")

    addSection(p, T("JumpPower"), "JumpPower")
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
    end, "JumpPower")
    addSlider(p, T("JumpPowerValue"), "JumpPowerValue", 50, 500, false, nil, "JumpPowerValue")

    addSection(p, T("InfiniteJump"), "InfiniteJump")
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
    end, "InfiniteJump")

    addSection(p, T("Teleport"), "Teleport")
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
    end, "ClickTeleport")

    addSection(p, T("Sprint"), "Sprint")
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
    end, "Sprint")
    addSlider(p, T("SprintSpeed"), "SprintSpeed", 20, 100, false, nil, "SprintSpeed")

    addSection(p, T("AntiVoid"), "AntiVoid")
    addCheckbox(p, T("AntiVoid"), "AntiVoid", function(v)
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
end

-- UTILITY TAB
do
    local p = pages["Utility"]
    addSection(p, T("AntiAFK"), "AntiAFK")
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
    end, "AntiAFK")

    addSection(p, T("FreezeTime"), "FreezeTime")
    addCheckbox(p, T("FreezeTime"), "FreezeTime", function(v)
        killConn("FreezeTime")
        if v then
            setConn("FreezeTime", RunService.RenderStepped:Connect(function()
                if not States.FreezeTime then killConn("FreezeTime") return end
                pcall(function() Lighting.ClockTime = 14 end)
            end))
        end
    end, "FreezeTime")

    addSection(p, T("FPSBoost"), "FPSBoost")
    addCheckbox(p, T("FPSBoost"), "FPSBoost", function(v)
        if v then
            pcall(function()
                settings().Rendering.QualityLevel = 1
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Texture") then obj.Transparency = 1 end
                    if obj:IsA("Decal") then obj.Transparency = 1 end
                    if obj:IsA("ParticleEmitter") then obj.Enabled = false end
                    if obj:IsA("Trail") then obj.Enabled = false end
                end
            end)
            notify(T("FPSBoost"), T("Enabled"), 2)
        else
            pcall(function() settings().Rendering.QualityLevel = 3 end)
            notify(T("FPSBoost"), T("Disabled"), 2)
        end
    end, "FPSBoost")

    addSection(p, T("AntiBlind"), "AntiBlind")
    addCheckbox(p, T("AntiBlind"), "AntiBlind", function(v)
        killConn("AntiBlind")
        if v then
            setConn("AntiBlind", RunService.RenderStepped:Connect(function()
                if not States.AntiBlind then killConn("AntiBlind") return end
                pcall(function()
                    Lighting.Brightness = math.max(Lighting.Brightness, 1)
                    Lighting.FogEnd = math.max(Lighting.FogEnd, 10000)
                end)
            end))
        end
    end, "AntiBlind")

    addCheckbox(p, T("AntiSlow"), "AntiSlow", function(v)
        killConn("AntiSlow")
        if v then
            setConn("AntiSlow", RunService.RenderStepped:Connect(function()
                if not States.AntiSlow then killConn("AntiSlow") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid.WalkSpeed = math.max(player.Character.Humanoid.WalkSpeed, 16)
                    end
                end)
            end))
        end
    end, "AntiSlow")

    addCheckbox(p, T("AntiRagdoll"), "AntiRagdoll", function(v)
        killConn("AntiRagdoll")
        if v then
            setConn("AntiRagdoll", RunService.Stepped:Connect(function()
                if not States.AntiRagdoll then killConn("AntiRagdoll") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
            end))
        end
    end, "AntiRagdoll")

    addCheckbox(p, T("AntiGrab"), "AntiGrab", function(v)
        killConn("AntiGrab")
        if v then
            setConn("AntiGrab", RunService.RenderStepped:Connect(function()
                if not States.AntiGrab then killConn("AntiGrab") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local rootPart = player.Character.HumanoidRootPart
                        -- Remove any welds created by grab mechanics
                        for _, child in ipairs(rootPart:GetChildren()) do
                            if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Motor6D") then
                                if child.Name:find("Grab") or child.Name:find("grab") or child.Name:find("Carry") then
                                    child:Destroy()
                                end
                            end
                        end
                    end
                end)
            end))
        end
    end, "AntiGrab")
end
-- ============================================================
-- POPULATE TABS - Server, Fun, Settings
-- ============================================================

-- SERVER TAB
do
    local p = pages["Server"]
    addSection(p, T("RejoinServer"), "RejoinServer")
    addButton(p, T("RejoinServer"), function()
        notify(T("RejoinServer"), "Rejoining...", 2)
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        end)
    end, "RejoinServer")

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
    end, "ServerHop")

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
    end, "JoinSmallServer")

    addSection(p, T("Respawn"), "Respawn")
    addButton(p, T("Respawn"), function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = 0
                notify(T("Respawn"), T("Enabled"), 2)
            end
        end)
    end, "Respawn")

    addButton(p, T("TeleportToSpawn"), function()
        pcall(function()
            local spawn = nil
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("SpawnLocation") then
                    spawn = obj
                    break
                end
            end
            if not spawn then
                spawn = workspace:FindFirstChild("SpawnLocation")
            end
            if spawn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
                notify(T("TeleportToSpawn"), "Teleported!", 2)
            else
                notify(T("TeleportToSpawn"), "No spawn found!", 2)
            end
        end)
    end, "TeleportToSpawn")

    addSection(p, T("PlayerList"), "PlayerList")
    local spectateNames = {}
    for _, p2 in ipairs(Players:GetPlayers()) do
        if p2 ~= player then table.insert(spectateNames, p2.Name) end
    end
    if #spectateNames > 0 then
        addDropdown(p, T("SpectatePlayer"), spectateNames, function(selected)
            killConn("Spectate")
            local target = Players:FindFirstChild(selected)
            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                setConn("Spectate", RunService.RenderStepped:Connect(function()
                    if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") then
                        killConn("Spectate") return
                    end
                    camera.CameraSubject = target.Character.Humanoid
                end))
                notify(T("SpectatePlayer"), selected, 2)
            end
        end, "SpectatePlayer")
    end

    addButton(p, T("StopSpectate"), function()
        killConn("Spectate")
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = player.Character.Humanoid
            end
        end)
        notify(T("SpectatePlayer"), "Stopped", 2)
    end, "StopSpectate")
end

-- FUN TAB
do
    local p = pages["Fun"]
    addSection(p, T("Spin"), "Spin")
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
    end, "Spin")
    addSlider(p, T("SpinSpeed"), "SpinSpeed", 1, 100, false, nil, "SpinSpeed")

    addSection(p, T("Float"), "Float")
    addCheckbox(p, T("Float"), "Float", function(v)
        killConn("Float")
        if v then
            setConn("Float", RunService.RenderStepped:Connect(function()
                if not States.Float then killConn("Float") return end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = player.Character.HumanoidRootPart
                        local floatY = math.sin(tick() * 2) * 5
                        -- Primary: AssemblyLinearVelocity (modern method)
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, floatY, hrp.AssemblyLinearVelocity.Z)
                        end)
                        -- Fallback: BodyVelocity (legacy method for Delta)
                        local bv = hrp:FindFirstChild("FLUYEN_FloatBV")
                        if not bv then
                            bv = Instance.new("BodyVelocity")
                            bv.Name = "FLUYEN_FloatBV"
                            bv.MaxForce = Vector3.new(0, math.huge, 0)
                            bv.Velocity = Vector3.new(0, 0, 0)
                            bv.Parent = hrp
                        end
                        bv.Velocity = Vector3.new(0, floatY, 0)
                    end
                end)
            end))
        else
            pcall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local bv = player.Character.HumanoidRootPart:FindFirstChild("FLUYEN_FloatBV")
                    if bv then bv:Destroy() end
                end
            end)
        end
    end, "Float")

    addSection(p, T("Bang"), "Bang")
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
    end, "Bang")

    addSection(p, T("Fling"), "Fling")
    addButton(p, T("Fling"), function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local flingV = Vector3.new(
                    math.random(-Values.FlingPower, Values.FlingPower),
                    math.random(200, Values.FlingPower),
                    math.random(-Values.FlingPower, Values.FlingPower)
                )
                pcall(function() player.Character.HumanoidRootPart.AssemblyLinearVelocity = flingV end)
                pcall(function() player.Character.HumanoidRootPart.Velocity = flingV end)
            end
        end)
    end, "Fling")
    addSlider(p, T("FlingPower"), "FlingPower", 100, 2000, false, nil, "FlingPower")

    addSection(p, T("OrbitPlayer"), "OrbitPlayer")
    local orbitTarget = nil
    local orbitPlayers = {}
    for _, p2 in ipairs(Players:GetPlayers()) do
        if p2 ~= player then table.insert(orbitPlayers, p2.Name) end
    end
    if #orbitPlayers > 0 then
        addDropdown(p, T("OrbitPlayer"), orbitPlayers, function(selected)
            orbitTarget = Players:FindFirstChild(selected)
        end, "OrbitPlayer")
    end

    addCheckbox(p, T("OrbitActive"), "OrbitActive", function(v)
        States.OrbitActive = v
        killConn("Orbit")
        if v and orbitTarget then
            setConn("Orbit", RunService.RenderStepped:Connect(function()
                if not States.OrbitActive then killConn("Orbit") return end
                if not orbitTarget or not orbitTarget.Character or not orbitTarget.Character:FindFirstChild("HumanoidRootPart") then
                    killConn("Orbit") return
                end
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local angle = CFrame.Angles(0, math.rad(tick() * Values.OrbitSpeed * 50 % 360), 0)
                        local offset = CFrame.new(Values.OrbitRadius, 0, 0)
                        player.Character.HumanoidRootPart.CFrame = orbitTarget.Character.HumanoidRootPart.CFrame * angle * offset
                    end
                end)
            end))
        end
    end, "OrbitActive")
    addSlider(p, T("OrbitRadius"), "OrbitRadius", 1, 20, false, nil, "OrbitRadius")
    addSlider(p, T("OrbitSpeed"), "OrbitSpeed", 1, 20, false, nil, "OrbitSpeed")

    addSection(p, T("Invisible"), "Invisible")
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
    end, "Invisible")
end

-- SETTINGS TAB
do
    local p = pages["Settings"]

    -- Key System
    addSection(p, T("KeySystem"), "KeySystem")
    addKeyInput(p)

    -- Theme section
    addSection(p, T("Theme"), "Theme")
    addDropdown(p, T("Theme"), {"Dark", "Light", "Sky Blue", "Galaxy"}, function(selected)
        local themeMap = {Dark="Dark", Light="Light", ["Sky Blue"]="SkyBlue", Galaxy="Galaxy"}
        currentTheme = themeMap[selected] or "Dark"
        updateAllThemes()
        notify(T("Theme"), selected, 2)
    end, "Theme")

    -- Language section
    addSection(p, T("Language"), "Language")
    addDropdown(p, T("Language"), {"English", "Tieng Viet", "Espanol", "Portugues", "Russkiy"}, function(selected)
        local langMap = {English="EN", ["Tieng Viet"]="VI", ["Espanol"]="ES", ["Portugues"]="PT", ["Russkiy"]="RU"}
        currentLang = langMap[selected] or "EN"
        updateAllLanguages()
        notify(T("Language"), selected, 2)
    end, "Language")

    -- GUI section
    addSection(p, T("GUI"), "GUI")
    addCheckbox(p, T("AutoLoadSettings"), "AutoLoadSettings", nil, "AutoLoadSettings")
    addCheckbox(p, T("MinimizeButton"), "MinimizeButton", function(v)
        miniBtn.Visible = v and not isOpen
    end, "MinimizeButton")
    addCheckbox(p, T("DraggableGUI"), "DraggableGUI", nil, "DraggableGUI")
    addCheckbox(p, T("Notifications"), "Notifications", nil, "Notifications")

    -- Save/Load/Reset
    addSection(p, T("SaveSettings"), "SaveSettings")
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
    end, "SaveSettings")

    addButton(p, T("ResetSettings"), function()
        for k, v in pairs(States) do
            if type(v) == "boolean" then States[k] = false end
        end
        States.AntiAFK = true
        States.MinimizeButton = true
        States.DraggableGUI = true
        States.Notifications = true
        Values.SpeedValue = 16
        Values.FlySpeed = 50
        Values.JumpPowerValue = 50
        Values.SprintSpeed = 24
        Values.SpinSpeed = 10
        Values.AimFOVValue = 90
        Values.AimSmoothness = 5
        Values.HitboxSize = 10
        Values.OrbitRadius = 5
        Values.OrbitSpeed = 1
        Values.FlingPower = 500
        Values.FieldOfView = 70
        Values.LowGravityValue = 50
        pcall(function() workspace.Gravity = 196.2 end)
        pcall(function() camera.CameraType = Enum.CameraType.Custom end)
        currentTheme = "Dark"
        currentLang = "EN"
        updateAllThemes()
        updateAllLanguages()
        notify(T("ResetSettings"), "Settings reset!", 2)
    end, "ResetSettings")

    -- Keybind info
    addSection(p, T("ToggleKeybind"), "ToggleKeybind")
    addInfoRow(p, T("ToggleKeybind"), "3-finger tap x3", "ToggleKeybind")
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
                    updateAllThemes()
                    updateAllLanguages()
                    notify("Auto Load", "Settings loaded!", 2)
                end
            end)
        end
    end
end)

-- ============================================================
-- INITIAL RECALC & NOTIFICATION
-- ============================================================
recalcCurrentPage()
_delay(1, function()
    -- Recalc all pages after UI has rendered (fixes scroll not working)
    for pageName, page in pairs(pages) do
        recalcPage(page)
    end
end)
_delay(3, function()
    for pageName, page in pairs(pages) do
        recalcPage(page)
    end
end)

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
    notify(SCRIPT_NAME, SCRIPT_VERSION .. " " .. T("Loaded"), 4)
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
