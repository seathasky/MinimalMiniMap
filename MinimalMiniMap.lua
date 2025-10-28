local addonName = ...
if type(addonName) ~= "string" or addonName == "" then
	addonName = "MinimalMiniMap"
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")

---@diagnostic disable: undefined-global

local MinimalMiniMap = _G.MinimalMiniMap or {}
_G.MinimalMiniMap = MinimalMiniMap

MinimalMiniMap.name = addonName
MinimalMiniMap.frame = frame
MinimalMiniMap.media = {
	texture = "Interface\\AddOns\\MinimalMiniMap\\square.tga",
	font = "Interface\\AddOns\\MinimalMiniMap\\MMM.ttf",
}

MinimalMiniMap.defaults = {
	MOUSEOVER = false,
	BUTTONS   = true,
	MM_SCALE  = 1.1,
	BORDER_OPACITY = 0.1,
	HNS       = true,
	ZONE_TEXT_Y = 6,
	ZONE_TEXT_FONT_SIZE = 12,
	CLOCK_Y = -14,
	CLOCK_FONT_SIZE = 10,
	CLOCK_BG_OPACITY = 0.5,
	SHOW_FPS = false,
	FONT = "MMM",  -- Options: "MMM", "Friz", "Arial", "Morpheus"
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
	BUFF_SCALE = 1.0,
}

MinimalMiniMap.state = MinimalMiniMap.state or {}

function MinimalMiniMap:GetState()
	self.state = self.state or {}
	return self.state
end

function MinimalMiniMap:GetMedia()
	return self.media
end

function MinimalMiniMap:GetDefaults()
	return self.defaults
end

function MinimalMiniMap:GetDB()
	if not MinimalMiniMapDB then
		self:InitDB()
	end
	return MinimalMiniMapDB
end

function MinimalMiniMap:CopyDefaults(src, dest)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dest[k]) ~= "table" then dest[k] = {} end
			self:CopyDefaults(v, dest[k])
		elseif dest[k] == nil then
			dest[k] = v
		end
	end
end

function MinimalMiniMap:InitDB()
	MinimalMiniMapDB = MinimalMiniMapDB or {}
	self:CopyDefaults(self.defaults, MinimalMiniMapDB)
	local state = self:GetState()
	state.db = MinimalMiniMapDB
end

function MinimalMiniMap:EnableMouseWheel()
	if not Minimap then return end
	if not Minimap.EnableMouseWheel then return end

	Minimap:EnableMouseWheel(true)

	local handler = self:GetState().mouseWheelHandler
	if not handler then
		handler = function(_, delta)
			if delta and delta > 0 then
				Minimap_ZoomIn()
			else
				Minimap_ZoomOut()
			end
		end
		self:GetState().mouseWheelHandler = handler
	end

	Minimap:SetScript("OnMouseWheel", handler)
end

function MinimalMiniMap:ApplyCore()
	if MinimapCluster then
		self:ApplyScale()
		self:ApplyPosition()
	end

	self:ApplyMask()
	self:ApplyBorder()
	self:ApplyButtons()
	self:ApplyMouseover()
	self:ApplyNorthTag()
	self:ApplyZoneText()
	self:ApplyClock()
	self:ApplyVisibility()

	GetMinimapShape = function()
		return "SQUARE"
	end

	self:DetachBuffsFromMinimap()
	self:ApplyBuffScale()
	self:EnableDragging()
	self:EnableBuffDragging()
	self:ApplyUnlockState()
	self:ApplyBuffUnlockState()
	self:EnableMouseWheel()
end

function MinimalMiniMap:HandleSlash(msg)
	if self.OnSlashCommand then
		self:OnSlashCommand(msg)
	end
end

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		MinimalMiniMap:InitDB()
		MinimalMiniMap:ApplyCore()
		frame:UnregisterEvent(event)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
		-- Reapply buff position when changing zones
		if MinimalMiniMap.DetachBuffsFromMinimap then
			MinimalMiniMap:DetachBuffsFromMinimap()
		end
	end
end)

SLASH_MINIMALMINIMAP1 = "/mmm"
SlashCmdList.MINIMALMINIMAP = function(msg)
	MinimalMiniMap:HandleSlash(msg)
end
