local Vector = Vector
local ix = ix
local IsValid = IsValid
local isstring = isstring
local isvector = isvector
local util = util
local debugoverlay = debugoverlay
local Color = Color
local CurTime = CurTime
local istable = istable
local pairs = pairs
local hook = hook
local IsFirstTimePredicted = IsFirstTimePredicted
local net = net
local FindMetaTable = FindMetaTable
local math = math
local isnumber = isnumber
local os = os
local ipairs = ipairs
local isfunction = isfunction
local baseclass = baseclass

function GM:PlayerNoClip(client)
    return client:IsAdmin()
end

-- luacheck: globals HOLDTYPE_TRANSLATOR
HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

-- luacheck: globals  PLAYER_HOLDTYPE_TRANSLATOR
PLAYER_HOLDTYPE_TRANSLATOR = {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["passive"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "normal"

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR
local animationFixOffset = Vector(16.5438, -0.1642, -20.5493)

function GM:TranslateActivity(client, act)
    local clientTable = client:GetTable()

    -- Check if we have changed the activity from the last time we checked
    local oldAct = client.ixLastAct or -1
    if ( oldAct != act ) then
        clientTable.ixLastAct = act
    end

    local modelClass = clientTable.ixAnimModelClass or "player"
    local bRaised = client:IsWepRaised()

    if ( modelClass == "player" ) then
        local weapon = client:GetActiveWeapon()
        local bAlwaysRaised = ix.config.Get("weaponAlwaysRaised")
        weapon = IsValid(weapon) and weapon or nil

        if ( !bAlwaysRaised and weapon and !bRaised and client:OnGround() ) then
            local model = client:GetModel()
            if ( ix.util.StringMatches(model, "zombie" ) ) then
                local tree = ix.anim.zombie
                if ( ix.util.StringMatches(model, "fast" ) ) then
                    tree = ix.anim.fastZombie
                end

                if ( tree[act] ) then
                    return tree[act]
                end
            end

            local holdType = weapon and ( weapon.HoldType or weapon:GetHoldType()) or "normal"
            local isPistol = holdType == "pistol" or holdType == "revolver"
            if ( !bAlwaysRaised and weapon and !bRaised and client:OnGround() ) then
                holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or ( isPistol and "normal" or "passive" )
            end

            local tree = ix.anim.player[holdType]
            if ( tree and tree[act] ) then
                if ( isstring(tree[act]) ) then
                    clientTable.CalcSeqOverride = client:LookupSequence(tree[act])

                    return
                else
                    return tree[act]
                end
            end
        end

        return self.BaseClass:TranslateActivity(client, act)
    end

    if ( clientTable.ixAnimTable ) then
        local glide = clientTable.ixAnimGlide

        if ( client:InVehicle() ) then
            local newAct = clientTable.ixAnimTable[1]

            local fixVector = clientTable.ixAnimTable[2]
            if ( isvector(fixVector) ) then
                client:SetLocalPos(animationFixOffset)
            end

            if ( isstring(newAct) ) then
                clientTable.CalcSeqOverride = client:LookupSequence(newAct)
            elseif ( istable(newAct) ) then
                if ( !clientTable.CalcSeqOverrideTable ) then
                    clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
                end

                -- Randomly select a new sequence from the table if we came from a different act
                if ( oldAct != newAct ) then
                    clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
                end

                clientTable.CalcSeqOverride = clientTable.CalcSeqOverrideTable
            else
                return newAct
            end
        elseif ( client:OnGround() ) then
            if ( clientTable.ixAnimTable[act] ) then
                local newAct = clientTable.ixAnimTable[act][bRaised and 2 or 1]

                if ( isstring(newAct) ) then
                    clientTable.CalcSeqOverride = client:LookupSequence(newAct)
                elseif ( istable(newAct) ) then
                    if ( !clientTable.CalcSeqOverrideTable ) then
                        clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
                    end

                    -- Randomly select a new sequence from the table if we came from a different act
                    if ( oldAct != clientTable.ixLastAct ) then
                        clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
                    end

                    clientTable.CalcSeqOverride = clientTable.CalcSeqOverrideTable
                else
                    return newAct
                end
            end
        elseif ( client:GetMoveType() == MOVETYPE_LADDER ) then
            local ladderIdle = clientTable.ixAnimLadderIdle
            local ladderMove = clientTable.ixAnimLadderMove
            local ladderUp = clientTable.ixAnimLadderUp
            local ladderDown = clientTable.ixAnimLadderDown

            local pos = client:WorldSpaceCenter()
            local ang = client:EyeAngles()
            ang.p = 0

            local trace = util.TraceLine({
                start = pos,
                endpos = pos + ang:Forward() * 48,
                filter = client,
                mask = MASK_PLAYERSOLID
            })

            debugoverlay.Line(trace.StartPos, trace.HitPos, 0.1, Color(255, 0, 0), true)
            debugoverlay.Cross(trace.HitPos, 5, 0.1, trace.Hit and Color(0, 255, 0) or Color(255, 0, 0), true)

            if ( !trace.Hit ) then
                if ( glide ) then
                    if ( isstring(glide) ) then
                        clientTable.CalcSeqOverride = client:LookupSequence(glide)
                    else
                        return glide
                    end
                end
            end

            local velocity = client:GetVelocity()
            local len2D = velocity:Length2DSqr()

            -- Check if we are moving up or down the ladder
            client.ixLadderVelocity = client.ixLadderVelocity or Vector(0, 0, 0)
            client.ixLadderNextCheck = client.ixLadderNextCheck or CurTime()
            client.ixLadderDir = client.ixLadderDir or "idle"

            if ( CurTime() >= client.ixLadderNextCheck ) then
                client.ixLadderNextCheck = CurTime() + 0.1

                if ( velocity.z > 10 ) then
                    client.ixLadderDir = "up"
                elseif ( velocity.z < -10 ) then
                    client.ixLadderDir = "down"
                else
                    client.ixLadderDir = "idle"
                end
            end

            if ( len2D <= 0.25 ) then
                if ( client.ixLadderDir == "up" ) then
                    if ( ladderUp ) then
                        if ( isstring(ladderUp) ) then
                            clientTable.CalcSeqOverride = client:LookupSequence(ladderUp)
                        else
                            return ladderUp
                        end
                    end
                elseif ( client.ixLadderDir == "down" ) then
                    if ( ladderDown ) then
                        if ( isstring(ladderDown) ) then
                            clientTable.CalcSeqOverride = client:LookupSequence(ladderDown)
                        else
                            return ladderDown
                        end
                    end
                else
                    if ( ladderIdle ) then
                        if ( isstring(ladderIdle) ) then
                            clientTable.CalcSeqOverride = client:LookupSequence(ladderIdle)
                        else
                            return ladderIdle
                        end
                    end
                end
            else
                if ( ladderMove ) then
                    if ( isstring(ladderMove) ) then
                        clientTable.CalcSeqOverride = client:LookupSequence(ladderMove)
                    else
                        return ladderMove
                    end
                end
            end
        elseif ( glide ) then
            if ( isstring(glide) ) then
                clientTable.CalcSeqOverride = client:LookupSequence(glide)
            else
                return clientTable.ixAnimGlide
            end
        end
    end
end

function GM:CanPlayerUseBusiness(client, uniqueID)
    if (!ix.config.Get("allowBusiness", true)) then return false end

    local itemTable = ix.item.list[uniqueID]

    local character = client:GetCharacter()
    if ( !character ) then return false end
    if ( itemTable.noBusiness ) then return false end

    if ( itemTable.factions ) then
        local allowed = false

        if ( istable(itemTable.factions) ) then
            for _, v in pairs(itemTable.factions) do
                if ( client:Team() == v ) then
                    allowed = true

                    break
                end
            end
        elseif ( client:Team() != itemTable.factions ) then
            allowed = false
        end

        if ( !allowed ) then return false end
    end

    if ( itemTable.classes ) then
        local allowed = false

        if ( istable(itemTable.classes) ) then
            for _, v in pairs(itemTable.classes) do
                if ( character:GetClass() == v ) then
                    allowed = true

                    break
                end
            end
        elseif ( character:GetClass() == itemTable.classes ) then
            allowed = true
        end

        if ( !allowed ) then return false end
    end

    if ( itemTable.flag ) then
        if ( !character:HasFlags(itemTable.flag) ) then return false end
    end

    return true
end

function GM:DoAnimationEvent(client, event, data)
    local class = client.ixAnimModelClass
    if ( class == "player" ) then
        return self.BaseClass:DoAnimationEvent(client, event, data)
    else
        local weapon = client:GetActiveWeapon()
        if ( IsValid(weapon) ) then
            local animation = client.ixAnimTable
            if ( !animation ) then return end

            local attack = isstring(animation.attack) and client:LookupSequence(animation.attack) or animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1
            local reload = isstring(animation.reload) and client:LookupSequence(animation.reload) or animation.reload or ACT_GESTURE_RELOAD_SMG1

            if ( event == PLAYERANIMEVENT_ATTACK_PRIMARY ) then
                client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, attack, true)

                return ACT_VM_PRIMARYATTACK
            elseif ( event == PLAYERANIMEVENT_ATTACK_SECONDARY ) then
                client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, attack, true)

                return ACT_VM_SECONDARYATTACK
            elseif ( event == PLAYERANIMEVENT_RELOAD ) then
                client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, reload, true)

                return ACT_INVALID
            elseif ( event == PLAYERANIMEVENT_JUMP ) then
                client:AnimRestartMainSequence()

                return ACT_INVALID
            elseif ( event == PLAYERANIMEVENT_CANCEL_RELOAD ) then
                client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

                return ACT_INVALID
            end
        end
    end

    return ACT_INVALID
