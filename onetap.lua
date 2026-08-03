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

local orig_getwpnmdl = mdlmng.getWeaponModel
local orig_getknfmdl = mdlmng.getKnifeModel
local orig_getwpnanim = mdlmng.getWeaponAnimation
local orig_getknfanim = mdlmng.getKnifeAnimation
local orig_getwpnname = char_mngr.getHoldingWeaponName
local orig_getfiresnd = wpnmng.getFireSound
local orig_vmshoot = vwmdlclnt.shoot
local orig_scope = wpnclnt.scope
local orig_lazymod = tblmngr.lazyLoadModule

mdlmng.getWeaponModel = function(name)
    if type(name) == "buffer" then name = tostring(name) end
    if type(name) ~= "string" then return nil end
    local cw = lp.Character and lp.Character:GetAttribute("currentWeapon")
    if cw == "Primary" and flgs["ot_primary_skin"] ~= "" and flgs["ot_primary_skin"] ~= nil then
        local m = orig_getwpnmdl(flgs["ot_primary_skin"])
        if m then return m end
    elseif cw == "Secondary" and flgs["ot_secondary_skin"] ~= "" and flgs["ot_secondary_skin"] ~= nil then
        local m = orig_getwpnmdl(flgs["ot_secondary_skin"])
        if m then return m end
    end
    return orig_getwpnmdl(name)
end

mdlmng.getKnifeModel = function(name)
    if type(name) == "buffer" then name = tostring(name) end
    if type(name) ~= "string" then return nil end
    if flgs["ot_knife_skin"] ~= "" and flgs["ot_knife_skin"] ~= nil then
        local m = orig_getknfmdl(flgs["ot_knife_skin"])
        if m then return m end
    end
    return orig_getknfmdl(name)
end

mdlmng.getWeaponAnimation = function(name)
    if type(name) ~= "string" then return nil end
    local cw = lp.Character and lp.Character:GetAttribute("currentWeapon")
    if cw == "Primary" and flgs["ot_primary_skin"] ~= "" and flgs["ot_primary_skin"] ~= nil then
        local a = orig_getwpnanim(flgs["ot_primary_skin"])
        if a then return a end
    elseif cw == "Secondary" and flgs["ot_secondary_skin"] ~= "" and flgs["ot_secondary_skin"] ~= nil then
        local a = orig_getwpnanim(flgs["ot_secondary_skin"])
        if a then return a end
    end
    return orig_getwpnanim(name)
end

mdlmng.getKnifeAnimation = function(name)
    if type(name) ~= "string" then return nil end
    if flgs["ot_knife_skin"] ~= "" and flgs["ot_knife_skin"] ~= nil then
        local a = orig_getknfanim(flgs["ot_knife_skin"])
        if a then return a end
    end
    return orig_getknfanim(name)
end

char_mngr.getHoldingWeaponName = function(char)
    if char == lp.Character then
        local cw = char:GetAttribute("currentWeapon")
        if cw == "Primary" and flgs["ot_primary_skin"] ~= "" and flgs["ot_primary_skin"] ~= nil then
            return flgs["ot_primary_skin"]
        elseif cw == "Secondary" and flgs["ot_secondary_skin"] ~= "" and flgs["ot_secondary_skin"] ~= nil then
            return flgs["ot_secondary_skin"]
        elseif cw == "Knife" and flgs["ot_knife_skin"] ~= "" and flgs["ot_knife_skin"] ~= nil then
            return flgs["ot_knife_skin"]
        end
    end
    return orig_getwpnname(char)
end

tblmngr.lazyLoadModule = function(name, dict, parent)
    if type(name) == "string" and string.sub(name, 1, 1) == "_" then
        if flgs["ot_kill_effect"] ~= "" and flgs["ot_kill_effect"] ~= nil then
            name = "_" .. flgs["ot_kill_effect"]
        end
    end
    return orig_lazymod(name, dict, parent)
end

