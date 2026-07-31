-- Fruit Notifier | Blox Fruits | by Warniy
-- Уведомления о спавне фруктов + ESP + полёт к фрукту + лёгкое GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ================= ACCESS SYSTEM 🔒 =================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1532684652328784054/LUuB2sSQJVjjuSI_-spyhzzHEfn7NBphZRI3CO2vuk6GvK46-HU4muswb_qcR5PgvE1X"
local JSONBIN_URL = "https://api.jsonbin.io/v3/b/6a6cabe9f5f4af5e29da249b/latest"
local JSONBIN_KEY = "$2a$10$dbP7YG3B4TvIMdme.V1z4Ol7w0AnFIwEUXbc6.G8itIVs2AV.lhAO"
local ACCESS_GRANTED = false
local AUTH_CACHE_FILE = "fruit_notifier_auth.json"
local AUTH_CACHE_TTL = 5400

local function SaveAuth(key)
    local data = { key = key, time = os.time(), hwid = "" }
    pcall(function() data.hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
    pcall(function() writefile(AUTH_CACHE_FILE, HttpService:JSONEncode(data)) end)
end

local function LoadAuth()
    local content = nil
    pcall(function() content = readfile(AUTH_CACHE_FILE) end)
    if not content then return nil, 0 end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok or type(data) ~= "table" then return nil, 0 end
    local elapsed = os.time() - (data.time or 0)
    if elapsed > AUTH_CACHE_TTL then
        pcall(function() delfile(AUTH_CACHE_FILE) end)
        return nil, 0
    end
    local hwid = ""
    pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
    if data.hwid ~= hwid then
        pcall(function() delfile(AUTH_CACHE_FILE) end)
        return nil, 0
    end
    return data.key, AUTH_CACHE_TTL - elapsed
end

local function ClearAuth()
    pcall(function() delfile(AUTH_CACHE_FILE) end)
end

local function SendToWebhook(message)
    local jsonBody = HttpService:JSONEncode({ content = message })
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    if reqFn then
        pcall(function()
            reqFn({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonBody })
        end)
    else
        pcall(function() game:HttpPost(WEBHOOK_URL, jsonBody, true, { ["Content-Type"] = "application/json" }) end)
    end
end

local function FetchKeys()
    local keysData = {}
    local body = nil

    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    if reqFn then
        local ok, res = pcall(function()
            return reqFn({ Url = JSONBIN_URL, Method = "GET", Headers = { ["Accept"] = "application/json", ["X-Master-Key"] = JSONBIN_KEY } })
        end)
        if ok and res and res.Body then body = res.Body end
    end
    if not body then
        pcall(function()
            local req2 = (syn and syn.request) or (http and http.request) or http_request or request
            if req2 then
                local r2 = req2({ Url = JSONBIN_URL, Method = "GET", Headers = { ["X-Master-Key"] = JSONBIN_KEY } })
                if r2 and r2.Body then body = r2.Body end
            end
        end)
    end

    if body then
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok and type(data) == "table" then
            local record = data.record or data
            if type(record) == "table" and record.record then
                record = record.record
            end
            if type(record) == "table" then
                for _, entry in ipairs(record) do
                    if type(entry) == "table" and entry.key and entry.username then
                        keysData[string.upper(entry.key)] = string.lower(entry.username)
                    end
                end
            end
        end
    end
    return keysData
end

local function ShowAccessDenied()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AccessDenied"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    overlay.BackgroundTransparency = 0.15
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 380, 0, 180)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel = 0
    main.Parent = overlay
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Transparency = 0.2
    stroke.Parent = main

    local redLine = Instance.new("Frame")
    redLine.Size = UDim2.new(1, 0, 0, 3)
    redLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    redLine.BorderSizePixel = 0
    redLine.Parent = main

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 50)
    icon.Position = UDim2.new(0, 0, 0, 25)
    icon.BackgroundTransparency = 1
    icon.Text = "X"
    icon.TextColor3 = Color3.fromRGB(255, 50, 50)
    icon.TextSize = 40
    icon.Font = Enum.Font.GothamBold
    icon.Parent = main

    local denyTitle = Instance.new("TextLabel")
    denyTitle.Size = UDim2.new(1, -30, 0, 30)
    denyTitle.Position = UDim2.new(0, 15, 0, 80)
    denyTitle.BackgroundTransparency = 1
    denyTitle.Text = "ACCESS DENIED"
    denyTitle.TextColor3 = Color3.fromRGB(255, 60, 60)
    denyTitle.TextSize = 22
    denyTitle.Font = Enum.Font.GothamBold
    denyTitle.Parent = main

    local denyMsg = Instance.new("TextLabel")
    denyMsg.Size = UDim2.new(1, -30, 0, 40)
    denyMsg.Position = UDim2.new(0, 15, 0, 115)
    denyMsg.BackgroundTransparency = 1
    denyMsg.Text = "У тебя нет доступа к этому скрипту.\nОбратись к владельцу за доступом."
    denyMsg.TextColor3 = Color3.fromRGB(140, 140, 155)
    denyMsg.TextSize = 12
    denyMsg.Font = Enum.Font.Gotham
    denyMsg.Parent = main

    return gui
end

local function ShowAuthGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AccessSystem"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 220)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    main.BorderSizePixel = 0
    main.Parent = overlay
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(72, 209, 224)
    s.Transparency = 0.3
    s.Parent = main

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = Color3.fromRGB(72, 209, 224)
    accent.BorderSizePixel = 0
    accent.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 36)
    title.Position = UDim2.new(0, 15, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "FRUIT NOTIFIER"
    title.TextColor3 = Color3.fromRGB(225, 225, 232)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -30, 0, 18)
    sub.Position = UDim2.new(0, 15, 0, 50)
    sub.BackgroundTransparency = 1
    sub.Text = "Введи ключ для доступа"
    sub.TextColor3 = Color3.fromRGB(140, 140, 155)
    sub.TextSize = 12
    sub.Font = Enum.Font.Gotham
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = main

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -30, 0, 38)
    inputBg.Position = UDim2.new(0, 15, 0, 78)
    inputBg.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    inputBg.BorderSizePixel = 0
    inputBg.Parent = main
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(55, 55, 65)
    inputStroke.Parent = inputBg

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 1, 0)
    input.Position = UDim2.new(0, 8, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "FRUIT-XXXX-XXXX-XXXX"
    input.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
    input.TextColor3 = Color3.fromRGB(225, 225, 232)
    input.TextSize = 14
    input.Font = Enum.Font.GothamMedium
    input.ClearTextOnFocus = false
    input.Parent = inputBg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 38)
    btn.Position = UDim2.new(0, 15, 0, 128)
    btn.BackgroundColor3 = Color3.fromRGB(72, 209, 224)
    btn.BorderSizePixel = 0
    btn.Text = "Проверить"
    btn.TextColor3 = Color3.fromRGB(12, 12, 16)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -30, 0, 20)
    status.Position = UDim2.new(0, 15, 0, 176)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.Parent = main

    return gui, input, btn, status
end

local AccessEvent = Instance.new("BindableEvent")

pcall(function()
    local savedKey, remainingSec = LoadAuth()
    if savedKey then
        local keysData = FetchKeys()
        if next(keysData) ~= nil then
            local upperKey = string.upper(savedKey)
            local boundUsername = keysData[upperKey]
            if boundUsername and boundUsername == string.lower(LocalPlayer.Name) then
                ACCESS_GRANTED = true
                local remMin = math.floor(remainingSec / 60)
                local remSec = remainingSec % 60
                local timeStr = remMin > 0 and (remMin .. "м " .. remSec .. "с") or (remSec .. "с")
                pcall(function()
                    local hwid = ""
                    pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
                    SendToWebhook("** Fruit Notifier | Автологин **\n> Ник: `" .. LocalPlayer.Name .. "`\n> HWID: " .. tostring(hwid) .. "\n> Осталось: **" .. timeStr .. "**")
                end)
                AccessEvent:Fire()
            else
                ClearAuth()
            end
        else
            ClearAuth()
        end
    end
end)

if not ACCESS_GRANTED then
local AuthGui, AuthInput, AuthBtn, AuthStatus = ShowAuthGui()

AuthBtn.MouseButton1Click:Connect(function()
    local inputKey = AuthInput.Text
    if inputKey == "" then
        AuthStatus.Text = "Введи ключ"
        AuthStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    AuthBtn.Text = "Проверка..."
    AuthBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

    local keysData = FetchKeys()

    if next(keysData) == nil then
        AuthStatus.Text = "Ошибка загрузки. Повтори позже."
        AuthStatus.TextColor3 = Color3.fromRGB(255, 180, 50)
        AuthBtn.Text = "Проверить"
        AuthBtn.BackgroundColor3 = Color3.fromRGB(72, 209, 224)
        return
    end

    task.delay(0.3, function()
        local upperKey = string.upper(string.gsub(inputKey, "%s+", ""))
        local boundUsername = keysData[upperKey]

        if not boundUsername then
            AuthStatus.Text = "Неверный ключ!"
            AuthStatus.TextColor3 = Color3.fromRGB(255, 60, 60)
            AuthBtn.Text = "Проверить"
            AuthBtn.BackgroundColor3 = Color3.fromRGB(72, 209, 224)
            return
        end

        local realName = string.lower(LocalPlayer.Name)
        if boundUsername ~= realName then
            AuthStatus.Text = "Ключ привязан к другому нику!"
            AuthStatus.TextColor3 = Color3.fromRGB(255, 60, 60)
            AuthBtn.Text = "Проверить"
            AuthBtn.BackgroundColor3 = Color3.fromRGB(72, 209, 224)
            ShowAccessDenied()
            pcall(function()
                local hwid = ""
                pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
                SendToWebhook("** Fruit Notifier | Чужой аккаунт **\n> Ключ: ||" .. upperKey .. "||\n> Привязан к: `" .. boundUsername .. "`\n> Пытался: `" .. LocalPlayer.Name .. "`\n> HWID: " .. tostring(hwid))
            end)
            return
        end

        ACCESS_GRANTED = true
        SaveAuth(inputKey)
        AuthStatus.Text = "Добро пожаловать, " .. LocalPlayer.Name .. "!"
        AuthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        pcall(function()
            local hwid = ""
            pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
            SendToWebhook("** Fruit Notifier | Доступ выдан **\n> Ник: `" .. LocalPlayer.Name .. "`\n> HWID: " .. tostring(hwid))
        end)
        task.delay(0.8, function()
            AuthGui:Destroy()
            AccessEvent:Fire()
        end)
    end)
end)

AccessEvent.Event:Wait()
end
-- ================= ACCESS SYSTEM END 🔒 =================

