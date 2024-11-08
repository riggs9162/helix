function GM:PlayerNoClip(ply)
    return ply:IsAdmin()
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

function GM:TranslateActivity(ply, act)
    local plyInfo = ply:GetTable()
    local modelClass = plyInfo.ixAnimModelClass or "player"
    local bRaised = ply:IsWepRaised()

    if ( modelClass == "player" ) then
        local weapon = ply:GetActiveWeapon()
        local bAlwaysRaised = ix.config.Get("weaponAlwaysRaised")
        weapon = IsValid(weapon) and weapon or nil

        if ( !bAlwaysRaised and weapon and !bRaised and ply:OnGround() ) then
            local model = ply:GetModel()
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
            if ( !bAlwaysRaised and weapon and !bRaised and ply:OnGround() ) then
                holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
            end

            local tree = ix.anim.player[holdType]
            if ( tree and tree[act] ) then
                if ( isstring(tree[act]) ) then
                    plyInfo.CalcSeqOverride = ply:LookupSequence(tree[act])

                    return
                else
                    return tree[act]
                end
            end
        end

        return self.BaseClass:TranslateActivity(ply, act)
    end

    if ( plyInfo.ixAnimTable ) then
        local glide = plyInfo.ixAnimGlide
        local ladderIdle = plyInfo.ixAnimLadderIdle
        local ladderMove = plyInfo.ixAnimLadderMove
        local ladderUp = plyInfo.ixAnimLadderUp
        local ladderDown = plyInfo.ixAnimLadderDown

        local pos = ply:WorldSpaceCenter()
        local ang = ply:EyeAngles()
        ang.p = 0

        local trace = util.TraceLine({
            start = pos,
            endpos = pos + ang:Forward() * 48,
            filter = ply,
            mask = MASK_PLAYERSOLID
        })

        debugoverlay.Line(trace.StartPos, trace.HitPos, 0.1, Color(255, 0, 0), true)
        debugoverlay.Cross(trace.HitPos, 5, 0.1, trace.Hit and Color(0, 255, 0) or Color(255, 0, 0), true)

        if ( ply:InVehicle() ) then
            act = plyInfo.ixAnimTable[1]

            local fixVector = plyInfo.ixAnimTable[2]
            if ( isvector(fixVector) ) then
                ply:SetLocalPos(animationFixOffset)
            end

            if ( isstring(act) ) then
                plyInfo.CalcSeqOverride = ply:LookupSequence(act)
            else
                return act
            end
        elseif ( ply:OnGround() ) then
            if ( plyInfo.ixAnimTable[act] ) then
                local act2 = plyInfo.ixAnimTable[act][bRaised and 2 or 1]

                if ( isstring(act2) ) then
                    plyInfo.CalcSeqOverride = ply:LookupSequence(act2)
                else
                    return act2
                end
            end
        elseif ( ply:GetMoveType() == MOVETYPE_LADDER and trace.Hit ) then
            local velocity = ply:GetVelocity()
            local len2D = velocity:Length2DSqr()

            -- Check if we are moving up or down the ladder
            ply.ixLadderVelocity = ply.ixLadderVelocity or Vector(0, 0, 0)
            ply.ixLadderNextCheck = ply.ixLadderNextCheck or CurTime()
            ply.ixLadderDir = ply.ixLadderDir or "idle"

            if ( CurTime() >= ply.ixLadderNextCheck ) then
                ply.ixLadderNextCheck = CurTime() + 0.1

                if ( velocity.z > 10 ) then
                    ply.ixLadderDir = "up"
                elseif ( velocity.z < -10 ) then
                    ply.ixLadderDir = "down"
                else
                    ply.ixLadderDir = "idle"
                end
            end

            if ( len2D <= 0.25 ) then
                if ( ply.ixLadderDir == "up" ) then
                    if ( ladderUp ) then
                        if ( isstring(ladderUp) ) then
                            plyInfo.CalcSeqOverride = ply:LookupSequence(ladderUp)
                        else
                            return ladderUp
                        end
                    end
                elseif ( ply.ixLadderDir == "down" ) then
                    if ( ladderDown ) then
                        if ( isstring(ladderDown) ) then
                            plyInfo.CalcSeqOverride = ply:LookupSequence(ladderDown)
                        else
                            return ladderDown
                        end
                    end
                else
                    if ( ladderIdle ) then
                        if ( isstring(ladderIdle) ) then
                            plyInfo.CalcSeqOverride = ply:LookupSequence(ladderIdle)
                        else
                            return ladderIdle
                        end
                    end
                end
            else
                if ( ladderMove ) then
                    if ( isstring(ladderMove) ) then
                        plyInfo.CalcSeqOverride = ply:LookupSequence(ladderMove)
                    else
                        return ladderMove
                    end
                end
            end
        elseif ( glide ) then
            if ( isstring(glide) ) then
                plyInfo.CalcSeqOverride = ply:LookupSequence(glide)
            else
                return plyInfo.ixAnimGlide
            end
        end
    end
