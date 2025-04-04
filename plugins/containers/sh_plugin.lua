
--[[--
Provides characters the ability to store items in containers placed by server administrators.

]]
-- @module ix.container

local PLUGIN = PLUGIN

PLUGIN.name = "Containers"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Provides the ability to store items."

ix.container = ix.container or {}
ix.container.stored = ix.container.stored or {}

ix.config.Add("containerSave", true, "Whether or not containers will save after a server restart.", nil, {
    category = "Containers"
})

ix.config.Add("containerOpenTime", 0.7, "How long it takes to open a container.", nil, {
    data = {min = 0, max = 50},
    category = "Containers"
})

--- Registers a model as a container in the Helix framework.
-- Containers are objects in the game that allow players to store and retrieve items. Each container can have its own size, 
-- optional sounds, and custom behaviors when interacting with it (e.g., animations or sound effects). Containers are registered
-- based on their model, and the container’s properties are defined through the `data` table.
--
-- @realm shared
-- @string model The path to the model used for the container (e.g., `"models/props_junk/trashbin01a.mdl"`). The model path is automatically converted to lowercase for consistency.
-- @tparam table data The container's properties and optional behavior.
-- @usage
-- -- Register a small trash bin with a 2x2 inventory grid.
-- ix.container.Register("models/props_junk/trashbin01a.mdl", {
--     name = "Trash Bin",
--     description = "What do you expect to find in here?",
--     width = 2,
--     height = 2
-- })
function ix.container.Register(model, data)
    -- Register the container's data under the model path, converting the path to lowercase.
    -- This ensures that lookups are consistent, regardless of the case of the model path.
    ix.container.stored[model:lower()] = data

    --- The `data` table defines the properties and optional behaviors of the container.
    -- This structure allows for customizations like the container's name, description, size, sounds, and custom behavior on opening and closing.
    -- 
    -- @table ContainerInfoStructure
    -- @realm shared
    -- @field[type=string] name The name displayed to the player when interacting with the container.
    -- @field[type=string] description A short description that gives context or a hint about the container's contents or purpose.
    -- @field[type=number] width The number of inventory slots horizontally in the container.
    -- @field[type=number] height The number of inventory slots vertically in the container.
    -- @field[type=function,opt] OnOpen A function executed when the container is opened. This can be used to trigger actions like playing an animation or sound when a player interacts with the container.
    -- @field[type=function,opt] OnClose A function executed when the container is closed. It allows for custom behavior when the container is no longer being accessed.
    -- @field[type=string,opt] locksound The sound played when the container is locked or accessed. This provides auditory feedback when interacting with locked containers.
    -- 
    -- @usage
    -- -- Registering a trash bin container with a simple inventory.
    -- ix.container.Register("models/props_junk/trashbin01a.mdl", {
    --     name = "Trash Bin",
    --     description = "What do you expect to find in here?",
    --     width = 2,
    --     height = 2
    -- })
    -- 
    -- -- Registering a dumpster with a larger inventory.
    -- ix.container.Register("models/props_junk/trashdumpster01a.mdl", {
    --     name = "Dumpster",
    --     description = "A dumpster meant to stow away trash. It emanates an unpleasant smell.",
    --     width = 6,
    --     height = 3
    -- })
    -- @usage
    -- -- Registering an ammo crate with a custom OnOpen function to play animations and sounds.
    -- ix.container.Register("models/items/ammocrate_smg1.mdl", {
    --     name = "Ammo Crate",
    --     description = "A heavy crate that stores ammo.",
    --     width = 5,
    --     height = 3,
    --     locksound = "items/ammocrate_close.wav",
    --     OnOpen = function(entity, activator)
    --         local closeSeq = entity:LookupSequence("Close")
    --         entity:ResetSequence(closeSeq)
    -- 
    --         timer.Simple(2, function()
    --             if (IsValid(entity)) then
    --                 local openSeq = entity:LookupSequence("Open")
    --                 entity:ResetSequence(openSeq)
    --             end
    --         end)
    --     end,
    --     OnClose = function(entity)
    --         -- Play a close sound or reset container state here
    --     end
    -- })
end

ix.util.Include("sh_definitions.lua")

