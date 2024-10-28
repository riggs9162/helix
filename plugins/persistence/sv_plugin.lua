local PLUGIN = PLUGIN

ix.log.AddType("persist", function(client, ...)
    local arg = {...}
    return string.format("%s has %s persistence for '%s'.", client:Name(), arg[2] and "enabled" or "disabled", arg[1])
end)