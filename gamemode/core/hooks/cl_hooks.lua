local LocalPlayer = LocalPlayer
local IsValid = IsValid
local vgui = vgui
local surface = surface
local ScreenScale = ScreenScale
local math = math
local ix = ix
local Angle = Angle
local Vector = Vector
local hook = hook
local ScrW = ScrW
local ScrH = ScrH
local timer = timer
local GetGlobalString = GetGlobalString
local Color = Color
local RealTime = RealTime
local util = util
local Entity = Entity
local SysTime = SysTime
local FrameTime = FrameTime
local render = render
local cam = cam
local pairs = pairs
local team = team
local L = L
local string = string
local IsFirstTimePredicted = IsFirstTimePredicted
local isfunction = isfunction
local RunConsoleCommand = RunConsoleCommand
local istable = istable
local table = table
local derma = derma
local SetClipboardText = SetClipboardText
local net = net
local Derma_StringRequest = Derma_StringRequest
local gameevent = gameevent
local Player = Player
local chat = chat
local unpack = unpack

function GM:ForceDermaSkin()
    return "helix"
end

function GM:ScoreboardShow()
    local ply = LocalPlayer()
    if ( !IsValid(ply) ) then return end

    if (ply:GetCharacter()) then
        vgui.Create("ixMenu")
    end
end

function GM:ScoreboardHide()
end

