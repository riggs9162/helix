
-- luacheck: ignore 111

--[[--
Global hooks for general use.

Plugin hooks are regular hooks that can be used in your schema with `Schema:HookName(args)`, in your plugin with
`PLUGIN:HookName(args)`, or in your addon with `hook.Add("HookName", function(args) end)`.
]]
-- @hooks Plugin

--- Adjusts the data used just before creating a new character.
-- @realm server
-- @player client Player that is creating the character
-- @tab payload Table of data to be used for character creation
-- @tab newPayload Table of data be merged with the current payload
-- @usage function PLUGIN:AdjustCreationPayload(client, payload, newPayload)
--     newPayload.money = payload.attributes["stm"] -- Sets the characters initial money to the stamina attribute value.
-- end
function AdjustCreationPayload(client, payload, newPayload)
end

--- Adjusts a player's current stamina offset amount. This is called when the player's stamina is about to be changed; every
-- `0.25` seconds on the server, and every frame on the client.
-- @realm shared
-- @player client Player whose stamina is changing
-- @number baseOffset Amount the stamina is changing by. This can be a positive or negative number depending if they are
-- exhausting or regaining stamina
-- @treturn number New offset to use
-- @usage function PLUGIN:AdjustStaminaOffset(client, baseOffset)
--     return baseOffset * 2 -- Drain/Regain stamina twice as fast.
-- end
function AdjustStaminaOffset(client, baseOffset)
end

--- Creates the business panel in the tab menu.
-- @realm client
-- @treturn bool Whether or not to create the business menu
-- @usage function PLUGIN:BuildBusinessMenu()
--     return LocalPlayer():IsAdmin() -- Only builds the business menu for admins.
-- end
function BuildBusinessMenu()
end

--- Whether or not a message can be auto formatted with punctuation and capitalization.
-- @realm server
-- @player speaker Player that sent the message
-- @string chatType Chat type of the message. This will be something registered with `ix.chat.Register` - like `ic`, `ooc`, etc.
-- @string text Unformatted text of the message
-- @treturn bool Whether or not to allow auto formatting on the message
-- @usage function PLUGIN:CanAutoFormatMessage(speaker, chatType, text)
--     return false -- Disable auto formatting outright.
-- end
function CanAutoFormatMessage(speaker, chatType, text)
end

--- Whether or not certain information can be displayed in the character info panel in the tab menu.
-- @realm client
-- @tab suppress Information to **NOT** display in the UI - modify this to change the behaviour. This is a table of the names of
-- some panels to avoid displaying. Valid names include:
--
-- - `time` - current in-game time
-- - `name` - name of the character
-- - `description` - description of the character
-- - `characterInfo` - entire panel showing a list of additional character info
-- - `faction` - faction name of the character
-- - `class` - name of the character's class if they're in one
-- - `money` - current money the character has
-- - `attributes` - attributes list for the character
--
-- Note that schemas/plugins can add additional character info panels.
-- @usage function PLUGIN:CanCreateCharacterInfo(suppress)
--     suppress.attributes = true -- Hides the attributes panel from the character info tab
-- end
function CanCreateCharacterInfo(suppress)
end

--- Whether or not the ammo HUD should be drawn.
-- @realm client
-- @entity weapon Weapon the player currently is holding
-- @treturn bool Whether or not to draw the ammo hud
-- @usage function PLUGIN:CanDrawAmmoHUD(weapon)
--     if (weapon:GetClass() == "weapon_frag") then -- Hides the ammo hud when holding grenades.
--         return false
--     end
-- end
function CanDrawAmmoHUD(weapon)
end

--- Called when a player tries to use abilities on the door, such as locking.
-- @realm shared
-- @player client The client trying something on the door.
-- @entity door The door entity itself.
-- @number access The access level used when called.
-- @treturn bool Whether or not to allow the client access.
-- @usage function PLUGIN:CanPlayerAccessDoor(client, door, access)
--     return true -- Always allow access.
-- end
function CanPlayerAccessDoor(client, door, access)
end

--- Whether or not a player is allowed to combine an item `other` into the given `item`.
-- @realm server
-- @player client Player attempting to combine an item into another
-- @number item instance ID of the item being dropped onto
-- @number other instance ID of the item being combined into the first item, this can be invalid due to it being from clientside
-- @treturn bool Whether or not to allow the player to combine the items
-- @usage function PLUGIN:CanPlayerCombineItem(client, item, other)
--        local otherItem = ix.item.instances[other]
--
--        if (otherItem and otherItem.uniqueID == "soda") then
--            return false -- disallow combining any item that has a uniqueID equal to `soda`
--        end
--    end
function CanPlayerCombineItem(client, item, other)
end

--- Whether or not a player is allowed to create a new character with the given payload.
-- @realm server
-- @player client Player attempting to create a new character
-- @tab payload Data that is going to be used for creating the character
-- @treturn bool Whether or not the player is allowed to create the character. This function defaults to `true`, so you
-- should only ever return `false` if you're disallowing creation. Otherwise, don't return anything as you'll prevent any other
-- calls to this hook from running.
-- @treturn string Language phrase to use for the error message
-- @treturn ... Arguments to use for the language phrase
-- @usage function PLUGIN:CanPlayerCreateCharacter(client, payload)
--     if (!client:IsAdmin()) then
--         return false, "notNow" -- only allow admins to create a character
--     end
-- end
-- -- non-admins will see the message "You are not allowed to do this right now!"
function CanPlayerCreateCharacter(client, payload)
end

--- Whether or not a player is allowed to drop the given `item`.
-- @realm server
-- @player client Player attempting to drop an item
-- @number item instance ID of the item being dropped
-- @treturn bool Whether or not to allow the player to drop the item
-- @usage function PLUGIN:CanPlayerDropItem(client, item)
--     return false -- Never allow dropping items.
-- end
function CanPlayerDropItem(client, item)
end

