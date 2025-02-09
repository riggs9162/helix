
ITEM.name = "Weapon"
ITEM.description = "A Weapon."
ITEM.category = "Weapons"
ITEM.model = "models/weapons/w_pistol.mdl"

ITEM.width = 1
ITEM.height = 1

ITEM.class = "weapon_pistol"
ITEM.isWeapon = true
ITEM.isGrenade = false
ITEM.weaponCategory = "sidearm"
ITEM.useSound = "items/ammo_pickup.wav"

-- Inventory drawing
if (CLIENT) then
    function ITEM:PaintOver(item, w, h)
        if (item:GetData("equip")) then
            surface.SetDrawColor(110, 255, 110, 100)
            surface.DrawRect(w - 14, h - 14, 8, 8)
        end
    end

    function ITEM:PopulateTooltip(tooltip)
        if (self:GetData("equip")) then
            local name = tooltip:GetRow("name")
            name:SetBackgroundColor(derma.GetColor("Success", tooltip))
        end
    end
end

-- On item is dropped, Remove a weapon from the player and keep the ammo in the item.
ITEM:Hook("drop", function(item)
    local inventory = ix.item.inventories[item.invID]
    if ( !inventory ) then return end

    -- the item could have been dropped by someone else (i.e someone searching this player), so we find the real owner
    local owner
    for ply, character in ix.util.GetCharacters() do
        if ( character:GetID() == inventory.owner ) then
            owner = ply
            break
        end
    end

    if ( !IsValid(owner) ) then return end

    if ( item:GetData("equip") ) then
        item:SetData("equip", nil)

        owner.carryWeapons = owner.carryWeapons or {}

        local weapon = owner.carryWeapons[item.weaponCategory]
        if ( !IsValid(weapon) ) then
            weapon = owner:GetWeapon(item.class)
        end

        if ( IsValid(weapon) ) then
            item:SetData("ammo", weapon:Clip1())

            owner:StripWeapon(item.class)
            owner.carryWeapons[item.weaponCategory] = nil
            owner:EmitSound(item.useSound, 60)
        end

        item:RemovePAC(owner)
    end
end)

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.EquipUn = { -- sorry, for name order.
    name = "Unequip",
    tip = "equipTip",
    icon = "icon16/cross.png",

    OnRun = function(item)
        item:Unequip(item.player, true)
        return false
    end,

    OnCanRun = function(item)
        local ply = item.player

        return !IsValid(item.entity) and IsValid(ply) and item:GetData("equip") == true and hook.Run("CanPlayerUnequipItem", ply, item) != false
    end
}

-- On player eqipped the item, Gives a weapon to player and load the ammo data from the item.
ITEM.functions.Equip = {
    name = "Equip",
    tip = "equipTip",
    icon = "icon16/tick.png",

    OnRun = function(item)
        item:Equip(item.player, true)
        return false
    end,

    OnCanRun = function(item)
        local ply = item.player

        return !IsValid(item.entity) and IsValid(ply) and item:GetData("equip") != true and hook.Run("CanPlayerEquipItem", ply, item) != false
    end
}

function ITEM:WearPAC(ply)
    if ( ix.pac and self.pacData ) then
        ply:AddPart(self.uniqueID, self)
    end
end

function ITEM:RemovePAC(ply)
    if ( ix.pac and self.pacData ) then
        ply:RemovePart(self.uniqueID)
    end
end

function ITEM:Equip(ply, bNoSelect, bNoSound)
    local char = ply:GetCharacter()
    local inventory = char:GetInventory()

    local items = inventory:GetItems()

    ply.carryWeapons = ply.carryWeapons or {}

    for v, _ in inventory:Iter() do
        if ( v.id != self.id ) then
            local itemTable = ix.item.instances[v.id]
            if ( !itemTable ) then
                ply:NotifyLocalized("tellAdmin", "wid!xt")

                return false
            else
                if ( itemTable.isWeapon and ply.carryWeapons[self.weaponCategory] and itemTable:GetData("equip") ) then
                    ply:NotifyLocalized("weaponSlotFilled", self.weaponCategory)

                    return false
                end
            end
        end
    end

    if ( ply:HasWeapon(self.class) ) then
        ply:StripWeapon(self.class)
    end

    local weapon = ply:Give(self.class, !self.isGrenade)
    if ( IsValid(weapon) ) then
        local ammoType = weapon:GetPrimaryAmmoType()

        ply.carryWeapons[self.weaponCategory] = weapon

        if ( !bNoSelect ) then
            ply:SelectWeapon(weapon:GetClass())
        end

        if ( !bNoSound ) then
            ply:EmitSound(self.useSound, 60)
        end

        -- Remove default given ammo.
        if ( ply:GetAmmoCount(ammoType) == weapon:Clip1() and self:GetData("ammo", 0) == 0 ) then
            ply:RemoveAmmo(weapon:Clip1(), ammoType)
        end

        -- assume that a weapon with -1 clip1 and clip2 would be a throwable (i.e hl2 grenade)
        -- TODO: figure out if this interferes with any other weapons
        if ( weapon:GetMaxClip1() == -1 and weapon:GetMaxClip2() == -1 and ply:GetAmmoCount(ammoType) == 0 ) then
            ply:SetAmmo(1, ammoType)
        end

        self:SetData("equip", true)

        if ( self.isGrenade ) then
            weapon:SetClip1(1)
            ply:SetAmmo(0, ammoType)
        else
            weapon:SetClip1(self:GetData("ammo", 0))
        end

        weapon.ixItem = self

        if ( self.OnEquipWeapon ) then
            self:OnEquipWeapon(ply, weapon)
        end
    else
        print(Format("[Helix] Cannot equip weapon - %s does not exist!", self.class))
    end
