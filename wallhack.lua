-- ==========================================
-- WALLHACK MODULE - ANIMAL VISUALS
-- ==========================================
local Wallhack = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

Wallhack.wallhackActive = false
Wallhack.wallhackedAnimals = {}
Wallhack.outlineConnection = nil
Wallhack.selectionBoxes = {}

-- Цвет для животных (фиолетово-розовый ближе к белому)
local WALLHACK_COLOR = Color3.fromRGB(200, 150, 200)

-- Прозрачность
local WALLHACK_TRANSPARENCY = 0.5

-- Цвет outline (белый)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)

-- Функция для применения wallhack эффекта на модель
local function applyWallhackToModel(model)
    if not model or not model:IsDescendantOf(Workspace) then
        return
    end

    -- Проходим по всем частям модели
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Пропускаем RootPart и невидимые части - оставляем их невидимыми
            if part.Name == "HumanoidRootPart" or part.Name == "Root" or part.Transparency == 1 then
                if not part:GetAttribute("OriginalTransparency") then
                    part:SetAttribute("OriginalTransparency", part.Transparency)
                end
                part:SetAttribute("IsRootPart", true)
                goto continue
            end

            -- Сохраняем оригинальные свойства
            if not part:GetAttribute("OriginalColor") then
                part:SetAttribute("OriginalColor", part.Color)
                part:SetAttribute("OriginalTransparency", part.Transparency)
            end

            -- Применяем wallhack эффект
            pcall(function()
                part.Color = WALLHACK_COLOR
                part.Transparency = WALLHACK_TRANSPARENCY
            end)

            -- Создаем SelectionBox для outline эффекта
            if not Wallhack.selectionBoxes[part] then
                local selectionBox = Instance.new("SelectionBox")
                selectionBox.Adornee = part
                selectionBox.Color3 = OUTLINE_COLOR
                selectionBox.LineThickness = 0.05
                selectionBox.Parent = part
                
                Wallhack.selectionBoxes[part] = selectionBox
            end

            ::continue::
        end
    end

    -- Добавляем модель в отслеживаемые
    Wallhack.wallhackedAnimals[model] = true
end

-- Функция для удаления wallhack эффекта
local function removeWallhackFromModel(model)
    if not model then return end

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local originalColor = part:GetAttribute("OriginalColor")
            local originalTransparency = part:GetAttribute("OriginalTransparency")

            if originalColor then
                pcall(function()
                    part.Color = originalColor
                end)
            end
            if originalTransparency ~= nil then
                part.Transparency = originalTransparency
            end

            -- Удаляем SelectionBox
            if Wallhack.selectionBoxes[part] then
                pcall(function()
                    Wallhack.selectionBoxes[part]:Destroy()
                end)
                Wallhack.selectionBoxes[part] = nil
            end

            part:SetAttribute("OriginalColor", nil)
            part:SetAttribute("OriginalTransparency", nil)
            part:SetAttribute("IsRootPart", nil)
        end
    end

    Wallhack.wallhackedAnimals[model] = nil
end

-- Запустить wallhack
function Wallhack:start()
    self.wallhackActive = true

    -- Применяем ко всем текущим животным
    local animalsFolder = Workspace:FindFirstChild("Gameplay")
    if animalsFolder then
        animalsFolder = animalsFolder:FindFirstChild("Dynamic")
    end
    if animalsFolder then
        animalsFolder = animalsFolder:FindFirstChild("Animals")
    end

    if animalsFolder then
        for _, animal in ipairs(animalsFolder:GetChildren()) do
            applyWallhackToModel(animal)
        end
    end

    -- Отслеживаем новых животных
    if self.outlineConnection then
        self.outlineConnection:Disconnect()
    end

    self.outlineConnection = RunService.Heartbeat:Connect(function()
        if not self.wallhackActive then return end

        local animalsFolder = Workspace:FindFirstChild("Gameplay")
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Dynamic")
        end
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Animals")
        end

        if animalsFolder then
            for _, animal in ipairs(animalsFolder:GetChildren()) do
                if not self.wallhackedAnimals[animal] then
                    applyWallhackToModel(animal)
                end

                -- Проверяем, не удалилось ли животное
                if not animal:IsDescendantOf(Workspace) then
                    removeWallhackFromModel(animal)
                end
            end
        end
    end)
end

-- Остановить wallhack
function Wallhack:stop()
    self.wallhackActive = false

    if self.outlineConnection then
        self.outlineConnection:Disconnect()
        self.outlineConnection = nil
    end

    -- Убираем эффект со всех животных
    for model, _ in pairs(self.wallhackedAnimals) do
        removeWallhackFromModel(model)
    end

    self.wallhackedAnimals = {}
    self.selectionBoxes = {}
end

return Wallhack
