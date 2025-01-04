
local PANEL = {}

AccessorFunc( PANEL, "ActiveButton", "ActiveButton" )

function PANEL:Init()

	self.Navigation = vgui.Create( "DScrollPanel", self )
	self.Navigation:Dock( LEFT )
	self.Navigation:SetWidth( 100 )
	self.Navigation:DockMargin( 10, 10, 10, 0 )

	self.Content = vgui.Create( "Panel", self )
	self.Content:Dock( FILL )

	self.Items = {}

end

function PANEL:AddSheet( label, panel, material )

	if ( !IsValid( panel ) ) then return end

	local Sheet = {}

	Sheet.Button = vgui.Create( "ixMenuButton", self.Navigation )

	Sheet.Button:SetImage( material )
	Sheet.Button.Target = panel
	Sheet.Button:Dock( TOP )
	Sheet.Button:SetText( label )
	Sheet.Button:SetContentAlignment(5)

	Sheet.Button.DoClick = function()
		self:SetActiveButton( Sheet.Button )
	end

	Sheet.Panel = panel
	Sheet.Panel:SetParent( self.Content )
	Sheet.Panel:SetVisible( false )

	Sheet.Button:SizeToContents()

	table.insert( self.Items, Sheet )

	local maxWidth = 0
	for _, Sheet in pairs( self.Items ) do
		maxWidth = math.max( maxWidth, Sheet.Button:GetWide() )
	end

	self.Navigation:SetWide( maxWidth + ScreenScale( 16 ) )

	if ( !IsValid( self.ActiveButton ) ) then
		self:SetActiveButton( Sheet.Button )
	end

	return Sheet
end

function PANEL:SetActiveButton( active )

	if ( self.ActiveButton == active ) then return end

	if ( self.ActiveButton and self.ActiveButton.Target ) then
		self.ActiveButton.Target:SetVisible( false )
		self.ActiveButton:SetSelected( false )
		self.ActiveButton:SetToggle( false )
		--self.ActiveButton:SetColor( Color( 150, 150, 150, 100 ) )
	end

	self.ActiveButton = active
	active.Target:SetVisible( true )
	active:SetSelected( true )
	active:SetToggle( true )
	--active:SetColor( color_white )

	self.Content:InvalidateLayout()

end

vgui.Register( "ixColumnSheet", PANEL, "Panel" )
