-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Connections storage for clean unloading
local Connections = {}

local Whitelist = {} 
local Highlights = {} 
local MenuOpen = true
local Aiming = false

-- Settings
local Settings = {
    AimEnabled = true,
    ChamsEnabled = true,
    FovEnabled = true,
    AutoShootEnabled = false,
    FOVRadius = 150,
    Smoothness = 0.2,
    ToggleKey = Enum.KeyCode.F,
    AimKey = Enum.UserInputType.MouseButton2,
}

-- ScreenGui Creation in CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernTargetUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true

local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Visual FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.ZIndex = 1000
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(88, 101, 242)
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.4
FOVStroke.Parent = FOVCircle

-- Main Frame UI
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 1000
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Header Bar
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Header.BorderSizePixel = 0
Header.ZIndex = 1001
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 10)
HeaderCover.Position = UDim2.new(0, 0, 1, -10)
HeaderCover.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
HeaderCover.BorderSizePixel = 0
HeaderCover.ZIndex = 1001
HeaderCover.Parent = Header

local Title = Instance.new("TextLabel")
Title.Text = "TARGET SYSTEM // ESP & AIM"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.ZIndex = 1002
Title.Parent = Header

-- Content Panels
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.48, -12, 1, -65)
LeftPanel.Position = UDim2.new(0, 12, 0, 55)
LeftPanel.BackgroundTransparency = 1
LeftPanel.ZIndex = 1001
LeftPanel.Parent = MainFrame

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.52, -18, 1, -65)
RightPanel.Position = UDim2.new(0.48, 6, 0, 55)
RightPanel.BackgroundTransparency = 1
RightPanel.ZIndex = 1001
RightPanel.Parent = MainFrame

-- Left Panel: Entity List
local ListTitle = Instance.new("TextLabel")
ListTitle.Text = "Игроки и Боты (ЛКМ = Whitelist)"
ListTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
ListTitle.Font = Enum.Font.GothamMedium
ListTitle.TextSize = 11
ListTitle.Size = UDim2.new(1, 0, 0, 20)
ListTitle.BackgroundTransparency = 1
ListTitle.ZIndex = 1002
ListTitle.Parent = LeftPanel

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, 0, 1, -24)
PlayerScroll.Position = UDim2.new(0, 0, 0, 24)
PlayerScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
PlayerScroll.ZIndex = 1002
PlayerScroll.Parent = LeftPanel

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = PlayerScroll

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = PlayerScroll

-- UI Generators
local function CreateCheckbox(parent, text, positionY, defaultState, callback)
    local Container = Instance.new("TextButton")
    Container.Size = UDim2.new(1, 0, 0, 28)
    Container.Position = UDim2.new(0, 0, 0, positionY)
    Container.BackgroundTransparency = 1
    Container.Text = ""
    Container.ZIndex = 1002
    Container.Parent = parent

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 18, 0, 18)
    Box.Position = UDim2.new(0, 0, 0.5, -9)
    Box.BackgroundColor3 = defaultState and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(28, 28, 36)
    Box.BorderSizePixel = 0
    Box.ZIndex = 1003
    Box.Parent = Container

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 5)
    BoxCorner.Parent = Box

    local CheckMark = Instance.new("TextLabel")
    CheckMark.Text = "✓"
    CheckMark.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheckMark.Font = Enum.Font.GothamBold
    CheckMark.TextSize = 12
    CheckMark.Size = UDim2.new(1, 0, 1, 0)
    CheckMark.BackgroundTransparency = 1
    CheckMark.Visible = defaultState
    CheckMark.ZIndex = 1004
    CheckMark.Parent = Box

    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(210, 210, 220)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Position = UDim2.new(0, 26, 0, 0)
    Label.Size = UDim2.new(1, -26, 1, 0)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.ZIndex = 1003
    Label.Parent = Container

    local state = defaultState
    local conn = Container.MouseButton1Click:Connect(function()
        state = not state
        Box.BackgroundColor3 = state and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(28, 28, 36)
        CheckMark.Visible = state
        callback(state)
    end)
    table.insert(Connections, conn)
end

CreateCheckbox(RightPanel, "Aimbot", 0, Settings.AimEnabled, function(val) Settings.AimEnabled = val end)
CreateCheckbox(RightPanel, "Chams (ESP)", 32, Settings.ChamsEnabled, function(val)
    Settings.ChamsEnabled = val
    for _, highlight in pairs(Highlights) do
        if highlight and highlight.Parent then highlight.Enabled = val end
    end
end)
CreateCheckbox(RightPanel, "Автовыстрел", 64, Settings.AutoShootEnabled, function(val)
    Settings.AutoShootEnabled = val
end)
CreateCheckbox(RightPanel, "FOV круг", 96, Settings.FovEnabled, function(val)
    Settings.FovEnabled = val
    FOVCircle.Visible = val
end)

