
--- Various useful helper functions.
-- @module ix.util

ix.type = ix.type or {
    [2] = "string",
    [4] = "text",
    [8] = "number",
    [16] = "player",
    [32] = "steamid",
    [64] = "character",
    [128] = "bool",
    [1024] = "color",
    [2048] = "vector",

    string = 2,
    text = 4,
    number = 8,
    player = 16,
    steamid = 32,
    character = 64,
    bool = 128,
    color = 1024,
    vector = 2048,

    optional = 256,
    array = 512
}

ix.blurRenderQueue = {}

--- Includes a lua file based on the prefix of the file. This will automatically call `include` and `AddCSLuaFile` based on the
-- current realm. This function should always be called shared to ensure that the client will receive the file from the server.
-- @realm shared
-- @string fileName Path of the Lua file to include. The path is relative to the file that is currently running this function
-- @string[opt] realm Realm that this file should be included in. You should usually ignore this since it
-- will be automatically be chosen based on the `SERVER` and `CLIENT` globals. This value should either be `"server"` or
-- `"client"` if it is filled in manually
-- @usage ix.util.Include("sh_config.lua")
-- @usage ix.util.Include("cl_init.lua", "client")
-- @usage ix.util.Include("sv_hooks.lua", "server")
function ix.util.Include(fileName, realm)
    if (!fileName) then
        error("[Helix] No file name specified for including.")
    end

    -- Only include server-side if we're on the server.
    if ((realm == "server" or fileName:find("sv_")) and SERVER) then
        return include(fileName)
    -- Shared is included by both server and client.
    elseif (realm == "shared" or fileName:find("shared.lua") or fileName:find("sh_")) then
        if (SERVER) then
            -- Send the file to the client if shared so they can run it.
            AddCSLuaFile(fileName)
        end

        return include(fileName)
    -- File is sent to client, included on client.
    elseif (realm == "client" or fileName:find("cl_")) then
        if (SERVER) then
            AddCSLuaFile(fileName)
        else
            return include(fileName)
        end
    end
end

--- Includes multiple files in a directory.
-- @realm shared
-- @string directory Directory to include files from
-- @bool[opt] bFromLua Whether or not to search from the base `lua/` folder, instead of contextually basing from `schema/`
-- or `gamemode/`
-- @see ix.util.Include
-- @usage ix.util.IncludeDir("libs/thirdparty")
function ix.util.IncludeDir(directory, bFromLua)
    -- By default, we include relatively to Helix.
    local baseDir = "helix"

    -- If we're in a schema, include relative to the schema.
    if (Schema and Schema.folder and Schema.loading) then
        baseDir = Schema.folder.."/schema/"
    else
        baseDir = baseDir.."/gamemode/"
    end

    -- Find all of the files within the directory.
    for _, v in ipairs(file.Find((bFromLua and "" or baseDir)..directory.."/*.lua", "LUA")) do
        -- Include the file from the prefix.
        ix.util.Include(directory.."/"..v)
    end
end

--- Removes the realm prefix from a file name. The returned string will be unchanged if there is no prefix found.
-- @realm shared
-- @string name String to strip prefix from
-- @treturn string String stripped of prefix
-- @usage print(ix.util.StripRealmPrefix("sv_init.lua"))
-- > init.lua
function ix.util.StripRealmPrefix(name)
    local prefix = name:sub(1, 3)

    return (prefix == "sh_" or prefix == "sv_" or prefix == "cl_") and name:sub(4) or name
end

--- Returns `true` if the given input is a color table. This is necessary since the engine `IsColor` function only checks for
-- color metatables - which are not used for regular Lua color types.
-- @realm shared
-- @param input Input to check
-- @treturn bool Whether or not the input is a color
function ix.util.IsColor(input)
    return istable(input) and
        isnumber(input.a) and isnumber(input.g) and isnumber(input.b) and (input.a and isnumber(input.a) or input.a == nil)
end

--- Returns a dimmed version of the given color by the given scale.
-- @realm shared
-- @color color Color to dim
-- @number multiplier What to multiply the red, green, and blue values by
-- @number[opt=255] alpha Alpha to use in dimmed color
-- @treturn color Dimmed color
-- @usage print(ix.util.DimColor(Color(100, 100, 100, 255), 0.5))
-- > 50 50 50 255
function ix.util.DimColor(color, multiplier, alpha)
    return Color(color.r * multiplier, color.g * multiplier, color.b * multiplier, alpha or 255)
end

--- Sanitizes an input value with the given type. This function ensures that a valid type is always returned. If a valid value
-- could not be found, it will return the default value for the type. This only works for simple types - e.g it does not work
-- for player, character, or Steam ID types.
-- @realm shared
-- @ixtype type Type to check for
-- @param input Value to sanitize
-- @return Sanitized value
-- @see ix.type
-- @usage print(ix.util.SanitizeType(ix.type.number, "123"))
-- > 123
-- print(ix.util.SanitizeType(ix.type.bool, 1))
-- > true
function ix.util.SanitizeType(type, input)
    if (type == ix.type.string) then
        return tostring(input)
    elseif (type == ix.type.text) then
        return tostring(input)
    elseif (type == ix.type.number) then
        return tonumber(input or 0) or 0
    elseif (type == ix.type.bool) then
        return tobool(input)
    elseif (type == ix.type.color) then
        return istable(input) and
            Color(tonumber(input.r) or 255, tonumber(input.g) or 255, tonumber(input.b) or 255, tonumber(input.a) or 255) or
            color_white
    elseif (type == ix.type.vector) then
        return isvector(input) and input or Vector(0, 0, 0)
    elseif (type == ix.type.array) then
        return input
    else
        error("attempted to sanitize " .. (ix.type[type] and ("invalid type " .. ix.type[type]) or "unknown type " .. type))
    end
end

do
    local typeMap = {
        string = ix.type.string,
        number = ix.type.number,
        Player = ix.type.player,
        boolean = ix.type.bool,
        Vector = ix.type.vector
    }

    local tableMap = {
        [ix.type.character] = function(value)
            return getmetatable(value) == ix.meta.character
        end,

        [ix.type.color] = function(value)
            return ix.util.IsColor(value)
        end,

        [ix.type.steamid] = function(value)
            return isstring(value) and (value:match("STEAM_(%d+):(%d+):(%d+)")) != nil
        end
    }

    --- Returns the `ix.type` of the given value.
    -- @realm shared
    -- @param value Value to get the type of
    -- @treturn ix.type Type of value
    -- @see ix.type
    -- @usage print(ix.util.GetTypeFromValue("hello"))
    -- > 2 -- i.e the value of ix.type.string
    function ix.util.GetTypeFromValue(value)
        local result = typeMap[type(value)]

        if (result) then
            return result
        end

        if (istable(value)) then
            for k, v in pairs(tableMap) do
                if (v(value)) then
                    return k
                end
            end
        end
    end