-- ================= НАСТРОЙКИ =================
local Settings = {
    Notifications = true,   -- уведомление при спавне фрукта
    NotifySound = true,     -- звук уведомления
    NotifySoundId = 1,      -- индекс звука (1-5)
    MusicEnabled = false,   -- фоновая музыка
    MusicId = 1,            -- индекс музыки
    FruitESP = true,        -- ESP на фрукты (имя + дистанция)
    TracerLines = true,     -- линия от низа экрана к фрукту
    AutoTeleport = false,   -- 🛫 авто-полёт к фрукту
    AutoStore = true,       -- 🎒 авто-стор подобранных фруктов
    MaxStoreFruits = 2,     -- 🎒 макс. фруктов в стор (регулируется ползунком в GUI)
    DropIfFull = true,      -- 🌊 выбрасывать фрукт в море, если стор полон
    AutoRoll = false,       -- 🎰 авто-ролл (гача) случайного фрукта — тратит бели!
    RollInterval = 5,       -- 🎰 пауза между роллами (сек)
    FlyToSea = true,        -- ✈️ true = лететь к морю, если дальше 550 studs; false = всегда телепорт
    TweenSpeed = 300,       -- скорость полёта (studs/сек)
    ScanInterval = 3,       -- частота сканирования (сек)
    SilentAim = false,      -- 🎯 сайлент-аим на ближайшего игрока (макс AimRange studs, 360°)
    AimRange = 500,         -- 🎯 макс. дистанция таргета сайлент-аима (studs)
    AntiStun = false,       -- 🛡️ анти-стан (сброс стана/обнуления скорости)
    AutoRespawn = false,    -- 💀 авто-респавн после смерти
    AimHighlight = true,    -- 🟢 зелёное поле вокруг цели Silent Aim
    AimTracer = true,       -- 🔴 красный трейсер к цели Silent Aim
    DebugMode = false,      -- 🐞 режим отладки (вывод дополнительной информации)
    ESPColor = Color3.fromRGB(255, 170, 0),
    TextSize = 14,
}
-- =============================================

local SoundList = {
    { Name = "Уведомление", Id = "4590662766" },
    { Name = "Динь", Id = "6042053626" },
    { Name = "Классика", Id = "130787889" },
    { Name = "Приятный", Id = "6518811692" },
    { Name = "Роблокс", Id = "5766244233" },
    { Name = "Secret", Id = "73962744404254" },
    { Name = "Warniy", Id = "82951257906837" },
    { Name = "WarniyPRIME", Id = "93923991230215" },
}

local MusicList = {
    { Name = "Гимн Украины", Id = "1837478410" },
    { Name = "Гимн Украины (v2)", Id = "494399831" },
}

local MusicSound = nil

local TrackedFruits = {}
local SeenFruits = {}

-- Уведомление
local function Notify(title, text, duration)
    if not Settings.Notifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 6,
        })
    end)
    if Settings.NotifySound then
        pcall(function()
            local s = Instance.new("Sound", Workspace)
            local soundData = SoundList[Settings.NotifySoundId] or SoundList[1]
            s.SoundId = "rbxassetid://" .. soundData.Id
            s.Volume = 2
            s:Play()
            game:GetService("Debris"):AddItem(s, 3)
        end)
    end
end

local function StartMusic()
    if MusicSound then return end
    local musicData = MusicList[Settings.MusicId] or MusicList[1]
    MusicSound = Instance.new("Sound")
    MusicSound.SoundId = "rbxassetid://" .. musicData.Id
    MusicSound.Volume = 0.5
    MusicSound.Looped = true
    MusicSound.Parent = Workspace
    MusicSound:Play()
end

local function StopMusic()
    if MusicSound then
        MusicSound:Stop()
        MusicSound:Destroy()
        MusicSound = nil
    end
end

local function ToggleMusic()
    if Settings.MusicEnabled then
        StartMusic()
    else
        StopMusic()
    end
end

local function ChangeMusic()
    StopMusic()
    if Settings.MusicEnabled then
        StartMusic()
    end
end

-- ============ КОНФИГ 💾 ============
-- Сохранение/загрузка настроек в файл (writefile/readfile — есть почти во всех эксплойтах)
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "FruitNotifier_Warniy.json"

local CurrentTheme = 1 -- индекс выбранной темы (см. ThemeColors в GUI)

local DefaultSettings = {} -- копия дефолтов для ресета
for k, v in pairs(Settings) do DefaultSettings[k] = v end

local function SaveConfig()
    if not writefile then
        Notify("💾 Конфиг", "Эксплойт не поддерживает writefile 😕", 5)
        return
    end
    local data = { Theme = CurrentTheme }
    for k, v in pairs(Settings) do
        if type(v) == "boolean" or type(v) == "number" then
            data[k] = v -- Color3 и прочее не сериализуем
        end
    end
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
    Notify("💾 Конфиг", ok and "Конфиг сохранён!" or "Не удалось сохранить конфиг", 4)
end

