---@diagnostic disable: undefined-global

local MinimalMiniMap = _G.MinimalMiniMap
if not MinimalMiniMap then return end

local function getDB()
    return MinimalMiniMap:GetDB()
end

local state = MinimalMiniMap:GetState()

function MinimalMiniMap:SaveBuffPositionFrom(frame)
    if not frame then return end
    local db = getDB()
    if not db then return end

    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    if not point then return end

    local pos = db.BUFF_POSITION
    pos.point = point
    pos.relativePoint = relativePoint or point
    pos.x = xOfs or 0
    pos.y = yOfs or 0
end

function MinimalMiniMap:ApplyBuffPosition()
    if not BuffFrame then return end
    local db = getDB()
    if not db then return end

    local pos = db.BUFF_POSITION
    local point = pos.point or "TOPRIGHT"
    local relativePoint = pos.relativePoint or point
    local x = pos.x or -200
    local y = pos.y or -10

    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint(point, UIParent, relativePoint, x, y)
end

function MinimalMiniMap:DetachBuffsFromMinimap()
    if not BuffFrame then return end
    BuffFrame:SetParent(UIParent)
    self:ApplyBuffPosition()
end

function MinimalMiniMap:EnsureBuffOverlay()
    if state.buffOverlay or not BuffFrame then return end
    state.buffOverlay = self:CreateOverlay(BuffFrame, "Move Buffs", "RIGHT", 1, 0.5, 0)
end

local function finishBuffDrag(frame)
    if frame.__MinimalMiniMapIsMoving then
        frame:StopMovingOrSizing()
        frame.__MinimalMiniMapIsMoving = nil
        MinimalMiniMap:SaveBuffPositionFrom(frame)
        MinimalMiniMap:ApplyBuffPosition()
    end
end

function MinimalMiniMap:EnableBuffDragging()
    if not BuffFrame then return end
    if BuffFrame.__MinimalMiniMapDragging then return end
    BuffFrame.__MinimalMiniMapDragging = true

    BuffFrame:SetMovable(true)
    BuffFrame:SetUserPlaced(true)
    BuffFrame:SetClampedToScreen(false)
    BuffFrame:EnableMouse(true)
    BuffFrame:RegisterForDrag("LeftButton")

    BuffFrame:SetScript("OnDragStart", function(frame)
        local db = getDB()
        if db and db.BUFF_UNLOCKED then
            frame:StartMoving()
            frame.__MinimalMiniMapIsMoving = true
        else
            frame.__MinimalMiniMapIsMoving = nil
        end
    end)

    BuffFrame:SetScript("OnDragStop", finishBuffDrag)
    BuffFrame:HookScript("OnMouseUp", finishBuffDrag)
    BuffFrame:HookScript("OnHide", finishBuffDrag)
end

function MinimalMiniMap:ApplyBuffUnlockState()
    if not BuffFrame then return end
    self:EnsureBuffOverlay()

    local db = getDB()
    if not db then return end

    local unlocked = db.BUFF_UNLOCKED
    if unlocked then
        if state.buffOverlay then state.buffOverlay:Show() end
    else
        if state.buffOverlay then state.buffOverlay:Hide() end
    end

    local guiFrame = state.guiFrame
    if guiFrame and guiFrame.buffUnlockCheck then
        guiFrame.buffUnlockCheck:SetChecked(unlocked)
    end
end
