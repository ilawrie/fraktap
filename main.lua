-- ==========================================
-- MAIN MODULE - UI AND INITIALIZATION
-- ==========================================

local cloneref = (cloneref or clonereference or function(instance) return instance end)

local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- LOAD MODULES VIA HTTPGET
-- ==========================================
local function loadModule(moduleName)
    local url = "https://raw.githubusercontent.com/ilawrie/fraktap/refs/heads/main/" .. moduleName .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleName .. " - " .. tostring(result))
        return {}
    end
    
    return result
end

local AutoFarm = loadModule("autofarm")
local AutoChest = loadModule("autochest")
local SetAnimal = loadModule("setanimal")
local KillExploit = loadModule("killexploit")
local KillAnimals = loadModule("killanimals")
local DestroyProps = loadModule("destroyprops")
local ESP = loadModule("esp")
local Campaign = loadModule("campaign")

-- Wait for necessary remotes
local NetRemote = ReplicatedStorage:WaitForChild("Net")
local PlayerStateEvent = ReplicatedStorage:WaitForChild("iKomi"):WaitForChild("Modules"):WaitForChild("States"):WaitForChild("Player"):WaitForChild("StateRemoteEvent")
local GlobalStateEvent = ReplicatedStorage:WaitForChild("iKomi"):WaitForChild("Modules"):WaitForChild("States"):WaitForChild("Global"):WaitForChild("StateRemoteEvent")

-- ==========================================
-- ANTI-AFK
-- ==========================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- WIND UI INITIALIZATION
-- ==========================================
local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        if RunService:IsStudio() then
            WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end
end

local Green = Color3.fromHex("#574C40")

local Window = WindUI:CreateWindow({  
    Title = "fraktap",
    Icon = "solar:wind-bold",
    Folder = "fraktap",
    Theme = "Midnight",
    NewElements = true,
    HideSearchBar = true,
    OpenButton = { Enabled = false },
    Topbar = { Height = 44, ButtonsType = "Default" },
})

-- ==========================================
-- FIX GUI DISPLAY
-- ==========================================
task.spawn(function()
    task.wait(0.5)
    local targetContainer = nil

    if type(gethui) == "function" then
        targetContainer = gethui()
    else
        local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if success and coreGui then
            targetContainer = coreGui
        else
            if Players.LocalPlayer then
                targetContainer = Players.LocalPlayer:FindFirstChild("PlayerGui")
            end
        end
    end

    if targetContainer then
        for _, gui in ipairs(targetContainer:GetChildren()) do
            if gui:IsA("ScreenGui") then
                if gui.Name ~= "RobloxGui" and gui.Name ~= "CoreScriptsRootProvider" and gui.Name ~= "RobloxNetworkPerformance" then
                    pcall(function()
                        gui.DisplayOrder = 999999999
                        gui.IgnoreGuiInset = true
                    end)
                end
            end
        end
    end
end)

-- ==========================================
-- DOUBLE-TAP TO TOGGLE MENU
-- ==========================================
local lastClickTime = 0
local doubleClickDelay = 0.35 
local centerRadius = 150         

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local camera = workspace.CurrentCamera
        if not camera then return end

        local mousePos = input.Position
        local screenCenter = camera.ViewportSize / 2
        local distance = (Vector2.new(mousePos.X, mousePos.Y) - screenCenter).Magnitude
        
        if distance <= centerRadius then
            local currentTime = tick()
            if currentTime - lastClickTime <= doubleClickDelay then
                Window:Toggle()
                lastClickTime = 0
            else
                lastClickTime = currentTime
            end
        end
    end
end)

-- ==========================================
-- NOTIFICATION FUNCTIONS
-- ==========================================
local function notifyAnimal()
    if not SetAnimal.selectedAnimalName then return end
    
    WindUI:Notify({
        Title = "Animal set",
        Content = "You will play: " .. tostring(SetAnimal.selectedAnimalName),
        Icon = "solar:bell-bold",
        Duration = 4,
        CanClose = true,
    })
end

-- ==========================================
-- UI TABS AND BUTTONS
-- ==========================================