local function LoadConfig()
    if not (isfile and readfile) then return end
    local ok, data = pcall(function()
        if not isfile(CONFIG_FILE) then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if k == "Theme" and type(v) == "number" then
            CurrentTheme = v
        elseif Settings[k] ~= nil and type(Settings[k]) == type(v) then
            Settings[k] = v
        end
    end
end

local function ResetConfig()
    for k, v in pairs(DefaultSettings) do
        Settings[k] = v
    end
    CurrentTheme = 1
    pcall(function()
        if delfile and isfile and isfile(CONFIG_FILE) then
            delfile(CONFIG_FILE)
        end
    end)
    Notify("🔄 Конфиг", "Сброшено до настроек по умолчанию", 4)
end

LoadConfig() -- подхватываем сохранённый конфиг при запуске
if Settings.MusicEnabled then ToggleMusic() end
-- ===================================

-- Проверка: является ли объект фруктом
local function IsFruit(obj)
    if not obj:IsA("Tool") and not obj:IsA("Model") then return false end
    if obj.Name:find("Fruit") and obj:FindFirstChild("Handle") then
        local parent = obj.Parent
        if parent and Players:GetPlayerFromCharacter(parent) then
            return false
        end
        return true
    end
    return false
end

local function GetFruitPosition(fruit)
    local handle = fruit:FindFirstChild("Handle")
    if handle then return handle.Position end
    if fruit:IsA("Model") and fruit.PrimaryPart then
        return fruit.PrimaryPart.Position
    end
    return nil
end

-- Ближайший фрукт к персонажу
local function GetNearestFruit()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, nearestDist = nil, math.huge
    for fruit in pairs(SeenFruits) do
        if fruit.Parent then
            local pos = GetFruitPosition(fruit)
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < nearestDist then
                    nearest, nearestDist = fruit, d
                end
            end
        end
    end
    return nearest
end

local function CreateFruitESP(fruit)
    if TrackedFruits[fruit] then return end

    local bg = Drawing.new("Square")
    bg.Visible = false
    bg.Filled = true
    bg.Color = Color3.fromRGB(12, 12, 16)
    bg.Transparency = 0.65
    bg.Thickness = 0

    local border = Drawing.new("Square")
    border.Visible = false
    border.Filled = false
    border.Color = Color3.fromRGB(255, 255, 255)
    border.Thickness = 1
    border.Transparency = 0.8

    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Size = Settings.TextSize
    text.Color = Settings.ESPColor
    text.Font = 2

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1.5
    tracer.Color = Settings.ESPColor

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ESPColor
    highlight.FillTransparency = 0.85
    highlight.OutlineColor = Settings.ESPColor
    highlight.OutlineTransparency = 0.0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = fruit
    pcall(function() highlight.Parent = gui end)

    TrackedFruits[fruit] = { Text = text, Bg = bg, Border = border, Tracer = tracer, Highlight = highlight }
end

local function RemoveFruitESP(fruit)
    local obj = TrackedFruits[fruit]
    if obj then
        obj.Text:Remove()
        obj.Bg:Remove()
        obj.Border:Remove()
        obj.Tracer:Remove()
        if obj.Highlight then pcall(function() obj.Highlight:Destroy() end) end
        TrackedFruits[fruit] = nil
    end
end

-- ============ ПОЛЁТ К ФРУКТУ ============
-- Без TweenService: двигаем HRP вручную каждый кадр (Heartbeat).
-- Твины на персонаже часто глушатся физикой/античитом — поэтому «не летело».
local IsFlying = false
local FlightId = 0
local OnFlightStateChanged = nil -- колбэк для GUI

local function SetFlying(state)
    IsFlying = state
    if OnFlightStateChanged then
        pcall(OnFlightStateChanged, state)
    end
end

local function StopTween()
    FlightId = FlightId + 1 -- обрывает активный цикл полёта
    SetFlying(false)
end

local function TeleportToFruit(fruit)
    StopTween() -- отменяем предыдущий полёт, если был

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local startPos = GetFruitPosition(fruit)
    if not startPos then return end

    FlightId = FlightId + 1
    local myId = FlightId
    SetFlying(true)
    Notify("🍈 Fruit Notifier", ("Лечу к фрукту: %s (%d studs)"):format(fruit.Name, math.floor((hrp.Position - startPos).Magnitude)), 4)

    task.spawn(function()
        while IsFlying and FlightId == myId do
            local dt = RunService.Heartbeat:Wait()

            -- перечитываем персонажа (мог умереть/зареспавниться)
            char = LocalPlayer.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hrp or not hum or hum.Health <= 0 then break end

            -- фрукт пропал по дороге (кто-то подобрал)
            if not fruit.Parent then
                Notify("🍈 Fruit Notifier", "Фрукт пропал по дороге 😢", 4)
                break
            end

            local fruitPos = GetFruitPosition(fruit)
            if not fruitPos then break end
            local targetPos = fruitPos + Vector3.new(0, 3, 0)
            local delta = targetPos - hrp.Position
            local dist = delta.Magnitude

            -- прибыли
            if dist < 4 then
                Notify("🍈 Fruit Notifier", ("Прибыл к фрукту: %s"):format(fruit.Name), 4)
                -- подбираем фрукт тачем по Handle (если эксплойт умеет firetouchinterest)
                local handle = fruit:FindFirstChild("Handle")
                if handle and firetouchinterest then
                    firetouchinterest(hrp, handle, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, handle, 1)
                end
                break
            end

            -- ноуклип + отключаем физику персонажа, чтобы её не мотало
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            hum:ChangeState(Enum.HumanoidStateType.Physics)

            -- шаг с постоянной скоростью TweenSpeed studs/сек
            local step = math.min(Settings.TweenSpeed * dt, dist)
            local newPos = hrp.Position + delta.Unit * step
            local flat = Vector3.new(delta.X, 0, delta.Z)
            if flat.Magnitude > 0.1 then
                hrp.CFrame = CFrame.new(newPos, newPos + flat.Unit) -- смотрим по направлению полёта
            else
                hrp.CFrame = CFrame.new(newPos) * hrp.CFrame.Rotation
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end

        -- вернуть нормальное состояние персонажа
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if FlightId == myId then
            StopTween()
        end
    end)
end

-- ============ AUTO STORE ============
-- Автоматически убирает фрукты из инвентаря в стор через ремоут StoreFruit

local function IsFruitTool(tool)
    return tool:IsA("Tool") and tool.Name:find("Fruit") ~= nil
end

local StoreAttempts = {} -- [tool] = число попыток
local NextTryAt = {}     -- [tool] = время следующей попытки (пауза после серии неудач)
local StoredCount = 0    -- сколько фруктов скрипт уже убрал в стор за сессию

-- Успех проверяем по факту: после стора тул уничтожается (tool.Parent == nil).
-- Сервер в разных билдах ждёт разное имя фрукта — перебираем все варианты:
-- "Rocket Fruit" (как в туле), "Rocket" (без суффикса), "Rocket-Rocket" (старый формат).
local function GetNameVariants(tool)
    local n = tool.Name
    local variants = { n }
    local short = n:gsub(" Fruit$", "")
    if short ~= n then table.insert(variants, short) end
    table.insert(variants, short .. "-" .. short)             -- старый формат "Rocket-Rocket"
    table.insert(variants, short .. "-" .. short .. " Fruit") -- "Rocket-Rocket Fruit"
    return variants
end

local function InvokeStore(name, tool)
    local ret
    pcall(function()
        ret = ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", name, tool)
    end)
    if ret ~= nil then
        -- ответ сервера виден в консоли (F9) — помогает понять причину отказа
        print(("[Fruit Notifier] StoreFruit('%s') -> "):format(name), ret)
    end
    task.wait(0.3)
    return not tool.Parent
end

local function TryStoreRemote(tool)
    -- вариант 1: тул из рюкзака/рук как есть, перебор имён
    for _, name in ipairs(GetNameVariants(tool)) do
        if InvokeStore(name, tool) then return true end
    end

    -- вариант 2: сначала экипировать фрукт в руки — часто сервер принимает только экипированный тул
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        local equipped = char:FindFirstChild(tool.Name) or tool
        for _, name in ipairs(GetNameVariants(equipped)) do
            if InvokeStore(name, equipped) then return true end
        end
        pcall(function() hum:UnequipTools() end) -- убираем обратно в рюкзак
    end
    return not tool.Parent
end

-- ============ ВЫБРОС В МОРЕ 🌊 ============
-- Отдельная функция: если стор полон — выбрасываем фрукт в море (фрукты в воде исчезают).

-- Ищем точку ГАРАНТИРОВАННО над водой: перебираем 8 направлений и дистанции
-- от 400 до 1200 studs и рейкастом вниз проверяем, что под точкой ИМЕННО вода (Terrain Water),
-- а не берег или крыша острова.
local function FindSeaPosition(fromPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.IgnoreWater = false -- вода должна ловиться рейкастом

    for dist = 400, 1200, 200 do -- пробуем всё дальше от острова
        for angle = 0, 315, 45 do -- 8 направлений по кругу
            local rad = math.rad(angle)
            local candidate = fromPos + Vector3.new(math.cos(rad) * dist, 0, math.sin(rad) * dist)
            local origin = Vector3.new(candidate.X, 500, candidate.Z)
            local result = Workspace:Raycast(origin, Vector3.new(0, -1000, 0), params)
            if result and result.Instance and result.Instance:IsA("Terrain") and result.Material == Enum.Material.Water then
                -- нашли открытую воду: возвращаем точку над ней и саму поверхность воды
                return Vector3.new(candidate.X, result.Position.Y + 60, candidate.Z), result.Position
            end
        end
    end
    return nil -- вода не найдена рядом
end

-- Перемещение к точке: близко (<= 550 studs) — телепорт, далеко — плавный полёт
-- CFrame-шагами на скорости Settings.TweenSpeed (как полёт к фрукту).
-- Если Settings.FlyToSea = false — всегда телепорт, даже на больших дистанциях (тогл в GUI).
local function TravelTo(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not Settings.FlyToSea or (targetPos - hrp.Position).Magnitude <= 550 then
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- летим плавно, без телепорта
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
    while true do
        local dt = RunService.Heartbeat:Wait()
        char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local delta = targetPos - hrp.Position
        local dist = delta.Magnitude
        if dist < 5 then break end

        local step = math.min(Settings.TweenSpeed * dt, dist)
        hrp.CFrame = CFrame.new(hrp.Position + delta.Unit * step, targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero

        -- noclip на время полёта
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    hrp.CFrame = CFrame.new(targetPos)
    hrp.AssemblyLinearVelocity = Vector3.zero
    local hum2 = char and char:FindFirstChildOfClass("Humanoid")
    if hum2 then pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end

local function DropFruitIntoSea(tool)
    if IsFlying then return end -- не мешаем полёту, попробуем позже
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not tool.Parent then return end

    local savedCFrame = hrp.CFrame
    local seaPos, waterSurface = FindSeaPosition(hrp.Position)
    if not seaPos then
        -- запасной вариант: очень далеко в сторону от острова
        seaPos = hrp.Position + Vector3.new(600, 80, 600)
        waterSurface = seaPos - Vector3.new(0, 60, 0)
    end

    -- берём фрукт в руки, переносимся над морем, топим фрукт и возвращаемся
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:EquipTool(tool) end) end
    task.wait(0.2)
    TravelTo(seaPos) -- близко — телепорт, дальше 550 studs — плавный полёт
    task.wait(0.25)

    pcall(function()
        tool.Parent = Workspace
        local handle = tool:FindFirstChild("Handle")
        if handle then
            -- кладём хэндл чуть НИЖЕ поверхности воды — фрукт оказывается ПРЯМО в море
            handle.CFrame = CFrame.new(waterSurface - Vector3.new(0, 3, 0))
            handle.AssemblyLinearVelocity = Vector3.new(0, -80, 0)
        end
    end)
    task.wait(0.25)

    TravelTo(savedCFrame.Position) -- возвращаемся тем же способом
    StoreAttempts[tool] = nil
    NextTryAt[tool] = nil
    Notify("🌊 Drop в море", ("Стор полон — выбросил %s прямо в море"):format(tool.Name), 6)
end
-- ========================================

local function StoreFruitTool(tool)
    if StoredCount >= Settings.MaxStoreFruits then return end -- лимит стора достигнут
    if NextTryAt[tool] and tick() < NextTryAt[tool] then return end -- пауза после серии неудач

    StoreAttempts[tool] = (StoreAttempts[tool] or 0) + 1

    if TryStoreRemote(tool) then
        StoreAttempts[tool] = nil
        NextTryAt[tool] = nil
        StoredCount = StoredCount + 1
        Notify("🎒 Auto Store", ("Фрукт убран в стор: %s (%d/%d)"):format(tool.Name, StoredCount, Settings.MaxStoreFruits), 5)
    elseif Settings.DropIfFull and StoreAttempts[tool] >= 6 then
        -- 6 неудач подряд = стор почти наверняка полон → выбрасываем в море
        DropFruitIntoSea(tool)
    elseif StoreAttempts[tool] % 3 == 0 then
        -- после каждых 3 неудач — пауза 10 сек, но попытки НЕ прекращаются
        NextTryAt[tool] = tick() + 10
        Notify("🎒 Auto Store", ("Не убрал %s (попытка %d) — повторю через 10 сек"):format(tool.Name, StoreAttempts[tool]), 5)
    end
end

local function CheckAndStore()
    if not Settings.AutoStore then return end
    if StoredCount >= Settings.MaxStoreFruits then return end -- достигнут лимит — больше не сторим
    -- фрукты в рюкзаке
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if IsFruitTool(tool) then
                StoreFruitTool(tool)
                task.wait(0.3)
            end
        end
    end
    -- фрукт в руках
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if IsFruitTool(tool) then
                StoreFruitTool(tool)
                task.wait(0.3)
            end
        end
    end
end

-- фоновая проверка инвентаря
task.spawn(function()
    while task.wait(1) do
        pcall(CheckAndStore)
    end
end)
-- ====================================

-- ============ АВТО-РОЛЛ (ГАЧА) 🎰 ============
-- Крутит случайный фрукт у Blox Fruit Dealer's Cousin. ВНИМАНИЕ: каждый ролл стоит бели!
-- Выпавший фрукт попадает в инвентарь — дальше его подхватывает Auto Store.
local function RollFruit()
    -- Проверяем, существуют ли необходимые объекты
    if not ReplicatedStorage then
        local errorMsg = "Ошибка: ReplicatedStorage не найден"
        if Settings.DebugMode then print("[Fruit Notifier] " .. errorMsg) end
        Notify("🎰 Авто-ролл", errorMsg, 5)
        return
    end
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = nil
    
    -- Если папка Remotes существует, ищем в ней
    if remotes then
        commF = remotes:FindFirstChild("CommF_")
    end
    
    -- Если не нашли, попробуем найти напрямую в ReplicatedStorage
    if not commF then
        commF = ReplicatedStorage:FindFirstChild("CommF_")
    end
    
    -- Если и это не работает, попробуем рекурсивный поиск
    if not commF then
        local function findRemote(parent, name)
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == name and child:FindFirstChild("InvokeServer") then
                    return child
                elseif child:IsA("Folder") or child:IsA("RemoteFunction") or child:IsA("RemoteEvent") then
                    local found = findRemote(child, name)
                    if found then return found end
                end
            end
            return nil
        end
        
        commF = findRemote(ReplicatedStorage, "CommF_")
    end
    
    if not commF then
        local errorMsg = "Ошибка: CommF_ Remote не найден"
        if Settings.DebugMode then 
            print("[Fruit Notifier] " .. errorMsg)
            print("[Fruit Notifier] Структура ReplicatedStorage:")
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                print("[Fruit Notifier] - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
        end
        Notify("🎰 Авто-ролл", errorMsg, 5)
        return
    end
    
    if not commF.InvokeServer then
        local errorMsg = "Ошибка: CommF_ не имеет метода InvokeServer"
        if Settings.DebugMode then print("[Fruit Notifier] " .. errorMsg) end
        Notify("🎰 Авто-ролл", errorMsg, 5)
        return
    end
    
    local ret
    local ok = pcall(function()
        ret = commF:InvokeServer("Cousin", "Buy")
        if ret == nil then
            ret = commF:InvokeServer("Cousin", "buy")
        end
        if ret == nil then
            ret = commF:InvokeServer("Cousin")
        end
        if ret == nil then
            ret = commF:InvokeServer("Buy")
        end
    end)

    local retStr = tostring(ret or "")
    if Settings.DebugMode then
        print("[Fruit Notifier] Гача ответ:", retStr)
    end

    -- парсим кулдаун из ответа сервера ( "wait X minutes", "подождите X минут" и т.д.)
    local cooldownMinutes = retStr:match("(%d+)%s*min")
        or retStr:match("(%d+)%s*мин")
        or retStr:match("(%d+)%s*minute")

    if ok and ret ~= nil and not cooldownMinutes then
        Notify("🎰 Авто-ролл", ("Ролл: %s"):format(retStr), 5)
        return true, 0
    else
        local waitSec = cooldownMinutes and (tonumber(cooldownMinutes) * 60) or Settings.RollInterval
        return false, waitSec
    end
end

local function FormatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    if h > 0 then
        return ("%dч %02dм"):format(h, m)
    elseif m > 0 then
        return ("%dм %02dс"):format(m, s)
    else
        return ("%dс"):format(s)
    end
end

-- фоновый цикл роллов
task.spawn(function()
    while true do
        task.wait(1)
        if not Settings.AutoRoll then continue end

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or humanoid.Health <= 0 then continue end

        local ok, waitSec = pcall(RollFruit)

        if ok and waitSec then
            if waitSec > 0 then
                for remaining = waitSec, 1, -1 do
                    if not Settings.AutoRoll then break end
                    Notify("🎰 Авто-ролл", ("Нельзя крутить. Подожди: %s"):format(FormatTime(remaining)), 2)
                    task.wait(1)
                end
            else
                task.wait(Settings.RollInterval)
            end
        else
            task.wait(Settings.RollInterval)
        end
    end
end)
-- ==============================================

-- ============ СЕРВЕРНОЕ API 🌐 ============
-- Утилиты получения списка публичных серверов — используются Server Browser'ом.
local TeleportService = game:GetService("TeleportService")

-- game:HttpGet без заголовков получает 403 от Cloudflare на games.roblox.com —
-- именно поэтому хоп не работал. Используем request/syn.request с User-Agent.
-- Получаем JSON через request/syn.request с User-Agent (имитация Roblox-клиента, обходит Cloudflare).
-- Тот же API, что стоит за встроенным сервер-браузером Roblox.
local function HttpGetJson(url)
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    if reqFn then
        local ok, res = pcall(reqFn, {
            Url = url, Method = "GET",
            Headers = { ["User-Agent"] = "Roblox/WinInet" },
        })
        if ok and res and res.Body then
            local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if ok2 then return data end
        end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body then
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok2 then return data end
    end
    return nil
end

-- Старый эндпоинт Roblox: не требует заголовков, работает там где новый недоступен.
-- Возвращает таблицу server JobId строк.
local function FetchServersLegacy()
    local servers = {}
    for startIndex = 0, 200, 100 do
        local url = ("https://www.roblox.com/games/getgameinstancesjson?placeId=%d&startindex=%d"):format(game.PlaceId, startIndex)
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok or not body then break end
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok2 or type(data) ~= "table" then break end
        local list = data.Collection or data.RawServerList or {}
        if #list == 0 then break end
        for _, s in ipairs(list) do
            local id = s.Guid or s.id
            local playing = s.CurrentPlayers or s.playing or 0
            local maxP = s.MaximumPlayers or s.maxPlayers or 0
            if id and id ~= game.JobId and playing < maxP then
                table.insert(servers, id)
            end
        end
        if #servers >= 20 then break end
    end
    return servers
end

-- ============================================

local function FlyToNearest()
    local fruit = GetNearestFruit()
    if fruit then
        TeleportToFruit(fruit)
    else
        Notify("🍈 Fruit Notifier", "На карте нет фруктов 😕", 4)
    end
end
-- =====================================

local function OnFruitFound(fruit, isNew)
    local pos = GetFruitPosition(fruit)
    if not pos then return end

    if isNew then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = hrp and math.floor((hrp.Position - pos).Magnitude) or 0
        Notify("🍈 Fruit Notifier", ("Найден фрукт: %s\nДистанция: %d studs"):format(fruit.Name, dist), 8)

        if Settings.AutoTeleport and not IsFlying then
            task.wait(0.5)
            TeleportToFruit(fruit)
        end
    end

    CreateFruitESP(fruit)
end

-- Сканирование карты
local function ScanMap()
    local found = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if IsFruit(obj) then
            found[obj] = true
            if not SeenFruits[obj] then
                SeenFruits[obj] = true
                OnFruitFound(obj, true)
            else
                OnFruitFound(obj, false)
            end
        end
    end
    for fruit in pairs(TrackedFruits) do
        if not found[fruit] or not fruit.Parent then
            RemoveFruitESP(fruit)
            SeenFruits[fruit] = nil
        end
    end
end

Workspace.ChildAdded:Connect(function(obj)
    task.wait(0.2)
    if IsFruit(obj) and not SeenFruits[obj] then
        SeenFruits[obj] = true
        OnFruitFound(obj, true)
    end
end)

-- Рендер ESP
local RainbowTime = 0
RunService.RenderStepped:Connect(function(dt)
    RainbowTime = RainbowTime + dt * 0.15

    for fruit, obj in pairs(TrackedFruits) do
        local pos = fruit.Parent and GetFruitPosition(fruit)
        if pos and Settings.FruitESP then
            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local dist = hrp and math.floor((hrp.Position - pos).Magnitude) or 0

                local hue = (RainbowTime % 1)
                local rainbowColor = Color3.fromHSV(hue, 0.9, 1)
                local rainbowColor2 = Color3.fromHSV((hue + 0.33) % 1, 0.9, 1)

                obj.Text.Text = ("%dm %s"):format(dist, fruit.Name)
                obj.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                obj.Text.Visible = true
                obj.Text.Color = rainbowColor

                local textSize = obj.Text.TextBounds
                local padX, padY = 8, 4
                obj.Bg.Size = Vector2.new(textSize.X + padX * 2, textSize.Y + padY * 2)
                obj.Bg.Position = Vector2.new(screenPos.X - textSize.X / 2 - padX, screenPos.Y - 30 - textSize.Y / 2 - padY + 5)
                obj.Bg.Visible = true

                obj.Border.Size = obj.Bg.Size
                obj.Border.Position = obj.Bg.Position
                obj.Border.Visible = true
                obj.Border.Color = rainbowColor2

                if Settings.TracerLines then
                    obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    obj.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    obj.Tracer.Color = rainbowColor
                    obj.Tracer.Visible = true
                else
                    obj.Tracer.Visible = false
                end

                if obj.Highlight then
                    obj.Highlight.Adornee = fruit
                    obj.Highlight.OutlineColor = rainbowColor2
                    obj.Highlight.FillColor = rainbowColor
                end
            else
                obj.Text.Visible = false
                obj.Bg.Visible = false
                obj.Border.Visible = false
                obj.Tracer.Visible = false
                if obj.Highlight then obj.Highlight.Adornee = nil end
            end
        elseif pos then
            obj.Text.Visible = false
            obj.Bg.Visible = false
            obj.Border.Visible = false
            obj.Tracer.Visible = false
            if obj.Highlight then obj.Highlight.Adornee = nil end
        else
            RemoveFruitESP(fruit)
        end
    end
end)

-- Цикл сканирования
task.spawn(function()
    while task.wait(Settings.ScanInterval) do
        ScanMap()
    end
end)

-- ==================== GUI (GameSense style) ====================
local ACCENT = Color3.fromRGB(72, 209, 224) -- циан-акцент (меняется кнопками темы)
local BG = Color3.fromRGB(18, 18, 22)       -- почти чёрный фон панели
local BG2 = Color3.fromRGB(26, 26, 32)      -- контейнеры / сайдбар
local BG3 = Color3.fromRGB(40, 40, 48)      -- подсветка при наведении
local WIN_W = 398
local SIDEBAR_W = 120                         -- ширина левой ленты вкладок
local ExtraHeight = 0   -- добавка к высоте, когда открыты доп. опции выброса
local ThemeToggles = {} -- чекбоксы тоглов для перекраски темы
local Sliders = {}      -- ползунки (для перекраски темы и RefreshUI)
local GroupHeaders = {} -- заголовки групп (для перекраски темой)
local minimized = false

local gui = Instance.new("ScreenGui")
gui.Name = "FruitNotifierGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Главное окно
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, 446)
main.Position = UDim2.new(0, 20, 0.3, 0)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(42, 42, 50)
stroke.Transparency = 0.2
stroke.Parent = main

-- тонкая циан-градиентная полоса по верхней кромке (фирменная черта GameSense)
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.Position = UDim2.new(0, 0, 0, 0)
topAccent.BackgroundColor3 = ACCENT
topAccent.BorderSizePixel = 0
topAccent.ZIndex = 5
topAccent.Parent = main

local topAccentGradient = Instance.new("UIGradient")
topAccentGradient.Color = ColorSequence.new(ACCENT, ACCENT:Lerp(Color3.fromRGB(140, 90, 220), 0.6))
topAccentGradient.Parent = topAccent

-- Лёгкая подсветка кнопок при наведении
local function AddHover(btn, baseColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor or BG3 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = baseColor or BG2 }):Play()
    end)
end

-- Шапка (за неё таскаем): плоская, тайтл слева, свернуть справа
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.ZIndex = 4
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🍈 FRUIT NOTIFIER"
title.TextColor3 = Color3.fromRGB(225, 225, 232)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

-- Кнопка свернуть
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -28, 0.5, -11)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.ZIndex = 4
minimizeBtn.Parent = header

