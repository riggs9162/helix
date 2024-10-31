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

function TOOL:CanPersist(entity)
    if ( entity:IsPlayer() or entity:IsVehicle() or entity.bNoPersist ) then return false end
    if ( entity:MapCreationID() != -1 ) then return false end

    return true
end

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    local entity = trace.Entity

    if ( !self:CanPersist(entity) ) then
        if ( CLIENT and IsValid(entity) ) then
            ix.util.NotifyLocalized("persist_cant_persist")
        end

        return false
    end

    if ( CLIENT ) then return true end

    if ( entity:GetNetVar("Persistent", false) ) then
        ply:NotifyLocalized("persist_already_persisted")
        return false
    end

    for k, v in ipairs(ix.persist.stored) do
        if ( v == entity ) then
            ply:NotifyLocalized("persist_already_persisted")
            return false
        end
    end

    ix.persist.stored[#ix.persist.stored + 1] = entity

    entity:SetNetVar("Persistent", true)

    ply:NotifyLocalized("persist_entity")

    ix.log.Add(ply, "persist", ix.persist:GetRealModel(entity), true)

    return true
end

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    local entity = trace.Entity

    if ( !self:CanPersist(entity) ) then
        if ( CLIENT and IsValid(entity) ) then
            ix.util.NotifyLocalized("persist_cant_persist")
        end

        return false
    end

    if ( CLIENT ) then return true end

    if ( !entity:GetNetVar("Persistent", false) ) then
        ply:NotifyLocalized("persist_not_persisted")
        return false
    end

    for k, v in ipairs(ix.persist.stored) do
        if ( v == entity ) then
            table.remove(ix.persist.stored, k)
            break
        end
    end

    entity:SetNetVar("Persistent", false)

    ply:NotifyLocalized("persist_unpersisted")

    ix.log.Add(ply, "persist", ix.persist:GetRealModel(entity), false)

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