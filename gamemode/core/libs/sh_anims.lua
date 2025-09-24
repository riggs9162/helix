
--[[--
Player model animation.

Helix comes with support for using NPC animations/models as regular player models by manually translating animations. There are
a few standard animation sets that are built-in that should cover most non-player models:
    citizen_male
    citizen_female
    metrocop
    overwatch
    vortigaunt
    player

If you find that your models are T-posing when they work elsewhere, you'll probably need to set the model class for your
model with `ix.anim.SetModelClass` in order for the correct animations to be used. If you'd like to add your own animation
class, simply add to the `ix.anim` table with a model class name and the required animation translation table.
]]
-- @module ix.anim

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "ar2"
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

function GM:HandlePlayerJumping(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then
        clientTable.m_bJumping = false
        return
    end

    if ( !clientTable.m_bJumping and !client:OnGround() and client:WaterLevel() <= 0) then
        if ( !clientTable.m_fGroundTime ) then
            clientTable.m_fGroundTime = CurTime()
        elseif ( ( CurTime() - clientTable.m_fGroundTime ) > 0 and velocity:Length2DSqr() < 0.25 ) then
            clientTable.m_bJumping = true
            clientTable.m_bFirstJumpFrame = false
            clientTable.m_flJumpStartTime = 0
        end
    end

    if ( clientTable.m_bJumping ) then
        if ( clientTable.m_bFirstJumpFrame ) then
            clientTable.m_bFirstJumpFrame = false
            client:AnimRestartMainSequence()
        end

        if ( ( client:WaterLevel() >= 2 ) or ( ( CurTime() - clientTable.m_flJumpStartTime ) > 0.2 and client:OnGround() ) ) then
            clientTable.m_bJumping = false
            clientTable.m_fGroundTime = nil
            client:AnimRestartMainSequence()
        end

        if ( clientTable.m_bJumping ) then
            clientTable.CalcIdeal = ACT_MP_JUMP
            return true
        end
    end

    return false
end

function GM:HandlePlayerDucking(client, velocity, clientTable)
    if ( !clientTable ) then
        clientTable = client:GetTable()
    end

    if ( !client:IsFlagSet(FL_ANIMDUCKING) ) then return false end

    if ( velocity:Length2DSqr() > 0.25 ) then
        clientTable.CalcIdeal = ACT_MP_CROUCHWALK
    else
        clientTable.CalcIdeal = ACT_MP_CROUCH_IDLE
    end

    return true
end

function GM:HandlePlayerNoClipping(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:GetMoveType() != MOVETYPE_NOCLIP or client:InVehicle() ) then
        if ( clientTable.m_bWasNoclipping ) then
            clientTable.m_bWasNoclipping = nil
            client:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
        end

        return
    end

    if ( !clientTable.m_bWasNoclipping ) then
        client:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false)
    end

    return true
end