function GM:LoadFonts(font, genericFont)
    surface.CreateFont("ix3D2DFont", {
        font = font,
        size = 128,
        extended = true,
        weight = 100
    })

    surface.CreateFont("ix3D2DMediumFont", {
        font = font,
        size = 48,
        extended = true,
        weight = 100
    })

    surface.CreateFont("ix3D2DSmallFont", {
        font = font,
        size = 24,
        extended = true,
        weight = 400
    })

    surface.CreateFont("ixTitleFont", {
        font = font,
        size = ScreenScale(30),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixSubTitleFont", {
        font = font,
        size = ScreenScale(16),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixMenuMiniFont", {
        font = "Roboto",
        size = math.max(ScreenScale(4), 18),
        weight = 300,
    })

    surface.CreateFont("ixMenuButtonFont", {
        font = "Roboto Th",
        size = ScreenScale(14),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixMenuButtonFontSmall", {
        font = "Roboto Th",
        size = ScreenScale(10),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixMenuButtonFontThick", {
        font = "Roboto",
        size = ScreenScale(14),
        extended = true,
        weight = 300
    })

    surface.CreateFont("ixMenuButtonLabelFont", {
        font = "Roboto Th",
        size = 28,
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixMenuButtonHugeFont", {
        font = "Roboto Th",
        size = ScreenScale(24),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixToolTipText", {
        font = font,
        size = 20,
        extended = true,
        weight = 500
    })

    surface.CreateFont("ixMonoSmallFont", {
        font = "Consolas",
        size = 12,
        extended = true,
        weight = 800
    })

    surface.CreateFont("ixMonoMediumFont", {
        font = "Consolas",
        size = 22,
        extended = true,
        weight = 800
    })

    -- The more readable font.
    font = genericFont

    surface.CreateFont("ixBigFont", {
        font = font,
        size = 36,
        extended = true,
        weight = 1000
    })

    surface.CreateFont("ixMediumFont", {
        font = font,
        size = 25,
        extended = true,
        weight = 1000
    })

    surface.CreateFont("ixNoticeFont", {
        font = font,
        size = math.max(ScreenScale(8), 18),
        weight = 100,
        extended = true,
        antialias = true
    })

    surface.CreateFont("ixMediumLightFont", {
        font = font,
        size = 25,
        extended = true,
        weight = 200
    })

    surface.CreateFont("ixMediumLightBlurFont", {
        font = font,
        size = 25,
        extended = true,
        weight = 200,
        blursize = 4
    })

    surface.CreateFont("ixGenericFont", {
        font = font,
        size = 20,
        extended = true,
        weight = 1000
    })

    surface.CreateFont("ixChatFont", {
        font = font,
        size = math.max(ScreenScale(7), 17) * ix.option.Get("chatFontScale", 1),
        extended = true,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("ixChatFontItalics", {
        font = font,
        size = math.max(ScreenScale(7), 17) * ix.option.Get("chatFontScale", 1),
        extended = true,
        weight = 600,
        antialias = true,
        italic = true
    })

    surface.CreateFont("ixSmallTitleFont", {
        font = "Roboto Th",
        size = math.max(ScreenScale(12), 24),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixMinimalTitleFont", {
        font = "Roboto",
        size = math.max(ScreenScale(8), 22),
        extended = true,
        weight = 800
    })

    surface.CreateFont("ixSmallFont", {
        font = font,
        size = math.max(ScreenScale(6), 17),
        extended = true,
        weight = 500
    })

    surface.CreateFont("ixItemDescFont", {
        font = font,
        size = math.max(ScreenScale(6), 17),
        extended = true,
        shadow = true,
        weight = 500
    })

    surface.CreateFont("ixSmallBoldFont", {
        font = font,
        size = math.max(ScreenScale(8), 20),
        extended = true,
        weight = 800
    })

    surface.CreateFont("ixItemBoldFont", {
        font = font,
        shadow = true,
        size = math.max(ScreenScale(8), 20),
        extended = true,
        weight = 800
    })

    -- Introduction fancy font.
    font = "Roboto Th"

    surface.CreateFont("ixIntroTitleFont", {
        font = font,
        size = math.min(ScreenScale(128), 128),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixIntroTitleBlurFont", {
        font = font,
        size = math.min(ScreenScale(128), 128),
        extended = true,
        weight = 100,
        blursize = 4
    })

    surface.CreateFont("ixIntroSubtitleFont", {
        font = font,
        size = ScreenScale(24),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixIntroSmallFont", {
        font = font,
        size = ScreenScale(14),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixIconsSmall", {
        font = "fontello",
        size = 22,
        extended = true,
        weight = 500
    })

    surface.CreateFont("ixSmallTitleIcons", {
        font = "fontello",
        size = math.max(ScreenScale(11), 23),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixIconsMedium", {
        font = "fontello",
        extended = true,
        size = 28,
        weight = 500
    })

    surface.CreateFont("ixIconsMenuButton", {
        font = "fontello",
        size = ScreenScale(14),
        extended = true,
        weight = 100
    })

    surface.CreateFont("ixIconsBig", {
        font = "fontello",
        extended = true,
        size = 48,
        weight = 500
    })
end

function GM:OnCharacterMenuCreated(panel)
    if (IsValid(ix.gui.notices)) then
        ix.gui.notices:Clear()
    end
end

LOWERED_ANGLES = Angle(30, 0, -25)

function GM:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
    if (!IsValid(weapon)) then return end

    local ply = LocalPlayer()
    local bWepRaised = ply:IsWepRaised()

    -- update tween if the raised state is out of date
    if (ply.ixWasWeaponRaised != bWepRaised) then
        local fraction = bWepRaised and 0 or 1

        ply.ixRaisedFraction = 1 - fraction
        ply.ixRaisedTween = ix.tween.new(0.75, ply, {
            ixRaisedFraction = fraction
        }, LOWER_EASE_INOUT or "outQuint")

        ply.ixWasWeaponRaised = bWepRaised
    end

    local fraction = ply.ixRaisedFraction
    local lowerPos = weapon.LowerPosition or Vector(0, 0, 0)
    local rotation = weapon.LowerAngles or LOWERED_ANGLES

    if (ix.option.Get("altLower", true) and weapon.LowerAngles2) then
        rotation = weapon.LowerAngles2
    end

    eyePos = eyePos + lowerPos.x * eyeAngles:Forward() * fraction
    eyePos = eyePos + lowerPos.y * eyeAngles:Right() * fraction
    eyePos = eyePos + lowerPos.z * eyeAngles:Up() * fraction

    eyeAngles:RotateAroundAxis(eyeAngles:Up(), rotation.p * fraction)
    eyeAngles:RotateAroundAxis(eyeAngles:Forward(), rotation.y * fraction)
    eyeAngles:RotateAroundAxis(eyeAngles:Right(), rotation.r * fraction)

    viewModel:SetPos(eyePos)
    viewModel:SetAngles(eyeAngles)

    return self.BaseClass:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAngles, eyePos, eyeAngles)
end

function GM:LoadIntro()
    if (!IsValid(ix.gui.intro)) then
        vgui.Create("ixIntro")
    end
end

function GM:CharacterLoaded()
    local menu = ix.gui.characterMenu

    if (IsValid(menu)) then
        menu:Close((LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()) and true or nil)
    end
end

function GM:InitializedConfig()
    local color = ix.config.Get("color")

    hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))
    hook.Run("ColorSchemeChanged", color)

    if (!ix.config.loaded and !IsValid(ix.gui.loading)) then
        local loader = vgui.Create("DPanel")
        loader:SetDrawOnTop(true)
        loader:SetSize(ScrW(), ScrH())
        loader:MakePopup()
        loader.Think = function(this)
            this:MoveToFront()
        end
        loader.Paint = function(this, width, height)
            surface.SetDrawColor(color_black)
            surface.DrawRect(0, 0, width, height)
        end

        local statusLabel = loader:Add("DLabel")
        statusLabel:SetText(L"loading")
        statusLabel:SetFont("ixTitleFont")
        statusLabel:SetTextColor(color_white)
        statusLabel:SizeToContents()
        statusLabel:Center()

        timer.Simple(5, function()
            if (IsValid(ix.gui.loading)) then
                local fatalError = GetGlobalString("fatalError", "")
                if (fatalError and fatalError != "") then
                    local label = loader:Add("DLabel")
                    label:SetFont("ixSubTitleFont")
                    label:SetText(fault)
                    label:SetTextColor(Color(255, 50, 50))
                    label:SizeToContents()
                    label:Center()
                    label:SetY(statusLabel:GetTall() + 8)
                end
            end
        end)

        ix.gui.loading = loader
        ix.config.loaded = true

        if (ix.config.Get("intro", true) and ix.option.Get("showIntro", true)) then
            hook.Run("LoadIntro")
        end
    end
