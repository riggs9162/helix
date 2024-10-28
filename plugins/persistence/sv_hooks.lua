local PLUGIN = PLUGIN

function PLUGIN:LoadData()
    local entities = self:GetData() or {}

    for _, v in ipairs(entities) do
        local entity = ents.Create(v.Class)

        if (IsValid(entity)) then
            entity:SetPos(v.Pos)
            entity:SetAngles(v.Angle)
            entity:SetModel(v.Model)
            entity:SetSkin(v.Skin)
            entity:SetColor(v.Color)
            entity:SetMaterial(v.Material)
            entity:Spawn()
            entity:Activate()

            if (v.bNoCollision) then
                entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
            end

            if (istable(v.BodyGroups)) then
                for k2, v2 in pairs(v.BodyGroups) do
                    entity:SetBodygroup(k2, v2)
                end
            end

            if (istable(v.SubMaterial)) then
                for k2, v2 in pairs(v.SubMaterial) do
                    if (!isnumber(k2) or !isstring(v2)) then
                        continue
                    end

                    entity:SetSubMaterial(k2 - 1, v2)
                end
            end

            local physicsObject = entity:GetPhysicsObject()

            if (IsValid(physicsObject)) then
                physicsObject:EnableMotion(v.Movable)
            end

            self.stored[#self.stored + 1] = entity

            entity:SetNetVar("Persistent", true)
        end
    end
end

function PLUGIN:SaveData()
    local entities = {}

    for _, v in ipairs(self.stored) do
        if (IsValid(v)) then
            local data = {}
            data.Class = v.ClassOverride or v:GetClass()
            data.Pos = v:GetPos()
            data.Angle = v:GetAngles()
            data.Model = GetRealModel(v)
            data.Skin = v:GetSkin()
            data.Color = v:GetColor()
            data.Material = v:GetMaterial()
            data.bNoCollision = v:GetCollisionGroup() == COLLISION_GROUP_WORLD

            local materials = v:GetMaterials()

            if (istable(materials)) then
                data.SubMaterial = {}

                for k2, _ in pairs(materials) do
                    if (v:GetSubMaterial(k2 - 1) != "") then
                        data.SubMaterial[k2] = v:GetSubMaterial(k2 - 1)
                    end
                end
            end

            local bodyGroups = v:GetBodyGroups()

            if (istable(bodyGroups)) then
                data.BodyGroups = {}

                for _, v2 in pairs(bodyGroups) do
                    if (v:GetBodygroup(v2.id) > 0) then
                        data.BodyGroups[v2.id] = v:GetBodygroup(v2.id)
                    end
                end
            end

            local physicsObject = v:GetPhysicsObject()

            if (IsValid(physicsObject)) then
                data.Movable = physicsObject:IsMoveable()
            end

            entities[#entities + 1] = data
        end
    end

    self:SetData(entities)
end