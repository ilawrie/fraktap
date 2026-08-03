local AutoChest = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))

AutoChest.autochestActive = false

local function getBigChestTimer()
    local success, timer = pcall(function()
        return Workspace._Static.ParkourChests["\226\155\147\239\184\143 ParkourChest (big)"].TimerPart.SurfaceGui["\240\159\148\151 ParkourChestTimer"]
    end)
    return success and timer or nil
end

local function getSmallChestTimer()
    local success, timer = pcall(function()
        return Workspace._Static.ParkourChests["\226\155\147\239\184\143 ParkourChest (small)"].TimerPart.SurfaceGui["\240\159\148\151 ParkourChestTimer"]
    end)
    return success and timer or nil
end

local function isChestAvailable(timerLabel)
    if not timerLabel then return false end
    
    local success, text = pcall(function()
        return timerLabel.Text
    end)
    
    if not success or not text then return false end
    
    return text:lower():find("claim") ~= nil or text == ""
end

function AutoChest:start()
    self.autochestActive = true
    
    task.spawn(function()
        local Event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TryClaimParkourChest")
        
        while self.autochestActive do
            task.wait(0.5)
            
            if self.autochestActive then
                local smallTimer = getSmallChestTimer()
                if isChestAvailable(smallTimer) then
                    pcall(function()
                        Event:FireServer("parkourChestSmall")
                    end)
                end
                
                task.wait(0.1)
                
                local bigTimer = getBigChestTimer()
                if isChestAvailable(bigTimer) then
                    pcall(function()
                        Event:FireServer("parkourChestBig")
                    end)
                end
            else
                break
            end
        end
    end)
end

function AutoChest:stop()
    self.autochestActive = false
end

function AutoChest:setupChestEventListener(WindUI)
    task.spawn(function()
        local success, eventPath = pcall(function()
            return ReplicatedStorage:WaitForChild("iKomi"):WaitForChild("Modules"):WaitForChild("Events"):WaitForChild("Owner"):WaitForChild("RemoteEvent")
        end)
        
        if success and eventPath then
            eventPath.OnClientEvent:Connect(function(actionType, data)
                if actionType == "OnParkourChestClaimed" and type(data) == "table" then
                    local chestName = data.chestName
                    local rewardName = data.rewardName
                    
                    local title = "Chest"
                    if chestName == "parkourChestBig" then
                        title = "Big Chest"
                    elseif chestName == "parkourChestSmall" then
                        title = "Small Chest"
                    end
                    
                    WindUI:Notify({
                        Title = title,
                        Content = "You got: " .. tostring(rewardName),
                        Icon = "solar:bell-bold",
                        Duration = 4,
                        CanClose = true,
                    })
                end
            end)
        end
    end)
end

return AutoChest