end

if (IsValid(ix.gui.loading)) then
    ix.gui.loading:Remove()
end

function GM:InitPostEntity()
    ix.joinTime = RealTime() - 0.9716
    ix.option.Sync()

    ix.gui.bars = vgui.Create("ixInfoBarManager")
end

function GM:NetworkEntityCreated(entity)
    if (entity:IsPlayer()) then
        entity:SetIK(false)

        -- we've just discovered a new player, so we need to update their animation state
        if (entity != LocalPlayer()) then
            -- we don't need to call the PlayerWeaponChanged hook here since it'll be handled below,
            -- when this player's weapon has been discovered
            hook.Run("PlayerModelChanged", entity, entity:GetModel())
        end
    elseif (entity:IsWeapon()) then
        local owner = entity:GetOwner()

        if (IsValid(owner) and owner:IsPlayer() and entity == owner:GetActiveWeapon()) then
            hook.Run("PlayerWeaponChanged", owner, entity)
        end
    end
end

local vignette = ix.util.GetMaterial("helix/gui/vignette.png")
local vignetteAlphaGoal = 0
local vignetteAlphaDelta = 0
local vignetteTraceHeight = Vector(0, 0, 768)
local blurGoal = 0
local blurDelta = 0
local hasVignetteMaterial = !vignette:IsError()

timer.Create("ixVignetteChecker", 1, 0, function()
    local ply = LocalPlayer()

    if (IsValid(ply)) then
        local data = {}
            data.start = ply:GetPos()
            data.endpos = data.start + vignetteTraceHeight
            data.filter = ply
        local trace = util.TraceLine(data)

        -- this timer could run before InitPostEntity is called, so we have to check for the validity of the trace table
        if (trace and trace.Hit) then
            vignetteAlphaGoal = 80
        else
            vignetteAlphaGoal = 0
        end
    end
end)

function GM:CalcView(ply, origin, angles, fov)
    local view = self.BaseClass:CalcView(ply, origin, angles, fov) or {}
    local entity = Entity(ply:GetLocalVar("ragdoll", 0))
    local ragdoll = IsValid(ply:GetRagdollEntity()) and ply:GetRagdollEntity() or entity

    if ((!ply:ShouldDrawLocalPlayer() and IsValid(entity) and entity:IsRagdoll())
    or (!LocalPlayer():Alive() and IsValid(ragdoll))) then
        local ent = LocalPlayer():Alive() and entity or ragdoll
        local index = ent:LookupAttachment("eyes")

        if (index) then
            local data = ent:GetAttachment(index)

            if (data) then
                view.origin = data.Pos
                view.angles = data.Ang
            end

            return view
        end
    end

    local menu = ix.gui.menu
    local entityMenu = ix.menu.panel

    if (IsValid(menu) and menu:IsVisible() and menu:GetCharacterOverview()) then
        local newOrigin, newAngles, newFOV, bDrawPlayer = menu:GetOverviewInfo(origin, angles, fov)

        view.drawviewer = bDrawPlayer
        view.fov = newFOV
        view.origin = newOrigin
        view.angles = newAngles
    elseif (IsValid(entityMenu)) then
        view.angles = entityMenu:GetOverviewInfo(origin, angles)
    end

    return view
