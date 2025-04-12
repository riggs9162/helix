
local PANEL = {}

function PANEL:Init()
    local entity = ix.gui.vendor.entity

    self:SetSize(ScrW() / 4, ScrH() / 2)
    self:SetX(ScrW() / 4 - self:GetWide() / 2)
    self:CenterVertical()
    self:SetTitle(L"vendorEditor")
    self.lblTitle:SetTextColor(color_white)

    self.name = self:Add("ixTextEntry")
    self.name:Dock(TOP)
    self.name:SetText(entity:GetDisplayName())
    self.name:SetFont("ixSmallTitleFont")
    self.name:SetPlaceholderText(L"name")
    self.name.OnEnter = function(this)
        if (entity:GetDisplayName() != this:GetText()) then
            self:updateVendor("name", this:GetText())
        end
    end

    self.description = self:Add("ixTextEntry")
    self.description:Dock(TOP)
    self.description:DockMargin(0, 4, 0, 0)
    self.description:SetText(entity:GetDescription())
    self.description:SetFont("ixSmallTitleFont")
    self.description:SetPlaceholderText(L"description")
    self.description.OnEnter = function(this)
        if (entity:GetDescription() != this:GetText()) then
            self:updateVendor("description", this:GetText())
        end
    end

    self.model = self:Add("ixTextEntry")
    self.model:Dock(TOP)
    self.model:DockMargin(0, 4, 0, 0)
    self.model:SetText(entity:GetModel())
    self.model:SetFont("ixSmallTitleFont")
    self.model:SetPlaceholderText(L"model")
    self.model.OnEnter = function(this)
        if (entity:GetModel():lower() != this:GetText():lower()) then
            self:updateVendor("model", this:GetText():lower())
        end
    end

    local useMoney = tonumber(entity.money) != nil

    self.money = self:Add("ixTextEntry")
    self.money:Dock(TOP)
    self.money:DockMargin(0, 4, 0, 0)
    self.money:SetText(!useMoney and "∞" or entity.money)
    self.money:SetFont("ixSmallTitleFont")
    self.money:SetPlaceholderText(L"money")
    self.money:SetDisabled(!useMoney)
    self.money:SetEnabled(useMoney)
    self.money:SetNumeric(true)
    self.money.OnEnter = function(this)
        local value = tonumber(this:GetText()) or entity.money

        if (value == entity.money) then return end

        self:updateVendor("money", value)
    end

    self.bubble = self:Add("ixSettingsRowBool")
    self.bubble:SetText(L("vendorNoBubble"))
    self.bubble:Dock(TOP)
    self.bubble:DockMargin(0, 4, 0, 0)
    self.bubble:SetValue(entity:GetNoBubble() and 1 or 0)
    self.bubble.OnValueChanged = function(this, value)
        self:updateVendor("bubble", value)
    end

    self.useMoney = self:Add("ixSettingsRowBool")
    self.useMoney:SetText(L("vendorUseMoney"))
    self.useMoney:Dock(TOP)
    self.useMoney:DockMargin(0, 4, 0, 0)
    self.useMoney:SetValue(useMoney)
    self.useMoney.OnValueChanged = function(this, value)
        self:updateVendor("useMoney")
    end

    self.sellScale = self:Add("ixSettingsRowNumber")
    self.sellScale:Dock(TOP)
    self.sellScale:DockMargin(0, 4, 0, 0)
    self.sellScale:SetText(L("vendorSellScale"))
    self.sellScale:SetDecimals(1)
    self.sellScale:SetValue(entity.scale)
    self.sellScale.OnValueChanged = function(this, value)
        timer.Create("ixVendorScale", 1, 1, function()
            if (IsValid(self) and IsValid(self.sellScale)) then
                value = self.sellScale:GetValue()

                if (value != entity.scale) then
                    self:updateVendor("scale", value)
                end
            end
        end)
    end

    self.faction = self:Add("ixMenuButton")
    self.faction:Dock(TOP)
    self.faction:DockMargin(0, 4, 0, 4)
    self.faction:SetText(L("vendorFaction"))
    self.faction:SizeToContents()
    self.faction.DoClick = function(this)
        if (IsValid(ix.gui.editorFaction)) then
            ix.gui.editorFaction:Remove()
        end

        ix.gui.editorFaction = vgui.Create("ixVendorFactionEditor")
        ix.gui.editorFaction.updateVendor = self.updateVendor
        ix.gui.editorFaction.entity = entity
        ix.gui.editorFaction:Setup()
    end

    self.searchBar = self:Add("ixIconTextEntry")
    self.searchBar:Dock(TOP)
    self.searchBar:SetUpdateOnType(true)
    self.searchBar:SetPlaceholderText("Search...")
    self.searchBar.OnValueChange = function(this, value)
        self:ReloadItemList(value)
    end

    local menu

    self.items = self:Add("ixListView")
    self.items:Dock(FILL)
    self.items:DockMargin(0, 4, 0, 0)
    self.items:AddColumn(L"name").Header:SetTextColor(color_black)
    self.items:AddColumn(L"category").Header:SetTextColor(color_black)
    self.items:AddColumn(L"mode").Header:SetTextColor(color_black)
    self.items:AddColumn(L"price").Header:SetTextColor(color_black)
    self.items:AddColumn(L"stock").Header:SetTextColor(color_black)
    self.items:SetMultiSelect(false)
    self.items.OnRowRightClick = function(this, index, line)
        if (IsValid(menu)) then
            menu:Remove()
        end

        local uniqueID = line.item

        menu = DermaMenu()
            -- Modes of the item.
            local mode, panel = menu:AddSubMenu(L"mode")
            panel:SetImage("icon16/key.png")

            -- Disable buying/selling of the item.
            mode:AddOption(L"none", function()
                self:updateVendor("mode", {uniqueID, nil})
            end):SetImage("icon16/cog_error.png")

            -- Allow the vendor to sell and buy this item.
            mode:AddOption(L"vendorBoth", function()
                self:updateVendor("mode", {uniqueID, VENDOR_SELLANDBUY})
            end):SetImage("icon16/cog.png")

            -- Only allow the vendor to buy this item from players.
            mode:AddOption(L"vendorBuy", function()
                self:updateVendor("mode", {uniqueID, VENDOR_BUYONLY})
            end):SetImage("icon16/cog_delete.png")

            -- Only allow the vendor to sell this item to players.
            mode:AddOption(L"vendorSell", function()
                self:updateVendor("mode", {uniqueID, VENDOR_SELLONLY})
            end):SetImage("icon16/cog_add.png")

            local itemTable = ix.item.list[uniqueID]

            -- Set the price of the item.
            menu:AddOption(L"price", function()
                Derma_StringRequest(
                    itemTable.GetName and itemTable:GetName() or L(itemTable.name),
                    L"vendorPriceReq",
                    entity:GetPrice(uniqueID),
                    function(text)
                        text = tonumber(text)

                        if (text == itemTable.price) then
                            text = nil
                        end

                        self:updateVendor("price", {uniqueID, text})
                    end
                )
            end):SetImage("icon16/coins.png")

            -- Set the stock of the item or disable it.
            local stock, menuPanel = menu:AddSubMenu(L"stock")
            menuPanel:SetImage("icon16/table.png")

            -- Disable the use of stocks for this item.
            stock:AddOption(L"disable", function()
                self:updateVendor("stockDisable", uniqueID)
            end):SetImage("icon16/table_delete.png")

            -- Edit the maximum stock for this item.
            stock:AddOption(L"edit", function()
                local _, max = entity:GetStock(uniqueID)

                Derma_StringRequest(
                    itemTable.GetName and itemTable:GetName() or L(itemTable.name),
                    L"vendorStockReq",
                    max or 1,
                    function(text)
                        self:updateVendor("stockMax", {uniqueID, text})
                    end
                )
            end):SetImage("icon16/table_edit.png")

            -- Edit the current stock of this item.
            stock:AddOption(L"vendorEditCurStock", function()
                Derma_StringRequest(
                    itemTable.GetName and itemTable:GetName() or L(itemTable.name),
                    L"vendorStockCurReq",
                    entity:GetStock(uniqueID) or 0,
                    function(text)
                        self:updateVendor("stock", {uniqueID, text})
                    end
                )
            end):SetImage("icon16/table_edit.png")
        menu:Open()
    end

    self:ReloadItemList()
    self:MakePopup()
end

function PANEL:ReloadItemList(filter)
    local entity = ix.gui.vendor.entity
    self.lines = {}

    self.items:Clear()

    for k, v in SortedPairs(ix.item.list) do
        local itemName = v.GetName and v:GetName() or L(v.name)

        if (filter and !itemName:lower():find(filter:lower(), 1, false)) then continue end

        local mode = entity.items[k] and entity.items[k][VENDOR_MODE]
        local current, max = entity:GetStock(k)
        local panel = self.items:AddLine(
            itemName,
            v.category or L"none",
            mode and L(VENDOR_TEXT[mode]) or L"none",
            entity:GetPrice(k),
            max and current.."/"..max or "-"
        )

        panel.item = k
        self.lines[k] = panel
    end
end

function PANEL:OnRemove()
    if (IsValid(ix.gui.vendor)) then
        ix.gui.vendor:Remove()
    end

    if (IsValid(ix.gui.editorFaction)) then
        ix.gui.editorFaction:Remove()
    end
end

function PANEL:updateVendor(key, value)
    net.Start("ixVendorEdit")
        net.WriteString(key)
        net.WriteType(value)
    net.SendToServer()
end

vgui.Register("ixVendorEditor", PANEL, "DFrame")
