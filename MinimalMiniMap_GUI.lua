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
    local media = self:GetMedia()
    local fontPath = media and media.font

    local function applyFont(fontString, size)
        if not fontString then return end
        if fontPath then
            local success = fontString:SetFont(fontPath, size, "OUTLINE")
            if not success then
                -- Fallback to default font if custom font fails
                fontString:SetFontObject("GameFontNormal")
            end
        else
            fontString:SetFontObject("GameFontNormal")
        end
    end

    local function applySliderFonts(slider, textSize)
        if not slider then return end
        local name = slider:GetName()
        if not name then return end
        applyFont(_G[name .. "Low"], textSize - 1)
        applyFont(_G[name .. "High"], textSize - 1)
        applyFont(_G[name .. "Text"], textSize)
    end

    local frame = CreateFrame("Frame", "MinimalMiniMapGUI", UIParent)
    frame:SetSize(400, 380)
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
    applyFont(frame.title, 16)
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

    -- Tab System
    local tabButtons = {}
    local tabContainers = {}
    local activeTab = 1

    local function switchTab(tabIndex)
        activeTab = tabIndex
        for i, container in ipairs(tabContainers) do
            if i == tabIndex then
                container:Show()
            else
                container:Hide()
            end
        end
        for i, btn in ipairs(tabButtons) do
            if i == tabIndex then
                btn:SetAlpha(1)
                btn.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
            else
                btn:SetAlpha(0.7)
                btn.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end
    end

    local tabNames = {"General", "Minimap", "Buffs"}
    local tabSidebarWidth = 90
    
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, frame)
        btn:SetSize(tabSidebarWidth - 4, 30)
        if i == 1 then
            btn:SetPoint("TOPLEFT", 2, -26)
        else
            btn:SetPoint("TOP", tabButtons[i-1], "BOTTOM", 0, -2)
        end
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER")
        applyFont(btn.text, 11)
        btn.text:SetText(name)
        btn.text:SetTextColor(1, 1, 1)
        
        btn:SetScript("OnClick", function() switchTab(i) end)
        btn:SetScript("OnEnter", function(self) 
            if activeTab ~= i then
                self.bg:SetColorTexture(0.25, 0.25, 0.25, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= i then
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end)
        
        tabButtons[i] = btn
    end

    -- Create scrollable tab containers
    local contentHeights = {
        150,  -- General tab (shorter)
        480,  -- Minimap tab (7 sliders + 3 section headers + 1 checkbox)
        120   -- Buffs tab (1 slider + spacing)
    }
    
    for i = 1, 3 do
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", tabSidebarWidth + 2, -26)
        scrollFrame:SetPoint("BOTTOMRIGHT", -10, 10)
        scrollFrame:Hide()
        
        local container = CreateFrame("Frame", nil, scrollFrame)
        container:SetSize(280, contentHeights[i])  -- Set height based on actual content
        scrollFrame:SetScrollChild(container)
        
        tabContainers[i] = container
        tabContainers[i].scrollFrame = scrollFrame
    end
    
    -- Override switchTab to show/hide scroll frames
    local oldSwitchTab = switchTab
    switchTab = function(tabIndex)
        activeTab = tabIndex
        for i, container in ipairs(tabContainers) do
            if i == tabIndex then
                if container.scrollFrame then
                    container.scrollFrame:Show()
                else
                    container:Show()
                end
            else
                if container.scrollFrame then
                    container.scrollFrame:Hide()
                else
                    container:Hide()
                end
            end
        end
        for i, btn in ipairs(tabButtons) do
            if i == tabIndex then
                btn:SetAlpha(1)
                btn.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
            else
                btn:SetAlpha(0.7)
                btn.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end
    end

    -- TAB 1: GENERAL
    local generalTab = tabContainers[1]
    
    local generalDesc = generalTab:CreateFontString(nil, "OVERLAY")
    generalDesc:SetPoint("TOP", generalTab, "TOP", 0, -20)
    applyFont(generalDesc, 11)
    generalDesc:SetText("Enable unlocking to move frames")
    generalDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local unlockMinimapCheck = CreateFrame("CheckButton", nil, generalTab, "UICheckButtonTemplate")
    unlockMinimapCheck:SetPoint("TOPLEFT", generalTab, "TOPLEFT", 20, -50)
    unlockMinimapCheck:SetSize(20, 20)
    unlockMinimapCheck:SetChecked(db.UNLOCKED)
    unlockMinimapCheck.text = unlockMinimapCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unlockMinimapCheck.text:SetPoint("LEFT", unlockMinimapCheck, "RIGHT", 0, 0)
    applyFont(unlockMinimapCheck.text, 12)
    unlockMinimapCheck.text:SetText("Unlock Minimap")
    unlockMinimapCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        db.UNLOCKED = checked
        MinimalMiniMap:ApplyUnlockState()
        local stateName = checked and "unlocked" or "locked"
        print(MinimalMiniMap.name .. ": minimap " .. stateName .. (stateName == "unlocked" and ". Drag to move." or "."))
    end)
    
    local unlockBuffCheck = CreateFrame("CheckButton", nil, generalTab, "UICheckButtonTemplate")
    unlockBuffCheck:SetPoint("TOPLEFT", unlockMinimapCheck, "BOTTOMLEFT", 0, -10)
    unlockBuffCheck:SetSize(20, 20)
    unlockBuffCheck:SetChecked(db.BUFF_UNLOCKED)
    unlockBuffCheck.text = unlockBuffCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unlockBuffCheck.text:SetPoint("LEFT", unlockBuffCheck, "RIGHT", 0, 0)
    applyFont(unlockBuffCheck.text, 12)
    unlockBuffCheck.text:SetText("Unlock Buff Panel")
    unlockBuffCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        db.BUFF_UNLOCKED = checked
        MinimalMiniMap:ApplyBuffUnlockState()
        local stateName = checked and "unlocked" or "locked"
        print(MinimalMiniMap.name .. ": buffs " .. stateName .. (stateName == "unlocked" and ". Drag to move." or "."))
    end)
    
    -- Font Dropdown
    local fontLabel = generalTab:CreateFontString(nil, "OVERLAY")
    fontLabel:SetPoint("TOPLEFT", unlockBuffCheck, "BOTTOMLEFT", 0, -20)
    applyFont(fontLabel, 11)
    fontLabel:SetText("Minimap Font:")
    fontLabel:SetTextColor(0.9, 0.9, 0.9)
    
    local fontDropdown = CreateFrame("Frame", "MMMFontDropdown", generalTab, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -15, -5)
    
    local fontOptions = {
        {text = "MMM (DEFAULT)", value = "MMM"},
        {text = "Friz Quadrata", value = "Friz"},
        {text = "Arial Narrow", value = "Arial"},
        {text = "Morpheus", value = "Morpheus"},
    }
    
    UIDropDownMenu_SetWidth(fontDropdown, 150)
    UIDropDownMenu_Initialize(fontDropdown, function(self)
        for _, option in ipairs(fontOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function(self)
                db.FONT = self.value
                UIDropDownMenu_SetSelectedValue(fontDropdown, self.value)
                MinimalMiniMap:ApplyZoneText()
                MinimalMiniMap:ApplyClock()
                print("MinimalMiniMap: Font changed to " .. option.text)
            end
            info.checked = (db.FONT == option.value)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(fontDropdown, db.FONT or "MMM")
    
    -- Reset All Settings Button
    local resetAllBtn = CreateFrame("Button", nil, generalTab)
    resetAllBtn:SetSize(140, 24)
    resetAllBtn:SetPoint("TOP", fontDropdown, "BOTTOM", 15, -15)
    
    local resetAllBg = resetAllBtn:CreateTexture(nil, "BACKGROUND")
    resetAllBg:SetAllPoints()
    resetAllBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    
    local resetAllText = resetAllBtn:CreateFontString(nil, "OVERLAY")
    resetAllText:SetPoint("CENTER")
    applyFont(resetAllText, 11)
    resetAllText:SetText("Reset Defaults")
    resetAllText:SetTextColor(1, 1, 1)
    
    resetAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("MINIMALMINIMAP_RESET_ALL")
    end)
    
    resetAllBtn:SetScript("OnEnter", function(self)
        resetAllBg:SetColorTexture(1, 0.3, 0.3, 1)
    end)
    
    resetAllBtn:SetScript("OnLeave", function(self)
        resetAllBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    end)

    -- TAB 2: MINIMAP
    local minimapTab = tabContainers[2]
    
    -- MINIMAP SECTION
    local mmHeader = minimapTab:CreateFontString(nil, "OVERLAY")
    mmHeader:SetPoint("TOPLEFT", minimapTab, "TOPLEFT", 10, -10)
    applyFont(mmHeader, 12)
    mmHeader:SetText("Minimap")
    mmHeader:SetTextColor(1, 0.82, 0)

    -- Scale Slider
    local scaleSlider = CreateFrame("Slider", "MMMScaleSlider", minimapTab, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", mmHeader, "BOTTOMLEFT", 5, -10)
    scaleSlider:SetSize(140, 14)
    scaleSlider:SetMinMaxValues(0.5, 2)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(db.MM_SCALE)
    applySliderFonts(scaleSlider, 10)
    MMMScaleSliderLow:SetText("0.5")
    MMMScaleSliderHigh:SetText("2")
    MMMScaleSliderText:SetText("Scale: " .. db.MM_SCALE)
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.MM_SCALE = value
        MMMScaleSliderText:SetText("Scale: " .. value)
        MinimalMiniMap:ApplyScale(true)
    end)

    -- Border Opacity Slider
    local opacitySlider = CreateFrame("Slider", "MMMOpacitySlider", minimapTab, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    opacitySlider:SetSize(140, 14)
    opacitySlider:SetMinMaxValues(0, 1)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetValue(db.BORDER_OPACITY)
    applySliderFonts(opacitySlider, 10)
    MMMOpacitySliderLow:SetText("0")
    MMMOpacitySliderHigh:SetText("1")
    MMMOpacitySliderText:SetText("Border: " .. db.BORDER_OPACITY)
    opacitySlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.BORDER_OPACITY = value
        MMMOpacitySliderText:SetText("Border: " .. value)
        MinimalMiniMap:ApplyBorder()
    end)
    
    -- ZONE TEXT SECTION
    local zoneHeader = minimapTab:CreateFontString(nil, "OVERLAY")
    zoneHeader:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", -5, -15)
    applyFont(zoneHeader, 12)
    zoneHeader:SetText("Zone Text")
    zoneHeader:SetTextColor(1, 0.82, 0)

    -- Zone Text Position Slider
    local zoneTextYSlider = CreateFrame("Slider", "MMMZoneTextYSlider", minimapTab, "OptionsSliderTemplate")
    zoneTextYSlider:SetPoint("TOPLEFT", zoneHeader, "BOTTOMLEFT", 5, -10)
    zoneTextYSlider:SetSize(140, 14)
    zoneTextYSlider:SetMinMaxValues(-50, 50)
    zoneTextYSlider:SetValueStep(1)
    zoneTextYSlider:SetObeyStepOnDrag(true)
    zoneTextYSlider:SetValue(db.ZONE_TEXT_Y)
    applySliderFonts(zoneTextYSlider, 10)
    MMMZoneTextYSliderLow:SetText("-50")
    MMMZoneTextYSliderHigh:SetText("50")
    MMMZoneTextYSliderText:SetText("Position: " .. db.ZONE_TEXT_Y)
    zoneTextYSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.ZONE_TEXT_Y = value
        MMMZoneTextYSliderText:SetText("Position: " .. value)
        MinimalMiniMap:ApplyZoneText()
    end)

    -- Zone Font Size Slider
    local zoneFontSlider = CreateFrame("Slider", "MMMZoneFontSlider", minimapTab, "OptionsSliderTemplate")
    zoneFontSlider:SetPoint("TOPLEFT", zoneTextYSlider, "BOTTOMLEFT", 0, -20)
    zoneFontSlider:SetSize(140, 14)
    zoneFontSlider:SetMinMaxValues(8, 24)
    zoneFontSlider:SetValueStep(1)
    zoneFontSlider:SetObeyStepOnDrag(true)
    zoneFontSlider:SetValue(db.ZONE_TEXT_FONT_SIZE)
    applySliderFonts(zoneFontSlider, 10)
    MMMZoneFontSliderLow:SetText("8")
    MMMZoneFontSliderHigh:SetText("24")
    MMMZoneFontSliderText:SetText("Font Size: " .. db.ZONE_TEXT_FONT_SIZE)
    zoneFontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.ZONE_TEXT_FONT_SIZE = value
        MMMZoneFontSliderText:SetText("Font Size: " .. value)
        MinimalMiniMap:ApplyZoneText()
    end)
    
    -- CLOCK SECTION
    local clockHeader = minimapTab:CreateFontString(nil, "OVERLAY")
    clockHeader:SetPoint("TOPLEFT", zoneFontSlider, "BOTTOMLEFT", -5, -15)
    applyFont(clockHeader, 12)
    clockHeader:SetText("Clock")
    clockHeader:SetTextColor(1, 0.82, 0)

    -- Clock Position Slider
    local clockYSlider = CreateFrame("Slider", "MMMClockYSlider", minimapTab, "OptionsSliderTemplate")
    clockYSlider:SetPoint("TOPLEFT", clockHeader, "BOTTOMLEFT", 5, -10)
    clockYSlider:SetSize(140, 14)
    clockYSlider:SetMinMaxValues(-50, 50)
    clockYSlider:SetValueStep(1)
    clockYSlider:SetObeyStepOnDrag(true)
    clockYSlider:SetValue(db.CLOCK_Y)
    applySliderFonts(clockYSlider, 10)
    MMMClockYSliderLow:SetText("-50")
    MMMClockYSliderHigh:SetText("50")
    MMMClockYSliderText:SetText("Position: " .. db.CLOCK_Y)
    clockYSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.CLOCK_Y = value
        MMMClockYSliderText:SetText("Position: " .. value)
        MinimalMiniMap:ApplyClock()
    end)

    -- Clock Font Size Slider
    local clockFontSlider = CreateFrame("Slider", "MMMClockFontSlider", minimapTab, "OptionsSliderTemplate")
    clockFontSlider:SetPoint("TOPLEFT", clockYSlider, "BOTTOMLEFT", 0, -20)
    clockFontSlider:SetSize(140, 14)
    clockFontSlider:SetMinMaxValues(8, 24)
    clockFontSlider:SetValueStep(1)
    clockFontSlider:SetObeyStepOnDrag(true)
    clockFontSlider:SetValue(db.CLOCK_FONT_SIZE)
    applySliderFonts(clockFontSlider, 10)
    MMMClockFontSliderLow:SetText("8")
    MMMClockFontSliderHigh:SetText("24")
    MMMClockFontSliderText:SetText("Font Size: " .. db.CLOCK_FONT_SIZE)
    clockFontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        db.CLOCK_FONT_SIZE = value
        MMMClockFontSliderText:SetText("Font Size: " .. value)
        MinimalMiniMap:ApplyClock()
    end)
    
    -- Clock Background Opacity Slider
    local clockBgSlider = CreateFrame("Slider", "MMMClockBgSlider", minimapTab, "OptionsSliderTemplate")
    clockBgSlider:SetPoint("TOPLEFT", clockFontSlider, "BOTTOMLEFT", 0, -20)
    clockBgSlider:SetSize(140, 14)
    clockBgSlider:SetMinMaxValues(0, 1)
    clockBgSlider:SetValueStep(0.05)
    clockBgSlider:SetObeyStepOnDrag(true)
    clockBgSlider:SetValue(db.CLOCK_BG_OPACITY or 0.5)
    applySliderFonts(clockBgSlider, 10)
    MMMClockBgSliderLow:SetText("0")
    MMMClockBgSliderHigh:SetText("1")
    MMMClockBgSliderText:SetText("BG Opacity: " .. (db.CLOCK_BG_OPACITY or 0.5))
    clockBgSlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.CLOCK_BG_OPACITY = value
        MMMClockBgSliderText:SetText("BG Opacity: " .. value)
        MinimalMiniMap:ApplyClock()
    end)

    local function createCheckButton(label, parent, anchor, offsetX, offsetY, dbKey, applyFunc, tag)
        local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetX, offsetY)
        check:SetSize(20, 20)
        check:SetChecked(db[dbKey])
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        check.text:SetPoint("LEFT", check, "RIGHT", 0, 0)
        applyFont(check.text, 12)
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

    -- Show FPS in Clock checkbox
    local fpsCheck = createCheckButton("Show FPS in Clock", minimapTab, clockBgSlider, 5, -30, "SHOW_FPS", 
        function(self) self:ApplyClock() end, nil)

    -- TAB 3: BUFFS
    local buffsTab = tabContainers[3]
    
    local buffScaleSlider = CreateFrame("Slider", "MMMBuffScaleSlider", buffsTab, "OptionsSliderTemplate")
    buffScaleSlider:SetPoint("TOPLEFT", 20, -20)
    buffScaleSlider:SetSize(160, 16)
    buffScaleSlider:SetMinMaxValues(0.5, 2)
    buffScaleSlider:SetValueStep(0.05)
    buffScaleSlider:SetObeyStepOnDrag(true)
    buffScaleSlider:SetValue(db.BUFF_SCALE)
    applySliderFonts(buffScaleSlider, 12)
    MMMBuffScaleSliderLow:SetText("0.5")
    MMMBuffScaleSliderHigh:SetText("2")
    MMMBuffScaleSliderText:SetText("Buff Scale: " .. db.BUFF_SCALE)
    MMMBuffScaleSliderText:SetTextColor(0.9, 0.9, 0.9)
    buffScaleSlider:SetScript("OnValueChanged", function(_, value)
        value = formatScale(value)
        db.BUFF_SCALE = value
        MMMBuffScaleSliderText:SetText("Buff Scale: " .. value)
        MinimalMiniMap:ApplyBuffScale()
    end)

    state.guiFrame = frame
    state.scaleSlider = scaleSlider
    state.zoneFontSlider = zoneFontSlider
    state.clockFontSlider = clockFontSlider
    state.buffScaleSlider = buffScaleSlider
    frame.unlockCheck = unlockMinimapCheck
    frame.buffUnlockCheck = unlockBuffCheck
    frame.fpsCheck = fpsCheck

    -- Show first tab by default
    switchTab(1)

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

