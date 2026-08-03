--[[
    Lunar X
    Copyright (c) 2026 nick (.weound)
    Licensed under the Non-Commercial Share-Alike License (see LICENSE in the repo root).
--]]

if getgenv().lib then
    if type(getgenv().lib.unld) == "function" then
        pcall(function() getgenv().lib.unld() end)
    elseif getgenv().lib.gui then
        pcall(function() getgenv().lib.gui:Destroy() end)
    end
    getgenv().lib = nil
end

-- Prevent double loading
if getgenv().LunarXLoaded then
    print("Lunar X already loaded, unloading previous instance...")
    return
end
getgenv().LunarXLoaded = true

print("init")
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/vaderpaste/refs/heads/main/library.lua"))()
local flgs = lib.flags
lib.directory = "LunarX-ot"

function lib:cfg_lst_upd()
    if not lib.cfg_hldr then return end
    local list = {}
    local dir = lib.directory .. "/configs/"
    if isfolder(dir) then
        for _, f in next, listfiles(dir) do
            local name = string.match(f, "([^/\\]+)%.cfg$")
            if name then table.insert(list, name) end
        end
    end
    lib.cfg_hldr:refresh_options(list)
end

local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local light = game:GetService("Lighting")
local rs = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local debris = game:GetService("Debris")
local http = game:GetService("HttpService")

local lp = plrs.LocalPlayer
local pgui = lp:FindFirstChild("PlayerGui")
local cam = ws.CurrentCamera
local mouse = lp:GetMouse()

local wpnmng = require(rs.Common.Managers.WeaponManager)
local wpnpkts = require(rs.Common.Packets.WeaponPackets)
local mdlmng = require(rs.Common.Managers.ModelsManager)
local qstpkts = require(rs.Common.Packets.QuestPackets)
local lvlrewpkts = require(rs.Common.Packets.LevelRewardPackets)
local dataclnt = require(lp.PlayerScripts.Start.Backend.DataClient)
local mngmpkts = require(rs.Common.Packets.MainGamePackets)
local wpnclnt = require(lp.PlayerScripts.Start.Game.WeaponClient)
local vwmdlclnt = require(lp.PlayerScripts.Start.Game.ViewmodelClient)
local char_mngr = require(rs.Common.Managers.CharacterManager)
local killeffmng = require(rs.Common.Managers.KillEffectManager)
local util_mngrs_fld = rs.Common.Managers.UtilityManagers
local tblmngr = require(util_mngrs_fld:WaitForChild("TableManager"))
local battlepasspkts = require(rs.Common.Packets.BattlepassPackets)
local killeffpkts = require(rs.Common.Packets.Replication.KillEffectPackets)
local bytenetrel = rs:WaitForChild('ByteNetReliable')

local function getchar() return lp.Character end
local function gethum() local c = getchar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getroot() local c = getchar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local _wpns = wpnmng.getWeapons()
for name, data in pairs(_wpns) do
    data._firerate = data.firerate
    data._damage = data.damage
    data._reloadTime = data.reloadTime
    data._magazine = data.magazine
end

local orig_vmshoot = vwmdlclnt.shoot
local orig_scope = wpnclnt.scope

local box_col = rgb(100, 255, 255)
local skel_col = rgb(255, 100, 255)
local name_col = rgb(255, 255, 255)
local dist_col = rgb(180, 180, 180)

local wpn_chams_col = rgb(255, 0, 0)
local wpn_chams_trans = 0
local arm_chams_col = rgb(0, 255, 0)
local arm_chams_trans = 0

local ckf_txt = ""

local st = {
    silent_target_part = nil,
    silent_target_player = nil,
    lastClickTime = 0
}

-- Friend list system
local friends_list = {}
local friend_chams_col = rgb(0, 255, 0)

local ws_en = false
local jp_en = false
local currtarg = nil
local cons = {}
local function connct(sig, cb) 
    local c = sig:Connect(cb)
    table.insert(cons, c)
    return c 
end

local function disc_all()
    for _, c in ipairs(cons) do pcall(function() c:Disconnect() end) end
    cons = {}
end

local function newdraw(t, props)
    local d, err = Drawing.new(t)
    if not d then return nil end
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function apply_wpn_mods()
    for name, data in pairs(_wpns) do
        data.firerate = flgs["no_shoot_delay"] and 9999 or data._firerate
        data.damage = data._damage
        data.reloadTime = flgs["instant_reload"] and 0 or data._reloadTime
        data.magazine = flgs["inf_ammo"] and 999 or data._magazine
    end
    wpnmng.Constants.DEFAULT_FIRERATE = flgs["no_shoot_delay"] and 9999 or 2
    wpnmng.Constants.DEFAULT_PISTOL_FIRERATE = flgs["no_shoot_delay"] and 9999 or 4
    wpnmng.Constants.DEFAULT_DAMAGE = 100
    wpnmng.Constants.DEFAULT_PISTOL_DAMAGE = 50
    wpnmng.Constants.DEFAULT_RELOAD_TIME = flgs["instant_reload"] and 0 or 0.75
    wpnmng.Constants.DEFAULT_PISTOL_RELOAD_TIME = flgs["instant_reload"] and 0 or 0.5
    wpnmng.Constants.DEFAULT_MAGAZINE = flgs["inf_ammo"] and 999 or 1
end

mngmpkts.hitResult.listen(function(data)
    task.spawn(function()
        if flgs["hit_notifs"] then
            setthreadidentity(8)
            local tname = (typeof(data.target) == "Instance" and data.target.Name) or "Enemy"
            local hpart = (data.bonus and data.bonus.headshot) and "head" or "body"
            local hplost = data.killed and 100 or math.random(10, 50)
            local msg = flgs["hit_notif_msg"] or "hit (target) for (hp) in the (part)!"
            msg = string.gsub(msg, "%(target%)", tname)
            msg = string.gsub(msg, "%(part%)", hpart)
            msg = string.gsub(msg, "%(hp%)", tostring(hplost))
            
            local ok, err = pcall(function() lib:notification({ text = msg }) end)
            if not ok then
                warn("fatal err: " .. tostring(err))
            end
        end
    end)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        if key == "WalkSpeed" and ws_en and self:IsA("Humanoid") then return 16 end
        if key == "JumpPower" and jp_en and self:IsA("Humanoid") then return 50 end
    end
    return oldIndex(self, key)
end))