-- ---------- Вкладки: вертикальная лента слева (GameSense) ----------
local TabNames = { "Fruits", "Combat", "Settings", "Configs" }
local TabIcons = { Fruits = "🍈", Combat = "🗡️", Settings = "⚙️", Configs = "💾" }
local PageHeights = { Fruits = 446, Combat = 282, Settings = 208, Configs = 200 } -- высота окна для каждой вкладки
local TAB_H = 34    -- высота одной вкладки в ленте
local TAB_TOP = 38  -- отступ ленты сверху (под шапкой)
local currentTab = "Fruits"

-- Левая лента вкладок
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -34)
sidebar.Position = UDim2.new(0, 0, 0, 32)
sidebar.BackgroundColor3 = BG2
sidebar.BackgroundTransparency = 0.4
sidebar.BorderSizePixel = 0
sidebar.Parent = main

-- вертикальный разделитель между лентой и контентом
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, 1, 1, -42)
divider.Position = UDim2.new(0, SIDEBAR_W, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
divider.BorderSizePixel = 0
divider.Parent = main

-- вертикальная полоска-индикатор у активной вкладки
local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0, 2, 0, 20)
tabIndicator.Position = UDim2.new(0, 0, 0, TAB_TOP + 7)
tabIndicator.BackgroundColor3 = ACCENT
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 3
tabIndicator.Parent = main

-- Контейнер страниц (справа от ленты)
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -(SIDEBAR_W + 20), 1, -44)
content.Position = UDim2.new(0, SIDEBAR_W + 12, 0, 38)
content.BackgroundTransparency = 1
content.Parent = main

local Pages = {}
local TabButtons = {}

local function TargetHeight()
    return (PageHeights[currentTab] or 300)
        + (currentTab == "Fruits" and ExtraHeight or 0)
end

local function SwitchTab(name)
    if currentTab == name then return end
    currentTab = name
    for n, page in pairs(Pages) do
        page.Visible = (n == name)
    end
    -- плавное появление страницы
    local page = Pages[name]
    page.Position = UDim2.new(0, 8, 0, 0)
    TweenService:Create(page, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    -- вертикальная полоска-индикатор едет к активной вкладке
    local idx = table.find(TabNames, name)
    TweenService:Create(tabIndicator, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, TAB_TOP + (idx - 1) * TAB_H + 7)
    }):Play()
    -- подсветка вкладок
    for n, b in pairs(TabButtons) do
        TweenService:Create(b, TweenInfo.new(0.15), {
            TextColor3 = (n == name) and ACCENT or Color3.fromRGB(140, 140, 150)
        }):Play()
    end
    -- высота окна подстраивается под вкладку
    if not minimized then
        TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, WIN_W, 0, TargetHeight())
        }):Play()
    end
end

