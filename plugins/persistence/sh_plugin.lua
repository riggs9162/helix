local PLUGIN = PLUGIN

PLUGIN.name = "Persistence"
PLUGIN.description = "Define entities to persist through restarts."
PLUGIN.author = "alexgrist, Riggs"

PLUGIN.stored = PLUGIN.stored or {}

function PLUGIN:GetRealModel(entity)
    return entity:GetClass() == "prop_effect" and entity.AttachedEntity:GetModel() or entity:GetModel()
end

properties.Add("persist", {
    MenuLabel = "#makepersistent",
    Order = 400,
    MenuIcon = "icon16/link.png",

    Filter = function(self, entity, client)
        if (entity:IsPlayer() or entity:IsVehicle() or entity.bNoPersist) then return false end
        if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end
        if (entity:MapCreationID() == -1) then return false end

        return !entity:GetNetVar("Persistent", false)
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        PLUGIN.stored[#PLUGIN.stored + 1] = entity

        entity:SetNetVar("Persistent", true)

        ix.log.Add(client, "persist", PLUGIN:GetRealModel(entity), true)
    end
})

properties.Add("persist_end", {
    MenuLabel = "#stoppersisting",
    Order = 400,
    MenuIcon = "icon16/link_break.png",

    Filter = function(self, entity, client)
        if (entity:IsPlayer()) then return false end
        if (!gamemode.Call("CanProperty", client, "persist", entity)) then return false end
        if (entity:MapCreationID() == -1) then return false end

        return entity:GetNetVar("Persistent", false)
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        for k, v in ipairs(PLUGIN.stored) do
            if (v == entity) then
                table.remove(PLUGIN.stored, k)

                break
            end
        end

        entity:SetNetVar("Persistent", false)

        ix.log.Add(client, "persist", PLUGIN:GetRealModel(entity), false)
    end
})

function PLUGIN:PhysgunPickup(client, entity)
    if (entity:GetNetVar("Persistent", false)) then return false end
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("sv_hooks.lua")

ix.persist = PLUGIN