local ExploitsTab = Window:Tab({
    Title = "Exploits",
    Icon = "terminal",
})

-- Auto Farm Toggle
ExploitsTab:Toggle({
    Title = "Auto farm",
    Desc = "Passive money earning",
    Type = "Checkbox",
    Callback = function(state)
        AutoFarm.farmActive = state
        if not AutoFarm.farmActive then
            AutoFarm:resetRoundState()
        else
            AutoFarm:setupRenderLoop()
        end
    end
})

ExploitsTab:Space()

-- Auto Chest Toggle
ExploitsTab:Toggle({
    Title = "Auto chest",
    Desc = "Automatically claim parkour chests",
    Type = "Checkbox",
    Callback = function(state)
        if state then
            AutoChest:start()
            AutoChest:setupChestEventListener(WindUI)
        else
            AutoChest:stop()
        end
    end
})

ExploitsTab:Space()

-- Set Animal Button
local SetAnimalBtn
SetAnimalBtn = ExploitsTab:Button({
    Title = "Set animal",
    Desc = "Play as a selected animal",
    Icon = "mouse",
    Callback = function()
        local success = SetAnimal:spendAnimalTicket()
        if success then
            notifyAnimal()
        end
        if SetAnimalBtn and SetAnimalBtn.Highlight then SetAnimalBtn:Highlight() end
    end,
})

-- Select Animal Dropdown
ExploitsTab:Dropdown({
    Title = "Select animal",
    Values = SetAnimal.ANIMALS,
    Value = nil,
    Callback = function(selectedValue)
        SetAnimal:setSelectedAnimal(selectedValue)
    end,
})

-- Auto Set Animal Toggle
ExploitsTab:Toggle({
    Title = "Auto set",
    Type = "Checkbox",
    Callback = function(state)
        SetAnimal.useTicketActive = state
    end
})

ExploitsTab:Space()

-- Kill Exploit Button
local KillExploitBtn
KillExploitBtn = ExploitsTab:Button({
    Title = "Kill exploit",
    Desc = "Damage the selected animal",
    Icon = "mouse",
    Callback = function()
        pcall(function()
            KillExploit:attackTarget()
        end)
        if KillExploitBtn and KillExploitBtn.Highlight then KillExploitBtn:Highlight() end
    end,
})

-- Select Target Dropdown
KillExploit.killExploitDropdown = ExploitsTab:Dropdown({
    Title = "Select target",
    Values = {},
    Value = nil,
    Callback = function(selectedValue)
        if selectedValue and selectedValue ~= "" then
            local playerName = KillExploit:extractPlayerName(selectedValue)
            KillExploit.targetPlayerName = playerName
        else
            KillExploit.targetPlayerName = nil
        end
    end,
})

-- Update target list (optimized - only refresh when list changes)
local lastAnimalsList = {}
task.spawn(function()
    while true do
        task.wait(0.5)
        local currentPlayers = KillExploit:getActiveAnimalsList()
        
        -- Only refresh if the list actually changed
        local listChanged = false
        if #currentPlayers ~= #lastAnimalsList then
            listChanged = true
        else
            for i = 1, #currentPlayers do
                if currentPlayers[i] ~= lastAnimalsList[i] then
                    listChanged = true
                    break
                end
            end
        end
        
        if listChanged then
            lastAnimalsList = currentPlayers
            pcall(function()
                if KillExploit.killExploitDropdown and KillExploit.killExploitDropdown.Refresh then
                    KillExploit.killExploitDropdown:Refresh(currentPlayers)
                end
            end)
        end
    end
end)

ExploitsTab:Space()

-- Kill Animals Button
local KillAnimalsBtn
KillAnimalsBtn = ExploitsTab:Button({
    Title = "Kill animals",
    Desc = "Deal mass damage to all animals", 
    Icon = "mouse",
    Callback = function()
        pcall(function()
            KillAnimals:killAll()
        end)
        if KillAnimalsBtn and KillAnimalsBtn.Highlight then KillAnimalsBtn:Highlight() end
    end,
})

ExploitsTab:Space()

