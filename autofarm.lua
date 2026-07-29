-- ==========================================
-- AUTO FARM MODULE
-- ==========================================
local AutoFarm = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")
local SpawnLocation = Workspace:WaitForChild("Lobby"):WaitForChild("Lobby"):WaitForChild("Visual"):WaitForChild("Props"):WaitForChild("SpawnLocation")
local ATTACH_OFFSET = CFrame.new(0, 0, 4)

-- State variables
AutoFarm.farmActive = false
AutoFarm.savedSpawnCFrame = nil
AutoFarm.currentHunter = nil
AutoFarm.cachedHunterRoot = nil
AutoFarm.isTaunting = false
AutoFarm.isAttached = false
AutoFarm.tauntTask = nil

local LocalPlayer = cloneref(game:GetService("Players")).LocalPlayer

-- Получить персонаж игрока
function AutoFarm:getCharacter()
    local char = LocalPlayer.Character
    if not char then
        return nil, nil, nil
    end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

-- Сбросить персонаж (убить)
function AutoFarm:resetCharacter()
    local _, _, hum = self:getCharacter()
    if hum then
        hum.Health = 0
    end
end

-- Получить корень охотника
function AutoFarm:getHunterRoot()
    if self.cachedHunterRoot and self.cachedHunterRoot.Parent and self.cachedHunterRoot:IsDescendantOf(Workspace) then
        return self.cachedHunterRoot
    end

    if not self.currentHunter then
        return nil
    end

    local hunterName = (typeof(self.currentHunter) == "Instance" and self.currentHunter:IsA("Player")) and self.currentHunter.Name or tostring(self.currentHunter)

    local Players = cloneref(game:GetService("Players"))
    local playerObj = Players:FindFirstChild(hunterName)
    if playerObj and playerObj.Character then
        local hrp = playerObj.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            self.cachedHunterRoot = hrp
            return hrp
        end
    end

    for _, obj in ipairs(getnilinstances()) do
        if obj.Name == hunterName and obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                self.cachedHunterRoot = hrp
                return hrp
            end
        end
    end

    return nil
end

-- Прикрепиться к охотнику
function AutoFarm:attachToHunter()
    local _, root = self:getCharacter()
    local hunterRoot = self:getHunterRoot()

    if root and hunterRoot then
        root.CFrame = hunterRoot.CFrame * ATTACH_OFFSET
        self.isAttached = true
        return true
    end

    self.isAttached = false
    return false
end

-- Сбросить состояние раунда
function AutoFarm:resetRoundState()
    self.isTaunting = false
    self.isAttached = false
    self.savedSpawnCFrame = nil
    self.currentHunter = nil
    self.cachedHunterRoot = nil

    if self.tauntTask then
        task.cancel(self.tauntTask)
        self.tauntTask = nil
    end

    local _, _, hum = self:getCharacter()
    if hum then
        hum.PlatformStand = false
    end
end

-- Начать цикл дразнения охотника
function AutoFarm:startTauntLoop()
    self.isTaunting = true

    if self.tauntTask then
        task.cancel(self.tauntTask)
    end

    self.tauntTask = task.spawn(function()
        while self.isTaunting and self.farmActive do
            pcall(function()
                NetRemote:FireServer("Taunt.play")
            end)
            task.wait(2)
        end
    end)
end

-- RenderStepped цикл для привязки
function AutoFarm:setupRenderLoop()
    RunService.RenderStepped:Connect(function()
        if not self.farmActive or not self.isAttached then
            return
        end

        local _, myRoot, myHum = self:getCharacter()
        local hunterRoot = self:getHunterRoot()

        if myRoot and myHum and hunterRoot then
            myHum.PlatformStand = true
            myRoot.CFrame = hunterRoot.CFrame * ATTACH_OFFSET
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

return AutoFarm