end

function GM:EntityEmitSound(data)
    if ( data.Entity.ixIsMuted ) then return false end
end

function GM:EntityRemoved(entity)
    if ( SERVER ) then
        entity:ClearNetVars()
    elseif ( entity:IsWeapon() ) then
        local owner = entity:GetOwner()

        -- GetActiveWeapon is the player's new weapon at this point so we'll assume
        -- that the player switched away from this weapon
        if ( IsValid(owner) and owner:IsPlayer() ) then
            hook.Run("PlayerWeaponChanged", owner, owner:GetActiveWeapon())
        end
    end
end

local function UpdatePlayerHoldType(client, weapon)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()

    weapon = weapon or client:GetActiveWeapon()
    local holdType = "normal"

    if ( IsValid(weapon) ) then
        holdType = weapon.HoldType or weapon:GetHoldType()
        holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType
    end

    clientTable.ixAnimHoldType = holdType
    clientTable.ixLastAct = -1
end

local function UpdateAnimationTable(client, vehicle)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    local baseTable = ix.anim[clientTable.ixAnimModelClass] or {}

    if ( IsValid(vehicle) ) then
        local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

        if ( baseTable.vehicle ) then
            if ( baseTable.vehicle[vehicleClass] ) then
                clientTable.ixAnimTable = baseTable.vehicle[vehicleClass]
            else
                clientTable.ixAnimTable = {"silo_sit", vector_origin}
            end
        else
            clientTable.ixAnimTable = baseTable.normal[ACT_MP_CROUCH_IDLE]
        end
    else
        clientTable.ixAnimTable = baseTable[clientTable.ixAnimHoldType]
    end

    clientTable.ixAnimGlide = baseTable["glide"]
    clientTable.ixAnimLadderIdle = baseTable["ladder_idle"]
    clientTable.ixAnimLadderMove = baseTable["ladder_move"]
    clientTable.ixAnimLadderUp = baseTable["ladder_up"]
    clientTable.ixAnimLadderDown = baseTable["ladder_down"]
    clientTable.ixLastAct = -1