for i, name in ipairs(TabNames) do
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = (name == currentTab)
    page.Parent = content

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.FillDirection = Enum.FillDirection.Vertical
    pageLayout.Parent = page

    Pages[name] = page

    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, SIDEBAR_W - 12, 0, TAB_H)
    tabBtn.Position = UDim2.new(0, 8, 0, TAB_TOP + (i - 1) * TAB_H)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = "  " .. (TabIcons[name] or "") .. "  " .. name
    tabBtn.TextColor3 = (name == currentTab) and ACCENT or Color3.fromRGB(140, 140, 150)
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = main

    tabBtn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)

    TabButtons[name] = tabBtn
end

-- Фабрика тоглов: плоский квадратный чекбокс (GameSense)
local function CreateToggle(name, settingKey, order, onChanged, page, swatchColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = page or Pages.Fruits

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 14, 0, 14)
    box.Position = UDim2.new(0, 0, 0.5, -7)
    box.BackgroundColor3 = Settings[settingKey] and ACCENT or BG2
    box.BorderSizePixel = 0
    box.Parent = btn

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 3)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(70, 70, 82)
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    -- внутренняя точка-заполнение
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    dot.BorderSizePixel = 0
    dot.Visible = Settings[settingKey]
    dot.Parent = box
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 2)
    dotCorner.Parent = dot

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -46, 1, 0)
    label.Position = UDim2.new(0, 22, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(205, 205, 214)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    -- необязательный цветовой свотч справа (для визуалов)
    if swatchColor then
        local sw = Instance.new("Frame")
        sw.Size = UDim2.new(0, 14, 0, 14)
        sw.Position = UDim2.new(1, -16, 0.5, -7)
        sw.BackgroundColor3 = swatchColor
        sw.BorderSizePixel = 0
        sw.Parent = btn
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 3)
    end

    table.insert(ThemeToggles, { Box = box, Dot = dot, Key = settingKey })

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local on = Settings[settingKey]
        dot.Visible = on
        TweenService:Create(box, TweenInfo.new(0.12), {
            BackgroundColor3 = on and ACCENT or BG2
        }):Play()
        if onChanged then onChanged(on) end
    end)

    return btn
end

-- Фабрика заголовков групп (тонкая cyan-подпись + линия)
local function CreateGroupHeader(page, order, text)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 18)
    h.BackgroundTransparency = 1
    h.LayoutOrder = order
    h.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text)
    lbl.TextColor3 = ACCENT
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    line.BorderSizePixel = 0
    line.Parent = h

    table.insert(GroupHeaders, lbl)
    return h
end

-- Фабрика ползунков (тонкая дорожка, значение в подписи)
local function CreateSlider(page, order, labelFormat, settingKey, minV, maxV)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 14)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(205, 205, 214)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local back = Instance.new("Frame")
    back.Size = UDim2.new(1, 0, 0, 4)
    back.Position = UDim2.new(0, 0, 0, 20)
    back.BackgroundColor3 = Color3.fromRGB(46, 46, 56)
    back.BorderSizePixel = 0
    back.Parent = row

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(1, 0)
    backCorner.Parent = back

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = back

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 8, 0, 8)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = back
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function Refresh()
        local v = Settings[settingKey]
        local rel = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        label.Text = labelFormat:format(v)
    end
    Refresh()

    local dragging = false
    local function Update(inputPos)
        local rel = math.clamp((inputPos.X - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
        Settings[settingKey] = math.floor(minV + rel * (maxV - minV) + 0.5)
        Refresh()
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    table.insert(Sliders, { Fill = fill, Refresh = Refresh })
end

local function CreateSoundSelector(name, settingKey, list, order, page, onChanged)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = order
    row.Parent = page or Pages.Fruits

    local leftBtn = Instance.new("TextButton")
    leftBtn.Size = UDim2.new(0, 18, 0, 18)
    leftBtn.Position = UDim2.new(0, 0, 0.5, -9)
    leftBtn.BackgroundColor3 = BG2
    leftBtn.BorderSizePixel = 0
    leftBtn.Text = "<"
    leftBtn.TextColor3 = ACCENT
    leftBtn.TextSize = 12
    leftBtn.Font = Enum.Font.GothamBold
    leftBtn.Parent = row
    Instance.new("UICorner", leftBtn).CornerRadius = UDim.new(0, 3)

    local rightBtn = Instance.new("TextButton")
    rightBtn.Size = UDim2.new(0, 18, 0, 18)
    rightBtn.Position = UDim2.new(0, 140, 0.5, -9)
    rightBtn.BackgroundColor3 = BG2
    rightBtn.BorderSizePixel = 0
    rightBtn.Text = ">"
    rightBtn.TextColor3 = ACCENT
    rightBtn.TextSize = 12
    rightBtn.Font = Enum.Font.GothamBold
    rightBtn.Parent = row
    Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 3)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 70, 0, 18)
    label.Position = UDim2.new(0, 22, 0.5, -9)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(205, 205, 214)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -162, 0, 18)
    nameLabel.Position = UDim2.new(0, 162, 0.5, -9)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local function Refresh()
        local idx = Settings[settingKey]
        label.Text = ("%d/%d"):format(idx, #list)
        nameLabel.Text = list[idx] and list[idx].Name or ""
    end

    leftBtn.MouseButton1Click:Connect(function()
        Settings[settingKey] = Settings[settingKey] - 1
        if Settings[settingKey] < 1 then Settings[settingKey] = #list end
        Refresh()
        pcall(function() SaveConfig() end)
        if onChanged then pcall(onChanged) end
    end)

    rightBtn.MouseButton1Click:Connect(function()
        Settings[settingKey] = Settings[settingKey] + 1
        if Settings[settingKey] > #list then Settings[settingKey] = 1 end
        Refresh()
        pcall(function() SaveConfig() end)
        if onChanged then pcall(onChanged) end
    end)

    row.MouseButton1Click:Connect(function()
        Settings[settingKey] = Settings[settingKey] + 1
        if Settings[settingKey] > #list then Settings[settingKey] = 1 end
        Refresh()
        pcall(function() SaveConfig() end)
        if onChanged then pcall(onChanged) end
    end)

    Refresh()
    table.insert(Sliders, { Refresh = Refresh })
end

CreateGroupHeader(Pages.Fruits, 1, "Notifications")
CreateToggle("Уведомления", "Notifications", 2)
CreateToggle("Звук", "NotifySound", 3)
CreateSoundSelector("Тип звука", "NotifySoundId", SoundList, 4, Pages.Fruits)
CreateToggle("Музыка", "MusicEnabled", 5, function(on)
    ToggleMusic()
end)
CreateSoundSelector("Трек", "MusicId", MusicList, 6, Pages.Fruits, function()
    ChangeMusic()
end)
CreateToggle("Fruit ESP", "FruitESP", 7)
CreateToggle("Трейсеры", "TracerLines", 8)
CreateGroupHeader(Pages.Fruits, 9, "Farm")
CreateToggle("Авто-полёт 🛫", "AutoTeleport", 10, function(on)
    if on then
        FlyToNearest() -- включил тогл — сразу летим к ближайшему
    else
        StopTween()    -- выключил — останавливаем полёт
    end
end)
CreateToggle("Auto Store 🎒", "AutoStore", 11)
local dropRow = CreateToggle("Выброс в море 🌊", "DropIfFull", 12)

-- стрелка «доп. опции» на тогле выброса в море
local dropArrow = Instance.new("TextButton")
dropArrow.Size = UDim2.new(0, 18, 0, 18)
dropArrow.Position = UDim2.new(1, -18, 0.5, -9)
dropArrow.BackgroundTransparency = 1
dropArrow.Text = ">" -- ASCII: юникод-стрелки (▸) в шрифтах Roblox рендерятся квадратом
dropArrow.TextColor3 = Color3.fromRGB(160, 160, 170)
dropArrow.TextSize = 14
dropArrow.Font = Enum.Font.GothamBold
dropArrow.Parent = dropRow

-- доп. опция выброса: скрыта, открывается стрелочкой «>»
local flyToSeaRow = CreateToggle("   ↳ Лететь к морю ✈️", "FlyToSea", 13)
flyToSeaRow.Visible = false

CreateToggle("Авто-ролл 🎰", "AutoRoll", 14)
CreateToggle("Отладка 🐞", "DebugMode", 15, function(on)
    SaveConfig()
end)

-- Ползунок: лимит фруктов в стор
CreateSlider(Pages.Fruits, 16, "Лимит стора: %d", "MaxStoreFruits", 1, 10)

-- ============ COMBAT 🗡️ ============
-- Silent Aim на ближайшего игрока (радиус AimRange, 360°) с визуалом: зелёное
-- полупрозрачное поле вокруг цели + красный трейсер. Плюс анти-стан и авто-респавн.
local Combat = { Target = nil, Highlight = nil, Tracer = nil }

-- ближайший ЖИВОЙ игрок в радиусе AimRange (любое направление, 360°)
local function GetNearestPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, Settings.AimRange
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local phrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if phrp and hum and hum.Health > 0 then
                local dd = (hrp.Position - phrp.Position).Magnitude
                if dd <= bestDist then best, bestDist = plr, dd end
            end
        end
    end
    return best
end

-- зелёное полупрозрачное поле вокруг тела цели
local function EnsureHighlight()
    if Combat.Highlight and Combat.Highlight.Parent then return Combat.Highlight end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(60, 220, 90)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(90, 255, 120)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    pcall(function() hl.Parent = gui end)
    Combat.Highlight = hl
    return hl
end

-- красный трейсер к цели
local function EnsureTracer()
    if Combat.Tracer then return Combat.Tracer end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1.8
    line.Color = Color3.fromRGB(255, 60, 60)
    Combat.Tracer = line
    return line
end

local function ClearTargetVisuals()
    if Combat.Highlight then Combat.Highlight.Adornee = nil end
    if Combat.Tracer then Combat.Tracer.Visible = false end
end

-- обновление цели и визуала каждый кадр
RunService.RenderStepped:Connect(function()
    if not Settings.SilentAim then
        Combat.Target = nil
        ClearTargetVisuals()
        return
    end
    local target = GetNearestPlayer()
    Combat.Target = target
    if not target or not target.Character then
        ClearTargetVisuals()
        return
    end
    local tchar = target.Character
    -- зелёное поле только если включён тогл визуала
    local hl = EnsureHighlight()
    hl.Adornee = Settings.AimHighlight and tchar or nil
    local thrp = tchar:FindFirstChild("HumanoidRootPart")
    local tracer = EnsureTracer()
    if Settings.AimTracer and thrp then
        local sp, onScreen = Camera:WorldToViewportPoint(thrp.Position)
        if onScreen then
            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            tracer.To = Vector2.new(sp.X, sp.Y)
            tracer.Visible = true
        else
            tracer.Visible = false
        end
    else
        tracer.Visible = false
    end
end)

-- Silent Aim (истинный silent aim, БЕЗ хука ремоутов).
-- «Курсор как будто на враге, но не на враге»: подменяем не ремоуты (это ломало
-- игру — фриз/кик через рассинхрон позиции), а то, что скилл читает у МЫШИ.
-- Через hookmetamethod(game, "__index") перехватываем обращения к прицелу
-- локального мыша: Mouse.Hit -> CFrame цели, Mouse.Target -> HRP цели,
-- Mouse.UnitRay -> луч камера->цель. Сам курсор при этом НЕ двигается.
-- Ремоуты не трогаются вообще => позиция игрока не рассинхронивается => нет фриза.
local aimHookInstalled = false
local function InstallAimHook()
    if aimHookInstalled then return end
    if not hookmetamethod then
        Notify("🎯 Silent Aim", "Эксплойт не поддерживает hookmetamethod 😕", 5)
        return
    end
    aimHookInstalled = true

    local mouse = LocalPlayer:GetMouse()

    local function TargetHrp()
        local t = Combat.Target
        local tchar = t and t.Character
        return tchar and tchar:FindFirstChild("HumanoidRootPart")
    end

    local oldIndex
    local function idx(self, key)
        -- реагируем ТОЛЬКО на прицел локального мыша, всё остальное — без изменений
        if Settings.SilentAim and self == mouse then
            -- пропускаем чтения самого скрипта, чтобы наши визуалы брали реальные данные
            local skip = false
            if checkcaller then
                local okc, res = pcall(checkcaller)
                skip = okc and res
            end
            if not skip then
                local thrp = TargetHrp()
                if thrp then
                    if key == "Hit" then
                        return CFrame.new(thrp.Position)
                    elseif key == "Target" then
                        return thrp
                    elseif key == "UnitRay" then
                        local cam = Workspace.CurrentCamera
                        local origin = (cam and cam.CFrame.Position) or thrp.Position
                        return Ray.new(origin, (thrp.Position - origin).Unit)
                    end
                end
            end
        end
        return oldIndex(self, key)
    end

    -- newcclosure повышает совместимость и снижает шанс детекта хука
    if newcclosure then
        local okN, wrapped = pcall(newcclosure, idx)
        if okN and type(wrapped) == "function" then idx = wrapped end
    end

    oldIndex = hookmetamethod(game, "__index", idx)
    Notify("🎯 Silent Aim", "Прицел подменяется на цель, курсор не двигается", 4)
end

-- Анти-стан: сбрасываем стан/обнуление скорости, снимаем типичные эффекты
task.spawn(function()
    while task.wait(0.3) do
        if Settings.AntiStun then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if hum.WalkSpeed < 8 then hum.WalkSpeed = 16 end
                    if hum.JumpPower < 10 then hum.JumpPower = 50 end
                    hum.Sit = false
                    hum.PlatformStand = false
                    for _, n in ipairs({ "Stun", "Paralyze", "Ken", "Freeze", "Bound" }) do
                        local val = char:FindFirstChild(n)
                        if val and val:IsA("ValueBase") then val.Value = false end
                        if char:GetAttribute(n) ~= nil then pcall(function() char:SetAttribute(n, false) end) end
                    end
                end
            end)
        end
    end
end)