if (SERVER) then
    util.AddNetworkString("ixContainerPassword")

    function PLUGIN:PlayerSpawnedProp(client, model, entity)
        model = tostring(model):lower()
        local data = ix.container.stored[model]

        if (data) then
            if (hook.Run("CanPlayerSpawnContainer", client, model, entity) == false) then return end

            local container = ents.Create("ix_container")
            container:SetPos(entity:GetPos())
            container:SetAngles(entity:GetAngles())
            container:SetModel(model)
            container:Spawn()

            ix.inventory.New(0, "container:" .. model:lower(), function(inventory)
                -- we'll technically call this a bag since we don't want other bags to go inside
                inventory.vars.isBag = true
                inventory.vars.isContainer = true

                if (IsValid(container)) then
                    container:SetInventory(inventory)
                    self:SaveContainer()
                end
            end)

            entity:Remove()
        end
    end

    function PLUGIN:CanSaveContainer(entity, inventory)
        return ix.config.Get("containerSave", true)
    end

    function PLUGIN:SaveContainer()
        local data = {}

        for _, v in ipairs(ents.FindByClass("ix_container")) do
            if (hook.Run("CanSaveContainer", v, v:GetInventory()) != false) then
                local inventory = v:GetInventory()

                if (inventory) then
                    data[#data + 1] = {
                        v:GetPos(),
                        v:GetAngles(),
                        inventory:GetID(),
                        v:GetModel(),
                        v.password,
                        v:GetDisplayName(),
                        v:GetMoney()
                    }
                end
            else
                local index = v:GetID()

                local query = mysql:Delete("ix_items")
                    query:Where("inventory_id", index)
                query:Execute()

                query = mysql:Delete("ix_inventories")
                    query:Where("inventory_id", index)
                query:Execute()
            end
        end

        self:SetData(data)
    end

    function PLUGIN:SaveData()
        if (!ix.shuttingDown) then
            self:SaveContainer()
        end
    end

    function PLUGIN:ContainerRemoved(entity, inventory)
        self:SaveContainer()
    end

    function PLUGIN:LoadData()
        local data = self:GetData()

        if (data) then
            for _, v in ipairs(data) do
                local data2 = ix.container.stored[v[4]:lower()]

                if (data2) then
                    local inventoryID = tonumber(v[3])

                    if (!inventoryID or inventoryID < 1) then
                        ErrorNoHalt(string.format(
                            "[Helix] Attempted to restore container inventory with invalid inventory ID '%s' (%s, %s)\n",
                            tostring(inventoryID), v[6] or "no name", v[4] or "no model"))

                        continue
                    end

                    local entity = ents.Create("ix_container")
                    entity:SetPos(v[1])
                    entity:SetAngles(v[2])
                    entity:Spawn()
                    entity:SetModel(v[4])
                    entity:SetSolid(SOLID_VPHYSICS)
                    entity:PhysicsInit(SOLID_VPHYSICS)

                    if (v[5]) then
                        entity.password = v[5]
                        entity:SetLocked(true)
                        entity.Sessions = {}
                        entity.PasswordAttempts = {}
                    end

                    if (v[6]) then
                        entity:SetDisplayName(v[6])
                    end

                    if (v[7]) then
                        entity:SetMoney(v[7])
                    end

                    ix.inventory.Restore(inventoryID, data2.width, data2.height, function(inventory)
                        inventory.vars.isBag = true
                        inventory.vars.isContainer = true

                        if (IsValid(entity)) then
                            entity:SetInventory(inventory)
                        end
                    end)

                    local physObject = entity:GetPhysicsObject()

                    if (IsValid(physObject)) then
                        physObject:EnableMotion()
                    end
                end
            end
        end
    end

    net.Receive("ixContainerPassword", function(length, client)
        if ((client.ixNextContainerPassword or 0) > RealTime()) then return end

        local entity = net.ReadEntity()
        local steamID = client:SteamID64()
        local attempts = entity.PasswordAttempts[steamID]

        if (attempts and attempts >= 10) then
            client:NotifyLocalized("passwordAttemptLimit")

            return
        end

        local password = net.ReadString()
        local dist = entity:GetPos():DistToSqr(client:GetPos())

        if (dist < 16384 and password) then
            if (entity.password and entity.password == password) then
                entity:OpenInventory(client)
            else
                entity.PasswordAttempts[steamID] = attempts and attempts + 1 or 1

                client:NotifyLocalized("wrongPassword")
            end
        end

        client.ixNextContainerPassword = RealTime() + 1
    end)

    ix.log.AddType("containerPassword", function(client, ...)
        local arg = {...}
        return string.format("%s has %s the password for '%s'.", client:Name(), arg[3] and "set" or "removed", arg[1], arg[2])
    end)

    ix.log.AddType("containerName", function(client, ...)
        local arg = {...}

        if (arg[3]) then
            return string.format("%s has set container %d name to '%s'.", client:Name(), arg[2], arg[1])
        else
            return string.format("%s has removed container %d name.", client:Name(), arg[2])
        end
    end)

    ix.log.AddType("openContainer", function(client, ...)
        local arg = {...}
        return string.format("%s opened the '%s' #%d container.", client:Name(), arg[1], arg[2])
    end, FLAG_NORMAL)

    ix.log.AddType("closeContainer", function(client, ...)
        local arg = {...}
        return string.format("%s closed the '%s' #%d container.", client:Name(), arg[1], arg[2])
    end, FLAG_NORMAL)