end

function GM:PlayerWeaponChanged(client, weapon)
    UpdatePlayerHoldType(client, weapon)
    UpdateAnimationTable(client)

    if ( CLIENT ) then return end

    -- update weapon raise state
    if ( weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon:GetClass()] ) then
        client:SetWepRaised(true, weapon)
        return
    elseif ( weapon.IsAlwaysLowered or weapon.NeverRaised ) then
        client:SetWepRaised(false, weapon)
        return
    end

    -- If the player has been forced to have their weapon lowered.
    if ( client:IsRestricted() ) then
        client:SetWepRaised(false, weapon)
        return
    end

    -- Let the config decide before actual results.
    if ( ix.config.Get("weaponAlwaysRaised") ) then
        client:SetWepRaised(true, weapon)
        return
    end

    client:SetWepRaised(false, weapon)
end

function GM:PlayerSwitchWeapon(client, oldWeapon, weapon)
    if ( !IsFirstTimePredicted() ) then return end

    -- the player switched weapon themself (i.e not through SelectWeapon), so we have to network it here
    if ( SERVER ) then
        net.Start("PlayerSelectWeapon")
            net.WritePlayer(client)
            net.WriteString(weapon:GetClass())
        net.Broadcast()
    end

    hook.Run("PlayerWeaponChanged", client, weapon)