-- Confirmation dialog for reset all settings
StaticPopupDialogs["MINIMALMINIMAP_RESET_ALL"] = {
    text = "Reset ALL settings to defaults?\nThis will remove all your custom settings for Minimap and Buffs.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local db = getDB()
        local defaults = MinimalMiniMap:GetDefaults()
        
        -- Reset ALL settings
        db.MM_SCALE = defaults.MM_SCALE
        db.BORDER_OPACITY = defaults.BORDER_OPACITY
        db.ZONE_TEXT_Y = defaults.ZONE_TEXT_Y
        db.ZONE_TEXT_FONT_SIZE = defaults.ZONE_TEXT_FONT_SIZE
        db.CLOCK_Y = defaults.CLOCK_Y
        db.CLOCK_FONT_SIZE = defaults.CLOCK_FONT_SIZE
        db.CLOCK_BG_OPACITY = defaults.CLOCK_BG_OPACITY
        db.SHOW_FPS = defaults.SHOW_FPS
        db.FONT = defaults.FONT
        db.UNLOCKED = defaults.UNLOCKED
        db.POSITION = {
            point = defaults.POSITION.point,
            relativePoint = defaults.POSITION.relativePoint,
            x = defaults.POSITION.x,
            y = defaults.POSITION.y,
        }
        db.BUFF_SCALE = defaults.BUFF_SCALE
        db.BUFF_UNLOCKED = defaults.BUFF_UNLOCKED
        db.BUFF_POSITION = {
            point = defaults.BUFF_POSITION.point,
            relativePoint = defaults.BUFF_POSITION.relativePoint,
            x = defaults.BUFF_POSITION.x,
            y = defaults.BUFF_POSITION.y,
        }
        
        -- Update GUI
        if state.scaleSlider then state.scaleSlider:SetValue(db.MM_SCALE) end
        if state.zoneFontSlider then state.zoneFontSlider:SetValue(db.ZONE_TEXT_FONT_SIZE) end
        if state.clockFontSlider then state.clockFontSlider:SetValue(db.CLOCK_FONT_SIZE) end
        if state.buffScaleSlider then state.buffScaleSlider:SetValue(db.BUFF_SCALE) end
        if state.guiFrame and state.guiFrame.unlockCheck then
            state.guiFrame.unlockCheck:SetChecked(db.UNLOCKED)
        end
        if state.guiFrame and state.guiFrame.buffUnlockCheck then
            state.guiFrame.buffUnlockCheck:SetChecked(db.BUFF_UNLOCKED)
        end
        if state.guiFrame and state.guiFrame.fpsCheck then
            state.guiFrame.fpsCheck:SetChecked(db.SHOW_FPS)
        end
        
        -- Apply all changes
        MinimalMiniMap:ApplyScale(false)
        MinimalMiniMap:ApplyPosition()
        MinimalMiniMap:ApplyBorder()
        MinimalMiniMap:ApplyZoneText()
        MinimalMiniMap:ApplyClock()
        MinimalMiniMap:ApplyUnlockState()
        MinimalMiniMap:ApplyBuffScale()
        MinimalMiniMap:ApplyBuffPosition()
        MinimalMiniMap:ApplyBuffUnlockState()
        
        print("MinimalMiniMap: All settings reset to defaults")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
