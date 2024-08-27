
local PLUGIN = PLUGIN

PLUGIN.name = "Map Scenes"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds areas of the map that are visible during character selection."
PLUGIN.scenes = PLUGIN.scenes or {}

local x3, y3 = 0, 0
local realOrigin = Vector(0, 0, 0)
local realAngles = Angle(0, 0, 0)
local view = {}

ix.config.Add("mapSceneFOV", 90, "The field of view for the map scene.", nil, {
    data = {decimals = 0, min = 0, max = 180},
    category = "Map Scenes"
})

ix.config.Add("mapSceneSmooth", 100, "How smooth the camera should move between scenes.", nil, {
    data = {decimals = 0, min = 0, max = 100},
    category = "Map Scenes"
})

ix.config.Add("mapSceneTime", 30, "How long it should take to transition between scenes.", nil, {
    data = {decimals = 0, min = 0, max = 180},
    category = "Map Scenes"
})

ix.config.Add("mapSceneLinear", false, "Should the camera move in a more smooth or linear fashion? If true, the camera will move in a more linear fashion.", nil, {
    category = "Map Scenes"
})

ix.config.Add("mapSceneMouseInput", true, "Should the camera also move based on mouse input?", nil, {
    category = "Map Scenes"
})

local function Approach(fraction, start, finish)
    fraction = fraction * ix.config.Get("mapSceneSmooth", 100) * 0.01
    
    if (ix.config.Get("mapSceneLinear", false)) then
        return math.Approach(start, finish, fraction * math.abs(finish - start))
    else
        return Lerp(fraction, start, finish)
    end
end

local function ApproachVector(fraction, start, finish)
    return Vector(Approach(fraction, start.x, finish.x), Approach(fraction, start.y, finish.y), Approach(fraction, start.z, finish.z))
end

local function ApproachAngle(fraction, start, finish)
    return Angle(Approach(fraction, start.p, finish.p), Approach(fraction, start.y, finish.y), Approach(fraction, start.r, finish.r))
end