-- Destroy Props Button
local DestroyPropsBtn
DestroyPropsBtn = ExploitsTab:Button({
    Title = "Destroy props",
    Desc = "Destroy all map props",
    Icon = "mouse",
    Callback = function()
        pcall(function()
            DestroyProps:destroyAll()
        end)
        if DestroyPropsBtn and DestroyPropsBtn.Highlight then DestroyPropsBtn:Highlight() end
    end,
})

ExploitsTab:Space()

-- Campaign Unlocker Button
local CampaignUnlockerBtn
CampaignUnlockerBtn = ExploitsTab:Button({
    Title = "Campaign unlocker",
    Desc = "Unlock selected campaign item",
    Icon = "mouse",
    Callback = function()
        pcall(function()
            Campaign:collectSelectedItem()
        end)
        if CampaignUnlockerBtn and CampaignUnlockerBtn.Highlight then CampaignUnlockerBtn:Highlight() end
    end,
})

-- Campaign Item Dropdown
ExploitsTab:Dropdown({
    Title = "Select item",
    Values = Campaign:getItemNames(),
    Value = nil,
    Callback = function(selectedValue)
        Campaign.selectedItem = selectedValue
    end,
})

-- ==========================================
-- VISUALS TAB
-- ==========================================

local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
})

-- ESP Toggle
VisualsTab:Toggle({
    Title = "ESP",
    Desc = "See assigned animals with boxes",
    Type = "Checkbox",
    Callback = function(state)
        ESP.flags["Enabled"] = state
        ESP.flags["Boxes"] = state
        ESP:refresh_elements()
        if state then
            ESP:initialize()
        end
    end
})

-- Box Color Picker
local BoxColorPicker = VisualsTab:Colorpicker({
    Title = "Box Color",
    Desc = "Choose box color",
    Default = Color3.fromRGB(255, 255, 255),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        ESP.flags["Box_Color"].Color = color
        ESP:refresh_elements()
    end
})

-- ==========================================
-- NETWORK EVENT HANDLERS
-- ==========================================

GlobalStateEvent.OnClientEvent:Connect(function(key, playerObject)
    if key == "Seeker" then
        AutoFarm.currentHunter = playerObject
        AutoFarm.cachedHunterRoot = nil

        if playerObject == LocalPlayer and AutoFarm.farmActive then
            AutoFarm:resetCharacter()
        end
    end
end)

PlayerStateEvent.OnClientEvent:Connect(function(targetPlayer, key, animalName)
    local playerName = nil
    if typeof(targetPlayer) == "Instance" then
        playerName = targetPlayer.Name
    end

    if key == "CurrentAnimal" and playerName then
        if animalName ~= nil then
            KillExploit:setAnimalData(playerName, animalName)
        else
            KillExploit:removeAnimalData(playerName)
            -- Also remove ESP for this animal
            pcall(function()
                if targetPlayer.Character then
                    ESP:remove_object(targetPlayer.Character)
                end
            end)
        end
    end

    if targetPlayer == LocalPlayer and key == "CurrentAnimal" then
        if animalName ~= nil then
            -- Set camera to max distance when animal is assigned
            local camera = Workspace.CurrentCamera
            if camera then
                camera.MaxAxisLength = 40
            end
        end
    end

    if targetPlayer == LocalPlayer and key == "CurrentAnimal" and AutoFarm.farmActive then
        local _, root = AutoFarm:getCharacter()
        if not root then
            return
        end

        if animalName ~= nil then
            task.spawn(function()
                local SpawnLocation = Workspace:WaitForChild("Lobby"):WaitForChild("Lobby"):WaitForChild("Visual"):WaitForChild("Props"):WaitForChild("SpawnLocation")
                
                if not AutoFarm.farmActive then return end
                local _, currentRoot = AutoFarm:getCharacter()
                if currentRoot then
                    currentRoot.CFrame = SpawnLocation.CFrame
                end
                task.wait(0.5)

                if not AutoFarm.farmActive then return end
                _, currentRoot = AutoFarm:getCharacter()
                if currentRoot and AutoFarm.savedSpawnCFrame then
                    currentRoot.CFrame = AutoFarm.savedSpawnCFrame
                end
                task.wait(0.5)

                if not AutoFarm.farmActive then return end
                _, currentRoot = AutoFarm:getCharacter()
                if currentRoot then
                    currentRoot.CFrame = SpawnLocation.CFrame
                end
                task.wait(0.5)

                if not AutoFarm.farmActive then return end
                _, currentRoot = AutoFarm:getCharacter()
                if currentRoot and AutoFarm.savedSpawnCFrame then
                    currentRoot.CFrame = AutoFarm.savedSpawnCFrame
                end
                task.wait(0.5)

                if not AutoFarm.farmActive then return end
                AutoFarm:attachToHunter()
            end)
        else
            if not AutoFarm:attachToHunter() then
                local _, currentRoot = AutoFarm:getCharacter()
                if currentRoot and AutoFarm.savedSpawnCFrame then
                    currentRoot.CFrame = AutoFarm.savedSpawnCFrame
                    AutoFarm.isAttached = true
                end
            end
        end
    end
end)

