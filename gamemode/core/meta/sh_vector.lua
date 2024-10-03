
--[[--
Position and direction in 3D space.

`Vectors` are used to represent 3D positions, directions, and sizes. They are used in many places in the Source Engine, such as the `Entity` class, the `PhysObj` class, and the `CUserCmd` class.

Vectors are represented by three numbers, `x`, `y`, and `z`. They can be created using the `Vector` function, which takes three numbers as arguments, or by using the `Vector` class, which has several methods for creating and manipulating vectors.

See the [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/Vector) for all other methods that the `Vector` class has.
]]
-- @classmod Vector

local meta = FindMetaTable("Vector")

--- Returns the center of two vectors
-- @realm shared
-- @treturn Vector The center of the two vectors
-- @usage -- Prints the center of two players
-- print(Entity(1):GetPos():Center(Entity(2):GetPos()))
function meta:Center(other)
    return ( self + other ) / 2
end

--- Rounds the vector to the nearest whole number
-- @realm shared
-- @treturn Vector The rounded vector
-- @usage -- Rounds the vector to the nearest whole number
-- local vec = Vector(1.5, 2.3, 3.7)
-- print(vec:Round())
-- > 2 2 4
function meta:Round(decimals)
    local x, y, z = self.x, self.y, self.z
    return Vector(math.Round(x, decimals), math.Round(y, decimals), math.Round(z, decimals))
end

--- Returns the distance between two vectors
-- @realm shared
-- @treturn number The distance between the two vectors
-- @usage -- Prints the distance between two players
-- print(Entity(1):GetPos():Distance(Entity(2):GetPos()))
function meta:Distance(other)
    local x, y, z = self.x, self.y, self.z
    local x2, y2, z2 = other.x, other.y, other.z

    return math.sqrt((x - x2)^2 + (y - y2)^2 + (z - z2)^2)
end

local CrossProduct = meta.Cross
local right = Vector(0, -1, 0)

--- Returns the right vector of the vector
-- @realm shared
-- @tparam[opt=Vector(0, -1, 0)] Vector vUp The up vector
-- @treturn Vector The right vector
-- @usage -- Prints the right vector of the player
-- print(Entity(1):GetPos():Right())
function meta:Right(vUp)
    if (self[1] == 0 and self[2] == 0) then
        return right
    end

    if (vUp == nil) then
        vUp = vector_up
    end

    local vRet = CrossProduct(self, vUp)
    vRet:Normalize()

    return vRet
end

--- Returns the up vector of the vector
-- @realm shared
-- @tparam[opt=Vector(0, 0, 1)] Vector vUp The up vector
-- @treturn Vector The up vector
-- @usage -- Prints the up vector of the player
-- print(Entity(1):GetPos():Up())
function meta:Up(vUp)
    if (self[1] == 0 and self[2] == 0) then return Vector(-self[3], 0, 0) end

    if (vUp == nil) then
        vUp = vector_up
    end

    local vRet = CrossProduct(self, vUp)
    vRet = CrossProduct(vRet, self)
    vRet:Normalize()

    return vRet
end

local trace = {collisiongroup = COLLISION_GROUP_WORLD, output = {}}

--- Returns whether or not the vector is in the world.
-- @realm shared
-- @treturn bool Whether or not the vector is in the world
-- @usage -- Prints whether or not the vector is in the world
-- print(Entity(1):GetPos():InWorld())
function meta:InWorld()
    if ( SERVER ) then return util.IsInWorld(self) end

    trace.start = self
	trace.endpos = self

    return util.TraceLine(tr).HitWorld
end