--- Whether or not a player can earn money at regular intervals. This hook runs only if the player's character faction has
-- a salary set - i.e `FACTION.pay` is set to something other than `0` for their faction.
-- @realm server
-- @player client Player to give money to
-- @tab faction Faction of the player's character
-- @treturn bool Whether or not to allow the player to earn salary
-- @usage function PLUGIN:CanPlayerEarnSalary(client, faction)
--     return client:IsAdmin() -- Restricts earning salary to admins only.
-- end
function CanPlayerEarnSalary(client, faction)
end

--- Whether or not the player is allowed to enter observer mode. This is allowed only for admins by default and can be
-- customized by server owners if the server is using a CAMI-compliant admin mod.
-- @realm server
-- @player client Player attempting to enter observer
-- @treturn bool Whether or not to allow the player to enter observer
-- @usage function PLUGIN:CanPlayerEnterObserver(client)
--     return true -- Always allow observer.
-- end
function CanPlayerEnterObserver(client)
end

--- Whether or not a player can equip the given `item`. This is called for items with `outfit`, `pacoutfit`, or `weapons` as
-- their base. Schemas/plugins can utilize this hook for their items.
-- @realm server
-- @player client Player attempting to equip the item
-- @tab item Item being equipped
-- @treturn bool Whether or not to allow the player to equip the item
-- @see CanPlayerUnequipItem
-- @usage function PLUGIN:CanPlayerEquipItem(client, item)
--     return client:IsAdmin() -- Restrict equipping items to admins only.
-- end
function CanPlayerEquipItem(client, item)
end

