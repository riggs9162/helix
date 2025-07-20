
--- A library representing the server's currency system.
-- @module ix.currency

ix.currency = ix.currency or {}
ix.currency.symbol = ix.currency.symbol or "$"
ix.currency.singular = ix.currency.singular or "dollar"
ix.currency.plural = ix.currency.plural or "dollars"
ix.currency.model = ix.currency.model or "models/props_lab/box01a.mdl"

--- Sets the currency type.
-- @realm shared
-- @string symbol The symbol of the currency.
-- @string singular The name of the currency in it's singular form.
-- @string plural The name of the currency in it's plural form.
-- @string model The model of the currency entity.
function ix.currency.Set(symbol, singular, plural, model)
    ix.currency.symbol = symbol or ix.currency.symbol
    ix.currency.singular = singular or ix.currency.singular
    ix.currency.plural = plural or ix.currency.plural
    ix.currency.model = model or ix.currency.model
end

--- Returns a formatted string according to the current currency.
-- @realm shared
-- @number amount The amount of cash being formatted.
-- @treturn string The formatted string.
-- @usage ix.currency.Get(1000) -- "$1000"
function ix.currency.Get(amount)
    if (!isnumber(amount)) then
        ErrorNoHaltWithStack("[Helix] Can't get currency: Invalid amount")
        return nil
    end

    if (amount == 1) then
        return ix.currency.symbol .. "1 " .. ix.currency.singular
    else
        return ix.currency.symbol .. amount .. " " .. ix.currency.plural
    end
end

--- Seperates the currency amount with commas.
-- @realm shared
-- @number amount The amount of cash being formatted.
-- @treturn string The formatted string.
-- @usage ix.currency.Format(1000) -- "1,000"
function ix.currency.Format(amount)
    if (!isnumber(amount)) then
        ErrorNoHaltWithStack("[Helix] Can't format currency: Invalid amount")
        return nil
    end

    local formatted = amount

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')

        if (k == 0) then
            break
        end
    end

    return formatted
end

--- Formats the currency amount with the symbol.
-- @realm shared
-- @number amount The amount of cash being formatted.
-- @treturn string The formatted string with the currency symbol.
-- @usage ix.currency.FormatWithSymbol(1000) -- "$1,000"
function ix.currency.FormatWithSymbol(amount)
    local formatted = ix.currency.Format(amount)
    return formatted and (ix.currency.symbol .. formatted) or nil
end

--- Applies a tax to a specified amount.
-- @realm shared
-- @number amount The amount of currency.
-- @number rate The tax rate to apply (in percentage, e.g. 10 for 10%).
-- @treturn number The taxed amount.
-- @usage ix.currency.ApplyTax(100, 10) -- 90
function ix.currency.ApplyTax(amount, rate)
    if (!isnumber(amount) or !isnumber(rate) or rate < 0) then
        ErrorNoHaltWithStack("[Helix] Can't apply tax: Invalid amount or rate")
        return nil
    end

    return amount - (amount * (rate / 100))
end

--- Transfers currency from one character to another.
-- @realm server
-- @char fromChar The character to transfer currency from.
-- @char toChar The character to transfer currency to.
-- @number amount The amount to transfer.
-- @treturn boolean Returns true if the transfer was successful.
-- @usage ix.currency.Transfer(Entity(1), Entity(2), 100) -- true
function ix.currency.Transfer(fromChar, toChar, amount)
    if (!fromChar or !toChar) then
        ErrorNoHaltWithStack("[Helix] Can't transfer currency: Invalid character(s)")
        return false
    end

    if (fromChar:GetMoney() >= amount) then
        fromChar:TakeMoney(amount)
        toChar:GiveMoney(amount)
        return true
    end

    return false
end

if (SERVER) then
    --- Spawns an amount of cash at a specific location on the map.
    -- @realm server
    -- @vector pos The position of the money to be spawned.
    -- @number amount The amount of cash being spawned.
    -- @angle[opt=Angle(0, 0, 0)] angle The angle of the entity being spawned.
    -- @treturn entity The spawned money entity.
    function ix.currency.Spawn(pos, amount, angle)
        if (!amount or amount < 0) then
            print("[Helix] Can't create currency entity: Invalid Amount of money")
            return
        end

        local money = ents.Create("ix_money")
        money:Spawn()

        if (IsValid(pos) and pos:IsPlayer()) then
            pos = pos:GetItemDropPos(money)
        elseif (!isvector(pos)) then
            print("[Helix] Can't create currency entity: Invalid Position")

            money:Remove()
            return
        end

        money:SetPos(pos)
        -- double check for negative.
        money:SetAmount(math.Round(math.abs(amount)))
        money:SetAngles(angle or Angle(0, 0, 0))
        money:Activate()

        return money
    end

    function GM:OnPickupMoney(client, moneyEntity)
        if (IsValid(moneyEntity)) then
            local amount = moneyEntity:GetAmount()
            client:GetCharacter():GiveMoney(amount)
        end
    end
end

do
    local character = ix.meta.character

    function character:HasMoney(amount)
        if (amount < 0) then
            print("Negative Money Check Received.")
        end

        return self:GetMoney() >= amount
    end

    function character:GiveMoney(amount, bNoLog)
        amount = math.abs(amount)

        if (!bNoLog) then
            ix.log.Add(self:GetPlayer(), "money", amount)
        end

        self:SetMoney(self:GetMoney() + amount)

        return true
    end

    function character:TakeMoney(amount, bNoLog)
        amount = math.abs(amount)

        if (!bNoLog) then
            ix.log.Add(self:GetPlayer(), "money", -amount)
        end

        self:SetMoney(self:GetMoney() - amount)

        return true
    end
end
