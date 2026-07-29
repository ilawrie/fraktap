-- ==========================================
-- SET KEEPER MODULE
-- ==========================================
local SetKeeper = {}

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local NetRemote = ReplicatedStorage:WaitForChild("Net")

SetKeeper.useHunterTicketActive = false

-- Потратить билет на охотника (хранителя)
function SetKeeper:spendHunterTicket()
    pcall(function()
        NetRemote:FireServer("Ticket.spendHunterTicket")
    end)
end

return SetKeeper