if (CLIENT) then
    PLUGIN.ordered = PLUGIN.ordered or {}
    PLUGIN.startTime = 0
    PLUGIN.finishTime = 0

    function PLUGIN:ShouldRenderMapScene()
    end

    local function ShouldRenderMapScene()
        if ( !IsValid(ix.gui.characterMenu) ) then
            return false
        end

        if ( IsValid(ix.gui.characterMenu) and ix.gui.characterMenu:IsClosing() ) then
            return false
        end

        if ( table.IsEmpty(PLUGIN.scenes) ) then
            return false
        end

        local can = hook.Run("ShouldRenderMapScene")
        if (can == false) then
            return false
        end

        return true
    end

    function PLUGIN:CalcView(client, origin, angles, fov)
        local scenes = self.scenes

        if (ShouldRenderMapScene()) then
            local key = self.index
            local value = scenes[self.index]

            if (!self.index or !value) then
                value, key = table.Random(scenes)
                self.index = key
            end

            if (self.orderedIndex or value.origin or isvector(key)) then
                local curTime = CurTime()

                self.orderedIndex = self.orderedIndex or 1

                local ordered = self.ordered[self.orderedIndex]

                if (ordered) then
                    key = ordered[1]
                    value = ordered[2]
                end

                if (!self.startTime) then
                    self.startTime = curTime
                    self.finishTime = curTime + ix.config.Get("mapSceneTime", 30)
                end

                local fraction = math.min(math.TimeFraction(self.startTime, self.finishTime, CurTime()), 1)

                if (value) then
                    realOrigin = ApproachVector(fraction, key, value[1])
                    realAngles = ApproachAngle(fraction, value[2], value[3])
                end

                if (fraction >= 1) then
                    self.startTime = curTime
                    self.finishTime = curTime + ix.config.Get("mapSceneTime", 30)

                    -- Reset PVS, we're moving to a new scene.
                    client.ixMapSceneSentPVS = false

                    if (ordered) then
                        self.orderedIndex = self.orderedIndex + 1

                        if (self.orderedIndex > #self.ordered) then
                            self.orderedIndex = 1
                        end
                    else
                        local keys = {}

                        for k, _ in pairs(scenes) do
                            if (isvector(k)) then
                                keys[#keys + 1] = k
                            end
                        end

                        self.index = table.Random(keys)
                    end
                end
            elseif (value) then
                realOrigin = value[1]
                realAngles = value[2]
            end

            local x, y = gui.MousePos()
            local x2, y2 = surface.ScreenWidth() * 0.5, surface.ScreenHeight() * 0.5
            local frameTime = FrameTime() * 0.5

            if (!ix.config.Get("mapSceneMouseInput", true)) then
                x, y = 0, 0
            end

            y3 = Approach(frameTime, y3, math.Clamp((y - y2) / y2, -1, 1) * -6)
            x3 = Approach(frameTime, x3, math.Clamp((x - x2) / x2, -1, 1) * 6)

            view.origin = realOrigin + realAngles:Up()*y3 + realAngles:Right()*x3
            view.angles = realAngles + Angle(y3 * -0.5, x3 * -0.5, 0)

            -- Send the PVS to the server if it's not already sent.
            if (client.ixMapSceneSentPVS != true) then
                net.Start("ixMapScenePVS")
                    net.WriteVector(realOrigin)
                net.SendToServer()

                client.ixMapSceneSentPVS = true
            end

            view.fov = ix.config.Get("mapSceneFOV", 90)

            return view
        else
            -- Reset PVS, we're not in the character menu.
            if (client.ixMapSceneSentPVS != false) then
                net.Start("ixMapScenePVS")
                net.SendToServer()

                client.ixMapSceneSentPVS = false
            end
        end
    end

    function PLUGIN:PreDrawViewModel(viewModel, client, weapon)
        if (IsValid(ix.gui.characterMenu) and !ix.gui.characterMenu:IsClosing()) then
            return true
        end
    end

    net.Receive("ixMapSceneAdd", function()
        local data = net.ReadTable()

        PLUGIN.scenes[#PLUGIN.scenes + 1] = data
    end)

    net.Receive("ixMapSceneRemove", function()
        local index = net.ReadUInt(16)

        PLUGIN.scenes[index] = nil
    end)

    net.Receive("ixMapSceneAddPair", function()
        local data = net.ReadTable()
        local origin = net.ReadVector()

        PLUGIN.scenes[origin] = data

        table.insert(PLUGIN.ordered, {origin, data})
    end)

    net.Receive("ixMapSceneRemovePair", function()
        local key = net.ReadVector()

        PLUGIN.scenes[key] = nil

        for k, v in ipairs(PLUGIN.ordered) do
            if (v[1] == key) then
                table.remove(PLUGIN.ordered, k)

                break
            end
        end
    end)

    net.Receive("ixMapSceneSync", function()
        local length = net.ReadUInt(32)
        local data = net.ReadData(length)
        local uncompressed = util.Decompress(data)

        if (!uncompressed) then
            ErrorNoHalt("[Helix] Unable to decompress map scene data!\n")
            return
        end

        -- Set the list of texts to the ones provided by the server.
        PLUGIN.scenes = util.JSONToTable(uncompressed)

        for k, v in pairs(PLUGIN.scenes) do
            if (v.origin or isvector(k)) then
                table.insert(PLUGIN.ordered, {v.origin and v.origin or k, v})
            end
        end
    end)
else
    util.AddNetworkString("ixMapSceneSync")
    util.AddNetworkString("ixMapSceneAdd")
    util.AddNetworkString("ixMapSceneRemove")

    util.AddNetworkString("ixMapSceneAddPair")
    util.AddNetworkString("ixMapSceneRemovePair")

    util.AddNetworkString("ixMapScenePVS")

    net.Receive("ixMapScenePVS", function(_, client)
        local origin = net.ReadVector()
        client.ixMapSceneOrigin = origin
    end)

    function PLUGIN:SaveScenes()
        self:SetData(self.scenes)

        local json = util.TableToJSON(self.scenes)
        local compressed = util.Compress(json)
        local length = compressed:len()

        net.Start("ixMapSceneSync")
            net.WriteUInt(length, 32)
            net.WriteData(compressed, length)
        net.Broadcast()
    end

    function PLUGIN:LoadData()
        self.scenes = self:GetData() or {}
    end

    function PLUGIN:PlayerInitialSpawn(client)
        local json = util.TableToJSON(self.scenes)
        local compressed = util.Compress(json)
        local length = compressed:len()

        net.Start("ixMapSceneSync")
            net.WriteUInt(length, 32)
            net.WriteData(compressed, length)
        net.Send(client)
    end

    function PLUGIN:AddScene(position, angles, position2, angles2)
        local data

        if (position2) then
            data = {origin=position, position2, angles, angles2}
            self.scenes[#self.scenes + 1] = data

            net.Start("ixMapSceneAddPair")
                net.WriteTable(data)
                net.WriteVector(position)
            net.Broadcast()
        else
            data = {position, angles}
            self.scenes[#self.scenes + 1] = data

            net.Start("ixMapSceneAdd")
                net.WriteTable(data)
            net.Broadcast()
        end

        self:SaveScenes()
    end

    function PLUGIN:SetupPlayerVisibility(client, viewEntity)
        local origin = client.ixMapSceneOrigin

        if (origin) then
            AddOriginToPVS(origin)
        end
    end
end

ix.command.Add("MapSceneAdd", {
    description = "@cmdMapSceneAdd",
    privilege = "Manage Map Scenes",
    adminOnly = true,
    arguments = bit.bor(ix.type.bool, ix.type.optional),
    OnRun = function(self, client, bIsPair)
        local position, angles = client:EyePos(), client:EyeAngles()

        -- This scene is in a pair for moving scenes.
        if (tobool(bIsPair) and !client.ixScnPair) then
            client.ixScnPair = {position, angles}

            return "@mapRepeat"
        else
            if (client.ixScnPair) then
                PLUGIN:AddScene(client.ixScnPair[1], client.ixScnPair[2], position, angles)
                client.ixScnPair = nil
            else
                PLUGIN:AddScene(position, angles)
            end

            return "@mapAdd"
        end
    end
})

ix.command.Add("MapSceneRemove", {
    description = "@cmdMapSceneRemove",
    privilege = "Manage Map Scenes",
    adminOnly = true,
    arguments = bit.bor(ix.type.number, ix.type.optional),
    OnRun = function(self, client, radius)
        radius = radius or 280

        local position = client:GetPos()
        local i = 0

        for k, v in pairs(PLUGIN.scenes) do
            local delete = false

            if (isvector(k)) then
                if (k:Distance(position) <= radius or v[1]:Distance(position) <= radius) then
                    delete = true
                end
            elseif (v[1]:Distance(position) <= radius) then
                delete = true
            end

            if (delete) then
                if (isvector(k)) then
                    net.Start("ixMapSceneRemovePair")
                        net.WriteVector(k)
                    net.Broadcast()
                else
                    net.Start("ixMapSceneRemove")
                        net.WriteString(k)
                    net.Broadcast()
                end

                PLUGIN.scenes[k] = nil

                i = i + 1
            end
        end

        if (i > 0) then
            PLUGIN:SaveScenes()
        end

        return "@mapDel", i
    end
})

MAPSCENE = PLUGIN