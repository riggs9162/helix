# Creating Items

Items in Helix are versatile objects that players can pick up, use, and interact with. Whether it’s weapons, consumables, or even junk, creating items in Helix is straightforward and allows you to expand your schema with unique content.

# Understanding Items in Helix

Items are defined within Lua files and can have various attributes and functions that determine their behavior. They can be stored in different categories, from weapons to consumables, and can also include specific interactions or properties.

# Item Structure

Items are typically defined in Lua files within your schema’s `items` directory. Here’s a breakdown of a basic item structure:

## Example: Weapon Item (SPAS-12 Shotgun)

Here’s an example of a weapon item for a SPAS-12 shotgun located in `gamemodes/myschema/schema/items/weapons/sh_spas12.lua`:

```
ITEM.name = "SPAS-12"
ITEM.description = "A powerful shotgun that fires 12 gauge shells."
ITEM.model = Model("models/weapons/w_shotgun.mdl")

ITEM.class = "weapon_shotgun"
ITEM.weaponCategory = "primary"

ITEM.width = 3
ITEM.height = 1
```

## Example: Basic Item (Empty Mug)

Here’s an example of a basic item for an empty mug located in `gamemodes/myschema/schema/items/sh_empty_mug.lua`:

```
ITEM.name = "Empty Mug"
ITEM.description = "An empty mug commonly found in kitchens. While not exactly junk, it is reusable."
ITEM.category = "Junk"

ITEM.model = Model("models/props_junk/garbage_coffeemug001a.mdl")

ITEM.iconCam = {
    pos = Vector(0, 200, 1),
    ang = Angle(0, 270, 0),
    fov = 10
}
```

# Breaking Down the Examples

Let’s break down the key attributes used in these examples:

## ITEM.name

This is the name of the item as it appears in-game.

```
ITEM.name = "SPAS-12"
```

## ITEM.description

This provides a description of the item that players see when they hover over it in their inventory.

```
ITEM.description = "A powerful shotgun that fires 12 gauge shells."
```

## ITEM.model

Defines the 3D model that represents the item. It should be specified using the `Model` function in order to cache the model on the server and client.

```
ITEM.model = Model("models/weapons/w_shotgun.mdl")
```

## ITEM.class

For weapon items, this specifies the class name of the weapon entity that will be given to the player. Make sure the class name matches the weapon entity you want to give.

```
ITEM.class = "weapon_shotgun"
```

## ITEM.weaponCategory

Defines the category of the weapon, such as "primary" or "secondary". This helps determine where the weapon is equipped in the player’s inventory.

```
ITEM.weaponCategory = "primary"
```

## ITEM.width and ITEM.height

These define the item’s size within the inventory grid.

```
ITEM.width = 3
ITEM.height = 1
```

## Additional Attributes (for the Basic Item)

**ITEM.category**

This categorizes the item within the inventory, helping with organization.

```
ITEM.category = "Junk"
```

**ITEM.iconCam**

The `iconCam` table controls how the item’s icon is displayed in the inventory. It includes settings for position (`pos`), angle (`ang`), and field of view (`fov`). Adjust these values to ensure the item’s icon looks good in the inventory.

There is a default iconCam generated for each model, but you can override it if needed using the Helix Icon Editor menu in-game, by opening the console and typing `ix iconeditor`. Once you have the iconCam you want, you can copy the values to the item file and adjust them as needed.

If you are fully done with the iconCam, you need to run `ix_flushicon` in the console to erase older iterations of the generated icon for the item. After running the command, restart your game.

```
ITEM.iconCam = {
    pos = Vector(0, 200, 1),
    ang = Angle(0, 270, 0),
    fov = 10
}
```

# Creating Your Item

To create a new item in Helix, follow these steps:

## Navigate to Your Schema’s Items Directory

Items should be stored in the `schema/items` directory within your schema. If the folder doesn’t exist, create it:

```
garrysmod/gamemodes/myschema/schema/items/
```

## Create a New Lua File for Your Item

Each item should be in its own Lua file. Name the file descriptively, such as `sh_spas12.lua` for a SPAS-12 shotgun or `sh_empty_mug.lua` for an empty mug. To ensure the file is shared between the client and server, use the `sh_` prefix. When making a weapon item, you can place it in the `weapons` subfolder, if the folder doesn't exist, create one:

```
garrysmod/gamemodes/myschema/schema/items/weapons/
```

## Define Your Item in the Lua File

Paste the item code into the file, modifying the attributes as needed. For example:

**SPAS-12 Shotgun:**

```
ITEM.name = "SPAS-12"
ITEM.description = "A powerful shotgun that fires 12 gauge shells."
ITEM.model = Model("models/weapons/w_shotgun.mdl")

ITEM.class = "weapon_shotgun"
ITEM.weaponCategory = "primary"

ITEM.width = 3
ITEM.height = 1
```

**Empty Mug:**

```
ITEM.name = "Empty Mug"
ITEM.description = "An empty mug commonly found in kitchens. While not exactly junk, it is reusable."
ITEM.model = Model("models/props_junk/garbage_coffeemug001a.mdl")
ITEM.category = "Junk"

ITEM.iconCam = {
    pos = Vector(0, 200, 1),
    ang = Angle(0, 270, 0),
    fov = 10
}
```

## Save and Restart Your Server

Once you save the file, restart your server to load the new item. Helix will automatically recognize and load it.

# Conclusion

Creating items in Helix is a simple yet powerful way to enhance your schema. Whether you’re adding weapons, consumables, or decorative junk, the process is consistent and flexible. Experiment with different attributes and properties to create unique items that fit your server’s needs!