local function CreateSlider(parent, labelText, positionY, minVal, maxVal, defaultVal, isFloat, callback)
    local Label = Instance.new("TextLabel")
    Label.Text = labelText .. (isFloat and string.format(": %.2f", defaultVal) or string.format(": %d", defaultVal))
    Label.TextColor3 = Color3.fromRGB(180, 180, 190)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.Position = UDim2.new(0, 0, 0, positionY)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.ZIndex = 1002
    Label.Parent = parent

    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, 0, 0, 6)
    SliderBg.Position = UDim2.new(0, 0, 0, positionY + 18)
    SliderBg.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    SliderBg.BorderSizePixel = 0
    SliderBg.ZIndex = 1002
    SliderBg.Parent = parent

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = SliderBg

    local initialRel = (defaultVal - minVal) / (maxVal - minVal)
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(initialRel, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    SliderFill.BorderSizePixel = 0
    SliderFill.ZIndex = 1003
    SliderFill.Parent = SliderBg

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill

    local Sliding = false
    table.insert(Connections, SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Sliding = true end
    end))
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Sliding = false end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if Sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation().X
            local sliderAbsPos = SliderBg.AbsolutePosition.X
            local sliderAbsSize = SliderBg.AbsoluteSize.X
            local relX = math.clamp((mousePos - sliderAbsPos) / sliderAbsSize, 0, 1)
            SliderFill.Size = UDim2.new(relX, 0, 1, 0)
            local value = minVal + relX * (maxVal - minVal)
            Label.Text = labelText .. (isFloat and string.format(": %.2f", value) or string.format(": %d", math.floor(value)))
            callback(value)
        end
    end))
end

CreateSlider(RightPanel, "Smoothness", 136, 0.05, 1.0, Settings.Smoothness, true, function(val) Settings.Smoothness = math.clamp(val, 0.05, 1) end)
CreateSlider(RightPanel, "FOV Radius", 182, 30, 350, Settings.FOVRadius, false, function(val)
    Settings.FOVRadius = math.floor(val)
    FOVCircle.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
end)

-- Unload Logic
local function UnloadScript()
    for _, conn in ipairs(Connections) do
        if conn then 
            pcall(function() conn:Disconnect() end) 
        end 
    end
    table.clear(Connections)
    
    for _, highlight in pairs(Highlights) do 
        if highlight and highlight.Parent then 
            pcall(function() highlight:Destroy() end) 
        end 
    end
    table.clear(Highlights)
    
    if ScreenGui then 
        pcall(function() ScreenGui:Destroy() end) 
    end
end

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(1, 0, 0, 30)
UnloadButton.Position = UDim2.new(0, 0, 1, -30)
UnloadButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
UnloadButton.Text = "Выгрузить скрипт"
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.TextSize = 11
UnloadButton.ZIndex = 1002
UnloadButton.Parent = RightPanel

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 8)
UnloadCorner.Parent = UnloadButton
table.insert(Connections, UnloadButton.MouseButton1Click:Connect(UnloadScript))

-- Dragging Logic
local Dragging, DragInput, DragStart, StartPos
table.insert(Connections, Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        local connEnded
        connEnded = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                if connEnded then connEnded:Disconnect() end
            end
        end)
    end
end))
table.insert(Connections, Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = input end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    end
end))

-- Hotkeys (F to toggle menu)
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.ToggleKey then
        MenuOpen = not MenuOpen
        MainFrame.Visible = MenuOpen
    end
end))

-- ПОИСК СУЩНОСТЕЙ
local function GetValidEntities()
    local entities = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            table.insert(entities, {
                Key = player.UserId,
                Name = player.DisplayName .. " (@" .. player.Name .. ")",
                Character = player.Character,
                IsPlayer = true
            })
        end
    end

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local head = obj:FindFirstChild("Head")
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            
            if humanoid and head and rootPart and humanoid.Health > 0 then
                local isPlayerChar = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then isPlayerChar = true break end
                end
                
                if not isPlayerChar then
                    table.insert(entities, {
                        Key = "BOT_" .. obj.Name .. "_" .. tostring(obj),
                        Name = "[Bot] " .. obj.Name,
                        Character = obj,
                        IsPlayer = false
                    })
                end
            end
        end
    end

    return entities
end

