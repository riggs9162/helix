/*
Helper library for loading/getting rank information.

Ranks are temporary assignments for characters - analogous to a "job" in a faction. For example, you may have a police faction
in your schema, and have "police recruit" and "police chief" as different ranks in your faction. Anyone can join a rank in
their faction by default, but you can restrict this as you need with `CLASS.CanSwitchTo`.
*/

// @module ix.rank

ix.rank = ix.rank or {}
ix.rank.list = {}

local charMeta = ix.meta.character

ix.char.RegisterVar("rank", {
    bNoDisplay = true,
})

/// Loads ranks from a directory.
// @realm shared
// @internal
// @string directory The path to the rank files.
function ix.rank.LoadFromDir(directory)
    for i = 1, #file.Find(directory.."/*.lua", "LUA") do
        local v = file.Find(directory.."/*.lua", "LUA")[i]

        local niceName = v:sub(4, -5)
        // Determine a numeric identifier for this rank.
        local index = #ix.rank.list + 1
        local halt

        for _, v2 in ipairs(ix.rank.list) do
            if (v2.uniqueID == niceName) then
                halt = true

                break
            end
        end

        if (halt == true) then
            continue
        end

        // Set up a global table so the file has access to the rank table.
        RANK = {index = index, uniqueID = niceName}
            RANK.name = "Unknown"
            RANK.description = "No description available."
            RANK.limit = 0

            // For future use with plugins.
            if (PLUGIN) then
                RANK.plugin = PLUGIN.uniqueID
            end

            ix.util.Include(directory.."/"..v, "shared")

            // Why have a rank without a faction?
            if (!RANK.faction or !team.Valid(RANK.faction)) then
                ErrorNoHalt("Rank '"..niceName.."' does not have a valid faction!\n")
                RANK = nil

                continue
            end

            // Allow rank to be joinable by default.
            if (!RANK.CanSwitchTo) then
                RANK.CanSwitchTo = function(client)
                    return true
                end
            end

            ix.rank.list[index] = RANK
        RANK = nil
    end
end

/// Determines if a player is allowed to join a specific rank.
// @realm shared
// @player client Player to check
// @number rank Index of the rank
// @treturn bool Whether or not the player can switch to the rank
function ix.rank.CanSwitchTo(client, rank)
    // Get the rank table by its numeric identifier.
    local info = ix.rank.list[rank]

    // See if the rank exists.
    if (!info) then
        return false, "no info"
    end

    // If the player's faction matches the rank's faction.
    if (client:Team() != info.faction) then
        return false, "not correct team"
    end

    if (info.limit > 0) then
        if (#ix.rank.GetPlayers(info.index) >= info.limit) then
            return false, "rank is full"
        end
    end

    local canJoin, reason = hook.Run("CanPlayerJoinRank", client, rank, info)
    if (canJoin == false) then
        return false, reason
    end

    // See if the rank allows the player to join it.
    return info:CanSwitchTo(client)
end

/// Retrieves a rank table.
// @realm shared
// @number identifier Index of the rank
// @treturn table Rank table
function ix.rank.Get(identifier)
    for _, v in ipairs(ix.rank.list) do
        if (ix.util.StringMatches(v.uniqueID, tostring(identifier)) or v.index == identifier) then
            return v
        end
    end

    return nil
end

/// Retrieves the players in a rank
// @realm shared
// @number rank Index of the rank
// @treturn table Table of players in the rank
function ix.rank.GetPlayers(rank)
    local players = {}

    for _, v in player.Iterator() do
        if not ( IsValid(v) ) then
            continue
        end

        local char = v:GetCharacter()
        if (char and char:GetRank() == rank) then
            players[#players + 1] = v
        end
    end

    return players
end

if (SERVER) then
    /// Character rank methods
    // @rankmod Character

    /// Makes this character join a rank. This automatically calls `KickRank` for you.
    // @realm server
    // @number rank Index of the rank to join
    // @treturn bool Whether or not the character has successfully joined the rank
    function charMeta:JoinRank(rank)
        if (!rank) then
            self:KickRank()
            return false
        end

        local oldRank = self:GetRank()
        local client = self:GetPlayer()

        if (ix.rank.CanSwitchTo(client, rank)) then
            self:SetRank(rank)
            hook.Run("PlayerJoinedRank", client, rank, oldRank)

            return true
        end

        return false
    end

    /// Kicks this character out of the rank they are currently in.
    // @realm server
    function charMeta:KickRank()
        local client = self:GetPlayer()
        if (!client) then return end

        local goRank

        for k, v in ipairs(ix.rank.list) do
            if (v.faction == client:Team() and v.isDefault) then
                goRank = k

                break
            end
        end

        self:JoinRank(goRank)

        hook.Run("PlayerJoinedRank", client, goRank)
    end

    function GAMEMODE:PlayerJoinedRank(client, rank, oldRank)
        local info = ix.rank.list[rank]
        local info2 = ix.rank.list[oldRank]

        if (info and info.OnSet) then
            info:OnSet(client)
        end

        if (info2 and info2.OnLeave) then
            info2:OnLeave(client)
        end
    end
end

ix.lang.AddTable("english", {
    cmdCharSetRank = "Forcefully makes someone become part of the specified rank in their current faction.",
    rank = "Rank",
    ranks = "Ranks",
    becomeRankFail = "You cannot become a %s!",
    becomeRank = "You have become a %s.",
    setRank = "You have set %s's rank to %s.",
    invalidRank = "That is not a valid rank!",
    invalidRankFaction = "That is not a valid rank for that faction!",
})

ix.command.Add("CharSetRank", {
    description = "@cmdCharSetRank",
    adminOnly = true,
    arguments = {
        ix.type.character,
        ix.type.text
    },
    OnRun = function(self, client, target, rank)
        local rankTable

        for _, v in ipairs(ix.rank.list) do
            if (ix.util.StringMatches(v.uniqueID, rank) or ix.util.StringMatches(v.name, rank)) then
                rankTable = v
            end
        end

        if (rankTable) then
            local oldRank = target:GetRank()
            local targetPlayer = target:GetPlayer()

            if (targetPlayer:Team() == rankTable.faction) then
                target:SetRank(rankTable.index)
                hook.Run("PlayerJoinedRank", targetPlayer, rankTable.index, oldRank)

                targetPlayer:NotifyLocalized("becomeRank", L(rankTable.name, targetPlayer))

                // only send second notification if the character isn't setting their own rank
                if (client != targetPlayer) then
                    return "@setRank", target:GetName(), L(rankTable.name, client)
                end
            else
                return "@invalidRankFaction"
            end
        else
            return "@invalidRank"
        end
    end
})

hook.Add("InitializedPlugins", "ixLoadRanks", function()
    ix.rank.LoadFromDir(engine.ActiveGamemode().."/schema/ranks")
end)