end

local hookRun = hook.Run

do
    local aimLength = 0.35
    local aimTime = 0
    local aimEntity
    local lastEntity
    local lastTrace = {}

    timer.Create("ixCheckTargetEntity", 0.1, 0, function()
        local ply = LocalPlayer()
        local time = SysTime()

        if (!IsValid(ply)) then return end

        local char = ply:GetCharacter()
        if (!char) then return end

        lastTrace.start = ply:GetShootPos()
        lastTrace.endpos = lastTrace.start + ply:GetAimVector(ply) * 160
        lastTrace.filter = ply
        lastTrace.mask = MASK_SHOT_HULL

        lastEntity = util.TraceHull(lastTrace).Entity

        if (lastEntity != aimEntity) then
            aimTime = time + aimLength
            aimEntity = lastEntity
        end

        local panel = ix.gui.entityInfo
        local bShouldShow = time >= aimTime and (!IsValid(ix.gui.menu) or ix.gui.menu.bClosing) and
            (!IsValid(ix.gui.characterMenu) or ix.gui.characterMenu.bClosing)
        local bShouldPopulate = lastEntity.OnShouldPopulateEntityInfo and lastEntity:OnShouldPopulateEntityInfo() or true

        if (bShouldShow and IsValid(lastEntity) and hookRun("ShouldPopulateEntityInfo", lastEntity) != false and
            (lastEntity.PopulateEntityInfo or bShouldPopulate)) then

            if (!IsValid(panel) or (IsValid(panel) and panel:GetEntity() != lastEntity)) then
                if (IsValid(ix.gui.entityInfo)) then
                    ix.gui.entityInfo:Remove()
                end

                local infoPanel = vgui.Create(ix.option.Get("minimalTooltips", false) and "ixTooltipMinimal" or "ixTooltip")
                local entityPlayer = lastEntity:GetNetVar("player")

                if (entityPlayer) then
                    infoPanel:SetEntity(entityPlayer)
                    infoPanel.entity = lastEntity
                else
                    infoPanel:SetEntity(lastEntity)
                end

                infoPanel:SetDrawArrow(true)
                ix.gui.entityInfo = infoPanel
            end
        elseif (IsValid(panel)) then
            panel:Remove()
        end
    end)
end

local mathApproach = math.Approach
local surface = surface

function GM:HUDPaintBackground()
    local ply = LocalPlayer()

    if (!ply:GetCharacter()) then return end

    local frameTime = FrameTime()
    local scrW, scrH = ScrW(), ScrH()

    if (hasVignetteMaterial and ix.config.Get("vignette")) then
        vignetteAlphaDelta = mathApproach(vignetteAlphaDelta, vignetteAlphaGoal, frameTime * 30)

        local drawVignette = hook.Run("DrawVignette", vignetteAlphaDelta)
        if (drawVignette != false) then
            surface.SetDrawColor(0, 0, 0, 175 + vignetteAlphaDelta)
            surface.SetMaterial(vignette)
            surface.DrawTexturedRect(0, 0, scrW, scrH)
        end
    end

    blurGoal = ply:GetLocalVar("blur", 0) + (hookRun("AdjustBlurAmount", blurGoal) or 0)

    if (blurDelta != blurGoal) then
        blurDelta = mathApproach(blurDelta, blurGoal, frameTime * 20)
    end

    if (blurDelta > 0 and !ply:ShouldDrawLocalPlayer()) then
        ix.util.DrawBlurAt(0, 0, scrW, scrH, blurDelta)
    end

    self.BaseClass:PaintWorldTips()

    local weapon = ply:GetActiveWeapon()

    if (IsValid(weapon) and hook.Run("CanDrawAmmoHUD", weapon) != false and weapon.DrawAmmo != false) then
        local clip = weapon:Clip1()
        local clipMax = weapon:GetMaxClip1()
        local count = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
        local secondary = ply:GetAmmoCount(weapon:GetSecondaryAmmoType())
        local x, y = scrW - 80, scrH - 80

        if (secondary > 0) then
            ix.util.DrawBlurAt(x, y, 64, 64)

            surface.SetDrawColor(255, 255, 255, 5)
            surface.DrawRect(x, y, 64, 64)
            surface.SetDrawColor(255, 255, 255, 3)
            surface.DrawOutlinedRect(x, y, 64, 64)

            ix.util.DrawText(secondary, x + 32, y + 32, nil, 1, 1, "ixBigFont")
        end

        if (weapon:GetClass() != "weapon_slam" and clip > 0 or count > 0) then
            x = x - (secondary > 0 and 144 or 64)

            ix.util.DrawBlurAt(x, y, 128, 64)

            surface.SetDrawColor(255, 255, 255, 5)
            surface.DrawRect(x, y, 128, 64)
            surface.SetDrawColor(255, 255, 255, 3)
            surface.DrawOutlinedRect(x, y, 128, 64)

            ix.util.DrawText((clip == -1 or clipMax == -1) and count or clip.."/"..count, x + 64, y + 32, nil, 1, 1, "ixBigFont")
        end
    end

    if (ply:GetLocalVar("restricted") and !ply:GetLocalVar("restrictNoMsg")) then
        ix.util.DrawText(L"restricted", scrW * 0.5, scrH * 0.33, nil, 1, 1, "ixBigFont")
    end
