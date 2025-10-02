local ADDON_NAME = "MinimalMiniMap"
local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")

---@diagnostic disable: undefined-global

local TEXTURE_PATH = "Interface\\AddOns\\MinimalMiniMap\\square.tga"
local FONT_PATH = "Interface\\AddOns\\MinimalMiniMap\\MMM.ttf"

local DEFAULTS = {
    MOUSEOVER = false,
    BUTTONS   = true,
    MM_SCALE  = 1.1,
    BORDER_OPACITY = 0.1,
    HNS       = true,
    ZONE_TEXT_Y = 2,
    CLOCK_Y = -2,
    POSITION  = {
        point = "TOPRIGHT",
        relativePoint = "TOPRIGHT",
        x = -5,
        y = -10,
    },
    UNLOCKED = false,
    BUFF_UNLOCKED = false,
    BUFF_POSITION = {
        point = "TOPRIGHT",
        relativePoint = "TOPRIGHT",
        x = -200,
        y = -10,
    },
}

local guiFrame, scaleSlider

local function GetAbsoluteCenter(frame)
    if not frame then return end
    local scale = frame:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    local x, y = frame:GetCenter()
    if not x or not y then return end
    return x * scale, y * scale
end

local function SetAbsoluteCenter(frame, absX, absY)
    if not frame or not absX or not absY then return end
    local scale = frame:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absX / scale, absY / scale)
end

local function CopyDefaults(src, dest)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then dest[k] = {} end
            CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

local function InitDB()
    if not MinimalMiniMapDB then MinimalMiniMapDB = {} end
    CopyDefaults(DEFAULTS, MinimalMiniMapDB)
end

local function ApplyMask()
    if Minimap then
        Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
    end
end

local function ApplyBorderTexture(frame)
    if not frame then return end
    frame:SetTexture(TEXTURE_PATH)
    frame:SetAlpha(MinimalMiniMapDB.BORDER_OPACITY or 0.1)
    frame:Show()
end

local function ApplyBorder()
    ApplyBorderTexture(MinimapBorder)
    ApplyBorderTexture(MinimapBorderTop)
end

local function SavePositionFrom(frame)
    local pos = MinimalMiniMapDB.POSITION
    if type(pos) ~= "table" then
        pos = {}
        MinimalMiniMapDB.POSITION = pos
    end
    local absX, absY = GetAbsoluteCenter(frame)
    if absX and absY then
        pos.centerX = absX
        pos.centerY = absY
    end
end

local function ApplyScale(preservePosition)
    if not MinimapCluster then return end

    local absX, absY
    if preservePosition then
        absX, absY = GetAbsoluteCenter(MinimapCluster)
    end

    MinimapCluster:SetScale(MinimalMiniMapDB.MM_SCALE)

    if absX and absY then
        SetAbsoluteCenter(MinimapCluster, absX, absY)
        SavePositionFrom(MinimapCluster)
    end
end

local function ApplyButtons()
    if not MinimalMiniMapDB.BUTTONS then return end
    local hide = { MinimapZoomIn, MinimapZoomOut, MinimapToggleButton, MinimapBorderTop, MiniMapWorldMapButton }
    for _, frame in ipairs(hide) do
        if frame then frame:Hide() end
    end
end

local function ShowZoneTextButton()
    if MinimapZoneTextButton then MinimapZoneTextButton:Show() end
end

local function HideZoneTextButton()
    if MinimapZoneTextButton then MinimapZoneTextButton:Hide() end
end

local function ApplyMouseover()
    if not Minimap then return end
    if MinimalMiniMapDB.MOUSEOVER then
        Minimap:SetScript("OnEnter", ShowZoneTextButton)
        Minimap:SetScript("OnLeave", HideZoneTextButton)
        HideZoneTextButton()
    else
        Minimap:SetScript("OnEnter", nil)
        Minimap:SetScript("OnLeave", nil)
        ShowZoneTextButton()
    end