local oldnm
oldnm = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
    local m = getnamecallmethod()
    if m == 'FireServer' and self == bytenetrel and currtarg then
        local args = {...}
        if typeof(args[2]) == 'table' and typeof(args[2][1]) == 'Instance' then
            local hitchance = flgs["silent_hitchance"] or 100
            if math.random(1, 100) <= hitchance then
                args[2][1] = currtarg
                args[2][2] = currtarg.Head
            end
        end
    elseif m == "FindFirstChild" and flgs["ff_bypass"] then
        local args = {...}
        if args[1] == "ForceField" then
            return nil
        end
    end
    return oldnm(self, ...)
end))

local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
    if not checkcaller() and key == "AssemblyLinearVelocity" and typeof(value) == "Vector3" then
        if self:IsA("BasePart") and self.Name == "HumanoidRootPart" then
            local char = self:FindFirstAncestorOfClass("Model")
            if char and char == lp.Character then
                if ws_en and value.X == 0 and value.Z == 0 then
                    return
                end
                if jp_en and value.Y < -40 then
                    return
                end
            end
        end
    end
    return oldNewIndex(self, key, value)
end))

local function apply_ws(state, speed)
    ws_en = state
    local hum = gethum()
    if hum then hum.WalkSpeed = state and (speed or 50) or 16 end
end

local function apply_jp(state, power)
    jp_en = state
    local hum = gethum()
    if hum then hum.JumpPower = state and (power or 50) or 50 end
end

function get_targs()
    local targs = {}
    for _, plr in ipairs(plrs:GetPlayers()) do
        if plr ~= lp and plr.Character then
            table.insert(targs, plr.Character)
        end
    end
    for _, obj in ipairs(ws:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not plrs:GetPlayerFromCharacter(obj) then
            table.insert(targs, obj)
        end
    end
    return targs
end

local function get_siltarg()
    local mp = uis:GetMouseLocation()
    local fov = flgs["silent_radius"] or 150
    local maxDist = flgs["aim_max_dist"] or 500
    local root = getroot()
    local best, bestScore = nil, math.huge

    for _, char in ipairs(get_targs()) do
        local h = char:FindFirstChildOfClass("Humanoid")
        local part = char:FindFirstChild(flgs["aim_part"] or "Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (h and part and hrp and h.Health > 0) then continue end
        
        -- Skip friends
        local player = plrs:GetPlayerFromCharacter(char)
        if player and friends_list[player.Name] then continue end
        
        local dist3D = root and (hrp.Position - root.Position).Magnitude or 0
        if not flgs["inf_distance"] and dist3D > maxDist then continue end

        if flgs["silent_wall_check"] and not flgs["wallbang"] then
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {getchar(), char}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local hit = ws:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position), rp)
            if hit and not hit.Instance:IsDescendantOf(char) then continue end
        end

        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not flgs["inf_distance"] and not onScreen then continue end
        
        local screenDist = onScreen and (Vector2.new(sp.X, sp.Y) - mp).Magnitude or math.huge
        if not flgs["inf_distance"] and screenDist > fov then continue end

        local score = flgs["inf_distance"] and dist3D or screenDist

        if score < bestScore then best = char; bestScore = score end
    end
    return best
end

local esp_objs = {}
local skel_prs = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
    {"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"}
}
local skel_prs_r6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function build_esp(char)
    if esp_objs[char] then return end
    local corners = {}
    for i = 1, 8 do corners[i] = newdraw("Line", {Thickness = 2, Visible = false, Color = box_col}) end
    local skeleton = {}
    for i = 1, #skel_prs do skeleton[i] = newdraw("Line", {Thickness = 1, Visible = false, Color = skel_col}) end
    
    esp_objs[char] = {
        box = newdraw("Square", {Thickness = 1, Filled = false, Visible = false, Color = box_col}),
        corners = corners,
        skeleton = skeleton,
        nameText = newdraw("Text", {Size = 13, Center = true, Outline = true, Visible = false, Color = name_col, Font = 2}),
        distText = newdraw("Text", {Size = 11, Center = true, Outline = true, Visible = false, Color = dist_col, Font = 2}),
        hpBG = newdraw("Square", {Filled = true, Visible = false, Color = rgb(0, 0, 0)}),
        hpBar = newdraw("Square", {Filled = true, Visible = false, Color = rgb(0, 255, 0)})
    }
end

local function destroy_esp(char)
    local d = esp_objs[char]
    if not d then return end
    for _, v in pairs(d.corners) do pcall(function() v:Remove() end) end
    for _, v in pairs(d.skeleton) do pcall(function() v:Remove() end) end
    for k, v in pairs(d) do
        if k ~= "corners" and k ~= "skeleton" then pcall(function() v:Remove() end) end
    end
    esp_objs[char] = nil
end

local function rng()
   return math.random(1, 967676767)
end

-- NEW CHAMS SYSTEM
local Highlights = {}
local players_chams_col = rgb(255, 0, 0)
local bots_chams_col = rgb(150, 150, 150)

local function GetValidEntities()
    local entities = {}

    for _, obj in ipairs(ws:GetChildren()) do
        if obj:IsA("Model") and obj ~= lp.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local head = obj:FindFirstChild("Head")
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            
            if humanoid and head and rootPart and humanoid.Health > 0 then
                local isPlayerChar = false
                for _, p in ipairs(plrs:GetPlayers()) do
                    if p.Character == obj then isPlayerChar = true break end
                end
                
                if isPlayerChar then
                    table.insert(entities, {
                        Key = "PLAYER_" .. obj.Name .. "_" .. tostring(obj),
                        Character = obj,
                        IsPlayer = true
                    })
                else
                    table.insert(entities, {
                        Key = "BOT_" .. obj.Name .. "_" .. tostring(obj),
                        Character = obj,
                        IsPlayer = false
                    })
                end
            end
        end
    end

    return entities
end

