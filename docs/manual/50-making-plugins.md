# Making Plugins

Creating plugins for the Helix Framework allows you to extend the core functionality of your schema with custom features. Whether you’re adding simple enhancements or complex systems, plugins provide a modular way to organize your code.

This guide will walk you through the process of creating a plugin using an example for playing gestures on players.

# Getting Started

Plugins in Helix are structured similarly to the framework itself. They consist of server-side, client-side, and shared components that are loaded in a specific order. The plugin structure is straightforward, allowing you to extend the framework without modifying the core files directly.

## Plugin Structure

A typical plugin will have the following structure:

```
myplugin/
|-- cl_hooks.lua
|-- cl_plugin.lua
|-- meta/
|   |-- sh_player.lua
|-- sh_plugin.lua
|-- sv_hooks.lua
|-- sv_plugin.lua
```

- **cl_hooks.lua**: Contains client-side hooks.
- **cl_plugin.lua**: Contains client-side logic specific to your plugin.
- **meta/sh_player.lua**: Modifies or adds functionality to existing Helix entities or classes (like players).
- **sh_plugin.lua**: Contains shared settings and configurations.
- **sv_hooks.lua**: Contains server-side hooks.
- **sv_plugin.lua**: Contains server-side logic.

## The Basics of `sh_plugin.lua`

Every plugin starts with a `sh_plugin.lua` file. This file provides essential metadata for your plugin, like its name, description, author, and version.

Here’s an example of what `sh_plugin.lua` might look like:

```
local PLUGIN = PLUGIN

PLUGIN.name = "Gestures"
PLUGIN.description = "Allows developers to play gestures on players."
PLUGIN.author = "Riggs"
PLUGIN.schema = "Any" -- Optional: Specifies a schema, or set to "Any" for universal use.
PLUGIN.version = "1.0"

-- Including additional files
ix.util.Include("meta/sh_player.lua")

ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")

ix.util.Include("cl_hooks.lua")
ix.util.Include("sv_hooks.lua")
```

## Including Files

The `ix.util.Include` function is used to load additional files needed by your plugin. These files can be either client-side, server-side, or shared. Including them in the `sh_plugin.lua` file ensures they are loaded at the correct time.

## The Meta Folder

The `meta` folder is where you place files that modify or add new functionality to existing Helix classes or entities. In the example, `meta/sh_player.lua` could be used to extend player functionality with custom methods or properties.

# Example File Breakdown

## `cl_plugin.lua`

Client-side logic for your plugin goes here. This file handles anything that needs to be executed on the client side, like UI changes or visual effects.

Example:

```
-- cl_plugin.lua
function PLUGIN:PlayerButtonDown(client, button)
    if button == KEY_G then
        -- Custom client-side code for when the G key is pressed.
    end
end
```

## `sv_plugin.lua`

Server-side logic for your plugin is placed in this file. This is where you handle actions that need to be processed by the server, such as manipulating player states, handling commands, or managing data.

Example:

```
-- sv_plugin.lua
function PLUGIN:PlayerSpawn(client)
    client:SetHealth(100) -- Example: Ensures players spawn with full health.
end
```

## `cl_hooks.lua` and `sv_hooks.lua`

These files handle client-side and server-side hooks, respectively. Hooks are events triggered by the Helix framework (e.g., when a player spawns or a command is executed).

Example:

```
-- cl_hooks.lua
function PLUGIN:HUDPaint()
    draw.SimpleText("Hello, Helix!", "DermaDefault", ScrW()/2, ScrH()/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- sv_hooks.lua
function PLUGIN:PlayerDeath(client)
    print(client:Name() .. " has died.")
end
```

## `meta/sh_player.lua`

This file is used to add or modify properties and functions specific to players. For example, you might add a custom method to play a gesture:

```
-- meta/sh_player.lua
local playerMeta = FindMetaTable("Player")

function playerMeta:PlayGesture(gesture)
    if self:IsValid() then
        self:AnimRestartGesture(GESTURE_SLOT_CUSTOM, gesture, true)
    end
end
```

# Loading the Plugin

Once your plugin files are ready, simply place the folder in the `plugins` directory of your Helix schema. Helix automatically detects and loads plugins from this directory.

```
garrysmod/gamemodes/myschema/plugins/myplugin
```

After placing your plugin in the correct directory, restart your server, and Helix will load your plugin.

# Conclusion

This guide covered the basics of creating a plugin for the Helix Framework. By following these steps and utilizing the structure provided, you’ll be able to extend your schema with new features easily. With practice, you can create more complex plugins to enhance your server and provide unique experiences for your players.

Feel free to experiment with additional hooks, client-server communication, and other Lua features as you build more advanced plugins!