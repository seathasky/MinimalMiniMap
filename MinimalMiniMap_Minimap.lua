---@diagnostic disable: undefined-global

local MinimalMiniMap = _G.MinimalMiniMap
if not MinimalMiniMap then return end

local function getDB()
    return MinimalMiniMap:GetDB()
end

local state = MinimalMiniMap:GetState()
state.drag = state.drag or { active = false, offsetX = 0, offsetY = 0 }

local function forceHideFrame(frame)
    if not frame then return end
    frame:Hide()
    if frame.__MMMOnShowHooked then return end
    frame:HookScript("OnShow", function(self)
        self:Hide()
    end)
    frame.__MMMOnShowHooked = true
end

local function stripTextureRegions(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
            region:SetAlpha(0)
        end
    end
end

local function forceHideTexture(texture)
    if not texture then return end
    texture:Hide()
    texture:SetTexture(nil)
    texture:SetAlpha(0)
    if texture.__MMMOnShowHooked then return end
    texture:HookScript("OnShow", function(self)
        self:Hide()
        self:SetTexture(nil)
        self:SetAlpha(0)
    end)
    texture.__MMMOnShowHooked = true
end

local function forceHideObject(object)
    if not object then return end
    if object.GetObjectType and object:GetObjectType() == "Texture" then
        forceHideTexture(object)
    else
        forceHideFrame(object)
        stripTextureRegions(object)
    end
end

local function stripMinimapBackdropArt()
    local backdrop = _G.MinimapBackdrop
    if not backdrop then return end

    local function stripBackdrop(self)
        stripTextureRegions(self)
        if self.SetBackdrop then
            self:SetBackdrop(nil)
        end
    end

    stripBackdrop(backdrop)

    if backdrop.__MMMStripHooked then return end
    backdrop:HookScript("OnShow", function(self)
        stripBackdrop(self)
    end)
    backdrop.__MMMStripHooked = true
end

local function applyTopCapsuleFix()
    forceHideTexture(MinimapBorderTop)
    stripMinimapBackdropArt()
    if MinimapCluster then
        forceHideObject(MinimapCluster.BorderTop)
    end
end

local function clearButtonTexture(texture)
    if not texture then return end
    texture:SetTexture(nil)
    texture:SetAlpha(0)
    texture:Hide()
end

local function stripTextureRegionsDeep(frame)
    if not frame then return end
    stripTextureRegions(frame)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        stripTextureRegions(child)
    end
end

local function clearZoneTextButtonArt()
    if not MinimapZoneTextButton then return end

    stripTextureRegionsDeep(MinimapZoneTextButton)

    if MinimapZoneTextButton.GetNormalTexture then
        clearButtonTexture(MinimapZoneTextButton:GetNormalTexture())
    end
    if MinimapZoneTextButton.GetPushedTexture then
        clearButtonTexture(MinimapZoneTextButton:GetPushedTexture())
    end
    if MinimapZoneTextButton.GetHighlightTexture then
        clearButtonTexture(MinimapZoneTextButton:GetHighlightTexture())
    end

    clearButtonTexture(_G.MinimapZoneTextButtonLeft)
    clearButtonTexture(_G.MinimapZoneTextButtonMiddle)
    clearButtonTexture(_G.MinimapZoneTextButtonRight)
end

local function ensureStandaloneZoneText()
    if not Minimap or not MinimapZoneText then return end
    local state = MinimalMiniMap:GetState()
    if state.zoneTextDetached then return end

    if MinimapZoneText.SetParent then
        MinimapZoneText:SetParent(Minimap)
    end
    if MinimapZoneText.SetFrameStrata then
        MinimapZoneText:SetFrameStrata("HIGH")
    end
    if MinimapZoneText.SetFrameLevel and Minimap.GetFrameLevel then
        MinimapZoneText:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    end

    if MinimapZoneTextButton then
        if MinimapZoneTextButton.EnableMouse then
            MinimapZoneTextButton:EnableMouse(false)
        end
        forceHideFrame(MinimapZoneTextButton)
    end

    state.zoneTextDetached = true
end

local function getFontPath()
    local db = getDB()
    local fontChoice = db and db.FONT or "MMM"
    
    if fontChoice == "MMM" then
        return MinimalMiniMap:GetMedia().font
    elseif fontChoice == "Friz" then
        return "Fonts\\FRIZQT__.TTF"
    elseif fontChoice == "Arial" then
        return "Fonts\\ARIALN.TTF"
    elseif fontChoice == "Morpheus" then
        return "Fonts\\MORPHEUS.TTF"
    else
        return MinimalMiniMap:GetMedia().font
    end
end

function MinimalMiniMap:GetAbsoluteCenter(frame)
    if not frame then return end
    local scale = frame:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    local x, y = frame:GetCenter()
    if not x or not y then return end
    return x * scale, y * scale
end

function MinimalMiniMap:SetAbsoluteCenter(frame, absX, absY)
    if not frame or not absX or not absY then return end
    local scale = frame:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absX / scale, absY / scale)
