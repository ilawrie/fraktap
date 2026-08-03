local Chams = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Workspace = cloneref(game:GetService("Workspace"))

Chams.chamsActive = false
Chams.highlightedAnimals = {}
Chams.connections = {}

local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_COLOR = Color3.fromRGB(255, 255, 255)

function Chams:applyToAnimal(animalModel)
    if not animalModel or not animalModel:IsA("Model") then return end
    if self.highlightedAnimals[animalModel] then return end

    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "ChamsHighlight"
        highlight.Adornee = animalModel
        highlight.OutlineColor = OUTLINE_COLOR
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.Parent = animalModel

        self.highlightedAnimals[animalModel] = highlight
    end)
end

function Chams:removeFromAnimal(animalModel)
    if not animalModel then return end

    local highlight = self.highlightedAnimals[animalModel]
    if highlight and highlight.Parent then
        pcall(function()
            highlight:Destroy()
        end)
    end

    self.highlightedAnimals[animalModel] = nil
end

function Chams:findAllAnimals()
    local animals = {}
    local animalsFolder = Workspace:FindFirstChild("Gameplay")
    
    if animalsFolder then
        animalsFolder = animalsFolder:FindFirstChild("Dynamic")
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Animals")
            if animalsFolder then
                for _, model in ipairs(animalsFolder:GetChildren()) do
                    if model:IsA("Model") then
                        table.insert(animals, model)
                    end
                end
            end
        end
    end

    return animals
end

function Chams:start()
    self.chamsActive = true

    for _, animal in ipairs(self:findAllAnimals()) do
        self:applyToAnimal(animal)
    }

    task.spawn(function()
        local animalsFolder = Workspace:FindFirstChild("Gameplay")
        if animalsFolder then
            animalsFolder = animalsFolder:FindFirstChild("Dynamic")
            if animalsFolder then
                animalsFolder = animalsFolder:FindFirstChild("Animals")
                if animalsFolder then
                    local addConn = animalsFolder.ChildAdded:Connect(function(child)
                        if self.chamsActive and child:IsA("Model") then
                            task.wait(0.05)
                            self:applyToAnimal(child)
                        end
                    end)

                    local removeConn = animalsFolder.ChildRemoved:Connect(function(child)
                        self:removeFromAnimal(child)
                    end)

                    table.insert(self.connections, addConn)
                    table.insert(self.connections, removeConn)
                end
            end
        end
    end)
end

function Chams:stop()
    self.chamsActive = false

    for _, connection in ipairs(self.connections) do
        if connection and connection.Connected then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    self.connections = {}

    for animalModel, _ in pairs(self.highlightedAnimals) do
        self:removeFromAnimal(animalModel)
    end

    self.highlightedAnimals = {}
end

function Chams:setOutlineColor(color)
    OUTLINE_COLOR = color
    for _, highlight in pairs(self.highlightedAnimals) do
        if highlight then
            highlight.OutlineColor = color
        end
    end
end

return Chams