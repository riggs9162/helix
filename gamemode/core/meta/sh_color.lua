
--[[--
Color manipulation utilities.

The `Color` class is used to represent RGBA colors. Each color is defined by four values: red, green, blue, and alpha (transparency). The following utility functions help create, manipulate, and convert colors.

]]--
-- @classmod Color

local meta = FindMetaTable("Color")

--- Returns the color in a table format.
-- @realm shared
-- @treturn table The color as a table with fields: r, g, b, a.
-- @usage
-- local color = Color(255, 128, 64, 255)
-- print(color:ToTable()) -- {r = 255, g = 128, b = 64, a = 255}
function meta:ToTable()
    return {r = self.r, g = self.g, b = self.b, a = self.a}
end

--- Darkens the color by a percentage.
-- @realm shared
-- @tparam number percentage The percentage to darken (0-100).
-- @treturn Color The darkened color.
-- @usage
-- local color = Color(255, 128, 64, 255)
-- print(color:Darken(50)) -- Color(128, 64, 32, 255)
function meta:Darken(percentage)
    local factor = 1 - (percentage / 100)
    return Color(
        math.max(0, self.r * factor),
        math.max(0, self.g * factor),
        math.max(0, self.b * factor),
        self.a
    )
end

--- Lightens the color by a percentage.
-- @realm shared
-- @tparam number percentage The percentage to lighten (0-100).
-- @treturn Color The lightened color.
-- @usage
-- local color = Color(100, 100, 100, 255)
-- print(color:Lighten(50)) -- Color(150, 150, 150, 255)
function meta:Lighten(percentage)
    local factor = 1 + (percentage / 100)
    return Color(
        math.min(255, self.r * factor),
        math.min(255, self.g * factor),
        math.min(255, self.b * factor),
        self.a
    )
end

--- Converts the color to a hexadecimal string.
-- @realm shared
-- @treturn string The hexadecimal string in the form "#RRGGBB".
-- @usage
-- local color = Color(255, 128, 64, 255)
-- print(color:ToHex()) -- "#FF8040"
function meta:ToHex()
    return string.format("#%02X%02X%02X", self.r, self.g, self.b)
end

--- Adjusts the alpha value of the color.
-- @realm shared
-- @tparam number alpha The new alpha value (0-255).
-- @treturn Color The color with the modified alpha value.
-- @usage
-- local color = Color(255, 128, 64, 255)
-- print(color:WithAlpha(128)) -- Color(255, 128, 64, 128)
function meta:WithAlpha(alpha)
    return Color(self.r, self.g, self.b, math.Clamp(alpha, 0, 255))
end

--- Returns whether two colors are equal.
-- @realm shared
-- @tparam Color other The other color to compare with.
-- @treturn boolean True if the colors are equal, false otherwise.
-- @usage
-- local color1 = Color(255, 0, 0, 255)
-- local color2 = Color(255, 0, 0, 255)
-- print(color1:IsEqual(color2)) -- true
function meta:IsEqual(other)
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

--- Converts the color to a string in the format "r g b a".
-- @realm shared
-- @treturn string The color as a string.
-- @usage
-- local color = Color(255, 128, 64, 255)
-- print(color:ToString()) -- "255 128 64 255"
function meta:ToString()
    return string.format("%d %d %d %d", self.r, self.g, self.b, self.a)
end