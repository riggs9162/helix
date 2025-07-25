--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`. They are a physical representation of a `Character` - and can possess at most one `Character`
object at a time that you can interface with.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
    util.AddNetworkString("ixData")
    util.AddNetworkString("ixDataSync")

    --- Loads all of the player's data from the database.
    -- @realm server
    -- @internal
    -- @func callback Callback function to run after the data has been loaded
    -- @usage player:LoadData(function(data)
    --     print(data.money) --Prints the player's money from the database
    -- end)
    function playerMeta:LoadData(callback)
        hook.Run("PrePlayerDataLoaded", self)

        local name = self:SteamName()
        local steamID64 = self:SteamID64()
        local timestamp = math.floor(os.time())
        local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

        local query = mysql:Select("ix_players")
            query:Select("data")
            query:Select("play_time")
            query:Where("steamid", steamID64)
            query:Callback(function(result)
                if (IsValid(self) and istable(result) and #result > 0 and result[1].data) then
                    local updateQuery = mysql:Update("ix_players")
                        updateQuery:Update("last_join_time", timestamp)
                        updateQuery:Update("address", ip)
                        updateQuery:Where("steamid", steamID64)
                    updateQuery:Execute()

                    self.ixPlayTime = tonumber(result[1].play_time) or 0
                    self.ixData = util.JSONToTable(result[1].data)

                    if (callback) then
                        callback(self.ixData)
                    end

                    hook.Run("PlayerDataLoaded", self)
                else
                    local insertQuery = mysql:Insert("ix_players")
                        insertQuery:Insert("steamid", steamID64)
                        insertQuery:Insert("steam_name", name)
                        insertQuery:Insert("play_time", 0)
                        insertQuery:Insert("address", ip)
                        insertQuery:Insert("last_join_time", timestamp)
                        insertQuery:Insert("data", util.TableToJSON({}))
                    insertQuery:Execute()

                    if (callback) then
                        callback({})
                    end

                    hook.Run("PlayerDataLoaded", self)
                end

                hook.Run("PostPlayerDataLoaded", self)
            end)
        query:Execute()
    end

    --- Saves all of the player's data to the database.
    -- @realm server
    -- @usage player:SaveData() -- Saves the player's data to the database, must be called after setting data
    function playerMeta:SaveData()
        if (self:IsBot()) then return end

        local name = self:SteamName()
        local steamID64 = self:SteamID64()

        local query = mysql:Update("ix_players")
            query:Update("steam_name", name)
            query:Update("play_time", math.floor((self.ixPlayTime or 0) + (RealTime() - (self.ixJoinTime or RealTime() - 1))))
            query:Update("data", util.TableToJSON(self.ixData or {}))
            query:Where("steamid", steamID64)
        query:Execute()

        hook.Run("PlayerDataSaved", self)
    end

    --- Sets a piece of data for the player.
    -- @realm server
    -- @string key Key to store the data under
    -- @param value Value to store
    -- @bool[opt=false] bNoNetworking Whether or not to network the data to the player
    -- @usage player:SetData("customData", "hello") -- Sets the player's custom data to "hello"
    -- player:SaveData() -- Saves the player's data to the database
    function playerMeta:SetData(key, value, bNoNetworking)
        self.ixData = self.ixData or {}
        self.ixData[key] = value

        if (!bNoNetworking) then
            net.Start("ixData")
                net.WriteString(key)
                net.WriteType(value)
            net.Send(self)
        end

        hook.Run("PlayerDataUpdated", self, key, value)
    end
end

-- Whitelisting information for the player.
do
    --- Sets whether or not the player is whitelisted for a certain faction.
    -- @realm server
    -- @string faction Unique ID of the faction
    -- @bool whitelisted Whether or not the player is whitelisted
    -- @return boolean Whether or not the player was successfully whitelisted
    function playerMeta:SetWhitelisted(faction, whitelisted)
        if (!whitelisted) then
            whitelisted = nil
        end

        local data = ix.faction.indices[faction]

        if (data) then
            local whitelists = self:GetData("whitelists", {})
            whitelists[Schema.folder] = whitelists[Schema.folder] or {}
            whitelists[Schema.folder][data.uniqueID] = whitelisted and true or nil

            self:SetData("whitelists", whitelists)
            self:SaveData()

            return true
        end

        return false
    end
end

do
    playerMeta.ixGive = playerMeta.ixGive or playerMeta.Give

    function playerMeta:Give(className, bNoAmmo)
        local weapon

        self.ixWeaponGive = true
            weapon = self:ixGive(className, bNoAmmo)
        self.ixWeaponGive = nil

        return weapon
    end
end
