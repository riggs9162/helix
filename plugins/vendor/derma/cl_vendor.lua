
local animationTime = 1
local matrixZScale = Vector(1, 1, 0.0001)
local backgroundColor = Color(0, 0, 0, 66)

DEFINE_BASECLASS("ixSubpanelParent")
local PANEL = {}

AccessorFunc(PANEL, "bReadOnly", "ReadOnly", FORCE_BOOL)

function PANEL:Init()
    if (IsValid(ix.gui.vendor)) then
        ix.gui.vendor:Remove()
    end

    self.currentAlpha = 0
    self.currentBlur = 0
    self.bSettingUp = true
    self.anchorMode = true
    self.noAnchor = CurTime() + 0.5
    self.bClosing = false

    self:SetPadding(ScreenScale(32), true)
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)

    local header = self:Add("EditablePanel")
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, 8)

    local configColor = ix.config.Get("color")

    self.vendorName = header:Add("DLabel")
    self.vendorName:Dock(LEFT)
    self.vendorName:SetWide(self:GetWide() / 2 - self:GetPadding() - 4)
    self.vendorName:SetText("John Doe")
    self.vendorName:SetTextColor(configColor)
    self.vendorName:SetFont("ixSubTitleFont")
    self.vendorName:SetContentAlignment(5)
    self.vendorName:SizeToContentsY()
    self.vendorName:SetMouseInputEnabled(false)

    self.ourName = header:Add("DLabel")
    self.ourName:Dock(RIGHT)
    self.ourName:SetWide(self:GetWide() / 2 - self:GetPadding() - 4)
    self.ourName:SetText(L("you") .. " (" .. ix.currency.Get(LocalPlayer():GetCharacter():GetMoney()) .. ")")
    self.ourName:SetTextColor(configColor)
    self.ourName:SetFont("ixSubTitleFont")
    self.ourName:SetContentAlignment(5)
    self.ourName:SizeToContentsY()
    self.ourName:SetMouseInputEnabled(false)

    header:SetTall(math.max(self.vendorName:GetTall(), self.ourName:GetTall()))

    local footer = self:Add("EditablePanel")
    footer:Dock(BOTTOM)
    footer:DockMargin(0, 8, 0, 0)
    footer:SetTall(ScreenScale(16))

    self.vendorSell = footer:Add("ixMenuButton")
    self.vendorSell:SetWide(self.vendorName:GetWide())
    self.vendorSell:Dock(LEFT)
    self.vendorSell:DockMargin(0, 0, 4, 0)
    self.vendorSell:SetContentAlignment(5)
    self.vendorSell:SetText(L("purchase"))
    self.vendorSell.DoClick = function(this)
        if (IsValid(self.activeSell)) then
            net.Start("ixVendorTrade")
                net.WriteString(self.activeSell.item)
                net.WriteBool(false)
            net.SendToServer()
        end
    end

    self.vendorBuy = footer:Add("ixMenuButton")
    self.vendorBuy:SetWide(self.ourName:GetWide())
    self.vendorBuy:Dock(RIGHT)
    self.vendorBuy:DockMargin(4, 0, 0, 0)
    self.vendorBuy:SetContentAlignment(5)
    self.vendorBuy:SetText(L("sell"))
    self.vendorBuy.DoClick = function(this)
        if (IsValid(self.activeBuy)) then
            net.Start("ixVendorTrade")
                net.WriteString(self.activeBuy.item)
                net.WriteBool(true)
            net.SendToServer()
        end
    end

    self.selling = self:Add("DScrollPanel")
    self.selling:SetWide(self:GetWide() / 2 - self:GetPadding() - 4)
    self.selling:Dock(LEFT)
    self.selling.Paint = function(this, width, height)
        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(0, 0, width, height)
    end

    self.sellingItems = self.selling:Add("DListLayout")
    self.sellingItems:SetSize(self.selling:GetSize())
    self.sellingItems:DockPadding(0, 0, 0, 4)
    self.sellingItems:SetTall(ScrH())

    self.buying = self:Add("DScrollPanel")
    self.buying:SetWide(self:GetWide() / 2 - self:GetPadding() - 4)
    self.buying:Dock(RIGHT)
    self.buying.Paint = function(this, width, height)
        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(0, 0, width, height)
    end

    self.buyingItems = self.buying:Add("DListLayout")
    self.buyingItems:SetSize(self.buying:GetSize())
    self.buyingItems:DockPadding(0, 0, 0, 4)

    self.sellingList = {}
    self.buyingList = {}

    self.sellingButtons = {}
    self.buyingButtons = {}

    self:ShowBackground()

    self:MakePopup()
    self:OnOpened()