local hitsnd_prsts = { cod = 77082587278347, ["bubble pop"] = 119697580657161, ["jet set"] = 97113622160405, osu = 123941247147792, whip = 90487264912905, hint = 134763632925481, ["bubble pop 2"] = 104824514322839, ["coin flip"] = 99636386529233, custom = 0 }
local pri_sht_prsts = { glock = 6581933860, tank = 138839154527248, ["tf2 shit"] = 124218436566507, custom = 0 }
local sec_sht_prsts = { ["desert eagle"] = 82286818216627, m1911 = 1136243671, custom = 0 }

wpnmng.getFireSound = function(name, ...)
    local isPistol = false
    if type(name) == "string" then
        local wd = wpnmng.getWeaponData(name)
        if wd and wd.isPistol then isPistol = true end
    end
    
    if isPistol and flgs["custom_sec_shoot_sounds"] then
        local id = 0
        local prst = flgs["sec_shoot_sound_preset"]
        if prst == "custom" then
            local txt = flgs["custom_sec_shoot_sound_id"] or ""
            local num = string.match(txt, "%d+")
            if num then id = tonumber(num) end
        else
            id = sec_sht_prsts[prst] or 0
        end
        if id > 0 then return id end
    elseif not isPistol and flgs["custom_pri_shoot_sounds"] then
        local id = 0
        local prst = flgs["pri_shoot_sound_preset"]
        if prst == "custom" then
            local txt = flgs["custom_pri_shoot_sound_id"] or ""
            local num = string.match(txt, "%d+")
            if num then id = tonumber(num) end
        else
            id = pri_sht_prsts[prst] or 0
        end
        if id > 0 then return id end
    end
    return orig_getfiresnd(name, ...)
end