end

function MinimalMiniMap:GetCursorPositionInUI()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

function MinimalMiniMap:SavePositionFrom(frame)
    local db = getDB()
    if not db or not frame then return end
    local pos = db.POSITION
    if type(pos) ~= "table" then
        pos = {}
        db.POSITION = pos
    end
    local absX, absY = self:GetAbsoluteCenter(frame)
    if absX and absY then
        pos.centerX = absX
        pos.centerY = absY
    end
end

function MinimalMiniMap:ApplyScale(preservePosition)
    if not MinimapCluster then return end
    local db = getDB()
    if not db then return end

    local absX, absY
    if preservePosition then
        absX, absY = self:GetAbsoluteCenter(MinimapCluster)
    end

    MinimapCluster:SetScale(db.MM_SCALE)

    if absX and absY then
        self:SetAbsoluteCenter(MinimapCluster, absX, absY)
        self:SavePositionFrom(MinimapCluster)
    end
end

function MinimalMiniMap:ApplyPosition()
    if not MinimapCluster then return end
    local db = getDB()
    if not db then return end

    local pos = db.POSITION
    if pos.centerX and pos.centerY then
        self:SetAbsoluteCenter(MinimapCluster, pos.centerX, pos.centerY)
    else
        local point = pos.point or "TOPRIGHT"
        local relativePoint = pos.relativePoint or point
        local x = pos.x or -5
        local y = pos.y or -10
        MinimapCluster:ClearAllPoints()
        MinimapCluster:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

function MinimalMiniMap:ApplyMask()
    if not Minimap then return end
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
end

function MinimalMiniMap:ApplyBorderTexture(frame)
    if not frame then return end
    local media = self:GetMedia()
    local db = getDB()
    local alpha = db and db.BORDER_OPACITY or 0.1
    frame:SetTexture(media.texture)
    frame:SetAlpha(alpha)
    frame:Show()
end

function MinimalMiniMap:ApplyBorder()
    self:ApplyBorderTexture(MinimapBorder)
    -- Keep the default top capsule pieces hidden for both TBC and Classic paths.
    applyTopCapsuleFix()
end

function MinimalMiniMap:ApplyButtons()
    local db = getDB()
    if not db or not db.BUTTONS then return end
    local hideFrames = {
        MinimapZoomIn,
        MinimapZoomOut,
        MinimapToggleButton,
        MiniMapWorldMapButton,
    }
    for _, frame in ipairs(hideFrames) do
        forceHideFrame(frame)
    end
end

local function ShowZoneTextButton()
    local state = MinimalMiniMap:GetState()
    if state.zoneTextDetached then
        if MinimapZoneText then MinimapZoneText:Show() end
        return
    end
    if MinimapZoneTextButton then MinimapZoneTextButton:Show() end
end

local function HideZoneTextButton()
    local state = MinimalMiniMap:GetState()
    if state.zoneTextDetached then
        if MinimapZoneText then MinimapZoneText:Hide() end
        return
    end
    if MinimapZoneTextButton then MinimapZoneTextButton:Hide() end
end

function MinimalMiniMap:ApplyMouseover()
    if not Minimap then return end
    local db = getDB()
    if db and db.MOUSEOVER then
        Minimap:SetScript("OnEnter", ShowZoneTextButton)
        Minimap:SetScript("OnLeave", HideZoneTextButton)
        HideZoneTextButton()
    else
        Minimap:SetScript("OnEnter", nil)
        Minimap:SetScript("OnLeave", nil)
        ShowZoneTextButton()
    end
end

function MinimalMiniMap:ApplyNorthTag()
    local db = getDB()
    if MinimapNorthTag and db then
        MinimapNorthTag:SetAlpha(db.HNS and 0 or 1)
    end
