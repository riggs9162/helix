
-- luacheck: ignore 111

--[[--
Rank setup hooks.

As with `Faction`s, `Rank`s get their own hooks for when players leave/join a rank, etc. These hooks are only
valid in rank tables that are created in `schema/ranks/sh_rankname.lua`, and cannot be used like regular gamemode hooks.
]]
-- @hooks Rank

--- Whether or not a player can switch to this rank.
-- @realm shared
-- @player client Client that wants to switch to this rank
-- @treturn bool True if the player is allowed to switch to this rank
-- @usage function RANK:CanSwitchTo(client)
--     return client:IsAdmin() -- only admins allowed in this rank!
-- end
function CanSwitchTo(client)
end

--- Called when a character has left this rank and has joined a different one. You can get the rank the character has
-- has joined by calling `character:GetRank()`.
-- @realm server
-- @player client Player who left this rank
function OnLeave(client)
end

--- Called when a character has joined this rank.
-- @realm server
-- @player client Player who has joined this rank
-- @usage function RANK:OnSet(client)
--     client:SetModel("models/police.mdl")
-- end
function OnSet(client)
end

--- Called when a character in this rank has spawned in the world.
-- @realm server
-- @player client Player that has just spawned
function OnSpawn(client)
end

--- Called when a character in this rank has been given their loadouts.
-- @realm server
-- @player client Player that has been given their loadouts
function OnLoadout(client)
end