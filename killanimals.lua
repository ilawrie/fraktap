local KillAnimals = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")
local LocalPlayer = Players.LocalPlayer

function KillAnimals:killAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    NetRemote:FireServer("Ult.fire", hrp.Position)
                    NetRemote:FireServer("Shooting.ultDamage", player)
                end)
            end
        end
    end
end

return KillAnimals