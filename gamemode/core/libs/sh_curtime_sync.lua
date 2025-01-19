--[[
	This script solves CurTime's lack of precision

	https://github.com/Facepunch/garrysmod-issues/issues/2502

	Created by: RaphaelIT7(https://github.com/RaphaelIT7)
]]

local SyncDelay = 30 -- in seconds
local SyncType = "net" -- can be NW2 or net

if SyncType == "NW2" then
	--[[
		NW2 solution
	]]
	if SERVER then
		timer.Create("CurTime-Sync", SyncDelay, -1, function()
			Entity(0):SetNW2Float("CurTime-Sync", CurTime()) -- NW2Float has no precision error unlike NWFloat. Functions the same as SetGlobal2Float.
		end)
	else
		hook.Add("InitPostEntity", "CurTime-Sync", function()
			local SyncTime = 0
			Entity(0):SetNW2VarProxy("CurTime-Sync", function(_, _, _, ServerCurTime)
				SyncTime = OldCurTime() - ServerCurTime
			end)

			OldCurTime = OldCurTime or CurTime -- added if you should ever need it. just add local if you dont.
			function CurTime()
				return OldCurTime() - SyncTime
			end
		end)
	end
elseif SyncType == "net" then
	--[[
		net solution
	]]
	if SERVER then
		util.AddNetworkString("CurTime-Sync")
		timer.Create("CurTime-Sync", SyncDelay, -1, function()
			net.Start("CurTime-Sync", true) -- Can be unreliable because It is not needed to sync every time.
				net.WriteFloat(CurTime())
			net.Broadcast()
		end)
	else
		hook.Add("InitPostEntity", "CurTime-Sync", function()
			local SyncTime = 0
			net.Receive("CurTime-Sync", function()
				local ServerCurTime = net.ReadFloat()
				if !ServerCurTime then return end
				SyncTime = OldCurTime() - ServerCurTime
			end)

			OldCurTime = OldCurTime or CurTime -- added if you should ever need it. just add local if you dont.
			function CurTime()
				return OldCurTime() - SyncTime
			end
		end)
	end
end

-- print("[CurTime-Sync] Successfully loaded.")
-- print("[CurTime-Sync] Created by: RaphaelIT7(https://github.com/RaphaelIT7)")