end

local function ApplyNorthTag()
    if MinimapNorthTag then
        MinimapNorthTag:SetAlpha(MinimalMiniMapDB.HNS and 0 or 1)
    end
end

local function ApplyZoneText()
    if MinimapZoneTextButton and Minimap then
        MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, MinimalMiniMapDB.ZONE_TEXT_Y or 2)
    end
    if MinimapZoneText then
        MinimapZoneText:SetFont(FONT_PATH, 11, "OUTLINE")
    end
end

local function ApplyClock()
    if TimeManagerClockButton and Minimap then
        TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, MinimalMiniMapDB.CLOCK_Y or -2)
        local region = TimeManagerClockButton:GetRegions()
        if region then region:Hide() end
    end
    if TimeManagerClockTicker then
        TimeManagerClockTicker:SetFont(FONT_PATH, 12, "OUTLINE")
    end
end

local function ApplyPosition()
    if not MinimapCluster then return end
    local pos = MinimalMiniMapDB.POSITION
    if pos.centerX and pos.centerY then
        SetAbsoluteCenter(MinimapCluster, pos.centerX, pos.centerY)
    else
        local point = pos.point or "TOPRIGHT"
        local relativePoint = pos.relativePoint or point
        local x = pos.x or -5
        local y = pos.y or -10
        MinimapCluster:ClearAllPoints()
        MinimapCluster:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

local function SaveBuffPositionFrom(frame)
    if not frame then return end
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    if not point then return end
    local pos = MinimalMiniMapDB.BUFF_POSITION
    pos.point = point
    pos.relativePoint = relativePoint or point
    pos.x = xOfs or 0
    pos.y = yOfs or 0
end

local function ApplyBuffPosition()
    if not BuffFrame then return end
    local pos = MinimalMiniMapDB.BUFF_POSITION
    local point = pos.point or "TOPRIGHT"
    local relativePoint = pos.relativePoint or point
    local x = pos.x or -200
    local y = pos.y or -10
    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

local function DetachBuffsFromMinimap()
    if BuffFrame then
        BuffFrame:SetParent(UIParent)
        ApplyBuffPosition()
    end
end

local moveOverlay
local buffOverlay

local function CreateOverlay(parent, labelText, labelPoint, r, g, b)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(parent:GetFrameLevel() + 5)
    overlay:EnableMouse(false)

    local texture = overlay:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, 0.25)

    local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    label:SetPoint(labelPoint)
    label:SetText(labelText)
    label:SetTextColor(r, g, b)

    overlay:Hide()
    return overlay
end

local function EnsureBuffOverlay()
    if buffOverlay or not BuffFrame then return end
    buffOverlay = CreateOverlay(BuffFrame, "Move Buffs", "RIGHT", 1, 0.5, 0)
end

local function EnsureMoveOverlay()
    if moveOverlay or not Minimap then return end
    moveOverlay = CreateOverlay(Minimap, "Move Map", "CENTER", 0, 1, 0)
end

local isDragging = false
local dragOffsetX, dragOffsetY = 0, 0

local function GetCursorPositionInUI()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function DragUpdate()
    if not isDragging or not MinimapCluster then return end
    local cursorX, cursorY = GetCursorPositionInUI()
    local newLeft = cursorX - dragOffsetX
    local newTop = cursorY + dragOffsetY
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newLeft, newTop)
end

local function StartDrag()
    if not MinimapCluster or not MinimalMiniMapDB or not MinimalMiniMapDB.UNLOCKED then return end
    local left = MinimapCluster:GetLeft()
    local top = MinimapCluster:GetTop()
    local right = MinimapCluster:GetRight()
    local bottom = MinimapCluster:GetBottom()
    if not left or not top or not right or not bottom then return end

    local cursorX, cursorY = GetCursorPositionInUI()
    dragOffsetX = cursorX - left
    dragOffsetY = top - cursorY
    isDragging = true
    addon:SetScript("OnUpdate", DragUpdate)
