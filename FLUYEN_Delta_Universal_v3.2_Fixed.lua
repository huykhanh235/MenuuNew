--[[
 ╔══════════════════════════════════════════════════════════════════╗
 ║  FLUYEN HUD MENU - DELTA UNIVERSAL EDITION v3.2 (FIXED)        ║
 ║  UI Style: Modern Dark + Orange Accent | All Games | Fixed     ║
 ╚══════════════════════════════════════════════════════════════════╝
]]
-- ============================================================
-- POLYFILL: task library for Delta executor compatibility
-- Delta executor does NOT have the task library (task.spawn, task.wait, etc.)
-- It DOES have legacy globals: wait(), spawn(), delay()
-- ============================================================

-- Safe check: does the task global exist at all?
local _taskExists = (function()
    local ok, _ = pcall(function()
        local _ = task
    end)
    return ok
end)()

-- _wait: yield the thread for t seconds
-- Priority: wait() global > task.wait() > busy-wait (last resort)
local _wait
_wait = function(t)
    t = t or 0
    if t <= 0 then
        -- Just yield once using whatever method works
        local ok, _ = pcall(function() wait(0) end)
        if not ok and _taskExists then
            pcall(function() task.wait(0) end)
        end
        return
    end
    -- Try legacy wait() first (always works on Delta)
    local ok, _ = pcall(function() wait(t) end)
    if ok then return end
    -- Try task.wait as fallback
    if _taskExists then
        ok, _ = pcall(function() task.wait(t) end)
        if ok then return end
    end
    -- Last resort: busy-wait (should never happen on Delta but just in case)
    local t0 = tick()
    while tick() - t0 < t do end
end

-- _spawn: run function in a new thread (yields properly)
-- Priority: spawn() global > task.spawn() > coroutine.wrap (last resort)
local _spawn
_spawn = function(f)
    -- Try legacy spawn() first (always works on Delta)
    local ok, _ = pcall(function() spawn(f) end)
    if ok then return end
    -- Try task.spawn as fallback
    if _taskExists then
        ok, _ = pcall(function() task.spawn(f) end)
        if ok then return end
    end
    -- Last resort: coroutine.wrap (runs synchronously, no yielding!)
    pcall(function() coroutine.wrap(f)() end)
end

-- _delay: run function after t seconds
-- Priority: delay() global > task.delay() > spawn+wait (last resort)
local _delay
_delay = function(t, f)
    t = t or 0
    -- Try legacy delay() first (always works on Delta)
    local ok, _ = pcall(function() delay(t, f) end)
    if ok then return end
    -- Try task.delay as fallback
    if _taskExists then
        ok, _ = pcall(function() task.delay(t, f) end)
        if ok then return end
    end
    -- Last resort: spawn a new thread that waits then calls f
    _spawn(function()
        _wait(t)
        f()
    end)
end