--- Whether or not a player is allowed to hold an entity with the hands SWEP.
-- @realm server
-- @player client Player attempting to hold an entity
-- @entity entity Entity being held
-- @treturn bool Whether or not to allow the player to hold the entity
-- @usage function PLUGIN:CanPlayerHoldObject(client, entity)
--     return !(client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer holding objects.
-- end
function CanPlayerHoldObject(client, entity)
end

--- Whether or not a player is allowed to interact with an entity's interaction menu if it has one.
-- @realm server
-- @player client Player attempting interaction
-- @entity entity Entity being interacted with
-- @string option Option selected by the player
-- @param data Any data passed with the interaction option
-- @treturn bool Whether or not to allow the player to interact with the entity
-- @usage function PLUGIN:CanPlayerInteractEntity(client, entity, option, data)
--     return false -- Disallow interacting with any entity.
-- end
function CanPlayerInteractEntity(client, entity, option, data)
end

--- Whether or not a player is allowed to interact with an item via an inventory action (e.g picking up, dropping, transferring
-- inventories, etc). Note that this is for an item *table*, not an item *entity*. This is called after `CanPlayerDropItem`
-- and `CanPlayerTakeItem`.
-- @realm server
-- @player client Player attempting interaction
-- @string action The action being performed
-- @param item Item's instance ID or item table
-- @param data Any data passed with the action
-- @treturn bool Whether or not to allow the player to interact with the item
-- @usage function PLUGIN:CanPlayerInteractItem(client, action, item, data)
--     return false -- Disallow interacting with any item.
-- end
function CanPlayerInteractItem(client, action, item, data)
end

--- Whether or not a plyer is allowed to join a class.
-- @realm shared
-- @player client Player attempting to join
-- @number class ID of the class
-- @tab info The class table
-- @treturn bool Whether or not to allow the player to join the class
-- @usage function PLUGIN:CanPlayerJoinClass(client, class, info)
--     return client:IsAdmin() -- Restrict joining classes to admins only.
-- end
function CanPlayerJoinClass(client, class, info)
end

--- Whether or not a player can knock on the door with the hands SWEP.
-- @realm server
-- @player client Player attempting to knock
-- @entity entity Door being knocked on
-- @treturn bool Whether or not to allow the player to knock on the door
-- @usage function PLUGIN:CanPlayerKnock(client, entity)
--     return false -- Disable knocking on doors outright.
-- end
function CanPlayerKnock(client, entity)
end

--- Whether or not a player can open a shipment spawned from the business menu.
-- @realm server
-- @player client Player attempting to open the shipment
-- @entity entity Shipment entity
-- @treturn bool Whether or not to allow the player to open the shipment
-- @usage function PLUGIN:CanPlayerOpenShipment(client, entity)
--     return client:Team() == FACTION_BMD -- Restricts opening shipments to FACTION_BMD.
-- end
function CanPlayerOpenShipment(client, entity)
end

--- Whether or not a player is allowed to spawn a container entity.
-- @realm server
-- @player client Player attempting to spawn a container
-- @string model Model of the container being spawned
-- @entity entity Container entity
-- @treturn bool Whether or not to allow the player to spawn the container
-- @usage function PLUGIN:CanPlayerSpawnContainer(client, model, entity)
--     return client:IsAdmin() -- Restrict spawning containers to admins.
-- end
function CanPlayerSpawnContainer(client, model, entity)
end

--- Whether or not a player is allowed to take an item and put it in their inventory.
-- @realm server
-- @player client Player attempting to take the item
-- @entity item Entity corresponding to the item
-- @treturn bool Whether or not to allow the player to take the item
-- @usage function PLUGIN:CanPlayerTakeItem(client, item)
--     return !(client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle()) -- Disallow players in observer taking items.
-- end
function CanPlayerTakeItem(client, item)
end

--- Whether or not the player is allowed to punch with the hands SWEP.
-- @realm shared
-- @player client Player attempting throw a punch
-- @treturn bool Whether or not to allow the player to punch
-- @usage function PLUGIN:CanPlayerThrowPunch(client)
--     return client:GetCharacter():GetAttribute("str", 0) > 0 -- Only allow players with strength to punch.
-- end
function CanPlayerThrowPunch(client)
end

--- Whether or not a player can trade with a vendor.
-- @realm server
-- @player client Player attempting to trade
-- @entity entity Vendor entity
-- @string uniqueID The uniqueID of the item being traded.
-- @bool isSellingToVendor If the client is selling to the vendor
-- @treturn bool Whether or not to allow the client to trade with the vendor
-- @usage function PLUGIN:CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
--     return false -- Disallow trading with vendors outright.
-- end
function CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
end

--- Whether or not a player can unequip an item.
-- @realm server
-- @player client Player attempting to unequip an item
-- @tab item Item being unequipped
-- @treturn bool Whether or not to allow the player to unequip the item
-- @see CanPlayerEquipItem
-- @usage function PLUGIN:CanPlayerUnequipItem(client, item)
--     return false -- Disallow unequipping items.
-- end
function CanPlayerUnequipItem(client, item)
end

--- Whether or not a player can buy an item from the business menu.
-- @realm shared
-- @player client Player that uses a business menu
-- @string uniqueID The uniqueID of the business menu item
-- @treturn bool Whether or not to allow the player to buy an item from the business menu
-- @usage function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
--  return false -- Disallow buying from the business menu.
-- end
function CanPlayerUseBusiness(client, uniqueID)
end

--- Whether or not a player can use a character.
-- @realm shared
-- @player client Player that wants to use a character
-- @char character Character that a player wants to use
-- @treturn bool Whether or not to allow the player to load a character
-- @usage function PLUGIN:CanPlayerUseCharacter(client, character)
--     return false -- Disallow using any character.
-- end
function CanPlayerUseCharacter(client, character)
end

--- Whether or not a player can use a door.
-- @realm server
-- @player client Player that wants to use a door
-- @entity entity Door that a player wants to use
-- @treturn bool Whether or not to allow the player to use a door
-- @usage function PLUGIN:CanPlayerUseDoor(client, character)
--     return false -- Disallow using any door.
-- end
function CanPlayerUseDoor(client, entity)
end

--- Determines whether a player can use a vendor.
-- @realm server
-- @player activator The player attempting to use the vendor
-- @entity vendor The vendor entity being used
-- @treturn bool Returns false if the player can't use the vendor
function CanPlayerUseVendor(activator, vendor)
end

--- Whether or not a player can view his inventory.
-- @realm client
-- @treturn bool Whether or not to allow the player to view his inventory
-- @usage function PLUGIN:CanPlayerViewInventory()
--     return false -- Prevent player from viewing his inventory.
-- end
function CanPlayerViewInventory()
end

--- Whether or not to save a container.
-- @realm server
-- @entity entity Container entity to save
-- @tab inventory Container inventory
-- @treturn bool Whether or not to save a container
-- @usage function PLUGIN:CanSaveContainer(entity, inventory)
--  return false -- Disallow saving any container.
-- end
function CanSaveContainer(entity, inventory)
end

--- Whether or not and item can be transferred from one inventory to another.
-- @realm shared
-- @tab item Item being transferred
-- @tab currentInv Current inventory
-- @tab oldInv Old inventory
-- @treturn bool Whether or not to allow the item to be transferred
-- @usage function PLUGIN:CanTransferItem(item, currentInv, oldInv)
--     if (IsValid(item:GetOwner() and !item:GetOwner():IsAdmin()) then
--         return false -- Admins can transfer items.
--     end
-- end
function CanTransferItem(item, currentInv, oldInv)
end

--- Called character's attributes are being boosted.
-- @realm shared
-- @player client Player that is boosting the character
-- @char character Character that is being boosted
-- @number attribID ID of the attribute being boosted
-- @number boostID ID of the boost
-- @number boostAmount Amount of the boost
-- @usage function PLUGIN:CharacterAttributeBoosted(client, character, attribID, boostID, boostAmount)
--     client:Notify("Your character's "..ix.attributes.list[attribID].name.." has been boosted by "..boostAmount..".")
-- end
function CharacterAttributeBoosted(client, character, attribID, boostID, boostAmount)
end

--- Called when a character's attribute is being updated.
-- @realm shared
-- @player client Player that is updating the character
-- @char character Character that is being updated
-- @string key Key of the attribute being updated
-- @number value Value of the attribute
-- @usage function PLUGIN:CharacterAttributeUpdated(client, character, key, value)
--     client:Notify("Your character's "..key.." has been updated to "..value..".")
-- end
function CharacterAttributeUpdated(client, character, key, value)
end

--- Called when a character is being deleted.
-- @realm shared
-- @player client Player that is deleting the character
-- @number id ID of the character being deleted
-- @bool isCurrentChar Whether or not the character is the current character
-- @usage function PLUGIN:CharacterDeleted(client, id, isCurrentChar)
--     if (CLIENT and isCurrentChar) then
--         client:Notify("You have deleted your current character.")
--     end
-- end
function CharacterDeleted(client, id, isCurrentChar)
end

--- Returns if the character has the given flags.
-- @realm shared
-- @char character Character to check
-- @number flags Flags to check
-- @treturn bool Whether or not the character has the flags
-- @usage function PLUGIN:CharacterHasFlags(character, flags)
--     return {"p", "e", "t"} -- Character has the spawning, physgun and toolgun flags.
-- end
function CharacterHasFlags(character, flags)
end

--- Called when a character is loaded.
-- @realm shared
-- @char character Character that is being loaded
-- @usage function PLUGIN:CharacterLoaded(character)
--     print("Character "..character:GetName().." has been loaded.")
-- end
function CharacterLoaded(character)
end

--- Called when a character was saved.
-- @realm shared
-- @char character that was saved
-- @usage function PLUGIN:CharacterPostSave(character)
--     print("Character "..character:GetName().." has been saved.")
-- end
function CharacterPostSave(character)
end

--- Called before a character is saved.
-- @realm shared
-- @char character Character that is being saved
-- @usage function PLUGIN:CharacterPreSave(character)
--     print("Character "..character:GetName().." is about to be saved.")
-- end
function CharacterPreSave(character)
end

--- @realm shared
function CharacterRecognized()
end

--- Called when a character was restored.
-- @realm server
-- @char character that was restored
function CharacterRestored(character)
end

--- @realm shared
function CharacterVarChanged(character, key, oldVar, value)
end

--- @realm shared
function CharacterVendorTraded(client, entity, uniqueID, isSellingToVendor)
end

--- @realm client
function ChatboxCreated()
end

--- @realm client
function ChatboxPositionChanged(x, y, width, height)
end

--- @realm client
function ColorSchemeChanged(color)
end

--- Called when a container was removed.
-- @realm server
-- @entity container Container that was removed
-- @tab inventory Container inventory
function ContainerRemoved(container, inventory)
end

--- @realm client
function CreateCharacterInfo(panel)
end

--- @realm client
function CreateCharacterInfoCategory(panel)
end

--- @realm client
function CreateItemInteractionMenu(icon, menu, itemTable)
end

--- Called whenever buttons are being created for the tab menu, this is useful for creating new tabs or modifying existing ones.
-- @realm client
-- @tab tabs Table of tabs to be modified
-- @usage -- Create a new tab in the tab menu using localizations.
-- function PLUGIN:CreateMenuButtons(tabs)
--     tabs["skills"] = function(container)
--         local button = container:Add("DButton")
--         button:SetText("chooseSkills")
--         button:Dock(FILL)
--         button.DoClick = function(this)
--             ix.util.NotifyLocalized("noDesc")
--         end
--     end
-- end
--
-- -- You can also remove tabs by setting them to nil.
-- function PLUGIN:CreateMenuButtons(tabs)
--     tabs["inv"] = nil
-- end
--
-- -- When creating tabs, you can use it as a table instead of a function instead to provide more information for the button and the tab itself.
-- function PLUGIN:CreateMenuButtons(tabs)
--     tabs["skills"] = {
--         buttonColor = Color(255, 0, 0), -- color of the button
--         bDefault = true, -- make this tab the default tab
--         PopulateTabButton = function(info, button) -- function to populate the tab button
--             print("Populating tab button for skills")
--         end,
--         Create = function(info, container) -- function to create the tab
--             local button = container:Add("DButton")
--             button:SetText("chooseSkills")
--             button:Dock(FILL)
--             button.DoClick = function(this)
--                 ix.util.NotifyLocalized("noDesc")
--             end
--         end,
--         OnSelected = function(info, container) -- function to call when the tab is selected
--             print("Selected tab skills")
--         end,
--         OnDeselected = function(info, container) -- function to call when the tab is deselected
--             print("Deselected tab skills")
--         end
--     }
-- end
function CreateMenuButtons(tabs)
end

--- Called when a shipment was created.
-- @realm server
-- @player client Player that ordered the shipment
-- @entity entity Shipment entity
function CreateShipment(client, entity)
end

--- Called when a server has connected to the database.
-- @realm server
function DatabaseConnected()
end

--- Called when a server failed to connect to the database.
-- @realm server
-- @string error Error that prevented server from connecting to the database
function DatabaseConnectionFailed(error)
end

--- @realm shared
function DoPluginIncludes(path, pluginTable)
end

--- @realm client
function DrawCharacterOverview()
end

--- @realm client
function DrawHelixModelView(panel, entity)
end

--- @realm client
function DrawPlayerRagdoll(entity)
end

--- @realm client
function GetCharacterDescription(client)
end

--- Returns the name of the character to be displayed in the chat box or other areas.
-- @realm shared
-- @player speaker Player that is speaking
-- @string chatType Chat type of the message. This will be something registered with `ix.chat.Register` - like `ic`, `ooc`, etc.
-- @treturn string Name of the character
-- @usage -- Show the name of the character at all times to admins.
-- function PLUGIN:GetCharacterName(speaker, chatType)
--     if (LocalPlayer():IsAdmin()) then
--         return speaker:GetCharacter():GetName()
--     end
-- end
function GetCharacterName(speaker, chatType)
end

--- @realm shared
function GetChatPrefixInfo(text)
end

--- @realm client
function GetCrosshairAlpha(curAlpha)
end

--- @realm shared
function GetDefaultAttributePoints(client, count)
end

--- @realm shared
function GetDefaultCharacterName(client, faction)
end

--- @realm shared
function GetMaxPlayerCharacter(client)
end

--- Returns the sound to emit from the player upon death. If nothing is returned then it will use the default male/female death
-- sounds.
-- @realm server
-- @player client Player that died
-- @treturn[1] string Sound to play
-- @treturn[2] bool `false` if a sound shouldn't be played at all
-- @usage function PLUGIN:GetPlayerDeathSound(client)
--     -- play impact sound every time someone dies
--     return "physics/body/body_medium_impact_hard1.wav"
-- end
-- @usage function PLUGIN:GetPlayerDeathSound(client)
--     -- don't play a sound at all
--     return false
-- end
function GetPlayerDeathSound(client)
end

--- @realm client
function GetPlayerEntityMenu(client, options)
end

--- Returns the player's icon to be displayed in the chat box.
-- @realm shared
-- @player speaker Player that is speaking
-- @treturn string Icon to display
-- @usage function PLUGIN:GetPlayerIcon(speaker)
--     return "icon16/user.png" -- Use the default user icon.
-- end
function GetPlayerIcon(speaker)
end

--- Returns the player's color to be displayed in the chat box.
-- @realm shared
-- @player speaker Player that is speaking
-- @treturn Color Color to display
-- @usage function PLUGIN:GetPlayerColor(speaker)
--     return Color(255, 0, 0) -- Use red color for the player.
-- end
function GetPlayerColor(speaker)
end

--- Returns the sound to emit from the player upon getting damage.
-- @realm server
-- @player client Client that received damage
-- @treturn string Sound to emit
-- @usage function PLUGIN:GetPlayerPainSound(client)
--     return "NPC_MetroPolice.Pain" -- Make players emit MetroPolice pain sound.
-- end
function GetPlayerPainSound(client)
end

--- Returns the damage that the player should deal with his punches.
-- @realm shared
-- @player client Client that is punching
-- @number damage Base damage of the punch
-- @tab context Context of the punch
-- @treturn number Damage to deal
-- @usage function PLUGIN:GetPlayerPunchDamage(client, damage, context)
--     return (client:IsAdmin() and damage * 2) or damage -- Admins deal double damage.
-- end
function GetPlayerPunchDamage(client, damage, context)
end

--- Returns the salary that character should get instead of his faction salary.
-- @realm server
-- @player client Client that is receiving salary
-- @tab faction Faction of the player's character
-- @treturn number Character salary
-- @see CanPlayerEarnSalary
-- @usage function PLUGIN:GetSalaryAmount(client, faction)
--  return 0 -- Everyone get no salary.
-- end
function GetSalaryAmount(client, faction)
end

--- Called whenever a player gets his salary.
-- @realm server
-- @player client Player that is receiving salary
-- @tab faction Faction of the player's character
-- @number salary Salary amount
-- @see CanPlayerEarnSalary
-- @usage function PLUGIN:OnPlayerEarnSalary(client, faction, salary)
--     client:Notify("You have received a salary of "..salary..".")
-- end
function OnPlayerEarnSalary(client, faction, salary)
end

--- @realm client
function GetTypingIndicator(character, text)
end

--- Registers chat classes after the core framework chat classes have been registered. You should usually create your chat
-- classes in this hook - especially if you want to reference the properties of a framework chat class.
-- @realm shared
-- @usage function PLUGIN:InitializedChatClasses()
--     -- let's say you wanted to reference an existing chat class's color
--     ix.chat.Register("myclass", {
--         format = "%s says \"%s\"",
--         GetColor = function(self, speaker, text)
--             -- make the chat class slightly brighter than the "ic" chat class
--             local color = ix.chat.classes.ic:GetColor(speaker, text)
--
--             return Color(color.r + 35, color.g + 35, color.b + 35)
--         end,
--         -- etc.
--     })
-- end
-- @see ix.chat.Register
-- @see ix.chat.classes
function InitializedChatClasses()
end

--- Called after the config has been initialized.
-- @realm shared
-- @usage function PLUGIN:InitializedConfig()
--     ix.config.Add("myConfig", true, "Whether or not my config is enabled.")
-- end
function InitializedConfig()
end

--- Called after all the plugins have been initialized.
-- @realm shared
-- @usage function PLUGIN:InitializedPlugins()
--     print("All plugins have been initialized!")
-- end
function InitializedPlugins()
end

--- Called after the schema has been initialized.
-- @realm shared
-- @usage function PLUGIN:InitializedSchema()
--     print("The schema has been initialized!")
-- end
function InitializedSchema()
end

--- Called when an item was added to the inventory.
-- @realm server
-- @tab oldInv Previous item inventory
-- @tab inventory New item inventory
-- @tab item Item that was added to the inventory
function InventoryItemAdded(oldInv, inventory, item)
end

--- Called when an item was removed from the inventory.
-- @realm server
-- @tab inventory Inventory from which item was removed
-- @tab item Item that was removed from the inventory
function InventoryItemRemoved(inventory, item)
end

--- @realm shared
function IsCharacterRecognized(character, id)
end

--- @realm client
function IsPlayerRecognized(client)
end

--- @realm client
function IsRecognizedChatType(chatType)
end

--- Called when server is loading data.
-- @realm server
-- @usage function PLUGIN:LoadData()
--     print("Loading data...")
-- end
function LoadData()
end

--- Called when the client is loading fonts.
-- @realm client
-- @string font Font to load from the config
-- @string genericFont Generic font to load from the config
-- @usage function PLUGIN:LoadFonts(font, genericFont)
--     surface.CreateFont("ixBigFont", {
--         font = font,
--         extended = true,
--         size = 32,
--         weight = 700
--     })
-- end
function LoadFonts(font, genericFont)
end

--- Called when the client is loading the intro for the first time.
-- @realm client
-- @usage function PLUGIN:LoadIntro()
--     print("Loading the intro for the first time!")
-- end
function LoadIntro()
end

--- @realm client
function MenuSubpanelCreated(subpanelName, panel)
end

--- @realm client
function MessageReceived(client, info)
end

--- @realm client
function OnAreaChanged(oldID, newID)
end

--- @realm shared
function OnCharacterCreated(client, character)
end

--- Called when a player who uses a character has disconnected.
-- @realm server
-- @player client The player that has disconnected
-- @char character The character that the player was using
function OnCharacterDisconnect(client, character)
end

--- Called when a character was ragdolled or unragdolled.
-- @realm server
-- @player client Player that was ragdolled or unradolled
-- @entity entity Ragdoll that represents the player
-- @bool bFallenOver Whether or not the character was ragdolled or unragdolled
function OnCharacterFallover(client, entity, bFallenOver)
end

--- Called when a character has gotten up from the ground.
-- @realm server
-- @player client Player that has gotten up
-- @entity ragdoll Ragdoll used to represent the player
function OnCharacterGetup(client, ragdoll)
end

--- @realm client
function OnCharacterMenuCreated(panel)
end

--- Called whenever an item entity has spawned in the world. You can access the entity's item table with
-- `entity:GetItemTable()`.
-- @realm server
-- @entity entity Spawned item entity
-- @usage function PLUGIN:OnItemSpawned(entity)
--     local item = entity:GetItemTable()
--     -- do something with the item here
-- end
function OnItemSpawned(entity)
end

--- Called when an item was transferred from one inventory to another.
-- @realm shared
-- @item item Item that was transferred
-- @tab curInv Current inventory
-- @tab inventory Inventory that item was transferred to
-- @usage function PLUGIN:OnItemTransferred(item, curInv, inventory)
--     print("Item "..item:GetName().." was transferred to "..inventory:GetOwner():Name())
-- end
function OnItemTransferred(item, curInv, inventory)
end

--- @realm client
function OnLocalVarSet(key, var)
end

--- @realm client
function OnPAC3PartTransferred(part)
end

--- Called when a player has picked up the money from the ground.
-- @realm server
-- @player client Player that picked up the money
-- @entity self Money entity
-- @treturn bool Whether or not to allow the player to pick up the money
-- @usage function PLUGIN:OnPickupMoney(client, self)
--     return false -- Disallow picking up money.
-- end
function OnPickupMoney(client, self)
end

--- Called when a player moved to a new area.
-- @realm shared
-- @player client Player that moved to a new area
-- @number oldID ID of the old area
-- @number newID ID of the new area
-- @usage function PLUGIN:OnPlayerAreaChanged(client, oldID, newID)
--     client:Notify("You have moved to "..newID..".")
-- end
function OnPlayerAreaChanged(client, oldID, newID)
end

--- Called when a player has entered or exited the observer mode.
-- @realm server
-- @player client Player that entered or exited the observer mode
-- @bool state Previous observer state
-- @usage function PLUGIN:OnPlayerObserve(client, state)
--     client:Notify(state and "You have entered observer mode." or "You have exited observer mode.")
-- end
function OnPlayerObserve(client, state)
end

--- Called when a player has selected the entity interaction menu option while interacting with a player.
-- @realm server
-- @player client Player that other player has interacted with
-- @player callingClient Player that has interacted with with other player
-- @string option Option that was selected
function OnPlayerOptionSelected(client, callingClient, option)
end

--- Called when a player has purchased or sold a door.
-- @realm server
-- @player client Player that has purchased or sold a door
-- @entity entity Door that was purchased or sold
-- @bool bBuying Whether or not the player is bying a door
-- @func bCallOnDoorChild Function to call something on the door child
-- @usage function PLUGIN:OnPlayerPurchaseDoor(client, entity, bBuying, bCallOnDoorChild)
--     client:Notify("You have "..(bBuying and "purchased" or "sold").." a door.")
-- end
function OnPlayerPurchaseDoor(client, entity, bBuying, bCallOnDoorChild)
end

--- Called when a player was restricted.
-- @realm server
-- @player client Player that was restricted
-- @usage function PLUGIN:OnPlayerRestricted(client)
--     client:Kick("You have been restricted.")
-- end
function OnPlayerRestricted(client)
end

--- Called when a player was unrestricted.
-- @realm server
-- @player client Player that was unrestricted
-- @usage function PLUGIN:OnPlayerUnRestricted(client)
--     client:Notify("You have been unrestricted.")
-- end
function OnPlayerUnRestricted(client)
end

--- Called when a saved items were loaded.
-- @realm server
-- @tab loadedItems Table of items that were loaded
function OnSavedItemLoaded(loadedItems)
end

--- Called when server database are being wiped.
-- @realm server
function OnWipeTables()
end

-- Called when a player has entered a sequence.
-- @realm shared
-- @player client Player that has entered a sequence
-- @string sequence Sequence that player has entered
-- @param callback Callback function
-- @param time Time of the sequence
-- @param bNoFreeze Whether or not to freeze the player
-- @usage function PLUGIN:PlayerEnterSequence(client, sequence, callback, time, bNoFreeze)
--     if (CLIENT) then
--         client:Notify("You have entered a sequence.")
--     end
-- end
function PlayerEnterSequence(client, sequence, callback, time, bNoFreeze)
end

--- Called when a player has interacted with an entity through the entity's interaction menu.
-- @realm server
-- @player client Player that performed interaction
-- @entity entity Entity being interacted with
-- @string option Option selected by the player
-- @param data Any data passed with the interaction option
function PlayerInteractEntity(client, entity, option, data)
end

--- Called when a player has interacted with an item.
-- @realm server
-- @player client Player that interacted with an item
-- @string action Action selected by the player
-- @tab item Item being interacted with
function PlayerInteractItem(client, action, item)
end

--- Called when a player has joined a class.
-- @realm server
-- @player client Player that has joined a class
-- @number class Index of the class player has joined to
-- @number oldClass Index of the player's previous class
function PlayerJoinedClass(client, class, oldClass)
end

--- Called when a player leaves a certain sequence.
-- @realm server
-- @player client Player that has left a sequence
-- @usage function PLUGIN:PlayerLeaveSequence(client)
--     client:Notify("You have left the sequence.")
-- end
function PlayerLeaveSequence(client)
end

--- Called when a player has loaded a character.
-- @realm server
-- @player client Player that has loaded a character
-- @char character Character that was loaded
-- @char currentChar Character that player was using
-- @usage function PLUGIN:PlayerLoadedCharacter(client, character, currentChar)
--     client:Notify("Welcome back, "..character:GetName().."!")
-- end
function PlayerLoadedCharacter(client, character, currentChar)
end

--- Called when a player has locked a door.
-- @realm server
-- @player client Player that has locked a door
-- @entity door Door that was locked
-- @entity partner Door partner
function PlayerLockedDoor(client, door, partner)
end

--- Called when a player has locked a vehicle.
-- @realm server
-- @player client Player that has locked a vehicle
-- @entity vehicle Vehicle that was locked
function PlayerLockedVehicle(client, vehicle)
end

--- Called when player has said something in the text chat.
-- @realm server
-- @player speaker Player that has said something in the text chat
-- @string chatType Type of the chat that player used
-- @string text Chat message that player send
-- @bool anonymous Whether or not message was anonymous
-- @tab receivers Players who will hear that message
-- @string rawText Chat message without any formatting
-- @treturn string You can return text that will be shown instead
-- @usage function PLUGIN:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
--  return "Text" -- When a player writes something into chat, he will say "Text" instead.
-- end
function PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
end

--- Called when a player model was changed.
-- @realm server
-- @player client Player whose model was changed
-- @string oldModel Old player model
function PlayerModelChanged(client, oldModel)
end

--- Called when a player has got stamina.
-- @realm server
-- @player client Player who has got stamina
function PlayerStaminaGained(client)
end

--- Called when a player has lost stamina.
-- @realm server
-- @player client Player who has lost stamina
function PlayerStaminaLost(client)
end

--- @realm shared
function PlayerThrowPunch(client, trace)
end

--- Called when a player has unlocked a door.
-- @realm server
-- @player client Player that has unlocked a door
-- @entity door Door that was unlocked
-- @entity partner Door partner
function PlayerUnlockedDoor(client, door, partner)
end

--- Called when a player has unlocked a vehicle.
-- @realm server
-- @player client Player that has unlocked a vehicle
-- @entity vehicle Vehicle that was unlocked
function PlayerUnlockedVehicle(client, vehicle)
end

--- Called when a player has used an entity.
-- @realm server
-- @player client Player who has used an entity
-- @entity entity Entity that was used by the player
function PlayerUse(client, entity)
end

--- Called when a player has used a door.
-- @realm server
-- @player client Player who has used a door
-- @entity entity Door that was used by the player
function PlayerUseDoor(client, entity)
end

--- @realm shared
function PlayerWeaponChanged(client, weapon)
end

--- Called before the player's data is about to be loaded
-- @realm server
-- @player client Player that is about to load data
-- @usage function PLUGIN:PrePlayerDataLoaded(client)
--     print("Player "..client:Name().." is about to load data.")
-- end
function PrePlayerDataLoaded(client)
end

--- Called when a player's data is about to be loaded.
-- @realm server
-- @player client Player that is about to load data
-- @usage function PLUGIN:PlayerDataLoaded(client)
--     print("Player "..client:Name().." is about to load data.")
-- end
-- @internal
function PlayerDataLoaded(client)
end

--- Called after the player's data is fully loaded.
-- @realm server
-- @player client Player that has loaded data
-- @usage function PLUGIN:PostPlayerDataLoaded(client)
--     print("Player "..client:Name().." has loaded data.")
-- end
function PostPlayerDataLoaded(client)
end

--- @realm shared
function PluginShouldLoad(uniqueID)
end

--- @realm shared
function PluginUnloaded(uniqueID)
end

--- @realm client
function PopulateCharacterInfo(client, character, tooltip)
end

--- @realm client
function PopulateEntityInfo(entity, tooltip)
end

--- @realm client
function PopulateHelpMenu(categories)
end

--- @realm client
function PopulateImportantCharacterInfo(entity, character, tooltip)
end

--- @realm client
function PopulateItemTooltip(tooltip, item)
end

--- @realm client
function PopulatePlayerTooltip(client, tooltip)
end

--- @realm client
function PopulateScoreboardPlayerMenu(client, menu)
end

--- @realm client
function PostChatboxDraw(width, height, alpha)
end

--- @realm client
function PostDrawHelixModelView(panel, entity)
end

--- @realm client
function PostDrawInventory(panel)
end

--- Called when server data was loaded.
-- @realm server
-- @usage function PLUGIN:PostLoadData()
--     print("Data has been loaded.")
-- end
function PostLoadData()
end

--- Called after player loadout.
-- @realm server
-- @player client
-- @usage function PLUGIN:PostPlayerLoadout(client)
--     client:StripWeapon("ix_keys") -- Strip keys from player loadout.
-- end
function PostPlayerLoadout(client)
end

--- Called after player has said something in the text chat.
-- @realm server
-- @player client Player that has said something in the text chat
-- @string chatType Type of the chat that player used
-- @string message Chat message that player send
-- @bool anonymous Whether or not message was anonymous
function PostPlayerSay(client, chatType, message, anonymous)
end

--- @realm shared
function PostSetupActs()
end

--- Called before character deletion.
-- @realm server
-- @player client Character owner
-- @char character Chraracter that will be deleted
function PreCharacterDeleted(client, character)
end

--- Called before character loading.
-- @realm server
-- @player client Player that loading a character
-- @char character Character that will be loaded
-- @char currentChar Character that player is using
function PrePlayerLoadedCharacter(client, character, currentChar)
end

--- Called before a message sent by a player is processed to be sent to other players - i.e this is ran as early as possible
-- and before things like the auto chat formatting. Can be used to prevent the message from being sent at all.
-- @realm server
-- @player client Player sending the message
-- @string chatType Chat class of the message
-- @string message Contents of the message
-- @bool bAnonymous Whether or not the player is sending the message anonymously
-- @treturn bool Whether or not to prevent the message from being sent
-- @usage function PLUGIN:PrePlayerMessageSend(client, chatType, message, bAnonymous)
--     if (!client:IsAdmin()) then
--         return false -- only allow admins to talk in chat
--     end
-- end
function PrePlayerMessageSend(client, chatType, message, bAnonymous)
end

--- Called when server is saving data.
-- @realm server
-- @usage function PLUGIN:SaveData()
--     for k, v in player.Iterator() do
--         ix.util.Notify(v, "The server's data has been saved.")
--     end
-- end
function SaveData()
end

--- Called whenever the client changed their screen resolution.
-- @realm client
-- @number width New screen width
-- @number height New screen height
-- @usage function PLUGIN:ScreenResolutionChanged(width, height)
--     print("Screen resolution changed to "..width.."x"..height)
-- end
function ScreenResolutionChanged(width, height)
end

--- @realm shared
function SetupActs()
end

--- @realm shared
function SetupAreaProperties()
end

--- Called when a player has taken a shipment item.
-- @realm server
-- @player client Player that has taken a shipment item
-- @string uniqueID UniqueID of the shipment item that was taken
-- @number amount Amount of the items that were taken
function ShipmentItemTaken(client, uniqueID, amount)
end

--- Wether or not a specific bar of the hud should be drawn.
-- @realm client
-- @number bar Bar ID
-- @treturn bool Whether or not the bar should be drawn
-- @usage function PLUGIN:ShouldBarDraw(bar)
--     return bar == "stm" -- Only draw the stamina bar.
-- end
function ShouldBarDraw(bar)
end

--- Whether or not the server should delete saved items.
-- @realm server
-- @treturn bool Whether or not the server should delete saved items
-- @usage function PLUGIN:ShouldDeleteSavedItems()
--  return true -- Delete all saved items.
-- end
function ShouldDeleteSavedItems()
end

--- Whether or not the area should be displayed when entering it.
-- @realm client
-- @number newID ID of the new area
-- @treturn bool Whether or not the area should be displayed
-- @usage function PLUGIN:ShouldDisplayArea(newID)
--     return newID == 1 -- Only display area 1.
-- end
function ShouldDisplayArea(newID)
end

--- Whether or not the crosshair should be drawn.
-- @realm client
-- @player client Player that the crosshair is being drawn for
-- @entity weapon Weapon that the crosshair is being drawn for
-- @treturn bool Whether or not the crosshair should be drawn
-- @usage function PLUGIN:ShouldDrawCrosshair(client, weapon)
--     return client:IsAdmin() -- Only draw crosshair for admins.
-- end
function ShouldDrawCrosshair(client, weapon)
end

--- @realm client
function ShouldDrawItemSize(item)
end

--- Wehther or not the hud bars should be hidden.
-- @realm client
-- @treturn bool Whether or not the hud bars should be hidden
-- @usage function PLUGIN:ShouldHideBars()
--     return true -- Hide all hud bars.
-- end
function ShouldHideBars()
end

--- Whether or not a character should be permakilled upon death. This is only called if the `permakill` server config is
-- enabled.
-- @realm server
-- @player client Player to permakill
-- @char character Player's current character
-- @entity inflictor Entity that inflicted the killing blow
-- @entity attacker Other player or entity that killed the player
-- @treturn bool `false` if the player should not be permakilled
-- @usage function PLUGIN:ShouldPermakillCharacter(client, character, inflictor, attacker)
--         if (client:IsAdmin()) then
--             return false -- all non-admin players will have their character permakilled
--         end
--     end
function ShouldPermakillCharacter(client, character, inflictor, attacker)
end

--- Whether or not player should drown.
-- @realm server
-- @player client Player that is underwater
-- @treturn bool Whether or not player should drown
-- @usage function PLUGIN:ShouldPlayerDrowned(client)
--  return false -- Players will not drown.
-- end
function ShouldPlayerDrowned(client)
end

--- Whether or not remove player ragdoll on death.
-- @realm server
-- @player client Player that died
-- @treturn bool Whether or not remove player ragdoll on death
-- @usage function PLUGIN:ShouldRemoveRagdollOnDeath(client)
--  return false -- Player ragdolls will not be removed.
-- end
function ShouldRemoveRagdollOnDeath(client)
end

--- Whether or not to restore character inventory.
-- @realm server
-- @number characterID ID of the character
-- @number inventoryID ID of the inventory
-- @string inventoryType Type of the inventory
-- @treturn bool Whether or not to restore character inventory
-- @usage function PLUGIN:ShouldRestoreInventory(characterID, inventoryID, inventoryType)
--  return false -- Character inventories will not be restored.
-- end
function ShouldRestoreInventory(characterID, inventoryID, inventoryType)
end

--- Whether or not to show the player on the scoreboard.
-- @realm client
-- @player client Player to show on the scoreboard
-- @treturn bool Whether or not to show the player on the scoreboard
-- @usage function PLUGIN:ShouldShowPlayerOnScoreboard(client)
--  return !client:IsAdmin() -- Admins will not be shown on the scoreboard, but regular players will.
-- end
function ShouldShowPlayerOnScoreboard(client)
end

--- Whether or not spawn player ragdoll on death.
-- @realm server
-- @player client Player that died
-- @treturn bool Whether or not spawn player ragdoll on death
-- @usage function PLUGIN:ShouldSpawnClientRagdoll(client)
--  return false -- Player ragdolls will not be spawned.
-- end
function ShouldSpawnClientRagdoll(client)
end

--- @realm client
function ShowEntityMenu(entity)
end

--- Called whenever thirdperson has either been enabled or disabled.
-- @realm client
-- @bool oldValue Old value of thirdperson
-- @bool value New value of thirdperson
-- @usage function PLUGIN:ThirdPersonToggled(oldValue, value)
--     print("Thirdperson has been toggled from "..tostring(oldValue).." to "..tostring(value))
-- end
function ThirdPersonToggled(oldValue, value)
end

--- @realm client
function UpdateCharacterInfo(panel, character)
end

--- @realm client
function UpdateCharacterInfoCategory(panel, character)
end

--- Called when the distance on which the voice can be heard was changed.
-- @realm server
-- @number newValue New voice distance
function VoiceDistanceChanged(newValue)
end

--- Able to return a new sound to play when cycling weapons.
-- @realm client
-- @treturn string Sound to play when cycling weapons
-- @usage function PLUGIN:WeaponCycleSound()
--     return "weapons/357/357_spin1.wav" -- Play the 357 spin sound when cycling weapons.
-- end
function WeaponCycleSound()
end

--- Able to return a new sound to play when selecting weapons.
-- @realm client
-- @entity weapon Weapon that is being selected
-- @treturn string Sound to play when selecting weapons
-- @usage function PLUGIN:WeaponSelectSound(weapon)
--     if (weapon:GetClass() == "weapon_physgun") then
--         return "weapons/physcannon/physcannon_charge.wav" -- Play the physgun charge sound when selecting the physgun.
--     end
-- end
function WeaponSelectSound(weapon)
end

--- Runs when a player tries to create a character and checks if the character name is valid.
-- @realm shared
-- @string name Name of the character
-- @treturn bool Whether or not the character name is valid
-- @treturn string|nil Error message if the character name is invalid
-- @usage function PLUGIN:CharacterNameValid(name)
--     if (string.find(name, "badword")) then
--         return false, "Your character name contains a bad word."
--     end
-- end
function IsCharacterNameValid(name)
end

--- Runs when a player tries to create a character and checks if the character description is valid.
-- @realm shared
-- @string description Description of the character
-- @treturn bool Whether or not the character description is valid
-- @usage function PLUGIN:IsCharacterDescriptionValid(description)
--     if (string.find(description, "badword")) then
--         return false
--     end
-- end
function IsCharacterDescriptionValid(description)
end