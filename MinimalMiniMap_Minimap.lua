---@diagnostic disable: undefined-global

local MinimalMiniMap = _G.MinimalMiniMap
if not MinimalMiniMap then return end

local function getDB()
    return MinimalMiniMap:GetDB()
end

local state = MinimalMiniMap:GetState()
state.drag = state.drag or { active = false, offsetX = 0, offsetY = 0 }

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
    frame:SetTexture(media.texture)
    local db = getDB()
    local alpha = db and db.BORDER_OPACITY or 0.1
    frame:SetAlpha(alpha)
    frame:Show()
end

function MinimalMiniMap:ApplyBorder()
    self:ApplyBorderTexture(MinimapBorder)
    self:ApplyBorderTexture(MinimapBorderTop)
end

function MinimalMiniMap:ApplyButtons()
    local db = getDB()
    if not db or not db.BUTTONS then return end
    local hide = {
        MinimapZoomIn,
        MinimapZoomOut,
        MinimapToggleButton,
        MinimapBorderTop,
        MiniMapWorldMapButton,
    }
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
    local media = self:GetMedia()
    if MinimapZoneTextButton and Minimap and db then
        MinimapZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, db.ZONE_TEXT_Y or 2)
    end
    if MinimapZoneText then
        local fontSize = db and db.ZONE_TEXT_FONT_SIZE or 11
        MinimapZoneText:SetFont(media.font, fontSize, "OUTLINE")
    end
end

function MinimalMiniMap:ApplyClock()
    local db = getDB()
    local media = self:GetMedia()
    if TimeManagerClockButton and Minimap and db then
        TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, db.CLOCK_Y or -2)
        local region = TimeManagerClockButton:GetRegions()
        if region then region:Hide() end
    end
    if TimeManagerClockTicker then
        local fontSize = db and db.CLOCK_FONT_SIZE or 12
        TimeManagerClockTicker:SetFont(media.font, fontSize, "OUTLINE")
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
