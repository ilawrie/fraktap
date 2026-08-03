local DestroyProps = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")

function DestroyProps:destroyAll()
    task.spawn(function()
        local mapsFolder = Workspace:FindFirstChild("Gameplay") 
            and Workspace.Gameplay:FindFirstChild("Dynamic") 
            and Workspace.Gameplay.Dynamic:FindFirstChild("Maps")

        if not mapsFolder then return end

        for _, map in ipairs(mapsFolder:GetChildren()) do
            local propsFolder = map:FindFirstChild("Gameplay") and map.Gameplay:FindFirstChild("Props")
            if propsFolder then
                local count = 0
                for _, obj in ipairs(propsFolder:GetChildren()) do
                    local cf = nil
                    
                    if obj:IsA("Model") then
                        local success, res = pcall(function() return obj:GetPivot() end)
                        if success then cf = res end
                    elseif obj:IsA("BasePart") then
                        cf = obj.CFrame
                    end

                    if cf then
                        pcall(function()
                            NetRemote:FireServer("Map.destroyProps", obj.Name, cf)
                        end)
                        count = count + 1
                        
                        if count % 3 == 0 then
                            task.wait(0.04)
                        end
                    end
                end
            end
        end
    end)
end

return DestroyProps