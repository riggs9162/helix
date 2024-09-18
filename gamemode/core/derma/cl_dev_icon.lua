--Icon Editor Base and Math Scale Functions from: https://github.com/TeslaCloud/flux-ce/tree/master

local scaleFactorX = 1 / 1920
local scaleFactorY = 1 / 1080

local function scale(size)
    return math.floor(size * (ScrH() * scaleFactorY))
end

local function scale_x(size)
    return math.floor(size * (ScrW() * scaleFactorX))
end

/*
local buttonSize = scale(48)

self.model = vgui.Create("DAdjustableModelPanel", self)
self.model:SetSize(pW * 0.5, pH - buttonSize)
self.model:Dock(LEFT)
self.model:DockMargin(0, 0, 0, buttonSize + scale(8))
self.model:SetModel("models/props_borealis/bluebarrel001.mdl")
self.model:SetLookAt(Vector(0, 0, 0))

self.model.LayoutEntity = function() end

local x = scale_x(4)
self.best = vgui.Create("ixMenuButton", self)
self.best:SetContentAlignment(5)
self.best:SetSize(buttonSize, buttonSize)
self.best:SetPos(x, pH - buttonSize - scale(4))
self.best:SetFont("ixIconsMenuButton")
self.best:SetText("b", true, true)
self.best:SetTooltip(L("iconEditorAlignBest"))

self.best.DoClick = function()
    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    local camData = PositionSpawnIcon(entity, pos)

    if (camData) then
        self.model:SetCamPos(camData.origin)
        self.model:SetFOV(camData.fov)
        self.model:SetLookAng(camData.angles)
    end
end

x = x + buttonSize + scale_x(4)

self.front = vgui.Create("ixMenuButton", self)
self.front:SetContentAlignment(5)
self.front:SetSize(buttonSize, buttonSize)
self.front:SetPos(x, pH - buttonSize - scale(4))
self.front:SetFont("ixIconsMenuButton")
self.front:SetText("m", true, true)
self.front:SetTooltip(L("iconEditorAlignFront"))

self.front.DoClick = function()
    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    local camPos = pos + Vector(-200, 0, 0)
    self.model:SetCamPos(camPos)
    self.model:SetFOV(45)
    self.model:SetLookAng((camPos * -1):Angle())
end

x = x + buttonSize + scale_x(4)

self.above = vgui.Create("ixMenuButton", self)
self.above:SetContentAlignment(5)
self.above:SetSize(buttonSize, buttonSize)
self.above:SetPos(x, pH - buttonSize - scale(4))
self.above:SetFont("ixIconsMenuButton")
self.above:SetText("u", true, true)
self.above:SetTooltip(L("iconEditorAlignAbove"))

self.above.DoClick = function()
    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    local camPos = pos + Vector(0, 0, 200)
    self.model:SetCamPos(camPos)
    self.model:SetFOV(45)
    self.model:SetLookAng((camPos * -1):Angle())
end

x = x + buttonSize + scale_x(4)

self.right = vgui.Create("ixMenuButton", self)
self.right:SetContentAlignment(5)
self.right:SetSize(buttonSize, buttonSize)
self.right:SetPos(x, pH - buttonSize - scale(4))
self.right:SetFont("ixIconsMenuButton")
self.right:SetText("t", true, true)
self.right:SetTooltip(L("iconEditorAlignRight"))

self.right.DoClick = function()
    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    local camPos = pos + Vector(0, 200, 0)
    self.model:SetCamPos(camPos)
    self.model:SetFOV(45)
    self.model:SetLookAng((camPos * -1):Angle())
end

x = x + buttonSize + scale_x(4)

self.center = vgui.Create("ixMenuButton", self)
self.center:SetContentAlignment(5)
self.center:SetSize(buttonSize, buttonSize)
self.center:SetPos(x, pH - buttonSize - scale(4))
self.center:SetFont("ixIconsMenuButton")
self.center:SetText("T", true, true)
self.center:SetTooltip(L("iconEditorAlignCenter"))

self.center.DoClick = function()
    local entity = self.model:GetEntity()
    local pos = entity:GetPos()
    self.model:SetCamPos(pos)
    self.model:SetFOV(45)
    self.model:SetLookAng(Angle(0, -180, 0))
end

self.preview = vgui.Create("DPanel", self)
self.preview:Dock(FILL)
self.preview:DockMargin(scale_x(4), 0, 0, 0)
self.preview:DockPadding(scale_x(4), scale(4), scale_x(4), scale(4))

self.preview.Paint = function(this, width, height)
    draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 100))
end

self.modelPath = vgui.Create("ixSettingsRowString", self.preview)
self.modelPath:SetText(L("iconEditorModel"))
self.modelPath:SetValue(self.model:GetModel())
self.modelPath:Dock(TOP)
self.modelPath.setting:SetFont("ixMenuButtonFontSmall")
self.modelPath.setting:SetPlaceholderText("Model...")

self.modelPath.setting.OnEnter = function(this)
    local model = this:GetValue()

    if (model and model != "") then
        self.model:SetModel(model)
        self.container.item:Rebuild()
    end
end

self.modelPath.setting.OnLoseFocus = function(this)
    local model = this:GetValue()

    if (model and model != "") then
        self.model:SetModel(model)
        self.container.item:Rebuild()
    end
end

self.width = vgui.Create("ixSettingsRowNumber", self.preview)
self.width:Dock(TOP)
self.width:SetText(L("iconEditorWidth"))
self.width:SetMin(1)
self.width:SetMax(24)
self.width:SetDecimals(0)
self.width:SetValue(1)

self.width.OnValueChanged = function(this, value)
    self.container.item:Rebuild()
end

self.height = vgui.Create("ixSettingsRowNumber", self.preview)
self.height:Dock(TOP)
self.height:SetText(L("iconEditorHeight"))
self.height:SetMin(1)
self.height:SetMax(24)
self.height:SetDecimals(0)
self.height:SetValue(1)

self.height.OnValueChanged = function(this, value)
    self.container.item:Rebuild()
end

self.itemPanel = vgui.Create("DPanel", self.preview)
self.itemPanel:Dock(FILL)

self.itemPanel.Paint = function(this, width, height)
    draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 100))
end

self.item = vgui.Create("DModelPanel", self.itemPanel)
self.item:SetMouseInputEnabled(false)
self.item.LayoutEntity = function() end

self.item.PaintOver = function(this, width, height)
    surface.SetDrawColor(color_white)
    surface.DrawOutlinedRect(0, 0, width, height)
end

self.item.Rebuild = function(this)
    local slotSize = 64
    local padding = scale(2)
    local slotWidth, slotHeight = math.Round(self.width:GetValue()), math.Round(self.height:GetValue())
    local width, height = slotWidth * (slotSize + padding) - padding, slotHeight * (slotSize + padding) - padding
    this:SetModel(self.model:GetModel())
    this:SetCamPos(self.model:GetCamPos())
    this:SetFOV(self.model:GetFOV())
    this:SetLookAng(self.model:GetLookAng())
    this:SetSize(width, height)
    this:Center()
end

self.container.item:Rebuild()
self.best:DoClick()

timer.Create("ixIconEditorUpdate", 0.5, 0, function()
    if IsValid(self) and IsValid(self.model) then
        self.container.item:Rebuild()
    else
        timer.Remove("ixIconEditorUpdate")
    end
end)

self.copy = vgui.Create("ixMenuButton", self)
self.copy:SetContentAlignment(5)
self.copy:SetSize(buttonSize, buttonSize)
self.copy:SetPos(pW - buttonSize - scale_x(12), pH - buttonSize - scale(12))
self.copy:SetFont("ixIconsMenuButton")
self.copy:SetText("}", true, true)
self.copy:SetTooltip(L("iconEditorCopy"))
self.copy.DoClick = function()
    local camPos = self.model:GetCamPos()
    local camAng = self.model:GetLookAng()
    local str = "ITEM.iconCam = {\n"
    .."\tpos = Vector("..math.Round(camPos.x, 2)..", "..math.Round(camPos.y, 2)..", "..math.Round(camPos.z, 2).."),\n"
    .."\tang = Angle("..math.Round(camAng.p, 2)..", "..math.Round(camAng.y, 2)..", "..math.Round(camAng.r, 2).."),\n"
    .."\tfov = "..math.Round(self.model:GetFOV(), 2).."\n"
    .."}\n"

    SetClipboardText(str)
    ix.util.Notify(L("iconEditorCopied"))
end
*/

