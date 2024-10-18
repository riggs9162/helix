
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

--- Registers a sequence as a performable animation (or "act") for a specific model class or multiple model classes.
-- Acts allow players to perform custom animations, enhancing the roleplay experience. 
-- This function ties an animation (or a series of animations) to a model class, which can then be triggered using commands.
--
-- @realm shared
-- @string name The name of the act (in CamelCase). This name will be used as the identifier for the act and in the commands (e.g., `ActWave`).
-- @string modelClass The model class or list of model classes that this act applies to. For example, "citizen" or `{"citizen", "metrocop"}`. 
-- Acts will only be available for the specified model(s).
-- @tab data The data table that defines the act. This table must contain a `sequence` field, which is the main sequence that the act will perform.
-- This is explained in more detail in the `ActInfoStructure` table.
-- @usage
-- -- Register a simple "Wave" animation for the "citizen" model class
-- ix.act.Register("Wave", "citizen", {
--     sequence = "wave"
-- })
--
-- -- Register a more complex "Salute" animation for multiple model classes with start and finish sequences
-- ix.act.Register("Salute", {"citizen", "metrocop"}, {
--     sequence = {"salute_idle1", "salute_idle2"},  -- Main sequence
--     start = {"salute_start1", "salute_start2"},   -- Starting sequence
--     finish = {"salute_finish1", "salute_finish2"} -- Finishing sequence
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

    --- The `data` table passed into `ix.act.Register` defines the structure of the act, including the main sequence
    -- as well as optional starting and finishing sequences. This table allows you to control the animation performed by
    -- the player, including preparation and cool down sequences for more immersive animations.
    -- 
    -- @table ActInfoStructure
    -- @realm shared
    -- @field[type=string|table] sequence The main sequence(s) that the act will perform. This is required, and can be either a single sequence (as a string) or multiple sequences (as a table). If multiple sequences are provided, one will be chosen at random.
    -- @field[type=string|table,opt] start An optional starting sequence (or sequences) that plays before the main sequence. If provided, this must match the number of main sequences, or an error will be thrown.
    -- @field[type=string|table,opt] finish An optional finishing sequence (or sequences) that plays after the main sequence. If provided, this must match the number of main sequences, or an error will be thrown.
    -- @usage
    -- -- Simple example with a single sequence
    -- ix.act.Register("Wave", "citizen", {
    --     sequence = "wave"
    -- })
    --
    -- -- Complex example with start and finish sequences for multiple model classes
    -- ix.act.Register("Salute", {"citizen", "metrocop"}, {
    --     sequence = {"salute_idle1", "salute_idle2"},
    --     start = {"salute_start1", "salute_start2"},
    --     finish = {"salute_finish1", "salute_finish2"}
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
