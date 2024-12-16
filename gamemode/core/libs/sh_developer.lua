CAMI.RegisterPrivilege({
    Name = "Helix - Developer",
    Description = "Allows the user to access various developer tools.",
    MinAccess = "admin"
})

if ( SERVER ) then
    util.AddNetworkString("ixDeveloperAreaEditName")
    net.Receive("ixDeveloperAreaEditName", function(_, ply)
        if ( CAMI.PlayerHasAccess(ply, "Helix - Developer", nil) and CAMI.PlayerHasAccess(ply, "Helix - AreaEdit", nil) ) then
            local previousName = net.ReadString()
            local name = net.ReadString()

            local area = ix.area.stored[previousName]
            if ( !area ) then return end

            ix.area.stored[previousName] = nil
            ix.area.stored[name] = area

            timer.Simple(1, function()
                local json = util.TableToJSON(ix.area.stored)
                local compressed = util.Compress(json)
                local length = compressed:len()

                net.Start("ixAreaSync")
                    net.WriteUInt(length, 32)
                    net.WriteData(compressed, length)
                net.Send(ply)
            end)

            ply:NotifyLocalized("areaEditorUpdated", L(areaID))
        end
    end)

    util.AddNetworkString("ixDeveloperAreaEditProperties")
    net.Receive("ixDeveloperAreaEditProperties", function(_, ply)
        if ( CAMI.PlayerHasAccess(ply, "Helix - Developer", nil) and CAMI.PlayerHasAccess(ply, "Helix - AreaEdit", nil) ) then
            local areaID = net.ReadString()
            local key = net.ReadString()
            local value = net.ReadType()

            local area = ix.area.stored[areaID]
            if ( !area ) then return end

            local areaProperties = area.properties
            if ( !areaProperties ) then return end

            areaProperties[key] = value

            timer.Simple(1, function()
                local json = util.TableToJSON(ix.area.stored)
                local compressed = util.Compress(json)
                local length = compressed:len()

                net.Start("ixAreaSync")
                    net.WriteUInt(length, 32)
                    net.WriteData(compressed, length)
                net.Send(ply)
            end)

            ply:NotifyLocalized("areaEditorUpdated", L(areaID))
        end
    end)
end