hook.Add("CreateDeveloperMenuButtons", "ixDeveloperItemCam", function(tabs)
    tabs["iconEditor"] = {
        Create = function(info, container)
            local halfWidth = container:GetWide() / 2
            local halfHeight = container:GetTall() / 2

            local leftPanel = container:Add("DPanel")
            leftPanel:SetSize(halfWidth, container:GetTall())
            leftPanel:Dock(LEFT)
            leftPanel:DockMargin(0, 0, 8, 0)
            leftPanel.Paint = function(this, width, height)
                surface.SetDrawColor(0, 0, 0, 66)
                surface.DrawRect(0, 0, width, height)
            end

            local rightPanel = container:Add("DPanel")
            rightPanel:SetSize(halfWidth, halfHeight)
            rightPanel:Dock(FILL)
            rightPanel.Paint = function(this, width, height)
                surface.SetDrawColor(0, 0, 0, 66)
                surface.DrawRect(0, 0, width, height)
            end

            local topPanel = container:Add("DScrollPanel")
            topPanel:SetTall(halfHeight)
            topPanel:Dock(TOP)
            topPanel:DockMargin(0, 0, 0, 8)
            topPanel:GetCanvas():DockPadding(8, 8, 8, 8)
            topPanel.Paint = function(this, width, height)
                surface.SetDrawColor(0, 0, 0, 66)
                surface.DrawRect(0, 0, width, height)
            end

            local model = leftPanel:Add("DAdjustableModelPanel")
            model:Dock(FILL)
            model:SetModel("models/props_borealis/bluebarrel001.mdl")
            model:SetLookAt(Vector(0, 0, 0))

            model.LayoutEntity = function() end

            local best = leftPanel:Add("ixMenuButton")
            best.padding = {0, 0, 0, 0}
            best:SetTextInset(0, 0)
            best:SetContentAlignment(5)
            best:SetSize(64, 64)
            best:SetPos(0, container:GetTall() - 64)
            best:SetFont("ixIconsMenuButton")
            best:SetText("b", true, true)
            best:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorAlignBest"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorAlignBestDesc"))
                description:SizeToContents()
            end)

            best.DoClick = function()
                local entity = model:GetEntity()
                local pos = entity:GetPos()
                local camData = PositionSpawnIcon(entity, pos)

                if (camData) then
                    model:SetCamPos(camData.origin)
                    model:SetFOV(camData.fov)
                    model:SetLookAng(camData.angles)
                end
            end

            local front = leftPanel:Add("ixMenuButton")
            front.padding = {0, 0, 0, 0}
            front:SetTextInset(0, 0)
            front:SetContentAlignment(5)
            front:SetSize(64, 64)
            front:SetPos(64, container:GetTall() - 64)
            front:SetFont("ixIconsMenuButton")
            front:SetText("m", true, true)
            front:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorAlignFront"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorAlignFrontDesc"))
                description:SizeToContents()
            end)

            front.DoClick = function()
                local entity = model:GetEntity()
                local pos = entity:GetPos()
                local camPos = pos + Vector(-200, 0, 0)
                model:SetCamPos(camPos)
                model:SetFOV(45)
                model:SetLookAng((camPos * -1):Angle())
            end

            local above = leftPanel:Add("ixMenuButton")
            above.padding = {0, 0, 0, 0}
            above:SetTextInset(0, 0)
            above:SetContentAlignment(5)
            above:SetSize(64, 64)
            above:SetPos(128, container:GetTall() - 64)
            above:SetFont("ixIconsMenuButton")
            above:SetText("u", true, true)
            above:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorAlignAbove"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorAlignAboveDesc"))
                description:SizeToContents()
            end)

            above.DoClick = function()
                local entity = model:GetEntity()
                local pos = entity:GetPos()
                local camPos = pos + Vector(0, 0, 200)
                model:SetCamPos(camPos)
                model:SetFOV(45)
                model:SetLookAng((camPos * -1):Angle())
            end

            local right = leftPanel:Add("ixMenuButton")
            right.padding = {0, 0, 0, 0}
            right:SetTextInset(0, 0)
            right:SetContentAlignment(5)
            right:SetSize(64, 64)
            right:SetPos(192, container:GetTall() - 64)
            right:SetFont("ixIconsMenuButton")
            right:SetText("t", true, true)
            right:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorAlignRight"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorAlignRightDesc"))
                description:SizeToContents()
            end)

            right.DoClick = function()
                local entity = model:GetEntity()
                local pos = entity:GetPos()
                local camPos = pos + Vector(0, 200, 0)
                model:SetCamPos(camPos)
                model:SetFOV(45)
                model:SetLookAng((camPos * -1):Angle())
            end

            local center = leftPanel:Add("ixMenuButton")
            center.padding = {0, 0, 0, 0}
            center:SetTextInset(0, 0)
            center:SetContentAlignment(5)
            center:SetSize(64, 64)
            center:SetPos(256, container:GetTall() - 64)
            center:SetFont("ixIconsMenuButton")
            center:SetText("T", true, true)
            center:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorAlignCenter"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorAlignCenterDesc"))
                description:SizeToContents()
            end)

            center.DoClick = function()
                local entity = model:GetEntity()
                local pos = entity:GetPos()
                model:SetCamPos(pos)
                model:SetFOV(45)
                model:SetLookAng(Angle(0, -180, 0))
            end

            local modelPath = topPanel:Add("ixSettingsRowString")
            modelPath:SetText(L("iconEditorModel"))
            modelPath:SetValue(model:GetModel())
            modelPath:Dock(TOP)
            modelPath:DockMargin(0, 0, 0, 8)
            modelPath.setting:SetFont("ixMenuButtonFontSmall")
            modelPath.setting:SetPlaceholderText("Model...")

            modelPath.PerformLayout = function(this, width, height)
                this.setting:SetWide(width * 0.75)
            end

            modelPath.setting.OnChange = function(this)
                local model = this:GetValue()

                if (model and model != "") then
                    model:SetModel(model)
                end
            end

            local width = topPanel:Add("ixSettingsRowNumber")
            width:SetText(L("iconEditorWidth"))
            width:SetMin(1)
            width:SetMax(24)
            width:SetDecimals(0)
            width:SetValue(1)
            width:Dock(TOP)
            width:DockMargin(0, 0, 0, 8)

            width.PerformLayout = function(this, width, height)
                this.setting:SetWide(width * 0.75)
            end

            width.OnValueChanged = function(this, value)
                container.item:Rebuild()
            end

            local height = topPanel:Add("ixSettingsRowNumber")
            height:SetText(L("iconEditorHeight"))
            height:SetMin(1)
            height:SetMax(24)
            height:SetDecimals(0)
            height:SetValue(1)
            height:Dock(TOP)
            height:DockMargin(0, 0, 0, 8)

            height.PerformLayout = function(this, width, height)
                this.setting:SetWide(width * 0.75)
            end

            height.OnValueChanged = function(this, value)
                container.item:Rebuild()
            end

            local itemPanel = rightPanel:Add("DPanel")
            itemPanel:Dock(FILL)
            itemPanel.Paint = nil

            local item = itemPanel:Add("DModelPanel")
            item:SetMouseInputEnabled(false)
            item.LayoutEntity = function() end

            item.PaintOver = function(this, width, height)
                surface.SetDrawColor(color_white)
                surface.DrawOutlinedRect(0, 0, width, height)
            end

            item.Rebuild = function(this)
                local slotSize = ScreenScale(32)
                local padding = 2
                local slotWidth, slotHeight = math.Round(width:GetValue()), math.Round(height:GetValue())
                local width, height = slotWidth * (slotSize + padding) - padding, slotHeight * (slotSize + padding) - padding
                this:SetModel(model:GetModel())
                this:SetCamPos(model:GetCamPos())
                this:SetFOV(model:GetFOV())
                this:SetLookAng(model:GetLookAng())
                this:SetSize(width, height)
                this:Center()
            end

            item:Rebuild()
            best:DoClick()

            timer.Create("ixIconEditorUpdate", 0.5, 0, function()
                if ( IsValid(model) ) then
                    container.item:Rebuild()
                else
                    timer.Remove("ixIconEditorUpdate")
                end
            end)

            container.item = item

            local copy = rightPanel:Add("ixMenuButton")
            copy.padding = {0, 0, 0, 0}
            copy:SetTextInset(0, 0)
            copy:SetContentAlignment(5)
            copy:SetSize(64, 64)
            copy:SetPos(rightPanel:GetWide() - 64 - 12, rightPanel:GetTall() - 64 - 12)
            copy:SetFont("ixIconsMenuButton")
            copy:SetText("}", true, true)
            copy:SetHelixTooltip(function(tooltip)
                local title = tooltip:AddRow("title")
                title:SetImportant()
                title:SetText(L("iconEditorCopy"))
                title:SizeToContents()

                local description = tooltip:AddRow("description")
                description:SetText(L("iconEditorCopyDesc"))
                description:SizeToContents()
            end)

            copy.DoClick = function()
                local camPos = model:GetCamPos()
                local camAng = model:GetLookAng()
                local str = "ITEM.iconCam = {\n"
                .."\tpos = Vector("..math.Round(camPos.x, 2)..", "..math.Round(camPos.y, 2)..", "..math.Round(camPos.z, 2).."),\n"
                .."\tang = Angle("..math.Round(camAng.p, 2)..", "..math.Round(camAng.y, 2)..", "..math.Round(camAng.r, 2).."),\n"
                .."\tfov = "..math.Round(model:GetFOV(), 2).."\n"
                .."}\n"

                SetClipboardText(str)

                ix.util.NotifyLocalized("iconEditorCopied")
            end
        end
    }
end)

concommand.Add("ix_dev_icon", function()
    if (CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Developer", nil)) then
        ix.gui.lastDeveloperMenuTab = "iconEditor"
        vgui.Create("ixDeveloperMenu")
    end
end)