end

function MinimalMiniMap:ApplyZoneText()
    local db = getDB()
    ensureStandaloneZoneText()
    if MinimapZoneTextButton then
        clearZoneTextButtonArt()
        if not MinimapZoneTextButton.__MMMStripHooked then
            MinimapZoneTextButton:HookScript("OnShow", function(self)
                clearZoneTextButtonArt()
            end)
            MinimapZoneTextButton.__MMMStripHooked = true
        end
    end
    if MinimapZoneTextButton and Minimap and db then
        MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, db.ZONE_TEXT_Y or 2)
    end
    if MinimapZoneText then
        local fontSize = db and db.ZONE_TEXT_FONT_SIZE or 11
        MinimapZoneText:ClearAllPoints()
        MinimapZoneText:SetPoint("TOP", Minimap, "TOP", 0, db and db.ZONE_TEXT_Y or 2)
        MinimapZoneText:SetFont(getFontPath(), fontSize, "OUTLINE")
        MinimapZoneText:SetDrawLayer("OVERLAY")
        MinimapZoneText:SetJustifyH("CENTER")
        MinimapZoneText:SetShadowOffset(0, 0)
        MinimapZoneText:SetShadowColor(0, 0, 0, 0)
        MinimapZoneText:SetTextColor(1, 0.82, 0, 1)
    end
end

function MinimalMiniMap:ApplyClock()
    local db = getDB()
    local state = self:GetState()
    if not Minimap or not db then return end

    -- TBC 2.5.5 clock lives in Blizzard_TimeManager and may be LoD.
    if (not TimeManagerClockButton or not TimeManagerClockTicker) and LoadAddOn and IsAddOnLoaded then
        if not IsAddOnLoaded("Blizzard_TimeManager") then
            pcall(LoadAddOn, "Blizzard_TimeManager")
        end
    end

    if not state.fallbackClockButton then
        local btn = CreateFrame("Frame", "MinimalMiniMapClockFrame", Minimap)
        btn:SetFrameStrata("HIGH")
        btn:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        btn:SetSize(1, 1)
        btn:EnableMouse(false)

        local ticker = btn:CreateFontString(nil, "OVERLAY")
        ticker:SetPoint("CENTER", btn, "CENTER", 0, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("CENTER", ticker, "CENTER", 0, 0)

        state.fallbackClockButton = btn
        state.fallbackClockTicker = ticker
        state.fallbackClockBackground = bg
    end

    local nativeClockButton = _G.TimeManagerClockButton
    local nativeClockTicker = _G.TimeManagerClockTicker

    local clockTicker = nativeClockTicker or state.fallbackClockTicker
    local clockBackground = nil

    if nativeClockButton and nativeClockTicker then
        nativeClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, db.CLOCK_Y or -2)
        nativeClockButton:SetFrameStrata("HIGH")
        nativeClockButton:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        local region = nativeClockButton:GetRegions()
        if region then region:Hide() end

        if not state.clockBackground then
            state.clockBackground = nativeClockButton:CreateTexture(nil, "BACKGROUND")
        end
        clockBackground = state.clockBackground

        if state.fallbackClockButton then
            state.fallbackClockButton:Hide()
        end

        if not state.nativeClockUpdateHooked and hooksecurefunc and type(TimeManagerClockButton_Update) == "function" then
            hooksecurefunc("TimeManagerClockButton_Update", function()
                MinimalMiniMap:UpdateClockText()
            end)
            state.nativeClockUpdateHooked = true
        end
    elseif state.fallbackClockButton then
        state.fallbackClockButton:ClearAllPoints()
        state.fallbackClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, db.CLOCK_Y or -2)
        state.fallbackClockButton:Show()
        clockBackground = state.fallbackClockBackground
    end

    if clockTicker then
        local fontSize = db.CLOCK_FONT_SIZE or 12
        clockTicker:SetFont(getFontPath(), fontSize, "OUTLINE")
    end

    if clockBackground and clockTicker then
        local bgOpacity = db.CLOCK_BG_OPACITY or 0.5
        clockBackground:SetColorTexture(0, 0, 0, bgOpacity)
        local width = clockTicker:GetStringWidth() + 8
        local height = clockTicker:GetStringHeight() + 4
        clockBackground:SetSize(width, height)
        clockBackground:SetPoint("CENTER", clockTicker, "CENTER", 0, 0)
        clockBackground:Show()
    end

    state.activeClockTicker = clockTicker
    state.activeClockBackground = clockBackground

    if not state.clockUpdater then
        state.clockUpdater = CreateFrame("Frame")
        state.clockUpdateElapsed = 0
        state.clockUpdater:SetScript("OnUpdate", function(_, elapsed)
            local cfg = getDB()
            local interval = (cfg and cfg.SHOW_FPS) and 0.5 or 1.0
            state.clockUpdateElapsed = state.clockUpdateElapsed + elapsed
            if state.clockUpdateElapsed >= interval then
                state.clockUpdateElapsed = 0
                MinimalMiniMap:UpdateClockText()
            end
        end)
    end

    self:InitializeFPSTracking()
    self:UpdateClockText()
