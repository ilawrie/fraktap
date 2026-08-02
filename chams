-- ==========================================
-- CHAMS MODULE
-- ==========================================
local Chams = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

Chams.chamsActive = false
Chams.highlightedAnimals = {}
Chams.animalsFolder = nil
Chams.connections = {}

local HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 255, 255)

-- Получить папку с животными
function Chams:getAnimalsFolder()
    if not self.animalsFolder or not self.animalsFolder.Parent then
        local gameplay = Workspace:FindFirstChild("Gameplay")
        if gameplay then
            local dynamic = gameplay:FindFirstChild("Dynamic")
            if dynamic then
                self.animalsFolder = dynamic:FindFirstChild("Animals")
            end
        end
    end
    return self.animalsFolder
end

-- Применить Chams к модели животного
function Chams:applyToAnimal(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return end
    if self.highlightedAnimals[animalModel] then return end -- Уже обработано

    pcall(function()
        -- Создать Highlight для обводки
        local highlight = Instance.new("Highlight")
        highlight.Name = "ChamsHighlight"
        highlight.Adornee = animalModel
        highlight.FillColor = HIGHLIGHT_FILL_COLOR
        highlight.OutlineColor = HIGHLIGHT_COLOR
        highlight.FillTransparency = 0.5 -- Полупрозрачная заливка
        highlight.OutlineTransparency = 0
        highlight.Parent = animalModel

        self.highlightedAnimals[animalModel] = {
            highlight = highlight
        }
    end)
end

-- Удалить Chams с модели животного
function Chams:removeFromAnimal(animalModel)
    if not animalModel then return end

    local data = self.highlightedAnimals[animalModel]
    if not data then return end

    -- Удалить Highlight
    if data.highlight and data.highlight.Parent then
        pcall(function()
            data.highlight:Destroy()
        end)
    end

    self.highlightedAnimals[animalModel] = nil
end

-- Найти все папки скинов и животных внутри них
function Chams:findAllAnimals()
    local animals = {}

    local animalsFolder = self:getAnimalsFolder()
    if not animalsFolder then return animals end

    -- Итерировать по всем папкам скинов (Default, Thug, Artist и т.д.)
    for _, skinFolder in ipairs(animalsFolder:GetChildren()) do
        if skinFolder:IsA("Folder") then
            -- Итерировать по всем моделям животных внутри папки скина
            for _, animalModel in ipairs(skinFolder:GetChildren()) do
                if animalModel:IsA("Model") then
                    table.insert(animals, animalModel)
                end
            end
        end
    end

    return animals
end

-- Запустить Chams
function Chams:start()
    self.chamsActive = true

    -- Применить ко всем текущим животным
    for _, animal in ipairs(self:findAllAnimals()) do
        self:applyToAnimal(animal)
    end

    -- Следить за новыми животными
    task.spawn(function()
        local animalsFolder = self:getAnimalsFolder()
        if not animalsFolder then return end

        -- Для каждой папки скина
        for _, skinFolder in ipairs(animalsFolder:GetChildren()) do
            if skinFolder:IsA("Folder") then
                -- Отслеживать новых животных в папке скина
                local childAddedConn = skinFolder.ChildAdded:Connect(function(child)
                    if self.chamsActive and child:IsA("Model") then
                        task.wait(0.1) -- Подождать пока модель загрузится
                        self:applyToAnimal(child)
                    end
                end)

                local childRemovedConn = skinFolder.ChildRemoved:Connect(function(child)
                    self:removeFromAnimal(child)
                end)

                table.insert(self.connections, childAddedConn)
                table.insert(self.connections, childRemovedConn)
            end
        end

        -- Следить за новыми папками скинов
        local skinFolderConn = animalsFolder.ChildAdded:Connect(function(skinFolder)
            if self.chamsActive and skinFolder:IsA("Folder") then
                task.wait(0.1)

                -- Подключить события для новой папки скина
                local childAddedConn = skinFolder.ChildAdded:Connect(function(child)
                    if self.chamsActive and child:IsA("Model") then
                        task.wait(0.1)
                        self:applyToAnimal(child)
                    end
                end)

                local childRemovedConn = skinFolder.ChildRemoved:Connect(function(child)
                    self:removeFromAnimal(child)
                end)

                table.insert(self.connections, childAddedConn)
                table.insert(self.connections, childRemovedConn)

                -- Применить ко всем существующим животным в новой папке скина
                for _, animal in ipairs(skinFolder:GetChildren()) do
                    if animal:IsA("Model") then
                        self:applyToAnimal(animal)
                    end
                end
            end
        end)

        table.insert(self.connections, skinFolderConn)
    end)
end

-- Остановить Chams
function Chams:stop()
    self.chamsActive = false

    -- Удалить все соединения событий
    for _, connection in ipairs(self.connections) do
        if connection and connection.Connected then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    self.connections = {}

    -- Удалить Chams со всех животных
    for animalModel, _ in pairs(self.highlightedAnimals) do
        self:removeFromAnimal(animalModel)
    end

    self.highlightedAnimals = {}
end

-- Изменить цвет контура
function Chams:setOutlineColor(color)
    HIGHLIGHT_COLOR = color
    for _, data in pairs(self.highlightedAnimals) do
        if data.highlight then
            data.highlight.OutlineColor = color
        end
    end
end

-- Изменить цвет заливки
function Chams:setFillColor(color)
    HIGHLIGHT_FILL_COLOR = color
    for _, data in pairs(self.highlightedAnimals) do
        if data.highlight then
            data.highlight.FillColor = color
        end
    end
end

return Chams
