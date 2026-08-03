local SetAnimal = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")

SetAnimal.selectedAnimalName = nil
SetAnimal.useTicketActive = false

SetAnimal.ANIMALS = {
    "ant", "anteater", "armadillo", "axolotl", "beaver", "bee", "blowfish", "capybara", "chameleon", "cheetah",
    "chimpanzee", "cow", "crab", "crocodile", "deer", "dodo", "donkey", "dromedary", "eagle", "elephant",
    "fennec", "fish", "flamingo", "flyingSquirrel", "frog", "giantTortoise", "giraffe", "goat", "goose", "gorilla",
    "hippopotamus", "horse", "kangaroo", "komodoDragon", "lemur", "lion", "llama", "lynx", "mantaRay", "meerkat",
    "miniatureHorse", "mouse", "octopus", "orangutan", "ostrich", "owl", "panda", "peacock", "penguin", "pig",
    "platypus", "polarBear", "rabbit", "rhino", "rooster", "scorpion", "seal", "snake", "spider", "spiderCrab",
    "squid", "tiger", "toucan", "turtle", "walrus", "wolf", "zebra"
}

function SetAnimal:setSelectedAnimal(animalName)
    if table.find(self.ANIMALS, animalName) then
        self.selectedAnimalName = animalName
    end
end

function SetAnimal:spendAnimalTicket()
    if not self.selectedAnimalName then
        return false
    end
    
    pcall(function()
        NetRemote:FireServer("Ticket.spendAnimalTicket", self.selectedAnimalName)
    end)
    
    return true
end

function SetAnimal:getSelectedAnimal()
    return self.selectedAnimalName
end

return SetAnimal