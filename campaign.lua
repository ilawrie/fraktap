local Campaign = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

Campaign.ITEMS = {
    {name = "Basket", count = 8},
    {name = "Binoculars", count = 8},
    {name = "Briefcase", count = 9},
    {name = "Cookie", count = 8},
    {name = "Diamond", count = 6},
    {name = "Egg", count = 8},
    {name = "Map", count = 6},
    {name = "Maracas", count = 10},
    {name = "MarshmallowStick", count = 7},
    {name = "Newspaper", count = 9},
    {name = "PaintTube", count = 8},
    {name = "Passport", count = 10},
    {name = "Plushie", count = 12},
    {name = "Scarab", count = 8},
    {name = "Seashell", count = 10},
    {name = "SkiBoot", count = 12},
    {name = "SubmarineToy", count = 5},
    {name = "SunScreen", count = 9},
    {name = "TrainingDart", count = 10},
}

Campaign.selectedItem = "Scarab"

function Campaign:getItemNames()
    local names = {}
    for _, item in ipairs(self.ITEMS) do
        table.insert(names, item.name)
    end
    return names
end

function Campaign:getItemData(itemName)
    for _, item in ipairs(self.ITEMS) do
        if item.name == itemName then
            return item
        end
    end
    return nil
end

function Campaign:collectSelectedItem()
    local itemData = self:getItemData(self.selectedItem)
    if not itemData then return end
    
    task.spawn(function()
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TryPickupCampaignItem")
            for i = 1, itemData.count do
                Event:FireServer(itemData.name .. i)
                task.wait(0.05)
            end
        end)
    end)
end

function Campaign:collectAllItems()
    task.spawn(function()
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TryPickupCampaignItem")
            for _, item in ipairs(self.ITEMS) do
                for i = 1, item.count do
                    Event:FireServer(item.name .. i)
                    task.wait(0.02)
                end
            end
        end)
    end)
end

return Campaign