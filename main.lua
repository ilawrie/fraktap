local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GITHUB_REPO = "https://raw.githubusercontent.com/ilawrie/fraktap/main/"

-- Функция для скачивания модулей без кэширования
local function LoadModule(fileName)
    local url = GITHUB_REPO .. fileName .. ".lua?t=" .. tostring(tick())
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        return result
    else
        warn("Ошибка загрузки модуля " .. fileName .. ": " .. tostring(result))
        return nil
    end
end

-- ==========================================
-- 2. ЗАГРУЗКА ИНТЕРФЕЙСА (WIND UI)
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "fraktap",
    Folder = "ftgshub",
    Theme = "Amber",
    NewElements = true,
    HideSearchBar = true,
    OpenButton = { Enabled = false },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

-- Создаем вкладки
local ExploitsTab = Window:Tab({
    Title = "Exploits",
    Icon = "solar:check-square-bold",
    IconShape = "Square",
    Border = true,
})

local SkinchangerTab = Window:Tab({
    Title = "Skinchanger",
    Icon = "solar:palette-bold",
    IconShape = "Square",
    Border = true,
})

-- ==========================================
-- 3. ПОДГРУЗКА МОДУЛЕЙ И КНОПКИ
-- ==========================================
local AutoChest = LoadModule("autochest")
local Exploits = LoadModule("exploits")

if AutoChest then
    -- Запускаем фоновые циклы для сундуков, передаем WindUI для уведомлений
    AutoChest.Init(WindUI)
    
    ExploitsTab:Toggle({
        Title = "Auto chest",
        Desc = "Automatically claim parkour chests",
        Type = "Checkbox",
        Callback = function(state)
            AutoChest.SetActive(state)
        end
    })
end

ExploitsTab:Space()

if Exploits then
    ExploitsTab:Button({
        Title = "Kill animals",
        Desc = "Deal mass damage to all animals", 
        Icon = "mouse",
        Callback = function()
            Exploits.KillAllAnimals(LocalPlayer)
        end,
    })

    ExploitsTab:Space()

    ExploitsTab:Button({
        Title = "Destroy props",
        Desc = "Destroy all map props",
        Icon = "mouse",
        Callback = function()
            Exploits.DestroyProps()
        end,
    })
end

-- Выбираем первую вкладку по умолчанию
task.spawn(function()
    task.wait(0.1)
    if ExploitsTab.Select then ExploitsTab:Select() end
end)

-- ==========================================
-- 4. ФИКС ОТОБРАЖЕНИЯ МЕНЮ И АНТИ-АФК
-- ==========================================
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
    task.wait(0.5)
    local targetContainer = type(gethui) == "function" and gethui() or game:GetService("CoreGui")
    if targetContainer then
        for _, gui in ipairs(targetContainer:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "RobloxGui" then
                pcall(function()
                    gui.DisplayOrder = 999999999
                    gui.IgnoreGuiInset = true
                end)
            end
        end
    end
end)