local function UpdateChamsColorsAndHighlights()
    if not flgs["chams_on"] then
        for key, hl in pairs(Highlights) do
            if hl then pcall(function() hl:Destroy() end) end
            Highlights[key] = nil
        end
        return
    end

    local entities = GetValidEntities()
    local activeKeys = {}

    for _, entity in ipairs(entities) do
        activeKeys[entity.Key] = true
        local char = entity.Character
        
        if not char or not char.Parent then
            if Highlights[entity.Key] then
                pcall(function() Highlights[entity.Key]:Destroy() end)
                Highlights[entity.Key] = nil
            end
            continue
        end
        
        local highlight = Highlights[entity.Key]

        if highlight then
            pcall(function() highlight:Destroy() end)
            Highlights[entity.Key] = nil
        end
        
        highlight = Instance.new("Highlight")
        highlight.Name = "ChamsHighlight"
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char
        Highlights[entity.Key] = highlight

        local player = plrs:GetPlayerFromCharacter(char)
        local isFriend = player and friends_list[player.Name]

        if isFriend then
            highlight.FillColor = friend_chams_col
            highlight.OutlineColor = Color3.new(1, 1, 1)
        elseif entity.IsPlayer then
            highlight.FillColor = players_chams_col
            highlight.OutlineColor = Color3.new(1, 1, 1)
        else
            highlight.FillColor = bots_chams_col
            highlight.OutlineColor = Color3.new(1, 1, 1)
        end
    end

    for key, hl in pairs(Highlights) do
        if not activeKeys[key] then
            if hl then pcall(function() hl:Destroy() end) end
            Highlights[key] = nil
        end
    end
end

local function apply_vm_chams()
    local vm = cam:FindFirstChild("Viewmodel")
    if not vm then return end
    
    local function apply(part, color, material, trans, enabled)
        if not part or not part:IsA("BasePart") then return end
        if enabled then
            if not part:GetAttribute("LunarVMOrig") then
                part:SetAttribute("LunarVMOrig", true)
                part:SetAttribute("OrigMat", part.Material)
                part:SetAttribute("OrigColor", part.Color)
                part:SetAttribute("OrigTrans", part.Transparency)
            end
            part.Color = color
            part.Material = material
            part.Transparency = trans
        else
            if part:GetAttribute("LunarVMOrig") then
                part.Material = part:GetAttribute("OrigMat")
                part.Color = part:GetAttribute("OrigColor")
                part.Transparency = part:GetAttribute("OrigTrans")
                part:SetAttribute("LunarVMOrig", nil)
            end
        end
    end

    for _, child in ipairs(vm:GetChildren()) do
        if string.find(child.Name, "Arm") then
            apply(child, arm_chams_col, Enum.Material[flgs["arm_chams_mat"] or "Neon"], arm_chams_trans, flgs["arm_chams_on"])
            for _, desc in ipairs(child:GetDescendants()) do
                apply(desc, arm_chams_col, Enum.Material[flgs["arm_chams_mat"] or "Neon"], arm_chams_trans, flgs["arm_chams_on"])
            end
        elseif child.Name == "Weapon" then
            apply(child, wpn_chams_col, Enum.Material[flgs["wpn_chams_mat"] or "Neon"], wpn_chams_trans, flgs["wpn_chams_on"])
            for _, desc in ipairs(child:GetDescendants()) do
                apply(desc, wpn_chams_col, Enum.Material[flgs["wpn_chams_mat"] or "Neon"], wpn_chams_trans, flgs["wpn_chams_on"])
            end
        end
    end
end

local menu_open = false
local mouse_lock = false

local function unlock_mouse(visible)
    if visible and not menu_open then
        menu_open = true
        if uis.MouseBehavior == Enum.MouseBehavior.LockCenter or uis.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
            mouse_lock = true
        else
            mouse_lock = false
        end
    elseif not visible and menu_open then
        menu_open = false
        if mouse_lock then
            uis.MouseBehavior = Enum.MouseBehavior.LockCenter
            mouse_lock = false
        end
    end

    if visible and uis.MouseBehavior ~= Enum.MouseBehavior.Default then
        uis.MouseBehavior = Enum.MouseBehavior.Default
    end
end

local wnd = lib:window({ name = "lunar x | one tap", size = UDim2.fromOffset(580, 600) })

local aim_tab = wnd:tab({ name = "aimbot" })
local vis_tab = wnd:tab({ name = "visuals" })
local wpn_tab = wnd:tab({ name = "weapon" })
local misc_tab = wnd:tab({ name = "misc" })
local set_tab = wnd:tab({ name = "settings" })

local sil_sec = aim_tab:section({ name = "silent aim", side = "left" })
local aim_cfg = aim_tab:section({ name = "config", side = "left" })

sil_sec:toggle({ name = "Silent Aim", flag = "silent_aim", default = false })
sil_sec:slider({ name = "Hit Chance", flag = "silent_hitchance", min = 1, max = 100, default = 100, interval = 1, suffix = "%" })
sil_sec:toggle({ name = "Wall Check", flag = "silent_wall_check", default = true })
sil_sec:toggle({ name = "Wallbang", flag = "wallbang", default = false })
sil_sec:toggle({ name = "Inf Distance", flag = "inf_distance", default = false })
sil_sec:slider({ name = "Silent Aim Radius", flag = "silent_radius", min = 10, max = 1000, default = 150, interval = 5, suffix = "px" })
sil_sec:toggle({ name = "Show FOV Circle", flag = "show_fov_circle", default = false })

