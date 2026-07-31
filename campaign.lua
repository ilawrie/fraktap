-- ==========================================
-- CAMPAIGN UNLOCKER MODULE
-- ==========================================
local Campaign = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

-- Список всех предметов с их количеством
Campaign.ITEMS = {
    {name = "scarab", count = 8},
    {name = "sunscreen", count = 9},
    {name = "briefcase", count = 9},
    {name = "seashell", count = 10},
    {name = "newspaper", count = 9},
    {name = "maracas", count = 10},
    {name = "submarinetoy", count = 5},
    {name = "painttube", count = 8},
    {name = "map", count = 6},
    {name = "marshmallowstick", count = 7},
    {name = "plushie", count = 12},
    {name = "passport", count = 10},
    {name = "diamond", count = 6},
    {name = "binoculars", count = 8},
    {name = "egg", count = 8},
    {name = "basket", count = 8},
    {name = "trainingdart", count = 10},
    {name = "cookie", count = 8},
    {name = "skiBoot", count = 12}
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
