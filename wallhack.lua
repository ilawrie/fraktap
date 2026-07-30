-- ==========================================
-- WALLHACK MODULE (Clone-based ESP)
-- ==========================================
local Wallhack = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

Wallhack.wallhackActive = false
Wallhack.highlightedAnimals = {}
Wallhack.renderConnection = nil

local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local PART_COLOR = Color3.fromRGB(255, 176, 254)
local TRANSPARENCY = 0.6

-- Создать ESP клон для животного
function Wallhack:createESPClone(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return nil end
    
    -- Клонировать модель
    local espClone = animalModel:Clone()
    espClone.Name = animalModel.Name .. "_ESP"
    
    -- Настроить все части клона
    for _, part in ipairs(espClone:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = true
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
                part.Material = Enum.Material.SmoothPlastic
                part.Color = PART_COLOR
                part.Transparency = TRANSPARENCY
                part.CastShadow = false
            end)
        elseif part:IsA("Decal") or part:IsA("Texture") or part:IsA("SurfaceGui") then
            -- Удалить декали и текстуры для чистоты
            part:Destroy()
        elseif part:IsA("Script") or part:IsA("LocalScript") or part:IsA("ModuleScript") then
            -- Удалить скрипты
            part:Destroy()
        end
    end
    
    -- Удалить AnimationController если есть
    local animController = espClone:FindFirstChildOfClass("AnimationController")
    if animController then
        animController:Destroy()
    end
    
    -- Удалить Humanoid если есть
    local humanoid = espClone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:Destroy()
    end
    
    -- Создать Humanoid для Highlight
    local newHumanoid = Instance.new("Humanoid")
    newHumanoid.RequiresNeck = false
    newHumanoid.BreakJointsOnDeath = false
    newHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    newHumanoid.Health = 100
    newHumanoid.MaxHealth = 100
    newHumanoid.Parent = espClone
    
    -- Создать Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "WallhackHighlight"
    highlight.Adornee = espClone
    highlight.FillColor = PART_COLOR
    highlight.OutlineColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = TRANSPARENCY
    highlight.OutlineTransparency = 0
    highlight.Parent = espClone
    
    espClone.Parent = Workspace
    
    return espClone
end

-- Применить wallhack к модели животного
function Wallhack:applyToAnimal(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return end
    if self.highlightedAnimals[animalModel] then return end -- Уже обработано
    
    -- Создать ESP клон
    local espClone = self:createESPClone(animalModel)
    if not espClone then return end
    
    self.highlightedAnimals[animalModel] = {
        clone = espClone,
        original = animalModel
    }
end

-- Удалить wallhack с модели животного
function Wallhack:removeFromAnimal(animalModel)
    if not animalModel then return end
    
    local data = self.highlightedAnimals[animalModel]
    if not data then return end
    
    -- Удалить клон
    if data.clone and data.clone.Parent then
        data.clone:Destroy()
    end
    
    self.highlightedAnimals[animalModel] = nil
end

-- Обновить позиции клонов (RenderStepped)
function Wallhack:updateClones()
    for original, data in pairs(self.highlightedAnimals) do
        if original and original.Parent and data.clone and data.clone.Parent then
            -- Проверить что оригинал существует
            if original:IsDescendantOf(Workspace) then
                pcall(function()
                    -- Обновить позицию клона
                    if original.PrimaryPart then
                        data.clone:PivotTo(original:GetPivot())
                    elseif original:FindFirstChild("HumanoidRootPart") then
                        data.clone:PivotTo(original.HumanoidRootPart.CFrame)
                    elseif original:FindFirstChild("Torso_Main") then
                        data.clone:PivotTo(original.Torso_Main.CFrame)
                    end
                end)
            else
                -- Оригинал удалён, удалить клон
                self:removeFromAnimal(original)
            end
        else
            -- Клон или оригинал удалён
            self:removeFromAnimal(original)
        end
    end
end

-- Найти все модели животных
function Wallhack:findAllAnimals()
    local animals = {}
    
    local animalsFolder = Workspace:FindFirstChild("Gameplay")
    if animalsFolder then
        animalsFolder = animalsFolder:FindFirstChild("Dynamic")
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Animals")
            if animalsFolder then
                for _, child in ipairs(animalsFolder:GetChildren()) do
                    if child:IsA("Model") then
                        table.insert(animals, child)
                    end
                end
            end
        end
    end
    
    return animals
end

-- Запустить wallhack
function Wallhack:start()
    self.wallhackActive = true
    
    -- Применить ко всем текущим животным
    for _, animal in ipairs(self:findAllAnimals()) do
        self:applyToAnimal(animal)
    end
    
    -- Следить за новыми животными
    task.spawn(function()
        local animalsFolder = Workspace:FindFirstChild("Gameplay")
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Dynamic")
            if animalsFolder then
                animalsFolder = animalsFolder:FindFirstChild("Animals")
                if animalsFolder then
                    animalsFolder.ChildAdded:Connect(function(child)
                        if self.wallhackActive and child:IsA("Model") then
                            task.wait(0.1) -- Подождать пока модель загрузится
                            self:applyToAnimal(child)
                        end
                    end)
                    
                    animalsFolder.ChildRemoved:Connect(function(child)
                        self:removeFromAnimal(child)
                    end)
                end
            end
        end
    end)
    
    -- Запустить RenderStepped для обновления позиций клонов
    if not self.renderConnection then
        self.renderConnection = RunService.RenderStepped:Connect(function()
            if self.wallhackActive then
                self:updateClones()
            end
        end)
    end
end

-- Остановить wallhack
function Wallhack:stop()
    self.wallhackActive = false
    
    -- Удалить wallhack со всех животных
    for animalModel, _ in pairs(self.highlightedAnimals) do
        self:removeFromAnimal(animalModel)
    end
    
    self.highlightedAnimals = {}
    
    -- Отключить RenderStepped
    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection = nil
    end
end

return Wallhack