aim_cfg:dropdown({ name = "Target Part", flag = "aim_part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, default = "Head" })
aim_cfg:slider({ name = "Smoothness", flag = "aim_smooth", min = 0.01, max = 1, default = 0.15, interval = 0.01, suffix = "x" })
aim_cfg:slider({ name = "Max Distance", flag = "aim_max_dist", min = 50, max = 5000, default = 1000, interval = 50, suffix = " st" })

local esp_sec = vis_tab:section({ name = "player esp", side = "left" })
local chams_sec = vis_tab:section({ name = "chams", side = "left" })
local vm_sec = vis_tab:section({ name = "viewmodel chams", side = "right" })

local mats = {"Neon", "ForceField", "Glass", "Ice", "Plastic", "Metal", "SmoothPlastic"}

vm_sec:toggle({ name = "Weapon Chams", flag = "wpn_chams_on", default = false })
vm_sec:colorpicker({ name = "Color", flag = "wpn_chams_color", color = wpn_chams_col, alpha = 0, callback = function(c, t)
    wpn_chams_col = c
end})
vm_sec:dropdown({ name = "Material", flag = "wpn_chams_mat", items = mats, default = "Neon" })
vm_sec:slider({ name = "Transparency", flag = "wpn_chams_trans", min = 0, max = 1, default = 0, interval = 0.1, callback = function(v) wpn_chams_trans = v end })

vm_sec:toggle({ name = "Arm Chams", flag = "arm_chams_on", default = false })
vm_sec:colorpicker({ name = "Color", flag = "arm_chams_color", color = arm_chams_col, alpha = 0, callback = function(c, t)
    arm_chams_col = c
end})
vm_sec:dropdown({ name = "Material", flag = "arm_chams_mat", items = mats, default = "Neon" })
vm_sec:slider({ name = "Transparency", flag = "arm_chams_trans", min = 0, max = 1, default = 0, interval = 0.1, callback = function(v) arm_chams_trans = v end })

esp_sec:toggle({ name = "ESP Enabled", flag = "esp_on", default = false })
esp_sec:slider({ name = "Max Distance", flag = "esp_max_dist", min = 50, max = 5000, default = 2000, interval = 50, suffix = " st" })
esp_sec:dropdown({ name = "Box Style", flag = "box_style", items = {"None", "Full Box", "Corner Box"}, default = "Corner Box" })
esp_sec:toggle({ name = "Box ESP", flag = "box_esp", default = true })
esp_sec:colorpicker({ name = "Box Color", flag = "box_color", color = box_col, alpha = 0, callback = function(c) box_col = c end })
esp_sec:toggle({ name = "Name ESP", flag = "name_esp", default = false })
esp_sec:toggle({ name = "Distance ESP", flag = "dist_esp", default = false })
esp_sec:toggle({ name = "Health Bar", flag = "hp_esp", default = false })
esp_sec:toggle({ name = "Skeleton ESP", flag = "skel_esp", default = false })
esp_sec:colorpicker({ name = "Skeleton Color", flag = "skel_color", color = skel_col, alpha = 0, callback = function(c) skel_col = c end })

chams_sec:toggle({ name = "Chams", flag = "chams_on", default = false })
chams_sec:colorpicker({ name = "Players Fill Color", flag = "players_chams_color", color = players_chams_col, alpha = 0, callback = function(c) players_chams_col = c end })
chams_sec:colorpicker({ name = "Bots Fill Color", flag = "bots_chams_color", color = bots_chams_col, alpha = 0, callback = function(c) bots_chams_col = c end })

local xp_hkd = false
local orig_vals = wpnclnt.__setValues
wpnclnt.__setValues = function(self, key)
    local res = orig_vals(self, key)
    if not xp_hkd and wpnpkts.useWeapon and wpnpkts.useWeapon.send then
        local origsendd = wpnpkts.useWeapon.send
        wpnpkts.useWeapon.send = function(data)
            if flgs["max_xp"] then
                data.was360 = true
                data.quickscope = true
                data.scoped = true
            end
            return origsendd(data)
        end
        xp_hkd = true
    end
    return res
end

local wpn_main_sec = wpn_tab:section({ name = "weapon mods", side = "left" })
wpn_main_sec:toggle({ name = "Inf Fire Rate", flag = "no_shoot_delay", default = false, callback = apply_wpn_mods })
wpn_main_sec:toggle({ name = "No Recoil", flag = "no_recoil", default = false, callback = function(v)
    if v then
        vwmdlclnt.shoot = function(...) end
    else
        vwmdlclnt.shoot = orig_vmshoot
    end
end})
wpn_main_sec:toggle({ name = "Instant Reload", flag = "instant_reload", default = false, callback = apply_wpn_mods })
wpn_main_sec:toggle({ name = "Infinite Ammo", flag = "inf_ammo", default = false, callback = apply_wpn_mods })
wpn_main_sec:toggle({ name = "Max XP", flag = "max_xp", default = false })
wpn_main_sec:toggle({ name = "No Knife Cooldown", flag = "no_knife_cd", default = false })
wpn_main_sec:toggle({ name = "Forcefield Bypass", flag = "ff_bypass", default = false })

local misc_sec = misc_tab:section({ name = "local player", side = "left" })
local move_sec = misc_tab:section({ name = "movement", side = "left" })

misc_sec:toggle({ name = "Anti-AFK", flag = "anti_afk", default = false })
misc_sec:toggle({ name = "Noclip", flag = "noclip_on", default = false })
misc_sec:toggle({ name = "Auto Deploy", flag = "auto_deploy", default = false, callback = function(v)
    if v then
        while v do 
            mngmpkts.deploy.send()
            task.wait(1)
        end
    end
end})
misc_sec:toggle({ name = "Instant Respawn", flag = "instant_respawn", default = false, callback = function(v)
    if v then
        task.spawn(function()
            while flgs["instant_respawn"] do
                if pgui:FindFirstChild("Game Interface") and pgui:FindFirstChild("Game Interface"):FindFirstChild("Deathscreen") then
                    if pgui:FindFirstChild("Game Interface").Deathscreen.Visible then
                        mngmpkts.respawn.send(true)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end})

misc_sec:toggle({ name = "Auto Equip Weapon", flag = "auto_equip", default = false })
misc_sec:dropdown({ name = "Equip Weapon", flag = "auto_equip_weapon", items = {"Primary", "Secondary", "Knife"}, default = "Primary" })
local tp_con
misc_sec:toggle({ name = "Third Person", flag = "third_person", default = false, callback = function(v)
    if v then
        lp.CameraMode = Enum.CameraMode.Classic
        lp.CameraMaxZoomDistance = 128
        wpnclnt.scope = function(...) end
        tp_con = lp:GetPropertyChangedSignal("CameraMode"):Connect(function()
            if lp.CameraMode ~= Enum.CameraMode.Classic then
                lp.CameraMode = Enum.CameraMode.Classic
            end
        end)
    else
        if tp_con then tp_con:Disconnect() tp_con = nil end
    end
end})
misc_sec:toggle({ name = "Spin Bot", flag = "spin_on", default = false })
misc_sec:slider({ name = "Spin Speed", flag = "spin_speed", min = 10, max = 10000, default = 180, interval = 10, suffix = " deg/s" })
misc_sec:toggle({ name = "Custom Kill Feed", flag = "custom_kill_feed", default = false })
misc_sec:textbox({ name = "Kill Feed Text", flag = "kill_feed_text", placeholder = "Text", default = "", callback = function(text) ckf_txt = text end })
misc_sec:toggle({ name = "Hit Notifications", flag = "hit_notifs", default = false })
misc_sec:textbox({ name = "Hit Notif Message", flag = "hit_notif_msg", placeholder = "hit (target) for (hp) in (part)", default = "hit (target) for (hp) in the (part)!" })

misc_sec:toggle({ name = "Auto Collect Quests", flag = "auto_quests", default = false, callback = function(v)
    if v then
        task.spawn(function()
            while flgs["auto_quests"] do
                for i=1, 3 do pcall(function() qstpkts.claimDailyQuest.send(i) end) end
                for i=1, 3 do pcall(function() qstpkts.claimHourlyQuest.send(i) end) end
                task.wait(5)
            end
        end)
    end
end})
misc_sec:toggle({ name = "Auto Collect Level Rewards", flag = "auto_lvl_rewards", default = false, callback = function(v)
    if v then
        task.spawn(function()
            local level = 1
            pcall(function()
                level = dataclnt.getData().Data.level or 1
            end)
            for i = 1, level do
                pcall(function() lvlrewpkts.claimLevelReward.send(i) end)
                task.wait(0.5)
            end
            flgs["auto_lvl_rewards"] = false
        end)
    end
end})
misc_sec:toggle({ name = "Auto Collect Battlepass", flag = "auto_bp", default = false, callback = function(v)
    if v then
        task.spawn(function()
            while flgs["auto_bp"] do
                for i = 1, 30 do
                    pcall(function() battlepasspkts.claimItem.send({ tierIndex = i, isPremiumTier = false }) end)
                    pcall(function() battlepasspkts.claimItem.send({ tierIndex = i, isPremiumTier = true }) end)
                    task.wait(0.5)
                end
                task.wait(5)
            end
        end)
    end
end})

move_sec:toggle({ name = "Speed Hack", flag = "speed_onnn", default = false, callback = function(v) apply_ws(v, flgs["walkspeed"] or 50) end })
move_sec:dropdown({ name = "Speed Method", flag = "speed_method", items = {"WalkSpeed", "CFrame", "Velocity"}, default = "WalkSpeed" })
move_sec:slider({ name = "WalkSpeed", flag = "walkspeed", min = 16, max = 500, default = 50, interval = 1, suffix = " ws" })
move_sec:toggle({ name = "Jump Hack", flag = "jump_on", default = false, callback = function(v) apply_jp(v, flgs["jump_power"] or 50) end })
move_sec:dropdown({ name = "Jump Method", flag = "jump_method", items = {"JumpPower", "Velocity"}, default = "JumpPower" })
move_sec:slider({ name = "JumpPower", flag = "jump_power", min = 50, max = 500, default = 50, interval = 1, suffix = " jp" })

local cfg_sec = set_tab:section({ name = "configs", side = "left" })
local friends_sec = set_tab:section({ name = "friend list", side = "left" })
local ui_sec = set_tab:section({ name = "ui", side = "right" })

local dir = lib.directory .. "/configs/"
if not isfolder(lib.directory) then makefolder(lib.directory) end
if not isfolder(dir) then makefolder(dir) end
lib.cfg_hldr = cfg_sec:dropdown({ name = "Configs", flag = "config_name_list", items = {}, default = "" })
cfg_sec:textbox({ name = "Config Name", flag = "config_name_text_box", placeholder = "config name" })

local function custom_load_config(jsonStr)
    local config = http:JSONDecode(jsonStr)
    for flag, value in pairs(config) do
        local setter = lib.config_flags[flag]
        if setter then
            pcall(function()
                if type(value) == "table" then
                    if value.Color and value.Transparency then
                        local c = Color3.fromHex(value.Color)
                        if typeof(c) ~= "Color3" then c = Color3.new(1, 1, 1) end
                        setter(c, value.Transparency)
                    elseif value.active ~= nil then
                        setter(value)
                    end
                else
                    setter(value)
                end
            end)
        end
    end
end

local function custom_save_config(name)
    local Config = {}
    for flag, v in pairs(flgs) do
        if type(v) == "table" and v.key then
            Config[flag] = { active = v.active, mode = v.mode, key = tostring(v.key) }
        elseif type(v) == "table" and v["Transparency"] and v["Color"] then
            Config[flag] = { Transparency = v["Transparency"], Color = v["Color"]:ToHex() }
        else
            Config[flag] = v
        end
    end
    writefile(dir .. name .. ".cfg", http:JSONEncode(Config))
end

cfg_sec:button({ name = "Create", callback = function() local name = flgs["config_name_text_box"]; if name and name ~= "" then custom_save_config(name); lib:cfg_lst_upd() end end })
cfg_sec:button({ name = "Load", callback = function() local name = flgs["config_name_list"]; if name and name ~= "" and isfile(dir .. name .. ".cfg") then custom_load_config(readfile(dir .. name .. ".cfg")); lib:notification({text = "Loaded config: "..name}) end end })
cfg_sec:button({ name = "Save", callback = function() local name = flgs["config_name_list"] or flgs["config_name_text_box"]; if name and name ~= "" then custom_save_config(name); lib:cfg_lst_upd(); lib:notification({text = "Saved config: "..name}) end end })
cfg_sec:button({ name = "Delete", callback = function() local name = flgs["config_name_list"]; if name and name ~= "" and isfile(dir .. name .. ".cfg") then delfile(dir .. name .. ".cfg"); lib:cfg_lst_upd() end end })
cfg_sec:button({ name = "Set Auto Load", callback = function() 
    local name = flgs["config_name_list"]
    if name and name ~= "" then
        writefile(lib.directory .. "/autoload.cfg", name)
        lib:notification({text = "Set autoload to: "..name})
    else
        lib:notification({text = "Select a config first"})
    end
end })

cfg_sec:button({ name = "Stop Auto Load", callback = function()
    local p = lib.directory .. "/autoload.cfg"
    if isfile(p) then
        delfile(p)
        lib:notification({text = "Stopped auto loading"})
    else
        lib:notification({text = "No autoload set"})
    end
end })
lib:cfg_lst_upd()

-- Friend list UI
local function get_server_players()
    local server_players = {}
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp then
            table.insert(server_players, p.Name)
        end
    end
    return server_players
end

friends_sec:textbox({ name = "Add Friend by Name", flag = "friend_name_input", placeholder = "player name" })

friends_sec:button({ name = "Add Friend", callback = function()
    local name = flgs["friend_name_input"]
    if name and name ~= "" then
        friends_list[name] = true
        lib:notification({text = "Added "..name.." to friends"})
        flgs["friend_name_input"] = ""
    end
end })

local function update_friend_display()
    local friendsList = {}
    for name, _ in pairs(friends_list) do
        table.insert(friendsList, name)
    end
    if #friendsList == 0 then
        friends_sec:label("No friends added")
    end
    return friendsList
end

friends_sec:button({ name = "Show Online Players", callback = function()
    local players = get_server_players()
    local msg = "Players online: " .. table.concat(players, ", ")
    lib:notification({text = msg})
end })

friends_sec:button({ name = "Remove Friend", callback = function()
    local name = flgs["friend_name_input"]
    if name and name ~= "" then
        if friends_list[name] then
            friends_list[name] = nil
            lib:notification({text = "Removed "..name.." from friends"})
            flgs["friend_name_input"] = ""
        else
            lib:notification({text = name.." is not in your friends list"})
        end
    end
end })

-- Update friend list when players join/leave
connct(plrs.PlayerAdded, function(player)
    if player ~= lp then
        task.wait(0.1)
    end
end)

connct(plrs.PlayerRemoving, function(player)
    if friends_list[player.Name] then
        friends_list[player.Name] = nil
        lib:notification({text = player.Name.." left the game (removed from friends)"})
    end
end)

local cursor_ln = newdraw("Quad", {Thickness = 0, Filled = true, Visible = false, Color = Color3.new(0, 0, 0)})
local cursor = newdraw("Quad", {Thickness = 0, Filled = true, Visible = false, Color = rgb(100, 100, 255)})
local fov_circle = newdraw("Circle", {Thickness = 1, Filled = false, Visible = false, Color = rgb(100, 100, 255), NumSides = 30})
ui_sec:toggle({ name = "Keybind List", flag = "ui_keybind_list", default = false, callback = function(v) wnd.toggle_list(v) end })
ui_sec:toggle({ name = "Player List", flag = "ui_player_list", default = false, callback = function(v) wnd.toggle_playerlist(v) end })
local menu_vis = true
ui_sec:keybind({ name = "Menu Toggle", flag = "menu_key", default = Enum.KeyCode.RightControl, callback = function(v) 
    menu_vis = v 
    wnd.set_menu_visibility(v) 
end })
ui_sec:colorpicker({ name = "Accent Color", flag = "accent_color", color = rgb(100, 100, 255), alpha = 0, callback = function(c) lib:update_theme("accent", c) end })
ui_sec:toggle({ name = "Custom Cursor", flag = "custom_cursor", default = false })
ui_sec:dropdown({ name = "Cursor Mode", flag = "cursor_mode", items = {"Menu Opened", "Menu Closed", "Always"}, default = "Menu Opened" })

local function unld_gui()
    if lib and type(lib.unld) == "function" then lib:unld()
    else if lib and lib.gui then lib.gui:Destroy() end; getgenv().lib = nil end
end

ui_sec:button({ name = "Unload", callback = function()
    getgenv().LunarXLoaded = false
    disc_all()
    for char, _ in pairs(esp_objs) do destroy_esp(char) end
    for key, hl in pairs(Highlights) do
        if hl then pcall(function() hl:Destroy() end) end
        Highlights[key] = nil
    end
    if cursor then cursor:Remove() end
    if cursor_ln then cursor_ln:Remove() end
    if fov_circle then fov_circle:Remove() end
    
    uis.MouseIconEnabled = true
    hookmetamethod(game, "__namecall", oldnm)
    hookmetamethod(game, "__index", oldIndex)
    hookmetamethod(game, "__newindex", oldNewIndex)
    
    vwmdlclnt.shoot = orig_vmshoot
    wpnclnt.scope = orig_scope
    
    apply_wpn_mods()
    flgs["no_shoot_delay"] = false
    flgs["instant_reload"] = false
    flgs["inf_ammo"] = false
    apply_wpn_mods()

    unld_gui()
end})

local is_firing = false
connct(uis.InputBegan, function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gpe then
        is_firing = true
        st.lastClickTime = tick()
        task.spawn(function()
            while is_firing do
                if not uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then break end
                if flgs["auto_fire"] then
                    VIM:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, true, game, 0)
                    task.wait(0.02)
                    VIM:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 0)
                    task.wait(0.05)
                else
                    task.wait(0.1)
                end
            end
        end)
    end
end)
connct(uis.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then is_firing = false end
end)

connct(run.Heartbeat, function(dt)
    local hum = gethum()
    if hum then
        if ws_en then
            local method = flgs["speed_method"] or "WalkSpeed"
            local speedVal = flgs["walkspeed"] or 50
            local isWalking = hum.MoveDirection.Magnitude > 0
            if isWalking then
                if method == "WalkSpeed" then
                    if hum.WalkSpeed ~= speedVal then hum.WalkSpeed = speedVal end
                elseif method == "CFrame" then
                    local root = getroot()
                    if root then
                        root.CFrame = root.CFrame + (hum.MoveDirection * speedVal * dt)
                    end
                elseif method == "Velocity" then
                    local root = getroot()
                    if root then
                        local vel = hum.MoveDirection * speedVal
                        root.AssemblyLinearVelocity = Vector3.new(vel.X, root.AssemblyLinearVelocity.Y, vel.Z)
                    end
                end
            else
                if method == "WalkSpeed" then
                    if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
                elseif method == "Velocity" then
                    local root = getroot()
                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                    end
                end
            end
        end
        if jp_en then
            local method = flgs["jump_method"] or "JumpPower"
            local jumpVal = flgs["jump_power"] or 50
            if method == "JumpPower" then
                if hum.JumpPower ~= jumpVal then hum.JumpPower = jumpVal end
            elseif method == "Velocity" then
                local root = getroot()
                if root and hum:GetState() == Enum.HumanoidStateType.Jumping then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, jumpVal, root.AssemblyLinearVelocity.Z)
                end
            end
        end
    end
end)

