-- ==========================================
-- AUTO CHEST MODULE
-- ==========================================
local AutoChest = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

AutoChest.autochestActive = false

-- Начать цикл сбора сундуков
function AutoChest:start()
    self.autochestActive = true
    
    task.spawn(function()
        local Event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TryClaimParkourChest")
        
        while true do
            task.wait(1.0)
            if self.autochestActive then
                pcall(function()
                    Event:FireServer("parkourChestSmall")
                    task.wait(0.2)
                    Event:FireServer("parkourChestBig")
                end)
            else
                break
            end
        end
    end)
end

-- Остановить цикл сбора сундуков
function AutoChest:stop()
    self.autochestActive = false
end

-- Обработка события открытия сундука (возвращает функцию для WindUI)
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
