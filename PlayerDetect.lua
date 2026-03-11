local _, MPT = ...

-- ── Player Detect ─────────────────────────────────────────────
-- Lightweight PING/PONG to detect nearby Mythic Memories users.
-- Shows MM icon in tooltip + draggable button on target.

local scanCache = {} -- "Name-Realm" -> { hasAddon=bool, pending=bool, timestamp=number }
local CACHE_TTL = 300 -- 5 minutes
local PENDING_TTL = 8 -- seconds before treating no-response as "no addon"

local lastTooltipUnit = nil -- "Name-Realm" currently shown in tooltip
local scanBtn = nil -- module-local target button reference

local ICON_STRING = "|TInterface\\AddOns\\MythicMemories\\icon:16:16:0:0|t"

-- ── Cache helpers ─────────────────────────────────────────────

local function GetCacheEntry(nameKey)
	local entry = scanCache[nameKey]
	if not entry then return nil end
	local age = GetTime() - entry.timestamp
	if entry.pending and age > PENDING_TTL then
		entry.pending = nil
		entry.hasAddon = false
		return entry
	end
	if not entry.pending and age > CACHE_TTL then
		scanCache[nameKey] = nil
		return nil
	end
	return entry
end

local function MakeNameKey(name, realm)
	if not realm or realm == "" then
		realm = GetRealmName()
	end
	return name .. "-" .. realm
end

local function MakeWhisperTarget(name, realm)
	if realm and realm ~= "" and realm ~= GetRealmName() then
		return name .. "-" .. realm
	end
	return name
end

-- ── Send PING ─────────────────────────────────────────────────

function MPT:PlayerDetect_SendPing(name, realm)
	local myName = UnitName("player")
	if name == myName then return end

	local nameKey = MakeNameKey(name, realm)
	local entry = GetCacheEntry(nameKey)
	if entry then return end -- already cached or pending

	scanCache[nameKey] = { pending = true, timestamp = GetTime() }

	local target = MakeWhisperTarget(name, realm)
	local msg = self:Serialize("PING", {})
	self:SendCommMessage(self.COMM_PREFIX, msg, "WHISPER", target)
end

-- ── Receive PONG ──────────────────────────────────────────────

function MPT:PlayerDetect_OnPong(sender)
	local name, realm = sender:match("^([^%-]+)%-?(.*)$")
	realm = (realm and realm ~= "") and realm or GetRealmName()
	local nameKey = MakeNameKey(name, realm)

	scanCache[nameKey] = { hasAddon = true, timestamp = GetTime() }

	self:PlayerDetect_RefreshIfRelevant(nameKey)
end

-- ── Tooltip refresh on async PONG ─────────────────────────────

function MPT:PlayerDetect_RefreshIfRelevant(nameKey)
	-- Refresh tooltip if still showing this player
	if lastTooltipUnit and lastTooltipUnit == nameKey then
		if GameTooltip:IsShown() then
			local _, unit = GameTooltip:GetUnit()
			if unit and UnitIsPlayer(unit) then
				GameTooltip:AddTexture("Interface\\AddOns\\MythicMemories\\icon", {
					width = 16,
					height = 16,
					margin = { left = 0, right = 0, top = 0, bottom = 0 },
				})
				GameTooltip:Show()
			end
		end
	end

	-- Show target button if this is the current target
	if UnitExists("target") and UnitIsPlayer("target") then
		local tName, tRealm = UnitName("target")
		local tKey = MakeNameKey(tName, tRealm)
		if tKey == nameKey then
			local n, r = tName, tRealm
			if not r or r == "" then r = GetRealmName() end
			self:PlayerDetect_ShowScanBtn(n, r)
		end
	end
end

-- ── Tooltip hook ──────────────────────────────────────────────

function MPT:PlayerDetect_HookTooltip()
	if self._pdTooltipHooked then return end
	self._pdTooltipHooked = true

	local function OnTooltipUnit(tooltip)
		if tooltip ~= GameTooltip then return end
		local _, unit = tooltip:GetUnit()
		if not unit then
			lastTooltipUnit = nil
			return
		end

		local ok, isPlayer = pcall(UnitIsPlayer, unit)
		if not ok or not isPlayer then
			lastTooltipUnit = nil
			return
		end

		local name, realm = UnitName(unit)
		if not name then
			lastTooltipUnit = nil
			return
		end

		local myName = UnitName("player")
		if name == myName then
			lastTooltipUnit = nil
			return
		end

		local nameKey = MakeNameKey(name, realm)
		lastTooltipUnit = nameKey

		local entry = GetCacheEntry(nameKey)
		if entry and entry.hasAddon then
			tooltip:AddTexture("Interface\\AddOns\\MythicMemories\\icon", {
				width = 16,
				height = 16,
				margin = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			tooltip:Show()
		elseif not entry then
			self:PlayerDetect_SendPing(name, realm)
		end
	end

	if TooltipDataProcessor and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipUnit)
	else
		GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipUnit)
	end

	GameTooltip:HookScript("OnHide", function()
		lastTooltipUnit = nil
	end)
end