end

function ix.util.Bind(self, callback)
    return function(_, ...)
        return callback(self, ...)
    end
end

-- Returns the address:port of the server.
function ix.util.GetAddress()
    local address = tonumber(GetConVarString("hostip"))

    if (!address) then
        return "127.0.0.1"..":"..GetConVarString("hostport")
    end

    local ip = {}
        ip[1] = bit.rshift(bit.band(address, 0xFF000000), 24)
        ip[2] = bit.rshift(bit.band(address, 0x00FF0000), 16)
        ip[3] = bit.rshift(bit.band(address, 0x0000FF00), 8)
        ip[4] = bit.band(address, 0x000000FF)
    return table.concat(ip, ".")..":"..GetConVarString("hostport")
end

--- Returns a cached copy of the given material, or creates and caches one if it doesn't exist. This is a quick helper function
-- if you aren't locally storing a `Material()` call.
-- @realm shared
-- @string materialPath Path to the material
-- @string[opt] materialParameters
-- @treturn[1] material The cached material
-- @treturn[2] nil If the material doesn't exist in the filesystem
function ix.util.GetMaterial(materialPath, materialParameters)
    local key = materialPath .. (materialParameters and materialParameters or "")
    key = key:lower()
    key = key:gsub("%W", "")

    -- Cache the material.
    ix.util.cachedMaterials = ix.util.cachedMaterials or {}
    ix.util.cachedMaterials[key] = ix.util.cachedMaterials[key] or Material(materialPath, materialParameters)

    return ix.util.cachedMaterials[key]
end

