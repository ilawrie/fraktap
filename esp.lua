-- ==========================================
-- ESP MODULE (Box-based)
-- ==========================================
local ESP = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local workspace = cloneref(game:GetService("Workspace"))
local run = cloneref(game:GetService("RunService"))
local http_service = cloneref(game:GetService("HttpService"))
local players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local vec2 = Vector2.new
local dim2 = UDim2.new
local dim_offset = UDim2.fromOffset
local rgb = Color3.fromRGB
local camera = workspace.CurrentCamera

-- Configuration flags
ESP.flags = {
    ["Enabled"] = true,
    ["Boxes"] = true,
    ["Box_Color"] = { Color = rgb(255, 255, 255) },
}

-- State tracking
ESP.entities = {}
ESP.screengui = Instance.new("ScreenGui", gethui())
ESP.cache = Instance.new("ScreenGui", gethui())
ESP.connections = {}
ESP.roundActive = true
ESP.trackedAnimals = {} -- Maps animal models to player names
ESP.initialized = false -- Track if we've already initialized event handlers

-- Font registration
local fonts = {}; do
    function Register_Font(Name, Weight, Style, Asset)
        if not isfile(Asset.Id) then
            writefile(Asset.Id, Asset.Font)
        end
        if isfile(Name .. ".font") then
            delfile(Name .. ".font")
        end
        local Data = {
            name = Name,
            faces = {{ name = "Normal", weight = Weight, style = Style, assetId = getcustomasset(Asset.Id) }},
        }
        writefile(Name .. ".font", http_service:JSONEncode(Data))
        return getcustomasset(Name .. ".font")
    end

    local ProggyTiny = Register_Font("adwdawdwadadwadawdawdawdawd!", 100, "Normal", {
        Id = "ProggyTinyyyy.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyTiny.ttf"),
    })

    fonts = {
        main = Font.new(ProggyTiny, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    }
end

-- Setup ScreenGui
ESP.screengui.IgnoreGuiInset = true
ESP.screengui.Name = "\0"
ESP.cache.Enabled = false

-- Get screen position from world position
function ESP:get_screen_pos(world_position)
    local viewport_size = camera.ViewportSize
    local local_position = camera.CFrame:pointToObjectSpace(world_position) 
    
    local aspect_ratio = viewport_size.x / viewport_size.y
    local half_height = -local_position.z * math.tan(math.rad(camera.FieldOfView / 2))
    local half_width = aspect_ratio * half_height
    
    local far_plane_corner = Vector3.new(-half_width, half_height, local_position.z)
    local relative_position = local_position - far_plane_corner

    local screen_x = relative_position.x / (half_width * 2)
    local screen_y = -relative_position.y / (half_height * 2)

    local is_on_screen = -local_position.z > 0 and screen_x >= 0 and screen_x <= 1 and screen_y >= 0 and screen_y <= 1
    return Vector3.new(screen_x * viewport_size.x, screen_y * viewport_size.y, -local_position.z), is_on_screen
end

-- Calculate box dimensions
function ESP:box_solve(torso)
    if not torso then return nil, nil, nil end
    
    local ViewportTop = torso.Position + (torso.CFrame.UpVector * 1.8) + camera.CFrame.UpVector
    local ViewportBottom = torso.Position - (torso.CFrame.UpVector * 2.5) - camera.CFrame.UpVector
    local Top, TopIsRendered = ESP:get_screen_pos(ViewportTop)
    local Bottom, BottomIsRendered = ESP:get_screen_pos(ViewportBottom)
    local Width = math.max(math.floor(math.abs(Top.X - Bottom.X)), 3)
    local Height = math.max(math.floor(math.max(math.abs(Bottom.Y - Top.Y), Width / 2)), 3)
    local BoxSize = Vector2.new(math.floor(math.max(Height / 1.5, Width)), Height)
    local BoxPosition = Vector2.new(math.floor(Top.X * 0.5 + Bottom.X * 0.5 - BoxSize.X * 0.5), math.floor(math.min(Top.Y, Bottom.Y)))
    
    return BoxSize, BoxPosition, TopIsRendered
end

-- Create UI element
function ESP:create(instance, options)
    local ins = Instance.new(instance) 
    for prop, value in options do ins[prop] = value end
    return ins 
end

-- Create ESP object for an animal
function ESP:create_object(animalModel, playerName)
    if not animalModel or not playerName then return end
    
    local key = animalModel:GetFullName()
    ESP.entities[key] = { objects = {}, info = {}, playerName = playerName } 
    local data = ESP.entities[key] 
    local objects = data.objects

    objects["holder"] = ESP:create("Frame", { 
        Parent = ESP.screengui, 
        Name = "\0", 
        BackgroundTransparency = 1, 
        Position = dim2(0, 0, 0, 0), 
        Size = dim2(0, 0, 0, 0), 
        BorderSizePixel = 0 
    })
    
    objects["box_outline"] = ESP:create("UIStroke", { 
        Parent = objects["holder"], 
        LineJoinMode = Enum.LineJoinMode.Miter 
    })
    
    objects["box_handler"] = ESP:create("Frame", { 
        Parent = objects["holder"], 
        Name = "\0", 
        BackgroundTransparency = 1, 
        Position = dim2(0, 1, 0, 1), 
        Size = dim2(1, -2, 1, -2), 
        BorderSizePixel = 0 
    })
    
    objects["box_color"] = ESP:create("UIStroke", { 
        Color = ESP.flags["Box_Color"].Color, 
        LineJoinMode = Enum.LineJoinMode.Miter, 
        Name = "\0", 
        Parent = objects["box_handler"] 
    })
    
    objects["outline"] = ESP:create("Frame", { 
        Parent = objects["box_handler"], 
        Name = "\0", 
        BackgroundTransparency = 1, 
        Position = dim2(0, 1, 0, 1), 
        Size = dim2(1, -2, 1, -2), 
        BorderSizePixel = 0 
    })
    
    ESP:create("UIStroke", { 
        Parent = objects["outline"], 
        LineJoinMode = Enum.LineJoinMode.Miter 
    })

    -- Find HumanoidRootPart
    data.info.rootpart = animalModel:FindFirstChild("HumanoidRootPart")
    if data.info.rootpart then
        data.info.humanoid = animalModel:FindFirstChildOfClass("Humanoid")
    end
end

-- Remove ESP object
function ESP:remove_object(animalModel)
    if not animalModel then return end
    
    local key = animalModel:GetFullName()
    local holder = ESP.entities[key]
    if not holder then return end 
    
    if holder.objects["holder"] then
        holder.objects["holder"]:Destroy() 
    end
    
    ESP.entities[key] = nil
    ESP.trackedAnimals[animalModel] = nil
end

-- Refresh ESP visibility and colors
function ESP:refresh_elements()
    for key, data in pairs(ESP.entities) do 
        if not data or not data.objects then continue end
        
        local objects = data.objects
        local holder = objects["holder"]
        if not holder then continue end
        
        holder.Parent = ESP.flags["Enabled"] and ESP.screengui or ESP.cache
        objects["box_handler"].Parent = ESP.flags["Boxes"] and objects["holder"] or ESP.cache
        objects["box_outline"].Parent = ESP.flags["Boxes"] and objects["holder"] or ESP.cache
        objects["box_color"].Color = ESP.flags["Box_Color"].Color 
    end
end

-- Main render loop
function ESP:start_render()
    ESP.connection = run.RenderStepped:Connect(function()
        if not ESP.flags["Enabled"] then return end

        for key, data in pairs(ESP.entities) do 
            if not data or not data.objects then continue end
            
            local rootpart = data.info.rootpart
            local humanoid = data.info.humanoid

            if not (rootpart and humanoid and rootpart.Parent) then 
                -- Animal was destroyed, remove ESP
                ESP:remove_object(rootpart and rootpart.Parent or nil)
                continue 
            end
            
            local objects = data.objects 
            
            local box_size, box_pos, on_screen = ESP:box_solve(rootpart)
            if not box_size then continue end
            
            local holder = objects["holder"]
            if holder.Visible ~= on_screen then holder.Visible = on_screen end 
            
            if not on_screen then continue end 
            
            local pos = dim_offset(box_pos.X, box_pos.Y)
            if pos ~= holder.Position then holder.Position = pos end 
            
            local size = dim_offset(box_size.X, box_size.Y)
            if size ~= holder.Size then holder.Size = size end 
        end
    end)
end

-- Monitor animal folder for new animals (used as backup if PlayerStateEvent doesn't trigger)
-- function ESP:monitor_animal_folder()
--     task.spawn(function()
--         local animalsFolder = workspace:FindFirstChild("Gameplay")
--         if animalsFolder then
--             animalsFolder = animalsFolder:FindFirstChild("Dynamic")
--             if animalsFolder then
--                 animalsFolder = animalsFolder:FindFirstChild("Animals")
--                 if animalsFolder then
--                     animalsFolder.ChildAdded:Connect(function(child)
--                         if child:IsA("Model") then
--                             task.wait(0.1)
--                             -- Check if this animal is in killexploit tracking
--                             local KillExploit = require(script.Parent:FindFirstChild("killexploit") or ReplicatedStorage:FindFirstChild("killexploit"))
--                             for playerName, _ in pairs(KillExploit.activeAnimalsData) do
--                                 local player = players:FindFirstChild(playerName)
--                                 if player and player.Character == child then
--                                     ESP:create_object(child, playerName)
--                                     ESP.trackedAnimals[child] = playerName
--                                     break
--                                 end
--                             end
--                         end
--                     end)
--                     
--                     animalsFolder.ChildRemoved:Connect(function(child)
--                         ESP:remove_object(child)
--                     end)
--                 end
--             end
--         end
--     end)
-- end

-- Detect round end and clear boxes
function ESP:monitor_round_state()
    local NetRemote = ReplicatedStorage:WaitForChild("Net")
    
    NetRemote.OnClientEvent:Connect(function(eventsList)
        if type(eventsList) ~= "table" then return end

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
                local newState = args[2]
                if newState == "award" then
                    -- Round ended, clear all ESP boxes
                    ESP:clear_all()
                    ESP.roundActive = false
                elseif newState == "warmup" or newState == "active" then
                    ESP.roundActive = true
                end
            end
        end
    end)
end

-- Clear all ESP boxes
function ESP:clear_all()
    for key, data in pairs(ESP.entities) do
        if data and data.objects and data.objects["holder"] then
            data.objects["holder"]:Destroy()
        end
    end
    ESP.entities = {}
    ESP.trackedAnimals = {}
end

-- Connect to PlayerStateEvent to track animal assignments
function ESP:connect_to_player_state_events()
    task.spawn(function()
        local PlayerStateEvent = ReplicatedStorage:WaitForChild("iKomi"):WaitForChild("Modules"):WaitForChild("States"):WaitForChild("Player"):WaitForChild("StateRemoteEvent")
        
        PlayerStateEvent.OnClientEvent:Connect(function(targetPlayer, key, animalName)
            if key == "CurrentAnimal" and targetPlayer ~= players.LocalPlayer then
                if animalName ~= nil and targetPlayer.Character then
                    -- Animal was assigned, find the model
                    task.wait(0.05)
                    local animalModel = targetPlayer.Character
                    if animalModel and not ESP.trackedAnimals[animalModel] then
                        ESP:create_object(animalModel, targetPlayer.Name)
                        ESP.trackedAnimals[animalModel] = targetPlayer.Name
                    end
                else
                    -- Animal was unassigned or player lost their animal
                    if targetPlayer.Character then
                        ESP:remove_object(targetPlayer.Character)
                    end
                end
            end
        end)
    end)
end

-- Initialize ESP
function ESP:initialize()
    -- Only initialize event handlers once
    if ESP.initialized then
        ESP:refresh_elements()
        return
    end
    
    ESP.initialized = true
    
    -- Start render loop
    ESP:start_render()
    
    -- Connect to PlayerStateEvent for real-time animal assignment tracking
    ESP:connect_to_player_state_events()
    
    -- Monitor round state
    ESP:monitor_round_state()
    
    task.wait()
    ESP:refresh_elements()
end

return ESP