end

function GM:PlayerModelChanged(client, model)
    if ( !model ) then return end

    client.ixAnimModelClass = ix.anim.GetModelClass(model)

    UpdateAnimationTable(client)
end

function GM:HandlePlayerDucking(client, velocity, plyTable)
    if ( !plyTable ) then
        plyTable = client:GetTable()
    end

    if ( !client:IsFlagSet(FL_DUCKING) ) then return false end

    if ( velocity:Length2DSqr() > 0.25 ) then
        plyTable.CalcIdeal = ACT_MP_CROUCHWALK
    else
        plyTable.CalcIdeal = ACT_MP_CROUCH_IDLE
    end

    return true
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(client, velocity)
    local forcedSequence = client:GetNetVar("forcedSequence")
    if ( forcedSequence ) then
        if ( client:GetSequence() != forcedSequence ) then
            client:SetCycle(0)
        end

        return -1, forcedSequence
    end

    client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity)[2] - client:EyeAngles()[2]))

    local clientTable = client:GetTable()
    clientTable.CalcIdeal = ACT_MP_STAND_IDLE

    -- we could call the baseclass function, but it's faster to do it this way
    local BaseClass = GAMEMODE.BaseClass

    if ( BaseClass:HandlePlayerNoClipping(client, velocity) or
        BaseClass:HandlePlayerDriving(client) or
        BaseClass:HandlePlayerVaulting(client, velocity) or
        BaseClass:HandlePlayerJumping(client, velocity) or
        BaseClass:HandlePlayerSwimming(client, velocity) or
        BaseClass:HandlePlayerDucking(client, velocity) ) then -- luacheck: ignore 542
    else
        local len2D = velocity:Length2DSqr()

        if ( velocity[3] != 0 and len2D <= 16 ^ 2 ) then
            clientTable.CalcIdeal = ACT_GLIDE
        elseif ( len2D <= 0.25 ) then
            clientTable.CalcIdeal = ACT_MP_STAND_IDLE
        elseif ( len2D > ( ix.config.Get("walkSpeed") * 1.25 ) ^ 2 ) then
            clientTable.CalcIdeal = ACT_MP_RUN
        else
            clientTable.CalcIdeal = ACT_MP_WALK
        end
    end

    hook.Run("TranslateActivity", client, clientTable.CalcIdeal)

    local sequenceOverride = clientTable.CalcSeqOverride
    clientTable.CalcSeqOverride = -1

    clientTable.m_bWasOnGround = client:OnGround()
    clientTable.m_bWasNoclipping = ( client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle() )

    return clientTable.CalcIdeal, sequenceOverride or clientTable.CalcSeqOverride or -1
end

