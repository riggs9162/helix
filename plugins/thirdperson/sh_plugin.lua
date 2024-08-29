
local PLUGIN = PLUGIN

PLUGIN.name = "Third Person"
PLUGIN.author = "Black Tea"
PLUGIN.description = "Enables third person camera usage."

ix.config.Add("thirdperson", true, "Allow Thirdperson in the server.", nil, {
    category = "server"
})

ix.util.Include("cl_plugin.lua")