-- ============================================================
-- MAIN SCRIPT BODY - Wrapped in pcall for crash protection
-- If any error occurs, it will be printed instead of silent crash
-- ============================================================
local _scriptOk, _scriptErr = pcall(function()

    -- ═══════════════════════════════════════════════════════════════
    -- SERVICES
    -- ═══════════════════════════════════════════════════════════════
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local VirtualUser = game:GetService("VirtualUser")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local camera = Workspace.CurrentCamera

    -- ═══════════════════════════════════════════════════════════════
    -- CONFIG
    -- ═══════════════════════════════════════════════════════════════
    local SCRIPT_NAME = "FLUYEN"
    local SCRIPT_VERSION = "v3.2"
    local CREDITS = "FLUYEN Team"

    -- ═══════════════════════════════════════════════════════════════
    -- ANTI-DETECTION: Hide from game detection
    -- ═══════════════════════════════════════════════════════════════
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
                if conn.Disable then conn:Disable() end
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- STATES
    -- ═══════════════════════════════════════════════════════════════
    local States = {
        -- Visual
        ESP = false, BoxESP = false, NameESP = false, HealthESP = false,
        DistanceESP = false, Tracers = false, Chams = false, FullBright = false,
        -- Combat
        Aim = false, SilentAim = false, AimFOV = false, AimPrediction = false,
        TriggerBot = false, HitboxExpander = false,
        -- Movement
        Speed = false, Fly = false, Noclip = false, JumpPower = false,
        InfiniteJump = false, Teleport = false, ClickTeleport = false,
        Sprint = false, AntiVoid = false,
        -- Utility
        AntiAFK = false, FreezeTime = false, FPSBooster = false,
        -- Fun
        Spin = false, Float = false, Bang = false, Fling = false,
        OrbitPlayer = false, Invisible = false,
        -- Settings
        DraggableGUI = true, MinimizeButton = true, Notifications = true,
        AutoLoadSettings = false,
    }

    local Values = {
        SpeedValue = 50, JumpPowerValue = 100, FlySpeed = 50,
        AimFOVValue = 180, AimSmoothness = 0.1, HitboxSize = 5,
        ESPMaxDistance = 1000, FullBrightValue = 2,
        SpinSpeed = 50, FloatHeight = 5, OrbitRadius = 10,
        OrbitSpeed = 50, SprintSpeed = 70,
    }

    -- ═══════════════════════════════════════════════════════════════
    -- THEME - Modern Dark + Orange
    -- ═══════════════════════════════════════════════════════════════
    local Themes = {
        Dark = {
            bg = Color3.fromRGB(25, 25, 30),
            sidebar = Color3.fromRGB(20, 20, 25),
            tabActive = Color3.fromRGB(30, 30, 35),
            tabInactive = Color3.fromRGB(20, 20, 25),
            accent = Color3.fromRGB(255, 107, 53),
            accentDark = Color3.fromRGB(200, 80, 40),
            text = Color3.fromRGB(240, 240, 245),
            textDim = Color3.fromRGB(140, 140, 150),
            textHeader = Color3.fromRGB(100, 100, 110),
            checkboxBg = Color3.fromRGB(45, 45, 55),
            checkboxCheck = Color3.fromRGB(255, 107, 53),
            rowBg = Color3.fromRGB(30, 30, 35),
            sliderTrack = Color3.fromRGB(45, 45, 55),
            sliderFill = Color3.fromRGB(255, 107, 53),
            inputBg = Color3.fromRGB(35, 35, 42),
        },
        Light = {
            bg = Color3.fromRGB(245, 245, 250),
            sidebar = Color3.fromRGB(230, 230, 240),
            tabActive = Color3.fromRGB(240, 240, 245),
            tabInactive = Color3.fromRGB(230, 230, 240),
            accent = Color3.fromRGB(255, 107, 53),
            accentDark = Color3.fromRGB(200, 80, 40),
            text = Color3.fromRGB(30, 30, 40),
            textDim = Color3.fromRGB(100, 100, 110),
            textHeader = Color3.fromRGB(120, 120, 130),
            checkboxBg = Color3.fromRGB(200, 200, 210),
            checkboxCheck = Color3.fromRGB(255, 107, 53),
            rowBg = Color3.fromRGB(235, 235, 242),
            sliderTrack = Color3.fromRGB(200, 200, 210),
            sliderFill = Color3.fromRGB(255, 107, 53),
            inputBg = Color3.fromRGB(220, 220, 228),
        },
        ["Sky Blue"] = {
            bg = Color3.fromRGB(15, 25, 40),
            sidebar = Color3.fromRGB(12, 20, 35),
            tabActive = Color3.fromRGB(20, 35, 55),
            tabInactive = Color3.fromRGB(12, 20, 35),
            accent = Color3.fromRGB(0, 170, 255),
            accentDark = Color3.fromRGB(0, 130, 200),
            text = Color3.fromRGB(220, 240, 255),
            textDim = Color3.fromRGB(150, 180, 210),
            textHeader = Color3.fromRGB(100, 140, 180),
            checkboxBg = Color3.fromRGB(30, 50, 80),
            checkboxCheck = Color3.fromRGB(0, 170, 255),
            rowBg = Color3.fromRGB(20, 35, 55),
            sliderTrack = Color3.fromRGB(30, 50, 80),
            sliderFill = Color3.fromRGB(0, 170, 255),
            inputBg = Color3.fromRGB(25, 45, 75),
        },
        Galaxy = {
            bg = Color3.fromRGB(20, 10, 35),
            sidebar = Color3.fromRGB(15, 8, 28),
            tabActive = Color3.fromRGB(30, 15, 50),
            tabInactive = Color3.fromRGB(15, 8, 28),
            accent = Color3.fromRGB(180, 80, 255),
            accentDark = Color3.fromRGB(140, 60, 200),
            text = Color3.fromRGB(240, 220, 255),
            textDim = Color3.fromRGB(180, 150, 210),
            textHeader = Color3.fromRGB(140, 110, 170),
            checkboxBg = Color3.fromRGB(45, 25, 70),
            checkboxCheck = Color3.fromRGB(180, 80, 255),
            rowBg = Color3.fromRGB(30, 15, 50),
            sliderTrack = Color3.fromRGB(45, 25, 70),
            sliderFill = Color3.fromRGB(180, 80, 255),
            inputBg = Color3.fromRGB(40, 20, 65),
        },
    }

    local Languages = {
        English = {
            Home = "Home", Visual = "Visual", Combat = "Combat", Movement = "Movement",
            Utility = "Utility", Server = "Server", Fun = "Fun", Settings = "Settings",
            Theme = "Theme", Language = "Language", GUI = "GUI", ScriptName = "Script Name",
            Version = "Version", Username = "Username", Executor = "Executor",
            Credits = "Credits", Changelog = "Changelog", ESP = "ESP", BoxESP = "Box ESP",
            NameESP = "Name ESP", HealthESP = "Health ESP", DistanceESP = "Distance ESP",
            Tracers = "Tracers", ChamsXRay = "Chams / X-Ray", FullBright = "Full Bright",
            Aim = "Aim", SilentAim = "Silent Aim", AimFOV = "Aim FOV",
            AimPrediction = "Aim Prediction", TriggerBot = "Trigger Bot",
            HitboxExpander = "Hitbox Expander", Speed = "Speed", Fly = "Fly",
            Noclip = "Noclip", JumpPower = "Jump Power", InfiniteJump = "Infinite Jump",
            Teleport = "Teleport", ClickTeleport = "Click Teleport", Sprint = "Sprint",
            AntiVoid = "Anti Void", AntiAFK = "Anti AFK", FreezeTime = "Freeze Time",
            FPSBooster = "FPS Booster", RejoinServer = "Rejoin Server",
            ServerHop = "Server Hop", JoinSmallServer = "Join Small Server",
            PlayerList = "Player List", SpectatePlayer = "Spectate Player",
            Spin = "Spin", Float = "Float", Bang = "Bang", Fling = "Fling",
            OrbitPlayer = "Orbit Player", Invisible = "Invisible", Dark = "Dark",
            Light = "Light", SkyBlue = "Sky Blue", Galaxy = "Galaxy",
            SaveSettings = "Save Settings", AutoLoadSettings = "Auto Load Settings",
            ResetSettings = "Reset Settings", MinimizeButton = "Minimize Button",
            DraggableGUI = "Draggable GUI", ToggleKeybind = "Toggle Keybind",
            Notifications = "Notifications", SelectTheme = "Select Theme",
            SelectLanguage = "Select Language", SpectateSelected = "Spectate Selected",
            StopSpectating = "Stop Spectating", EnableAimbot = "Enable Aimbot",
            ShowFOVCircle = "Show FOV Circle", AimConfiguration = "Aim Configuration",
            Other = "Other", MaxDistance = "Max Distance", SpeedValue = "Speed Value",
            FlySpeed = "Fly Speed", JumpPowerValue = "Jump Power", SprintSpeed = "Sprint Speed",
            SpinSpeed = "Spin Speed", OrbitRadius = "Orbit Radius", OrbitSpeed = "Orbit Speed",
            HitboxSize = "Hitbox Size", AimFOVValue = "Aim FOV", AimSmoothness = "Aim Smoothness",
        },
        ["Tiếng Việt"] = {
            Home = "Trang chủ", Visual = "Hình ảnh", Combat = "Chiến đấu",
            Movement = "Di chuyển", Utility = "Tiện ích", Server = "Máy chủ",
            Fun = "Vui nhộn", Settings = "Cài đặt", Theme = "Giao diện",
            Language = "Ngôn ngữ", GUI = "Giao diện", ScriptName = "Tên Script",
            Version = "Phiên bản", Username = "Tên người dùng", Executor = "Executor",
            Credits = "Tín dụng", Changelog = "Nhật ký thay đổi", ESP = "ESP",
            BoxESP = "Box ESP", NameESP = "Tên ESP", HealthESP = "Máu ESP",
            DistanceESP = "Khoảng cách ESP", Tracers = "Đường dẫn",
            ChamsXRay = "Chams / X-Ray", FullBright = "Sáng tối đa",
            Aim = "Ngắm", SilentAim = "Ngắm âm thầm", AimFOV = "FOV Ngắm",
            AimPrediction = "Dự đoán Ngắm", TriggerBot = "Trigger Bot",
            HitboxExpander = "Mở rộng Hitbox", Speed = "Tốc độ", Fly = "Bay",
            Noclip = "Xuyên tường", JumpPower = "Lực nhảy",
            InfiniteJump = "Nhảy vô hạn", Teleport = "Dịch chuyển",
            ClickTeleport = "Click Dịch chuyển", Sprint = "Chạy nhanh",
            AntiVoid = "Chống Hố", AntiAFK = "Chống AFK",
            FreezeTime = "Đóng băng thời gian", FPSBooster = "Tăng FPS",
            RejoinServer = "Vào lại Server", ServerHop = "Chuyển Server",
            JoinSmallServer = "Vào Server nhỏ", PlayerList = "Danh sách người chơi",
            SpectatePlayer = "Theo dõi người chơi", Spin = "Xoay", Float = "Nổi",
            Bang = "Bang", Fling = "Ném", OrbitPlayer = "Quay quanh người chơi",
            Invisible = "Tàng hình", Dark = "Tối", Light = "Sáng",
            SkyBlue = "Xanh da trời", Galaxy = "Galaxy",
            SaveSettings = "Lưu cài đặt", AutoLoadSettings = "Tự động tải cài đặt",
            ResetSettings = "Đặt lại cài đặt", MinimizeButton = "Nút thu nhỏ",
            DraggableGUI = "Kéo thả GUI", ToggleKeybind = "Phím bật/tắt",
            Notifications = "Thông báo", SelectTheme = "Chọn giao diện",
            SelectLanguage = "Chọn ngôn ngữ", SpectateSelected = "Theo dõi đã chọn",
            StopSpectating = "Dừng theo dõi", EnableAimbot = "Bật Aimbot",
            ShowFOVCircle = "Hiện vòng FOV", AimConfiguration = "Cấu hình Aim",
            Other = "Khác", MaxDistance = "Khoảng cách tối đa", SpeedValue = "Giá trị tốc độ",
            FlySpeed = "Tốc độ bay", JumpPowerValue = "Lực nhảy", SprintSpeed = "Tốc độ chạy",
            SpinSpeed = "Tốc độ xoay", OrbitRadius = "Bán kính quay", OrbitSpeed = "Tốc độ quay",
            HitboxSize = "Kích thước Hitbox", AimFOVValue = "FOV Ngắm", AimSmoothness = "Độ mượt Ngắm",
        },
        ["Español"] = {
            Home = "Inicio", Visual = "Visual", Combat = "Combate", Movement = "Movimiento",
            Utility = "Utilidad", Server = "Servidor", Fun = "Diversión", Settings = "Ajustes",
            Theme = "Tema", Language = "Idioma", GUI = "Interfaz", ScriptName = "Nombre del Script",
            Version = "Versión", Username = "Usuario", Executor = "Ejecutor",
            Credits = "Créditos", Changelog = "Registro de cambios", ESP = "ESP", BoxESP = "Box ESP",
            NameESP = "Nombre ESP", HealthESP = "Salud ESP", DistanceESP = "Distancia ESP",
            Tracers = "Trazadores", ChamsXRay = "Chams / X-Ray", FullBright = "Brillo total",
            Aim = "Apuntar", SilentAim = "Apuntar silencioso", AimFOV = "FOV de Apuntado",
            AimPrediction = "Predicción de Apuntado", TriggerBot = "Trigger Bot",
            HitboxExpander = "Ampliar Hitbox", Speed = "Velocidad", Fly = "Volar",
            Noclip = "Noclip", JumpPower = "Potencia de salto", InfiniteJump = "Salto infinito",
            Teleport = "Teletransporte", ClickTeleport = "Click Teletransporte", Sprint = "Sprint",
            AntiVoid = "Anti Vacío", AntiAFK = "Anti AFK", FreezeTime = "Congelar tiempo",
            FPSBooster = "Aumentar FPS", RejoinServer = "Reunirse al servidor",
            ServerHop = "Cambiar servidor", JoinSmallServer = "Unirse a servidor pequeño",
            PlayerList = "Lista de jugadores", SpectatePlayer = "Espectar jugador",
            Spin = "Girar", Float = "Flotar", Bang = "Bang", Fling = "Lanzar",
            OrbitPlayer = "Orbitar jugador", Invisible = "Invisible", Dark = "Oscuro",
            Light = "Claro", SkyBlue = "Azul cielo", Galaxy = "Galaxia",
            SaveSettings = "Guardar ajustes", AutoLoadSettings = "Auto cargar ajustes",
            ResetSettings = "Restablecer ajustes", MinimizeButton = "Botón minimizar",
            DraggableGUI = "GUI arrastrable", ToggleKeybind = "Tecla de alternar",
            Notifications = "Notificaciones", SelectTheme = "Seleccionar tema",
            SelectLanguage = "Seleccionar idioma", SpectateSelected = "Espectar seleccionado",
            StopSpectating = "Dejar de espectar", EnableAimbot = "Activar Aimbot",
            ShowFOVCircle = "Mostrar círculo FOV", AimConfiguration = "Configuración de Apuntado",
            Other = "Otros", MaxDistance = "Distancia máxima", SpeedValue = "Valor de velocidad",
            FlySpeed = "Velocidad de vuelo", JumpPowerValue = "Potencia de salto", SprintSpeed = "Velocidad de sprint",
            SpinSpeed = "Velocidad de giro", OrbitRadius = "Radio de órbita", OrbitSpeed = "Velocidad de órbita",
            HitboxSize = "Tamaño de hitbox", AimFOVValue = "FOV de Apuntado", AimSmoothness = "Suavidad de Apuntado",
        },
        ["Português"] = {
            Home = "Início", Visual = "Visual", Combat = "Combate", Movement = "Movimento",
            Utility = "Utilitário", Server = "Servidor", Fun = "Diversão", Settings = "Configurações",
            Theme = "Tema", Language = "Idioma", GUI = "Interface", ScriptName = "Nome do Script",
            Version = "Versão", Username = "Usuário", Executor = "Executor",
            Credits = "Créditos", Changelog = "Registro de mudanças", ESP = "ESP", BoxESP = "Box ESP",
            NameESP = "Nome ESP", HealthESP = "Vida ESP", DistanceESP = "Distância ESP",
            Tracers = "Rastreadores", ChamsXRay = "Chams / X-Ray", FullBright = "Brilho total",
            Aim = "Mira", SilentAim = "Mira Silenciosa", AimFOV = "FOV da Mira",
            AimPrediction = "Predição de Mira", TriggerBot = "Trigger Bot",
            HitboxExpander = "Expandir Hitbox", Speed = "Velocidade", Fly = "Voar",
            Noclip = "Noclip", JumpPower = "Força do pulo", InfiniteJump = "Pulo infinito",
            Teleport = "Teleporte", ClickTeleport = "Click Teleporte", Sprint = "Correr",
            AntiVoid = "Anti Vazio", AntiAFK = "Anti AFK", FreezeTime = "Congelar tempo",
            FPSBooster = "Aumentar FPS", RejoinServer = "Reentrar no servidor",
            ServerHop = "Mudar servidor", JoinSmallServer = "Entrar em servidor pequeno",
            PlayerList = "Lista de jogadores", SpectatePlayer = "Espectar jogador",
            Spin = "Girar", Float = "Flutuar", Bang = "Bang", Fling = "Arremessar",
            OrbitPlayer = "Orbitar jogador", Invisible = "Invisível", Dark = "Escuro",
            Light = "Claro", SkyBlue = "Azul céu", Galaxy = "Galáxia",
            SaveSettings = "Salvar configurações", AutoLoadSettings = "Auto carregar configurações",
            ResetSettings = "Redefinir configurações", MinimizeButton = "Botão minimizar",
            DraggableGUI = "GUI arrastável", ToggleKeybind = "Tecla de alternar",
            Notifications = "Notificações", SelectTheme = "Selecionar tema",
            SelectLanguage = "Selecionar idioma", SpectateSelected = "Espectar selecionado",
            StopSpectating = "Parar de espectar", EnableAimbot = "Ativar Aimbot",
            ShowFOVCircle = "Mostrar círculo FOV", AimConfiguration = "Configuração de Mira",
            Other = "Outros", MaxDistance = "Distância máxima", SpeedValue = "Valor de velocidade",
            FlySpeed = "Velocidade de voo", JumpPowerValue = "Força do pulo", SprintSpeed = "Velocidade de corrida",
            SpinSpeed = "Velocidade de giro", OrbitRadius = "Raio de órbita", OrbitSpeed = "Velocidade de órbita",
            HitboxSize = "Tamanho da hitbox", AimFOVValue = "FOV da Mira", AimSmoothness = "Suavidade da Mira",
        },
        ["Русский"] = {
            Home = "Главная", Visual = "Визуал", Combat = "Бой", Movement = "Движение",
            Utility = "Утилиты", Server = "Сервер", Fun = "Развлечения", Settings = "Настройки",
            Theme = "Тема", Language = "Язык", GUI = "Интерфейс", ScriptName = "Имя скрипта",
            Version = "Версия", Username = "Имя пользователя", Executor = "Исполнитель",
            Credits = "Авторы", Changelog = "Журнал изменений", ESP = "ESP", BoxESP = "Box ESP",
            NameESP = "Имя ESP", HealthESP = "Здоровье ESP", DistanceESP = "Дистанция ESP",
            Tracers = "Трейсеры", ChamsXRay = "Chams / X-Ray", FullBright = "Полная яркость",
            Aim = "Прицел", SilentAim = "Тихий прицел", AimFOV = "FOV Прицела",
            AimPrediction = "Предсказание прицела", TriggerBot = "Trigger Bot",
            HitboxExpander = "Расширение хитбокса", Speed = "Скорость", Fly = "Полёт",
            Noclip = "Ноклип", JumpPower = "Сила прыжка", InfiniteJump = "Бесконечный прыжок",
            Teleport = "Телепорт", ClickTeleport = "Клик Телепорт", Sprint = "Спринт",
            AntiVoid = "Анти Пустота", AntiAFK = "Анти AFK", FreezeTime = "Заморозка времени",
            FPSBooster = "Усилитель FPS", RejoinServer = "Перезайти на сервер",
            ServerHop = "Сменить сервер", JoinSmallServer = "Присоединиться к малому серверу",
            PlayerList = "Список игроков", SpectatePlayer = "Наблюдать за игроком",
            Spin = "Вращение", Float = "Парение", Bang = "Bang", Fling = "Швырнуть",
            OrbitPlayer = "Орбита вокруг игрока", Invisible = "Невидимость", Dark = "Тёмная",
            Light = "Светлая", SkyBlue = "Небесно-голубая", Galaxy = "Галактика",
            SaveSettings = "Сохранить настройки", AutoLoadSettings = "Авто загрузка настроек",
            ResetSettings = "Сбросить настройки", MinimizeButton = "Кнопка сворачивания",
            DraggableGUI = "Перетаскиваемый GUI", ToggleKeybind = "Клавиша переключения",
            Notifications = "Уведомления", SelectTheme = "Выбрать тему",
            SelectLanguage = "Выбрать язык", SpectateSelected = "Наблюдать выбранного",
            StopSpectating = "Прекратить наблюдение", EnableAimbot = "Включить Aimbot",
            ShowFOVCircle = "Показать круг FOV", AimConfiguration = "Настройка прицела",
            Other = "Другое", MaxDistance = "Макс. дистанция", SpeedValue = "Значение скорости",
            FlySpeed = "Скорость полёта", JumpPowerValue = "Сила прыжка", SprintSpeed = "Скорость спринта",
            SpinSpeed = "Скорость вращения", OrbitRadius = "Радиус орбиты", OrbitSpeed = "Скорость орбиты",
            HitboxSize = "Размер хитбокса", AimFOVValue = "FOV Прицела", AimSmoothness = "Плавность прицела",
        },
    }

    local currentLang = "English"
    local currentTheme = "Dark"

    local function T(key)
        local langTable = Languages[currentLang]
        if langTable and langTable[key] then
            return langTable[key]
        end
        local engTable = Languages["English"]
        if engTable and engTable[key] then
            return engTable[key]
        end
        return key
    end

    local function getTheme()
        return Themes[currentTheme] or Themes["Dark"]
    end

    -- ═══════════════════════════════════════════════════════════════
    -- NOTIFICATION
    -- ═══════════════════════════════════════════════════════════════
    local function notify(title, content, duration)
        if not States.Notifications then return end
        duration = duration or 3

        pcall(function()
            local notifGui = Instance.new("ScreenGui")
            notifGui.Name = "FLUYEN_Noti_" .. tostring(math.random(100000, 999999))
            notifGui.ResetOnSpawn = false
            notifGui.DisplayOrder = 999
            notifGui.Parent = playerGui

            local theme = getTheme()

            local notifFrame = Instance.new("Frame")
            notifFrame.Size = UDim2.new(0, 280, 0, 70)
            notifFrame.Position = UDim2.new(1, 20, 0, 20)
            notifFrame.BackgroundColor3 = theme.bg
            notifFrame.BorderSizePixel = 0
            notifFrame.Parent = notifGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = notifFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.accent
            stroke.Thickness = 1.5
            stroke.Parent = notifFrame

            local accentBar = Instance.new("Frame")
            accentBar.Size = UDim2.new(0, 4, 1, 0)
            accentBar.BackgroundColor3 = theme.accent
            accentBar.BorderSizePixel = 0
            accentBar.Parent = notifFrame

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -20, 0, 22)
            titleLabel.Position = UDim2.new(0, 14, 0, 8)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 14
            titleLabel.TextColor3 = theme.text
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = notifFrame

            local contentLabel = Instance.new("TextLabel")
            contentLabel.Size = UDim2.new(1, -20, 0, 30)
            contentLabel.Position = UDim2.new(0, 14, 0, 30)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Text = content
            contentLabel.Font = Enum.Font.Gotham
            contentLabel.TextSize = 12
            contentLabel.TextColor3 = theme.textDim
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextWrapped = true
            contentLabel.Parent = notifFrame

            TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -300, 0, 20)
            }):Play()

            _delay(duration, function()
                pcall(function()
                    TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                        Position = UDim2.new(1, 20, 0, 20)
                    }):Play()
                    _wait(0.3)
                    notifGui:Destroy()
                end)
            end)
        end)
    end

    -- ═══════════════════════════════════════════════════════════════
    -- MAIN GUI - MODERN STYLE
    -- ═══════════════════════════════════════════════════════════════
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FLUYEN_Menu_" .. tostring(math.random(1000, 9999))
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
    local MENU_WIDTH, MENU_HEIGHT = 520, 380

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = getTheme().bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.ZIndex = 2
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    -- UI SCALE (FIXED - Scale starts at 1, menu visibility controlled by mainFrame.Visible)
    -- Wrapped in pcall because UIScale might not exist on some mobile executors
    local uiScale = nil
    local uiScaleOk = pcall(function()
        uiScale = Instance.new("UIScale")
        uiScale.Scale = 1
        uiScale.Parent = mainFrame
    end)
    if not uiScaleOk then
        uiScale = nil -- UIScale not supported, animations will be skipped
    end

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = getTheme().bg
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 10
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = SCRIPT_NAME .. " " .. SCRIPT_VERSION
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = getTheme().accent
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close X button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = getTheme().textDim
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar

    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = getTheme().textDim
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- SIDEBAR
    -- ═══════════════════════════════════════════════════════════════
    local SIDEBAR_WIDTH = 130
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "Sidebar"
    tabContainer.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -32)
    tabContainer.Position = UDim2.new(0, 0, 0, 32)
    tabContainer.BackgroundColor3 = getTheme().sidebar
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = 10
    tabContainer.ClipsDescendants = true
    tabContainer.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingLeft = UDim.new(0, 8)
    tabPadding.PaddingRight = UDim.new(0, 8)
    tabPadding.Parent = tabContainer

    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -32)
    contentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 32)
    contentArea.BackgroundColor3 = getTheme().bg
    contentArea.BackgroundTransparency = 0
    contentArea.ClipsDescendants = true
    contentArea.ZIndex = 10
    contentArea.Parent = mainFrame

    local pages = {}
    local tabButtons = {}
    local allUIElements = {}

    local function createPage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Position = UDim2.new(0, 0, 0, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = getTheme().accent
        page.ScrollBarImageTransparency = 0.3
        page.CanvasSize = UDim2.new(0, 0, 0, 500)
        -- ScrollingDirection may not exist on some mobile executors
        pcall(function() page.ScrollingDirection = Enum.ScrollingDirection.Y end)
        page.ScrollingEnabled = true
        page.Visible = false
        page.ZIndex = 2
        page.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = page

        pages[name] = page
        return page
    end

    -- Recalculate canvas size for all pages (fix for mobile executors where AutomaticCanvasSize doesn't work)
    local function recalcAllPages()
        _spawn(function()
            _wait(0.1) -- Wait for layout to compute sizes
            -- Temporarily make mainFrame visible (but off-screen) so AbsoluteSize is calculated correctly
            -- Without mainFrame being visible, children have zero AbsoluteSize
            local wasMainFrameVisible = mainFrame.Visible
            if not wasMainFrameVisible then
                mainFrame.Position = UDim2.new(0, -9999, 0, -9999) -- Move off-screen
                mainFrame.Visible = true
            end
            -- Make all pages temporarily visible so AbsoluteSize is calculated correctly
            local wasVisible = {}
            for pageName, page in pairs(pages) do
                wasVisible[pageName] = page.Visible
                page.Visible = true
            end
            _wait(0.05) -- Brief wait for layout to update on visible pages
            for pageName, page in pairs(pages) do
                pcall(function()
                    local contentHeight = 0
                    for _, child in ipairs(page:GetChildren()) do
                        if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                            -- Use AbsoluteSize.Y which gives the actual computed pixel height (works with both Scale and Offset)
                            local h = math.ceil(child.AbsoluteSize.Y > 0 and child.AbsoluteSize.Y or child.Size.Y.Offset)
                            contentHeight = contentHeight + h + 4
                        end
                    end
                    local totalHeight = math.max(contentHeight + 20, page.AbsoluteSize.Y + 1)
                    page.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
                end)
                -- Restore original visibility
                page.Visible = wasVisible[pageName]
            end
            -- Restore mainFrame visibility and position
            if not wasMainFrameVisible then
                mainFrame.Visible = false
                mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Restore centered position
            end
        end)
    end

    local function selectTab(name)
        for pageName, page in pairs(pages) do
            page.Visible = (pageName == name)
            -- Force layout recalculation for the now-visible page
            if pageName == name then
                page.CanvasPosition = UDim2.new(0, 0, 0, 0)
                local layout = page:FindFirstChild("UIListLayout")
                if layout then
                    pcall(function() layout:ApplyLayout() end)
                end
            end
        end
        for btnName, btn in pairs(tabButtons) do
            local active = (btnName == name)
            local theme = getTheme()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = active and theme.tabActive or theme.tabInactive
            }):Play()
            local border = btn:FindFirstChild("ActiveBorder")
            if border then
                border.Visible = active
            end
            btn.TextColor3 = active and theme.accent or theme.textDim
        end
        -- Recalculate the selected page canvas size when switching tabs
        recalcAllPages()
    end

    -- Tab icons (using ASCII-safe text instead of emoji for mobile compatibility)
    local tabIcons = {
        Home = "[H]", Visual = "[V]", Combat = "[C]",
        Movement = "[M]", Utility = "[U]", Server = "[S]",
        Fun = "[F]", Settings = "[G]"
    }

    local tabList = {"Home", "Visual", "Combat", "Movement", "Utility", "Server", "Fun", "Settings"}

    for i, name in ipairs(tabList) do
        createPage(name)

        local btn = Instance.new("TextButton")
        btn.Name = name .. "Button"
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = getTheme().tabInactive
        btn.AutoButtonColor = false
        btn.Text = " " .. (tabIcons[name] or "•") .. " " .. T(name)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextColor3 = getTheme().textDim
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.ZIndex = 2
        btn.Parent = tabContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local activeBorder = Instance.new("Frame")
        activeBorder.Name = "ActiveBorder"
        activeBorder.Size = UDim2.new(0, 3, 0.6, 0)
        activeBorder.Position = UDim2.new(0, 0, 0.2, 0)
        activeBorder.BackgroundColor3 = getTheme().accent
        activeBorder.BorderSizePixel = 0
        activeBorder.Visible = false
        activeBorder.Parent = btn

        local borderCorner = Instance.new("UICorner")
        borderCorner.CornerRadius = UDim.new(0, 2)
        borderCorner.Parent = activeBorder

        tabButtons[name] = btn
    end

    for name, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
    end

    selectTab("Home")

    -- ═══════════════════════════════════════════════════════════════
    -- UI COMPONENTS
    -- ═══════════════════════════════════════════════════════════════

    local function addSection(page, text)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, 0, 0, 20)
        section.BackgroundTransparency = 1
        section.Text = text:upper()
        section.Font = Enum.Font.GothamBold
        section.TextSize = 11
        section.TextColor3 = getTheme().textHeader
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.LayoutOrder = #page:GetChildren() * 10
        section.ZIndex = 3
        section.Parent = page
        table.insert(allUIElements, {type = "section", obj = section})
        return section
    end

    local function addCheckbox(page, label, key, defaultOn, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.LayoutOrder = #page:GetChildren() * 10 + 1
        row.ZIndex = 3
        row.Parent = page

        local checkboxBg = Instance.new("Frame")
        checkboxBg.Size = UDim2.new(0, 18, 0, 18)
        checkboxBg.Position = UDim2.new(0, 0, 0.5, -9)
        checkboxBg.BackgroundColor3 = getTheme().checkboxBg
        checkboxBg.BorderSizePixel = 0
        checkboxBg.ZIndex = 4
        checkboxBg.Parent = row

        local cbCorner = Instance.new("UICorner")
        cbCorner.CornerRadius = UDim.new(0, 4)
        cbCorner.Parent = checkboxBg

        local checkmark = Instance.new("Frame")
        checkmark.Size = UDim2.new(0, 12, 0, 12)
        checkmark.Position = UDim2.new(0.5, -6, 0.5, -6)
        checkmark.BackgroundColor3 = getTheme().checkboxCheck
        checkmark.BorderSizePixel = 0
        checkmark.Visible = false
        checkmark.ZIndex = 5
        checkmark.Parent = checkboxBg

        local checkCorner = Instance.new("UICorner")
        checkCorner.CornerRadius = UDim.new(0, 3)
        checkCorner.Parent = checkmark

        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(1, -28, 1, 0)
        labelText.Position = UDim2.new(0, 26, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.Font = Enum.Font.Gotham
        labelText.TextSize = 13
        labelText.TextColor3 = getTheme().text
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.ZIndex = 4
        labelText.Parent = row

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.ZIndex = 6
        clickBtn.Parent = row

        local state = States[key] or defaultOn or false
        States[key] = state

        local function applyState()
            checkmark.Visible = state
        end

        applyState()

        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            States[key] = state
            applyState()
            if callback then
                pcall(function() callback(state) end)
            end
        end)

        table.insert(allUIElements, {type = "checkbox", row = row, bg = checkboxBg, check = checkmark, label = labelText})
        return row
    end

    local function addSlider(page, label, key, min, max, default, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundTransparency = 1
        row.LayoutOrder = #page:GetChildren() * 10 + 1
        row.ZIndex = 3
        row.Parent = page

        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(1, -50, 0, 16)
        labelText.Position = UDim2.new(0, 0, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label .. " " .. (Values[key] or default)
        labelText.Font = Enum.Font.Gotham
        labelText.TextSize = 12
        labelText.TextColor3 = getTheme().text
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.ZIndex = 4
        labelText.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 4)
        track.Position = UDim2.new(0, 0, 0, 26)
        track.BackgroundColor3 = getTheme().sliderTrack
        track.BorderSizePixel = 0
        track.ZIndex = 4
        track.Parent = row

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fillPct = (max > min) and math.max(0, math.min((default - min) / (max - min), 1)) or 0
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(fillPct, 0, 1, 0)
        fill.BackgroundColor3 = getTheme().sliderFill
        fill.BorderSizePixel = 0
        fill.ZIndex = 5
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(fillPct, -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 6
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local dragging = false

        local function updateSlider(input)
            local pos = math.max(0, math.min((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 1))
            local rawValue = min + pos * (max - min)
            local value = (max - min) < 10 and math.floor(rawValue * 100) / 100 or math.floor(rawValue)
            Values[key] = value
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -6)
            labelText.Text = label .. " " .. value
            if callback then
                pcall(function() callback(value) end)
            end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        table.insert(allUIElements, {type = "slider", row = row, track = track, fill = fill, label = labelText})
        return row
    end

    local function addButton(page, label, callback)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = getTheme().accent
        row.AutoButtonColor = false
        row.Text = label
        row.Font = Enum.Font.GothamBold
        row.TextSize = 12
        row.TextColor3 = Color3.fromRGB(255, 255, 255)
        row.LayoutOrder = #page:GetChildren() * 10 + 1
        row.ZIndex = 3
        row.Parent = page

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row

        row.MouseButton1Click:Connect(function()
            pcall(function() callback() end)
        end)

        row.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = getTheme().accentDark}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = getTheme().accent}):Play()
        end)

        table.insert(allUIElements, {type = "button", obj = row})
        return row
    end

    local function addInfoRow(page, label, value)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        row.LayoutOrder = #page:GetChildren() * 10 + 1
        row.ZIndex = 3
        row.Parent = page

        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0.4, 0, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.Font = Enum.Font.Gotham
        labelText.TextSize = 12
        labelText.TextColor3 = getTheme().textDim
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = row

        local valueText = Instance.new("TextLabel")
        valueText.Size = UDim2.new(0.6, 0, 1, 0)
        valueText.Position = UDim2.new(0.4, 0, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = value
        valueText.Font = Enum.Font.GothamBold
        valueText.TextSize = 12
        valueText.TextColor3 = getTheme().text
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Parent = row

        table.insert(allUIElements, {type = "inforow", label = labelText, value = valueText})
        return row, valueText
    end

    local function addDropdown(page, label, options, default, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundTransparency = 1
        row.LayoutOrder = #page:GetChildren() * 10 + 1
        row.ZIndex = 3
        row.Parent = page

        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0.4, 0, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.Font = Enum.Font.Gotham
        labelText.TextSize = 12
        labelText.TextColor3 = getTheme().text
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.ZIndex = 4
        labelText.Parent = row

        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0.55, 0, 0, 24)
        dropdownBtn.Position = UDim2.new(0.45, 0, 0.5, -12)
        dropdownBtn.BackgroundColor3 = getTheme().inputBg
        dropdownBtn.AutoButtonColor = false
        dropdownBtn.Text = default
        dropdownBtn.Font = Enum.Font.Gotham
        dropdownBtn.TextSize = 11
        dropdownBtn.TextColor3 = getTheme().text
        dropdownBtn.ZIndex = 4
        dropdownBtn.Parent = row

        local ddCorner = Instance.new("UICorner")
        ddCorner.CornerRadius = UDim.new(0, 4)
        ddCorner.Parent = dropdownBtn

        local dropdownOpen = false
        local dropdownFrame = nil

        dropdownBtn.MouseButton1Click:Connect(function()
            if dropdownOpen then
                if dropdownFrame then dropdownFrame:Destroy() end
                dropdownOpen = false
                return
            end

            dropdownOpen = true
            dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 24, 120))
            dropdownFrame.Position = UDim2.new(0, 0, 1, 2)
            dropdownFrame.BackgroundColor3 = getTheme().inputBg
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.ZIndex = 8
            dropdownFrame.Parent = dropdownBtn

            local dfCorner = Instance.new("UICorner")
            dfCorner.CornerRadius = UDim.new(0, 4)
            dfCorner.Parent = dropdownFrame

            local dfLayout = Instance.new("UIListLayout")
            dfLayout.SortOrder = Enum.SortOrder.LayoutOrder
            dfLayout.Parent = dropdownFrame

            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 24)
                optBtn.BackgroundColor3 = getTheme().inputBg
                optBtn.AutoButtonColor = false
                optBtn.Text = opt
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 11
                optBtn.TextColor3 = getTheme().text
                optBtn.LayoutOrder = i
                optBtn.ZIndex = 9
                optBtn.Parent = dropdownFrame

                optBtn.MouseButton1Click:Connect(function()
                    dropdownBtn.Text = opt
                    if dropdownFrame then dropdownFrame:Destroy() end
                    dropdownOpen = false
                    if callback then
                        pcall(function() callback(opt) end)
                    end
                end)

                optBtn.MouseEnter:Connect(function()
                    optBtn.BackgroundColor3 = getTheme().accent
                    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end)
                optBtn.MouseLeave:Connect(function()
                    optBtn.BackgroundColor3 = getTheme().inputBg
                    optBtn.TextColor3 = getTheme().text
                end)
            end
        end)

        table.insert(allUIElements, {type = "dropdown", row = row, btn = dropdownBtn, label = labelText})
        return row
    end

    -- ═══════════════════════════════════════════════════════════════
    -- HOME TAB
    -- ═══════════════════════════════════════════════════════════════
    addSection(pages["Home"], T("Home"))
    addInfoRow(pages["Home"], T("ScriptName"), SCRIPT_NAME)
    addInfoRow(pages["Home"], T("Version"), SCRIPT_VERSION)
    addInfoRow(pages["Home"], T("Username"), player.Name)

    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then
            executorName = identifyexecutor()
        elseif syn then
            executorName = "Synapse X"
        elseif fluxus then
            executorName = "Fluxus"
        elseif krnl then
            executorName = "KRNL"
        elseif delta then
            executorName = "Delta"
        elseif getexecutorname then
            executorName = getexecutorname()
        end
    end)
    addInfoRow(pages["Home"], T("Executor"), executorName)
    addInfoRow(pages["Home"], T("Credits"), CREDITS)

    addSection(pages["Home"], T("Changelog"))
    local changelogText = Instance.new("TextLabel")
    changelogText.Size = UDim2.new(1, 0, 0, 80)
    changelogText.BackgroundTransparency = 1
    changelogText.Text = "• v3.2 - Fixed all bugs + Full Features\n• v3.1 - Fixed menu not showing\n• v3.0 - Full HUD Menu\n• v2.0 - Added ESP System\n• v1.0 - Initial Release"
    changelogText.Font = Enum.Font.Gotham
    changelogText.TextSize = 11
    changelogText.TextColor3 = getTheme().textDim
    changelogText.TextXAlignment = Enum.TextXAlignment.Left
    changelogText.TextYAlignment = Enum.TextYAlignment.Top
    changelogText.TextWrapped = true
    changelogText.LayoutOrder = #pages["Home"]:GetChildren() * 10 + 1
    changelogText.ZIndex = 3
    changelogText.Parent = pages["Home"]

    -- ═══════════════════════════════════════════════════════════════
    -- VISUAL TAB - UNIVERSAL ESP
    -- ═══════════════════════════════════════════════════════════════
    local ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "FLUYEN_ESP"
    ESPFolder.Parent = Workspace

    -- Tracers storage
    local tracerLines = {}

    local function createESPForPlayer(targetPlayer)
        if targetPlayer == player then return end

        local char = targetPlayer.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local oldEsp = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
        if oldEsp then oldEsp:Destroy() end

        local espGui = Instance.new("BillboardGui")
        espGui.Name = targetPlayer.Name .. "_ESP"
        espGui.Size = UDim2.new(0, 200, 0, 80)
        espGui.StudsOffset = Vector3.new(0, 2.5, 0)
        espGui.AlwaysOnTop = true
        espGui.Parent = ESPFolder

        local espFrame = Instance.new("Frame")
        espFrame.Size = UDim2.new(1, 0, 1, 0)
        espFrame.BackgroundTransparency = 1
        espFrame.Parent = espGui

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0, 18)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = targetPlayer.DisplayName
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = espFrame

        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "Health"
        healthLabel.Size = UDim2.new(1, 0, 0, 14)
        healthLabel.Position = UDim2.new(0, 0, 0, 18)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "100 HP"
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextSize = 11
        healthLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        healthLabel.TextStrokeTransparency = 0.5
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        healthLabel.Parent = espFrame

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Distance"
        distLabel.Size = UDim2.new(1, 0, 0, 14)
        distLabel.Position = UDim2.new(0, 0, 0, 32)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0 studs"
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextSize = 11
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeTransparency = 0.5
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.Parent = espFrame

        local box = Instance.new("Frame")
        box.Name = "Box"
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 2
        box.BorderColor3 = Color3.fromRGB(255, 107, 53)
        box.Parent = espFrame

        espGui.Adornee = hrp

        local highlight = Instance.new("Highlight")
        highlight.Name = targetPlayer.Name .. "_Chams"
        highlight.FillColor = Color3.fromRGB(255, 107, 53)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = ESPFolder

        if char then
            highlight.Adornee = char
        end
    end

    local function removeESPForPlayer(targetPlayer)
        local esp = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
        if esp then esp:Destroy() end
        local chams = ESPFolder:FindFirstChild(targetPlayer.Name .. "_Chams")
        if chams then chams:Destroy() end
        if tracerLines[targetPlayer] then
            tracerLines[targetPlayer]:Destroy()
            tracerLines[targetPlayer] = nil
        end
    end

    local function updateTracers()
        for plr, line in pairs(tracerLines) do
            if not plr.Parent or not States.Tracers then
                pcall(function() line:Destroy() end)
                tracerLines[plr] = nil
            end
        end

        if not States.Tracers then return end

        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local char = targetPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local distance = (hrp.Position - camera.CFrame.Position).Magnitude
                        if distance <= Values.ESPMaxDistance then
                            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local line = tracerLines[targetPlayer]
                                if not line then
                                    line = Instance.new("Frame")
                                    line.Name = targetPlayer.Name .. "_Tracer"
                                    line.BorderSizePixel = 0
                                    line.BackgroundColor3 = getTheme().accent
                                    line.ZIndex = 5
                                    line.Parent = screenGui
                                    tracerLines[targetPlayer] = line
                                end
                                local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                                local startPos = Vector2.new(screenCenter.X, screenCenter.Y)
                                local endPos = Vector2.new(screenPos.X, screenPos.Y)
                                local diff = endPos - startPos
                                local dist = diff.Magnitude
                                local angle = math.atan2(diff.Y, diff.X)

                                line.Size = UDim2.new(0, dist, 0, 1)
                                line.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
                                line.Rotation = math.deg(angle)
                                line.Visible = true
                            else
                                if tracerLines[targetPlayer] then
                                    tracerLines[targetPlayer].Visible = false
                                end
                            end
                        else
                            if tracerLines[targetPlayer] then
                                tracerLines[targetPlayer].Visible = false
                            end
                        end
                    end
                end
            end
        end
    end

    local function updateESP()
        if not States.ESP then
            for _, child in pairs(ESPFolder:GetChildren()) do
                if child:IsA("BillboardGui") then
                    child.Enabled = false
                end
                if child:IsA("Highlight") then
                    child.Enabled = false
                end
            end
            return
        end

        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local char = targetPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChild("Humanoid")

                    if hrp and hum and hum.Health > 0 then
                        local distance = (hrp.Position - camera.CFrame.Position).Magnitude

                        if distance <= Values.ESPMaxDistance then
                            local espGui = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
                            if not espGui then
                                pcall(function() createESPForPlayer(targetPlayer) end)
                                espGui = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
                            end

                            if espGui then
                                espGui.Enabled = true
                                espGui.Adornee = hrp

                                local frame = espGui:FindFirstChild("Frame")
                                if frame then
                                    local nameLbl = frame:FindFirstChild("Name")
                                    if nameLbl then
                                        nameLbl.Visible = States.NameESP
                                        nameLbl.Text = targetPlayer.DisplayName
                                    end

                                    local healthLbl = frame:FindFirstChild("Health")
                                    if healthLbl then
                                        healthLbl.Visible = States.HealthESP
                                        healthLbl.Text = math.floor(hum.Health) .. " HP"
                                        local hpPercent = hum.Health / hum.MaxHealth
                                        healthLbl.TextColor3 = Color3.fromRGB(255 - (255 * hpPercent), 255 * hpPercent, 0)
                                    end

                                    local distLbl = frame:FindFirstChild("Distance")
                                    if distLbl then
                                        distLbl.Visible = States.DistanceESP
                                        distLbl.Text = math.floor(distance) .. " studs"
                                    end

                                    local box = frame:FindFirstChild("Box")
                                    if box then
                                        box.Visible = States.BoxESP
                                    end
                                end
                            end

                            local highlight = ESPFolder:FindFirstChild(targetPlayer.Name .. "_Chams")
                            if highlight then
                                highlight.Enabled = States.Chams
                                highlight.Adornee = char
                            end
                        else
                            local espGui = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
                            if espGui then espGui.Enabled = false end
                        end
                    else
                        local espGui = ESPFolder:FindFirstChild(targetPlayer.Name .. "_ESP")
                        if espGui then espGui.Enabled = false end
                    end
                else
                    pcall(function() removeESPForPlayer(targetPlayer) end)
                end
            else
                pcall(function() removeESPForPlayer(targetPlayer) end)
            end
        end
    end

    -- Full Bright
    local originalBrightness = Lighting.Brightness
    local originalShadows = Lighting.GlobalShadows
    local fullBrightConn = nil

    -- Visual Tab UI
    addSection(pages["Visual"], T("Visual"))
    addCheckbox(pages["Visual"], T("ESP"), "ESP", false, function(state)
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    pcall(function() createESPForPlayer(p) end)
                end
            end
            notify("ESP", "Enabled", 2)
        else
            notify("ESP", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Visual"], T("BoxESP"), "BoxESP", false)
    addCheckbox(pages["Visual"], T("NameESP"), "NameESP", false)
    addCheckbox(pages["Visual"], T("HealthESP"), "HealthESP", false)
    addCheckbox(pages["Visual"], T("DistanceESP"), "DistanceESP", false)
    addCheckbox(pages["Visual"], T("Tracers"), "Tracers", false)
    addCheckbox(pages["Visual"], T("ChamsXRay"), "Chams", false)
    addSlider(pages["Visual"], T("MaxDistance"), "ESPMaxDistance", 100, 5000, 1000)

    addCheckbox(pages["Visual"], T("FullBright"), "FullBright", false, function(state)
        if state then
            originalBrightness = Lighting.Brightness
            originalShadows = Lighting.GlobalShadows
            Lighting.Brightness = Values.FullBrightValue
            Lighting.GlobalShadows = false
            fullBrightConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    Lighting.Brightness = Values.FullBrightValue
                    Lighting.GlobalShadows = false
                end)
            end)
            notify("Full Bright", "Enabled", 2)
        else
            Lighting.Brightness = originalBrightness
            Lighting.GlobalShadows = originalShadows
            if fullBrightConn then fullBrightConn:Disconnect() end
            notify("Full Bright", "Disabled", 2)
        end
    end)

    -- ESP connections
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            pcall(function() createESPForPlayer(p) end)
        end
    end

    Players.PlayerAdded:Connect(function(p)
        pcall(function() createESPForPlayer(p) end)
    end)

    Players.PlayerRemoving:Connect(function(p)
        pcall(function() removeESPForPlayer(p) end)
    end)

    RunService.RenderStepped:Connect(function()
        pcall(updateESP)
        pcall(updateTracers)
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- COMBAT TAB
    -- ═══════════════════════════════════════════════════════════════
    local aimConn = nil
    local silentAimConn = nil
    local triggerBotConn = nil
    local fovCircle = nil

    local function getClosestPlayer()
        local closest = nil
        local closestDist = math.huge
        local mousePos = UserInputService:GetMouseLocation()

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local char = p.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            if dist < closestDist and dist <= Values.AimFOVValue then
                                closestDist = dist
                                closest = p
                            end
                        end
                    end
                end
            end
        end

        return closest
    end

    local function createFOVCircle()
        pcall(function()
            if Drawing then
                fovCircle = Drawing.new("Circle")
                fovCircle.Visible = false
                fovCircle.Thickness = 1
                fovCircle.Color = Color3.fromRGB(255, 107, 53)
                fovCircle.Filled = false
                fovCircle.NumSides = 64
            end
        end)
    end

    createFOVCircle()

    local function updateFOVCircle()
        pcall(function()
            if fovCircle and States.AimFOV then
                fovCircle.Radius = Values.AimFOVValue
                fovCircle.Position = UserInputService:GetMouseLocation()
                fovCircle.Visible = true
            elseif fovCircle then
                fovCircle.Visible = false
            end
        end)
    end

    local function startAim()
        if aimConn then aimConn:Disconnect() end
        aimConn = RunService.RenderStepped:Connect(function()
            if not States.Aim then return end
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

            local target = getClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local targetPos = target.Character.Head.Position
                if States.AimPrediction then
                    local velocity = target.Character.HumanoidRootPart.Velocity
                    targetPos = targetPos + (velocity * Values.AimSmoothness)
                end
                camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
            end
        end)
    end

    local function startSilentAim()
        if silentAimConn then silentAimConn:Disconnect() end
        silentAimConn = RunService.RenderStepped:Connect(function()
            if not States.SilentAim then return end
            local target = getClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                _G.SilentAimTarget = target.Character.Head
            else
                _G.SilentAimTarget = nil
            end
        end)
    end

    local function startTriggerBot()
        if triggerBotConn then triggerBotConn:Disconnect() end
        triggerBotConn = RunService.RenderStepped:Connect(function()
            if not States.TriggerBot then return end

            local mousePos = UserInputService:GetMouseLocation()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    local char = p.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                if (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude < 20 then
                                    pcall(function()
                                        if mouse1click then mouse1click() end
                                    end)
                                    _wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local hitboxData = {}
    local function expandHitboxes(state)
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    local char = p.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and not hitboxData[p] then
                            hitboxData[p] = hrp.Size
                            hrp.Size = Vector3.new(Values.HitboxSize, Values.HitboxSize, Values.HitboxSize)
                            hrp.Transparency = 0.7
                        end
                    end
                end
            end
        else
            for p, originalSize in pairs(hitboxData) do
                pcall(function()
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        p.Character.HumanoidRootPart.Size = originalSize
                        p.Character.HumanoidRootPart.Transparency = 1
                    end
                end)
            end
            hitboxData = {}
        end
    end

    -- Combat Tab UI
    addSection(pages["Combat"], T("Combat"))

    addSection(pages["Combat"], T("Aim"))
    addCheckbox(pages["Combat"], T("EnableAimbot"), "Aim", false, function(state)
        if state then
            startAim()
            notify("Aimbot", "Enabled - Hold RMB", 2)
        else
            if aimConn then aimConn:Disconnect() end
            notify("Aimbot", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Combat"], T("SilentAim"), "SilentAim", false, function(state)
        if state then
            startSilentAim()
            notify("Silent Aim", "Enabled", 2)
        else
            if silentAimConn then silentAimConn:Disconnect() end
            _G.SilentAimTarget = nil
            notify("Silent Aim", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Combat"], T("ShowFOVCircle"), "AimFOV", false, function(state)
        if state then
            notify("FOV Circle", "Enabled", 2)
        else
            if fovCircle then fovCircle.Visible = false end
            notify("FOV Circle", "Disabled", 2)
        end
    end)

    addSection(pages["Combat"], T("AimConfiguration"))
    addSlider(pages["Combat"], T("AimFOVValue"), "AimFOVValue", 50, 500, 180, function(val)
        if fovCircle then fovCircle.Radius = val end
    end)

    addSlider(pages["Combat"], T("AimSmoothness"), "AimSmoothness", 0, 1, 0.1)

    addCheckbox(pages["Combat"], T("AimPrediction"), "AimPrediction", false)

    addSection(pages["Combat"], T("Other"))
    addCheckbox(pages["Combat"], T("TriggerBot"), "TriggerBot", false, function(state)
        if state then
            startTriggerBot()
            notify("Trigger Bot", "Enabled", 2)
        else
            if triggerBotConn then triggerBotConn:Disconnect() end
            notify("Trigger Bot", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Combat"], T("HitboxExpander"), "HitboxExpander", false, function(state)
        expandHitboxes(state)
        if state then
            notify("Hitbox", "Expanded to " .. Values.HitboxSize, 2)
        else
            notify("Hitbox", "Reset", 2)
        end
    end)

    addSlider(pages["Combat"], T("HitboxSize"), "HitboxSize", 2, 20, 5, function(val)
        if States.HitboxExpander then expandHitboxes(true) end
    end)

    RunService.RenderStepped:Connect(function()
        pcall(updateFOVCircle)
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- MOVEMENT TAB
    -- ═══════════════════════════════════════════════════════════════
    local speedConn = nil
    local flyConn = nil
    local noclipConn = nil
    local jumpConn = nil
    local sprintConn = nil
    local antiVoidConn = nil
    local flyBodyVel = nil
    local flyBodyGyro = nil
    local clickTeleportConn = nil

    local function startSpeed()
        if speedConn then speedConn:Disconnect() end
        speedConn = RunService.RenderStepped:Connect(function()
            if not States.Speed then return end
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end

            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end

            if moveDir.Magnitude > 0 then
                hum.WalkSpeed = Values.SpeedValue
            else
                hum.WalkSpeed = 16
            end
        end)
    end

    local function startFly()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVel.Velocity = Vector3.new(0, 0, 0)
        flyBodyVel.Parent = hrp

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.P = 10000
        flyBodyGyro.Parent = hrp

        flyConn = RunService.RenderStepped:Connect(function()
            if not States.Fly then return end
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local velocity = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity = velocity - Vector3.new(0, 1, 0) end

            if flyBodyVel then
                if velocity.Magnitude > 0 then
                    flyBodyVel.Velocity = velocity.Unit * Values.FlySpeed
                else
                    flyBodyVel.Velocity = Vector3.new(0, 0, 0)
                end
            end
            if flyBodyGyro then
                flyBodyGyro.CFrame = camera.CFrame
            end
        end)
    end

    local function stopFly()
        if flyConn then flyConn:Disconnect() end
        if flyBodyVel then flyBodyVel:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        flyBodyVel = nil
        flyBodyGyro = nil
    end

    local function startNoclip()
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            if not States.Noclip then return end
            local char = player.Character
            if not char then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function startInfiniteJump()
        if jumpConn then jumpConn:Disconnect() end
        jumpConn = UserInputService.JumpRequest:Connect(function()
            if not States.InfiniteJump then return end
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    local function startSprint()
        if sprintConn then sprintConn:Disconnect() end
        sprintConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not States.Sprint then return end
            if input.KeyCode == Enum.KeyCode.LeftShift then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum.WalkSpeed = Values.SprintSpeed end
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.LeftShift then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end
        end)
    end

    local function startAntiVoid()
        if antiVoidConn then antiVoidConn:Disconnect() end
        antiVoidConn = RunService.RenderStepped:Connect(function()
            if not States.AntiVoid then return end
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -50 then
                hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z)
                notify("Anti Void", "Teleported back up!", 2)
            end
        end)
    end

    -- Click Teleport
    local function startClickTeleport()
        if clickTeleportConn then clickTeleportConn:Disconnect() end
        clickTeleportConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not States.ClickTeleport then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local mouse = player:GetMouse()
                if mouse then
                    local target = mouse.Hit
                    if target then
                        hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                        notify("Click Teleport", "Teleported!", 1)
                    end
                end
            end
        end)
    end

    -- Movement Tab UI
    addSection(pages["Movement"], T("Movement"))

    addCheckbox(pages["Movement"], T("Speed"), "Speed", false, function(state)
        if state then
            startSpeed()
            notify("Speed", "Speed set to " .. Values.SpeedValue, 2)
        else
            if speedConn then speedConn:Disconnect() end
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
            notify("Speed", "Disabled", 2)
        end
    end)
    addSlider(pages["Movement"], T("SpeedValue"), "SpeedValue", 16, 200, 50)

    addCheckbox(pages["Movement"], T("Fly"), "Fly", false, function(state)
        if state then
            startFly()
            notify("Fly", "Enabled - WASD to move", 3)
        else
            stopFly()
            notify("Fly", "Disabled", 2)
        end
    end)
    addSlider(pages["Movement"], T("FlySpeed"), "FlySpeed", 10, 200, 50)

    addCheckbox(pages["Movement"], T("Noclip"), "Noclip", false, function(state)
        if state then
            startNoclip()
            notify("Noclip", "Enabled", 2)
        else
            if noclipConn then noclipConn:Disconnect() end
            local char = player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            notify("Noclip", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Movement"], T("JumpPower"), "JumpPower", false, function(state)
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = state and Values.JumpPowerValue or 50
            end
        end
        notify("Jump Power", state and "Set to " .. Values.JumpPowerValue or "Reset", 2)
    end)
    addSlider(pages["Movement"], T("JumpPowerValue"), "JumpPowerValue", 50, 300, 100, function(val)
        if States.JumpPower then
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.JumpPower = val end
            end
        end
    end)

    addCheckbox(pages["Movement"], T("InfiniteJump"), "InfiniteJump", false, function(state)
        if state then
            startInfiniteJump()
            notify("Infinite Jump", "Enabled", 2)
        else
            if jumpConn then jumpConn:Disconnect() end
            notify("Infinite Jump", "Disabled", 2)
        end
    end)

    -- Teleport button
    addButton(pages["Movement"], T("Teleport"), function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local mouse = player:GetMouse()
        if mouse then
            local target = mouse.Hit
            if target then
                hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                notify("Teleport", "Teleported to mouse position!", 2)
            end
        end
    end)

    addCheckbox(pages["Movement"], T("ClickTeleport"), "ClickTeleport", false, function(state)
        if state then
            startClickTeleport()
            notify("Click Teleport", "Enabled - Click to teleport", 2)
        else
            if clickTeleportConn then clickTeleportConn:Disconnect() end
            notify("Click Teleport", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Movement"], T("Sprint"), "Sprint", false, function(state)
        if state then
            startSprint()
            notify("Sprint", "Hold Shift to sprint", 2)
        else
            if sprintConn then sprintConn:Disconnect() end
            notify("Sprint", "Disabled", 2)
        end
    end)
    addSlider(pages["Movement"], T("SprintSpeed"), "SprintSpeed", 30, 150, 70)

    addCheckbox(pages["Movement"], T("AntiVoid"), "AntiVoid", false, function(state)
        if state then
            startAntiVoid()
            notify("Anti Void", "Enabled", 2)
        else
            if antiVoidConn then antiVoidConn:Disconnect() end
            notify("Anti Void", "Disabled", 2)
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- UTILITY TAB
    -- ═══════════════════════════════════════════════════════════════
    local antiAFKConn = nil
    local antiAFKLastMove = tick()

    local function startAntiAFK()
        if antiAFKConn then antiAFKConn:Disconnect() end
        antiAFKConn = RunService.RenderStepped:Connect(function()
            if not States.AntiAFK then return end
            if tick() - antiAFKLastMove > 120 then
                antiAFKLastMove = tick()
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        hum:Move(Vector3.new(0.1, 0, 0), true)
                        _wait(0.1)
                        hum:Move(Vector3.new(-0.1, 0, 0), true)
                    end
                end
            end
        end)

        UserInputService.InputBegan:Connect(function()
            antiAFKLastMove = tick()
        end)
    end

    local freezeTimeConn = nil
    local function startFreezeTime()
        if freezeTimeConn then freezeTimeConn:Disconnect() end
        freezeTimeConn = RunService.RenderStepped:Connect(function()
            if not States.FreezeTime then return end
            pcall(function()
                game:GetService("RunService").Heartbeat:Wait(0.05)
            end)
        end)
    end

    local fpsBoosted = false
    local function boostFPS(state)
        if state and not fpsBoosted then
            fpsBoosted = true
            pcall(function()
                if settings and settings().Rendering then
                    settings().Rendering.QualityLevel = 1
                end
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Material = Enum.Material.SmoothPlastic
                    end
                    if v:IsA("Decal") or v:IsA("Texture") then
                        v:Destroy()
                    end
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 100000
                for _, v in pairs(Lighting:GetChildren()) do
                    if v:IsA("PostEffect") then
                        v.Enabled = false
                    end
                end
            end)
            notify("FPS Booster", "Graphics optimized!", 2)
        elseif not state and fpsBoosted then
            fpsBoosted = false
            notify("FPS Booster", "Reset (restart game to restore)", 2)
        end
    end

    -- Utility Tab UI
    addSection(pages["Utility"], T("Utility"))

    addCheckbox(pages["Utility"], T("AntiAFK"), "AntiAFK", false, function(state)
        if state then
            startAntiAFK()
            notify("Anti AFK", "Enabled", 2)
        else
            if antiAFKConn then antiAFKConn:Disconnect() end
            notify("Anti AFK", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Utility"], T("FreezeTime"), "FreezeTime", false, function(state)
        if state then
            startFreezeTime()
            notify("Freeze Time", "Enabled", 2)
        else
            if freezeTimeConn then freezeTimeConn:Disconnect() end
            notify("Freeze Time", "Disabled", 2)
        end
    end)

    addCheckbox(pages["Utility"], T("FPSBooster"), "FPSBooster", false, function(state)
        boostFPS(state)
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- SERVER TAB
    -- ═══════════════════════════════════════════════════════════════
    addSection(pages["Server"], T("Server"))

    addButton(pages["Server"], T("RejoinServer"), function()
        notify("Server", "Rejoining...", 2)
        TeleportService:Teleport(game.PlaceId, player)
    end)

    addButton(pages["Server"], T("ServerHop"), function()
        notify("Server", "Finding new server...", 2)
        local success = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local response = game:HttpGet(url)
            local servers = HttpService:JSONDecode(response)
            if servers and servers.data then
                for _, server in ipairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                        return
                    end
                end
            end
        end)
        if not success then
            notify("Server Hop", "Failed - try again", 3)
        end
    end)

    addButton(pages["Server"], T("JoinSmallServer"), function()
        notify("Server", "Finding small server...", 2)
        local success = pcall(function()
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
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, smallest.id, player)
                end
            end
        end)
        if not success then
            notify("Join Small Server", "Failed", 3)
        end
    end)

    -- Player List
    addSection(pages["Server"], T("PlayerList"))
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, 0, 0, 100)
    playerListFrame.BackgroundColor3 = getTheme().rowBg
    playerListFrame.BorderSizePixel = 0
    playerListFrame.LayoutOrder = #pages["Server"]:GetChildren() * 10 + 1
    playerListFrame.ZIndex = 3
    playerListFrame.Parent = pages["Server"]

    local plCorner = Instance.new("UICorner")
    plCorner.CornerRadius = UDim.new(0, 6)
    plCorner.Parent = playerListFrame

    local plScrolling = Instance.new("ScrollingFrame")
    plScrolling.Size = UDim2.new(1, -8, 1, -8)
    plScrolling.Position = UDim2.new(0, 4, 0, 4)
    plScrolling.BackgroundTransparency = 1
    plScrolling.BorderSizePixel = 0
    plScrolling.ScrollBarThickness = 2
    plScrolling.CanvasSize = UDim2.new(0, 0, 0, 500)
    -- ScrollingDirection may not exist on some mobile executors
    pcall(function() plScrolling.ScrollingDirection = Enum.ScrollingDirection.Y end)
    plScrolling.ZIndex = 4
    plScrolling.Parent = playerListFrame

    local plLayout = Instance.new("UIListLayout")
    plLayout.Padding = UDim.new(0, 2)
    plLayout.SortOrder = Enum.SortOrder.LayoutOrder
    plLayout.Parent = plScrolling

    local function updatePlayerList()
        for _, child in pairs(plScrolling:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = getTheme().inputBg
            btn.AutoButtonColor = false
            btn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextColor3 = getTheme().text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = p.UserId
            btn.Parent = plScrolling

            local btnPad = Instance.new("UIPadding")
            btnPad.PaddingLeft = UDim.new(0, 6)
            btnPad.Parent = btn

            btn.MouseButton1Click:Connect(function()
                notify("Player", "Selected: " .. p.DisplayName, 2)
                _G.SelectedPlayer = p
            end)

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = getTheme().accent
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = getTheme().inputBg
                btn.TextColor3 = getTheme().text
            end)
        end

        -- Manually update canvas size for mobile compatibility
        pcall(function()
            plScrolling.CanvasSize = UDim2.new(0, 0, 0, count * 24 + 4)
        end)
    end

    updatePlayerList()
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)

    -- Spectate
    addSection(pages["Server"], T("SpectatePlayer"))
    addButton(pages["Server"], T("SpectateSelected"), function()
        if _G.SelectedPlayer and _G.SelectedPlayer.Character then
            local hum = _G.SelectedPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                camera.CameraSubject = hum
                notify("Spectate", "Now spectating " .. _G.SelectedPlayer.DisplayName, 2)
            end
        else
            notify("Spectate", "No player selected!", 2)
        end
    end)

    addButton(pages["Server"], T("StopSpectating"), function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                camera.CameraSubject = hum
                notify("Spectate", "Stopped", 2)
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- FUN TAB
    -- ═══════════════════════════════════════════════════════════════
    local spinConn = nil
    local floatConn = nil
    local bangConn = nil
    local flingConn = nil
    local orbitConn = nil

    addSection(pages["Fun"], T("Fun"))

    addCheckbox(pages["Fun"], T("Spin"), "Spin", false, function(state)
        if state then
            if spinConn then spinConn:Disconnect() end
            spinConn = RunService.RenderStepped:Connect(function()
                if not States.Spin then return end
                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Values.SpinSpeed * 0.1), 0)
                end
            end)
            notify("Spin", "Spinning!", 2)
        else
            if spinConn then spinConn:Disconnect() end
            notify("Spin", "Stopped", 2)
        end
    end)
    addSlider(pages["Fun"], T("SpinSpeed"), "SpinSpeed", 10, 200, 50)

    addCheckbox(pages["Fun"], T("Float"), "Float", false, function(state)
        if state then
            if floatConn then floatConn:Disconnect() end
            floatConn = RunService.RenderStepped:Connect(function()
                if not States.Float then return end
                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + math.sin(tick() * 2) * 0.5, hrp.Position.Z)
                end
            end)
            notify("Float", "Floating!", 2)
        else
            if floatConn then floatConn:Disconnect() end
            notify("Float", "Stopped", 2)
        end
    end)

    addCheckbox(pages["Fun"], T("Bang"), "Bang", false, function(state)
        if state then
            if bangConn then bangConn:Disconnect() end
            bangConn = RunService.RenderStepped:Connect(function()
                if not States.Bang then return end
                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, math.sin(tick() * 10) * 0.3, 0)
                end
            end)
            notify("Bang", "Banging!", 2)
        else
            if bangConn then bangConn:Disconnect() end
            notify("Bang", "Stopped", 2)
        end
    end)

    addCheckbox(pages["Fun"], T("Fling"), "Fling", false, function(state)
        if state then
            if flingConn then flingConn:Disconnect() end
            flingConn = RunService.RenderStepped:Connect(function()
                if not States.Fling then return end
                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(math.random(-500, 500), math.random(0, 500), math.random(-500, 500))
                end
            end)
            notify("Fling", "Flinging!", 2)
        else
            if flingConn then flingConn:Disconnect() end
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
            end
            notify("Fling", "Stopped", 2)
        end
    end)

    addCheckbox(pages["Fun"], T("OrbitPlayer"), "OrbitPlayer", false, function(state)
        if state then
            if not _G.SelectedPlayer then
                notify("Orbit", "Select a player first!", 2)
                States.OrbitPlayer = false
                return
            end
            if orbitConn then orbitConn:Disconnect() end
            local angle = 0
            orbitConn = RunService.RenderStepped:Connect(function()
                if not States.OrbitPlayer then return end
                local char = player.Character
                local targetChar = _G.SelectedPlayer and _G.SelectedPlayer.Character
                if not char or not targetChar then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                if not hrp or not targetHrp then return end

                angle = angle + math.rad(Values.OrbitSpeed * 0.05)
                local offset = Vector3.new(math.cos(angle) * Values.OrbitRadius, 0, math.sin(angle) * Values.OrbitRadius)
                hrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
            end)
            notify("Orbit", "Orbiting " .. _G.SelectedPlayer.DisplayName, 2)
        else
            if orbitConn then orbitConn:Disconnect() end
            notify("Orbit", "Stopped", 2)
        end
    end)
    addSlider(pages["Fun"], T("OrbitRadius"), "OrbitRadius", 5, 50, 10)
    addSlider(pages["Fun"], T("OrbitSpeed"), "OrbitSpeed", 10, 200, 50)

    addCheckbox(pages["Fun"], T("Invisible"), "Invisible", false, function(state)
        local char = player.Character
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = state and 1 or 0
            end
            if part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = state and 1 or 0
            end
        end
        notify("Invisible", state and "You are invisible!" or "Visible again", 2)
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- SETTINGS TAB
    -- ═══════════════════════════════════════════════════════════════
    addSection(pages["Settings"], T("Theme"))

    addDropdown(pages["Settings"], T("SelectTheme"), {"Dark", "Light", "Sky Blue", "Galaxy"}, currentTheme, function(selected)
        currentTheme = selected
        local theme = getTheme()

        mainFrame.BackgroundColor3 = theme.bg
        titleBar.BackgroundColor3 = theme.bg
        tabContainer.BackgroundColor3 = theme.sidebar

        for _, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = theme.tabInactive
            btn.TextColor3 = theme.textDim
            local border = btn:FindFirstChild("ActiveBorder")
            if border then
                border.BackgroundColor3 = theme.accent
            end
        end

        for _, elem in ipairs(allUIElements) do
            if elem.type == "section" then
                elem.obj.TextColor3 = theme.textHeader
            elseif elem.type == "checkbox" then
                elem.bg.BackgroundColor3 = theme.checkboxBg
                elem.check.BackgroundColor3 = theme.checkboxCheck
                elem.label.TextColor3 = theme.text
            elseif elem.type == "slider" then
                elem.track.BackgroundColor3 = theme.sliderTrack
                elem.fill.BackgroundColor3 = theme.sliderFill
                elem.label.TextColor3 = theme.text
            elseif elem.type == "button" then
                elem.obj.BackgroundColor3 = theme.accent
            elseif elem.type == "inforow" then
                elem.label.TextColor3 = theme.textDim
                elem.value.TextColor3 = theme.text
            elseif elem.type == "dropdown" then
                elem.btn.BackgroundColor3 = theme.inputBg
                elem.btn.TextColor3 = theme.text
                elem.label.TextColor3 = theme.text
            end
        end

        playerListFrame.BackgroundColor3 = theme.rowBg

        notify("Theme", "Changed to " .. selected, 2)
    end)

    addSection(pages["Settings"], T("Language"))

    addDropdown(pages["Settings"], T("SelectLanguage"), {"English", "Tiếng Việt", "Español", "Português", "Русский"}, currentLang, function(selected)
        currentLang = selected

        for name, btn in pairs(tabButtons) do
            btn.Text = " " .. (tabIcons[name] or "•") .. " " .. T(name)
        end

        notify("Language", "Changed to " .. selected, 2)
    end)

    addSection(pages["Settings"], T("GUI"))

    addButton(pages["Settings"], T("SaveSettings"), function()
        local settings = {
            states = {},
            values = Values,
            theme = currentTheme,
            language = currentLang,
        }
        for k, v in pairs(States) do
            if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                settings.states[k] = v
            end
        end

        local success = pcall(function()
            writefile("FLUYEN_settings.json", HttpService:JSONEncode(settings))
        end)

        if success then
            notify("Save Settings", "Settings saved!", 2)
        else
            notify("Save Settings", "Failed to save", 2)
        end
    end)

    addCheckbox(pages["Settings"], T("AutoLoadSettings"), "AutoLoadSettings", false)

    addButton(pages["Settings"], T("ResetSettings"), function()
        for k, v in pairs(States) do
            if type(v) == "boolean" then
                States[k] = false
            end
        end
        Values.SpeedValue = 50
        Values.JumpPowerValue = 100
        notify("Reset", "All settings reset!", 2)
    end)

    addCheckbox(pages["Settings"], T("MinimizeButton"), "MinimizeButton", true)
    addCheckbox(pages["Settings"], T("DraggableGUI"), "DraggableGUI", true)
    addCheckbox(pages["Settings"], T("Notifications"), "Notifications", true)

    addInfoRow(pages["Settings"], T("ToggleKeybind"), "3-Finger Tap x3")

    -- ═══════════════════════════════════════════════════════════════
    -- DRAGGABLE GUI
    -- ═══════════════════════════════════════════════════════════════
    local dragging = false
    local dragStart = nil
    local startPos = nil

    titleBar.InputBegan:Connect(function(input)
        if not States.DraggableGUI then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
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

    -- ═══════════════════════════════════════════════════════════════
    -- MINIMIZE BUTTON (Floating)
    -- ═══════════════════════════════════════════════════════════════
    local miniBtn = Instance.new("TextButton")
    miniBtn.Name = "MinimizeBtn"
    miniBtn.Size = UDim2.new(0, 40, 0, 40)
    miniBtn.Position = UDim2.new(0, 20, 0, 20)
    miniBtn.BackgroundColor3 = getTheme().accent
    miniBtn.Text = "F"
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.TextSize = 18
    miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    miniBtn.AutoButtonColor = false
    miniBtn.Visible = false
    miniBtn.Parent = screenGui

    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(1, 0)
    miniCorner.Parent = miniBtn

    -- ═══════════════════════════════════════════════════════════════
    -- OPEN / CLOSE ANIMATIONS (Moved BEFORE Minimize Button so toggleMenu exists)
    -- ═══════════════════════════════════════════════════════════════
    local isOpen = false
    local isAnimating = false

    local OPEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local CLOSE_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local FADE_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    local function openMenu()
        if isOpen or isAnimating then return end
        isAnimating = true
        isOpen = true

        -- Recalculate page sizes before showing (mainFrame still hidden, recalc will handle this)
        recalcAllPages()

        mainFrame.Visible = true
        backdrop.Visible = true
        backdrop.BackgroundTransparency = 1
        miniBtn.Visible = false

        -- Scale animation (if UIScale is supported)
        if uiScale then
            uiScale.Scale = 0.5
            TweenService:Create(uiScale, OPEN_INFO, {Scale = 1}):Play()
        end
        TweenService:Create(backdrop, FADE_INFO, {BackgroundTransparency = 0.5}):Play()

        _delay(OPEN_INFO.Time, function()
            if uiScale then uiScale.Scale = 1 end
            isAnimating = false
            -- Force a second recalculation after menu is fully visible and scaled
            -- This ensures content is properly laid out on mobile executors
            recalcAllPages()
        end)
    end

    local function closeMenu()
        if not isOpen or isAnimating then return end
        isAnimating = true
        isOpen = false

        if uiScale then
            local tween = TweenService:Create(uiScale, CLOSE_INFO, {Scale = 0.5})
            TweenService:Create(backdrop, CLOSE_INFO, {BackgroundTransparency = 1}):Play()
            tween:Play()
            tween.Completed:Connect(function()
                uiScale.Scale = 1
                mainFrame.Visible = false
                backdrop.Visible = false
                isAnimating = false
                if States.MinimizeButton then
                    miniBtn.Visible = true
                end
            end)
        else
            -- No UIScale support, just hide immediately
            TweenService:Create(backdrop, CLOSE_INFO, {BackgroundTransparency = 1}):Play()
            mainFrame.Visible = false
            backdrop.Visible = false
            isAnimating = false
            if States.MinimizeButton then
                miniBtn.Visible = true
            end
        end
    end

    local function toggleMenu()
        if isOpen then
            closeMenu()
        else
            openMenu()
        end
    end

    miniBtn.MouseButton1Click:Connect(function()
        toggleMenu()
    end)

    backdropClose.MouseButton1Click:Connect(closeMenu)
    closeBtn.MouseButton1Click:Connect(closeMenu)

    -- ═══════════════════════════════════════════════════════════════
    -- GESTURE: 3 FINGERS x 3 TAPS (FIXED)
    -- ═══════════════════════════════════════════════════════════════
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

        if now - lastTapTime > TAP_WINDOW then
            tapCount = 0
        end

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

    UserInputService.TouchEnded:Connect(function(touch, _gameProcessedEvent)
        if activeTouches[touch] then
            activeTouches[touch] = nil
            activeCount = math.max(0, activeCount - 1)
        end

        if activeCount < REQUIRED_FINGERS then
            reachedRequired = false
        end
    end)

    -- Keyboard toggle (Insert key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            toggleMenu()
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- AUTO LOAD SETTINGS
    -- ═══════════════════════════════════════════════════════════════
    _spawn(function()
        _wait(2)
        local success, data = pcall(function()
            return readfile("FLUYEN_settings.json")
        end)

        if success and data then
            local settings = HttpService:JSONDecode(data)
            if settings then
                if settings.theme then
                    currentTheme = settings.theme
                end
                if settings.language then
                    currentLang = settings.language
                end
                if settings.values then
                    for k, v in pairs(settings.values) do
                        Values[k] = v
                    end
                end
                if States.AutoLoadSettings and settings.states then
                    for k, v in pairs(settings.states) do
                        States[k] = v
                    end
                end
                notify("Auto Load", "Settings loaded!", 2)
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- RECALCULATE ALL PAGE SIZES (Fix for mobile executors)
    -- ═══════════════════════════════════════════════════════════════
    recalcAllPages()

    -- Second recalculation after a longer delay to ensure layout is fully computed on mobile executors
    _delay(2, function()
        recalcAllPages()
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- INITIAL NOTIFICATION
    -- ═══════════════════════════════════════════════════════════════
    _spawn(function()
        _wait(1)
        notify(SCRIPT_NAME, SCRIPT_VERSION .. " loaded! 3-finger tap x3 to open", 4)
    end)

    -- ═══════════════════════════════════════════════════════════════
    -- ANTI-AFK (built-in)
    -- ═══════════════════════════════════════════════════════════════
    player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)



end)

-- Error handler: if the script crashed, print the error so we know what happened
if not _scriptOk then
    warn('[FLUYEN] Script error: ' .. tostring(_scriptErr))
    -- Try to show a basic notification so user knows something happened
    pcall(function()
        local pg = game:GetService('Players').LocalPlayer:FindFirstChild('PlayerGui')
        if pg then
            local sg = Instance.new('ScreenGui')
            sg.Name = 'FLUYEN_Error'
            sg.Parent = pg
            local tl = Instance.new('TextLabel')
            tl.Size = UDim2.new(0.5, 0, 0, 50)
            tl.Position = UDim2.new(0.25, 0, 0.1, 0)
            tl.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            tl.TextColor3 = Color3.fromRGB(255, 255, 255)
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 14
            tl.TextWrapped = true
            tl.Text = '[FLUYEN Error] ' .. tostring(_scriptErr)
            tl.Parent = sg
            local cn = Instance.new('UICorner')
            cn.CornerRadius = UDim.new(0, 6)
            cn.Parent = tl
        end
    end)
else
    print('[FLUYEN] Script loaded successfully!')
end