function GM:HandlePlayerVaulting(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( velocity:LengthSqr() < 1000000 ) then return end
    if ( client:IsOnGround() ) then return end

    clientTable.CalcIdeal = ACT_MP_SWIM

    return true
end

function GM:HandlePlayerSwimming(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:WaterLevel() < 2 or client:IsOnGround() ) then
        clientTable.m_bInSwim = false
        return false
    end

    clientTable.CalcIdeal = ACT_MP_SWIM
    clientTable.m_bInSwim = true

    return true
end

function GM:HandlePlayerLanding(client, velocity, wasOnGround)
    if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then return end
    if ( client:IsOnGround() and !wasOnGround ) then
        local land = ACT_LAND
        local clientTable = client:GetTable()
        local animTable = clientTable.ixAnimTable
        if ( animTable and animTable.land ) then
            land = animTable.land
        end

        if ( isstring(land) ) then
            land = client:LookupSequence(land)
        elseif ( istable(land) ) then
            land = client:LookupSequence(land[math.random(#land)])
        end

        client:PlayGesture(GESTURE_SLOT_JUMP, land)
    end
end

function GM:HandlePlayerDriving(client, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( !client:InVehicle() or !IsValid(client:GetParent()) ) then
        return false
    end

    local vehicle = client:GetVehicle()
    if ( !vehicle.HandleAnimation and vehicle.GetVehicleClass ) then
        local c = vehicle:GetVehicleClass()
        local t = list.Get("Vehicles")[c]
        if ( t and t.Members and t.Members.HandleAnimation ) then
            vehicle.HandleAnimation = t.Members.HandleAnimation
        else
            vehicle.HandleAnimation = true
        end
    end

    if ( isfunction(vehicle.HandleAnimation) ) then
        local seq = vehicle:HandleAnimation(client)
        if ( seq != nil ) then
            clientTable.CalcSeqOverride = seq
        end
    end

    if ( clientTable.CalcSeqOverride == -1 ) then
        local class = vehicle:GetClass()
        if ( class == "prop_vehicle_jeep" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_jeep")
        elseif ( class == "prop_vehicle_airboat" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_airboat")
        elseif ( class == "prop_vehicle_prisoner_pod" and vehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_pd")
        else
            clientTable.CalcSeqOverride = client:LookupSequence("sit_rollercoaster")
        end
    end

    local useAnims = ( clientTable.CalcSeqOverride == client:LookupSequence("sit_rollercoaster") or clientTable.CalcSeqOverride == client:LookupSequence("sit") )
    if ( useAnims and client:GetAllowWeaponsInVehicle() and IsValid(client:GetActiveWeapon()) ) then
        local holdType = client:GetActiveWeapon():GetHoldType()
        if ( holdType == "smg" ) then
            holdType = "smg1"
        end

        local seqid = client:LookupSequence("sit_" .. holdType)
        if ( seqid != -1 ) then
            clientTable.CalcSeqOverride = seqid
        end
    end

    return true
end

function GM:UpdateAnimation(client, velocity, maxseqgroundspeed)
    local len = velocity:Length()
    local movement = 1.0
    if ( len > 0.2 ) then
        movement = (len / maxseqgroundspeed)
    end

    local rate = math.min(movement, 2)
    if ( client:WaterLevel() >= 2 ) then
        rate = math.max(rate, 0.5)
    elseif ( !client:IsOnGround() and len >= 1000 ) then
        rate = 0.1
    end

    client:SetPlaybackRate(rate)

    if ( CLIENT ) then
        if ( client:InVehicle() ) then
            local vehicle = client:GetVehicle()
            local Velocity = vehicle:GetVelocity()
            local fwd = vehicle:GetUp()
            local dp = fwd:Dot(vector_up)
            client:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + fwd:Dot(Velocity) * 0.005)

            local steer = vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1
            if ( vehicle:GetClass() == "prop_vehicle_prisoner_pod" ) then
                steer = 0 client:SetPoseParameter("aim_yaw", math.NormalizeAngle(client:GetAimVector():Angle().y - vehicle:GetAngles().y - 90))
            end

            client:SetPoseParameter("vehicle_steer", steer)
        end

        self:GrabEarAnimation(client)
        self:MouthMoveAnimation(client)
    end
end

function GM:GrabEarAnimation(client, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    clientTable.ChatGestureWeight = clientTable.ChatGestureWeight or 0

    if ( client:IsPlayingTaunt() ) then
        return
    end

    if ( client:IsTyping() ) then
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 1, FrameTime() * 5)
    else
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 0, FrameTime() * 5)
    end

    if ( clientTable.ChatGestureWeight > 0 ) then
        client:AnimRestartGesture(GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true)
        client:AnimSetGestureWeight(GESTURE_SLOT_VCD, clientTable.ChatGestureWeight)
    end
end

function GM:MouthMoveAnimation(client)
    local flexes = {
        client:GetFlexIDByName("jaw_drop"),
        client:GetFlexIDByName("left_part"),
        client:GetFlexIDByName("right_part"),
        client:GetFlexIDByName("left_mouth_drop"),
        client:GetFlexIDByName("right_mouth_drop")
    }

    local weight = client:IsSpeaking() and math.Clamp(client:VoiceVolume() * 2, 0, 2) or 0
    for i = 1, #flexes do
        client:SetFlexWeight(flexes[i], weight)
    end
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle
function GM:CalcMainActivity(client, velocity)
    local clientTable = client:GetTable()
    local forcedSequence = client:GetNetVar("forcedSequence")

    if ( forcedSequence ) then
        if ( client:GetSequence() != forcedSequence ) then
            client:SetCycle(0)
        end

        return -1, forcedSequence
    end

    clientTable.CalcIdeal = ACT_MP_STAND_IDLE

    local eyeAngles = client:EyeAngles()
    local aimVector = client:GetAimVector()
    local aimVectorAng = aimVector:Angle()
    local renderAng = client:GetRenderAngles()

    client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity).y - eyeAngles.y))

    local aimYaw = normalizeAngle(renderAng.y - eyeAngles.y)
    local aimPitch = normalizeAngle(renderAng.p - eyeAngles.p)

    client:SetPoseParameter("aim_yaw", aimYaw)
    client:SetPoseParameter("aim_pitch", aimPitch)

    local headYaw = normalizeAngle(renderAng.y - aimVectorAng.y)
    local headPitch = normalizeAngle(renderAng.p - aimVectorAng.p)

    client:SetPoseParameter("head_yaw", headYaw)
    client:SetPoseParameter("head_pitch", headPitch)

    self:HandlePlayerLanding(client, velocity, clientTable.m_bWasOnGround)

    if !( self:HandlePlayerNoClipping(client, velocity, clientTable) or
        self:HandlePlayerDriving(client, clientTable) or
        self:HandlePlayerVaulting(client, velocity, clientTable) or
        self:HandlePlayerJumping(client, velocity, clientTable) or
        self:HandlePlayerSwimming(client, velocity, clientTable) or
        self:HandlePlayerDucking(client, velocity, clientTable) ) then

        local len2d = velocity:Length2DSqr()
        if ( velocity[3] != 0 and len2d <= 16 ^ 2 ) then
            clientTable.CalcIdeal = ACT_GLIDE
        elseif ( len2d > 22500 ) then
            clientTable.CalcIdeal = ACT_MP_RUN
        elseif ( len2d > 0.25 ) then
            clientTable.CalcIdeal = ACT_MP_WALK
        else
            clientTable.CalcIdeal = ACT_MP_STAND_IDLE
        end
    end

    hook.Run("TranslateActivity", client, clientTable.CalcIdeal)

    local seqOverride = clientTable.CalcSeqOverride
    clientTable.CalcSeqOverride = -1

    clientTable.m_bWasOnGround = client:IsOnGround()
    clientTable.m_bWasNoclipping = (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle())

    return clientTable.CalcIdeal, seqOverride or clientTable.CalcSeqOverride
end

local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {}
IdleActivityTranslate[ACT_MP_STAND_IDLE] = IdleActivity
IdleActivityTranslate[ACT_MP_WALK] = IdleActivity + 1
IdleActivityTranslate[ACT_MP_RUN] = IdleActivity + 2
IdleActivityTranslate[ACT_MP_CROUCH_IDLE] = IdleActivity + 3
IdleActivityTranslate[ACT_MP_CROUCHWALK] = IdleActivity + 4
IdleActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_RELOAD_STAND] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_RELOAD_CROUCH] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
IdleActivityTranslate[ACT_MP_SWIM] = IdleActivity + 9
IdleActivityTranslate[ACT_LAND] = ACT_LAND

function GM:TranslateActivity(client, act)
    local clientTable = client:GetTable()
    local oldAct = clientTable.ixLastAct or -1

    local newAct = client:TranslateWeaponActivity(act)
    if ( act == newAct ) then
        return IdleActivityTranslate[act]
    end

    local class = ix.anim.GetModelClass(client:GetModel())
    if ( !class ) then return end

    if ( class:find("player") and client:InVehicle() ) then
        return newAct
    end

    local animTable = clientTable.ixAnimTable
    if ( animTable ) then
        if ( !animTable[ACT_MP_JUMP] ) then
            animTable[ACT_MP_JUMP] = ACT_JUMP
        end

        animTable = animTable[act]

        if ( animTable ) then
            if ( istable(animTable) ) then
                local preferred = animTable[client:IsWepRaised() and 2 or 1]
                newAct = preferred
            else
                newAct = animTable
            end
        elseif ( client.m_bJumping ) then
            newAct = ACT_GLIDE
        end
    end

    if ( isstring(newAct) ) then
        local seq = client:LookupSequence(newAct)
        if ( seq != -1 ) then
            clientTable.CalcSeqOverride = client:LookupSequence(newAct)
        end
    elseif ( istable(newAct) ) then
        if ( !clientTable.CalcSeqOverrideTable ) then
            clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
        end

        if ( oldAct != newAct ) then
            clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
        end

        clientTable.CalcSeqOverride = clientTable.CalcSeqOverrideTable
    end

    if ( oldAct != newAct ) then
        clientTable.ixLastAct = newAct
    end

    return newAct
end

function GM:DoAnimationEvent(client, event, data)
    local clientTable = client:GetTable()
    if ( event == PLAYERANIMEVENT_ATTACK_PRIMARY ) then
        local animTable = clientTable.ixAnimTable
        local desired = animTable.shoot or ACT_MP_ATTACK_STAND_PRIMARYFIRE
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.range_crouch or animTable.shoot or ACT_MP_ATTACK_CROUCH_PRIMARYFIRE
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        client:PlayGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired)

        return ACT_VM_PRIMARYATTACK
    elseif ( event == PLAYERANIMEVENT_ATTACK_SECONDARY ) then
        return ACT_VM_SECONDARYATTACK
    elseif ( event == PLAYERANIMEVENT_RELOAD ) then
        local animTable = clientTable.ixAnimTable
        local desired = animTable.reload or ACT_MP_RELOAD_STAND
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.reload_crouch or animTable.reload or ACT_MP_RELOAD_CROUCH
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        client:PlayGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired)

        return ACT_INVALID
    elseif ( event == PLAYERANIMEVENT_JUMP ) then
        clientTable.m_bJumping = true
        clientTable.m_bFirstJumpFrame = true
        clientTable.m_flJumpStartTime = CurTime()

        client:AnimRestartMainSequence()

        return ACT_INVALID
    elseif ( event == PLAYERANIMEVENT_CANCEL_RELOAD ) then
        client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

        return ACT_INVALID
    end