--- Attempts to find a player by matching their name or Steam ID.
-- @realm shared
-- @string identifier Search query
-- @bool[opt=false] bAllowPatterns Whether or not to accept Lua patterns in `identifier`
-- @treturn player Player that matches the given search query - this will be `nil` if a player could not be found
function ix.util.FindPlayer(identifier, bAllowPatterns)
    if (#identifier == 0) then return end

    if (string.find(identifier, "STEAM_(%d+):(%d+):(%d+)")) then
        return player.GetBySteamID(identifier)
    end

    if (!bAllowPatterns) then
        identifier = string.PatternSafe(identifier)
    end

    for _, v in player.Iterator() do
        if (ix.util.StringMatches(v:Name(), identifier) or v:SteamID() == identifier or v:SteamID64() == identifier) then
            return v
        end
    end
end

--- Checks to see if two strings are equivalent using a fuzzy manner. Both strings will be lowered, and will return `true` if
-- the strings are identical, or if `b` is a substring of `a`.
-- @realm shared
-- @string a First string to check
-- @string b Second string to check
-- @treturn bool Whether or not the strings are equivalent
function ix.util.StringMatches(a, b)
    if (a and b) then
        a = tostring(a)
        b = tostring(b)

        local a2, b2 = a:utf8lower(), b:utf8lower()

        -- Check if the actual letters match.
        if (a == b) then return true end
        if (a2 == b2) then return true end

        -- Be less strict and search.
        if (a:find(b)) then return true end
        if (a2:find(b2)) then return true end
    end

    return false
end

--- A more advanced version of `ix.util.StringMatches` that will check if two strings are equivalent by breaking them down into
-- tables of words and checking if any of the words match.
-- @realm shared
-- @string a First string to check
-- @string b Second string to check
-- @treturn bool Whether or not the strings are equivalent
function ix.util.StringMatchesTable(a, b)
    if (a and b) then
        a = tostring(a)
        b = tostring(b)

        local a2, b2 = a:utf8lower(), b:utf8lower()

        -- Check if the actual letters match.
        if (a == b) then return true end
        if (a2 == b2) then return true end

        -- Be less strict and search.
        if (a:find(b)) then return true end
        if (a2:find(b2)) then return true end

        -- Take apart the strings into tables of words.
        for _, v in ipairs(string.Explode("%s", a2, true)) do
            for _, v2 in ipairs(string.Explode("%s", b2, true)) do
                -- Now check if the words match.
                if (ix.util.StringMatches(v, v2)) then
                    return true
                end
            end
        end
    end

    return false
end

--- Returns a string that has the named arguments in the format string replaced with the given arguments.
-- @realm shared
-- @string format Format string
-- @tparam tab|... Arguments to pass to the formatted string. If passed a table, it will use that table as the lookup table for
-- the named arguments. If passed multiple arguments, it will replace the arguments in the string in order.
-- @usage print(ix.util.FormatStringNamed("Hi, my name is {name}.", {name = "Bobby"}))
-- > Hi, my name is Bobby.
-- @usage print(ix.util.FormatStringNamed("Hi, my name is {name}.", "Bobby"))
-- > Hi, my name is Bobby.
function ix.util.FormatStringNamed(format, ...)
    local arguments = {...}
    local bArray = false -- Whether or not the input has numerical indices or named ones
    local input

    -- If the first argument is a table, we can assumed it's going to specify which
    -- keys to fill out. Otherwise we'll fill in specified arguments in order.
    if (istable(arguments[1])) then
        input = arguments[1]
    else
        input = arguments
        bArray = true
    end

    local i = 0
    local result = format:gsub("{(%w-)}", function(word)
        i = i + 1
        return tostring((bArray and input[i] or input[word]) or word)
    end)

    return result
end

do
    local upperMap = {
        ["ooc"] = true,
        ["looc"] = true,
        ["afk"] = true,
        ["url"] = true
    }
    --- Returns a string that is the given input with spaces in between each CamelCase word. This function will ignore any words
    -- that do not begin with a capital letter. The words `ooc`, `looc`, `afk`, and `url` will be automatically transformed
    -- into uppercase text. This will not capitalize non-ASCII letters due to limitations with Lua's pattern matching.
    -- @realm shared
    -- @string input String to expand
    -- @bool[opt=false] bNoUpperFirst Whether or not to avoid capitalizing the first character. This is useful for lowerCamelCase
    -- @treturn string Expanded CamelCase string
    -- @usage print(ix.util.ExpandCamelCase("HelloWorld"))
    -- > Hello World
    function ix.util.ExpandCamelCase(input, bNoUpperFirst)
        input = bNoUpperFirst and input or input:utf8sub(1, 1):utf8upper() .. input:utf8sub(2)

        -- extra parentheses to select first return value of gsub
        return string.TrimRight((input:gsub("%u%l+", function(word)
            if (upperMap[word:utf8lower()]) then
                word = word:utf8upper()
            end

            return word .. " "
        end)))
    end
end

function ix.util.GridVector(vec, gridSize)
    if (gridSize <= 0) then
        gridSize = 1
    end

    for i = 1, 3 do
        vec[i] = vec[i] / gridSize
        vec[i] = math.Round(vec[i])
        vec[i] = vec[i] * gridSize
    end

    return vec
end

do
    local i
    local value
    local character

    local function iterator(table)
        repeat
            i = i + 1
            value = table[i]
            character = value and value:GetCharacter()
        until character or value == nil

        return value, character
    end

    --- Returns an iterator for characters. The resulting key/values will be a player and their corresponding characters. This
    -- iterator skips over any players that do not have a valid character loaded.
    -- @realm shared
    -- @treturn Iterator
    -- @usage for client, character in ix.util.GetCharacters() do
    --     print(client, character)
    -- end
    -- > Player [1][Bot01]    character[1]
    -- > Player [2][Bot02]    character[2]
    -- -- etc.
    function ix.util.GetCharacters()
        i = 0
        return iterator, player.GetAll()
    end
end

if (CLIENT) then
    local blur = ix.util.GetMaterial("pp/blurscreen")
    local surface = surface
    local render = render

    --- Blurs the content underneath the given panel. This will fall back to a simple darkened rectangle if the player has
    -- blurring disabled.
    -- @realm client
    -- @tparam panel panel Panel to draw the blur for
    -- @number[opt=5] amount Intensity of the blur. This should be kept between 0 and 10 for performance reasons
    -- @number[opt=0.2] passes Quality of the blur. This should be kept as default
    -- @number[opt=255] alpha Opacity of the blur
    -- @usage function PANEL:Paint(width, height)
    --     ix.util.DrawBlur(self)
    -- end
    function ix.util.DrawBlur(panel, amount, passes, alpha)
        amount = amount or 5

        if (ix.option.Get("cheapBlur", false)) then
            surface.SetDrawColor(50, 50, 50, alpha or (amount * 20))
            surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
        else
            surface.SetMaterial(blur)
            surface.SetDrawColor(255, 255, 255, alpha or 255)

            local x, y = panel:LocalToScreen(0, 0)

            for i = -(passes or 0.2), 1, 0.2 do
                -- Do things to the blur material to make it blurry.
                blur:SetFloat("$blur", i * amount)
                blur:Recompute()

                -- Draw the blur material over the screen.
                render.UpdateScreenEffectTexture()
                surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
            end
        end
    end

    --- Draws a more performant blur on the given panel. This should be used for things like an extra-ordinay amount of panels
    -- that need to be blurred. This will fall back to a simple darkened rectangle if the player has blurring disabled.
    -- @realm client
    -- @tparam panel panel Panel to draw the blur for
    -- @number[opt=5] amount Intensity of the blur. This should be kept between 0 and 10 for performance reasons
    -- @number[opt=255] alpha Opacity of the blur
    -- @usage function PANEL:Paint(width, height)
    --     ix.util.DrawPerformantBlur(self)
    -- end
    function ix.util.DrawPerformantBlur(panel, alpha)
        if (ix.option.Get("cheapBlur", false)) then
            surface.SetDrawColor(50, 50, 50, alpha or 200)
            surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
        else
            surface.SetMaterial(blur)
            surface.SetDrawColor(255, 255, 255, alpha or 255)

            local x, y = panel:LocalToScreen(0, 0)

            for i = 0.33, 1, 0.33 do
                blur:SetFloat("$blur", i)
                blur:Recompute()

                render.UpdateScreenEffectTexture()
                surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
            end
        end
    end

    --- Draws a blurred rectangle with the given position and bounds. This shouldn't be used for panels, see `ix.util.DrawBlur`
    -- instead.
    -- @realm client
    -- @number x X-position of the rectangle
    -- @number y Y-position of the rectangle
    -- @number width Width of the rectangle
    -- @number height Height of the rectangle
    -- @number[opt=5] amount Intensity of the blur. This should be kept between 0 and 10 for performance reasons
    -- @number[opt=0.2] passes Quality of the blur. This should be kept as default
    -- @number[opt=255] alpha Opacity of the blur
    -- @usage hook.Add("HUDPaint", "MyHUDPaint", function()
    --     ix.util.DrawBlurAt(0, 0, ScrW(), ScrH())
    -- end)
    function ix.util.DrawBlurAt(x, y, width, height, amount, passes, alpha)
        amount = amount or 5

        if (ix.option.Get("cheapBlur", false)) then
            surface.SetDrawColor(30, 30, 30, amount * 20)
            surface.DrawRect(x, y, width, height)
        else
            surface.SetMaterial(blur)
            surface.SetDrawColor(255, 255, 255, alpha or 255)

            local scrW, scrH = ScrW(), ScrH()
            local x2, y2 = x / scrW, y / scrH
            local w2, h2 = (x + width) / scrW, (y + height) / scrH

            for i = -(passes or 0.2), 1, 0.2 do
                blur:SetFloat("$blur", i * amount)
                blur:Recompute()

                render.UpdateScreenEffectTexture()
                surface.DrawTexturedRectUV(x, y, width, height, x2, y2, w2, h2)
            end
        end
    end

    --- Pushes a 3D2D blur to be rendered in the world. The draw function will be called next frame in the
    -- `PostDrawOpaqueRenderables` hook.
    -- @realm client
    -- @func drawFunc Function to call when it needs to be drawn
    function ix.util.PushBlur(drawFunc)
        ix.blurRenderQueue[#ix.blurRenderQueue + 1] = drawFunc
    end

    --- Draws some text with a shadow.
    -- @realm client
    -- @string text Text to draw
    -- @number x X-position of the text
    -- @number y Y-position of the text
    -- @color color Color of the text to draw
    -- @number[opt=TEXT_ALIGN_LEFT] alignX Horizontal alignment of the text, using one of the `TEXT_ALIGN_*` constants
    -- @number[opt=TEXT_ALIGN_LEFT] alignY Vertical alignment of the text, using one of the `TEXT_ALIGN_*` constants
    -- @string[opt="ixGenericFont"] font Font to use for the text
    -- @number[opt=color.a * 0.575] alpha Alpha of the shadow
    function ix.util.DrawText(text, x, y, color, alignX, alignY, font, alpha)
        color = color or color_white

        return draw.TextShadow({
            text = text,
            font = font or "ixGenericFont",
            pos = {x, y},
            color = color,
            xalign = alignX or TEXT_ALIGN_LEFT,
            yalign = alignY or TEXT_ALIGN_LEFT
        }, 1, alpha or (color.a * 0.575))
    end

    --- Wraps text so it does not pass a certain width. This function will try and break lines between words if it can,
    -- otherwise it will break a word if it's too long.
    -- @realm client
    -- @string text Text to wrap
    -- @number maxWidth Maximum allowed width in pixels
    -- @string[opt="ixChatFont"] font Font to use for the text
    function ix.util.WrapText(text, maxWidth, font)
        font = font or "ixChatFont"
        surface.SetFont(font)

        local words = string.Explode("%s", text, true)
        local lines = {}
        local line = ""
        local lineWidth = 0 -- luacheck: ignore 231

        -- we don't need to calculate wrapping if we're under the max width
        if (surface.GetTextSize(text) <= maxWidth) then
            return {text}
        end

        for i = 1, #words do
            local word = words[i]
            local wordWidth = surface.GetTextSize(word)

            -- this word is very long so we have to split it by character
            if (wordWidth > maxWidth) then
                local newWidth

                for i2 = 1, word:utf8len() do
                    local character = word[i2]
                    newWidth = surface.GetTextSize(line .. character)

                    -- if current line + next character is too wide, we'll shove the next character onto the next line
                    if (newWidth > maxWidth) then
                        lines[#lines + 1] = line
                        line = ""
                    end

                    line = line .. character
                end

                lineWidth = newWidth
                continue
            end

            local space = (i == 1) and "" or " "
            local newLine = line .. space .. word
            local newWidth = surface.GetTextSize(newLine)

            if (newWidth > maxWidth) then
                -- adding this word will bring us over the max width
                lines[#lines + 1] = line

                line = word
                lineWidth = wordWidth
            else
                -- otherwise we tack on the new word and continue
                line = newLine
                lineWidth = newWidth
            end
        end

        if (line != "") then
            lines[#lines + 1] = line
        end

        return lines
    end

    local cos, sin, abs, rad1, log, pow = math.cos, math.sin, math.abs, math.rad, math.log, math.pow

    -- arc drawing functions
    -- by bobbleheadbob
    -- https://facepunch.com/showthread.php?t=1558060
    function ix.util.DrawArc(cx, cy, radius, thickness, startang, endang, roughness, color)
        surface.SetDrawColor(color)
        ix.util.DrawPrecachedArc(ix.util.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness))
    end

    function ix.util.DrawPrecachedArc(arc) -- Draw a premade arc.
        for _, v in ipairs(arc) do
            surface.DrawPoly(v)
        end
    end

    function ix.util.PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
        local quadarc = {}

        -- Correct start/end ang
        startang = startang or 0
        endang = endang or 0

        -- Define step
        -- roughness = roughness or 1
        local diff = abs(startang - endang)
        local smoothness = log(diff, 2) / 2
        local step = diff / (pow(2, smoothness))

        if startang > endang then
            step = abs(step) * -1
        end

        -- Create the inner circle's points.
        local inner = {}
        local outer = {}
        local ct = 1
        local r = radius - thickness

        for deg = startang, endang, step do
            local rad = rad1(deg)
            local cosrad, sinrad = cos(rad), sin(rad) --calculate sin, cos

            local ox, oy = cx + (cosrad * r), cy + (-sinrad * r) --apply to inner distance
            inner[ct] = {
                x = ox,
                y = oy,
                u = (ox - cx) / radius + .5,
                v = (oy - cy) / radius + .5
            }

            local ox2, oy2 = cx + (cosrad * radius), cy + (-sinrad * radius) --apply to outer distance
            outer[ct] = {
                x = ox2,
                y = oy2,
                u = (ox2 - cx) / radius + .5,
                v = (oy2 - cy) / radius + .5
            }

            ct = ct + 1
        end

        -- QUAD the points.
        for tri = 1, ct do
            local p1, p2, p3, p4
            local t = tri + 1
            p1 = outer[tri]
            p2 = outer[t]
            p3 = inner[t]
            p4 = inner[tri]

            quadarc[tri] = {p1, p2, p3, p4}
        end

        -- Return a table of triangles to draw.
        return quadarc
    end

    --- Resets all stencil values to known good (i.e defaults)
    -- @realm client
    function ix.util.ResetStencilValues()
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
    end

    -- luacheck: globals derma
    -- Alternative to SkinHook that allows you to pass more arguments to skin methods
    function derma.SkinFunc(name, panel, a, b, c, d, e, f, g)
        local skin = (ispanel(panel) and IsValid(panel)) and panel:GetSkin() or derma.GetDefaultSkin()

        if (!skin) then return end

        local func = skin[name]

        if (!func) then return end

        return func(skin, panel, a, b, c, d, e, f, g)
    end

    -- Alternative to Color that retrieves from the SKIN.Colours table
    function derma.GetColor(name, panel, default)
        default = default or ix.config.Get("color")

        local skin = panel.GetSkin and panel:GetSkin() or derma.GetDefaultSkin()
        if (!skin) then
            return default
        end

        return skin.Colours[name] or default
    end


    hook.Add("OnScreenSizeChanged", "ix.OnScreenSizeChanged", function(oldWidth, oldHeight)
        hook.Run("ScreenResolutionChanged", oldWidth, oldHeight)
    end)
end

-- luacheck: globals FCAP_IMPULSE_USE FCAP_CONTINUOUS_USE FCAP_ONOFF_USE
-- luacheck: globals FCAP_DIRECTIONAL_USE FCAP_USE_ONGROUND FCAP_USE_IN_RADIUS
FCAP_IMPULSE_USE = 0x00000010
FCAP_CONTINUOUS_USE = 0x00000020
FCAP_ONOFF_USE = 0x00000040
FCAP_DIRECTIONAL_USE = 0x00000080
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200

function ix.util.IsUseableEntity(entity, requiredCaps)
    if (IsValid(entity)) then
        local caps = entity:ObjectCaps()

        if (bit.band(caps, bit.bor(FCAP_IMPULSE_USE, FCAP_CONTINUOUS_USE, FCAP_ONOFF_USE, FCAP_DIRECTIONAL_USE))) then
            if (bit.band(caps, requiredCaps) == requiredCaps) then
                return true
            end
        end
    end
end

do
    local function IntervalDistance(x, x0, x1)
        -- swap so x0 < x1
        if (x0 > x1) then
            local tmp = x0

            x0 = x1
            x1 = tmp
        end

        if (x < x0) then
            return x0-x
        elseif (x > x1) then
            return x - x1
        end

        return 0
    end

    local NUM_TANGENTS = 8
    local tangents = {0, 1, 0.57735026919, 0.3639702342, 0.267949192431, 0.1763269807, -0.1763269807, -0.267949192431}
    local traceMin = Vector(-16, -16, -16)
    local traceMax = Vector(16, 16, 16)

    function ix.util.FindUseEntity(player, origin, forward)
        local tr
        local up = forward:Up()
        -- Search for objects in a sphere (tests for entities that are not solid, yet still useable)
        local searchCenter = origin

        -- NOTE: Some debris objects are useable too, so hit those as well
        -- A button, etc. can be made out of clip brushes, make sure it's +useable via a traceline, too.
        local useableContents = bit.bor(MASK_SOLID, CONTENTS_DEBRIS, CONTENTS_PLAYERCLIP)

        -- UNDONE: Might be faster to just fold this range into the sphere query
        local pObject

        local nearestDist = 1e37
        -- try the hit entity if there is one, or the ground entity if there isn't.
        local pNearest = NULL

        for i = 1, NUM_TANGENTS do
            if (i == 0) then
                tr = util.TraceLine({
                    start = searchCenter,
                    endpos = searchCenter + forward * 1024,
                    mask = useableContents,
                    filter = player
                })

                tr.EndPos = searchCenter + forward * 1024
            else
                local down = forward - tangents[i] * up
                down:Normalize()

                tr = util.TraceHull({
                    start = searchCenter,
                    endpos = searchCenter + down * 72,
                    mins = traceMin,
                    maxs = traceMax,
                    mask = useableContents,
                    filter = player
                })

                tr.EndPos = searchCenter + down * 72
            end

            pObject = tr.Entity

            local bUsable = ix.util.IsUseableEntity(pObject, 0)

            while (IsValid(pObject) and !bUsable and pObject:GetMoveParent()) do
                pObject = pObject:GetMoveParent()
                bUsable = ix.util.IsUseableEntity(pObject, 0)
            end

            if (bUsable) then
                local delta = tr.EndPos - tr.StartPos
                local centerZ = origin.z - player:WorldSpaceCenter().z
                delta.z = IntervalDistance(tr.EndPos.z, centerZ - player:OBBMins().z, centerZ + player:OBBMaxs().z)
                local dist = delta:Length()

                if (dist < 80) then
                    pNearest = pObject

                    -- if this is directly under the cursor just return it now
                    if (i == 0) then
                        return pObject
                    end
                end
            end
        end

        -- check ground entity first
        -- if you've got a useable ground entity, then shrink the cone of this search to 45 degrees
        -- otherwise, search out in a 90 degree cone (hemisphere)
        if (IsValid(player:GetGroundEntity()) and ix.util.IsUseableEntity(player:GetGroundEntity(), FCAP_USE_ONGROUND)) then
            pNearest = player:GetGroundEntity()
        end

        if (IsValid(pNearest)) then
            -- estimate nearest object by distance from the view vector
            local point = pNearest:NearestPoint(searchCenter)
            nearestDist = util.DistanceToLine(searchCenter, forward, point)
        end

        for _, v in ipairs(ents.FindInSphere(searchCenter, 80)) do
            if (!ix.util.IsUseableEntity(v, FCAP_USE_IN_RADIUS)) then continue end

            -- see if it's more roughly in front of the player than previous guess
            local point = v:NearestPoint(searchCenter)

            local dir = point - searchCenter
            dir:Normalize()
            local dot = dir:Dot(forward)

            -- Need to be looking at the object more or less
            if (dot < 0.8) then continue end

            local dist = util.DistanceToLine(searchCenter, forward, point)

            if (dist < nearestDist) then
                -- Since this has purely been a radius search to this point, we now
                -- make sure the object isn't behind glass or a grate.
                local trCheckOccluded = {}

                util.TraceLine({
                    start = searchCenter,
                    endpos = point,
                    mask = useableContents,
                    filter = player,
                    output = trCheckOccluded
                })

                if (trCheckOccluded.fraction == 1.0 or trCheckOccluded.Entity == v) then
                    pNearest = v
                    nearestDist = dist
                end
            end
        end

        return pNearest
    end
end

ALWAYS_RAISED = {}
ALWAYS_RAISED["weapon_physgun"] = true
ALWAYS_RAISED["gmod_tool"] = true
ALWAYS_RAISED["ix_poshelper"] = true

function ix.util.FindEmptySpace(variable, filter, spacing, size, height, tolerance)
    filter = filter or {}
    spacing = spacing or 32
    size = size or 3
    height = height or 36
    tolerance = tolerance or 5

    local position = isvector(variable) and variable or isentity(variable) and variable:GetPos()
    if (!position) then return end

    local mins, maxs = Vector(-spacing * 0.5, -spacing * 0.5, 0), Vector(spacing * 0.5, spacing * 0.5, height)
    local output = {}

    for x = -size, size do
        for y = -size, size do
            local origin = position + Vector(x * spacing, y * spacing, 0)

            local data = {}
                data.start = origin + mins + Vector(0, 0, tolerance)
                data.endpos = origin + maxs
                data.filter = filter or isentity(variable) and variable or {}
            local trace = util.TraceLine(data)

            data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
            data.endpos = origin + Vector(mins.x, mins.y, height)

            local trace2 = util.TraceLine(data)

            if (trace.StartSolid or trace.Hit or trace2.StartSolid or trace2.Hit or !util.IsInWorld(origin)) then continue end

            output[#output + 1] = origin
        end
    end

    table.sort(output, function(a, b)
        return a:DistToSqr(position) < b:DistToSqr(position)
    end)

    return output
end

-- Time related stuff.
do
    --- Gets the current time in the UTC time-zone.
    -- @realm shared
    -- @treturn number Current time in UTC
    function ix.util.GetUTCTime()
        local date = os.date("!*t")
        local localDate = os.date("*t")
        localDate.isdst = false

        return os.difftime(os.time(date), os.time(localDate))
    end

    -- Setup for time strings.
    local TIME_UNITS = {}
    TIME_UNITS["s"] = 1                        -- Seconds
    TIME_UNITS["m"] = 60                    -- Minutes
    TIME_UNITS["h"] = 3600                    -- Hours
    TIME_UNITS["d"] = TIME_UNITS["h"] * 24    -- Days
    TIME_UNITS["w"] = TIME_UNITS["d"] * 7    -- Weeks
    TIME_UNITS["mo"] = TIME_UNITS["d"] * 30    -- Months
    TIME_UNITS["y"] = TIME_UNITS["d"] * 365    -- Years

    --- Gets the amount of seconds from a given formatted string. If no time units are specified, it is assumed minutes.
    -- The valid values are as follows:
    --
    -- - `s` - Seconds
    -- - `m` - Minutes
    -- - `h` - Hours
    -- - `d` - Days
    -- - `w` - Weeks
    -- - `mo` - Months
    -- - `y` - Years
    -- @realm shared
    -- @string text Text to interpret a length of time from
    -- @treturn[1] number Amount of seconds from the length interpreted from the given string
    -- @treturn[2] 0 If the given string does not have a valid time
    -- @usage print(ix.util.GetStringTime("5y2d7w"))
    -- > 162086400 -- 5 years, 2 days, 7 weeks
    function ix.util.GetStringTime(text)
        local minutes = tonumber(text)

        if (minutes) then
            return math.abs(minutes * 60)
        end

        local time = 0

        for amount, unit in text:lower():gmatch("(%d+)(%a+)") do
            amount = tonumber(amount)

            if (amount and TIME_UNITS[unit]) then
                time = time + math.abs(amount * TIME_UNITS[unit])
            end
        end

        return time
    end
end

--[[
    Credit to TFA for figuring this mess out.
    Original: https://steamcommunity.com/sharedfiles/filedetails/?id=903541818
]]

if (system.IsLinux()) then
    local cache = {}

    -- Helper Functions
    local function GetSoundPath(path, gamedir)
        if (!gamedir) then
            path = "sound/" .. path
            gamedir = "GAME"
        end

        return path, gamedir
    end

    local function f_IsWAV(f)
        f:Seek(8)

        return f:Read(4) == "WAVE"
    end

    -- WAV functions
    local function f_SampleDepth(f)
        f:Seek(34)
        local bytes = {}

        for i = 1, 2 do
            bytes[i] = f:ReadByte(1)
        end

        local num = bit.lshift(bytes[2], 8) + bit.lshift(bytes[1], 0)

        return num
    end

    local function f_SampleRate(f)
        f:Seek(24)
        local bytes = {}

        for i = 1, 4 do
            bytes[i] = f:ReadByte(1)
        end

        local num = bit.lshift(bytes[4], 24) + bit.lshift(bytes[3], 16) + bit.lshift(bytes[2], 8) + bit.lshift(bytes[1], 0)

        return num
    end

    local function f_Channels(f)
        f:Seek(22)
        local bytes = {}

        for i = 1, 2 do
            bytes[i] = f:ReadByte(1)
        end

        local num = bit.lshift(bytes[2], 8) + bit.lshift(bytes[1], 0)

        return num
    end

    local function f_Duration(f)
        return (f:Size() - 44) / (f_SampleDepth(f) / 8 * f_SampleRate(f) * f_Channels(f))
    end

    ixSoundDuration = ixSoundDuration or SoundDuration -- luacheck: globals ixSoundDuration

    function SoundDuration(str) -- luacheck: globals SoundDuration
        local path, gamedir = GetSoundPath(str)
        local f = file.Open(path, "rb", gamedir)

        if (!f) then return 0 end --Return nil on invalid files

        local ret

        if (cache[str]) then
            ret = cache[str]
        elseif (f_IsWAV(f)) then
            ret = f_Duration(f)
        else
            ret = ixSoundDuration(str)
        end

        f:Close()

        return ret
    end
end

local ADJUST_SOUND = SoundDuration("npc/metropolice/pain1.wav") > 0 and "" or "../../hl2/sound/"

--- Emits sounds one after the other from an entity.
-- @realm shared
-- @entity entity Entity to play sounds from
-- @tab sounds Sound paths to play
-- @number delay[opt=0] How long to wait before starting to play the sounds
-- @number spacing[opt=0.1] How long to wait between playing each sound
-- @number level[opt=75] The sound level of each sound
-- @number pitch[opt=100] Pitch percentage of each sound
-- @number volume[opt=1] Volume of each sound
-- @number channel[opt=CHAN_AUTO] Channel of each sound
-- @treturn number How long the entire sequence of sounds will take to play
-- @usage -- Play a sequence of sounds with a delay between each sound
-- ix.util.EmitQueuedSounds(entity, {"sound1.wav", "sound2.wav", "sound3.wav"}, 0.5, 0.1, 75, 100, 1, CHAN_AUTO)
function ix.util.EmitQueuedSounds(entity, sounds, delay, spacing, level, pitch, volume, channel)
    -- Let there be a delay before any sound is played.
    delay = delay or 0
    spacing = spacing or 0.1

    -- Loop through all of the sounds.
    for _, v in ipairs(sounds) do
        local postSet, preSet = 0, 0

        -- Determine if this sound has special time offsets.
        if (istable(v)) then
            postSet, preSet = v[2] or 0, v[3] or 0
            v = v[1]
        end

        -- Get the length of the sound.
        local length = SoundDuration(ADJUST_SOUND..v)
        -- If the sound has a pause before it is played, add it here.
        delay = delay + preSet

        -- Have the sound play in the future.
        timer.Simple(delay, function()
            -- Check if the entity still exists and play the sound.
            if (IsValid(entity)) then
                entity:EmitSound(v, level, pitch)
            end
        end)

        -- Add the delay for the next sound.
        delay = delay + length + postSet + spacing
    end

    -- Return how long it took for the whole thing.
    return delay
end

--- Merges the contents of the second table with the content in the first one. The destination table will be modified.
--- If element is table but not metatable object, value's elements will be changed only.
-- @realm shared
-- @tab destination The table you want the source table to merge with
-- @tab source The table you want to merge with the destination table
-- @return table
function ix.util.MetatableSafeTableMerge(destination, source)
    for k, v in pairs(source) do
        if (istable(v) and istable(destination[k]) and getmetatable(v) == nil) then
            -- don't overwrite one table with another
            -- instead merge them recurisvely
            ix.util.MetatableSafeTableMerge(destination[k], v);
        else
            destination[ k ] = v;
        end
    end
    return destination;
end

--- Returns a string that has the first letter capitalized.
-- @realm shared
-- @string str String to capitalize
-- @treturn string Capitalized string
-- @usage print(ix.util.CapitalizeFirst("hello"))
-- > Hello
function ix.util.CapitalizeFirst(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

--- Returns a formatted time string from a given amount of seconds. Useful for displaying 24-hour time.
-- @realm shared
-- @number time Amount of seconds
-- @treturn string Formatted time string
-- @usage print(ix.util.GetFormattedTime(3600))
-- > 01:00
function ix.util.GetTimeText(time)
    local minutes = math.floor(time / 60)
    local seconds = time % 60

    return string.format("%02d:%02d", minutes, seconds)
end

--- Returns a number with a certain amount of digits.
-- @realm shared
-- @number number Number to pad
-- @number digits Amount of digits to pad to
-- @treturn string Padded number
-- @usage print(ix.util.ZeroNumber(5, 3))
-- > 005
function ix.util.ZeroNumber(number, digits)
    local str = tostring(number)

    return string.rep("0", digits - #str) .. str
end

--- Trims a text to a certain length, adding an ending if it's too long.
-- @realm shared
-- @string text Text to trim
-- @number length Maximum length of the text
-- @string[opt="..."] ending Ending to add if the text is too long
-- @treturn string Trimmed text
-- @usage print(ix.util.TrimText("Hello, world!", 5))
-- > Hello...
function ix.util.TrimText(text, length, ending)
    if ( string.len(text) > length ) then
        return text:sub(1, length) .. ( ending or "..." )
    end

    return text
end

--- Converts a color table to a vector.
-- @realm shared
-- @color color Color table to convert
-- @treturn Vector Converted color table
-- @usage print(ix.util.ColorToVector(Color(255, 255, 255)))
-- > 1, 1, 1
function ix.util.ColorToVector(color)
    return Vector(color.r / 255, color.g / 255, color.b / 255)
end

--- Converts a color table to a hex color.
-- @realm shared
-- @color color Color table to convert
-- @treturn string Hex color
-- @usage print(ix.util.ColorToHex(Color(255, 255, 255)))
-- > #FFFFFF
function ix.util.ColorToHex(color)
    return string.format("#%02X%02X%02X", color.r, color.g, color.b)
end

--- Converts a color table to a vector.
-- @realm shared
-- @vector vector Vector table to convert
-- @treturn Color Converted vector table
-- @usage print(ix.util.VectorToColor(Vector(1, 1, 1)))
-- > 255, 255, 255
function ix.util.VectorToColor(vector)
    return Color(vector.x * 255, vector.y * 255, vector.z * 255)
end

--- Converts a hex color to a color table.
-- @realm shared
-- @string hex Hex color to convert
-- @treturn Color Converted hex color
-- @usage print(ix.util.HexToColor("#FFFFFF"))
-- > 255, 255, 255
function ix.util.HexToColor(hex)
    hex = hex:gsub("#", "")

    return Color(tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)))
end

--- Finds a target in the player's crosshair, with an optional range.
-- @realm shared
-- @player client Player to find the target for
-- @entity target Target entity to check
-- @number[opt=0.9] range Range to check for the target
-- @treturn bool Whether or not the target is in the player's crosshair
-- @usage -- returns true if Entity(2) is in Entity(1)'s crosshair
-- print(ix.util.FindInCrosshair(Entity(1), Entity(2)))
-- > true
-- @usage -- returns true if Entity(2) is in Entity(1)'s crosshair within 0.5 range
-- print(ix.util.FindInCrosshair(Entity(1), Entity(2), 0.5))
-- > true
-- @usage -- returns false if Entity(2) is not in Entity(1)'s crosshair within 0.1 range
-- print(ix.util.FindInCrosshair(Entity(1), Entity(2), 0.1))
-- > false
function ix.util.FindInCrosshair(client, target, range)
    if ( !IsValid(client) and !IsValid(target) ) then return end

    if ( !IsValid(target) ) then return end

    if ( !range ) then
        range = 0.9
    end

    range = math.Clamp(range, 0, 1)

    local origin, originVector = client:EyePos(), client:GetAimVector()

    local targetOrigin = target.EyePos and target:EyePos() or target:WorldSpaceCenter()
    local direction = targetOrigin - origin

    if ( originVector:Dot(direction:GetNormalized()) > range ) then return true end

    return false
end

--- Checks if a number is below 1 and above 0.
-- @realm shared
-- @number number Number to check
-- @treturn bool Whether or not the number is a decimal
-- @usage print(ix.util.IsDecimal(0.5))
-- > true
-- @usage print(ix.util.IsDecimal(5))
-- > false
function ix.util.IsDecimal(number)
    return number < 1 and number > 0
end

--- Converts a unit to meters.
-- @realm shared
-- @number unit Unit to convert
-- @treturn number Converted unit
-- @usage print(ix.util.UnitToMeters(256))
-- > 6.5024
function ix.util.UnitToMeters(unit)
    return unit * 0.0254
end

--- Converts meters to a unit.
-- @realm shared
-- @number meters Meters to convert
-- @treturn number Converted meters
-- @usage print(ix.util.MetersToUnit(20))
-- > 787.40157480315
function ix.util.MetersToUnit(meters)
    return meters / 0.0254
end

--- Returns the bearing of an angle.
-- @realm shared
-- @Angle ang Angle to get the bearing of
-- @treturn number Bearing of the angle
-- @usage print(ix.util.AngleToBearing(Angle(0, 90, 0)))
-- > 270
function ix.util.AngleToBearing(ang)
    return math.Round(360 - ( ang.y % 360 ))
end

--- @realm shared
function ix.util.GetClosestEntity(pos, distance, entities, bEntitiesIsIgnored)
    local closestEntity
    local closestDistance = distance

    if ( !entities ) then
        entities = {}

        for _, entity in ipairs(ents.FindInSphere(pos, distance)) do
            table.insert(entities, entity)
        end
    elseif ( !bEntitiesIsIgnored ) then
        for _, entity in ipairs(ents.FindInSphere(pos, distance)) do
            if ( table.HasValue(entities, entity) ) then continue end

            table.insert(entities, entity)
        end
    end

    local closestEntities = {}
    for _, entity in ipairs(entities) do
        table.insert(closestEntities, {entity, entity:GetPos():Distance(pos)})
    end

    table.sort(closestEntities, function(a, b)
        return a[2] < b[2]
    end)

    for _, entity in ipairs(closestEntities) do
        if ( entity[2] < closestDistance ) then
            closestEntity = entity[1]
            closestDistance = entity[2]
        end
    end

    return closestEntity, closestDistance, closestEntities
end

if ( CLIENT ) then
    --- Returns the size of a text string.
    -- @realm client
    -- @string text Text to get the size of
    -- @string font[opt="ixGenericFont"] Font to use
    -- @treturn number Width of the text
    -- @treturn number Height of the text
    -- @usage print(ix.util.GetTextSize("Hello, world!"))
    function ix.util.GetTextSize(text, font)
        surface.SetFont(font or "ixGenericFont")
        return surface.GetTextSize(text)
    end

    --- Returns the width of a text string.
    -- @realm client
    -- @string text Text to get the width of
    -- @string font[opt="ixGenericFont"] Font to use
    -- @treturn number Width of the text
    -- @usage print(ix.util.GetTextWidth("Hello, world!"))
    function ix.util.GetTextWidth(text, font)
        surface.SetFont(font or "ixGenericFont")
        return select(1, surface.GetTextSize(text))
    end

    --- Returns the height of a text string.
    -- @realm client
    -- @string text Text to get the height of
    -- @string font[opt="ixGenericFont"] Font to use
    -- @treturn number Height of the text
    -- @usage print(ix.util.GetTextHeight("Hello, world!"))
    function ix.util.GetTextHeight(text, font)
        surface.SetFont(font or "ixGenericFont")
        return select(2, surface.GetTextSize(text))
    end

    --- Returns a boolean indicating whether or not the specified server is down. If no address is provided, the current server is checked.
    -- @realm client
    -- @string address Address of the server
    -- @treturn bool Whether or not the server is down
    -- @usage -- returns true if the server is down
    -- print(ix.util.IsServerDown())
    -- > false
    function ix.util.IsServerDown(address)
        address = address or game.GetIPAddress()

        local bIsDown = false

        http.Fetch("http://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=" .. address, function(json)
            local data = util.JSONToTable(json)
            if ( !data or !data.response or !data.response.servers or !data.response.servers[0] ) then
                bIsDown = true
            end
        end)

        return bIsDown
    end

    local BASE_RES_X, BASE_RES_Y = 1920, 1080 -- Reference resolution

    --- Scales a value based on screen resolution while maintaining aspect ratio.
    -- The scaling function is designed to be dynamic, adapting to different screen sizes.
    -- Larger screens will have a smaller scale factor to maintain UI consistency.
    -- @realm client
    -- @param size The base size to scale
    -- @param useHeight Whether to scale based on height instead of width
    -- @return Scaled size
    function ix.util.ScreenScale(size, useHeight)
        local screenW, screenH = ScrW(), ScrH()
    
        -- Compute scale factors based on an exponential decay to make elements significantly smaller on large screens
        local scaleX = (BASE_RES_X / screenW) ^ 0.85
        local scaleY = (BASE_RES_Y / screenH) ^ 0.85
        
        -- Choose the appropriate scale mode
        local scale = useHeight and scaleY or math.min(scaleX, scaleY)
        
        -- Ensure elements do not disappear and maintain readability
        return math.max(math.floor(size * scale + 0.5), 1)
    end
end

--- Rolls a percentage chance.
-- @realm shared
-- @number chance The percentage chance (1-100).
-- @treturn boolean Returns true if the chance succeeds.
function ix.util.Chance(chance)
    return math.random(100) <= chance
end

--- Picks a random value from a weighted table.
-- @realm shared
-- @tab tbl The table containing values with weights.
-- @treturn any The randomly selected value.
function ix.util.WeightedRandom(tbl)
    local totalWeight = 0

    for _, weight in pairs(tbl) do
        totalWeight = totalWeight + weight
    end

    local randomWeight = math.random() * totalWeight

    for value, weight in pairs(tbl) do
        if (randomWeight < weight) then
            return value
        else
            randomWeight = randomWeight - weight
        end
    end
end

--- Calculates the shortest distance between two angles.
-- @realm shared
-- @number ang1 The first angle.
-- @number ang2 The second angle.
-- @treturn number The shortest distance between the angles.
function ix.util.CircularDistance(ang1, ang2)
    local delta = (ang1 - ang2) % 360
    if (delta > 180) then
        delta = delta - 360
    end
    return delta
end

--- Finds the nearest entity to a given position.
-- @realm server
-- @vector pos The position to search around.
-- @number radius The search radius.
-- @string entClass The entity class to search for.
-- @treturn entity The nearest entity.
function ix.util.FindNearestEntity(pos, radius, entClass)
    local entities = ents.FindInSphere(pos, radius)
    local nearestEnt = nil
    local nearestDist = math.huge

    table.sort(entities, function(a, b)
        return a:GetPos():Distance(pos) < b:GetPos():Distance(pos)
    end)

    for _, ent in ipairs(entities) do
        if (ent:GetClass() == entClass) then
            nearestEnt = ent
            break
        end
    end

    return nearestEnt
end

--- Converts seconds into a formatted time string.
-- @realm shared
-- @number time The time in seconds.
-- @treturn string Formatted string in H:MM:SS format.
function ix.util.FormatTime(time)
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = time % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--- Rounds a number to a specific number of decimal places.
-- @realm shared
-- @number num The number to round.
-- @number decimalPlaces The number of decimal places to round to.
-- @treturn number The rounded number.
function ix.util.Round(num, decimalPlaces)
    local mult = 10 ^ decimalPlaces
    return math.Round(num * mult) / mult
end

--- Recursively finds files in a directory and its subdirectories.
-- @realm server
-- @string dir The directory to search.
-- @treturn table A table of file paths.
function ix.util.FindFilesRecursive(dir)
    local files, dirs = file.Find(dir.."/*", "GAME")
    local results = {}

    for _, f in ipairs(files) do
        table.insert(results, dir.."/"..f)
    end

    for _, d in ipairs(dirs) do
        local subFiles = ix.util.FindFilesRecursive(dir.."/"..d)
        for _, f in ipairs(subFiles) do
            table.insert(results, f)
        end
    end

    return results
end

--- Searches through the game's mounted content for the given model.
-- @realm shared
-- @string model The model to search for.
-- @treturn bool Whether or not the model is valid.
-- @usage print(ix.util.IsValidModel("models/props_c17/oildrum001.mdl"))
-- > true
function ix.util.IsValidModel(model)
    local files, directories = file.Find("models/*", "GAME")

    for _, found in ipairs(files) do
        if ( ix.util.StringMatches(found, model) ) then
            return true
        end
    end

    for _, directory in ipairs(directories) do
        local files = file.Find("models/" .. directory .. "/*", "GAME")

        for _, found in ipairs(files) do
            if ( ix.util.StringMatches(found, model) ) then
                return true
            end
        end
    end

    return false
end

local color_fallback = Color(115, 53, 142)
function ix.util.Log(...)
    local comp = {...}
    table.insert(comp, "\n")
    MsgC(color_fallback, "[Helix] ", unpack(comp))
end

ix.util.Include("helix/gamemode/core/meta/sh_entity.lua")
ix.util.Include("helix/gamemode/core/meta/sh_player.lua")