function GM:UpdateAnimation(client, velocity, maxSeqGroundSpeed)
    if ( client:GetNetVar("forcedSequence") ) then
        client:SetPlaybackRate(client:GetNetVar("sequenceSpeed", 1))
    else
        local len = velocity:Length()
        local movement = 1.0

        if ( len > 0.2 ) then
            movement = (len / maxSeqGroundSpeed)
        end

        local rate = math.min(movement, 2)

        -- if we're under water we want to constantly be swimming..
        if ( client:WaterLevel() >= 2 ) then
            rate = math.max(rate, 0.5)
        elseif ( !client:IsOnGround() and len >= 1000 ) then
            rate = 0.1
        end

        client:SetPlaybackRate(rate)
    end

    -- We only need to do this clientside..
    if ( CLIENT ) then
        if ( client:InVehicle() ) then
            -- This is used for the 'rollercoaster' arms
            local Vehicle = client:GetVehicle()
            local Velocity = Vehicle:GetVelocity()
            local fwd = Vehicle:GetUp()
            local dp = fwd:Dot(Vector(0, 0, 1))

            client:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + fwd:Dot(Velocity) * 0.005)

            -- Pass the vehicles steer param down to the player
            local steer = Vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1 -- convert from 0..1 to -1..1
            if ( Vehicle:GetClass() == "prop_vehicle_prisoner_pod" ) then steer = 0 client:SetPoseParameter("aim_yaw", math.NormalizeAngle(client:GetAimVector():Angle().y - Vehicle:GetAngles().y - 90)) end
            client:SetPoseParameter("vehicle_steer", steer)

        end

        GAMEMODE:GrabEarAnimation(client)
        GAMEMODE:MouthMoveAnimation(client)
    end
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function GM:StartCommand(client, command)
    if ( !client:CanShootWeapon() ) then
        command:RemoveKey(KEY_BLACKLIST)
    end
end

function GM:CharacterVarChanged(character, varName, oldVar, newVar)
    if ( ix.char.varHooks[varName] ) then
        for _, v in pairs(ix.char.varHooks[varName]) do
            v(character, oldVar, newVar)
        end
    end
end

function GM:CanPlayerThrowPunch(client)
    if ( !client:IsWepRaised() ) then return false end

    return true
end

function GM:OnCharacterCreated(client, character)
    local faction = ix.faction.Get(character:GetFaction())
    if ( faction and faction.OnCharacterCreated ) then
        faction:OnCharacterCreated(client, character)
    end
end

function GM:GetDefaultCharacterName(client, faction)
    local info = ix.faction.indices[faction]
    if ( info and info.GetDefaultName ) then
        return info:GetDefaultName(client)
    end
end

function GM:CanPlayerUseCharacter(client, character)
    local banned = character:GetData("banned")
    if ( banned ) then
        if ( isnumber(banned) ) then
            if ( banned < os.time() ) then
                goto charBanBypass
            end

            return false, "@charBannedTemp"
        end

        return false, "@charBanned"
    end

    ::charBanBypass::

    local bHasWhitelist = client:HasWhitelist(character:GetFaction())
    if ( !bHasWhitelist ) then
        return false, "@noWhitelist"
    end
end

function GM:CanProperty(client, property, entity)
    if ( client:IsAdmin() ) then return true end

    if ( CLIENT and ( property == "remover" or property == "collision" ) ) then return true end

    return false
end

function GM:PhysgunPickup(client, entity)
    local bPickup = self.BaseClass:PhysgunPickup(client, entity)
    if ( !bPickup and entity:IsPlayer() and ( client:IsSuperAdmin() or client:IsAdmin() and !entity:IsSuperAdmin() ) ) then
        bPickup = true
    end

    if ( bPickup ) then
        if ( entity:IsPlayer() ) then
            entity:SetMoveType(MOVETYPE_NONE)
        elseif ( !entity.ixCollisionGroup ) then
            entity.ixCollisionGroup = entity:GetCollisionGroup()
            entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        end
    end

    return bPickup
end

function GM:PhysgunDrop(client, entity)
    if ( entity:IsPlayer() ) then
        entity:SetMoveType(MOVETYPE_WALK)
    elseif ( entity.ixCollisionGroup ) then
        entity:SetCollisionGroup(entity.ixCollisionGroup)
        entity.ixCollisionGroup = nil
    end
end

function GM:Move(client, moveData)
    local character = client:GetCharacter()
    if ( character ) then
        if ( client:GetNetVar("actEnterAngle") ) then
            moveData:SetForwardSpeed(0)
            moveData:SetSideSpeed(0)
            moveData:SetVelocity(Vector(0, 0, 0))
        end

        if ( client:GetMoveType() == MOVETYPE_WALK and moveData:KeyDown(IN_WALK) ) then
            local mf, ms = 0, 0
            local speed = client:GetWalkSpeed()
            local ratio = ix.config.Get("walkRatio")

            if ( moveData:KeyDown(IN_FORWARD) ) then
                mf = ratio
            elseif ( moveData:KeyDown(IN_BACK) ) then
                mf = -ratio
            end

            if ( moveData:KeyDown(IN_MOVELEFT) ) then
                ms = -ratio
            elseif ( moveData:KeyDown(IN_MOVERIGHT) ) then
                ms = ratio
            end

            moveData:SetForwardSpeed(mf * speed)
            moveData:SetSideSpeed(ms * speed)
        end
    end