NetRemote.OnClientEvent:Connect(function(eventsList)
    if type(eventsList) ~= "table" then
        return
    end

    local eventsToCheck = {}
    if eventsList.name then
        table.insert(eventsToCheck, eventsList)
    else
        for _, subData in ipairs(eventsList) do
            if type(subData) == "table" and subData.name then
                table.insert(eventsToCheck, subData)
            end
        end
    end

    for _, event in ipairs(eventsToCheck) do
        local name = event.name
        local args = event.arguments or {}

        if name == "Stream.send" and args[1] == "gameManager_currentState" then
            if args[2] == "intermission" then
                if SetAnimal.useTicketActive and SetAnimal.selectedAnimalName then
                    pcall(function()
                        SetAnimal:spendAnimalTicket()
                        notifyAnimal()
                    end)
                end
            elseif args[2] == "award" then
                AutoFarm:resetRoundState()
                KillExploit:clearAnimalList()
                -- Clear ESP boxes when round ends
                pcall(function()
                    ESP:clear_all()
                end)
            end
        end

        if name == "Stream.send" and args[1] == "round_currentState" and args[2] == "warmup" then
            if AutoFarm.farmActive then
                local _, root = AutoFarm:getCharacter()
                if root then
                    AutoFarm.savedSpawnCFrame = root.CFrame
                    AutoFarm:startTauntLoop()
                end
            end
        end

        if name == "Prey.add" then
            local targetObj = args[1]
            local animalType = args[2] or "animal"
            if typeof(targetObj) == "Instance" then
                KillExploit:setAnimalData(targetObj.Name, animalType)
            end
        elseif name == "Prey.updateHealth" then
            local targetObj = args[1]
            local newHealth = args[2]
            if newHealth and newHealth <= 0 and typeof(targetObj) == "Instance" then
                KillExploit:removeAnimalData(targetObj.Name)
            end
        elseif name == "Prey.remove" or name == "Prey.removeMultiple" then
            for _, pArg in ipairs(args) do
                if typeof(pArg) == "Instance" and pArg:IsA("Player") then
                    KillExploit:removeAnimalData(pArg.Name)
                elseif type(pArg) == "table" then
                    for _, subP in pairs(pArg) do
                        if typeof(subP) == "Instance" and subP:IsA("Player") then
                            KillExploit:removeAnimalData(subP.Name)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- RENDER LOOP FOR AUTO FARM
-- ==========================================
RunService.RenderStepped:Connect(function()
    if not AutoFarm.farmActive or not AutoFarm.isAttached then
        return
    end

    local _, myRoot, myHum = AutoFarm:getCharacter()
    local hunterRoot = AutoFarm:getHunterRoot()

    if myRoot and myHum and hunterRoot then
        myHum.PlatformStand = true
        myRoot.CFrame = hunterRoot.CFrame * CFrame.new(0, 0, 4)
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end
end)

-- ==========================================
-- ACTIVATE DEFAULT TAB
-- ==========================================
task.spawn(function()
    task.wait(0.1)
    if ExploitsTab and ExploitsTab.Select then
        pcall(function() ExploitsTab:Select() end)
    end
end)
