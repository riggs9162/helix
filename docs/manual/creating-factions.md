# Creating Factions

Factions in Helix represent different groups or organizations that players can belong to. For example, in a Half-Life 2 roleplay schema, you might have factions like the "Citizens" or the "[Overwatch Transhuman Arm](https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/factions/sh_ota.lua), a Combine faction from the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master)". This guide will show you how to create a new faction for your schema.

# Understanding Factions in Helix

A faction determines a character’s alignment, appearance, and other group-specific features. Factions often influence how other players or NPCs interact with members of that faction. You can also define default models, pay rates, and special hooks for each faction.

# Faction Structure

Factions are defined within Lua files inside your schema’s `factions` directory. Here’s a breakdown of a typical faction file:

## Example: [Overwatch Transhuman Arm](https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/factions/sh_ota.lua), a Combine faction from the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master)

Here’s an example faction definition for the [Overwatch Transhuman Arm](https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/factions/sh_ota.lua), a Combine faction from the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master):

```
FACTION.name = "Overwatch Transhuman Arm"
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
FACTION.color = Color(150, 50, 50, 255)
FACTION.pay = 40
FACTION.models = {"models/combine_soldier.mdl"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}

function FACTION:OnCharacterCreated(client, character)
    local inventory = character:GetInventory()

    inventory:Add("pistol", 1)
    inventory:Add("pistolammo", 2)

    inventory:Add("ar2", 1)
    inventory:Add("ar2ammo", 2)
end

function FACTION:GetDefaultName(client)
    return "OTA-ECHO.OWS-" .. Schema:ZeroNumber(math.random(1, 99999), 5), true
end

function FACTION:OnTransferred(character)
    character:SetName(self:GetDefaultName())
    character:SetModel(self.models[1])
end

function FACTION:OnNameChanged(client, oldValue, value)
    local character = client:GetCharacter()

    if (!Schema:IsCombineRank(oldValue, "OWS") and Schema:IsCombineRank(value, "OWS")) then
        character:JoinClass(CLASS_OWS)
    elseif (!Schema:IsCombineRank(oldValue, "EOW") and Schema:IsCombineRank(value, "EOW")) then
        character:JoinClass(CLASS_EOW)
    end
end

FACTION_OTA = FACTION.index
```

# Breaking Down the Example

Let’s go over each key part of this faction definition:

## FACTION.name

This is the name of the faction as it will appear in-game.

```
FACTION.name = "Overwatch Transhuman Arm"
```

## FACTION.description

A brief description of the faction, visible in the character creation menu.

```
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
```

## FACTION.color

The color associated with this faction, typically used in UI elements. It’s defined using the `Color` function.

```
FACTION.color = Color(150, 50, 50, 255)
```

## FACTION.pay

This determines the periodic salary that members of this faction receive.

```
FACTION.pay = 40
```

## FACTION.models

This table contains the character models available to this faction. When a player joins the faction, they can select from these models. If there is only one model, it will be automatically assigned.

```
FACTION.models = {"models/combine_soldier.mdl"}
```

## FACTION.isDefault

This determines whether this faction is the default faction for new characters. If set to `true`, new characters will automatically join this faction if they don’t have any other faction whitelist. In the example, it’s set to `false`, meaning it’s not a default faction and must be manually given to players by administrators or through other means.

```
FACTION.isDefault = false
```

## FACTION.isGloballyRecognized

When set to `true`, characters in this faction will be recognized by their faction name instead of just their character name (useful for Combine units or military factions).

```
FACTION.isGloballyRecognized = true
```

## FACTION.runSounds

This table defines custom running footstep sounds for members of this faction.

This is not a standard Helix feature and must be implemented manually. See the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master) for the implementation.

```
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}
```

# Custom Faction Functions

Helix allows you to define custom functions for factions to enhance their behavior. Here are a few examples:

## FACTION:OnCharacterCreated

This function runs when a character is first created within the faction. In this example, it automatically gives new characters certain weapons and ammo.

```
function FACTION:OnCharacterCreated(client, character)
    local inventory = character:GetInventory()

    inventory:Add("pistol", 1)
    inventory:Add("pistolammo", 2)

    inventory:Add("ar2", 1)
    inventory:Add("ar2ammo", 2)
end
```

## FACTION:GetDefaultName

This function generates a default name for characters in this faction, useful for factions with standardized naming conventions (like Combine units).

The second argument, `true`, indicates that the name is forced and cannot be changed by the player during character creation.

Keep in mind that `Schema:ZeroNumber` is a custom function and must be implemented manually. See the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master) for the implementation.

```
function FACTION:GetDefaultName(client)
    return "OTA-ECHO.OWS-" .. Schema:ZeroNumber(math.random(1, 99999), 5), true
end
```

## FACTION:OnTransferred

This function is triggered when a character is transferred into this faction from another faction. In this example, it sets a new name and model for the character.

```
function FACTION:OnTransferred(character)
    character:SetName(self:GetDefaultName())
    character:SetModel(self.models[1])
end
```

## FACTION:OnNameChanged

This function runs when a character’s name changes. It’s often used to adjust the character’s class based on rank changes, as shown here.

Like the running sounds example, this is not a standard Helix feature and must be implemented manually. See the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master) for the implementation.

```
function FACTION:OnNameChanged(client, oldValue, value)
    local character = client:GetCharacter()

    if (!Schema:IsCombineRank(oldValue, "OWS") and Schema:IsCombineRank(value, "OWS")) then
        character:JoinClass(CLASS_OWS)
    elseif (!Schema:IsCombineRank(oldValue, "EOW") and Schema:IsCombineRank(value, "EOW")) then
        character:JoinClass(CLASS_EOW)
    end
end
```

# Registering the Faction

Finally, you need to register the faction by assigning its index to a variable.

```
FACTION_OTA = FACTION.index
```

This line stores the faction’s index (generated by Helix when loading the faction) in the `FACTION_OTA` variable.

# Creating Your Faction

## Navigate to Your Schema’s `factions` Folder

Go to your schema’s directory, typically at `garrysmod/gamemodes/myschema/schema/factions`.

## Create a New Lua File for Your Faction

Name the file descriptively, such as `sh_ota.lua` for the [Overwatch Transhuman Arm](https://github.com/NebulousCloud/helix-hl2rp/blob/master/schema/factions/sh_ota.lua), a Combine faction from the [default Half-Life 2 schema](https://github.com/NebulousCloud/helix-hl2rp/tree/master).

## Define Your Faction in the Lua File

Paste your faction code into the file and customize it as needed. Here’s a basic structure to start with:

```
FACTION.name = "Your Faction Name"
FACTION.description = "A brief description of your faction."
FACTION.color = Color(255, 255, 255, 255)
FACTION.models = {
    "models/your_model.mdl",
    "models/your_model2.mdl"
}
FACTION.isDefault = false
FACTION.isGloballyRecognized = false

FACTION_YOURFACTION = FACTION.index
```

## Save the File and Restart the Server

Once the file is saved, restart your server to load the new faction. Helix will automatically detect and load it.

# Customizing Your Faction

You can further enhance your faction by adding custom hooks and functions like those shown in the examples above. Factions are a flexible way to organize players into distinct groups with specific roles, appearances, and features.

# Conclusion

Creating factions in Helix is a simple yet powerful way to define unique groups within your schema. Whether it’s for roleplay purposes, team-based gameplay, or enforcing specific rules, factions provide a structured way to manage character alignment and behavior. Follow this guide to create and customize your own factions, and tailor your server’s experience to your vision!