end

function MinimalMiniMap:InitializeFPSTracking()
    local state = self:GetState()
    local db = getDB()
    
    if not state.fpsTracker then
        state.fpsTracker = {
            frameCount = 0,
            currentFPS = 0,
            lastUpdate = 0
        }
    end
    
    if db and db.SHOW_FPS then
        if not state.fpsFrame then
            state.fpsFrame = CreateFrame("Frame")
        end

        state.fpsFrame:SetScript("OnUpdate", function(_, elapsed)
            MinimalMiniMap:UpdateFPS(elapsed)
        end)
    else
        if state.fpsFrame then
            state.fpsFrame:SetScript("OnUpdate", nil)
        end
    end
end

function MinimalMiniMap:UpdateFPS(elapsed)
    local state = self:GetState()
    local db = getDB()
    
    if not state.fpsTracker or not db.SHOW_FPS then return end
    
    local tracker = state.fpsTracker
    tracker.frameCount = tracker.frameCount + 1
    tracker.lastUpdate = tracker.lastUpdate + elapsed
    
    -- Update FPS every 0.5 seconds
    if tracker.lastUpdate >= 0.5 then
        tracker.currentFPS = tracker.frameCount / tracker.lastUpdate
        tracker.frameCount = 0
        tracker.lastUpdate = 0
        
        -- Update the clock text with FPS
        self:UpdateClockText()
    end
end

function MinimalMiniMap:UpdateClockText()
    local db = getDB()
    local state = self:GetState()
    local ticker = _G.TimeManagerClockTicker or state.activeClockTicker or state.fallbackClockTicker

    if not ticker or not db then return end
    
    -- Get the original time text - try different methods for Classic Era
    local timeText = ""
    if GameTime_GetTime then
        timeText = GameTime_GetTime(false)
    elseif ticker.timeDisplayFormat then
        -- Fallback: get current time format
        timeText = date(ticker.timeDisplayFormat or "%H:%M")
    else
        -- Last resort: simple time format
        timeText = date("%H:%M")
    end
    
    if db.SHOW_FPS and state.fpsTracker then
        local fps = math.floor(state.fpsTracker.currentFPS + 0.5)
        timeText = timeText .. " - " .. fps .. " FPS"
    end
    
    -- Force set the text and ensure it's visible
    ticker:SetText(timeText)
    ticker:Show()

    local bg = state.clockBackground or state.activeClockBackground or state.fallbackClockBackground
    if bg then
        local width = ticker:GetStringWidth() + 8
        local height = ticker:GetStringHeight() + 4
        bg:SetSize(width, height)
    end
end

function MinimalMiniMap:CreateOverlay(parent, labelText, labelPoint, r, g, b)
    if not parent then return end
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

function MinimalMiniMap:EnsureMoveOverlay()
    if state.moveOverlay or not Minimap then return end
    state.moveOverlay = self:CreateOverlay(Minimap, "Move Map", "CENTER", 0, 1, 0)
end

function MinimalMiniMap:UpdateDrag()
    if not state.drag.active or not MinimapCluster then return end
    local cursorX, cursorY = self:GetCursorPositionInUI()
    local newLeft = cursorX - state.drag.offsetX
    local newTop = cursorY + state.drag.offsetY
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newLeft, newTop)
end