connct(run.Stepped, function()
    if flgs["noclip_on"] then
        local char = getchar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

connct(run.Heartbeat, function()
    if flgs["no_shoot_delay"] then
        pcall(function() wpnclnt.resetBullets(true) end)
    end
end)

connct(run.RenderStepped, function(dt)
    local mp = uis:GetMouseLocation()
    local vp = cam.ViewportSize
    local espOn = flgs["esp_on"]
    local rootPos = getroot() and getroot().Position

    if flgs["silent_aim"] or flgs["wallbang"] then
        currtarg = get_siltarg()
    else
        currtarg = nil
    end

    unlock_mouse(menu_vis)

    apply_vm_chams()
    UpdateChamsColorsAndHighlights()

    local lvlup_vis = pgui:FindFirstChild("Game Interface") and pgui:FindFirstChild("Game Interface"):FindFirstChild("Level Up") and pgui:FindFirstChild("Game Interface"):FindFirstChild("Level Up").Visible
    local death_vis = pgui:FindFirstChild("Game Interface") and pgui:FindFirstChild("Game Interface"):FindFirstChild("Deathscreen") and pgui:FindFirstChild("Game Interface"):FindFirstChild("Deathscreen").Visible

    if lvlup_vis or death_vis then
        uis.MouseIconEnabled = true
        if cursor then cursor.Visible = false end
        if cursor_ln then cursor_ln.Visible = false end
        if uis.MouseBehavior ~= Enum.MouseBehavior.Default then
            uis.MouseBehavior = Enum.MouseBehavior.Default
        end
    else
        local showcursor = false
        if flgs["custom_cursor"] then
            if flgs["cursor_mode"] == "Always" then
                showcursor = true
            elseif flgs["cursor_mode"] == "Menu Opened" and menu_vis then
                showcursor = true
            elseif flgs["cursor_mode"] == "Menu Closed" and not menu_vis then
                showcursor = true
            end
        end

        local c = getchar()
        local deployed = c and c:GetAttribute("deployed")

        if showcursor then
            local mp = uis:GetMouseLocation()
            
            uis.MouseIconEnabled = false
            cursor.Visible = true
            cursor_ln.Visible = true
            
            local accentc = rgb(100, 100, 255)
            if flgs["accent_color"] and typeof(flgs["accent_color"]) == "table" and flgs["accent_color"].Color then
                accentc = flgs["accent_color"].Color
            elseif flgs["accent_color"] and typeof(flgs["accent_color"]) == "Color3" then
                accentc = flgs["accent_color"]
            end
            
            cursor.Color = accentc
            
            cursor_ln.PointA = Vector2.new(mp.X - 1, mp.Y - 1)
            cursor_ln.PointB = Vector2.new(mp.X + 5, mp.Y + 21)
            cursor_ln.PointC = Vector2.new(mp.X + 19, mp.Y + 13)
            cursor_ln.PointD = cursor_ln.PointC
            
            cursor.PointA = Vector2.new(mp.X, mp.Y)
            cursor.PointB = Vector2.new(mp.X + 3, mp.Y + 20)
            cursor.PointC = Vector2.new(mp.X + 17, mp.Y + 12)
            cursor.PointD = cursor.PointC
        else
            cursor.Visible = false
            cursor_ln.Visible = false
            
            if menu_vis then
                uis.MouseIconEnabled = true
            else
                uis.MouseIconEnabled = not deployed
            end
        end

        -- Draw FOV circle for silent aim
        if flgs["show_fov_circle"] and flgs["silent_aim"] then
            local mp = uis:GetMouseLocation()
            local fov_radius = flgs["silent_radius"] or 150
            fov_circle.Radius = fov_radius
            fov_circle.Position = mp
            fov_circle.Color = rgb(100, 100, 255)
            fov_circle.Visible = true
        else
            fov_circle.Visible = false
        end
    end

    if flgs["spin_on"] then
        local r = getroot()
        if r then
            r.CFrame = r.CFrame * CFrame.Angles(0, math.rad((flgs["spin_speed"] or 180) * dt), 0)
        end
    end

    if flgs["custom_kill_feed"] then
        pcall(function()
            local t = lp.PlayerGui.Gameplay.Kill.Tabs.TargetName
            if t and t.Visible then
                t.Text = ckf_txt
            end
        end)
    end

    for _, char in ipairs(get_targs()) do
        local h = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (h and hrp) then continue end

        build_esp(char)
        local d = esp_objs[char]

        local function hideAll()
            if d.box then d.box.Visible = false end
            if d.nameText then d.nameText.Visible = false end
            if d.distText then d.distText.Visible = false end
            if d.hpBG then d.hpBG.Visible = false end
            if d.hpBar then d.hpBar.Visible = false end
            for _, l in ipairs(d.corners) do if l then l.Visible = false end end
            for _, l in ipairs(d.skeleton) do if l then l.Visible = false end end
        end

        if not espOn or h.Health <= 0 then hideAll(); continue end
        if rootPos and (hrp.Position - rootPos).Magnitude > (flgs["esp_max_dist"] or 800) then hideAll(); continue end

        local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then hideAll(); continue end

        local topSP = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.8, 0))
        local botSP = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.8, 0))
        local boxH = math.abs(botSP.Y - topSP.Y)
        local boxW = boxH * 0.55
        local bx, by = sp.X - boxW / 2, topSP.Y
        local style = flgs["box_style"] or "Corner Box"

        if flgs["box_esp"] then
            if style == "Full Box" then
                for _, l in ipairs(d.corners) do if l then l.Visible = false end end
                if d.box then
                    d.box.Size = Vector2.new(boxW, boxH); d.box.Position = Vector2.new(bx, by)
                    d.box.Color = box_col; d.box.Visible = true
                end
            elseif style == "Corner Box" then
                if d.box then d.box.Visible = false end
                local cL = math.min(boxW, boxH) * 0.28
                local co = d.corners
                if co[1] then co[1].From, co[1].To = Vector2.new(bx, by), Vector2.new(bx + cL, by) end
                if co[2] then co[2].From, co[2].To = Vector2.new(bx, by), Vector2.new(bx, by + cL) end
                if co[3] then co[3].From, co[3].To = Vector2.new(bx + boxW, by), Vector2.new(bx + boxW - cL, by) end
                if co[4] then co[4].From, co[4].To = Vector2.new(bx + boxW, by), Vector2.new(bx + boxW, by + cL) end
                if co[5] then co[5].From, co[5].To = Vector2.new(bx, by + boxH), Vector2.new(bx + cL, by + boxH) end
                if co[6] then co[6].From, co[6].To = Vector2.new(bx, by + boxH), Vector2.new(bx, by + boxH - cL) end
                if co[7] then co[7].From, co[7].To = Vector2.new(bx + boxW, by + boxH), Vector2.new(bx + boxW - cL, by + boxH) end
                if co[8] then co[8].From, co[8].To = Vector2.new(bx + boxW, by + boxH), Vector2.new(bx + boxW, by + boxH - cL) end
                for _, l in ipairs(co) do if l then l.Color = box_col; l.Visible = true end end
            else
                if d.box then d.box.Visible = false end
                for _, l in ipairs(d.corners) do if l then l.Visible = false end end
            end
        else
            if d.box then d.box.Visible = false end
            for _, l in ipairs(d.corners) do if l then l.Visible = false end end
        end

        if flgs["name_esp"] and d.nameText then
            local plr = plrs:GetPlayerFromCharacter(char)
            d.nameText.Text = plr and plr.Name or char.Name
            d.nameText.Position = Vector2.new(sp.X, by - 14)
            d.nameText.Color = name_col
            d.nameText.Visible = true
        else 
            if d.nameText then d.nameText.Visible = false end 
        end

        if flgs["dist_esp"] and rootPos and d.distText then
            local dist = math.round((hrp.Position - rootPos).Magnitude)
            d.distText.Text = dist .. "m"
            d.distText.Position = Vector2.new(sp.X, by + boxH + 3)
            d.distText.Color = dist_col
            d.distText.Visible = true
        else 
            if d.distText then d.distText.Visible = false end 
        end

        if flgs["hp_esp"] then
            local pct = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
            local hbX, barH = bx - 6, boxH * pct
            if d.hpBG then
                d.hpBG.Size = Vector2.new(4, boxH); d.hpBG.Position = Vector2.new(hbX, by); d.hpBG.Visible = true
            end
            if d.hpBar then
                d.hpBar.Size = Vector2.new(4, barH); d.hpBar.Position = Vector2.new(hbX, by + boxH - barH)
                d.hpBar.Color = Color3.fromRGB(math.round((1 - pct) * 255), math.round(pct * 255), 0)
                d.hpBar.Visible = true
            end
        else
            if d.hpBG then d.hpBG.Visible = false end
            if d.hpBar then d.hpBar.Visible = false end
        end

        if flgs["skel_esp"] then
            local rigType = h.RigType.Name
            local pairsToUse = rigType == "R15" and skel_prs or skel_prs_r6
            for i, pair in ipairs(pairsToUse) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local ln = d.skeleton[i]
                if p1 and p2 and ln then
                    local s1, on1 = cam:WorldToViewportPoint(p1.Position)
                    local s2, on2 = cam:WorldToViewportPoint(p2.Position)
                    if on1 and on2 then
                        ln.From = Vector2.new(s1.X, s1.Y); ln.To = Vector2.new(s2.X, s2.Y)
                        ln.Color = skel_col; ln.Visible = true
                    else
                        ln.Visible = false
                    end
                else
                    if ln then ln.Visible = false end
                end
            end
        else
            for _, l in ipairs(d.skeleton) do if l then l.Visible = false end end
        end
    end

    if flgs["auto_equip"] then
        local c = getchar()
        if c and c:GetAttribute("deployed") then
            local cw = c:GetAttribute("currentWeapon")
            local tw = flgs["auto_equip_weapon"] or "Primary"
            if cw ~= tw then
                local idx = 1
                if tw == "Secondary" then idx = 2 elseif tw == "Knife" then idx = 3 end
                pcall(function() wpnclnt.setWeapon(idx) end)
            end
        end
    end
end)

print("e")

connct(run.Heartbeat, function()
    for char, _ in pairs(esp_objs) do
        if not char.Parent or not char:IsDescendantOf(ws) or not char:FindFirstChild("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
            destroy_esp(char)
        end
    end
end)

connct(lp.Idled, function()
    if flgs["anti_afk"] then
        if VIM then 
            VIM:SendKeyEvent(true, Enum.KeyCode.ButtonB, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.ButtonB, false, game) 
        end
    end
end)

task.spawn(function()
    task.wait(1)
    if isfile(lib.directory .. "/silentload.cfg") then
        wnd.set_menu_visibility(false)
        flgs["silent_load"] = true
    end
    local alpath = lib.directory .. "/autoload.cfg"
    if isfile(alpath) then
        local cfgName = readfile(alpath)
        if cfgName and cfgName ~= "" then
            local path = dir .. cfgName .. ".cfg"
            if isfile(path) then
                custom_load_config(readfile(path))
                lib:notification({text = "auto loaded: "..cfgName})
            end
        end
    end
end)

ui_sec:slider({
    name = "Colorpicker Anim Speed",
    flag = "color_picker_anim_speed",
    min = 0,
    max = 5,
    default = 2,
    interval = 0.01
})

aim_tab.open_tab()
