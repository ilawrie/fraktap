-- ==========================================
-- CAMPAIGN UNLOCKER MODULE
-- ==========================================
local Campaign = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
-- Список всех предметов с их количеством
Campaign.ITEMS = {
    {name = "Scarab", count = 8},
    {name = "SunScreen", count = 9},
    {name = "Briefcase", count = 9},
    {name = "Seashell", count = 10},
    {name = "Newspaper", count = 9},
    {name = "Maracas", count = 10},
    {name = "SubmarineToy", count = 5},
    {name = "Painttube", count = 8},
    {name = "Map", count = 6},
    {name = "MarshmallowStick", count = 7},
    {name = "Plushie", count = 12},
    {name = "Passport", count = 10},
    {name = "Diamond", count = 6},
    {name = "Binoculars", count = 8},
    {name = "Egg", count = 8},
    {name = "Basket", count = 8},
    {name = "TrainingDart", count = 10},
    {name = "Cookie", count = 8},
    {name = "SkiBoot", count = 12}

    
}

Campaign.selectedItem = "Scarab"

-- Получить список названий предметов для dropdown
function Campaign:getItemNames()
    local names = {}
    for _, item in ipairs(self.ITEMS) do
        table.insert(names, item.name)
    end
    return names
end

-- Найти данные предмета по имени
function Campaign:getItemData(itemName)
    for _, item in ipairs(self.ITEMS) do
        if item.name == itemName then
            return item
        end
    end
    return nil
end

-- Собрать выбранный предмет
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

-- Собрать все предметы
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