else
    net.Receive("ixContainerPassword", function(length)
        local entity = net.ReadEntity()

        Derma_StringRequest(
            L("containerPasswordWrite"),
            L("containerPasswordWrite"),
            "",
            function(val)
                net.Start("ixContainerPassword")
                    net.WriteEntity(entity)
                    net.WriteString(val)
                net.SendToServer()
            end
        )
    end)
end

function PLUGIN:InitializedPlugins()
    for k, v in pairs(ix.container.stored) do
        if (v.name and v.width and v.height) then
            ix.inventory.Register("container:" .. k:lower(), v.width, v.height)
        else
            ErrorNoHalt("[Helix] Container for '"..k.."' is missing all inventory information!\n")
            ix.container.stored[k] = nil
        end
    end
end

-- properties
properties.Add("container_setpassword", {
    MenuLabel = "Set Password",
    Order = 400,
    MenuIcon = "icon16/lock_edit.png",

    Filter = function(self, entity, client)
        if (entity:GetClass() != "ix_container") then return false end
        if (!gamemode.Call("CanProperty", client, "container_setpassword", entity)) then return false end

        return true
    end,

    Action = function(self, entity)
        Derma_StringRequest(L("containerPasswordWrite"), "", "", function(text)
            self:MsgStart()
                net.WriteEntity(entity)
                net.WriteString(text)
            self:MsgEnd()
        end)
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        local password = net.ReadString()

        entity.Sessions = {}
        entity.PasswordAttempts = {}

        if (password:len() != 0) then
            entity:SetLocked(true)
            entity.password = password

            client:NotifyLocalized("containerPassword", password)
        else
            entity:SetLocked(false)
            entity.password = nil

            client:NotifyLocalized("containerPasswordRemove")
        end

        local name = entity:GetDisplayName()
        local inventory = entity:GetInventory()

        ix.log.Add(client, "containerPassword", name, inventory:GetID(), password:len() != 0)
    end
})

properties.Add("container_setname", {
    MenuLabel = "Set Name",
    Order = 400,
    MenuIcon = "icon16/tag_blue_edit.png",

    Filter = function(self, entity, client)
        if (entity:GetClass() != "ix_container") then return false end
        if (!gamemode.Call("CanProperty", client, "container_setname", entity)) then return false end

        return true
    end,

    Action = function(self, entity)
        Derma_StringRequest(L("containerNameWrite"), "", "", function(text)
            self:MsgStart()
                net.WriteEntity(entity)
                net.WriteString(text)
            self:MsgEnd()
        end)
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        local name = net.ReadString()

        if (name:len() != 0) then
            entity:SetDisplayName(name)

            client:NotifyLocalized("containerName", name)
        else
            local definition = ix.container.stored[entity:GetModel():lower()]

            entity:SetDisplayName(definition.name)

            client:NotifyLocalized("containerNameRemove")
        end

        local inventory = entity:GetInventory()

        ix.log.Add(client, "containerName", name, inventory:GetID(), name:len() != 0)
    end
})