-- ── Target button (draggable) ─────────────────────────────────

function MPT:PlayerDetect_CreateScanBtn()
	if scanBtn then return end

	local C = self.C
	if not C then return end

	local f = CreateFrame("Button", "MPTScanBtn", UIParent, "BackdropTemplate")
	f:SetSize(42, 42)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("LeftButtonUp")
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(100)
	f:Hide()

	-- Restore saved position
	local pos = self.db.global.scanBtnPos or {}
	f:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 200, pos.y or -200)

	-- Backdrop
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	f:SetBackdropColor(C.panelBg[1], C.panelBg[2], C.panelBg[3], 0.92)
	f:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.6)

	-- Icon
	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\AddOns\\MythicMemories\\icon")
	icon:SetSize(30, 30)
	icon:SetPoint("CENTER")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Close button (small X in top-right corner)
	local closeBtn = CreateFrame("Button", nil, f)
	closeBtn:SetSize(16, 16)
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
	closeBtn:SetFrameLevel(f:GetFrameLevel() + 2)
	local closeTex = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	closeTex:SetPoint("CENTER")
	closeTex:SetText("x")
	closeTex:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	closeBtn:SetScript("OnEnter", function()
		closeTex:SetTextColor(1, 0.3, 0.3)
	end)
	closeBtn:SetScript("OnLeave", function()
		closeTex:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	closeBtn:SetScript("OnClick", function()
		f:Hide()
	end)

	-- Hover
	f:SetScript("OnEnter", function()
		f:SetBackdropColor(C.btnHover[1], C.btnHover[2], C.btnHover[3], 0.95)
		GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Mythic Memories", C.accent[1], C.accent[2], C.accent[3])
		if f.mptTargetName then
			GameTooltip:AddLine("View " .. f.mptTargetName .. "'s M+ table", 1, 1, 1, true)
		end
		GameTooltip:AddLine("Left-click to open | Drag to move", 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function()
		f:SetBackdropColor(C.panelBg[1], C.panelBg[2], C.panelBg[3], 0.92)
		GameTooltip:Hide()
	end)

	-- Click: toggle table (open if not viewing, close if already viewing this person)
	f:SetScript("OnClick", function(_, button)
		if button == "LeftButton" and f.mptTargetName then
			-- If already viewing this person's table, close it
			if MPT:IsViewingRemote() and MPT.viewingPlayer then
				local viewBase = MPT.viewingPlayer:match("^([^%-]+)")
				if viewBase == f.mptTargetName then
					MPT:ExitViewMode()
					if MPT.mainFrame then
						MPT.mainFrame:Hide()
					end
					return
				end
			end
			MPT:RequestTable(f.mptTargetName, f.mptTargetRealm)
		end
	end)

	-- Drag
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		MPT.db.global.scanBtnPos = { point = point, x = x, y = y }
	end)

	scanBtn = f
	self.scanBtn = f
end

function MPT:PlayerDetect_ShowScanBtn(name, realm)
	self:PlayerDetect_CreateScanBtn()
	if not scanBtn then return end
	scanBtn.mptTargetName = name
	scanBtn.mptTargetRealm = realm
	scanBtn:Show()
end

-- ── PLAYER_TARGET_CHANGED ─────────────────────────────────────

function MPT:PlayerDetect_OnTargetChanged()
	if not UnitExists("target") or not UnitIsPlayer("target") then
		if scanBtn then scanBtn:Hide() end
		return
	end

	local name, realm = UnitName("target")
	if not name then
		if scanBtn then scanBtn:Hide() end
		return
	end

	local myName = UnitName("player")
	if name == myName then
		if scanBtn then scanBtn:Hide() end
		return
	end

	local nameKey = MakeNameKey(name, realm)
	local entry = GetCacheEntry(nameKey)

	if entry and entry.hasAddon then
		if not realm or realm == "" then realm = GetRealmName() end
		self:PlayerDetect_ShowScanBtn(name, realm)
	else
		if scanBtn then scanBtn:Hide() end
		if not entry then
			self:PlayerDetect_SendPing(name, realm)
		end
	end
end

-- ── Zone change: clear pending, hide button ───────────────────

function MPT:PlayerDetect_OnZoneChanged()
	for k, entry in pairs(scanCache) do
		if entry.pending then
			scanCache[k] = nil
		end
	end
	if scanBtn then scanBtn:Hide() end
end

-- ── ApplyTheme teardown ───────────────────────────────────────

function MPT:PlayerDetect_DestroyUI()
	if scanBtn then
		-- Save position before destroying
		local point, _, _, x, y = scanBtn:GetPoint()
		if point then
			self.db.global.scanBtnPos = { point = point, x = x, y = y }
		end
		scanBtn:Hide()
		scanBtn:SetParent(nil)
		_G["MPTScanBtn"] = nil
		scanBtn = nil
	end
	self.scanBtn = nil
end

-- ── Enable ────────────────────────────────────────────────────

function MPT:PlayerDetect_Enable()
	self:PlayerDetect_HookTooltip()
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "PlayerDetect_OnTargetChanged")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "PlayerDetect_OnZoneChanged")
end
