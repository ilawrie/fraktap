-- ==========================================
-- WALLHACK MODULE
-- ==========================================
local Wallhack = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))

Wallhack.wallhackActive = false
Wallhack.highlightedAnimals = {}

local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local PART_COLOR = Color3.fromRGB(255, 176, 254)
local TRANSPARENCY = 0.6

-- Применить wallhack к модели животного
function Wallhack:applyToAnimal(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return end
    if self.highlightedAnimals[animalModel] then return end -- Уже обработано
    
    -- Добавить Humanoid если нет
    local humanoid = animalModel:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = Instance.new("Humanoid")
        humanoid.Parent = animalModel
    end
    
    -- Создать Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "WallhackHighlight"
    highlight.Adornee = animalModel
    highlight.FillColor = PART_COLOR
    highlight.OutlineColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = TRANSPARENCY
    highlight.OutlineTransparency = 0
    highlight.Parent = animalModel
    
    -- Изменить все части модели
    for _, part in ipairs(animalModel:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Material = Enum.Material.SmoothPlastic
                part.Color = PART_COLOR
                part.Transparency = TRANSPARENCY
            end)
        end
    end
    
    self.highlightedAnimals[animalModel] = {
        highlight = highlight,
        originalProperties = {}
    }
end

-- Удалить wallhack с модели животного
function Wallhack:removeFromAnimal(animalModel)
    if not animalModel then return end
    
    local data = self.highlightedAnimals[animalModel]
    if not data then return end
    
    -- Удалить Highlight
    if data.highlight and data.highlight.Parent then
        data.highlight:Destroy()
    end
    
    self.highlightedAnimals[animalModel] = nil
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
end

-- Остановить wallhack
function Wallhack:stop()
    self.wallhackActive = false
    
    -- Удалить wallhack со всех животных
    for animalModel, _ in pairs(self.highlightedAnimals) do
        self:removeFromAnimal(animalModel)
    end
    
    self.highlightedAnimals = {}
end

return Wallhack
