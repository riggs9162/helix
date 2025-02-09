ITEM.name = "Ammo Base"
ITEM.description = "A Box that contains %s of Pistol Ammo"
ITEM.category = "Ammunition"
ITEM.model = "models/items/boxsrounds.mdl"

ITEM.width = 1
ITEM.height = 1

ITEM.ammo = "pistol"
ITEM.ammoAmount = 18
ITEM.useSound = "items/ammo_pickup.wav"

-- For the description, it will show the amount of the ammo in the item.
function ITEM:GetDescription()
    local rounds = self:GetData("rounds", self.ammoAmount)
    return Format(self.description, rounds)
end

if ( CLIENT ) then
    -- Show how much ammo is in the item.
    function ITEM:PaintOver(item, width, height)
        local rounds = item:GetData("rounds", item.ammoAmount)
        draw.SimpleText(rounds, "DermaDefault", width - 4, height - 4, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black)
    end
end

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.use = {
    name = "Load",
    tip = "useTip",
    icon = "icon16/add.png",

    OnRun = function(item)
        local ply = item.player
        if ( !IsValid(ply) ) then return false end

        local rounds = item:GetData("rounds", item.ammoAmount)
        ply:GiveAmmo(rounds, item.ammo)
        ply:EmitSound(item.useSound, 60)

        return true
    end
}

-- Called after the item is registered into the item tables.
function ITEM:OnRegistered()
    if ( ix.ammo ) then
        ix.ammo.Register(self.ammo)
    end
end