
--[[--
Provides players the ability to perform animations.

]]
-- @module ix.act

local PLUGIN = PLUGIN

PLUGIN.name = "Player Acts"
PLUGIN.description = "Adds animations that can be performed by certain models."
PLUGIN.author = "`impulse"

ix.act = ix.act or {}
ix.act.stored = ix.act.stored or {}

CAMI.RegisterPrivilege({
    Name = "Helix - Player Acts",
    MinAccess = "user"
})
ix.lang.AddTable("english", {
    ["acts"] = "Acts"
})

ix.config.Add("actUpdateRenderAngles", true, "Whether to update the player's render angles when performing an act.", nil, {
    category = "acts"
})

--- Registers a sequence as a performable animation (or "act") for a specific model class or multiple model classes.
-- Acts allow players to perform immersive animations that enhance roleplay scenarios. This function ties an animation or a sequence
-- of animations to a model class or multiple model classes, and allows them to be triggered in-game via commands.
--
-- Acts can have various properties, including main animation sequences, optional start and finish sequences, custom duration, 
-- checks for certain conditions (e.g., proximity to a wall), and more.
--
-- @realm shared
-- @string name The name of the act (in CamelCase), which will also serve as the identifier for the act when called in a command (e.g., `/ActWave`).
-- @string modelClass The model class or classes to which this act applies. Acts will only be available for the specified model(s). Can be a single model (e.g., `"citizen_male"`) or a table of models (e.g., `{"citizen_male", "citizen_female"}`).
-- @tab data A table that describes the act's sequences and optional properties such as start/finish sequences, custom checks, and durations.
-- @usage
-- -- Registers a simple act for sitting for "citizen_male" and "citizen_female" models.
-- ix.act.Register("Sit", {"citizen_male", "citizen_female"}, {
--     start = {"idle_to_sit_ground", "idle_to_sit_chair"},
--     sequence = {"sit_ground", "sit_chair"},
--     finish = {{"sit_ground_to_idle", duration = 2.1}, ""},
--     untimed = true, -- This act will continue until the player moves or cancels it
--     idle = true -- The act is considered an idle animation
-- })
-- @usage
-- -- Prepare the function for checking if the player is facing away from a wall for future acts
-- local function FacingWallBack(client)
--     local data = {}
--     data.start = client:LocalToWorld(client:OBBCenter())
--     data.endpos = data.start - client:GetForward() * 20
--     data.filter = client
-- 
--     if (!util.TraceLine(data).Hit) then
--         return "@faceWallBack"
--     end
-- end
--
-- -- Registers a wall-based act where players need to be facing away from the wall
-- ix.act.Register("SitWall", {"citizen_male", "citizen_female"}, {
--     sequence = {
--         -- Only perform this sequence if the player is facing away from the wall
--         {"plazaidle4", check = FacingWallBack},
--         {"injured1", check = FacingWallBack, offset = function(client)
--             -- Adjust the player's position before the animation starts
--             return client:GetForward() * 14
--         end}
--     },
--     untimed = true,
--     idle = true
-- })
-- @usage
-- -- Registers a cheering act with custom durations for "citizen_male"
-- ix.act.Register("Cheer", "citizen_male", {
--     -- Sequence with duration for the first animation
--     sequence = {{"cheer1", duration = 1.6}, "cheer2", "wave_smg1"}
-- })
function ix.act.Register(name, modelClass, data)
    ix.act.stored[name] = ix.act.stored[name] or {} -- might be adding onto an existing act

    -- Ensure that a valid sequence is provided
    if (!data.sequence) then
        return ErrorNoHalt(string.format(
            "Act '%s' for '%s' tried to register without a provided sequence\n", name, modelClass
        ))
    end

    -- Convert single sequence to table format if needed
    if (!istable(data.sequence)) then
        data.sequence = {data.sequence}
    end

    -- Check if the number of start sequences matches the number of main sequences
    if (data.start and istable(data.start) and #data.start != #data.sequence) then
        return ErrorNoHalt(string.format(
            "Act '%s' tried to register without matching number of start sequences\n", name
        ))
    end

    -- Check if the number of finish sequences matches the number of main sequences
    if (data.finish and istable(data.finish) and #data.finish != #data.sequence) then
        return ErrorNoHalt(string.format(
            "Act '%s' tried to register without matching number of finish sequences\n", name
        ))
    end

    -- If modelClass is a table, register the act for all specified models
    if (istable(modelClass)) then
        for _, v in ipairs(modelClass) do
            ix.act.stored[name][v] = data
        end
    else
        ix.act.stored[name][modelClass] = data
    end

    --- The `data` table passed into `ix.act.Register` defines the structure of the act, including the main sequence, optional start and finish sequences, 
    -- and other properties such as duration, checks, or offsets. This structure allows developers to create custom animations
    -- and provide more immersive roleplay features.
    -- 
    -- @table ActInfoStructure
    -- @realm shared
    -- @field[type=string|table] sequence The main sequence(s) that the act will perform. Can be a single sequence or a table of sequences. Sequences may have additional properties like `duration` or `check`.
    -- @field[type=string|table,opt] start An optional starting sequence (or sequences) that plays before the main animation. Used to "prepare" for the act.
    -- @field[type=string|table,opt] finish An optional finishing sequence (or sequences) that plays after the main animation.
    -- @field[type=boolean,opt] untimed If true, the act continues indefinitely until manually stopped (e.g., sitting).
    -- @field[type=boolean,opt] idle If true, the act is considered an idle animation.
    -- @field[type=function,opt] check An optional function to check specific conditions (e.g., proximity to a wall) before performing the act.
    -- @field[type=function,opt] offset An optional function to adjust the player's position relative to an object before performing the act.
    -- @usage
    -- -- Prepare the function for checking if the player is facing away from a wall for future acts
    -- local function FacingWallBack(client)
    --     local data = {}
    --     data.start = client:LocalToWorld(client:OBBCenter())
    --     data.endpos = data.start - client:GetForward() * 20
    --     data.filter = client
    -- 
    --     if (!util.TraceLine(data).Hit) then
    --         return "@faceWallBack"
    --     end
    -- end
    --
    -- -- Registers a "Lean" act that adjusts the player's position relative to the wall
    -- ix.act.Register("Lean", {"citizen_male", "citizen_female"}, {
    --     start = {"idle_to_lean_back"},
    --     sequence = {{"lean_back", check = FacingWallBack}},
    --     untimed = true,
    --     idle = true
    -- })
end

--- Removes a sequence from being performable if it has been previously registered.
-- This function unregisters an act, making it unavailable for players. 
-- It also removes the associated command that allows players to trigger the act.
--
-- @realm shared
-- @string name The name of the act to remove.
-- @usage
-- -- Remove the "Wave" animation from being available for any model
-- ix.act.Remove("Wave")
function ix.act.Remove(name)
    ix.act.stored[name] = nil
    ix.command.list["Act" .. name] = nil
end

ix.util.Include("sh_definitions.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

function PLUGIN:InitializedPlugins()
    hook.Run("SetupActs")
    hook.Run("PostSetupActs")
end

function PLUGIN:ExitAct(client)
    client.ixUntimedSequence = nil
    client:SetNetVar("actEnterAngle")

    net.Start("ixActLeave")
    net.Send(client)
end

function PLUGIN:PostSetupActs()
    -- create chat commands for all stored acts
    for act, classes in pairs(ix.act.stored) do
        local variants = 1
        local COMMAND = {
            privilege = "Player Acts"
        }

        -- check if this act has any variants (i.e /ActSit 2)
        for _, v in pairs(classes) do
            if (#v.sequence > 1) then
                variants = math.max(variants, #v.sequence)
            end
        end

        -- setup command arguments if there are variants for this act
        if (variants > 1) then
            COMMAND.arguments = bit.bor(ix.type.number, ix.type.optional)
            COMMAND.argumentNames = {"variant (1-" .. variants .. ")"}
        end

        COMMAND.GetDescription = function(command)
            return L("cmdAct", act)
        end

        local privilege = "Helix - " .. COMMAND.privilege

        -- we'll perform a model class check in OnCheckAccess to prevent the command from showing up on the client at all
        COMMAND.OnCheckAccess = function(command, client)
            local bHasAccess, _ = CAMI.PlayerHasAccess(client, privilege, nil)

            if (!bHasAccess) then
                return false
            end

            local modelClass = ix.anim.GetModelClass(client:GetModel())

            if (!classes[modelClass]) then
                return false, "modelNoSeq"
            end

            return true
        end

        COMMAND.OnRun = function(command, client, variant)
            variant = math.Clamp(tonumber(variant) or 1, 1, variants)

            if (client:GetNetVar("actEnterAngle")) then
                return "@notNow"
            end

            local modelClass = ix.anim.GetModelClass(client:GetModel())
            local bCanEnter, error = PLUGIN:CanPlayerEnterAct(client, modelClass, variant, classes)

            if (!bCanEnter) then
                return error
            end

            local data = classes[modelClass]
            local mainSequence = data.sequence[variant]
            local mainDuration

            -- check if the main sequence has any extra info
            if (istable(mainSequence)) then
                -- any validity checks to perform (i.e facing a wall)
                if (mainSequence.check) then
                    local result = mainSequence.check(client)

                    if (result) then
                        return result
                    end
                end

                -- position offset
                if (mainSequence.offset) then
                    client.ixOldPosition = client:GetPos()
                    client:SetPos(client:GetPos() + mainSequence.offset(client))
                end

                mainDuration = mainSequence.duration
                mainSequence = mainSequence[1]
            end

            local startSequence = data.start and data.start[variant] or ""
            local startDuration

            if (istable(startSequence)) then
                startDuration = startSequence.duration
                startSequence = startSequence[1]
            end

            client:SetNetVar("actEnterAngle", client:GetAngles())

            client:ForceSequence(startSequence, function()
                -- we've finished the start sequence
                client.ixUntimedSequence = data.untimed -- client can exit after the start sequence finishes playing

                local duration = client:ForceSequence(mainSequence, function()
                    -- we've stopped playing the main sequence (either duration expired or user cancelled the act)
                    if (data.finish) then
                        local finishSequence = data.finish[variant]
                        local finishDuration

                        if (istable(finishSequence)) then
                            finishDuration = finishSequence.duration
                            finishSequence = finishSequence[1]
                        end

                        client:ForceSequence(finishSequence, function()
                            -- client has finished the end sequence and is no longer playing any animations
                            self:ExitAct(client)
                        end, finishDuration)
                    else
                        -- there's no end sequence so we can exit right away
                        self:ExitAct(client)
                    end
                end, data.untimed and 0 or (mainDuration or nil))

                if (!duration) then
                    -- the model doesn't support this variant
                    self:ExitAct(client)
                    client:NotifyLocalized("modelNoSeq")

                    return
                end
            end, startDuration, nil)

            net.Start("ixActEnter")
                net.WriteBool(data.idle or false)
            net.Send(client)

            client.ixNextAct = CurTime() + 4
        end

        ix.command.Add("Act" .. act, COMMAND)
    end

    -- setup exit act command
    local COMMAND = {
        privilege = "Player Acts",
        OnRun = function(command, client)
            if (client.ixUntimedSequence) then
                client:LeaveSequence()
            end
        end
    }

    if (CLIENT) then
        -- hide this command from the command list
        COMMAND.OnCheckAccess = function(client)
            return false
        end
    end

    ix.command.Add("ExitAct", COMMAND)
end

function PLUGIN:UpdateAnimation(client, moveData)
    if (!ix.config.Get("actUpdateRenderAngles", true)) then return end

    local angle = client:GetNetVar("actEnterAngle")
    if (angle) then
        client:SetRenderAngles(angle)
    end
end

do
    local keyBlacklist = IN_ATTACK + IN_ATTACK2
    function PLUGIN:StartCommand(client, command)
        if (client:GetNetVar("actEnterAngle")) then
            command:RemoveKey(keyBlacklist)
        end
    end
end
