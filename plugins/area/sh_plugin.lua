
--[[--
Allows administrators of the server to define areas that can be used for various purposes.

Areas are defined by a start and end position, and can have properties that can be used to define what the area is used for. For example, an area could be used to define a safezone, a restricted area, or a roleplay area if you are experienced with Lua.
]]
-- @module ix.area

local PLUGIN = PLUGIN

PLUGIN.name = "Areas"
PLUGIN.author = "`impulse"
PLUGIN.description = "Provides customizable area definitions."

ix.area = ix.area or {}
ix.area.types = ix.area.types or {}
ix.area.properties = ix.area.properties or {}
ix.area.stored = ix.area.stored or {}

ix.config.Add("areaTickTime", 1, "How many seconds between each time a character's current area is calculated.",
    function(oldValue, newValue)
        if (SERVER) then
            timer.Remove("ixAreaThink")
            timer.Create("ixAreaThink", newValue, 0, function()
                PLUGIN:AreaThink()
            end)
        end
    end,
    {
        data = {min = 0.1, max = 4},
        category = "areas"
    }
)

ix.config.Add("areaTickSoundEnabled", true, "Whether or not to play a sound when entering or exiting areas.",
    nil,
    {
        category = "areas"
    }
)

ix.config.Add("areaTickSound", "ui/buttonrollover.wav", "The sound to play when entering or exiting areas.",
    nil,
    {
        category = "areas"
    }
)

ix.config.Add("areaTickSoundMin", 190, "The minimum pitch of the area tick sound.",
    nil,
    {
        data = {min = 1, max = 255},
        category = "areas"
    }
)

ix.config.Add("areaTickSoundMax", 200, "The maximum pitch of the area tick sound.",
    nil,
    {
        data = {min = 1, max = 255},
        category = "areas"
    }
)

ix.config.Add("areaExpireTime", 8, "How many seconds before an area notification fades away.",
    nil,
    {
        data = {min = 1, max = 60},
        category = "areas"
    }
)

ix.config.Add("areaShowNotifications", true, "Whether or not to show area notifications.",
    nil,
    {
        category = "areas"
    }
)

ix.option.Add("areaEditSnap", ix.type.number, 8, {
    category = "areas",
    min = 0,
    max = 64,
    decimals = 0
})

--- Adds a new area property.
-- @realm shared
-- @string name The name of the property
-- @string type The type of the property
-- @param default The default value of the property
-- @param[opt] data Additional data for the property
-- @usage ix.area.AddProperty("color", ix.type.color, ix.config.Get("color"))
-- @usage ix.area.AddProperty("display", ix.type.bool, true)
function ix.area.AddProperty(name, type, default, data)
    ix.area.properties[name] = {
        type = type,
        default = default
    }
end

--- Adds a new area type.
-- @realm shared
-- @string type The type of the area
-- @string[opt=type] name The name of the area
-- @usage ix.area.AddType("safezone", "Safezone")
-- @usage ix.area.AddType("restricted")
function ix.area.AddType(type, name)
    name = name or type

    -- only store localized strings on the client
    ix.area.types[type] = CLIENT and name or true
end

--- Returns the nearest area to the specified position within the specified distance.
-- @realm shared
-- @vector position The position to check
-- @number distance The distance to check
-- @treturn string The area's unique identifier
-- @treturn table The area's information, if found
-- @usage local area, info = ix.area.GetNearestArea(vector_origin, 128)
-- if (area) then
--     print("The nearest area is", info.name)
-- else
--     print("No area found.")
-- end
function ix.area.GetNearestArea(position, distance)
    local found = {}
    for id, info in pairs(ix.area.stored) do
        -- First check if the position is inside the area's bounding box
        if (position:WithinAABox(info.startPosition, info.endPosition)) then
            found[#found + 1] = {id, 0}
            continue
        end

        -- If it isn't, we check if we are near the area
        local center, startPos, endPos = PLUGIN:GetLocalAreaPosition(info.startPosition, info.endPosition)
        local areaDistance = center:Distance(position)

        if (areaDistance <= distance) then
            found[#found + 1] = {id, areaDistance}
        end
    end

    -- return the area with the shortest distance
    table.sort(found, function(a, b)
        return a[2] < b[2]
    end)

    if (#found == 0) then
        return "unknown location"
    end

    local area = found[1][1]
    if (area and ix.area.stored[area]) then
        return area, ix.area.stored[area]
    end

    return "unknown location"
end

--- Returns whether or not the specified position is within the specified area.
-- @realm shared
-- @vector position The position to check
-- @string area The area's unique identifier
-- @treturn boolean Whether or not the position is within the area
-- @treturn table The area's information, if found
-- @usage local isInArea, info = ix.area.IsInArea(vector_origin, "example")
-- if (isInArea) then
--     print("The position is within the area", info.name)
-- else
--     print("The position is not within the area.")
-- end
function ix.area.IsInArea(position, area)
    if (area and ix.area.stored[area]) then
        local info = ix.area.stored[area]
        return position:WithinAABox(info.startPosition, info.endPosition), info
    end

    return 
end

--- Returns an area if the specified position is within one.
-- @realm shared
-- @vector position The position to check
-- @treturn string The area's unique identifier
-- @treturn table The area's information, if found
-- @usage local area, info = ix.area.GetArea(vector_origin)
-- if (area) then
--     print("The position is within the area", info.name)
-- else
--     print("The position is not within any area.")
-- end
function ix.area.GetArea(position)
    for id, info in pairs(ix.area.stored) do
        if (position:WithinAABox(info.startPosition, info.endPosition)) then
            return id, info
        end
    end
end

function PLUGIN:SetupAreaProperties()
    ix.area.AddType("area")

    ix.area.AddProperty("color", ix.type.color, ix.config.Get("color"))
    ix.area.AddProperty("display", ix.type.bool, true)
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

-- return world center, local min, and local max from world start/end positions
function PLUGIN:GetLocalAreaPosition(startPosition, endPosition)
    local center = LerpVector(0.5, startPosition, endPosition)
    local min = WorldToLocal(startPosition, angle_zero, center, angle_zero)
    local max = WorldToLocal(endPosition, angle_zero, center, angle_zero)

    return center, min, max
end

do
    local COMMAND = {}
    COMMAND.description = "@cmdAreaEdit"
    COMMAND.adminOnly = true

    function COMMAND:OnRun(client)
        client:SetWepRaised(false)

        net.Start("ixAreaEditStart")
        net.Send(client)
    end

    ix.command.Add("AreaEdit", COMMAND)
end

do
    local PLAYER = FindMetaTable("Player")

    -- returns the current area the player is in, or the last valid one if the player is not in an area
    function PLAYER:GetArea()
        return self:GetNetVar("area", "")
    end

    -- returns true if the player is in any area, this does not use the last valid area like GetArea does
    function PLAYER:IsInArea()
        return self.ixInArea
    end
end