function MinimalMiniMap:StartDrag()
    local db = getDB()
    if not MinimapCluster or not Minimap or not db or not db.UNLOCKED then return end

    local left = MinimapCluster:GetLeft()
    local top = MinimapCluster:GetTop()
    local right = MinimapCluster:GetRight()
    local bottom = MinimapCluster:GetBottom()
    if not left or not top or not right or not bottom then return end

    local cursorX, cursorY = self:GetCursorPositionInUI()
    state.drag.offsetX = cursorX - left
    state.drag.offsetY = top - cursorY
    state.drag.active = true

    state.dragUpdater = state.dragUpdater or function()
        MinimalMiniMap:UpdateDrag()
    end
    self.frame:SetScript("OnUpdate", state.dragUpdater)
end

function MinimalMiniMap:StopDrag()
    if not state.drag.active then return end
    self:UpdateDrag()
    state.drag.active = false
    self.frame:SetScript("OnUpdate", nil)
    self:SavePositionFrom(MinimapCluster)
    self:ApplyPosition()
end

function MinimalMiniMap:EnableDragging()
    if not MinimapCluster or not Minimap then return end
    if state.dragHooksInstalled then return end
    state.dragHooksInstalled = true

    MinimapCluster:SetMovable(true)
    MinimapCluster:SetUserPlaced(true)
    MinimapCluster:SetClampedToScreen(false)

    Minimap:HookScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            MinimalMiniMap:StartDrag()
        end
    end)

    Minimap:HookScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            MinimalMiniMap:StopDrag()
        end
    end)

    Minimap:HookScript("OnHide", function()
        MinimalMiniMap:StopDrag()
    end)
end

function MinimalMiniMap:ApplyUnlockState()
    local db = getDB()
    if not db then return end
    self:EnsureMoveOverlay()
    local unlocked = db.UNLOCKED

    if unlocked then
        if state.moveOverlay then state.moveOverlay:Show() end
    else
        self:StopDrag()
        if state.moveOverlay then state.moveOverlay:Hide() end
    end

    local guiFrame = state.guiFrame
    if guiFrame and guiFrame.unlockCheck then
        guiFrame.unlockCheck:SetChecked(unlocked)
    end
end

function MinimalMiniMap:ApplyVisibility()
    -- Always hide unused frames
    if MiniMapLFGFrame then
        MiniMapLFGFrame:Hide()
        MiniMapLFGFrame:SetScript("OnShow", function(self) self:Hide() end)
    end
    if GameTimeFrame then
        GameTimeFrame:Hide()
        GameTimeFrame:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    -- LFG Eye - bottom left
    if LFGMinimapFrame then
        LFGMinimapFrame:SetScale(0.6)
        LFGMinimapFrame:SetFrameStrata("HIGH")
        LFGMinimapFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        LFGMinimapFrame:ClearAllPoints()
        LFGMinimapFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
    end
    
    -- Tracking Button - hide it
    local trackingButton = MiniMapTracking or MiniMapTrackingButton
    if trackingButton then
        trackingButton:Hide()
        trackingButton:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    -- Mail Icon - middle right
    if MiniMapMailFrame then
        MiniMapMailFrame:SetScale(0.6)
        MiniMapMailFrame:SetFrameStrata("HIGH")
        MiniMapMailFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
        MiniMapMailFrame:ClearAllPoints()
        MiniMapMailFrame:SetPoint("RIGHT", Minimap, "RIGHT", -2, 0)
    end
    
    -- Settings Cogwheel - bottom right
    self:CreateSettingsButton()

    -- TBC/Classic: keep default top capsule pieces hidden.
    applyTopCapsuleFix()
end

function MinimalMiniMap:CreateSettingsButton()
    local state = self:GetState()
    if state.settingsButton then return end
    
    local btn = CreateFrame("Button", "MinimalMiniMapSettingsButton", Minimap)
    btn:SetSize(16, 16)
    btn:SetScale(0.6)
    btn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -2, 2)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    
    -- Background to mask the black
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    
    -- Use the cogwheel texture with transparency
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Trade_Engineering")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)  -- Crop edges to remove black border
    icon:SetDesaturated(true)  -- Grayscale
    
    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Icons\\Trade_Engineering")
    highlight:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    highlight:SetDesaturated(true)  -- Grayscale
    highlight:SetAlpha(0.5)
    
    btn:SetScript("OnClick", function()
        self:ToggleGUI()
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("MinimalMiniMap Settings")
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    state.settingsButton = btn
end