end

function GM:CanPlayerUseBusiness(ply, uniqueID)
    local itemTable = ix.item.list[uniqueID]

    local char = ply:GetCharacter()
    if ( !char ) then return false end
    if ( itemTable.noBusiness ) then return false end

    if ( itemTable.factions ) then
        local allowed = false

        if ( istable(itemTable.factions) ) then
            for _, v in pairs(itemTable.factions) do
                if ( ply:Team() == v ) then
                    allowed = true

                    break
                end
            end
        elseif ( ply:Team() != itemTable.factions ) then
            allowed = false
        end

        if ( !allowed ) then return false end
    end

    if ( itemTable.classes ) then
        local allowed = false

        if ( istable(itemTable.classes) ) then
            for _, v in pairs(itemTable.classes) do
                if ( char:GetClass() == v ) then
                    allowed = true

                    break
                end
            end
        elseif ( char:GetClass() == itemTable.classes ) then
            allowed = true
        end

        if ( !allowed ) then return false end
    end

    if ( itemTable.flag ) then
        if ( !char:HasFlags(itemTable.flag) ) then return false end
    end

    return true
end

function GM:DoAnimationEvent(ply, event, data)
    local class = ply.ixAnimModelClass
    if ( class == "player" ) then
        return self.BaseClass:DoAnimationEvent(ply, event, data)
    else
        local weapon = ply:GetActiveWeapon()

        if ( IsValid(weapon) ) then
            local animation = ply.ixAnimTable
            if ( !animation ) then return end

            local attack = isstring(animation.attack) and ply:LookupSequence(animation.attack) or animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1
            local reload = isstring(animation.reload) and ply:LookupSequence(animation.reload) or animation.reload or ACT_GESTURE_RELOAD_SMG1

            if ( event == PLAYERANIMEVENT_ATTACK_PRIMARY ) then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, attack, true)

                return ACT_VM_PRIMARYATTACK
            elseif ( event == PLAYERANIMEVENT_ATTACK_SECONDARY ) then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, attack, true)

                return ACT_VM_SECONDARYATTACK
            elseif ( event == PLAYERANIMEVENT_RELOAD ) then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, reload, true)

                return ACT_INVALID
            elseif ( event == PLAYERANIMEVENT_JUMP ) then
                ply:AnimRestartMainSequence()

                return ACT_INVALID
            elseif ( event == PLAYERANIMEVENT_CANCEL_RELOAD ) then
                ply:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

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

local function UpdatePlayerHoldType(ply, weapon)
    if ( !IsValid(ply) ) then return end

    local plyInfo = ply:GetTable()

    weapon = weapon or ply:GetActiveWeapon()
    local holdType = "normal"

    if ( IsValid(weapon) ) then
        holdType = weapon.HoldType or weapon:GetHoldType()
        holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType
    end

    plyInfo.ixAnimHoldType = holdType