end

function GM:CanTransferItem(itemObject, curInv, inventory)
    if ( SERVER ) then
        local client = itemObject.GetOwner and itemObject:GetOwner() or nil

        if ( IsValid(client) and curInv.GetReceivers ) then
            local bAuthorized = false

            for _, v in ipairs(curInv:GetReceivers()) do
                if ( client == v ) then
                    bAuthorized = true
                    break
                end
            end

            if ( !bAuthorized ) then
                return false
            end
        end
    end

    -- we can transfer anything that isn't a bag
    if ( !itemObject or !itemObject.isBag ) then return end

    -- don't allow bags to be put inside bags
    if ( inventory.id != 0 and curInv.id != inventory.id ) then
        if ( inventory.vars and inventory.vars.isBag and hook.Run("CanPlayerTransferNestedBags", itemObject, curInv, inventory) != true ) then
            if ( CLIENT ) then
                ix.util.NotifyLocalized("nestedBags")
            end

            return false
        end
    elseif ( inventory.id != 0 and curInv.id == inventory.id ) then
        -- we are simply moving items around if we're transferring to the same inventory
        return
    end

    inventory = ix.item.inventories[itemObject:GetData("id")]

    -- don't allow transferring items that are in use
    if ( inventory ) then
        for k, _ in inventory:Iter() do
            if (k:GetData("equip") == true) then
                if ( CLIENT ) then
                    ix.util.NotifyLocalized("equippedBag")
                end

                return false
            end
        end
    end
end

function GM:CanPlayerTransferNestedBags(itemObject, curInv, inventory)
    -- If the character is transferring a bag to the same bag, then restrict it.
    if ( itemObject:GetInventory() == inventory ) then
        if ( CLIENT ) then
            ix.util.NotifyLocalized("nestedBags")
        end

        return false
    end

    return true
end

function GM:CanPlayerEquipItem(client, item)
    return item.invID == client:GetCharacter():GetInventory():GetID()
end

function GM:CanPlayerUnequipItem(client, item)
    return item.invID == client:GetCharacter():GetInventory():GetID()
end

function GM:OnItemTransferred(item, curInv, inventory)
    local bagInventory = item.GetInventory and item:GetInventory()
    if ( !bagInventory ) then return end

    -- we need to retain the receiver if the owner changed while viewing as storage
    if ( inventory.storageInfo and isfunction(curInv.GetOwner) ) then
        bagInventory:AddReceiver(curInv:GetOwner())
    end
end

function GM:ShowHelp()
end

function GM:PreGamemodeLoaded()
    hook.Remove("PostDrawEffects", "RenderWidgets")
    hook.Remove("PlayerTick", "TickWidgets")
    hook.Remove("RenderScene", "RenderStereoscopy")
end

function GM:PostGamemodeLoaded()
    baseclass.Set("ix_character", ix.meta.character)
    baseclass.Set("ix_inventory", ix.meta.inventory)
    baseclass.Set("ix_item", ix.meta.item)
end

function widgets.PlayerTick()
end

if ( SERVER ) then
    util.AddNetworkString("PlayerVehicle")

    function GM:PlayerEnteredVehicle(client, vehicle, role)
        UpdateAnimationTable(client)

        net.Start("PlayerVehicle")
            net.WritePlayer(client)
            net.WriteEntity(vehicle)
            net.WriteBool(true)
        net.Broadcast()
    end

    function GM:PlayerLeaveVehicle(client, vehicle)
        UpdateAnimationTable(client)

        net.Start("PlayerVehicle")
            net.WritePlayer(client)
            net.WriteEntity(vehicle)
            net.WriteBool(false)
        net.Broadcast()
    end
else
    net.Receive("PlayerVehicle", function(length)
        local client = net.ReadPlayer()
        local vehicle = net.ReadEntity()
        local bEntered = net.ReadBool()

        UpdateAnimationTable(client, bEntered and vehicle or false)
    end)
end