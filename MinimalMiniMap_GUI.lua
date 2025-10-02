---@diagnostic disable: undefined-global

local MinimalMiniMap = _G.MinimalMiniMap
if not MinimalMiniMap then return end

local function getDB()
    return MinimalMiniMap:GetDB()
end

local state = MinimalMiniMap:GetState()

local function formatScale(value)
    return math.floor(value * 100 + 0.5) / 100
end

function MinimalMiniMap:EnsureGUI()
    if state.guiFrame then return state.guiFrame end
    return self:CreateGUI()
end

function MinimalMiniMap:CreateGUI()
    if state.guiFrame then return state.guiFrame end

    local db = getDB()

    local frame = CreateFrame("Frame", "MinimalMiniMapGUI", UIParent)
    frame:SetSize(200, 440)
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)

    -- Background
    local border = frame:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)

    local bg = frame:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.95)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -8)
    frame.title:SetText(self.name)
    frame.title:SetTextColor(0.8, 0.8, 0.8)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Minimap Section Header
    local minimapHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minimapHeader:SetPoint("TOPLEFT", 10, -30)
    minimapHeader:SetText("MINIMAP")
    minimapHeader:SetTextColor(0.5, 0.9, 0.5)

    -- Scale Slider
    local scaleSlider = CreateFrame("Slider", "MMMScaleSlider", frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", minimapHeader, "BOTTOMLEFT", 5, -12)
    scaleSlider:SetSize(160, 16)
    scaleSlider:SetMinMaxValues(0.5, 2)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(db.MM_SCALE)
    MMMScaleSliderLow:SetText("0.5")
    MMMScaleSliderHigh:SetText("2")
    MMMScaleSliderText:SetText("Scale: " .. db.MM_SCALE)
    MMMScaleSliderText:SetTextColor(0.9, 0.9, 0.9)
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.MM_SCALE = value
        MMMScaleSliderText:SetText("Scale: " .. value)
        MinimalMiniMap:ApplyScale(true)
    end)

    -- Opacity Slider
    local opacitySlider = CreateFrame("Slider", "MMMOpacitySlider", frame, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -28)
    opacitySlider:SetSize(160, 16)
    opacitySlider:SetMinMaxValues(0, 1)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetValue(db.BORDER_OPACITY)
    MMMOpacitySliderLow:SetText("0")
    MMMOpacitySliderHigh:SetText("1")
    MMMOpacitySliderText:SetText("Border Opacity: " .. db.BORDER_OPACITY)
    MMMOpacitySliderText:SetTextColor(0.9, 0.9, 0.9)
    opacitySlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.BORDER_OPACITY = value
        MMMOpacitySliderText:SetText("Border Opacity: " .. value)
        MinimalMiniMap:ApplyBorder()
    end)

    -- Zone Text Y Slider
    local zoneTextYSlider = CreateFrame("Slider", "MMMZoneTextYSlider", frame, "OptionsSliderTemplate")
    zoneTextYSlider:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -28)
    zoneTextYSlider:SetSize(160, 16)
    zoneTextYSlider:SetMinMaxValues(-50, 50)
    zoneTextYSlider:SetValueStep(1)
    zoneTextYSlider:SetObeyStepOnDrag(true)
    zoneTextYSlider:SetValue(db.ZONE_TEXT_Y)
    MMMZoneTextYSliderLow:SetText("-50")
    MMMZoneTextYSliderHigh:SetText("50")
    MMMZoneTextYSliderText:SetText("Zone Text Position: " .. db.ZONE_TEXT_Y)
    MMMZoneTextYSliderText:SetTextColor(0.9, 0.9, 0.9)
    zoneTextYSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.ZONE_TEXT_Y = value
        MMMZoneTextYSliderText:SetText("Zone Text Position: " .. value)
        MinimalMiniMap:ApplyZoneText()
    end)

    -- Clock Y Slider
    local zoneFontSlider = CreateFrame("Slider", "MMMZoneFontSlider", frame, "OptionsSliderTemplate")
    zoneFontSlider:SetPoint("TOPLEFT", zoneTextYSlider, "BOTTOMLEFT", 0, -28)
    zoneFontSlider:SetSize(160, 16)
    zoneFontSlider:SetMinMaxValues(8, 24)
    zoneFontSlider:SetValueStep(1)
    zoneFontSlider:SetObeyStepOnDrag(true)
    zoneFontSlider:SetValue(db.ZONE_TEXT_FONT_SIZE)
    MMMZoneFontSliderLow:SetText("8")
    MMMZoneFontSliderHigh:SetText("24")
    MMMZoneFontSliderText:SetText("Zone Font Size: " .. db.ZONE_TEXT_FONT_SIZE)
    MMMZoneFontSliderText:SetTextColor(0.9, 0.9, 0.9)
    zoneFontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.ZONE_TEXT_FONT_SIZE = value
        MMMZoneFontSliderText:SetText("Zone Font Size: " .. value)
        MinimalMiniMap:ApplyZoneText()
    end)

    local clockYSlider = CreateFrame("Slider", "MMMClockYSlider", frame, "OptionsSliderTemplate")
    clockYSlider:SetPoint("TOPLEFT", zoneFontSlider, "BOTTOMLEFT", 0, -28)
    clockYSlider:SetSize(160, 16)
    clockYSlider:SetMinMaxValues(-50, 50)
    clockYSlider:SetValueStep(1)
    clockYSlider:SetObeyStepOnDrag(true)
    clockYSlider:SetValue(db.CLOCK_Y)
    MMMClockYSliderLow:SetText("-50")
    MMMClockYSliderHigh:SetText("50")
    MMMClockYSliderText:SetText("Clock Text Position: " .. db.CLOCK_Y)
    MMMClockYSliderText:SetTextColor(0.9, 0.9, 0.9)
    clockYSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.CLOCK_Y = value
        MMMClockYSliderText:SetText("Clock Text Position: " .. value)
        MinimalMiniMap:ApplyClock()
    end)

    local clockFontSlider = CreateFrame("Slider", "MMMClockFontSlider", frame, "OptionsSliderTemplate")
    clockFontSlider:SetPoint("TOPLEFT", clockYSlider, "BOTTOMLEFT", 0, -28)
    clockFontSlider:SetSize(160, 16)
    clockFontSlider:SetMinMaxValues(8, 24)
    clockFontSlider:SetValueStep(1)
    clockFontSlider:SetObeyStepOnDrag(true)
    clockFontSlider:SetValue(db.CLOCK_FONT_SIZE)
    MMMClockFontSliderLow:SetText("8")
    MMMClockFontSliderHigh:SetText("24")
    MMMClockFontSliderText:SetText("Clock Font Size: " .. db.CLOCK_FONT_SIZE)
    MMMClockFontSliderText:SetTextColor(0.9, 0.9, 0.9)
    clockFontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.CLOCK_FONT_SIZE = value
        MMMClockFontSliderText:SetText("Clock Font Size: " .. value)
        MinimalMiniMap:ApplyClock()
    end)

    local function createCheckButton(label, anchor, offsetX, offsetY, dbKey, applyFunc, tag)
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX, offsetY)
        check:SetSize(20, 20)
        check:SetChecked(db[dbKey])
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        check.text:SetPoint("LEFT", check, "RIGHT", 0, 0)
        check.text:SetText(label)
        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked() and true or false
            db[dbKey] = checked
            applyFunc(MinimalMiniMap)
            if tag then
                local stateName = checked and "unlocked" or "locked"
                print(MinimalMiniMap.name .. ": " .. tag .. " " .. stateName .. (stateName == "unlocked" and ". Drag to move." or "."))
            end
        end)
        return check
    end

    local unlockCheck = createCheckButton("Unlock Minimap", clockFontSlider, -5, -22, "UNLOCKED", MinimalMiniMap.ApplyUnlockState, "minimap")

    -- Buffs Section Header
    local buffsHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    buffsHeader:SetPoint("TOPLEFT", unlockCheck, "BOTTOMLEFT", 5, -12)
    buffsHeader:SetText("BUFFS")
    buffsHeader:SetTextColor(0.9, 0.7, 0.3)

    local buffUnlockCheck = createCheckButton("Unlock Buff Panel", buffsHeader, -5, -8, "BUFF_UNLOCKED", MinimalMiniMap.ApplyBuffUnlockState, "buffs")

    state.guiFrame = frame
    state.scaleSlider = scaleSlider
    state.zoneFontSlider = zoneFontSlider
    state.clockFontSlider = clockFontSlider
    frame.unlockCheck = unlockCheck
    frame.buffUnlockCheck = buffUnlockCheck

    return frame
end

function MinimalMiniMap:ToggleGUI()
    local frame = self:EnsureGUI()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function MinimalMiniMap:OnSlashCommand(msg)
    msg = (msg or ""):lower():gsub("^%s+", "")
    if msg:find("^scale") then
        local value = tonumber(msg:match("scale%s+([%d%.]+)"))
        if value and value >= 0.5 and value <= 2 then
            value = formatScale(value)
            local db = getDB()
            db.MM_SCALE = value
            self:ApplyScale(true)
            if state.scaleSlider then
                state.scaleSlider:SetValue(value)
            end
            print(self.name .. ": scale set to " .. value)
        else
            print(self.name .. ": use /mmm scale 0.5 - 2")
        end
        return
    end

    self:ToggleGUI()
end
