
local matBlurScreen = Material( "pp/blurscreen" )

--[[
    This is designed for Paint functions..
--]]
function Derma_DrawBackgroundBlur( panel, starttime )

    local Fraction = 1

    if ( starttime ) then
        Fraction = math.Clamp( ( SysTime() - starttime ) / 1, 0, 1 )
    end

    local x, y = panel:LocalToScreen( 0, 0 )

    local wasEnabled = DisableClipping( true )

    -- Menu cannot do blur
    if ( !MENU_DLL ) then
        surface.SetMaterial( matBlurScreen )
        surface.SetDrawColor( 255, 255, 255, 255 )

        for i = 0.33, 1, 0.33 do
            matBlurScreen:SetFloat( "$blur", Fraction * 5 * i )
            matBlurScreen:Recompute()
            if ( render ) then render.UpdateScreenEffectTexture() end -- Todo: Make this available to menu Lua
            surface.DrawTexturedRect( x * -1, y * -1, ScrW(), ScrH() )
        end
    end

    surface.SetDrawColor( 10, 10, 10, 200 * Fraction )
    surface.DrawRect( x * -1, y * -1, ScrW(), ScrH() )

    DisableClipping( wasEnabled )

end

--[[
    Display a simple message box.

    Derma_Message( "Hey Some Text Here!!!", "Message Title (Optional)", "Button Text (Optional)" )
--]]

function Derma_Message( strText, strTitle, strButtonText )

    local Window = vgui.Create( "ixEntityMenu" )

    local Options = { }

    Options[ strButtonText or "OK" ] = function() end

    Window:SetOptions( Options )

    local Title = vgui.Create( "DLabel", Window )
    Title:SetText( strTitle )
    Title:SetFont( "ixSubTitleFont" )
    Title:SizeToContents()
    Title:SetX( Window:GetWide() / 2 - Title:GetWide() - 32 )
    Title:SetY( Window:GetTall() / 2 - Title:GetTall() )
    Title:SetTextColor( ix.config.Get( "color" ) )

    local SubTitle = vgui.Create( "DLabel", Window )
    SubTitle:SetText( strText )
    SubTitle:SetFont( "ixMenuButtonFont" )
    SubTitle:SizeToContents()
    SubTitle:SetX( Window:GetWide() / 2 - SubTitle:GetWide() - 32 )
    SubTitle:SetY( Window:GetTall() / 2 )
    SubTitle:SetTextColor( color_white )

    Window.OnMousePressed = nil
    Window.PaintOld = Window.Paint
    Window.Paint = function( self, w, h )

        surface.SetDrawColor( 10, 10, 10, self.blur * 100 )
        surface.DrawRect( 0, 0, w, h )

        ix.util.DrawBlur( self, 2, 0, self.blur * 255 )

        self:PaintOld( w, h )

    end

    return Window

end

concommand.Add( "ix_derma_message", function( ply )

    if ( !IsValid( ply ) ) then return end

    Derma_Message( "Hey Some Text Here!!!", "Message Title (Optional)", "Button Text (Optional)" )

end )

--[[
    Ask a question with multiple answers..

    Derma_Query( "Would you like me to punch you right in the face?", "Question!",
                        "Yesss",    function() MsgN( "Pressed YES!") end,
                        "Nope!",    function() MsgN( "Pressed Nope!") end,
                        "Cancel",    function() MsgN( "Cancelled!") end )

--]]

function Derma_Query( strText, strTitle, ... )

    local Window = vgui.Create( "ixEntityMenu" )

    local Options = { }

    for i = 1, 8, 2 do

        local Text = select( i, ... )
        if ( Text == nil ) then break end

        local Func = select( i + 1, ... ) or function() end

        Options[ Text ] = function()

            Func()

        end

    end

    Window:SetOptions( Options )

    local Title = vgui.Create( "DLabel", Window )
    Title:SetText( strTitle )
    Title:SetFont( "ixSubTitleFont" )
    Title:SizeToContents()
    Title:SetX( Window:GetWide() / 2 - Title:GetWide() - 32 )
    Title:SetY( Window:GetTall() / 2 - Title:GetTall() )
    Title:SetTextColor( ix.config.Get( "color" ) )

    local SubTitle = ix.util.WrapText( strText, Window:GetWide() / 2 - 64, "ixMenuButtonFont" )

    for i = 1, #SubTitle do

        local Label = vgui.Create( "DLabel", Window )
        Label:SetText( SubTitle[ i ] )
        Label:SetFont( "ixMenuButtonFont" )
        Label:SizeToContents()
        Label:SetX( Window:GetWide() / 2 - Label:GetWide() - 32 )
        Label:SetY( Window:GetTall() / 2 + Label:GetTall() * ( i - 1 ) )
        Label:SetTextColor( color_white )

    end

    Window.OnMousePressed = nil
    Window.PaintOld = Window.Paint
    Window.Paint = function( self, w, h )

        surface.SetDrawColor( 10, 10, 10, self.blur * 100 )
        surface.DrawRect( 0, 0, w, h )

        ix.util.DrawBlur( self, 2, 0, self.blur * 255 )

        self:PaintOld( w, h )

    end

    return Window

