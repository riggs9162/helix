
-- Include Helix content.
resource.AddWorkshop("1267236756")

-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store Helix information.
ix = ix or {util = {}, meta = {}}

-- Send the following files to players.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("core/sh_data.lua")
AddCSLuaFile("shared.lua")

-- Include utility functions, data storage functions, and then shared.lua
include("core/sh_util.lua")
include("core/sh_data.lua")
include("shared.lua")

-- security overrides, people should have these set anyway, but this is just in case
RunConsoleCommand("sv_allowupload", "0")
RunConsoleCommand("sv_allowdownload", "0")
RunConsoleCommand("sv_allowcslua", "0")

if ( engine.ActiveGamemode() == "helix" ) then
    local gs = ""
    for k, v in pairs(engine.GetGamemodes()) do
        if ( v.name:find("ix") and v.name != "helix" ) then
            gs = gs .. v.name .. "\n"
        end
    end

    SetGlobalString("fatalError", "No schema loaded. Please place the schema in your gamemodes folder, then set it as your gamemode.\n\nInstalled available schemas:\n" .. gs)
end

-- Include all files in the gamemode such as models, materials, sounds, etc. This is done to ensure that the files are sent to the client. Subfolders are included as well.
local function IncludeFolder(dir)
    local total = 0

    local files, folders = file.Find(dir .. "*", "GAME")
    for k, v in pairs(files) do
        total = total + 1

        resource.AddFile(dir .. v)
    end

    for k, v in pairs(folders) do
        total = total + IncludeFolder(dir .. v .. "/")
    end

    return total
end

local function IncludeContent()
    MsgC(Color(115, 53, 142), "[Helix] Loading content...\n")

    local total = 0

    total = total + IncludeFolder("materials/helix/")
    total = total + IncludeFolder("resource/fonts/")
    total = total + IncludeFolder("sound/helix/")

    MsgC(Color(0, 255, 0), "[Helix] Completed content load (" .. total .. " files)...\n")
end

-- Include all workshop addons
local function IncludeWorkshopAddons()
    MsgC(Color(115, 53, 142), "[Helix] Loading workshop addons...\n")

    local total = 0
    local addons = engine.GetAddons()

    for k, v in pairs(addons) do
        if ( v.mounted and v.wsid != "0" ) then
            total = total + 1

            resource.AddWorkshop(v.wsid)
            MsgC(Color(115, 53, 142), "[Helix] Added workshop addon: " .. v.title .. "\n")
        end
    end

    MsgC(Color(0, 255, 0), "[Helix] Completed workshop addon load (" .. total .. " addons)...\n")
end

IncludeContent()
IncludeWorkshopAddons()

cvars.AddChangeCallback("sbox_persist", function(name, old, new)
    -- A timer in case someone tries to rapily change the convar, such as addons with "live typing" or whatever
    timer.Create("sbox_persist_change_timer", 1, 1, function()
        hook.Run("PersistenceSave", old)

        if (new == "") then return end

        hook.Run("PersistenceLoad", new)
    end)
end, "sbox_persist_load")