end

ix.anim = ix.anim or {}
ix.anim.citizen_male = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_RANGE_ATTACK_THROW
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING
    },
    glide = ACT_GLIDE,
    vehicle = {
        ["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
        ["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
        ["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
        chair = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
    },
}

ix.anim.citizen_female = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_RANGE_ATTACK_THROW
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING
    },
    glide = ACT_GLIDE,
    vehicle = ix.anim.citizen_male.vehicle
}
ix.anim.metrocop = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_COMBINE_THROW_GRENADE
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING_GESTURE
    },
    glide = ACT_GLIDE,
    vehicle = {
        chair = {ACT_COVER_PISTOL_LOW, Vector(5, 0, -5)},
        ["prop_vehicle_airboat"] = {ACT_COVER_PISTOL_LOW, Vector(10, 0, 0)},
        ["prop_vehicle_jeep"] = {ACT_COVER_PISTOL_LOW, Vector(18, -2, 4)},
        ["prop_vehicle_prisoner_pod"] = {ACT_IDLE, Vector(-4, -0.5, 0)}
    }
}
ix.anim.overwatch = {
    normal = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING_GESTURE
    },
    glide = ACT_GLIDE
}
ix.anim.vortigaunt = {
    melee = {
        ["attack"] = ACT_MELEE_ATTACK1,
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
    },
    grenade = {
        ["attack"] = ACT_MELEE_ATTACK1,
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK}
    },
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        ["attack"] = ACT_MELEE_ATTACK1
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        ["reload"] = ACT_IDLE,
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        ["reload"] = ACT_IDLE,
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        ["reload"] = ACT_IDLE,
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        ["reload"] = ACT_IDLE,
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
    },
    beam = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK1,
        ["reload"] = ACT_IDLE,
        ["glide"] = {ACT_RUN, ACT_RUN}
    },
    glide = "jump_holding_glide"
}
ix.anim.player = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_revolver"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "range_pistol",
        ["reload"] = "reload_revolver"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_smg1"},
        [ACT_MP_WALK] = {"walk_passive", "walk_smg1"},
        [ACT_MP_RUN] = {"run_passive", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "range_smg1",
        ["reload"] = {"reload_smg1", "reload_smg1_alt"}
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_shotgun"},
        [ACT_MP_WALK] = {"walk_passive", "walk_shotgun"},
        [ACT_MP_RUN] = {"run_passive", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "range_shotgun",
        ["reload"] = "reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_passive", "walk_ar2"},
        [ACT_MP_RUN] = {"run_passive", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "range_ar2",
        ["reload"] = "reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

--- Creates a new animation class.
-- @realm shared
-- @string name Name of the animation class
-- @tab data Table of animation sequences
-- @usage ix.anim.CreateClass("My New Class", {
--     normal = {
--         [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
--         [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
--         [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
--         [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
--         [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
--         [ACT_LAND] = {ACT_RESET, ACT_RESET}
--     },
--     pistol = {
--         [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
--         [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
--         [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
--         [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
--         [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
--         [ACT_LAND] = {ACT_RESET, ACT_RESET},
--         attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
--         reload = ACT_RELOAD_PISTOL
--     }
-- })
-- @see ix.anim.GetModelClass
-- @see ix.anim.SetModelClass
function ix.anim.CreateClass(name, data)
    if (!name) then
        error("No name provided for animation class!")
    end

    if (!data) then
        error("No data provided for animation class '" .. name .. "'!")
    end

    ix.anim[name] = data
end

local translations = {}

--- Sets a model's animation class.
-- @realm shared
-- @string model Model name to set the animation class for
-- @string class Animation class to assign to the model
-- @usage ix.anim.SetModelClass("models/police.mdl", "metrocop")
function ix.anim.SetModelClass(model, class)
    if (!ix.anim[class]) then
        error("'" .. tostring(class) .. "' is not a valid animation class!")
    end

    translations[model:lower()] = class
end

--- Gets a model's animation class.
-- @realm shared
-- @string model Model to get the animation class for
-- @treturn[1] string Animation class of the model
-- @treturn[2] nil If there was no animation associated with the given model
-- @usage ix.anim.GetModelClass("models/police.mdl")
-- > metrocop
function ix.anim.GetModelClass(model)
    if (!model) then return end

    model = string.lower(model)
    local class = translations[model]

    if (!class and string.find(model, "/player")) then
        return "player"
    end

    class = class or "citizen_male"

    if (class == "citizen_male" and (
        string.find(model, "female") or
        string.find(model, "alyx") or
        string.find(model, "mossman"))) then
        class = "citizen_female"
    end

    return class
end

--- Returns the data for a given animation class.
-- @realm shared
-- @string class Animation class to get the data for
-- @treturn table Animation data for the class
-- @treturn nil If the class does not exist
-- @usage ix.anim.GetClass("metrocop")
-- > {normal = {...}, pistol = {...}, ...}
function ix.anim.GetClass(class)
    return ix.anim[class]
end

ix.anim.SetModelClass("models/police.mdl", "metrocop")
ix.anim.SetModelClass("models/combine_super_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier_prisonGuard.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/vortigaunt.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_blue.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_doctor.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_slave.mdl", "vortigaunt")

for _, model in pairs(player_manager.AllValidModels()) do
    ix.anim.SetModelClass(model, "player")
end

if (SERVER) then
    util.AddNetworkString("ixSequenceSet")
    util.AddNetworkString("ixSequenceReset")

    local playerMeta = FindMetaTable("Player")

    --- Player anim methods
    -- @classmod Player

    --- Forces this player's model to play an animation sequence. It also prevents the player from firing their weapon while the
    -- animation is playing.
    -- @realm server
    -- @string sequence Name of the animation sequence to play
    -- @func[opt=nil] callback Function to call when the animation finishes. This is also called immediately if the animation
    -- fails to play
    -- @number[opt=nil] time How long to play the animation for. This defaults to the duration of the animation
    -- @bool[opt=false] bNoFreeze Whether or not to avoid freezing this player in place while the animation is playing
    -- @bool[opt=false] loop Whether or not to have the animation loop. This does nothing if time is not set to greater than the duration of the animation
    -- @number[opt=1] speed The speed at which the animation should play
    -- @see LeaveSequence
    function playerMeta:ForceSequence(sequence, callback, time, bNoFreeze, loop, speed)
        speed = speed or 1

        hook.Run("PlayerEnterSequence", self, sequence, callback, time, bNoFreeze, loop, speed)

        if (!sequence) then
            net.Start("ixSequenceReset")
                net.WritePlayer(self)
            net.Broadcast()

            return
        end

        sequence = self:LookupSequence(tostring(sequence))

        if (sequence and sequence > 0) then
            time = time or (self:SequenceDuration(sequence) * (1 / speed))

            self.ixCouldShoot = self:GetNetVar("canShoot", false)
            self.ixSeqCallback = callback
            self:SetCycle(0)
            self:SetPlaybackRate(1)
            self:SetNetVar("forcedSequence", sequence)
            self:SetNetVar("sequenceLoop", loop)
            self:SetNetVar("sequenceSpeed", speed)
            self:SetNetVar("canShoot", false)

            if (!bNoFreeze) then
                self:SetNetVar("frozenSequence", true)
            end

            if (time > 0) then
                timer.Create("ixSeq" .. self:EntIndex(), time, 1, function()
                    if (IsValid(self)) then
                        self:LeaveSequence()
                    end
                end)
            end

            net.Start("ixSequenceSet")
                net.WriteEntity(self)
            net.Broadcast()

            return time
        elseif (callback) then
            callback()
        end

        return false
    end

    --- Forcefully stops this player's model from playing an animation that was started by `ForceSequence`.
    -- @realm server
    function playerMeta:LeaveSequence()
        hook.Run("PlayerLeaveSequence", self)

        net.Start("ixSequenceReset")
            net.WriteEntity(self)
        net.Broadcast()

        self:SetNetVar("canShoot", self.ixCouldShoot)
        self:SetNetVar("forcedSequence", nil)
        self:SetNetVar("sequenceLoop", nil)
        self:SetNetVar("sequenceSpeed", nil)
        self:SetNetVar("frozenSequence", nil)
        self.ixCouldShoot = nil

        if (self.ixSeqCallback) then
            self:ixSeqCallback()
        end
    end
else
    net.Receive("ixSequenceSet", function()
        local entity = net.ReadEntity()

        if (IsValid(entity)) then
            hook.Run("PlayerEnterSequence", entity)
        end
    end)

    net.Receive("ixSequenceReset", function()
        local entity = net.ReadPlayer()

        if (IsValid(entity)) then
            hook.Run("PlayerLeaveSequence", entity)
        end
    end)
end