-- Авто-респавн: при смерти персонажа быстро грузим нового
local function HookRespawn(char)
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.Died:Connect(function()
        if Settings.AutoRespawn then
            task.wait(1)
            pcall(function() LocalPlayer:LoadCharacter() end)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(HookRespawn)
if LocalPlayer.Character then HookRespawn(LocalPlayer.Character) end

-- ---------- Вкладка Combat 🗡️ ----------
CreateGroupHeader(Pages.Combat, 1, "Aimbot")
CreateToggle("🎯 Silent Aim", "SilentAim", 2, function(on)
    if on then InstallAimHook() end
end, Pages.Combat)
CreateSlider(Pages.Combat, 3, "Дальность таргета: %d studs", "AimRange", 100, 500)
CreateGroupHeader(Pages.Combat, 4, "Visuals")
CreateToggle("Зелёное поле цели", "AimHighlight", 5, nil, Pages.Combat, Color3.fromRGB(60, 220, 90))
CreateToggle("Красный трейсер", "AimTracer", 6, nil, Pages.Combat, Color3.fromRGB(255, 60, 60))
CreateGroupHeader(Pages.Combat, 7, "Player")
CreateToggle("🛡️ Анти-стан", "AntiStun", 8, nil, Pages.Combat)
CreateToggle("💀 Авто-респавн", "AutoRespawn", 9, nil, Pages.Combat)
-- ===================================

-- Заголовок группы «Действия» + кнопка ручного полёта
CreateGroupHeader(Pages.Fruits, 17, "Actions")
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(1, 0, 0, 24)
flyBtn.BackgroundColor3 = ACCENT
flyBtn.Text = "🛫 Лететь к ближайшему фрукту"
flyBtn.TextColor3 = Color3.fromRGB(15, 15, 18)
flyBtn.TextSize = 11
flyBtn.Font = Enum.Font.GothamBold
flyBtn.LayoutOrder = 18
flyBtn.Parent = Pages.Fruits

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyBtn

flyBtn.MouseButton1Click:Connect(function()
    if IsFlying then
        StopTween()
    else
        FlyToNearest()
    end
end)

-- Обновление кнопки при смене состояния полёта
OnFlightStateChanged = function(flying)
    flyBtn.Text = flying and "⏹ Стоп" or "🛫 Лететь к ближайшему фрукту"
    flyBtn.BackgroundColor3 = flying and Color3.fromRGB(220, 70, 70) or ACCENT
end

-- ---------- Server Browser 🌐 ----------
-- Кнопка в Fruits открывает попап со списком серверов — можно выбрать любой и зайти на него.
local sbOpenBtn = Instance.new("TextButton")
sbOpenBtn.Size = UDim2.new(1, 0, 0, 26)
sbOpenBtn.BackgroundColor3 = BG2
sbOpenBtn.Text = "🌐 Server Browser"
sbOpenBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
sbOpenBtn.TextSize = 12
sbOpenBtn.Font = Enum.Font.GothamBold
sbOpenBtn.LayoutOrder = 19
sbOpenBtn.Parent = Pages.Fruits
Instance.new("UICorner", sbOpenBtn).CornerRadius = UDim.new(0, 8)
AddHover(sbOpenBtn, BG2)

local sbWindow = Instance.new("Frame")
sbWindow.Size = UDim2.new(0, 220, 0, 290)
sbWindow.Position = UDim2.new(0, 268, 0.3, 0)
sbWindow.BackgroundColor3 = BG
sbWindow.BorderSizePixel = 0
sbWindow.Visible = false
sbWindow.ZIndex = 10
sbWindow.Parent = gui
Instance.new("UICorner", sbWindow).CornerRadius = UDim.new(0, 12)
local sbStroke = Instance.new("UIStroke")
sbStroke.Color = ACCENT
sbStroke.Transparency = 0.6
sbStroke.Parent = sbWindow

local sbHeader = Instance.new("Frame")
sbHeader.Size = UDim2.new(1, 0, 0, 30)
sbHeader.BackgroundColor3 = BG2
sbHeader.BorderSizePixel = 0
sbHeader.ZIndex = 11
sbHeader.Parent = sbWindow
Instance.new("UICorner", sbHeader).CornerRadius = UDim.new(0, 12)

local sbTitle = Instance.new("TextLabel")
sbTitle.Size = UDim2.new(1, -60, 1, 0)
sbTitle.Position = UDim2.new(0, 10, 0, 0)
sbTitle.BackgroundTransparency = 1
sbTitle.Text = "🌐 Server Browser"
sbTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
sbTitle.TextSize = 12
sbTitle.Font = Enum.Font.GothamBold
sbTitle.TextXAlignment = Enum.TextXAlignment.Left
sbTitle.ZIndex = 12
sbTitle.Parent = sbHeader

local sbRefBtn = Instance.new("TextButton")
sbRefBtn.Size = UDim2.new(0, 24, 0, 24)
sbRefBtn.Position = UDim2.new(1, -54, 0, 3)
sbRefBtn.BackgroundColor3 = BG
sbRefBtn.Text = "↻"
sbRefBtn.TextColor3 = ACCENT
sbRefBtn.TextSize = 15
sbRefBtn.Font = Enum.Font.GothamBold
sbRefBtn.ZIndex = 12
sbRefBtn.Parent = sbHeader
Instance.new("UICorner", sbRefBtn).CornerRadius = UDim.new(0, 6)

local sbCloseBtn = Instance.new("TextButton")
sbCloseBtn.Size = UDim2.new(0, 24, 0, 24)
sbCloseBtn.Position = UDim2.new(1, -28, 0, 3)
sbCloseBtn.BackgroundColor3 = BG
sbCloseBtn.Text = "✕"
sbCloseBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
sbCloseBtn.TextSize = 12
sbCloseBtn.Font = Enum.Font.GothamBold
sbCloseBtn.ZIndex = 12
sbCloseBtn.Parent = sbHeader
Instance.new("UICorner", sbCloseBtn).CornerRadius = UDim.new(0, 6)

local sbStatus = Instance.new("TextLabel")
sbStatus.Size = UDim2.new(1, -16, 0, 18)
sbStatus.Position = UDim2.new(0, 8, 0, 33)
sbStatus.BackgroundTransparency = 1
sbStatus.Text = "Нажмите ↻"
sbStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
sbStatus.TextSize = 10
sbStatus.Font = Enum.Font.Gotham
sbStatus.TextXAlignment = Enum.TextXAlignment.Left
sbStatus.ZIndex = 11
sbStatus.Parent = sbWindow

local sbScroll = Instance.new("ScrollingFrame")
sbScroll.Size = UDim2.new(1, -8, 1, -56)
sbScroll.Position = UDim2.new(0, 4, 0, 54)
sbScroll.BackgroundTransparency = 1
sbScroll.ScrollBarThickness = 3
sbScroll.ScrollBarImageColor3 = ACCENT
sbScroll.BorderSizePixel = 0
sbScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sbScroll.ZIndex = 11
sbScroll.Parent = sbWindow
local sbLayout = Instance.new("UIListLayout")
sbLayout.Padding = UDim.new(0, 4)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Parent = sbScroll

local function FetchAndShowServers()
    for _, c in ipairs(sbScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    sbStatus.Text = "⏳ Загрузка..."
    task.spawn(function()
        local all = {}
        local cursor = ""
        for p = 1, 5 do
            if #all >= 50 then break end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            local data = HttpGetJson(url)
            if not data or type(data.data) ~= "table" then break end
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId then table.insert(all, s) end
            end
            cursor = data.nextPageCursor
            if not cursor or cursor == "" then break end
        end
        -- если новый API не дал результатов — пробуем старый эндпоинт (www.roblox.com)
        if #all == 0 then
            for _, id in ipairs(FetchServersLegacy()) do
                table.insert(all, { id = id, playing = 0, maxPlayers = 0 })
            end
        end
        if #all == 0 then sbStatus.Text = "❌ Серверы не найдены" return end
        table.sort(all, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
        sbStatus.Text = ("✅ Найдено: %d"):format(#all)
        for i, s in ipairs(all) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = BG2
            row.LayoutOrder = i
            row.ZIndex = 12
            row.Parent = sbScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            local info = Instance.new("TextLabel")
            info.Size = UDim2.new(1, -56, 1, 0)
            info.Position = UDim2.new(0, 6, 0, 0)
            info.BackgroundTransparency = 1
            info.Text = ("👥 %d/%d игр"):format(s.playing or 0, s.maxPlayers or 0)
            info.TextColor3 = Color3.fromRGB(200, 200, 210)
            info.TextSize = 11
            info.Font = Enum.Font.Gotham
            info.TextXAlignment = Enum.TextXAlignment.Left
            info.ZIndex = 13
            info.Parent = row
            local jBtn = Instance.new("TextButton")
            jBtn.Size = UDim2.new(0, 44, 0, 20)
            jBtn.Position = UDim2.new(1, -48, 0.5, -10)
            jBtn.BackgroundColor3 = ACCENT
            jBtn.Text = "Join"
            jBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
            jBtn.TextSize = 11
            jBtn.Font = Enum.Font.GothamBold
            jBtn.ZIndex = 14
            jBtn.Parent = row
            Instance.new("UICorner", jBtn).CornerRadius = UDim.new(0, 6)
            local jobId = s.id
            jBtn.MouseButton1Click:Connect(function()
                sbWindow.Visible = false
                Notify("🌐 Server Hop", "Подключаюсь...", 5)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                end)
            end)
        end
        sbScroll.CanvasSize = UDim2.new(0, 0, 0, #all * 32)
    end)
end

sbRefBtn.MouseButton1Click:Connect(FetchAndShowServers)
sbCloseBtn.MouseButton1Click:Connect(function() sbWindow.Visible = false end)
sbOpenBtn.MouseButton1Click:Connect(function()
    sbWindow.Visible = not sbWindow.Visible
    if sbWindow.Visible then FetchAndShowServers() end
end)

-- Server Browser остаётся доступен как отдельная кнопка для ручного выбора сервера.

-- ---------- BF Stock 📦 ----------
-- Кнопка в Fruits открывает попап с ТЕКУЩИМ стоком дилера.
-- Сток берётся из ремоута GetFruits и фильтруется по флагу OnSale.
local bfOpenBtn = Instance.new("TextButton")
bfOpenBtn.Size = UDim2.new(1, 0, 0, 26)
bfOpenBtn.BackgroundColor3 = BG2
bfOpenBtn.Text = "📦 BF Stock"
bfOpenBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
bfOpenBtn.TextSize = 12
bfOpenBtn.Font = Enum.Font.GothamBold
bfOpenBtn.LayoutOrder = 20
bfOpenBtn.Parent = Pages.Fruits
Instance.new("UICorner", bfOpenBtn).CornerRadius = UDim.new(0, 8)
AddHover(bfOpenBtn, BG2)

-- Попап со стоком: окно, шапка с кнопками ↻ / ✕, статус и прокручиваемый список.
local bfWindow = Instance.new("Frame")
bfWindow.Size = UDim2.new(0, 220, 0, 290)
bfWindow.Position = UDim2.new(0, 268, 0.3, 0)
bfWindow.BackgroundColor3 = BG
bfWindow.BorderSizePixel = 0
bfWindow.Visible = false
bfWindow.ZIndex = 10
bfWindow.Parent = gui
Instance.new("UICorner", bfWindow).CornerRadius = UDim.new(0, 12)
local bfStroke = Instance.new("UIStroke")
bfStroke.Color = ACCENT
bfStroke.Transparency = 0.6
bfStroke.Parent = bfWindow

local bfHeader = Instance.new("Frame")
bfHeader.Size = UDim2.new(1, 0, 0, 30)
bfHeader.BackgroundColor3 = BG2
bfHeader.BorderSizePixel = 0
bfHeader.ZIndex = 11
bfHeader.Parent = bfWindow
Instance.new("UICorner", bfHeader).CornerRadius = UDim.new(0, 12)

local bfTitle = Instance.new("TextLabel")
bfTitle.Size = UDim2.new(1, -60, 1, 0)
bfTitle.Position = UDim2.new(0, 10, 0, 0)
bfTitle.BackgroundTransparency = 1
bfTitle.Text = "📦 BF Stock"
bfTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
bfTitle.TextSize = 12
bfTitle.Font = Enum.Font.GothamBold
bfTitle.TextXAlignment = Enum.TextXAlignment.Left
bfTitle.ZIndex = 12
bfTitle.Parent = bfHeader

local bfRefBtn = Instance.new("TextButton")
bfRefBtn.Size = UDim2.new(0, 24, 0, 24)
bfRefBtn.Position = UDim2.new(1, -54, 0, 3)
bfRefBtn.BackgroundColor3 = BG
bfRefBtn.Text = "↻"
bfRefBtn.TextColor3 = ACCENT
bfRefBtn.TextSize = 15
bfRefBtn.Font = Enum.Font.GothamBold
bfRefBtn.ZIndex = 12
bfRefBtn.Parent = bfHeader
Instance.new("UICorner", bfRefBtn).CornerRadius = UDim.new(0, 6)

local bfCloseBtn = Instance.new("TextButton")
bfCloseBtn.Size = UDim2.new(0, 24, 0, 24)
bfCloseBtn.Position = UDim2.new(1, -28, 0, 3)
bfCloseBtn.BackgroundColor3 = BG
bfCloseBtn.Text = "✕"
bfCloseBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
bfCloseBtn.TextSize = 12
bfCloseBtn.Font = Enum.Font.GothamBold
bfCloseBtn.ZIndex = 12
bfCloseBtn.Parent = bfHeader
Instance.new("UICorner", bfCloseBtn).CornerRadius = UDim.new(0, 6)

local bfStatus = Instance.new("TextLabel")
bfStatus.Size = UDim2.new(1, -16, 0, 18)
bfStatus.Position = UDim2.new(0, 8, 0, 33)
bfStatus.BackgroundTransparency = 1
bfStatus.Text = "Нажмите ↻"
bfStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
bfStatus.TextSize = 10
bfStatus.Font = Enum.Font.Gotham
bfStatus.TextXAlignment = Enum.TextXAlignment.Left
bfStatus.ZIndex = 11
bfStatus.Parent = bfWindow

local bfScroll = Instance.new("ScrollingFrame")
bfScroll.Size = UDim2.new(1, -8, 1, -56)
bfScroll.Position = UDim2.new(0, 4, 0, 54)
bfScroll.BackgroundTransparency = 1
bfScroll.ScrollBarThickness = 3
bfScroll.ScrollBarImageColor3 = ACCENT
bfScroll.BorderSizePixel = 0
bfScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
bfScroll.ZIndex = 11
bfScroll.Parent = bfWindow
local bfLayout = Instance.new("UIListLayout")
bfLayout.Padding = UDim.new(0, 4)
bfLayout.SortOrder = Enum.SortOrder.LayoutOrder
bfLayout.Parent = bfScroll

-- Текущий выбранный режим стока: "normal" — обычный дилер, "mirage" — Мираж-остров.
local stockMode = "normal"

-- Возвращает сток + строки отладки. Логи в консоли F9 тонут в спаме игры, поэтому
-- отладку (поля записей, счётчики) мы ВОЗВРАЩАЕМ и показываем прямо в попапе.
-- Обычный сток: GetFruits + фильтр OnSale. Мираж: сперва мираж-флаги в GetFruits,
-- если пусто — пробуем игровой модуль ReplicatedStorage.Modules.Asset.GetFeaturedFruits.
local function FetchFruitStock(mode)
    local dbg = {}
    local function d(...)
        local p = {}
        for _, a in ipairs({ ... }) do p[#p + 1] = tostring(a) end
        dbg[#dbg + 1] = table.concat(p, " ")
    end

    -- каталог фруктов через remote
    local ok, ret = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits")
    end)
    print(("[Fruit Notifier] GetFruits (%s) ->"):format(tostring(mode)), ret)
    d("GetFruits: ok=" .. tostring(ok) .. " type=" .. typeof(ret))

    local list = {}
    if ok and type(ret) == "table" then
        local rawCount, sampled = 0, false
        for key, v in pairs(ret) do
            rawCount = rawCount + 1
            if type(v) == "table" then
                if not sampled then
                    sampled = true
                    d("поля записи [" .. tostring(key) .. "]:")
                    for kk, vv in pairs(v) do d("  ." .. tostring(kk) .. "=" .. tostring(vv)) end
                end
                local inStock
                if mode == "mirage" then
                    inStock = v.OnSaleMirage
                    if inStock == nil then inStock = v.MirageOnSale end
                    if inStock == nil then inStock = v.MirageStock end
                    if inStock == nil then inStock = v.mirageOnSale end
                    if inStock == nil then inStock = v.Mirage end
                else
                    inStock = v.OnSale
                    if inStock == nil then inStock = v.onSale end
                    if inStock == nil then inStock = v.On_Sale end
                end
                if inStock == true or inStock == 1 then
                    local name = v.Name or v.name or (type(key) == "string" and key) or tostring(key)
                    table.insert(list, { Name = tostring(name), Money = v.Price or v.price, Robux = v.Robux or v.robux })
                end
            end
        end
        d("raw=" .. rawCount .. " найдено(" .. tostring(mode) .. ")=" .. #list)
    end

    -- мираж: если через GetFruits пусто — читаем игровой модуль GetFeaturedFruits
    if mode == "mirage" and #list == 0 then
        local okF, res = pcall(function()
            local mods = ReplicatedStorage:FindFirstChild("Modules")
            local asset = mods and mods:FindFirstChild("Asset")
            local mod = asset and asset:FindFirstChild("GetFeaturedFruits")
            if not mod then return "нет модуля" end
            local r = require(mod)
            if type(r) == "function" then return r() end
            return r
        end)
        d("GetFeaturedFruits: ok=" .. tostring(okF) .. " type=" .. typeof(res))
        if okF and type(res) == "table" then
            local sampled = false
            for key, v in pairs(res) do
                if type(v) == "table" then
                    if not sampled then
                        sampled = true
                        d("featured поля [" .. tostring(key) .. "]:")
                        for kk, vv in pairs(v) do d("  ." .. tostring(kk) .. "=" .. tostring(vv)) end
                    end
                    local name = v.Name or v.name or (type(key) == "string" and key) or tostring(key)
                    table.insert(list, { Name = tostring(name), Money = v.Price or v.price, Robux = v.Robux or v.robux })
                elseif type(v) == "string" then
                    table.insert(list, { Name = v })
                end
            end
            d("featured найдено=" .. #list)
        end
    end

    return list, dbg
end

local function ShowFruitStock()
    for _, c in ipairs(bfScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    bfStatus.Text = "⏳ Загрузка..."
    task.spawn(function()
        local list, dbg = FetchFruitStock(stockMode)
        list = list or {}
        table.sort(list, function(a, b) return a.Name < b.Name end)
        if #list == 0 then
            -- пусто: показываем отладку прямо в окне (её удобно заскринить)
            bfStatus.Text = "📦 Пусто — отладка ниже (заскринь)"
            local h = 0
            for i, line in ipairs(dbg or {}) do
                local dl = Instance.new("TextLabel")
                dl.Size = UDim2.new(1, -8, 0, 16)
                dl.BackgroundTransparency = 1
                dl.Text = line
                dl.TextColor3 = Color3.fromRGB(150, 150, 160)
                dl.TextSize = 10
                dl.Font = Enum.Font.Code
                dl.TextXAlignment = Enum.TextXAlignment.Left
                dl.TextTruncate = Enum.TextTruncate.AtEnd
                dl.LayoutOrder = i
                dl.ZIndex = 13
                dl.Parent = bfScroll
                h = h + 18
            end
            bfScroll.CanvasSize = UDim2.new(0, 0, 0, h)
            return
        end
        bfStatus.Text = ("✅ В стоке (%s): %d"):format(stockMode, #list)
        for i, f in ipairs(list) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = BG2
            row.LayoutOrder = i
            row.ZIndex = 12
            row.Parent = bfScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            local info = Instance.new("TextLabel")
            info.Size = UDim2.new(1, -12, 1, 0)
            info.Position = UDim2.new(0, 6, 0, 0)
            info.BackgroundTransparency = 1
            local price = ""
            if f.Money then price = ("$%s"):format(tostring(f.Money)) end
            if f.Robux then price = price .. (price ~= "" and " / " or "") .. ("R$%s"):format(tostring(f.Robux)) end
            info.Text = price ~= "" and ("🍈 %s — %s"):format(f.Name, price) or ("🍈 %s"):format(f.Name)
            info.TextColor3 = Color3.fromRGB(200, 200, 210)
            info.TextSize = 11
            info.Font = Enum.Font.Gotham
            info.TextXAlignment = Enum.TextXAlignment.Left
            info.ZIndex = 13
            info.Parent = row
        end
        bfScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 32)
    end)
end

-- Диалог выбора: обычный сток или мираж сток (открывается кнопкой 📦 BF Stock)
local bfChoice = Instance.new("Frame")
bfChoice.Size = UDim2.new(0, 200, 0, 128)
bfChoice.Position = UDim2.new(0, 268, 0.3, 0)
bfChoice.BackgroundColor3 = BG
bfChoice.BorderSizePixel = 0
bfChoice.Visible = false
bfChoice.ZIndex = 20
bfChoice.Parent = gui
Instance.new("UICorner", bfChoice).CornerRadius = UDim.new(0, 12)
local bfChoiceStroke = Instance.new("UIStroke")
bfChoiceStroke.Color = ACCENT
bfChoiceStroke.Transparency = 0.6
bfChoiceStroke.Parent = bfChoice

local bfChoiceTitle = Instance.new("TextLabel")
bfChoiceTitle.Size = UDim2.new(1, -16, 0, 30)
bfChoiceTitle.Position = UDim2.new(0, 8, 0, 8)
bfChoiceTitle.BackgroundTransparency = 1
bfChoiceTitle.Text = "Какой сток показать?"
bfChoiceTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
bfChoiceTitle.TextSize = 13
bfChoiceTitle.Font = Enum.Font.GothamBold
bfChoiceTitle.ZIndex = 21
bfChoiceTitle.Parent = bfChoice

-- открыть окно стока в выбранном режиме
local function OpenStock(mode)
    stockMode = mode
    bfTitle.Text = (mode == "mirage") and "🌴 Мираж сток" or "📦 Обычный сток"
    bfChoice.Visible = false
    bfWindow.Visible = true
    ShowFruitStock()
end

local function MakeChoiceBtn(text, order, mode)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, 42 + (order - 1) * 38)
    b.BackgroundColor3 = BG2
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 21
    b.Parent = bfChoice
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    AddHover(b, BG2)
    b.MouseButton1Click:Connect(function() OpenStock(mode) end)
    return b
end

MakeChoiceBtn("🛒 Обычный сток", 1, "normal")
MakeChoiceBtn("🌴 Мираж сток", 2, "mirage")

bfRefBtn.MouseButton1Click:Connect(ShowFruitStock)
bfCloseBtn.MouseButton1Click:Connect(function() bfWindow.Visible = false end)
bfOpenBtn.MouseButton1Click:Connect(function()
    -- клик закрывает всё, если окно/диалог открыты; иначе показывает выбор стока
    if bfWindow.Visible or bfChoice.Visible then
        bfWindow.Visible = false
        bfChoice.Visible = false
    else
        bfChoice.Visible = true
    end
end)

-- Смена акцентного цвета GUI
local function SetAccent(color)
    ACCENT = color -- новые элементы берут цвет автоматически
    topAccent.BackgroundColor3 = color
    topAccentGradient.Color = ColorSequence.new(color, color:Lerp(Color3.fromRGB(140, 90, 220), 0.6))
    tabIndicator.BackgroundColor3 = color
    if TabButtons[currentTab] then
        TabButtons[currentTab].TextColor3 = color
    end
    for _, lbl in ipairs(GroupHeaders) do
        lbl.TextColor3 = color
    end
    for _, s in ipairs(Sliders) do
        s.Fill.BackgroundColor3 = color
    end
    if not IsFlying then
        flyBtn.BackgroundColor3 = color
    end
    for _, t in ipairs(ThemeToggles) do
        if Settings[t.Key] then
            t.Box.BackgroundColor3 = color
        end
    end
end

-- Заголовок группы «Тема» + кнопочки смены цвета темы 🎨
CreateGroupHeader(Pages.Settings, 1, "Theme")
local themeRow = Instance.new("Frame")
themeRow.Size = UDim2.new(1, 0, 0, 26)
themeRow.BackgroundColor3 = BG2
themeRow.BackgroundTransparency = 0.3
themeRow.LayoutOrder = 2
themeRow.Parent = Pages.Settings

local themeRowCorner = Instance.new("UICorner")
themeRowCorner.CornerRadius = UDim.new(0, 8)
themeRowCorner.Parent = themeRow

local themeLayout = Instance.new("UIListLayout")
themeLayout.FillDirection = Enum.FillDirection.Horizontal
themeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
themeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
themeLayout.Padding = UDim.new(0, 8)
themeLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeLayout.Parent = themeRow

local ThemeColors = {
    Color3.fromRGB(72, 209, 224),  -- циан (по умолчанию)
    Color3.fromRGB(170, 110, 255), -- фиолетовый
    Color3.fromRGB(80, 200, 120),  -- зелёный
    Color3.fromRGB(255, 170, 0),   -- оранжевый
    Color3.fromRGB(220, 70, 70),   -- красный
    Color3.fromRGB(255, 105, 180), -- розовый
}

for i, color in ipairs(ThemeColors) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 18, 0, 18)
    cBtn.BackgroundColor3 = color
    cBtn.Text = ""
    cBtn.AutoButtonColor = true
    cBtn.LayoutOrder = i
    cBtn.Parent = themeRow

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(1, 0)
    cCorner.Parent = cBtn

    cBtn.MouseButton1Click:Connect(function()
        CurrentTheme = i -- запоминаем тему для конфига
        SetAccent(color)
    end)
end

-- Заголовок группы «Движение» + ползунок скорости полёта (макс 300 studs/сек)
CreateGroupHeader(Pages.Settings, 3, "Movement")
CreateSlider(Pages.Settings, 4, "Скорость полёта: %d studs/сек", "TweenSpeed", 50, 300)

-- применяем сохранённую тему из конфига
if ThemeColors[CurrentTheme] and CurrentTheme ~= 1 then
    SetAccent(ThemeColors[CurrentTheme])
end

-- Обновление всего GUI под текущие Settings (после ресета)
local function RefreshUI()
    for _, t in ipairs(ThemeToggles) do
        local on = Settings[t.Key]
        t.Box.BackgroundColor3 = on and ACCENT or BG2
        t.Dot.Visible = on
    end
    for _, s in ipairs(Sliders) do
        s.Refresh()
    end
    SetAccent(ThemeColors[CurrentTheme] or ThemeColors[1])
end

-- ---------- Вкладка Configs 💾 ----------
CreateGroupHeader(Pages.Configs, 1, "Config")
local configInfo = Instance.new("TextLabel")
configInfo.Size = UDim2.new(1, 0, 0, 44)
configInfo.BackgroundTransparency = 1
configInfo.Text = "Сохраняются тоглы, ползунки и тема.\nКонфиг подхватывается при запуске."
configInfo.TextColor3 = Color3.fromRGB(140, 140, 150)
configInfo.TextSize = 11
configInfo.Font = Enum.Font.Gotham
configInfo.TextWrapped = true
configInfo.TextXAlignment = Enum.TextXAlignment.Left
configInfo.LayoutOrder = 2
configInfo.Parent = Pages.Configs

-- «вспышка» на кнопке как подтверждение действия
local function Flash(btn, color)
    TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = color }):Play()
    task.delay(0.25, function()
        TweenService:Create(btn, TweenInfo.new(0.3), { BackgroundColor3 = BG2 }):Play()
    end)
end

-- Кнопки конфига: 💾 сохранить / 🔄 ресет
local configRow = Instance.new("Frame")
configRow.Size = UDim2.new(1, 0, 0, 26)
configRow.BackgroundTransparency = 1
configRow.LayoutOrder = 3
configRow.Parent = Pages.Configs

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.5, -3, 1, 0)
saveBtn.BackgroundColor3 = BG2
saveBtn.Text = "💾 Сохранить"
saveBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
saveBtn.TextSize = 12
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Parent = configRow

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 8)
saveCorner.Parent = saveBtn

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -3, 1, 0)
resetBtn.Position = UDim2.new(0.5, 3, 0, 0)
resetBtn.BackgroundColor3 = BG2
resetBtn.Text = "🔄 Ресет"
resetBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
resetBtn.TextSize = 12
resetBtn.Font = Enum.Font.GothamBold
resetBtn.Parent = configRow

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetBtn

AddHover(saveBtn, BG2)
AddHover(resetBtn, BG2)

saveBtn.MouseButton1Click:Connect(function()
    SaveConfig()
    Flash(saveBtn, Color3.fromRGB(80, 200, 120)) -- зелёная вспышка
end)
resetBtn.MouseButton1Click:Connect(function()
    ResetConfig()
    RefreshUI()
    Flash(resetBtn, Color3.fromRGB(220, 70, 70)) -- красная вспышка
end)

-- Сворачивание
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    minimizeBtn.Text = minimized and "+" or "—"
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, WIN_W, 0, 34) or UDim2.new(0, WIN_W, 0, TargetHeight())
    }):Play()
end)

-- Раскрытие доп. опций «Выброс в море»: стрелочка «>» поворачивается вниз при открытии
local dropExpanded = false
dropArrow.MouseButton1Click:Connect(function()
    dropExpanded = not dropExpanded
    TweenService:Create(dropArrow, TweenInfo.new(0.15), {
        Rotation = dropExpanded and 90 or 0
    }):Play()
    flyToSeaRow.Visible = dropExpanded
    ExtraHeight = dropExpanded and 32 or 0
    if not minimized and currentTab == "Fruits" then
        TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, WIN_W, 0, TargetHeight())
        }):Play()
    end
end)

-- Перетаскивание за шапку
do
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end
-- =============================================

ScanMap()
Notify("🍈 Fruit Notifier", "Скрипт запущен! Сканирую карту...", 5)
print("[Fruit Notifier] Загружен | by Warniy")
