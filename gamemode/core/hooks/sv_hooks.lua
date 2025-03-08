util.AddNetworkString("ixPlayerDeath")
util.AddNetworkString("ixPlayerStartVoice")
util.AddNetworkString("ixPlayerEndVoice")
util.AddNetworkString("ixStartChat")
util.AddNetworkString("ixFinishChat")

function GM:PlayerInitialSpawn(ply)
    ply.ixJoinTime = RealTime()

    if (ply:IsBot()) then
        local botID = os.time() + ply:EntIndex()
        local index = math.random(table.Count(ix.faction.indices))
        local faction = ix.faction.indices[index]

        local model = "models/player.mdl"
        if (faction.models) then
            if (istable(faction.models)) then
                local data = faction.models[math.random(#faction.models)]
                model = data[1]
            else
                model = faction.models
            end
        end

        local char = ix.char.New({
            name = ply:Nick(),
            faction = faction and faction.uniqueID or "unknown",
            model = faction and model or "models/gman.mdl"
        }, botID, ply, ply:SteamID64())
        char.isBot = true

        local inventory = ix.inventory.Create(ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight"), botID)
        inventory:SetOwner(botID)
        inventory.noSave = true

        char.vars.inv = {inventory}

        ix.char.loaded[botID] = char

        char:Setup()
        ply:Spawn()

        ix.chat.Send(nil, "connect", ply:SteamName())

        return
    end

    ix.config.Send(ply)
    ix.date.Send(ply)

    ply:LoadData(function(data)
        if (!IsValid(ply)) then return end

        -- Don't use the char cache if they've connected to another server using the same database
        local address = ix.util.GetAddress()
        local bNoCache = ply:GetData("lastIP", address) != address
        ply:SetData("lastIP", address)

        net.Start("ixDataSync")
            net.WriteTable(data or {})
            net.WriteUInt(ply.ixPlayTime or 0, 32)
        net.Send(ply)

        ix.char.Restore(ply, function(charList)
            if (!IsValid(ply)) then return end

            MsgN("Loaded (" .. table.concat(charList, ", ") .. ") for " .. ply:Nick())

            for _, v in ipairs(charList) do
                ix.char.loaded[v]:Sync(ply)
            end

            ply.ixCharList = charList

            net.Start("ixCharacterMenu")
            net.WriteUInt(#charList, 6)

            for _, v in ipairs(charList) do
                net.WriteUInt(v, 32)
            end

            net.Send(ply)

            ply.ixLoaded = true
            ply:SetData("intro", true)

            for _, v in player.Iterator() do
                if (v:GetCharacter()) then
                    v:GetCharacter():Sync(ply)
                end
            end
        end, bNoCache)

        ix.chat.Send(nil, "connect", ply:SteamName())
    end)

    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:Lock()
    ply:SyncVars()

    timer.Simple(1, function()
        if (!IsValid(ply)) then return end

        ply:KillSilent()
        ply:StripAmmo()
    end)
end

function GM:PlayerUse(ply, entity)
    if (ply:IsRestricted() or (isfunction(entity.GetEntityMenu) and entity:GetClass() != "ix_item")) then return false end

    return true
end

function GM:KeyPress(ply, key)
    if (key == IN_RELOAD) then
        timer.Create("ixToggleRaise" .. ply:SteamID(), ix.config.Get("weaponRaiseTime"), 1, function()
            if (IsValid(ply)) then
                ply:ToggleWepRaised()
            end
        end)
    elseif (key == IN_USE) then
        local data = {}
            data.start = ply:GetShootPos()
            data.endpos = data.start + ply:GetAimVector() * 96
            data.filter = ply
        local entity = util.TraceLine(data).Entity

        if (IsValid(entity) and hook.Run("PlayerUse", ply, entity)) then
            if (entity:IsDoor()) then
                local result = hook.Run("CanPlayerUseDoor", ply, entity)
                if (result != false) then
                    hook.Run("PlayerUseDoor", ply, entity)
                end
            end
        end
    end
end

function GM:KeyRelease(ply, key)
    if (key == IN_RELOAD) then
        timer.Remove("ixToggleRaise" .. ply:SteamID())
    elseif (key == IN_USE) then
        timer.Remove("ixCharacterInteraction" .. ply:SteamID())
    end
end

function GM:CanPlayerInteractItem(ply, action, item, data)
    if (ply:IsRestricted()) then return false end

    if (IsValid(ply.ixRagdoll)) then
        ply:NotifyLocalized("notNow")
        return false
    end

    if (action == "drop" and hook.Run("CanPlayerDropItem", ply, item) == false) then return false end
    if (action == "take" and hook.Run("CanPlayerTakeItem", ply, item) == false) then return false end

    if (action == "combine") then
        local other = data[1]

        if (hook.Run("CanPlayerCombineItem", ply, item, other) == false) then return false end

        local combineItem = ix.item.instances[other]

        if (combineItem and combineItem.invID != 0) then
            local combineInv = ix.item.inventories[combineItem.invID]

            if (!combineInv:OnCheckAccess(ply)) then
                return false
            end
        else
            return false
        end
    end

    if (isentity(item) and item.ixSteamID and item.ixCharID and item.ixSteamID == ply:SteamID() and item.ixCharID != ply:GetCharacter():GetID() and !item:GetItemTable().bAllowMultiCharacterInteraction and ix.config.Get("itemOwnership", false)) then
        ply:NotifyLocalized("itemOwned")
        return false
    end

    return ply:Alive()
end

function GM:CanPlayerDropItem(ply, item)
    -- Check if the player is able to drop the item.
end

function GM:CanPlayerTakeItem(ply, item)
    -- Check if the player is able to take the item.
end

function GM:CanPlayerCombineItem(ply, item, other)
    -- Check if the player is able to combine the item with another.
end

function GM:PlayerShouldTakeDamage(ply, attacker)
    return ply:GetCharacter() != nil
end

function GM:GetFallDamage(ply, speed)
    return ( speed - 580 ) * ( 100 / 444 )
end

function GM:EntityTakeDamage(entity, dmgInfo)
    local inflictor = dmgInfo:GetInflictor()
    if (IsValid(inflictor) and inflictor:GetClass() == "ix_item") then
        dmgInfo:SetDamage(0)
        return
    end

    if (IsValid(entity.ixPlayer)) then
        if (IsValid(entity.ixHeldOwner)) then
            dmgInfo:SetDamage(0)
            return
        end

        if (dmgInfo:IsDamageType(DMG_CRUSH)) then
            if ((entity.ixFallGrace or 0) < CurTime()) then
                if (dmgInfo:GetDamage() <= 10) then
                    dmgInfo:SetDamage(0)
                end

                entity.ixFallGrace = CurTime() + 0.1
            else
                return
            end

            local add = entity:GetVelocity():Length() / 32
            dmgInfo:AddDamage(add)
        end

        debugoverlay.Axis(dmgInfo:GetDamagePosition(), Angle(0, 0, 0), 5, 5, true)

        -- Scale the damage to be more realistic
        dmgInfo:ScaleDamage(dmgInfo:GetDamageForce():Length() / 1024)

        entity.ixPlayer:TakeDamageInfo(dmgInfo)
    end
end

function GM:PrePlayerLoadedCharacter(ply, char, lastChar)
    -- Reset all bodygroups
    ply:ResetBodygroups()

    -- Remove all skins
    ply:SetSkin(0)
end

function GM:PlayerLoadedCharacter(ply, char, lastChar)
    local query = mysql:Update("ix_characters")
        query:Where("id", char:GetID())
        query:Update("last_join_time", math.floor(os.time()))
    query:Execute()

    if (lastChar) then
        local charEnts = lastChar:GetVar("charEnts") or {}

        for _, v in ipairs(charEnts) do
            if (v and IsValid(v)) then
                v:Remove()
            end
        end

        lastChar:SetVar("charEnts", nil)
    end

    if (char) then
        for _, v in ipairs(ix.class.list) do
            if (v.faction == ply:Team() and v.isDefault) then
                char:SetClass(v.index)

                break
            end
        end

        for _, v in ipairs(ix.rank.list) do
            if (v.faction == ply:Team() and v.isDefault) then
                char:SetRank(v.index)

                break
            end
        end
    end

    local plyInfo = ply:GetTable()
    if (IsValid(plyInfo.ixRagdoll)) then
        plyInfo.ixRagdoll.ixNoReset = true
        plyInfo.ixRagdoll.ixIgnoreDelete = true
        plyInfo.ixRagdoll:Remove()
    end

    local faction = ix.faction.indices[char:GetFaction()]
    local uniqueID = "ixSalary" .. ply:SteamID64()

    if (faction and faction.pay and faction.pay > 0) then
        timer.Create(uniqueID, faction.payTime or 300, 0, function()
            if (IsValid(ply)) then
                if (hook.Run("CanPlayerEarnSalary", ply, faction) != false) then
                    local pay = hook.Run("GetSalaryAmount", ply, faction) or faction.pay

                    char:GiveMoney(pay)
                    ply:NotifyLocalized("salary", ix.currency.Get(pay))
                    hook.Run("OnPlayerEarnSalary", ply, faction, pay)
                end
            else
                timer.Remove(uniqueID)
            end
        end)
    elseif (timer.Exists(uniqueID)) then
        timer.Remove(uniqueID)
    end

    hook.Run("PlayerLoadout", ply)
end

function GM:CharacterLoaded(char)
    local ply = char:GetPlayer()

    if (IsValid(ply)) then
        local uniqueID = "ixSaveChar" .. ply:SteamID()

        timer.Create(uniqueID, ix.config.Get("saveInterval"), 0, function()
            if (IsValid(ply) and ply:GetCharacter()) then
                ply:GetCharacter():Save()
            else
                timer.Remove(uniqueID)
            end
        end)
    end
end

function GM:PlayerSay(ply, text)
    local chatType, message, anonymous = ix.chat.Parse(ply, text, true)

    if (chatType == "ic") then
        if (ix.command.Parse(ply, message)) then
            return ""
        end
    end

    text = ix.chat.Send(ply, chatType, message, anonymous)

    if (isstring(text) and chatType != "ic") then
        ix.log.Add(ply, "chat", chatType and chatType:utf8upper() or "??", text)
    end

    hook.Run("PostPlayerSay", ply, chatType, message, anonymous)

    return ""
end

function GM:CanAutoFormatMessage(ply, chatType, message)
    return chatType == "ic" or chatType == "w" or chatType == "y"
end

function GM:PlayerSpawn(ply)
    ply:ResetBoneMatrix()
    ply:SetNoDraw(false)
    ply:UnLock()
    ply:SetNotSolid(false)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetRagdolled(false)
    ply:SetAction()
    ply:SetDSP(1)

    hook.Run("PlayerLoadout", ply)
end

-- Shortcuts for (super)admin only things.
local function IsAdmin(_, ply)
    return ply:IsAdmin()
end

-- Set the gamemode hooks to the appropriate shortcuts.
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnSENT = IsAdmin

function GM:PlayerSpawnNPC(ply, npcType, weapon)
    return ply:IsAdmin() or ply:GetCharacter():HasFlags("n")
end

function GM:PlayerSpawnSWEP(ply, weapon, info)
    return ply:IsAdmin()
end

function GM:PlayerSpawnProp(ply)
    if (ply:GetCharacter() and ply:GetCharacter():HasFlags("e")) then return true end

    return false
end

function GM:PlayerSpawnRagdoll(ply)
    if (ply:GetCharacter() and ply:GetCharacter():HasFlags("r")) then return true end

    return false
end

function GM:PlayerSpawnVehicle(ply, model, name, data)
    if (ply:GetCharacter()) then
        if (data.Category == "Chairs") then
            return ply:GetCharacter():HasFlags("c")
        else
            return ply:GetCharacter():HasFlags("C")
        end
    end

    return false
end

function GM:PlayerSpawnedEffect(ply, model, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedNPC(ply, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedProp(ply, model, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedRagdoll(ply, model, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedSENT(ply, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedSWEP(ply, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

function GM:PlayerSpawnedVehicle(ply, entity)
    entity:SetNetVar("owner", ply:GetCharacter():GetID())
end

ix.allowedHoldableClasses = {
    ["ix_item"] = true,
    ["ix_money"] = true,
    ["ix_shipment"] = true,
    ["prop_physics"] = true,
    ["prop_physics_override"] = true,
    ["prop_physics_multiplayer"] = true,
    ["prop_ragdoll"] = true,
    ["func_physbox"] = true,
    ["npc_turret_floor"] = true,
}

function GM:CanPlayerHoldObject(ply, entity)
    if (ix.allowedHoldableClasses[entity:GetClass()]) then return true end
end

local voiceDistance = 360000
local function CalcPlayerCanHearPlayersVoice(listener)
    if (!IsValid(listener)) then return end

    listener.ixVoiceHear = listener.ixVoiceHear or {}

    local eyePos = listener:EyePos()
    for _, speaker in player.Iterator() do
        local speakerEyePos = speaker:EyePos()
        listener.ixVoiceHear[speaker] = eyePos:DistToSqr(speakerEyePos) < voiceDistance
    end
end

function GM:InitializedConfig()
    ix.date.Initialize()

    voiceDistance = ix.config.Get("voiceDistance")
    voiceDistance = voiceDistance ^ 2
end

function GM:VoiceToggled(bAllowVoice)
    for _, v in player.Iterator() do
        local uniqueID = v:SteamID64() .. "ixCanHearPlayersVoice"

        if (bAllowVoice) then
            timer.Create(uniqueID, 0.5, 0, function()
                CalcPlayerCanHearPlayersVoice(v)
            end)
        else
            timer.Remove(uniqueID)

            v.ixVoiceHear = nil
        end
    end
end

function GM:VoiceDistanceChanged(distance)
    voiceDistance = distance ^ 2
end

-- Called when weapons should be given to a player.
function GM:PlayerLoadout(ply)
    if (ply.ixSkipLoadout) then
        ply.ixSkipLoadout = nil

        return
    end

    ply:SetWeaponColor(Vector(ply:GetInfo("cl_weaponcolor")))
    ply:StripWeapons()
    ply:StripAmmo()
    ply:SetLocalVar("blur", nil)

    local char = ply:GetCharacter()

    -- Check if they have loaded a char.
    if (char) then
        ply:SetupHands()
        -- Set their player model to the char's model.

        local charModel = char:GetModel()
        if ( istable(charModel) ) then
            charModel = charModel[math.random(#charModel)]
        end

        ply:SetModel(charModel)
        ply:Give("ix_hands")
        ply:SetWalkSpeed(ix.config.Get("walkSpeed"))
        ply:SetRunSpeed(ix.config.Get("runSpeed"))
        ply:SetHealth(char:GetData("health", ply:GetMaxHealth()))

        local faction = ix.faction.indices[ply:Team()]
        if (faction) then
            -- If their faction wants to do something when the player spawns, let it.
            if (faction.OnSpawn) then
                faction:OnSpawn(ply)
            end

            -- @todo add docs for player:Give() failing if player already has weapon - which means if a player is given a weapon
            -- here due to the faction weapons table, the weapon's :Give call in the weapon base will fail since the player
            -- will already have it by then. This will cause issues for weapons that have pac data since the parts are applied
            -- only if the weapon returned by :Give() is valid

            -- If the faction has default weapons, give them to the player.
            if (faction.weapons) then
                for _, v in ipairs(faction.weapons) do
                    ply:Give(v)
                end
            end
        end

        -- Ditto, but for classes.
        local class = ix.class.list[ply:GetCharacter():GetClass()]
        if (class) then
            if (class.OnSpawn) then
                class:OnSpawn(ply)
            end

            if (class.weapons) then
                for _, v in ipairs(class.weapons) do
                    ply:Give(v)
                end
            end
        end

        -- Ditto, but for ranks.
        local rank = ix.rank.list[ply:GetCharacter():GetRank()]
        if (rank) then
            if (rank.OnSpawn) then
                rank:OnSpawn(ply)
            end

            if (rank.weapons) then
                for _, v in ipairs(rank.weapons) do
                    ply:Give(v)
                end
            end
        end

        -- Apply any flags as needed.
        ix.flag.OnSpawn(ply)
        ix.attributes.Setup(ply)

        hook.Run("PostPlayerLoadout", ply)

        ply:SelectWeapon("ix_hands")
    else
        ply:SetNoDraw(true)
        ply:Lock()
        ply:SetNotSolid(true)
    end
end

function GM:PostPlayerLoadout(ply)
    -- Reload All Attrib Boosts
    local char = ply:GetCharacter()
    if (char:GetInventory()) then
        for k, _ in char:GetInventory():Iter() do
			k:Call("OnLoadout", ply)

			if (k:GetData("equip") and k.attribBoosts) then
				for attribKey, attribValue in pairs(k.attribBoosts) do
					char:AddBoost(k.uniqueID, attribKey, attribValue)
				end
			end
		end
    end

    -- If their faction wants to do something when the player's loadout is set, let it.
    local faction = ix.faction.indices[ply:Team()]
    if (faction and faction.OnLoadout) then
        faction:OnLoadout(ply)
    end

    -- Ditto, but for classes.
    local class = ix.class.list[char:GetClass()]
    if (class and class.OnLoadout) then
        class:OnLoadout(ply)
    end

    -- Ditto, but for ranks.
    local rank = ix.rank.list[char:GetRank()]
    if (rank and rank.OnLoadout) then
        rank:OnLoadout(ply)
    end

    if (ix.config.Get("allowVoice")) then
        if ( timer.Exists(ply:SteamID64() .. "ixCanHearPlayersVoice") ) then
            timer.Remove(ply:SteamID64() .. "ixCanHearPlayersVoice")
        end

        timer.Create(ply:SteamID64() .. "ixCanHearPlayersVoice", 0.5, 0, function()
            CalcPlayerCanHearPlayersVoice(ply)
        end)
    end
end

local deathSounds = {
    Sound("vo/npc/male01/pain07.wav"),
    Sound("vo/npc/male01/pain08.wav"),
    Sound("vo/npc/male01/pain09.wav")
}

function GM:DoPlayerDeath(ply, attacker, damageinfo)
    ply:AddDeaths(1)

    if (hook.Run("ShouldSpawnClientRagdoll", ply) != false) then
        ply:CreateRagdoll()
    end

    if (IsValid(attacker) and attacker:IsPlayer()) then
        if (ply == attacker) then
            attacker:AddFrags(-1)
        else
            attacker:AddFrags(1)
        end
    end

    net.Start("ixPlayerDeath")
    net.Send(ply)

    ply:SetAction("@respawning", ix.config.Get("spawnTime", 5))
    ply:SetDSP(31)
end

function GM:PlayerDeath(ply, inflictor, attacker)
    local char = ply:GetCharacter()
    if (char) then
        if (IsValid(ply.ixRagdoll)) then
            ply.ixRagdoll.ixIgnoreDelete = true
            ply:SetLocalVar("blur", nil)

            if (hook.Run("ShouldRemoveRagdollOnDeath", ply) != false) then
                ply.ixRagdoll:Remove()
            end
        end

        ply:SetNetVar("deathStartTime", CurTime())
        ply:SetNetVar("deathTime", CurTime() + ix.config.Get("spawnTime", 5))

        char:SetData("health", nil)

        local deathSound = hook.Run("GetPlayerDeathSound", ply)

        if (deathSound != false) then
            deathSound = deathSound or deathSounds[math.random(1, #deathSounds)]

            if (ply:IsFemale() and !deathSound:find("female")) then
                deathSound = deathSound:gsub("male", "female")
            end

            ply:EmitSound(deathSound)
        end

        local weapon = attacker:IsPlayer() and attacker:GetActiveWeapon()
        local weaponText = IsValid(weapon) and weapon:GetClass()

        if ( attacker:IsPlayer() and attacker:InVehicle() and IsValid(attacker:GetVehicle()) ) then
            weaponText = attacker:GetVehicle():GetClass()
        end

        ix.log.Add(ply, "playerDeath", attacker:GetName() != "" and attacker:GetName() or attacker:GetClass(), weaponText)
    end
end

local painSounds = {
    Sound("vo/npc/male01/pain01.wav"),
    Sound("vo/npc/male01/pain02.wav"),
    Sound("vo/npc/male01/pain03.wav"),
    Sound("vo/npc/male01/pain04.wav"),
    Sound("vo/npc/male01/pain05.wav"),
    Sound("vo/npc/male01/pain06.wav")
}

local drownSounds = {
    Sound("player/pl_drown1.wav"),
    Sound("player/pl_drown2.wav"),
    Sound("player/pl_drown3.wav"),
}

function GM:GetPlayerPainSound(ply)
    if (ply:WaterLevel() >= 3) then
        return drownSounds[math.random(#drownSounds)]
    end
end

function GM:PlayerHurt(ply, attacker, health, damage)
    if ((ply.ixNextPain or 0) < CurTime() and health > 0) then
        local painSound = hook.Run("GetPlayerPainSound", ply) or painSounds[math.random(#painSounds)]

        if (ply:IsFemale() and !painSound:find("female")) then
            painSound = painSound:gsub("male", "female")
        end

        ply:EmitSound(painSound)
        ply.ixNextPain = CurTime() + 0.33
    end

    local name = IsValid(attacker) and (attacker.GetName and attacker:GetName() or attacker:GetClass()) or "world"
    local weapon = IsValid(attacker) and attacker.GetActiveWeapon and attacker:GetActiveWeapon()
    local weaponText = IsValid(weapon) and (weapon.GetPrintName and weapon:GetPrintName() or weapon:GetClass())

    ix.log.Add(ply, "playerHurt", damage, name, weaponText)
end

function GM:PlayerDeathThink(ply)
    if (ply:GetCharacter()) then
        local deathTime = ply:GetNetVar("deathTime")
        if (deathTime and deathTime <= CurTime()) then
            ply:Spawn()
        end
    end

    return false
end

function GM:PlayerDisconnected(ply)
    ply:SaveData()

    local char = ply:GetCharacter()
    if (char) then
        local charEnts = char:GetVar("charEnts") or {}

        for _, v in ipairs(charEnts) do
            if (v and IsValid(v)) then
                v:Remove()
            end
        end

        hook.Run("OnCharacterDisconnect", ply, char)
            char:Save()
        ix.chat.Send(nil, "disconnect", ply:SteamName())
    end

    local plyInfo = ply:GetTable()
    if (IsValid(plyInfo.ixRagdoll)) then
        plyInfo.ixRagdoll:Remove()
    end

    ply:ClearNetVars()

    if (!plyInfo.ixVoiceHear) then return end

    for _, v in player.Iterator() do
        if (!v.ixVoiceHear) then continue end

        v.ixVoiceHear[ply] = nil
    end

    if ( timer.Exists(ply:SteamID64() .. "ixCanHearPlayersVoice") ) then
        timer.Remove(ply:SteamID64() .. "ixCanHearPlayersVoice")
    end
end

function GM:InitPostEntity()
    local doors = ents.FindByClass("prop_door_rotating")

    for _, v in ipairs(doors) do
        local parent = v:GetOwner()

        if (IsValid(parent)) then
            v.ixPartner = parent
            parent.ixPartner = v
        else
            for _, v2 in ipairs(doors) do
                if (v2:GetOwner() == v) then
                    v2.ixPartner = v
                    v.ixPartner = v2

                    break
                end
            end
        end
    end

    timer.Simple(2, function()
        ix.entityDataLoaded = true
    end)
end

function GM:SaveData()
    ix.date.Save()

    -- Go through all doors and set their networked vars wether or not they are locked
    local doors = {}
    for _, v in ipairs(ents.GetAll()) do
        if (v:IsDoor()) then
            doors[#doors + 1] = v:EntIndex()
        end
    end

    if (#doors > 0) then
        for _, v in ipairs(doors) do
            local entity = Entity(v)

            if (IsValid(entity)) then
                local partner = entity.ixPartner

                if (IsValid(partner)) then
                    entity:SetNetVar("locked", entity:GetSaveTable().m_bLocked)
                    partner:SetNetVar("locked", entity:GetSaveTable().m_bLocked)
                end
            end
        end
    end

    -- Do the same for vehicles .. .
    local vehicles = {}
    for _, v in ipairs(ents.GetAll()) do
        if (v:IsVehicle()) then
            vehicles[#vehicles + 1] = v:EntIndex()
        end
    end

    if (#vehicles > 0) then
        for _, v in ipairs(vehicles) do
            local entity = Entity(v)

            if (IsValid(entity)) then
                entity:SetNetVar("locked", entity:GetSaveTable().VehicleLocked)
            end
        end
    end
end

function GM:ShutDown()
    ix.shuttingDown = true
    ix.config.Save()

    hook.Run("SaveData")

    for _, v in player.Iterator() do
        v:SaveData()

        if (v:GetCharacter()) then
            v:GetCharacter():Save()
        end
    end
end

function GM:GetGameDescription()
    return "IX: " .. (Schema and Schema.name or "Unknown")
end

function GM:OnPlayerUseBusiness(ply, item)
    -- You can manipulate purchased items with this hook.
    -- does not requires any kind of return.
    -- ex) item:SetData("businessItem", true)
    -- then every purchased item will be marked as Business Item.
end

function GM:PlayerDeathSound()
    return true
end

function GM:InitializedSchema()
    game.ConsoleCommand("sbox_persist ix_" .. Schema.folder .. "\n")
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
    if (!speaker:Alive()) then return false end

    local bCanHear = listener.ixVoiceHear and listener.ixVoiceHear[speaker]
    return bCanHear, true
end

function GM:PlayerCanPickupWeapon(ply, weapon)
    local data = {}
        data.start = ply:GetShootPos()
        data.endpos = data.start + ply:GetAimVector() * 96
        data.filter = ply
    local trace = util.TraceLine(data)

    if (trace.Entity == weapon and ply:KeyDown(IN_USE)) then return true end

    return ply.ixWeaponGive
end

function GM:OnPhysgunFreeze(weapon, physObj, entity, ply)
    -- Validate the physObj parameter
    if (!IsValid(physObj)) then return false end

    -- Object is already frozen (!?)
    if (!physObj:IsMoveable()) then return false end
    if (entity:GetUnFreezable()) then return false end

    physObj:EnableMotion(false)

    -- With the jeep we need to pause all of its physics objects
    -- to stop it spazzing out and killing the server.
    if (entity:GetClass() == "prop_vehicle_jeep") then
        local objects = entity:GetPhysicsObjectCount()

        for i = 0, objects - 1 do
            entity:GetPhysicsObjectNum(i):EnableMotion(false)
        end
    end

    -- Add it to the player's frozen props
    ply:AddFrozenPhysicsObject(entity, physObj)
    ply:SendHint("PhysgunUnfreeze", 0.3)
    ply:SuppressHint("PhysgunFreeze")

    return true
end

function GM:CanPlayerSuicide(ply)
    return false
end

function GM:AllowPlayerPickup(ply, entity)
    return false
end

function GM:PreCleanupMap()
    hook.Run("SaveData")
    hook.Run("PersistenceSave")
end

function GM:PostCleanupMap()
    ix.plugin.RunLoadData()
end

function GM:CharacterPreSave(char)
    local ply = char:GetPlayer()

    for v in char:GetInventory():Iter() do
		if (v.OnSave) then
			v:Call("OnSave", ply)
        end
    end

    char:SetData("health", ply:Alive() and ply:Health() or nil)
end

timer.Create("ixLifeGuard", 1, 0, function()
    for _, v in player.Iterator() do
        if (v:GetCharacter() and v:Alive() and hook.Run("ShouldPlayerDrowned", v) != false) then
            local vInfo = v:GetTable()
            if (v:WaterLevel() >= 3) then
                if (!vInfo.drowningTime) then
                    vInfo.drowningTime = CurTime() + 30
                    vInfo.nextDrowning = CurTime()
                    vInfo.drownDamage = vInfo.drownDamage or 0
                end

                if (vInfo.drowningTime < CurTime()) then
                    if (vInfo.nextDrowning < CurTime()) then
                        v:ScreenFade(1, Color(0, 0, 255, 100), 1, 0)
                        v:TakeDamage(10)
                        vInfo.drownDamage = vInfo.drownDamage + 10
                        vInfo.nextDrowning = CurTime() + 1
                    end
                end
            else
                if (vInfo.drowningTime) then
                    vInfo.drowningTime = nil
                    vInfo.nextDrowning = nil
                    vInfo.nextRecover = CurTime() + 2
                end

                if (vInfo.nextRecover and vInfo.nextRecover < CurTime() and vInfo.drownDamage > 0) then
                    vInfo.drownDamage = vInfo.drownDamage - 10
                    v:SetHealth(math.Clamp(v:Health() + 10, 0, v:GetMaxHealth()))
                    vInfo.nextRecover = CurTime() + 1
                end
            end
        end
    end
end)

net.Receive("ixStringRequest", function(length, ply)
    local time = net.ReadUInt(32)
    local text = net.ReadString()

    local plyInfo = ply:GetTable()
    if (plyInfo.ixStrReqs and plyInfo.ixStrReqs[time]) then
        plyInfo.ixStrReqs[time](text)
        plyInfo.ixStrReqs[time] = nil
    end
end)

function GM:GetPreferredCarryAngles(entity)
    if (entity:GetClass() == "ix_item") then
        local itemTable = entity:GetItemTable()

        if (itemTable) then
            local preferedAngle = itemTable.preferedAngle

            if (preferedAngle) then -- I don't want to return something
                return preferedAngle
            end
        end
    end
end

function GM:PluginShouldLoad(uniqueID)
    return !ix.plugin.unloaded[uniqueID]
end

function GM:DatabaseConnected()
    -- Create the SQL tables if they do not exist.
    ix.db.LoadTables()
    ix.log.LoadTables()

    MsgC(Color(0, 255, 0), "Database Type: " .. ix.db.config.adapter .. ".\n")

    timer.Create("ixDatabaseThink", 0.5, 0, function()
        mysql:Think()
    end)

    ix.plugin.RunLoadData()
end

function GM:DatabaseConnectionFailed()
    -- Set a net var so the client knows that the database connection failed.
    SetGlobalString("fatalError", "Database connection failed")
end

net.Receive("ixPlayerStartVoice", function(len)
    local target = net.ReadPlayer()
    if ( !IsValid(target) or !target:Alive() ) then return end

    hook.Run("PlayerStartVoice", target)
end)

net.Receive("ixPlayerEndVoice", function(len)
    local target = net.ReadPlayer()
    if ( !IsValid(target) or !target:Alive() ) then return end

    hook.Run("PlayerEndVoice", target)
end)

net.Receive("ixStartChat", function(len, ply)
    if ( !IsValid(ply) ) then return end

    local char = ply:GetCharacter()
    if ( !char ) then return end

    local bTeamChat = net.ReadBool()

    hook.Run("StartChat", ply, bTeamChat)
end)

net.Receive("ixFinishChat", function(len, ply)
    if ( !IsValid(ply) ) then return end

    local char = ply:GetCharacter()
    if ( !char ) then return end

    hook.Run("FinishChat", ply)
end)

net.Receive("ixMapRestart", function(len, ply)
    if ( !IsValid(ply) ) then return end
    if ( !CAMI.PlayerHasAccess(ply, "Helix - MapRestart", nil) ) then return end

    local delay = net.ReadFloat()
    
    ix.util.NotifyLocalized("mapRestarting", nil, delay)

    timer.Simple(delay, function()
        RunConsoleCommand("changelevel", game.GetMap())
    end)
end)