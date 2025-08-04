
local PANEL = {}

Derma_Hook( PANEL, "Paint", "Paint", "ListViewHeaderLabel" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "ListViewHeaderLabel" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "ListViewHeaderLabel" )

function PANEL:Init()
    
    self:SetFont( "ixSmallFont" )

end

-- No example for this control. Why do we have this control?
function PANEL:GenerateExample( class, tabs, w, h )
end

vgui.Register( "ixListViewHeaderLabel", PANEL, "DLabel" )

--[[---------------------------------------------------------
    ixListView_Column
-----------------------------------------------------------]]

local PANEL = {}

AccessorFunc( PANEL, "m_iMinWidth", "MinWidth" )
AccessorFunc( PANEL, "m_iMaxWidth", "MaxWidth" )

AccessorFunc( PANEL, "m_iTextAlign", "TextAlign" )

AccessorFunc( PANEL, "m_bFixedWidth", "FixedWidth" )
AccessorFunc( PANEL, "m_bDesc", "Descending" )
AccessorFunc( PANEL, "m_iColumnID", "ColumnID" )

Derma_Hook( PANEL, "Paint", "Paint", "ListViewColumn" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "ListViewColumn" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "ListViewColumn" )

function PANEL:Init()

    self.Header = vgui.Create( "ixMenuButton", self )
    self.Header:SetFont( "ixMenuButtonFontSmall" )
    self.Header:SetContentAlignment( 5 )
    self.Header:SetTextInset( 0, 0 )
    self.Header.DoClick = function() self:DoClick() end
    self.Header.DoRightClick = function() self:DoRightClick() end

    self:SetMinWidth( 10 )
    self:SetMaxWidth( 19200 )

end

function PANEL:SetFixedWidth( iSize )

    self:SetMinWidth( iSize )
    self:SetMaxWidth( iSize )
    self:SetWide( iSize )

end

function PANEL:DoClick()

    self:GetParent():SortByColumn( self:GetColumnID(), self:GetDescending() )
    self:SetDescending( !self:GetDescending() )

end

function PANEL:DoRightClick()

end

function PANEL:SetName( strName )

    self.Header:SetText( strName )

end

function PANEL:Paint()
    return true
end

function PANEL:PerformLayout()

    self.Header:SetPos( 0, 0 )
    self.Header:SetSize( self:GetWide(), self:GetParent():GetHeaderHeight() )

end

function PANEL:ResizeColumn( iSize )

    self:GetParent():OnRequestResize( self, iSize )

end

function PANEL:SetWidth( iSize )

    iSize = math.Clamp( iSize, self:GetMinWidth(), math.max( self:GetMaxWidth(), 0 ) )
    iSize = math.ceil( iSize )

    -- If the column changes size we need to lay the data out too
    if ( iSize != math.ceil( self:GetWide() ) ) then
        self:GetParent():SetDirty( true )
    end

    self:SetWide( iSize )
    return iSize

end

vgui.Register( "ixListView_Column", PANEL, "Panel" )

--[[---------------------------------------------------------
    ixListView_ColumnPlain
-----------------------------------------------------------]]

local PANEL = {}

function PANEL:DoClick()
end

vgui.Register( "ixListView_ColumnPlain", PANEL, "ixListView_Column" )