end

local function StopDrag()
    if not isDragging then return end
    DragUpdate()
    isDragging = false
    addon:SetScript("OnUpdate", nil)
    SavePositionFrom(MinimapCluster)
    ApplyPosition()
end

local function ApplyBuffUnlockState()
    if not BuffFrame then return end
    EnsureBuffOverlay()
    local unlocked = MinimalMiniMapDB and MinimalMiniMapDB.BUFF_UNLOCKED
    if unlocked then
        buffOverlay:Show()
    else
        buffOverlay:Hide()
    end
    if guiFrame and guiFrame.buffUnlockCheck then
        guiFrame.buffUnlockCheck:SetChecked(unlocked)
    end
end

local function ApplyUnlockState()
    if not Minimap then return end
    EnsureMoveOverlay()
    local unlocked = MinimalMiniMapDB and MinimalMiniMapDB.UNLOCKED
    if unlocked then
        moveOverlay:Show()
    else
        StopDrag()
        moveOverlay:Hide()
    end
    if guiFrame and guiFrame.unlockCheck then
        guiFrame.unlockCheck:SetChecked(unlocked)
    end
end

local function EnableBuffDragging()
    if not BuffFrame then return end
    if BuffFrame.__MinimalMiniMapDragging then return end
    BuffFrame.__MinimalMiniMapDragging = true

    BuffFrame:SetMovable(true)
    BuffFrame:SetUserPlaced(true)
    BuffFrame:SetClampedToScreen(false)
    BuffFrame:EnableMouse(true)
    BuffFrame:RegisterForDrag("LeftButton")

    BuffFrame:SetScript("OnDragStart", function(frame)
        if MinimalMiniMapDB and MinimalMiniMapDB.BUFF_UNLOCKED then
            frame:StartMoving()
            frame.__MinimalMiniMapIsMoving = true
        else
            frame.__MinimalMiniMapIsMoving = nil
        end
    end)

    local function FinishBuffDrag(frame)
        if frame.__MinimalMiniMapIsMoving then
            frame:StopMovingOrSizing()
            frame.__MinimalMiniMapIsMoving = nil
            SaveBuffPositionFrom(frame)
            ApplyBuffPosition()
        end
    end

    BuffFrame:SetScript("OnDragStop", FinishBuffDrag)
    BuffFrame:HookScript("OnMouseUp", FinishBuffDrag)
    BuffFrame:HookScript("OnHide", FinishBuffDrag)
end

local function EnableDragging()
    if not MinimapCluster or not Minimap then return end
    if MinimapCluster.__MinimalMiniMapDragging then return end
    MinimapCluster.__MinimalMiniMapDragging = true

    MinimapCluster:SetMovable(true)
    MinimapCluster:SetUserPlaced(true)
    MinimapCluster:SetClampedToScreen(false)

    Minimap:HookScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and MinimalMiniMapDB and MinimalMiniMapDB.UNLOCKED then
            StartDrag()
        end
    end)

    Minimap:HookScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            StopDrag()
        end
    end)

    Minimap:HookScript("OnHide", StopDrag)
end

local function ApplyCore()
    if MinimapCluster then
        ApplyScale()
        ApplyPosition()
    end
    if GameTimeFrame then GameTimeFrame:Hide() end
    ApplyMask()
    ApplyBorder()
    ApplyButtons()
    ApplyMouseover()
    ApplyNorthTag()
    ApplyZoneText()
    ApplyClock()
    GetMinimapShape = function() return "SQUARE" end
    DetachBuffsFromMinimap()
    EnableDragging()
    EnableBuffDragging()
    ApplyUnlockState()
    ApplyBuffUnlockState()
    if Minimap then
        Minimap:EnableMouseWheel(true)
        Minimap:SetScript("OnMouseWheel", function(_, z) if z>0 then Minimap_ZoomIn() else Minimap_ZoomOut() end end)
    end