end

function GM:PostDrawOpaqueRenderables(bDepth, bSkybox)
    if (bDepth or bSkybox or #ix.blurRenderQueue == 0) then return end

    ix.util.ResetStencilValues()

    render.SetStencilEnable(true)
        render.SetStencilWriteMask(27)
        render.SetStencilTestMask(27)
        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
        render.SetStencilReferenceValue(27)

        for i = 1, #ix.blurRenderQueue do
            ix.blurRenderQueue[i]()
        end

        render.SetStencilReferenceValue(34)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilReferenceValue(27)

        cam.Start2D()
            ix.util.DrawBlurAt(0, 0, ScrW(), ScrH())
        cam.End2D()
    render.SetStencilEnable(false)

    ix.blurRenderQueue = {}
end

function GM:PostDrawHUD()
    cam.Start2D()
        ix.hud.DrawAll()

        if (!IsValid(ix.gui.deathScreen) and (!IsValid(ix.gui.characterMenu) or ix.gui.characterMenu:IsClosing())) then
            ix.bar.DrawAction()
        end
    cam.End2D()
end

function GM:ShouldPopulateEntityInfo(entity)
    local ply = LocalPlayer()
    local ragdoll = Entity(ply:GetLocalVar("ragdoll", 0))
    local entityPlayer = entity:GetNetVar("player")

    if (vgui.CursorVisible() or !ply:Alive() or IsValid(ragdoll) or entity == ply or entityPlayer == ply) then return false end
end

local injTextTable = {
    [0.3] = {"injMajor", Color(192, 57, 43)},
    [0.6] = {"injLittle", Color(231, 76, 60)},
}

function GM:GetInjuredText(ply)
    local health = ply:Health()
    for k, v in pairs(injTextTable) do
        if ( ( health / ply:GetMaxHealth() ) < k ) then
            return v[1], v[2]
        end
    end
end

function GM:PopulateImportantCharacterInfo(ply, char, container)
    local color = team.GetColor(ply:Team())
    container:SetArrowColor(color)

    -- name
    local name = container:AddRow("name")
    name:SetImportant()
    name:SetText(hookRun("GetCharacterName", ply) or char:GetName())
    name:SetBackgroundColor(color)
    name:SizeToContents()

    -- injured text
    local injureText, injureTextColor = hookRun("GetInjuredText", ply)

    if (injureText) then
        local injure = container:AddRow("injureText")

        injure:SetText(L(injureText))
        injure:SetBackgroundColor(injureTextColor)
        injure:SizeToContents()
    end
end

function GM:PopulateCharacterInfo(ply, char, container)
    -- description
    local descriptionText = char:GetDescription()
    descriptionText = (descriptionText:utf8len() > 128 and
        string.format("%s...", descriptionText:utf8sub(1, 125)) or
        descriptionText)

    if (descriptionText != "") then
        local description = container:AddRow("description")
        description:SetText(descriptionText)
        description:SizeToContents()
    end
end

function GM:KeyRelease(ply, key)
    if (!IsFirstTimePredicted()) then return end

    if (key == IN_USE) then
        if (!ix.menu.IsOpen()) then
            local data = {}
            data.start = ply:GetShootPos()
            data.endpos = data.start + ply:GetAimVector() * 96
            data.filter = ply

            local entity = util.TraceLine(data).Entity

            if (IsValid(entity) and isfunction(entity.GetEntityMenu)) then
                hook.Run("ShowEntityMenu", entity)
            end
        end

        timer.Remove("ixItemUse")

        ply.ixInteractionTarget = nil
        ply.ixInteractionStartTime = nil
    end
end

function GM:PlayerBindPress(ply, bind, pressed)
    bind = bind:lower()

    if (bind:find("use") and pressed) then
        local pickupTime = ix.config.Get("itemPickupTime", 0.5)

        if (pickupTime > 0) then
            local data = {}
                data.start = ply:GetShootPos()
                data.endpos = data.start + ply:GetAimVector() * 96
                data.filter = ply
            local entity = util.TraceLine(data).Entity

            if (IsValid(entity) and entity.ShowPlayerInteraction and !ix.menu.IsOpen()) then
                ply.ixInteractionTarget = entity
                ply.ixInteractionStartTime = SysTime()

                timer.Create("ixItemUse", pickupTime, 1, function()
                    ply.ixInteractionTarget = nil
                    ply.ixInteractionStartTime = nil
                end)
            end
        end
    elseif (bind:find("jump")) then
        local entity = Entity(ply:GetLocalVar("ragdoll", 0))
        if (IsValid(entity)) then
            ix.command.Send("CharGetUp")
        end
    elseif (bind:find("speed") and ply:KeyDown(IN_WALK) and pressed and !ply:InVehicle()) then
        if (LocalPlayer():Crouching()) then
            RunConsoleCommand("-duck")
        else
            RunConsoleCommand("+duck")
        end
    end
end

function GM:CreateMove(command)
    if ((IsValid(ix.gui.characterMenu) and !ix.gui.characterMenu.bClosing) or (IsValid(ix.gui.menu) and !ix.gui.menu.bClosing and ix.gui.menu:GetActiveTab() == "you")) then
        command:ClearButtons()
        command:ClearMovement()
    end
end

-- Called when use has been pressed on an item.
function GM:ShowEntityMenu(entity)
    local options = entity:GetEntityMenu(LocalPlayer())

    if (istable(options) and !table.IsEmpty(options)) then
        ix.menu.Open(options, entity)
    end
end

local hidden = {}
hidden["CHudHealth"] = true
hidden["CHudBattery"] = true
hidden["CHudAmmo"] = true
hidden["CHudSecondaryAmmo"] = true
hidden["CHudCrosshair"] = true
hidden["CHudHistoryResource"] = true
hidden["CHudPoisonDamageIndicator"] = true
hidden["CHudSquadStatus"] = true
hidden["CHUDQuickInfo"] = true

function GM:HUDShouldDraw(element)
    if (hidden[element]) then return false end

    return true
end

function GM:ShouldDrawLocalPlayer(ply)
    if (IsValid(ix.gui.characterMenu) and ix.gui.characterMenu:IsVisible()) then return false end
end

function GM:PostProcessPermitted(class)
    return false
end

function GM:RenderScreenspaceEffects()
    local menu = ix.gui.menu

    if (IsValid(menu) and menu:GetCharacterOverview()) then
        local ply = LocalPlayer()
        local target = ply:GetObserverTarget()
        local weapon = ply:GetActiveWeapon()

        cam.Start3D()
            ix.util.ResetStencilValues()

            render.SetStencilEnable(true)
            render.SuppressEngineLighting(true)

            cam.IgnoreZ(true)
                render.SetColorModulation(1, 1, 1)
                render.SetStencilWriteMask(28)
                render.SetStencilTestMask(28)
                render.SetStencilReferenceValue(28)

                render.SetStencilCompareFunction(STENCIL_ALWAYS)
                render.SetStencilPassOperation(STENCIL_REPLACE)
                render.SetStencilFailOperation(STENCIL_KEEP)
                render.SetStencilZFailOperation(STENCIL_KEEP)

                if (IsValid(target)) then
                    target:DrawModel()
                else
                    ply:DrawModel()
                end

                if (IsValid(weapon)) then
                    weapon:DrawModel()
                end

                hook.Run("DrawCharacterOverview")

                render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
                render.SetStencilPassOperation(STENCIL_KEEP)

                cam.Start2D()
                    derma.SkinFunc("DrawCharacterStatusBackground", menu, menu.overviewFraction)
                cam.End2D()
            cam.IgnoreZ(false)

            render.SuppressEngineLighting(false)
            render.SetStencilEnable(false)
        cam.End3D()
    end
end

function GM:ShowPlayerOptions(ply, options)
    options["viewProfile"] = {"icon16/user.png", function()
        if (IsValid(ply)) then
            ply:ShowProfile()
        end
    end}

    options["Copy Steam ID"] = {"icon16/user.png", function()
        if (IsValid(ply)) then
            SetClipboardText(ply:SteamID())
        end
    end}

    options["Copy Steam ID64"] = {"icon16/user.png", function()
        if (IsValid(ply)) then
            SetClipboardText(ply:SteamID64())
        end
    end}
end

function GM:DrawHelixModelView(panel, ent)
    if (ent.weapon and IsValid(ent.weapon)) then
        ent.weapon:DrawModel()
    end
end

net.Receive("ixStringRequest", function()
    local time = net.ReadUInt(32)
    local title, subTitle = net.ReadString(), net.ReadString()
    local default = net.ReadString()

    if (title:sub(1, 1) == "@") then
        title = L(title:sub(2))
    end

    if (subTitle:sub(1, 1) == "@") then
        subTitle = L(subTitle:sub(2))
    end

    Derma_StringRequest(title, subTitle, default or "", function(text)
        net.Start("ixStringRequest")
            net.WriteUInt(time, 32)
            net.WriteString(text)
        net.SendToServer()
    end)
end)

net.Receive("ixPlayerDeath", function()
    if (IsValid(ix.gui.deathScreen)) then
        ix.gui.deathScreen:Remove()
    end

    ix.gui.deathScreen = vgui.Create("ixDeathScreen")
end)

function GM:Think()
    local ply = LocalPlayer()
    if (IsValid(ply) and ply:Alive() and ply.ixRaisedTween) then
        ply.ixRaisedTween:update(FrameTime())
    end
end

function GM:ScreenResolutionChanged(oldW, oldH)
    hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))

    if (IsValid(ix.gui.notices)) then
        ix.gui.notices:Remove()
        ix.gui.notices = vgui.Create("ixNoticeManager")
    end

    if (IsValid(ix.gui.bars)) then
        ix.gui.bars:Remove()
        ix.gui.bars = vgui.Create("ixInfoBarManager")
    end
