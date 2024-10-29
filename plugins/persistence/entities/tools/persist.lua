local PLUGIN = PLUGIN

TOOL.Name = "#tool.persist.name"
TOOL.Category = "Helix"
TOOL.Desc = "#tool.persist.desc"

TOOL.ClientConVar["persist"] = "1"

if ( CLIENT ) then
    language.Add("tool.persist.name", "Persist")
    language.Add("tool.persist.desc", "Persist entities so they are saved on the map.")
    language.Add("tool.persist.left", "Left click to persist an entity.")
    language.Add("tool.persist.right", "Right click to unpersist an entity.")
    language.Add("tool.persist.persist", "Persist")
    language.Add("tool.persist.persist.help", "Persist entities so they are saved on the map.")
end

TOOL.Information = {
    { name = "left" },
    { name = "right" }
}

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    local entity = trace.Entity
    if ( !IsValid(entity) or entity:IsPlayer() or entity:IsVehicle() or entity.bNoPersist ) then return false end
    if ( !gamemode.Call("CanProperty", ply, "persist", entity) ) then return false end

    if ( CLIENT ) then return true end

    if ( entity:GetNetVar("Persistent", false) ) then
        ply:NotifyLocalized("persist_already_persisted")
        return false
    end

    for k, v in ipairs(PLUGIN.stored) do
        if ( v == entity ) then
            ply:NotifyLocalized("persist_already_persisted")
            return false
        end
    end

    PLUGIN.stored[#PLUGIN.stored + 1] = entity

    entity:SetNetVar("Persistent", true)

    ply:NotifyLocalized("persist_entity")

    ix.log.Add(ply, "persist", GetRealModel(entity), true)

    return true
end

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    local entity = trace.Entity
    if ( !IsValid(entity) or entity:IsPlayer() ) then return false end
    if ( !gamemode.Call("CanProperty", ply, "persist", entity) ) then return false end

    if ( CLIENT ) then return true end

    if ( !entity:GetNetVar("Persistent", false) ) then
        ply:NotifyLocalized("persist_not_persisted")
        return false
    end

    for k, v in ipairs(PLUGIN.stored) do
        if ( v == entity ) then
            table.remove(PLUGIN.stored, k)
            break
        end
    end

    entity:SetNetVar("Persistent", false)

    ply:NotifyLocalized("persist_unpersisted")

    ix.log.Add(ply, "persist", GetRealModel(entity), false)

    return true
end

function TOOL:ReleaseGhostEntity()
end

function TOOL:FreezeMovement()
end

function TOOL:DrawHUD()
end

function TOOL:GetHelpText()
end

function TOOL:UpdateData()
end