end

function PANEL:OnOpened()
    self:SetAlpha(0)

    self:CreateAnimation(animationTime, {
        target = {currentAlpha = 255},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetAlpha(panel.currentAlpha)
        end
    })
end

function PANEL:HideBackground()
    self:CreateAnimation(animationTime, {
        index = 2,
        target = {currentBlur = 0},
        easing = "outQuint"
    })
end

function PANEL:ShowBackground()
    self:CreateAnimation(animationTime, {
        index = 2,
        target = {currentBlur = 1},
        easing = "outQuint"
    })
end

function PANEL:OnKeyCodePressed(key)
    self.noAnchor = CurTime() + 0.5

    if (key == KEY_TAB) then
        self:Remove()
    end
end

function PANEL:addItem(uniqueID, listID)
    local entity = self.entity
    local items = entity.items
    local data = items[uniqueID]

    if ((!listID or listID == "selling") and !IsValid(self.sellingList[uniqueID])
    and ix.item.list[uniqueID]) then
        if (data and data[VENDOR_MODE] and data[VENDOR_MODE] != VENDOR_BUYONLY) then
            local item = self.sellingItems:Add("ixVendorItem")
            item:SetButtonList(self.sellingButtons)
            item:Setup(uniqueID)

            self.sellingList[uniqueID] = item
            self.sellingItems:InvalidateLayout()
        end
    end

    if ((!listID or listID == "buying") and !IsValid(self.buyingList[uniqueID])
    and LocalPlayer():GetCharacter():GetInventory():HasItem(uniqueID)) then
        if (data and data[VENDOR_MODE] and data[VENDOR_MODE] != VENDOR_SELLONLY) then
            local item = self.buyingItems:Add("ixVendorItem")
            item:SetButtonList(self.buyingButtons)
            item:Setup(uniqueID)
            item.isLocal = true

            self.buyingList[uniqueID] = item
            self.buyingItems:InvalidateLayout()
        end
    end
end

function PANEL:removeItem(uniqueID, listID)
    if (!listID or listID == "selling") then
        if (IsValid(self.sellingList[uniqueID])) then
            self.sellingList[uniqueID]:Remove()
            self.sellingItems:InvalidateLayout()
        end
    end

    if (!listID or listID == "buying") then
        if (IsValid(self.buyingList[uniqueID])) then
            self.buyingList[uniqueID]:Remove()
            self.buyingItems:InvalidateLayout()
        end
    end
end

function PANEL:Setup(entity)
    self.entity = entity
    --self:SetTitle(entity:GetDisplayName())
    self.vendorName:SetText(entity:GetDisplayName()..(entity.money and " ("..entity.money..")" or ""))

    self.vendorBuy:SetEnabled(!self:GetReadOnly())
    self.vendorSell:SetEnabled(!self:GetReadOnly())

    for k, _ in SortedPairs(entity.items) do
        self:addItem(k, "selling")
    end

    for _, v in SortedPairs(LocalPlayer():GetCharacter():GetInventory():GetItems()) do
        self:addItem(v.uniqueID, "buying")
    end

    self.bSettingUp = false
end

function PANEL:Think()
    local entity = self.entity
    if (!IsValid(entity) and !self.bSettingUp) then
        BaseClass.Remove(self)
        return
    end

    if (self.bClosing) then return end

    local bTabDown = input.IsKeyDown(KEY_TAB)
    if (bTabDown and (self.noAnchor or CurTime() + 0.4) < CurTime() and self.anchorMode) then
        self.anchorMode = false
        surface.PlaySound("buttons/lightswitch2.wav")
    end

    if ((!self.anchorMode and !bTabDown) or gui.IsGameUIVisible()) then
        self:Remove()
    end

    if ((self.nextUpdate or 0) < CurTime()) then
        -- self:SetTitle(self.entity:GetDisplayName())
        self.vendorName:SetText(entity:GetDisplayName()..(entity.money and " ("..ix.currency.Get(entity.money)..")" or ""))
        self.ourName:SetText(L"you".." ("..ix.currency.Get(LocalPlayer():GetCharacter():GetMoney())..")")

        self.nextUpdate = CurTime() + 0.25
    end