end

concommand.Add( "ix_derma_query", function( ply )

    if ( !IsValid( ply ) ) then return end

    Derma_Query( "Would you like me to punch you right in the face?", "Question!",
                        "Yesss",    function() MsgN( "Pressed YES!") end,
                        "Nope!",    function() MsgN( "Pressed Nope!") end,
                        "Cancel",    function() MsgN( "Cancelled!") end )

end )

--[[
    Request a string from the user

    Derma_StringRequest( "Question",
                    "What Is Your Favourite Color?",
                    "Type your answer here!",
                    function( strTextOut ) Derma_Message( "Your Favourite Color Is: " .. strTextOut ) end,
                    function( strTextOut ) Derma_Message( "You pressed Cancel!" ) end,
                    "Okey Dokey",
                    "Cancel" )

--]]

function Derma_StringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )
    strButtonText = strButtonText or "OK"
    strButtonCancelText = strButtonCancelText or "Cancel"

    local Window = vgui.Create( "ixEntityMenu" )

    local Title = vgui.Create( "DLabel", Window )
    Title:SetText( strTitle )
    Title:SetFont( "ixSubTitleFont" )
    Title:SizeToContents()
    Title:SetTextColor( ix.config.Get( "color" ) )

    local SubTitle = ix.util.WrapText( strText, Window:GetWide() / 2 - 64, "ixMenuButtonFont" )
    local Labels = { }
    for i = 1, #SubTitle do

        local Label = vgui.Create( "DLabel", Window )
        Label:SetText( SubTitle[ i ] )
        Label:SetFont( "ixMenuButtonFont" )
        Label:SizeToContents()
        Label:SetTextColor( color_white )

        table.insert( Labels, Label )

    end

    Window.OnMousePressed = nil
    Window.PaintOld = Window.Paint
    Window.Paint = function( self, w, h )

        surface.SetDrawColor( 10, 10, 10, self.blur * 100 )
        surface.DrawRect( 0, 0, w, h )

        ix.util.DrawBlur( self, 2, 0, self.blur * 255 )

        self:PaintOld( w, h )

    end

    local TextEntry = vgui.Create( "ixTextEntry", Window )
    TextEntry:SetFont( "ixMenuButtonFont" )
    TextEntry:SetPlaceholderText( strDefaultText or "" )
    TextEntry:SetValue( strDefaultText or "" )
    TextEntry:SetWide( Window:GetWide() / 2 - 64 )

    local Options = {

        [ strButtonText ] = function()

            if ( fnEnter and isfunction( fnEnter ) ) then
                fnEnter( TextEntry:GetValue() or "" )
            end

        end,

        [ strButtonCancelText ] = function()

            if ( fnCancel and isfunction( fnCancel ) ) then
                fnCancel( TextEntry:GetValue() or "" )
            end

        end

    }

    if ( !Options or table.Count( Options ) == 0 ) then
        ErrorNoHalt( "Derma_StringRequest: No options provided!\n" )
        Window:Remove()
        return
    end

    Window:SetOptions( Options )

    Title:SetX( Window:GetWide() / 2 - Title:GetWide() - 32 )
    Title:SetY( Window:GetTall() / 2 - Window.list:GetTall() / 2 )

    for i = 1, #Labels do

        Labels[ i ]:SetX( Window:GetWide() / 2 - Labels[ i ]:GetWide() - 32 )
        Labels[ i ]:SetY( Title:GetY() + Title:GetTall() + Labels[ i ]:GetTall() * ( i - 1 ) )

    end

    TextEntry:SetX( Window:GetWide() / 2 - TextEntry:GetWide() - 32 )
    TextEntry:SetY( Labels[ #Labels ]:GetY() + Labels[ #Labels ]:GetTall() )

    return Window

end

concommand.Add( "ix_derma_stringrequest", function( ply )

    if ( !IsValid( ply ) ) then return end

    Derma_StringRequest( "Question",
                    "What Is Your Favourite Color?",
                    "Type your answer here!",
                    function( strTextOut ) Derma_Message( "Your Favourite Color Is: " .. strTextOut ) end,
                    function( strTextOut ) Derma_Message( "You pressed Cancel!" ) end,
                    "Okey Dokey",
                    "Cancel" )

end )