local box_col = rgb(100, 255, 255)
local trac_col = rgb(100, 100, 255)
local skel_col = rgb(255, 100, 255)
local name_col = rgb(255, 255, 255)
local dist_col = rgb(180, 180, 180)
local chams_col = rgb(170, 85, 235)
local xhair_col = rgb(255, 255, 255)
local dang_col = rgb(255, 0, 0)

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
    
    task.spawn(function()
        if flgs["custom_kill_sounds"] and data.killed then
            local id = 0
            local prst = flgs["kill_sound_preset"]
            if prst == "custom" then
                local txt = flgs["custom_kill_sound_id"] or ""
                local num = string.match(txt, "%d+")
                if num then id = tonumber(num) end
            else
                id = hitsnd_prsts[prst] or 0
            end
            if id > 0 then
                local s = Instance.new("Sound")
                s.SoundId = "rbxassetid://" .. id
                s.Volume = 1
                s.Parent = ws
                s:Play()
                debris:AddItem(s, 5)
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
local dang_inds = {}
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
        hpBar = newdraw("Square", {Filled = true, Visible = false, Color = rgb(0, 255, 0)}),
        tracer = newdraw("Line", {Thickness = 1, Visible = false, Color = trac_col})
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

local function apply_chams(char)
    if not char or not char.Parent then return end
    if not flgs["chams_on"] then
        if char:FindFirstChild("oikwerwe") then char.oikwerwe:Destroy() end
        return
    end
    
    if not char:FindFirstChild("oikwerwe") then
        local h = Instance.new("Highlight")
        h.Name = "oikwerwe"
        h.FillColor = chams_col
        h.OutlineColor = Color3.new(1, 1, 1)
        h.Parent = char
    end
    
    local c = char.oikwerwe
    c.FillColor = chams_col
    c.FillTransparency = 0.5
    c.OutlineTransparency = 0
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

local pri_skins, sec_skins, knf_skins = {}, {}, {}
for k, v in pairs(wpnmng.getWeapons()) do
    if v.isPistol then
        table.insert(sec_skins, k)
    else
        table.insert(pri_skins, k)
    end
end
for k, v in pairs(wpnmng.getKnives()) do table.insert(knf_skins, k) end
table.sort(pri_skins)
table.sort(sec_skins)
table.sort(knf_skins)

local killeff_list = {}
for k, v in pairs(killeffmng.getKillEffects()) do table.insert(killeff_list, k) end
table.sort(killeff_list)

local radar_gui = Instance.new("ScreenGui")
radar_gui.Name = math.random(1, 967676767)
radar_gui.Parent = gethui()
radar_gui.Enabled = false

local radar_frm = Instance.new("Frame", radar_gui)
radar_frm.Size = UDim2.new(0, 150, 0, 150)
radar_frm.Position = UDim2.new(0, 15, 0, 15)
radar_frm.BackgroundColor3 = Color3.new(0, 0, 0)
radar_frm.BackgroundTransparency = 0.5
radar_frm.BorderSizePixel = 0
Instance.new("UICorner", radar_frm).CornerRadius = UDim.new(1, 0)

local radar_cntr = Instance.new("Frame", radar_frm)
radar_cntr.Size = UDim2.new(0, 4, 0, 4)
radar_cntr.Position = UDim2.new(0.5, -2, 0.5, -2)
radar_cntr.BackgroundColor3 = Color3.new(1, 1, 1)
radar_cntr.BorderSizePixel = 0
Instance.new("UICorner", radar_cntr).CornerRadius = UDim.new(1, 0)

local radar_dots = {}
local radar_dot_col = rgb(255, 0, 0)

local wnd = lib:window({ name = "lunar x | one tap", size = UDim2.fromOffset(580, 600) })

local aim_tab = wnd:tab({ name = "aimbot" })
local vis_tab = wnd:tab({ name = "visuals" })
local wpn_tab = wnd:tab({ name = "weapon" })
local skn_tab = wnd:tab({ name = "skins" })
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

aim_cfg:dropdown({ name = "Target Part", flag = "aim_part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, default = "Head" })
aim_cfg:slider({ name = "Smoothness", flag = "aim_smooth", min = 0.01, max = 1, default = 0.15, interval = 0.01, suffix = "x" })
aim_cfg:slider({ name = "Max Distance", flag = "aim_max_dist", min = 50, max = 5000, default = 1000, interval = 50, suffix = " st" })

local esp_sec = vis_tab:section({ name = "player esp", side = "left" })
local trac_sec = vis_tab:section({ name = "tracer config", side = "left" })
local chams_sec = vis_tab:section({ name = "chams", side = "left" })
local fx_sec = vis_tab:section({ name = "effects", side = "left" })
local env_sec = vis_tab:section({ name = "environment", side = "right" })
local xhair_sec = vis_tab:section({ name = "custom crosshair", side = "right" })
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

trac_sec:toggle({ name = "Tracers", flag = "tracers_on", default = false })
trac_sec:colorpicker({ name = "Tracer Color", flag = "tracer_color", color = trac_col, alpha = 0, callback = function(c) trac_col = c end })
trac_sec:slider({ name = "Thickness", flag = "tracer_thick", min = 1, max = 5, default = 1, interval = 1, suffix = "px" })
trac_sec:dropdown({ name = "Origin", flag = "tracer_origin", items = {"Mouse", "HRP", "Arms"}, default = "Mouse" })
trac_sec:dropdown({ name = "Destination", flag = "tracer_dest", items = {"Head", "HRP", "Torso"}, default = "Head" })

chams_sec:toggle({ name = "Chams", flag = "chams_on", default = false })
chams_sec:colorpicker({ name = "Chams Color", flag = "chams_color", color = chams_col, alpha = 0, callback = function(c) chams_col = c end })

fx_sec:toggle({ name = "Danger Indicators", flag = "danger_indicators", default = false })
fx_sec:colorpicker({ name = "Danger Color", flag = "danger_color", color = dang_col, alpha = 0, callback = function(c) dang_col = c end })

local atmosphere = light:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Name = rng()
atmosphere.Parent = light

local function get_cc()
    local cc = light:FindFirstChild("lccc")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "lccc"
        cc.Parent = light
    end
    return cc
end

env_sec:dropdown({ name = "Skybox Preset", flag = "skybox_preset", items = {"default", "space", "nebula", "sword fight", "checker", "67", "larp", "astolfo", "rin tohsaka", "black and white", "sinister", "nick was here", "israel", "tung tung tung sahur", "lore accurate rayquaza", "my goat", "volt", "custom"}, default = "default", callback = function(v)
    for _, obj in pairs(game.Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            obj:Destroy()
        end
    end

    if v == "default" then
        return
    end

    local id = "0"
    if v == "space" then id = "2677508605"
    elseif v == "nebula" then id = "11992958367"
    elseif v == "sword fight" then id = "138569010610226"
    elseif v == "checker" then id = "2424906060"
    elseif v == "67" then id = "123574199714471"
    elseif v == "larp" then id = "92504539826208"
    elseif v == "astolfo" then id = "17871757372"
    elseif v == "rin tohsaka" then id = "18726861143"
    elseif v == "black and white" then id = "11526322514"
    elseif v == "sinister" then id = "80534607281301"
    elseif v == "nick was here" then id = "139071281654202"
    elseif v == "israel" then id = "10012831703"
    elseif v == "tung tung tung sahur" then id = "76287583641908"
    elseif v == "lore accurate rayquaza" then id = "4899954361"
    elseif v == "my goat" then id = "139932718825873"
    elseif v == "volt" then id = "120346696354096"
    elseif v == "custom" then id = tostring(flgs["skybox_id"] or "0") end

    local sky = Instance.new("Sky")
    sky.Name = "Sky"
    sky.SkyboxBk = "rbxassetid://"..id
    sky.SkyboxDn = "rbxassetid://"..id
    sky.SkyboxFt = "rbxassetid://"..id
    sky.SkyboxLf = "rbxassetid://"..id
    sky.SkyboxRt = "rbxassetid://"..id
    sky.SkyboxUp = "rbxassetid://"..id
    sky.Parent = game.Lighting
end})

env_sec:textbox({ name = "Custom Skybox ID", flag = "skybox_id", placeholder = "ID", callback = function() 
    if flgs["skybox_preset"] == "custom" then 
        local p = flgs["skybox_preset"]
        flgs["skybox_preset"] = "default"
        flgs["skybox_preset"] = p 
    end 
end})
env_sec:slider({ name = "Brightness", flag = "env_brightness", min = 0, max = 5, default = 2, interval = 0.1, callback = function(v) light.Brightness = v end })
env_sec:slider({ name = "Time of Day", flag = "env_time", min = 0, max = 24, default = 12, interval = 0.5, callback = function(v) light.ClockTime = v end })
env_sec:slider({ name = "Fog End", flag = "env_fogend", min = 0, max = 100000, default = 100000, interval = 1000, callback = function(v) light.FogEnd = v end })
env_sec:slider({ name = "Fog Start", flag = "env_fogstart", min = 0, max = 100000, default = 0, interval = 1000, callback = function(v) light.FogStart = v end })
env_sec:colorpicker({ name = "Fog Color", flag = "fog_color", color = rgb(128, 128, 128), alpha = 0, callback = function(c) light.FogColor = c end })
env_sec:slider({ name = "Atmosphere Density", flag = "atm_density", min = 0, max = 1, default = 0.3, interval = 0.01, callback = function(v) atmosphere.Density = v end })
env_sec:slider({ name = "Atmosphere Glare", flag = "atm_glare", min = 0, max = 1, default = 0, interval = 0.01, callback = function(v) atmosphere.Glare = v end })
env_sec:slider({ name = "Atmosphere Haze", flag = "atm_haze", min = 0, max = 1, default = 0, interval = 0.01, callback = function(v) atmosphere.Haze = v end })
env_sec:colorpicker({ name = "Atmosphere Color", flag = "atm_color", color = rgb(199, 170, 107), alpha = 0, callback = function(c) atmosphere.Color = c end })
env_sec:colorpicker({ name = "Atmosphere Decay", flag = "atm_decay", color = rgb(106, 112, 125), alpha = 0, callback = function(c) atmosphere.Decay = c end })

env_sec:slider({ name = "Saturation", flag = "saturation", min = -1, max = 1, default = 0, interval = 0.01, callback = function(v) get_cc().Saturation = v end })
env_sec:slider({ name = "Brightness CC", flag = "cc_bright", min = -1, max = 1, default = 0, interval = 0.01, callback = function(v) get_cc().Brightness = v end })
env_sec:slider({ name = "Contrast CC", flag = "cc_contrast", min = -1, max = 1, default = 0, interval = 0.01, callback = function(v) get_cc().Contrast = v end })
env_sec:colorpicker({ name = "CC Tint", flag = "cc_tint", color = rgb(255, 255, 255), alpha = 0, callback = function(c) get_cc().TintColor = c end })

local xhair_lns = {
    top = newdraw("Line", {Thickness = 2, Visible = false, Color = xhair_col}),
    bottom = newdraw("Line", {Thickness = 2, Visible = false, Color = xhair_col}),
    left = newdraw("Line", {Thickness = 2, Visible = false, Color = xhair_col}),
    right = newdraw("Line", {Thickness = 2, Visible = false, Color = xhair_col}),
    dot = newdraw("Circle", {Radius = 2, Filled = true, Visible = false, Color = xhair_col})
}

xhair_sec:toggle({ name = "Crosshair", flag = "xhair_on", default = false, callback = function(v) if not v then for _, l in pairs(xhair_lns) do if l then l.Visible = false end end end end })
xhair_sec:slider({ name = "Size", flag = "xhair_size", min = 2, max = 30, default = 10, interval = 1, suffix = "px" })
xhair_sec:slider({ name = "Gap", flag = "xhair_gap", min = 0, max = 15, default = 3, interval = 1, suffix = "px" })
xhair_sec:toggle({ name = "Center Dot", flag = "xhair_dot", default = true })
xhair_sec:colorpicker({ name = "Color", flag = "xhair_color", color = xhair_col, alpha = 0, callback = function(c) xhair_col = c; for _, l in pairs(xhair_lns) do if l then l.Color = c end end end })

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

local wpn_skn_sec = skn_tab:section({ name = "weapons", side = "left" })
local pri_drp = wpn_skn_sec:dropdown({ name = "Primary Skin", flag = "ot_primary_skin", items = pri_skins, default = "" })
wpn_skn_sec:textbox({ flag = "search_pri", placeholder = "search primary...", callback = function(text)
    local filtered = {}
    for _, item in ipairs(pri_skins) do if string.find(string.lower(item), string.lower(text)) then table.insert(filtered, item) end end
    pri_drp:refresh_options(filtered)
end })
wpn_skn_sec:button({ name = "apply primary", callback = function()
    if lp.Character and lp.Character:GetAttribute("deployed") then
        wpnclnt.setWeapon(1)
        task.wait(0.1)
        wpnclnt.setWeapon(1)
    end
end})

local sec_drp = wpn_skn_sec:dropdown({ name = "Secondary Skin", flag = "ot_secondary_skin", items = sec_skins, default = "" })
wpn_skn_sec:textbox({ flag = "search_sec", placeholder = "search secondary...", callback = function(text)
    local filtered = {}
    for _, item in ipairs(sec_skins) do if string.find(string.lower(item), string.lower(text)) then table.insert(filtered, item) end end
    sec_drp:refresh_options(filtered)
end })
wpn_skn_sec:button({ name = "apply secondary", callback = function()
    if lp.Character and lp.Character:GetAttribute("deployed") then
        wpnclnt.setWeapon(2)
        task.wait(0.1)
        wpnclnt.setWeapon(2)
    end
end})

local knf_skn_sec = skn_tab:section({ name = "knife", side = "left" })
local knf_drp = knf_skn_sec:dropdown({ name = "Select Knife Skin", flag = "ot_knife_skin", items = knf_skins, default = "" })
knf_skn_sec:textbox({ flag = "search_knife", placeholder = "search...", callback = function(text)
    local filtered = {}
    for _, item in ipairs(knf_skins) do if string.find(string.lower(item), string.lower(text)) then table.insert(filtered, item) end end
    knf_drp:refresh_options(filtered)
end })
knf_skn_sec:button({ name = "apply knife", callback = function()
    if lp.Character and lp.Character:GetAttribute("deployed") then
        wpnclnt.setWeapon(3)
        task.wait(0.1)
        wpnclnt.setWeapon(3)
    end
end})

local eff_skn_sec = skn_tab:section({ name = "kill effects", side = "right" })
local eff_drp = eff_skn_sec:dropdown({ name = "Select Kill Effect", flag = "ot_kill_effect", items = killeff_list, default = "" })
eff_skn_sec:textbox({ flag = "search_effect", placeholder = "search...", callback = function(text)
    local filtered = {}
    for _, item in ipairs(killeff_list) do if string.find(string.lower(item), string.lower(text)) then table.insert(filtered, item) end end
    eff_drp:refresh_options(filtered)
end })
eff_skn_sec:button({ name = "apply kill effect", callback = function()
    lib:notification({text = "applied: "..flgs["ot_kill_effect"]})
end})

local misc_sec = misc_tab:section({ name = "local player", side = "left" })
local move_sec = misc_tab:section({ name = "movement", side = "left" })
local radar_sec = misc_tab:section({ name = "radar", side = "left" })
local srv_sec = misc_tab:section({ name = "server", side = "right" })
local snd_sec = misc_tab:section({ name = "sounds", side = "right" })

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

radar_sec:toggle({ name = "Player Radar", flag = "radar_on", default = false, callback = function(v) radar_gui.Enabled = v end })
radar_sec:slider({ name = "Radar Size", flag = "radar_size", min = 50, max = 500, default = 150, interval = 10, callback = function(v) radar_frm.Size = UDim2.new(0, v, 0, v) end })
radar_sec:slider({ name = "Radar Range", flag = "radar_range", min = 100, max = 2000, default = 500, interval = 50, suffix = " st" })
radar_sec:slider({ name = "Radar X", flag = "radar_x", min = 0, max = 1920, default = 15, interval = 1, callback = function(v) radar_frm.Position = UDim2.new(0, v, 0, flgs["radar_y"] or 15) end })
radar_sec:slider({ name = "Radar Y", flag = "radar_y", min = 0, max = 1080, default = 15, interval = 1, callback = function(v) radar_frm.Position = UDim2.new(0, flgs["radar_x"] or 15, 0, v) end })
radar_sec:colorpicker({ name = "Radar Color", flag = "radar_color", color = radar_dot_col, alpha = 0, callback = function(c) radar_dot_col = c end })

srv_sec:button({ name = "Copy j*b ID", callback = function() pcall(function() setclipboard(game.JobId) end) end })
srv_sec:textbox({ name = "j*b ID", flag = "jb_id_input", placeholder = "Enter j*b Id" })
srv_sec:button({ name = "Join Server", callback = function()
    local id = flgs["jb_id_input"]
    if id and id ~= "" then
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, id, lp)
        end)
    else
        lib:notification({text = "pls enter a valid j*b Id"})
    end
end })
srv_sec:button({ name = "Server hop", callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, lp) end })

snd_sec:toggle({ name = "Custom Kill Sounds", flag = "custom_kill_sounds", default = false })
snd_sec:dropdown({ name = "Kill Sound Preset", flag = "kill_sound_preset", items = {"cod", "bubble pop", "jet set", "osu", "whip", "hint", "bubble pop 2", "coin flip", "custom"}, default = "cod" })
snd_sec:textbox({ name = "Custom Kill Sound ID", flag = "custom_kill_sound_id", placeholder = "rbxassetid://" })

snd_sec:toggle({ name = "Custom Primary Shoot Sounds", flag = "custom_pri_shoot_sounds", default = false })
snd_sec:dropdown({ name = "Primary Shoot Sound", flag = "pri_shoot_sound_preset", items = {"glock", "tank", "tf2 shit", "custom"}, default = "glock" })
snd_sec:textbox({ name = "Custom Primary Sound ID", flag = "custom_pri_shoot_sound_id", placeholder = "rbxassetid://" })

snd_sec:toggle({ name = "Custom Secondary Shoot Sounds", flag = "custom_sec_shoot_sounds", default = false })
snd_sec:dropdown({ name = "Secondary Shoot Sound", flag = "sec_shoot_sound_preset", items = {"desert eagle", "m1911", "custom"}, default = "m1911" })
snd_sec:textbox({ name = "Custom Secondary Sound ID", flag = "custom_sec_shoot_sound_id", placeholder = "rbxassetid://" })

local cfg_sec = set_tab:section({ name = "configs", side = "left" })
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
local cursor_ln = newdraw("Quad", {Thickness = 0, Filled = true, Visible = false, Color = Color3.new(0, 0, 0)})
local cursor = newdraw("Quad", {Thickness = 0, Filled = true, Visible = false, Color = rgb(100, 100, 255)})
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
    disc_all()
    for char, _ in pairs(esp_objs) do destroy_esp(char) end
    if cursor then cursor:Remove() end
    if cursor_ln then cursor_ln:Remove() end
    for _, l in pairs(xhair_lns) do if l then l:Remove() end end
    radar_gui:Destroy()
    
    uis.MouseIconEnabled = true
    hookmetamethod(game, "__namecall", oldnm)
    hookmetamethod(game, "__index", oldIndex)
    hookmetamethod(game, "__newindex", oldNewIndex)
    
    mdlmng.getWeaponModel = orig_getwpnmdl
    mdlmng.getKnifeModel = orig_getknfmdl
    mdlmng.getWeaponAnimation = orig_getwpnanim
    mdlmng.getKnifeAnimation = orig_getknfanim
    char_mngr.getHoldingWeaponName = orig_getwpnname
    wpnmng.getFireSound = orig_getfiresnd
    tblmngr.lazyLoadModule = orig_lazymod
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

local trig_cd = 0
local auto_shoot_cd = 0
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
    end

    if flgs["xhair_on"] then
        local cx, cy = vp.X / 2, vp.Y / 2
        local sz, gap, thk = flgs["xhair_size"] or 10, flgs["xhair_gap"] or 3, 2
        local col = xhair_col
        local function setL(l, fx, fy, tx, ty) 
            if not l then return end
            l.From, l.To = Vector2.new(fx, fy), Vector2.new(tx, ty)
            l.Thickness, l.Color, l.Visible = thk, col, true 
        end
        setL(xhair_lns.top, cx, cy - gap - sz, cx, cy - gap)
        setL(xhair_lns.bottom, cx, cy + gap, cx, cy + gap + sz)
        setL(xhair_lns.left, cx - gap - sz, cy, cx - gap, cy)
        setL(xhair_lns.right, cx + gap, cy, cx + gap + sz, cy)
        if xhair_lns.dot then
            xhair_lns.dot.Visible = flgs["xhair_dot"] == true
            xhair_lns.dot.Position = Vector2.new(cx, cy)
            xhair_lns.dot.Color = col
        end
    else
        for _, l in pairs(xhair_lns) do if l then l.Visible = false end end
    end

    if flgs["spin_on"] then
        local r = getroot()
        if r then
            r.CFrame = r.CFrame * CFrame.Angles(0, math.rad((flgs["spin_speed"] or 180) * dt), 0)
        end
    end

    if flgs["danger_indicators"] and rootPos then
        for _, char in ipairs(get_targs()) do
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local h = char:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                local dirToTarget = (hrp.Position - rootPos)
                local dist = dirToTarget.Magnitude
                if dist < 300 then
                    local relPos = cam.CFrame:VectorToObjectSpace(dirToTarget)
                    if relPos.Z < 0 then
                        local angle = math.atan2(relPos.X, -relPos.Y)
                        local radius = 200
                        local ex = vp.X/2 + math.cos(angle) * radius
                        local ey = vp.Y/2 + math.sin(angle) * radius
                        
                        if not dang_inds[char] then
                            dang_inds[char] = newdraw("Text", {Size = 13, Center = true, Outline = true, Visible = false, Color = dang_col, Font = 2})
                        end
                        dang_inds[char].Text = "!\n"..math.floor(dist).."m"
                        dang_inds[char].Position = Vector2.new(ex, ey)
                        dang_inds[char].Color = dang_col
                        dang_inds[char].Visible = true
                    else
                        if dang_inds[char] then dang_inds[char].Visible = false end
                    end
                else
                    if dang_inds[char] then dang_inds[char].Visible = false end
                end
            else
                if dang_inds[char] then dang_inds[char]:Remove(); dang_inds[char] = nil end
            end
        end
    else
        for char, d in pairs(dang_inds) do d:Remove() end
        dang_inds = {}
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
            if d.tracer then d.tracer.Visible = false end
            for _, l in ipairs(d.corners) do if l then l.Visible = false end end
            for _, l in ipairs(d.skeleton) do if l then l.Visible = false end end
        end

        if not espOn or h.Health <= 0 then hideAll(); continue end
        if rootPos and (hrp.Position - rootPos).Magnitude > (flgs["esp_max_dist"] or 800) then hideAll(); continue end

        apply_chams(char)

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

        if flgs["tracers_on"] and d.tracer then
            local origin = flgs["tracer_origin"] or "Mouse"
            local fromX = origin == "Mouse" and mp.X or vp.X / 2
            local fromY = origin == "Mouse" and mp.Y or vp.Y
            
            local dest = flgs["tracer_dest"] or "Head"
            local destPart = char:FindFirstChild(dest) or hrp
            local destSP = cam:WorldToViewportPoint(destPart.Position)
            
            d.tracer.From = Vector2.new(fromX, fromY); d.tracer.To = Vector2.new(destSP.X, destSP.Y)
            d.tracer.Color = trac_col; d.tracer.Thickness = flgs["tracer_thick"] or 1; d.tracer.Visible = true
        else 
            if d.tracer then d.tracer.Visible = false end 
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
    local rootPos = getroot() and getroot().Position
    if flgs["radar_on"] and rootPos then
        for _, char in ipairs(get_targs()) do
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local h = char:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                local relPos = cam.CFrame:PointToObjectSpace(hrp.Position)
                local dist = (hrp.Position - rootPos).Magnitude
                if dist < (flgs["radar_range"] or 500) then
                    if not radar_dots[char] then
                        radar_dots[char] = Instance.new("Frame", radar_frm)
                        radar_dots[char].Size = UDim2.new(0, 4, 0, 4)
                        radar_dots[char].BorderColor3 = Color3.new(0, 0, 0)
                        Instance.new("UICorner", radar_dots[char]).CornerRadius = UDim.new(1, 0)
                    end
                    radar_dots[char].BackgroundColor3 = radar_dot_col
                    local scale = (flgs["radar_size"] or 150) / 2
                    radar_dots[char].Position = UDim2.new(0.5, relPos.X / (flgs["radar_range"] or 500) * scale, 0.5, relPos.Z / (flgs["radar_range"] or 500) * scale)
                else
                    if radar_dots[char] then radar_dots[char]:Destroy(); radar_dots[char] = nil end
                end
            else
                if radar_dots[char] then radar_dots[char]:Destroy(); radar_dots[char] = nil end
            end
        end
    else
        for _, dot in pairs(radar_dots) do dot:Destroy() end
        radar_dots = {}
    end
end)

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
