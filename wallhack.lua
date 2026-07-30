-- ==========================================
-- WALLHACK MODULE
-- ==========================================
local Wallhack = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

Wallhack.wallhackActive = false
Wallhack.highlightedAnimals = {}

local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local PART_COLOR = Color3.fromRGB(255, 162, 222)

-- Применить wallhack к модели животного
function Wallhack:applyToAnimal(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return end
    if self.highlightedAnimals[animalModel] then return end -- Уже обработано
    
    local originalParts = {}
    local clonedParts = {}
    
    -- Обработать все части модели
    for _, part in ipairs(animalModel:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                -- Сохранить оригинальные свойства
                table.insert(originalParts, {
                    part = part,
                    originalMaterial = part.Material,
                    originalTransparency = part.Transparency,
                    originalReflectance = part.Reflectance
                })
                
                -- Установить оригинальную часть как невидимое стекло
                part.Material = Enum.Material.Glass
                part.Reflectance = 1
                part.Transparency = 1
                
                -- Создать цветную копию
                local clone = Instance.new("Part")
                clone.Name = "WallhackClone"
                clone.Size = part.Size
                clone.CFrame = part.CFrame
                clone.Color = PART_COLOR
                clone.Material = Enum.Material.SmoothPlastic
                clone.Reflectance = 0
                clone.Transparency = 0.4
                clone.CanCollide = false
                clone.Anchored = false
                clone.Parent = part
                
                -- Привязать копию к оригиналу с помощью Weld
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = part
                weld.Part1 = clone
                weld.Parent = clone
                
                table.insert(clonedParts, clone)
            end)
        end
    end
    
    -- Создать Highlight для обводки
    local highlight = Instance.new("Highlight")
    highlight.Name = "WallhackHighlight"
    highlight.Adornee = animalModel
    highlight.FillColor = PART_COLOR
    highlight.OutlineColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = 1 -- Прозрачная заливка, только обводка
    highlight.OutlineTransparency = 0
    highlight.Parent = animalModel
    
    self.highlightedAnimals[animalModel] = {
        highlight = highlight,
        originalParts = originalParts,
        clonedParts = clonedParts
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
    
    -- Восстановить оригинальные свойства частей
    for _, partData in ipairs(data.originalParts) do
        if partData.part and partData.part.Parent then
            pcall(function()
                partData.part.Material = partData.originalMaterial
                partData.part.Transparency = partData.originalTransparency
                partData.part.Reflectance = partData.originalReflectance
            end)
        end
    end
    
    -- Удалить клонированные части
    for _, clone in ipairs(data.clonedParts) do
        if clone and clone.Parent then
            clone:Destroy()
        end
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
