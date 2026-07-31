-- ==========================================
-- SET ANIMAL MODULE
-- ==========================================
local SetAnimal = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")

SetAnimal.selectedAnimalName = nil -- По умолчанию ничего не выбрано
SetAnimal.useTicketActive = false

-- Список всех животных
SetAnimal.ANIMALS = {
    "ant", "anteater", "armadillo", "axolotl", "beaver", "bee", "capybara", 
    "chameleon", "cheetah", "chimpanzee", "cow", "crab", "crocodile", "deer", 
    "dodo", "donkey", "dromedary", "eagle", "elephant", "fennec", "fish", 
    "flamingo", "flyingsquirrel", "frog", "gianttortoise", "giraffe", "goat", 
    "goose", "gorilla", "hippopotamus", "horse", "kangaroo", "komododragon", 
    "lemur", "lion", "llama", "lynx", "mantaray", "meerkat", "miniaturehorse", 
    "mouse", "octopus", "orangutan", "ostrich", "owl", "panda", "peacock", 
    "penguin", "pig", "platypus", "polarbear", "rabbit", "rhinoceros", "rooster", 
    "scorpion", "seal", "snake", "spider", "spiderCrab", "squid", "tiger", 
    "toucan", "turtle", "walrus", "wolf", "zebra"
}

-- Установить выбранное животное
function SetAnimal:setSelectedAnimal(animalName)
    if table.find(self.ANIMALS, animalName) then
        self.selectedAnimalName = animalName
    end
end

-- Потратить билет на животное
function SetAnimal:spendAnimalTicket()
    if not self.selectedAnimalName then
        return false -- Ничего не выбрано
    end
    
    pcall(function()
        NetRemote:FireServer("Ticket.spendAnimalTicket", self.selectedAnimalName)
    end)
    
    return true -- Успешно отправлено
end

-- Получить текущее выбранное животное
function SetAnimal:getSelectedAnimal()
    return self.selectedAnimalName
end

return SetAnimal