end

function ITEM:Unequip(ply, bPlaySound, bRemoveItem)
    ply.carryWeapons = ply.carryWeapons or {}

    local weapon = ply.carryWeapons[self.weaponCategory]
    if ( !IsValid(weapon) ) then
        weapon = ply:GetWeapon(self.class)
    end

    if ( IsValid(weapon) ) then
        weapon.ixItem = nil

        self:SetData("ammo", weapon:Clip1())
        ply:StripWeapon(self.class)
    else
        print(Format("[Helix] Cannot unequip weapon - %s does not exist!", self.class))
    end

    if ( bPlaySound ) then
        ply:EmitSound(self.useSound, 60)
    end

    ply.carryWeapons[self.weaponCategory] = nil

    self:SetData("equip", nil)
    self:RemovePAC(ply)

    if ( self.OnUnequipWeapon ) then
        self:OnUnequipWeapon(ply, weapon)
    end

    if ( bRemoveItem ) then
        self:Remove()
    end
end

function ITEM:CanTransfer(oldInventory, newInventory)
    if ( newInventory and self:GetData("equip") ) then
        local owner = self:GetOwner()
        if ( IsValid(owner) ) then
            owner:NotifyLocalized("equippedWeapon")
        end

        return false
    end

    return true
end

function ITEM:OnLoadout()
    if ( self:GetData("equip") ) then
        local ply = self.player
        ply.carryWeapons = ply.carryWeapons or {}

        local weapon = ply:Give(self.class, true)
        if ( IsValid(weapon) ) then
            ply:RemoveAmmo(weapon:Clip1(), weapon:GetPrimaryAmmoType())
            ply.carryWeapons[self.weaponCategory] = weapon

            weapon.ixItem = self
            weapon:SetClip1(self:GetData("ammo", 0))

            if ( self.OnEquipWeapon ) then
                self:OnEquipWeapon(ply, weapon)
            end
        else
            print(Format("[Helix] Cannot give weapon - %s does not exist!", self.class))
        end
    end
end

function ITEM:OnSave()
    local weapon = self.player:GetWeapon(self.class)
    if ( IsValid(weapon) and weapon.ixItem == self and self:GetData("equip") ) then
        self:SetData("ammo", weapon:Clip1())
    end
end

function ITEM:OnRemoved()
    local inventory = ix.item.inventories[self.invID]
    local owner = inventory.GetOwner and inventory:GetOwner()

    if ( IsValid(owner) and owner:IsPlayer() ) then
        local weapon = owner:GetWeapon(self.class)
        if ( IsValid(weapon) ) then
            weapon:Remove()
        end

        self:RemovePAC(owner)
    end
end

hook.Add("PlayerDeath", "ixStripClip", function(ply)
    ply.carryWeapons = {}

    local char = ply:GetCharacter()
    local inventory = char:GetInventory()
    for v, _ in inventory:Iter() do
        if ( v.isWeapon and v:GetData("equip") ) then
            v:SetData("ammo", nil)
            v:SetData("equip", nil)

            if ( v.pacData ) then
                v:RemovePAC(ply)
            end
        end
    end
end)

hook.Add("EntityRemoved", "ixRemoveGrenade", function(entity)
    -- hack to remove hl2 grenades after they've all been thrown
    if ( entity:GetClass() == "weapon_frag" ) then
        local ply = entity:GetOwner()

        if ( IsValid(ply) and ply:IsPlayer() and char ) then
            local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())
            if ( isstring(ammoName) and ammoName:lower() == "grenade" and ply:GetAmmoCount(ammoName) < 1 and entity.ixItem and entity.ixItem.Unequip ) then
                entity.ixItem:Unequip(ply, false, true)
            end
        end
    end
end)