end

function GM:DrawDeathNotice()
    return false
end

function GM:HUDAmmoPickedUp()
    return false
end

function GM:HUDDrawPickupHistory()
    return false
end

function GM:HUDDrawTargetID()
    return false
end

function GM:PlayerStartVoice(target)
    net.Start("ixPlayerStartVoice")
        net.WritePlayer(target)
    net.SendToServer()
end

function GM:PlayerEndVoice(target)
    net.Start("ixPlayerEndVoice")
        net.WritePlayer(target)
    net.SendToServer()
end

function GM:StartChat(bTeamChat)
    net.Start("ixStartChat")
        net.WriteBool(bTeamChat)
    net.SendToServer()
end

function GM:FinishChat()
    net.Start("ixFinishChat")
    net.SendToServer()
end

function GM:BuildBusinessMenu()
    if (!ix.config.Get("allowBusiness", true)) then
        return false
    end
end

gameevent.Listen("player_spawn")
hook.Add("player_spawn", "ixPlayerSpawn", function(data)
    local ply = Player(data.userid)

    if (IsValid(ply)) then
        -- GetBoneName returns __INVALIDBONE__ for everything the first time you use it, so we'll force an update to make them valid
        ply:SetupBones()
        ply:SetIK(false)

        if (ply == LocalPlayer() and (IsValid(ix.gui.deathScreen) and !ix.gui.deathScreen:IsClosing())) then
            ix.gui.deathScreen:Close()
        end
    end
end)

net.Receive("ixChatAddText", function()
    local args = net.ReadTable()

    chat.AddText(unpack(args))
end)

net.Receive("ixMapRestart", function()
    local delay = net.ReadFloat()
    Derma_Query(L("mapRestartConfirmation"), L("mapRestart"), L("yes"), function()
        net.Start("ixMapRestart")
            net.WriteFloat(delay)
        net.SendToServer()
    end, L("no"), function() end)
end)