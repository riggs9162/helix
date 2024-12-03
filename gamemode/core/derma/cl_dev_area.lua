hook.Add("CreateDeveloperMenuButtons", "ixDeveloperAreaEditor", function(tabs)
    tabs["areaEditor"] = {
        Create = function(info, container)
        end,
        Sections = {}
    }

    for k, v in SortedPairs(ix.area.stored) do
        tabs["areaEditor"].Sections[L(k)] = {
            Create = function(info, container)
                local buttons = container:Add("DPanel")
                buttons:Dock(BOTTOM)
                buttons:DockMargin(0, 8, 0, 0)
                buttons.Paint = nil

                local button = buttons:Add("ixMenuButton")
                button:SetText("Delete Area")
                button:SetTextColor(derma.GetColor("Error", button))
                button:SetFont("ixMenuButtonFontSmall")
                button:SizeToContents()
                button:Dock(LEFT)

                button.DoClick = function(this)
                    Derma_Query(L("areaDeleteConfirm", k), L("areaDelete"), L("yes"), function()
                        net.Start("ixDeveloperAreaDelete")
                            net.WriteString(k)
                        net.SendToServer()

                        ix.util.Notify("You have deleted the area.")
                    end, L("no"))
                end

                -- hacky...
                buttons:SetTall(button:GetTall())

                local label = container:Add("DLabel")
                label:SetText(L(k))
                label:SetTextColor(ix.config.Get("color"))
                label:SetFont("ixTitleFont")
                label:SizeToContents()
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, 4)

                local label = container:Add("DLabel")
                label:SetText("Settings")
                label:SetTextColor(ix.config.Get("color"))
                label:SetFont("ixSubTitleFont")
                label:SizeToContents()
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, 4)

                local textEntry = container:Add("ixSettingsRowString")
                textEntry:SetText("Name")
                textEntry:SetValue(k)
                textEntry:Dock(TOP)
                textEntry:DockMargin(0, 0, 0, 8)

                textEntry.OnValueChanged = function(this)
                    net.Start("ixDeveloperAreaEditName")
                        net.WriteString(k)
                        net.WriteType(this:GetValue())
                    net.SendToServer()
                end

                local label = container:Add("DLabel")
                label:SetText("Properties")
                label:SetTextColor(ix.config.Get("color"))
                label:SetFont("ixSubTitleFont")
                label:SizeToContents()
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, 4)

                for k2, v2 in SortedPairs(ix.area.properties) do
                    local name = L(k2) or ix.util.ExpandCamelCase(k2)
                    local value = v.properties[k2]
                    if ( value == nil ) then value = v2.default end

                    if ( v2.type == ix.type.bool ) then
                        local checkbox = container:Add("ixSettingsRowBool")
                        checkbox:SetText(name)
                        checkbox:SetValue(value)
                        checkbox:Dock(TOP)
                        checkbox:DockMargin(0, 0, 0, 8)

                        checkbox.OnValueChanged = function(this, value2)
                            print(value2)
                            net.Start("ixDeveloperAreaEditProperties")
                                net.WriteString(k)
                                net.WriteString(k2)
                                net.WriteType(value2)
                            net.SendToServer()
                        end
                    elseif ( v2.type == ix.type.color ) then
                        local color = container:Add("ixSettingsRowColor")
                        color:SetText(name)
                        color:SetValue(value)
                        color:Dock(TOP)
                        color:DockMargin(0, 0, 0, 8)

                        color.OnValueChanged = function(this, value2)
                            net.Start("ixDeveloperAreaEditProperties")
                                net.WriteString(k)
                                net.WriteString(k2)
                                net.WriteType(value2)
                            net.SendToServer()
                        end
                    elseif ( v2.type == ix.type.string or v2.type == ix.type.number ) then
                        local textEntry = container:Add("ixSettingsRowString")
                        textEntry:SetText(name)
                        textEntry:SetValue(value)
                        textEntry:Dock(TOP)
                        textEntry:DockMargin(0, 0, 0, 8)

                        textEntry.OnValueChanged = function(this)
                            net.Start("ixDeveloperAreaEditProperties")
                                net.WriteString(k)
                                net.WriteString(k2)
                                net.WriteType(this:GetValue())
                            net.SendToServer()
                        end
                    end
                end
            end
        }
    end
end)

concommand.Add("ix_dev_area", function()
    if (CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Developer", nil)) then
        ix.gui.lastDeveloperMenuTab = "areaEditor"
        vgui.Create("ixDeveloperMenu")
    end
end)