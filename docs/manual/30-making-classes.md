# Making Classes

Classes in Helix define specific roles or categories for players within a faction. For example, you might have classes like "Citizen" or "Overwatch Soldier" within a faction. This guide will walk you through the process of creating a new class for your Helix schema.

## Understanding Classes in Helix

A class determines attributes such as a player’s model, abilities, and initial loadout. Classes are typically tied to factions and help organize players into specific roles with unique traits.

## Class Structure

A class is defined within a Lua file inside your schema’s `classes` directory. The typical structure of a class file looks like this:

```
CLASS.name = "Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = true

function CLASS:OnSet(ply)
    -- Localize the character so we can use it later.
    local char = ply:GetCharacter()

    -- If the character doesn't exist, cancel the function.
    if ( !char ) then return end

    -- Set the character's model to a Overwatch Soldier.
    char:SetModel("models/combine_soldier.mdl")

    -- Set the character's skin data to 0.
    char:SetData("skin", 0)

    -- Set the player's skin to the default (skin 0).
    ply:SetSkin(0)
end

CLASS_OWS = CLASS.index
```

# Breaking Down the Example

Let’s break down each part of the example:

## CLASS.name

This specifies the name of the class as it appears in-game.

```
CLASS.name = "Overwatch Soldier"
```

## CLASS.faction

This associates the class with a specific faction. In this example, the class is linked to the `FACTION_OTA` faction.

```
CLASS.faction = FACTION_OTA
```

## CLASS.isDefault

This determines if the class is the default choice for the faction. If `true`, players will be automatically assigned to this class when they first join the faction.

```
CLASS.isDefault = true
```

## CLASS:OnSet(ply)

The `CLASS:OnSet` function is called when a player is assigned to this class. It’s typically used to set the player’s model, skin, or any other attributes specific to the class. More information about the `CLASS:OnSet` function can be found in the [Character Hooks](https://project-ordinance.com/helix/documentation/hooks/class/#OnSet) documentation.

In the example:

```
function CLASS:OnSet(ply)
    -- Localize the character so we can use it later.
    local char = ply:GetCharacter()

    -- If the character doesn't exist, cancel the function.
    if ( !char ) then return end

    -- Set the character's model to a Overwatch Soldier.
    char:SetModel("models/combine_soldier.mdl")

    -- Set the character's skin data to 0.
    char:SetData("skin", 0)

    -- Set the player's skin to the default (skin 0).
    ply:SetSkin(0)
end
```

- `char:SetModel("models/combine_soldier.mdl")` Sets the player’s character model to a Overwatch Soldier.
- `ply:SetSkin(0)` Sets the player’s skin to the default (skin 0).

## Registering the Class

Finally, the class is registered by storing its index in a variable. This can be useful if you need to reference the class elsewhere in your code.

```
CLASS_OWS = CLASS.index
```

This line assigns the class index (which Helix generates when loading the class) to the `CLASS_OWS` variable.

# Creating Your Class File

To create a new class, follow these steps:

## Navigate to Your Schema’s Directory

Go to your schema’s directory, typically located at `garrysmod/gamemodes/myschema`.

## Create a "classes" Folder (if it doesn’t exist)

If there’s no `classes` folder, create one in your schema directory:

```
garrysmod/gamemodes/myschema/schema/classes
```

## Create a New Lua File for Your Class

Name your file something descriptive like `sh_combine_soldier.lua`. The `sh_` prefix indicates that the file is shared between the client and server.

## Add Your Class Code

Paste the class code into the file and modify it to fit your needs. Here’s an example of what your file might look like:

```
CLASS.name = "Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = true

function CLASS:OnSet(ply)
    -- Localize the character so we can use it later.
    local char = ply:GetCharacter()

    -- If the character doesn't exist, cancel the function.
    if ( !char ) then return end

    -- Set the character's model to a Overwatch Soldier.
    char:SetModel("models/combine_soldier.mdl")

    -- Set the character's skin data to 0.
    char:SetData("skin", 0)

    -- Set the player's skin to the default (skin 0).
    ply:SetSkin(0)
end

CLASS_OWS = CLASS.index
```

## Save the File and Restart the Server

Once you’ve saved the file, restart your server to load the new class. Helix will automatically detect and load it.

# Customizing Your Class

You can further customize your class with additional properties and methods. Here are some examples:

## Setting Weapons

You can define the weapons a player starts with when they join a class. This is done by adding a `weapons` table to the class file. For example:

```
-- Give the player an AR2 and a pistol.
CLASS.weapons = {
    "weapon_ar2",
    "weapon_pistol"
}
```

## Setting Armor Points

You can give players armor points when they join a class as an example of customizing attributes. This is done by setting the player’s armor in the `CLASS:OnSet` function. For example:

```
function CLASS:OnSet(ply)
    -- Localize the character so we can use it later.
    local char = ply:GetCharacter()

    -- If the character doesn't exist, cancel the function.
    if ( !char ) then return end

    -- Set the character's model to a Overwatch Soldier.
    char:SetModel("models/combine_soldier.mdl")

    -- Set the character's skin data to 0.
    char:SetData("skin", 0)

    -- Set the player's skin to the default (skin 0).
    ply:SetSkin(0)

    -- Set the player's armor to 50.
    ply:SetArmor(50)
end
```

# Conclusion

Creating a class in Helix is a straightforward process that allows you to add more depth to your factions. Whether you want to give players access to unique models, loadouts, or abilities, classes provide a simple way to define these roles.

By following this guide, you can easily create custom classes for your schema and enhance your server’s gameplay. Experiment with different attributes and features to create unique roles for your players!