local function UpdateChamsColorsAndHighlights()
    local entities = GetValidEntities()
    local activeKeys = {}

    for _, entity in ipairs(entities) do
        activeKeys[entity.Key] = true
        local char = entity.Character
        
        if not char or not char.Parent then
            if Highlights[entity.Key] then
                pcall(function() Highlights[entity.Key]:Destroy() end)
                Highlights[entity.Key] = nil
            end
            continue
        end
        
        local highlight = Highlights[entity.Key]

        if highlight then
            pcall(function() highlight:Destroy() end)
            Highlights[entity.Key] = nil
        end
        
        highlight = Instance.new("Highlight")
        highlight.Name = "ChamsHighlight"
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = Settings.ChamsEnabled
        highlight.Adornee = char
        highlight.Parent = char
        Highlights[entity.Key] = highlight

        if entity.IsPlayer then
            if Whitelist[entity.Key] then
                highlight.FillColor = Color3.fromRGB(40, 220, 100)
                highlight.OutlineColor = Color3.fromRGB(40, 220, 100)
            else
                highlight.FillColor = Color3.fromRGB(245, 60, 60)
                highlight.OutlineColor = Color3.fromRGB(245, 40, 40)
            end
        else
            if Whitelist[entity.Key] then
                highlight.FillColor = Color3.fromRGB(40, 220, 100)
                highlight.OutlineColor = Color3.fromRGB(40, 220, 100)
            else
                highlight.FillColor = Color3.fromRGB(240, 240, 240)
                highlight.OutlineColor = Color3.fromRGB(180, 180, 180)
            end
        end
    end

    for key, hl in pairs(Highlights) do
        if not activeKeys[key] then
            if hl then pcall(function() hl:Destroy() end) end
            Highlights[key] = nil
        end
    end
end

-- Refresh UI List
local function RefreshEntityList()
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local entities = GetValidEntities()
    for _, entity in ipairs(entities) do
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -6, 0, 28)
        
        local bgColor = Color3.fromRGB(22, 22, 28)
        if Whitelist[entity.Key] then
            bgColor = Color3.fromRGB(25, 90, 50)
        end
        
        Button.BackgroundColor3 = bgColor
        Button.Text = entity.Name
        Button.TextColor3 = Color3.fromRGB(230, 230, 235)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 11
        Button.ZIndex = 1003
        Button.Parent = PlayerScroll

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = Button

        table.insert(Connections, Button.MouseButton1Click:Connect(function()
            Whitelist[entity.Key] = not Whitelist[entity.Key]
            UpdateChamsColorsAndHighlights()
            RefreshEntityList()
        end))
    end

    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

task.spawn(function()
    while true do
        pcall(UpdateChamsColorsAndHighlights)
        task.wait(5)
    end
end)

local lastChamsUpdate = 0
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastChamsUpdate >= 0.5 then
        pcall(UpdateChamsColorsAndHighlights)
        lastChamsUpdate = now
    end
end))

table.insert(Connections, Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(UpdateChamsColorsAndHighlights)
    end)
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    local key = player.UserId
    if Highlights[key] then
        pcall(function() Highlights[key]:Destroy() end)
        Highlights[key] = nil
    end
    Whitelist[key] = nil
end))

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(Connections, player.CharacterAdded:Connect(function()
            task.wait(0.5)
            pcall(UpdateChamsColorsAndHighlights)
        end))
    end
end

task.spawn(function()
    while true do
        pcall(RefreshEntityList)
        task.wait(2)
    end
end)

-- Aimbot Logic
local function IsVisible(targetPart)
    if not targetPart then return false end
    
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("Head") then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {myCharacter, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    
    if not rayResult then return true end
    if rayResult.Instance and rayResult.Instance:IsDescendantOf(targetPart.Parent) then return true end
    
    return false
end

local function GetClosestTarget()
    local closestEntity = nil
    local shortestDistance = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myCharacter.HumanoidRootPart.Position

    local entities = GetValidEntities()
    for _, entity in ipairs(entities) do
        if not Whitelist[entity.Key] then
            local char = entity.Character
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                    local fovDist = (screenPoint - viewportCenter).Magnitude

                    if not Settings.FovEnabled or fovDist <= Settings.FOVRadius then
                        local dist3D = (head.Position - myPos).Magnitude
                        if dist3D < shortestDistance then
                            shortestDistance = dist3D
                            closestEntity = char
                        end
                    end
                end
            end
        end
    end

    return closestEntity
end

table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Settings.AimKey then Aiming = true end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.AimKey then Aiming = false end
end))

local function AutoShoot()
    if Settings.AutoShootEnabled then
        mouse1press()
        task.wait(0.05)
        mouse1release()
    end
end

local LastTarget = nil
local LockedOnTime = 0

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if Aiming and Settings.AimEnabled then
        local targetChar = GetClosestTarget()
        if targetChar and targetChar:FindFirstChild("Head") then
            local headPosition = targetChar.Head.Position
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, headPosition)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Smoothness)
            
            if Settings.AutoShootEnabled then
                if IsVisible(targetChar.Head) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(headPosition)
                    if onScreen then
                        local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                        local distance = (screenPoint - viewportCenter).Magnitude
                        
                        if distance < 50 then
                            if targetChar ~= LastTarget then
                                LastTarget = targetChar
                                LockedOnTime = tick()
                            elseif tick() - LockedOnTime >= 0.1 then
                                AutoShoot()
                                task.wait(0.1)
                            end
                        else
                            LastTarget = nil
                            LockedOnTime = 0
                        end
                    end
                else
                    LastTarget = nil
                    LockedOnTime = 0
                end
            end
        else
            LastTarget = nil
            LockedOnTime = 0
        end
    else
        LastTarget = nil
        LockedOnTime = 0
    end
end))
