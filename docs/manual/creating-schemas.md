# Creating Schemas

A schema in Helix is the backbone of your roleplaying server. It defines everything from the game’s setting to the specific gameplay mechanics available to your players. This guide will walk you through creating a schema from scratch, using the [Skeleton Schema](https://github.com/NebulousCloud/helix-skeleton/tree/master) and the [Half-Life 2 Roleplay](https://github.com/NebulousCloud/helix-hl2rp/tree/master) Schema as examples.

# What is a Schema?

A schema is a collection of files and configurations that dictate how your server runs. It handles everything from character creation, factions, items, and commands to the overall structure and rules of your roleplay environment.

## Folder Structure

A typical schema is organized into various folders:

- `cl_schema.lua`: Client-specific logic and settings.
- `sv_schema.lua`: Server-specific logic and settings.
- `sh_schema.lua`: Shared logic, accessible by both the client and server.
- `cl_hooks.lua`, `sv_hooks.lua`, `sh_hooks.lua`: Game hooks for custom functionality.
- `libs/`: Contains custom libraries for your schema.
- `meta/`: Holds extended or modified behavior for existing Helix classes like [player](https://minerva-servers.com/helix/classes/player/), [character](https://minerva-servers.com/helix/classes/character/), etc.

# Basic Schema Setup

Here’s a basic schema setup, similar to the [Skeleton Schema](https://github.com/NebulousCloud/helix-skeleton/tree/master) example:

```
-- The shared init file. You'll want to fill out the info for your schema and include any other files that you need.

-- Schema info
Schema.name = "Skeleton"
Schema.author = "nebulous"
Schema.description = "A base schema for development."

-- Include necessary files
ix.util.Include("cl_schema.lua")
ix.util.Include("sv_schema.lua")

ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sv_hooks.lua")

-- Manually include files in the meta/ folder
ix.util.Include("meta/sh_character.lua")
ix.util.Include("meta/sh_player.lua")
```

## Schema Information

These are the basic properties of your schema:

- `Schema.name`: The name of your schema as it will appear in-game.
- `Schema.author`: The creator of the schema.
- `Schema.description`: A brief description of what your schema is about.

## File Includes

The `ix.util.Include` function is used to include additional Lua files. It automatically handles whether the file should be loaded on the client, server, or both based on its prefix (`cl_`, `sv_`, or `sh_`).

Here’s a typical file inclusion setup:

```
-- Include necessary files
ix.util.Include("cl_schema.lua")
ix.util.Include("sv_schema.lua")

ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sv_hooks.lua")
```

## Meta Files

Files in the `meta/` folder typically extend or modify existing Helix classes like `player`, `character`, etc. These files are not automatically loaded, so you must include them manually:

```
-- Manually include files in the meta/ folder
ix.util.Include("meta/sh_character.lua")
ix.util.Include("meta/sh_player.lua")
```

# Advanced Schema Setup

For a more complex schema like the [Half-Life 2 Roleplay](https://github.com/NebulousCloud/helix-hl2rp/tree/master) example, you may want to include additional libraries, commands, and configuration files.

## Including Third-Party Libraries

In some cases, you may need to include third-party libraries for extended functionality. For example, the [Half-Life 2 Roleplay schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master) includes the `netstream` library:

```
-- Include netstream library
ix.util.Include("libs/thirdparty/sh_netstream2.lua")
```

## Additional Configuration Files

You can split your configuration into separate files for better organization:

```
ix.util.Include("sh_configs.lua")
ix.util.Include("sh_commands.lua")
```

These files can contain [configs](https://minerva-servers.com/helix/libraries/ix.config/), [commands](https://minerva-servers.com/helix/libraries/ix.command/), or other utilities specific to your schema.

## Adding Flags

[Flags](https://minerva-servers.com/helix/libraries/ix.flag/#ix.flag.Add) are used in Helix to restrict access to certain items or features. You can define flags like this:

```
ix.flag.Add("v", "Access to light blackmarket goods.")
ix.flag.Add("V", "Access to heavy blackmarket goods.")
```

## Custom Animations

If your schema uses unique player models, you can define their [animation classes](https://minerva-servers.com/helix/libraries/ix.anim/) like this:

```
ix.anim.SetModelClass("models/eliteghostcp.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteshockcp.mdl", "metrocop")
```

# Custom Functions

Your schema can [include](https://minerva-servers.com/helix/libraries/ix.util/#ix.util.Include) custom utility functions to be used throughout your code. Here’s an example from the [Half-Life 2 Roleplay schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master):

```
function Schema:ZeroNumber(number, length)
    local amount = math.max(0, length - string.len(number))
    return string.rep("0", amount)..tostring(number)
end

function Schema:IsCombineRank(text, rank)
    return string.find(text, "[%D+]"..rank.."[%D+]")
end
```

These functions can be used anywhere in your schema to handle specific tasks, like formatting numbers or checking ranks.

# Setting Up Hooks

Hooks allow you to inject custom logic into specific events during the game. Your hooks should be organized into `cl_hooks.lua`, `sv_hooks.lua`, and `sh_hooks.lua` files, depending on where they are needed.

## Example Hook:

Here’s a simple hook that runs when a player spawns:

```
function Schema:PlayerSpawn(client)
    client:SetHealth(100)
    client:SetArmor(50)
end
```

This hook would be placed in `sv_hooks.lua` since it handles server-side logic.

# Conclusion

Creating a schema in Helix is straightforward once you understand the structure and organization. By following this guide, you can start building your own custom schema with everything from basic setups to advanced features like custom libraries, flags, and hooks. Experiment with different configurations and features to create a unique roleplaying experience for your players.