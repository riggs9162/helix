--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`. They are a physical representation of a `Character` - and can possess at most one `Character`
object at a time that you can interface with.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local playerMeta = FindMetaTable("Player")

-- ixData information for the player.
do
    if (SERVER) then
        --- Returns the value of a player's data.
        -- @realm shared
        -- @string key The key to get the data from.
        -- @param default The value to return if the data does not exist.
        -- @treturn any The value of the data.
        function playerMeta:GetData(key, default)
            if (key == true) then
                return self.ixData
            end

            local data = self.ixData and self.ixData[key]

            if (data == nil) then
                return default
            else
                return data
            end
        end
    else
        function playerMeta:GetData(key, default)
            local data = ix.localData and ix.localData[key]

            if (data == nil) then
                return default
            else
                return data
            end
        end

        net.Receive("ixDataSync", function()
            ix.localData = net.ReadTable()
            ix.playTime = net.ReadUInt(32)
        end)

        net.Receive("ixData", function()
            ix.localData = ix.localData or {}
            ix.localData[net.ReadString()] = net.ReadType()
        end)
    end
end

-- Whitelist networking information here.
do
    --- Returns whether or not a player has a whitelist for a faction.
    -- @realm shared
    -- @string faction The index of the faction to check.
    -- @treturn bool Whether or not the player has the whitelist.
    function playerMeta:HasWhitelist(faction)
        local data = ix.faction.indices[faction]

        if (data) then
            if (data.isDefault) then
                return true
            end

            local ixData = self:GetData("whitelists", {})

            return ixData[Schema.folder] and ixData[Schema.folder][data.uniqueID] == true or false
        end

        return false
    end

    --- Returns all of the player's current items.
    -- @realm shared
    -- @treturn table The player's items.
    function playerMeta:GetItems()
        local character = self:GetCharacter()

        if (character) then
            local inv = character:GetInventory()

            if (inv) then
                return inv:GetItems()
            end
        end
    end

    --- Returns the current class data of the character the player is using.
    -- @realm shared
    -- @treturn table The class data.
    function playerMeta:GetClassData()
        local character = self:GetCharacter()

        if (character) then
            local class = character:GetClass()

            if (class) then
                local classData = ix.class.list[class]

                return classData
            end
        end
    end

    --- Returns the current rank data of the character the player is using.
    -- @realm shared
    -- @treturn table The rank data.
    function playerMeta:GetRankData()
        local character = self:GetCharacter()

        if (character) then
            local rank = character:GetRank()

            if (rank) then
                local rankData = ix.rank.list[rank]

                return rankData
            end
        end
    end
end

do
    if (SERVER) then
        util.AddNetworkString("PlayerModelChanged")
        util.AddNetworkString("PlayerSelectWeapon")

        local entityMeta = FindMetaTable("Entity")

        entityMeta.ixSetModel = entityMeta.ixSetModel or entityMeta.SetModel
        playerMeta.ixSelectWeapon = playerMeta.ixSelectWeapon or playerMeta.SelectWeapon

        function entityMeta:SetModel(model)
            if (!model or model == "") then return end

            local oldModel = self:GetModel()

            if (self:IsPlayer()) then
                hook.Run("PlayerModelChanged", self, model, oldModel)

                net.Start("PlayerModelChanged")
                    net.WritePlayer(self)
                    net.WriteString(model)
                    net.WriteString(oldModel)
                net.Broadcast()
            end

            return self:ixSetModel(model)
        end

        function playerMeta:SelectWeapon(className)
            net.Start("PlayerSelectWeapon")
                net.WritePlayer(self)
                net.WriteString(className)
            net.Broadcast()

            return self:ixSelectWeapon(className)
        end
    else
        net.Receive("PlayerModelChanged", function(length)
            hook.Run("PlayerModelChanged", net.ReadPlayer(), net.ReadString(), net.ReadString())
        end)

        net.Receive("PlayerSelectWeapon", function(length)
            local client = net.ReadPlayer()
            local className = net.ReadString()

            if (!IsValid(client)) then
                hook.Run("PlayerWeaponChanged", client, NULL)
                return
            end

            for _, v in ipairs(client:GetWeapons()) do
                if (v:GetClass() == className) then
                    hook.Run("PlayerWeaponChanged", client, v)
                    break
                end
            end
        end)
    end
end
