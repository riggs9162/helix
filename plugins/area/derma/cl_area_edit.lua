
local PLUGIN = PLUGIN
local PANEL = {}
local padding = ScreenScale(16)

function PANEL:Init()
    if (IsValid(ix.gui.areaEdit)) then
        ix.gui.areaEdit:Remove()
    end

    ix.gui.areaEdit = self

    self:SetSize(ScrW() / 3, ScrH())
    self:SetPos(-self:GetWide(), 0)
    self:DockPadding(padding, padding, padding, padding)
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)

    self.list = {}
    self.properties = {}

    self.currentAlpha = 0
    self.currentX = -self:GetWide()

    -- scroll panel
    self.canvas = self:Add("DScrollPanel")
    self.canvas:Dock(FILL)

    -- name entry
    self.nameEntry = self.canvas:Add("ixSettingsRowString")
    self.nameEntry:SetText(L("name"))
    self.nameEntry:SetValue(L("areaNew"))
    self.nameEntry:Dock(TOP)
    self.nameEntry:DockMargin(0, 0, 0, 8)

    -- type entry
    self.typeEntry = self.canvas:Add("ixSettingsRowArray")
    self.typeEntry:Dock(TOP)
    self.typeEntry:DockMargin(0, 0, 0, 8)
    self.typeEntry:SetText(L("type"))

    local i = 1
    for id, name in pairs(ix.area.types) do
        self.typeEntry.setting:AddChoice(L(name), id, id == "area")
        self.typeEntry.array[id] = i

        i = i + 1
    end

    self.typeEntry.OnValueChanged = function(_, value)
        print(value)
    end

    -- properties
    for k, v in pairs(ix.area.properties) do
        /*
        local panel

        if (v.type == ix.type.string or v.type == ix.type.number) then
            panel = vgui.Create("ixTextEntry")
            panel:SetFont("ixMenuButtonFont")
            panel:SetText(tostring(v.default))
            panel:RequestFocus()

            if (v.type == ix.type.number) then
                panel.realGetValue = panel.GetValue
                panel.GetValue = function()
                    return tonumber(panel:realGetValue()) or v.default
                end
            end
        elseif (v.type == ix.type.bool) then
            panel = vgui.Create("ixCheckBox")
            panel:SetChecked(v.default, true)
            panel:SetTall(ScreenScale(14))
        elseif (v.type == ix.type.color) then
            panel = vgui.Create("ixMenuButton")
            panel.value = v.default
            panel:SetText("")
            panel:SetSize(64, 64)

            panel.picker = vgui.Create("DColorCombo")
            panel.picker:SetColor(panel.value)
            panel.picker:SetVisible(false)
            panel.picker.OnValueChanged = function(_, newColor)
                panel.value = newColor
            end

            panel.Paint = function(_, width, height)
                surface.SetDrawColor(panel.value)
                surface.DrawRect(0, 0, width, height)
            end

            panel.DoClick = function()
                if (!panel.picker:IsVisible()) then
                    local x, y = panel:LocalToScreen(0, 0)

                    panel.picker:SetPos(x, y + 32)
                    panel.picker:SetColor(panel.value)
                    panel.picker:SetVisible(true)
                    panel.picker:MakePopup()
                    panel.picker.OnFocusChanged = function(_, b)
                        if (!b) then
                            panel.picker:SetVisible(false)
                        end
                    end
                else
                    panel.picker:SetVisible(false)
                end
            end

            panel.OnRemove = function()
                panel.picker:Remove()
            end

            panel.GetValue = function()
                return panel.picker:GetColor()
            end
        end

        if (IsValid(panel)) then
            local row = self.canvas:Add("ixListRow")
            row:SetList(self.list)
            row:SetLabelText(L(k))
            row:SetRightPanel(panel)
            row:Dock(TOP)
            row:SizeToContents()
        end
        */

        local panel

        if (v.type == ix.type.string or v.type == ix.type.number) then
            panel = self.canvas:Add("ixSettingsRowString")
            panel:SetText(L(k))
            panel:SetValue(tostring(v.default))

            if (v.type == ix.type.number) then
                panel.realGetValue = panel.GetValue
                panel.GetValue = function()
                    return tonumber(panel:realGetValue()) or v.default
                end
            end
        elseif (v.type == ix.type.bool) then
            panel = self.canvas:Add("ixSettingsRowBool")
            panel:SetText(L(k))
            panel:SetValue(v.default, true)
        elseif (v.type == ix.type.color) then
            panel = self.canvas:Add("ixSettingsRowColor")
            panel:SetText(L(k))
        end

        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 8)

        self.properties[k] = function()
            return panel:GetValue()
        end
    end

    -- save button
    self.saveButton = self:Add("ixMenuButton")
    self.saveButton:SetText(L("save"))
    self.saveButton:SizeToContents()
    self.saveButton:Dock(BOTTOM)
    self.saveButton.DoClick = function()
        self:Submit()
    end

    self:CreateAnimation(0.25, {
        index = 1,
        target = {currentAlpha = 255},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetAlpha(panel.currentAlpha)
        end
    })

    self:CreateAnimation(0.25, {
        index = 2,
        target = {currentX = 0},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetX(panel.currentX)
        end
    })
end

function PANEL:Submit()
    local name = self.nameEntry:GetValue()

    if (ix.area.stored[name]) then
        ix.util.NotifyLocalized("areaAlreadyExists")
        return
    end

    local properties = {}

    for k, v in pairs(self.properties) do
        properties[k] = v()
    end

    local pos = PLUGIN:GetPlayerAreaTrace().HitPos
    local snap = ix.option.Get("areaEditSnap", 8)
    snap = snap == 0 and 0.1 or snap
    pos = Vector(math.Round(pos.x / snap) * snap, math.Round(pos.y / snap) * snap, math.Round(pos.z / snap) * snap)

    net.Start("ixAreaAdd")
        net.WriteString(name)
        net.WriteString(self.typeEntry:GetValue())
        net.WriteVector(PLUGIN.editStart)
        net.WriteVector(pos)
        net.WriteTable(properties)
    net.SendToServer()

    PLUGIN.editStart = nil
    self:Remove()
end

function PANEL:OnRemove()
    PLUGIN.editProperties = nil
end

local gradientLeft = ix.util.GetMaterial("vgui/gradient-l")
function PANEL:Paint(width, height)
    ix.util.DrawBlur(self)

    surface.SetDrawColor(0, 0, 0, 66)
    surface.DrawRect(0, 0, width, height)

    derma.SkinFunc("DrawImportantBackground", 0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 66)
    surface.SetMaterial(gradientLeft)
    surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:OnKeyCodePressed(key)
    if (key == KEY_TAB) then
        self:Remove()
    end
end

DEFINE_BASECLASS("DFrame")

function PANEL:RemoveOld()
    BaseClass.Remove(self)
end

function PANEL:Remove()
    self:CreateAnimation(0.25, {
        index = 1,
        target = {currentAlpha = 0},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetAlpha(panel.currentAlpha)
        end,

        OnComplete = function(animation, panel)
            panel:RemoveOld()
        end
    })

    self:CreateAnimation(0.25, {
        index = 2,
        target = {currentX = -self:GetWide()},
        easing = "outQuint",

        Think = function(animation, panel)
            panel:SetX(panel.currentX)
        end
    })
end

vgui.Register("ixAreaEdit", PANEL, "DFrame")

if (IsValid(ix.gui.areaEdit)) then
    ix.gui.areaEdit:RemoveOld()
end