end

local function UpdateAnimationTable(ply, vehicle)
    if ( !IsValid(ply) ) then return end

    local plyInfo = ply:GetTable()
    local baseTable = ix.anim[plyInfo.ixAnimModelClass] or {}

    if ( IsValid(vehicle) ) then
        local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

        if ( baseTable.vehicle and baseTable.vehicle[vehicleClass] ) then
            plyInfo.ixAnimTable = baseTable.vehicle[vehicleClass]
        else
            plyInfo.ixAnimTable = baseTable.normal[ACT_MP_CROUCH_IDLE]
        end
    else
        plyInfo.ixAnimTable = baseTable[plyInfo.ixAnimHoldType]
    end

    plyInfo.ixAnimGlide = baseTable["glide"]
    plyInfo.ixAnimLadderIdle = baseTable["ladder_idle"]
    plyInfo.ixAnimLadderMove = baseTable["ladder_move"]
    plyInfo.ixAnimLadderUp = baseTable["ladder_up"]
    plyInfo.ixAnimLadderDown = baseTable["ladder_down"]
end

function GM:PlayerWeaponChanged(ply, weapon)
    UpdatePlayerHoldType(ply, weapon)
    UpdateAnimationTable(ply)

    if ( CLIENT ) then return end

    -- update weapon raise state
    if ( weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon:GetClass()] ) then
        ply:SetWepRaised(true, weapon)
        return
    elseif ( weapon.IsAlwaysLowered or weapon.NeverRaised ) then
        ply:SetWepRaised(false, weapon)
        return
    end

    -- If the player has been forced to have their weapon lowered.
    if ( ply:IsRestricted() ) then
        ply:SetWepRaised(false, weapon)
        return
    end

    -- Let the config decide before actual results.
    if ( ix.config.Get("weaponAlwaysRaised") ) then
        ply:SetWepRaised(true, weapon)
        return
    end

    ply:SetWepRaised(false, weapon)
end

function GM:PlayerSwitchWeapon(ply, oldWeapon, weapon)
    if ( !IsFirstTimePredicted() ) then return end

    -- the player switched weapon themself (i.e not through SelectWeapon), so we have to network it here
    if ( SERVER ) then
        net.Start("PlayerSelectWeapon")
            net.WritePlayer(ply)
            net.WriteString(weapon:GetClass())
        net.Broadcast()
    end

    hook.Run("PlayerWeaponChanged", ply, weapon)
end

function GM:PlayerModelChanged(ply, model)
    if ( !model ) then return end

    ply.ixAnimModelClass = ix.anim.GetModelClass(model)

    UpdateAnimationTable(ply)
end