end

addon:SetScript("OnEvent", function(_, evt)
    if evt == "PLAYER_ENTERING_WORLD" then
        InitDB()
        ApplyCore()
        addon:UnregisterEvent(evt)
    end
end)

local function CreateGUI()
    if guiFrame then return end
    guiFrame = CreateFrame("Frame", "MinimalMiniMapGUI", UIParent)
    guiFrame:SetSize(200, 360)
    guiFrame:SetPoint("CENTER")
    guiFrame:Hide()
    guiFrame:SetMovable(true)
    guiFrame:EnableMouse(true)
    guiFrame:RegisterForDrag("LeftButton")
    guiFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    guiFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    guiFrame:SetClampedToScreen(true)
    
    -- Background
    local border = guiFrame:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)
    
    local bg = guiFrame:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.95)
    
    -- Title
    guiFrame.title = guiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guiFrame.title:SetPoint("TOP", 0, -8)
    guiFrame.title:SetText("MinimalMiniMap")
    guiFrame.title:SetTextColor(0.8, 0.8, 0.8)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, guiFrame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function() guiFrame:Hide() end)

    -- Minimap Section Header
    local minimapHeader = guiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minimapHeader:SetPoint("TOPLEFT", 10, -30)
    minimapHeader:SetText("MINIMAP")
    minimapHeader:SetTextColor(0.5, 0.9, 0.5)

    -- Scale Slider
    scaleSlider = CreateFrame("Slider", "MMMScaleSlider", guiFrame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", minimapHeader, "BOTTOMLEFT", 5, -12)
    scaleSlider:SetSize(160, 16)
    scaleSlider:SetMinMaxValues(0.5, 2)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(MinimalMiniMapDB.MM_SCALE)
    MMMScaleSliderLow:SetText("0.5")
    MMMScaleSliderHigh:SetText("2")
    MMMScaleSliderText:SetText("Scale: " .. MinimalMiniMapDB.MM_SCALE)
    MMMScaleSliderText:SetTextColor(0.9, 0.9, 0.9)
    scaleSlider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v*100 + 0.5)/100
        MinimalMiniMapDB.MM_SCALE = v
        MMMScaleSliderText:SetText("Scale: " .. v)
        ApplyScale(true)
    end)

    -- Opacity Slider
    local opacitySlider = CreateFrame("Slider", "MMMOpacitySlider", guiFrame, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -28)
    opacitySlider:SetSize(160, 16)
    opacitySlider:SetMinMaxValues(0, 1)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetValue(MinimalMiniMapDB.BORDER_OPACITY)
    MMMOpacitySliderLow:SetText("0")
    MMMOpacitySliderHigh:SetText("1")
    MMMOpacitySliderText:SetText("Border Opacity: " .. MinimalMiniMapDB.BORDER_OPACITY)
    MMMOpacitySliderText:SetTextColor(0.9, 0.9, 0.9)
    opacitySlider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v*100 + 0.5)/100
        MinimalMiniMapDB.BORDER_OPACITY = v
        MMMOpacitySliderText:SetText("Border Opacity: " .. v)
        ApplyBorder()
    end)

    local function CreateCheckButton(name, labelText, anchorPoint, xOffset, yOffset, dbKey, applyFunc)
        local check = CreateFrame("CheckButton", nil, guiFrame, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", anchorPoint, "BOTTOMLEFT", xOffset, yOffset)
        check:SetSize(20, 20)
        check:SetChecked(MinimalMiniMapDB[dbKey])
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        check.text:SetPoint("LEFT", check, "RIGHT", 0, 0)
        check.text:SetText(labelText)
        check:SetScript("OnClick", function(self)
            MinimalMiniMapDB[dbKey] = self:GetChecked() and true or false
            applyFunc()
            local state = MinimalMiniMapDB[dbKey] and "unlocked" or "locked"
            print(ADDON_NAME .. ": " .. name .. " " .. state .. (state == "unlocked" and ". Drag to move." or "."))
        end)
        return check
    end

    -- Zone Text Y Slider
    local zoneTextYSlider = CreateFrame("Slider", "MMMZoneTextYSlider", guiFrame, "OptionsSliderTemplate")
    zoneTextYSlider:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -28)
    zoneTextYSlider:SetSize(160, 16)
    zoneTextYSlider:SetMinMaxValues(-50, 50)
    zoneTextYSlider:SetValueStep(1)
    zoneTextYSlider:SetObeyStepOnDrag(true)
    zoneTextYSlider:SetValue(MinimalMiniMapDB.ZONE_TEXT_Y)
    MMMZoneTextYSliderLow:SetText("-50")
    MMMZoneTextYSliderHigh:SetText("50")
    MMMZoneTextYSliderText:SetText("Zone Text Position: " .. MinimalMiniMapDB.ZONE_TEXT_Y)
    MMMZoneTextYSliderText:SetTextColor(0.9, 0.9, 0.9)
    zoneTextYSlider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v + 0.5)
        MinimalMiniMapDB.ZONE_TEXT_Y = v
        MMMZoneTextYSliderText:SetText("Zone Text Position: " .. v)
        ApplyZoneText()
    end)

    -- Clock Y Slider
    local clockYSlider = CreateFrame("Slider", "MMMClockYSlider", guiFrame, "OptionsSliderTemplate")
    clockYSlider:SetPoint("TOPLEFT", zoneTextYSlider, "BOTTOMLEFT", 0, -28)
    clockYSlider:SetSize(160, 16)
    clockYSlider:SetMinMaxValues(-50, 50)
    clockYSlider:SetValueStep(1)
    clockYSlider:SetObeyStepOnDrag(true)
    clockYSlider:SetValue(MinimalMiniMapDB.CLOCK_Y)
    MMMClockYSliderLow:SetText("-50")
    MMMClockYSliderHigh:SetText("50")
    MMMClockYSliderText:SetText("Clock Text Position: " .. MinimalMiniMapDB.CLOCK_Y)
    MMMClockYSliderText:SetTextColor(0.9, 0.9, 0.9)
    clockYSlider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v + 0.5)
        MinimalMiniMapDB.CLOCK_Y = v
        MMMClockYSliderText:SetText("Clock Text Position: " .. v)
        ApplyClock()
    end)

    guiFrame.unlockCheck = CreateCheckButton("minimap", "Unlock Minimap", clockYSlider, -5, -22, "UNLOCKED", ApplyUnlockState)

    -- Buffs Section Header
    local buffsHeader = guiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buffsHeader:SetPoint("TOPLEFT", guiFrame.unlockCheck, "BOTTOMLEFT", 5, -12)
    buffsHeader:SetText("BUFFS")
    buffsHeader:SetTextColor(0.9, 0.7, 0.3)

    guiFrame.buffUnlockCheck = CreateCheckButton("buffs", "Unlock Buff Panel", buffsHeader, -5, -8, "BUFF_UNLOCKED", ApplyBuffUnlockState)
end

SLASH_MINIMALMINIMAP1 = "/mmm"
SlashCmdList.MINIMALMINIMAP = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", "")
    if msg:find("^scale") then
        local val = tonumber(msg:match("scale%s+([%d%.]+)"))
        if val and val>=0.5 and val<=2 then
            MinimalMiniMapDB.MM_SCALE = val
            ApplyScale(true)
            if scaleSlider then
                scaleSlider:SetValue(val)
            end
            print(ADDON_NAME .. ": scale set to " .. val)
        else
            print(ADDON_NAME .. ": use /mmm scale 0.5 - 2")
        end
        return
    end
    CreateGUI()
    if guiFrame:IsShown() then guiFrame:Hide() else guiFrame:Show() end
end