end

function PANEL:OnItemSelected(panel)
    local price = self.entity:GetPrice(panel.item, panel.isLocal)

    if (panel.isLocal) then
        self.vendorBuy:SetText(L"sell".." ("..ix.currency.Get(price)..")")
    else
        self.vendorSell:SetText(L"purchase".." ("..ix.currency.Get(price)..")")
    end
end

function PANEL:Paint(width, height)
    derma.SkinFunc("PaintMenuBackground", self, width, height, self.currentBlur)

    local bShouldScale = self.currentAlpha != 255
    if (bShouldScale) then
        local currentScale = Lerp(self.currentAlpha / 255, 0.9, 1)
        local matrix = Matrix()

        matrix:Scale(matrixZScale * currentScale)
        matrix:Translate(Vector(
            ScrW() / 2 - (ScrW() * currentScale / 2),
            ScrH() / 2 - (ScrH() * currentScale / 2),
            1
        ))

        cam.PushModelMatrix(matrix)
    end

    BaseClass.Paint(self, width, height)

    if (bShouldScale) then
        cam.PopModelMatrix()
    end
end

function PANEL:Remove()
    self.bClosing = true
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    CloseDermaMenus()
    gui.EnableScreenClicker(false)

    net.Start("ixVendorClose")
    net.SendToServer()

    if (IsValid(ix.gui.vendorEditor)) then
        ix.gui.vendorEditor:Remove()
    end

    self:CreateAnimation(animationTime / 2, {
        index = 2,
        target = {currentBlur = 0},
        easing = "outQuint"
    })

    self:CreateAnimation(animationTime / 2, {
        target = {currentAlpha = 0},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetAlpha(panel.currentAlpha)
        end,

        OnComplete = function(animation, panel)
            BaseClass.Remove(panel)
        end
    })
end

vgui.Register("ixVendor", PANEL, "ixSubpanelParent")

PANEL = {}

function PANEL:Init()
    self:SetContentAlignment(4)

    self.icon = self:Add("ixSpawnIcon")
    self.icon:Dock(LEFT)
    self.icon:SetModel("models/error.mdl")
    self.icon:SetMouseInputEnabled(false)
end

function PANEL:DoClick()
    if (self.isLocal) then
        ix.gui.vendor.activeBuy = self
    else
        ix.gui.vendor.activeSell = self
    end

    ix.gui.vendor:OnItemSelected(self)
end

function PANEL:Setup(uniqueID)
    local item = ix.item.list[uniqueID]
    if (item) then
        self.item = uniqueID
        self.icon:SetModel(item:GetModel(), item:GetSkin())
        self:SetText(item:GetName())
        self:SizeToContents()
        self:SetTall(self:GetTall() + 4)
        self.icon:SetSize(self:GetTall(), self:GetTall())
        self:SetTextInset(self.icon:GetWide() + 4, 0)
        self.itemName = item:GetName()

        self:SetHelixTooltip(function(tooltip)
            ix.hud.PopulateItemTooltip(tooltip, item)

            local entity = ix.gui.vendor.entity
            if (entity and entity.items[self.item] and entity.items[self.item][VENDOR_MAXSTOCK]) then
                local info = entity.items[self.item]
                local stock = tooltip:AddRowAfter("name", "stock")
                stock:SetText(string.format("Stock: %d/%d", info[VENDOR_STOCK], info[VENDOR_MAXSTOCK]))
                stock:SetBackgroundColor(derma.GetColor("Info", self))
                stock:SizeToContents()
            end
        end)
    end
end

function PANEL:Think()
    if ((self.nextUpdate or 0) < CurTime()) then
        local entity = ix.gui.vendor.entity
        if (entity and self.isLocal) then
            local count = LocalPlayer():GetCharacter():GetInventory():GetItemCount(self.item)
            if (count == 0) then
                self:Remove()
            end
        end

        self.nextUpdate = CurTime() + 0.1
    end
end

vgui.Register("ixVendorItem", PANEL, "ixMenuSelectionButton")

if (IsValid(ix.gui.vendor)) then
    ix.gui.vendor:Remove()
end