function GM:HandlePlayerDucking(ply, velocity, plyTable)
    if ( !plyTable ) then
        plyTable = ply:GetTable()
    end

    if ( !ply:IsFlagSet(FL_DUCKING) ) then
        return false
    end

    if ( velocity:Length2DSqr() > 0.25 ) then
        plyTable.CalcIdeal = ACT_MP_CROUCHWALK
    else
        plyTable.CalcIdeal = ACT_MP_CROUCH_IDLE
    end

    return true
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(ply, velocity)
    local forcedSequence = ply:GetNetVar("forcedSequence")
    if ( forcedSequence ) then
        if ( ply:GetSequence() != forcedSequence ) then
            ply:SetCycle(0)
        end

        return -1, forcedSequence
    end

    ply:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity)[2] - ply:EyeAngles()[2]))

    local plyInfo = ply:GetTable()
    plyInfo.CalcIdeal = ACT_MP_STAND_IDLE

    -- we could call the baseclass function, but it's faster to do it this way
    local BaseClass = GAMEMODE.BaseClass

    if ( BaseClass:HandlePlayerNoClipping(ply, velocity) or
        BaseClass:HandlePlayerDriving(ply) or
        BaseClass:HandlePlayerVaulting(ply, velocity) or
        BaseClass:HandlePlayerJumping(ply, velocity) or
        BaseClass:HandlePlayerSwimming(ply, velocity) or
        BaseClass:HandlePlayerDucking(ply, velocity) ) then -- luacheck: ignore 542
    else
        local len2D = velocity:Length2DSqr()

        if ( velocity[3] != 0 and len2D <= 16 ^ 2 ) then
            plyInfo.CalcIdeal = ACT_GLIDE
        elseif ( len2D <= 0.25 ) then
            plyInfo.CalcIdeal = ACT_MP_STAND_IDLE
        elseif ( len2D > ( ix.config.Get("walkSpeed") * 1.1 ) ^ 2 ) then
            plyInfo.CalcIdeal = ACT_MP_RUN
        else
            plyInfo.CalcIdeal = ACT_MP_WALK
        end
    end

    hook.Run("TranslateActivity", ply, plyInfo.CalcIdeal)

    local sequenceOverride = plyInfo.CalcSeqOverride
    plyInfo.CalcSeqOverride = -1

    plyInfo.m_bWasOnGround = ply:OnGround()
    plyInfo.m_bWasNoclipping = ( ply:GetMoveType() == MOVETYPE_NOCLIP and !ply:InVehicle() )

    return plyInfo.CalcIdeal, sequenceOverride or plyInfo.CalcSeqOverride or -1
end

function GM:UpdateAnimation(ply, velocity, maxSeqGroundSpeed)
    if ( ply:GetNetVar("forcedSequence") ) then
        ply:SetPlaybackRate(ply:GetNetVar("sequenceSpeed", 1))
    else
        local len = velocity:Length()
        local movement = 1.0

        if ( len > 0.2 ) then
            movement = (len / maxSeqGroundSpeed)
        end

        local rate = math.min(movement, 2)

        -- if we're under water we want to constantly be swimming..
        if ( ply:WaterLevel() >= 2 ) then
            rate = math.max(rate, 0.5)
        elseif ( !ply:IsOnGround() and len >= 1000 ) then
            rate = 0.1
        end

        ply:SetPlaybackRate(rate)
    end

    -- We only need to do this clientside..
    if ( CLIENT ) then
        if ( ply:InVehicle() ) then
            -- This is used for the 'rollercoaster' arms
            local Vehicle = ply:GetVehicle()
            local Velocity = Vehicle:GetVelocity()
            local fwd = Vehicle:GetUp()
            local dp = fwd:Dot(Vector(0, 0, 1))

            ply:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + fwd:Dot(Velocity) * 0.005)

            -- Pass the vehicles steer param down to the player
            local steer = Vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1 -- convert from 0..1 to -1..1
            if ( Vehicle:GetClass() == "prop_vehicle_prisoner_pod" ) then steer = 0 ply:SetPoseParameter("aim_yaw", math.NormalizeAngle(ply:GetAimVector():Angle().y - Vehicle:GetAngles().y - 90)) end
            ply:SetPoseParameter("vehicle_steer", steer)

        end

        GAMEMODE:GrabEarAnimation(ply)
        GAMEMODE:MouthMoveAnimation(ply)
    end
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2

function GM:StartCommand(ply, command)
    if ( !ply:CanShootWeapon() ) then
        command:RemoveKey(KEY_BLACKLIST)
    end
end

function GM:CharacterVarChanged(char, varName, oldVar, newVar)
    if ( ix.char.varHooks[varName] ) then
        for _, v in pairs(ix.char.varHooks[varName]) do
            v(char, oldVar, newVar)
        end
    end
end

function GM:CanPlayerThrowPunch(ply)
    if ( !ply:IsWepRaised() ) then return false end

    return true
end

function GM:OnCharacterCreated(ply, character)
    local faction = ix.faction.Get(character:GetFaction())
    if ( faction and faction.OnCharacterCreated ) then
        faction:OnCharacterCreated(ply, character)
    end
end

function GM:GetDefaultCharacterName(ply, faction)
    local info = ix.faction.indices[faction]
    if ( info and info.GetDefaultName ) then
        return info:GetDefaultName(ply)
    end
end

function GM:CanPlayerUseCharacter(ply, character)
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

    local bHasWhitelist = ply:HasWhitelist(character:GetFaction())
    if ( !bHasWhitelist ) then
        return false, "@noWhitelist"
    end
end

function GM:CanProperty(ply, property, entity)
    if ( ply:IsAdmin() ) then return true end

    if ( CLIENT and ( property == "remover" or property == "collision" ) ) then return true end

    return false
end

function GM:PhysgunPickup(ply, entity)
    local bPickup = self.BaseClass:PhysgunPickup(ply, entity)
    if ( !bPickup and entity:IsPlayer() and ( ply:IsSuperAdmin() or ply:IsAdmin() and !entity:IsSuperAdmin() ) ) then
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

function GM:PhysgunDrop(ply, entity)
    if ( entity:IsPlayer() ) then
        entity:SetMoveType(MOVETYPE_WALK)
    elseif ( entity.ixCollisionGroup ) then
        entity:SetCollisionGroup(entity.ixCollisionGroup)
        entity.ixCollisionGroup = nil
    end
end

local TOOL_DANGEROUS = {}
TOOL_DANGEROUS["dynamite"] = true
TOOL_DANGEROUS["duplicator"] = true

function GM:CanTool(ply, trace, tool)
    if ( ply:IsAdmin() ) then return true end

    if ( TOOL_DANGEROUS[tool] or hook.Run("CanPlayerUseTool", ply, tool, trace) == false ) then return false end

    return self.BaseClass:CanTool(ply, trace, tool)
end

function GM:Move(ply, moveData)
    local char = ply:GetCharacter()
    if ( char ) then
        if ( ply:GetNetVar("actEnterAngle") ) then
            moveData:SetForwardSpeed(0)
            moveData:SetSideSpeed(0)
            moveData:SetVelocity(vector_origin)
        end

        if ( ply:GetMoveType() == MOVETYPE_WALK and moveData:KeyDown(IN_WALK) ) then
            local mf, ms = 0, 0
            local speed = ply:GetWalkSpeed()
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
        local ply = itemObject.GetOwner and itemObject:GetOwner() or nil

        if ( IsValid(ply) and curInv.GetReceivers ) then
            local bAuthorized = false

            for _, v in ipairs(curInv:GetReceivers()) do
                if ( ply == v ) then
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
        for _, v in pairs(inventory:GetItems()) do
            if ( v:GetData("equip") == true ) then
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

function GM:CanPlayerEquipItem(ply, item)
    return item.invID == ply:GetCharacter():GetInventory():GetID()
end

function GM:CanPlayerUnequipItem(ply, item)
    return item.invID == ply:GetCharacter():GetInventory():GetID()
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

    function GM:PlayerEnteredVehicle(ply, vehicle, role)
        UpdateAnimationTable(ply)

        net.Start("PlayerVehicle")
            net.WritePlayer(ply)
            net.WriteEntity(vehicle)
            net.WriteBool(true)
        net.Broadcast()
    end

    function GM:PlayerLeaveVehicle(ply, vehicle)
        UpdateAnimationTable(ply)

        net.Start("PlayerVehicle")
            net.WritePlayer(ply)
            net.WriteEntity(vehicle)
            net.WriteBool(false)
        net.Broadcast()
    end
else
    net.Receive("PlayerVehicle", function(length)
        local ply = net.ReadPlayer()
        local vehicle = net.ReadEntity()
        local bEntered = net.ReadBool()

        UpdateAnimationTable(ply, bEntered and vehicle or false)
    end)
end