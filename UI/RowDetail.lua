local _, MPT = ...

local DETAIL_ROW_HEIGHT = 28
local DETAIL_HEADER_HEIGHT = 26
local DETAIL_PADDING = 10
local DETAIL_GAP = 3
local ACTION_BAR_HEIGHT = 32
local CLASS_BAR_WIDTH = 3

-- Colors derived from shared theme palette
local function DC()
	local c = MPT.C
	return {
		bg        = c.detailBg,
		cardOdd   = c.detailCardOdd,
		cardEven  = c.detailCardEven,
		headerBg  = c.detailHeaderBg,
		actionBg  = c.detailActionBg,
		accent    = c.accent,
		accentDim = c.accentDim,
		text      = c.textNeutral,
		textMuted = c.textMuted,
		divider   = c.divider,
		btnBg     = c.btnBg,
	}
end

-- Fixed columns (always shown): NAME + role icon
local FIXED_NAME_WIDTH = 160
local FIXED_ROLE_WIDTH = 30

-- Count-based stats use tostring(), everything else uses AbbreviateNumber
local COUNT_STATS = { deaths = true, interrupts = true, dispels = true }

-- Role icons via texture + tex coords (desaturated for pictogram look)
local ROLE_TEX = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
local ROLE_COORDS = {
	TANK    = { 0, 19/64, 22/64, 41/64 },
	HEALER  = { 20/64, 39/64, 1/64, 20/64 },
	DAMAGER = { 20/64, 39/64, 22/64, 41/64 },
}
local ROLE_ICON_SIZE = 18

function MPT:AbbreviateNumber(n)
	if not n or n == 0 then return "0" end
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	if n == math.floor(n) then return tostring(n) end
	return string.format("%.1f", n)
end

function MPT:OnMvpChanged()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:RefreshTable()
	end
	if self.mvpsSidePanel and self.mvpsSidePanel:IsShown() then
		self:RefreshMvpsSidePanel()
	end
	if IsInGroup() then
		if self.mvpBroadcastTimer then
			self.mvpBroadcastTimer:Cancel()
		end
		self.mvpBroadcastTimer = C_Timer.NewTimer(1, function()
			self:BroadcastBrowseMvps()
			self.mvpBroadcastTimer = nil
		end)
	end
end

function MPT:ToggleRowExpansion(row)
	if not row or not row.runData then return end

	local scrollBar = _G["MPTScrollFrameScrollBar"]
	local wasExpanded = self.expandedRunId == row.runData.id

	if wasExpanded then
		-- Collapsing
		self.expandedRunId = nil
		self:HideAllPopups()
		self:RefreshTable()
		-- Clamp scroll to new (smaller) range so no empty space at bottom
		if scrollBar then
			local _, maxVal = scrollBar:GetMinMaxValues()
			local cur = scrollBar:GetValue()
			if cur > maxVal then
				scrollBar:SetValue(maxVal)
			end
		end
	else
		-- Expanding: save scroll position, expand, restore, then refresh once
		local savedVal = scrollBar and scrollBar:GetValue() or 0
		self.expandedRunId = row.runData.id
		self:HideAllPopups()
		if scrollBar then
			scrollBar:SetValue(savedVal)
		end
		self:RefreshTable()
	end
end

function MPT:ExpandRow(row)
	local run = row.runData
	if not run then return end
	local dc = DC()

	local members = run.members or {}
	local numMembers = #members
	-- Top padding + header + gap + (member cards with gaps) + divider + action bar + bottom padding
	local detailHeight = DETAIL_PADDING
		+ DETAIL_HEADER_HEIGHT + DETAIL_GAP
		+ (numMembers * (DETAIL_ROW_HEIGHT + DETAIL_GAP))
		+ 1 + ACTION_BAR_HEIGHT + DETAIL_PADDING

	local detail = row.detailFrame
	if not detail then
		detail = CreateFrame("Frame", nil, row)
		row.detailFrame = detail
	end

	detail:ClearAllPoints()
	detail:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, 0)
	detail:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, 0)
	detail:SetHeight(detailHeight)

	-- Main background
	local bg = detail.bg
	if not bg then
		bg = detail:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		detail.bg = bg
	end
	bg:SetColorTexture(dc.bg[1], dc.bg[2], dc.bg[3], 1)

	-- Top accent line (gold, marks start of detail)
	local topLine = detail.topLine
	if not topLine then
		topLine = detail:CreateTexture(nil, "ARTWORK")
		detail.topLine = topLine
	end
	topLine:ClearAllPoints()
	topLine:SetHeight(2)
	topLine:SetPoint("TOPLEFT", detail, "TOPLEFT", 0, 0)
	topLine:SetPoint("TOPRIGHT", detail, "TOPRIGHT", 0, 0)
	topLine:SetColorTexture(dc.accentDim[1], dc.accentDim[2], dc.accentDim[3], 0.5)
	topLine:Show()

	-- Clear previous cell text
	if detail.cells then
		for _, cell in ipairs(detail.cells) do
			cell:SetText("")
		end
	end
	detail.cells = detail.cells or {}

	-- Hide previous name buttons and row backgrounds
	if detail.nameButtons then
		for _, btn in ipairs(detail.nameButtons) do
			btn:Hide()
		end
	end
	detail.nameButtons = detail.nameButtons or {}

	if detail.roleIcons then
		for _, t in ipairs(detail.roleIcons) do
			t:Hide()
		end
	end
	detail.roleIcons = detail.roleIcons or {}

	if detail.rowBgs then
		for _, t in ipairs(detail.rowBgs) do
			t:Hide()
		end
	end
	detail.rowBgs = detail.rowBgs or {}

	if detail.classBars then
		for _, t in ipairs(detail.classBars) do
			t:Hide()
		end
	end
	detail.classBars = detail.classBars or {}

	-- ── Header row ──────────────────────────────────────────────
	local headerBg = detail.headerBg
	if not headerBg then
		headerBg = detail:CreateTexture(nil, "BACKGROUND", nil, 1)
		detail.headerBg = headerBg
	end
	headerBg:ClearAllPoints()
	headerBg:SetPoint("TOPLEFT", detail, "TOPLEFT", DETAIL_PADDING, -DETAIL_PADDING)
	headerBg:SetPoint("RIGHT", detail, "RIGHT", -DETAIL_PADDING, 0)
	headerBg:SetHeight(DETAIL_HEADER_HEIGHT)
	headerBg:SetColorTexture(dc.headerBg[1], dc.headerBg[2], dc.headerBg[3], 1)
	headerBg:Show()

	local visibleStats = self:GetVisibleStatColumns()
	local cellIdx = 0
	local xOff = DETAIL_PADDING + CLASS_BAR_WIDTH + 6

	-- NAME header
	cellIdx = cellIdx + 1
	local nameHeader = detail.cells[cellIdx]
	if not nameHeader then
		nameHeader = detail:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
		detail.cells[cellIdx] = nameHeader
	end
	nameHeader:ClearAllPoints()
	nameHeader:SetPoint("TOPLEFT", detail, "TOPLEFT", xOff, -(DETAIL_PADDING + 6))
	nameHeader:SetWidth(FIXED_NAME_WIDTH)
	nameHeader:SetJustifyH("LEFT")
	nameHeader:SetText("NAME")
	nameHeader:SetTextColor(dc.accent[1], dc.accent[2], dc.accent[3])
	nameHeader:Show()
	xOff = xOff + FIXED_NAME_WIDTH

	-- Role icon header (empty label)
	cellIdx = cellIdx + 1
	local roleHeader = detail.cells[cellIdx]
	if not roleHeader then
		roleHeader = detail:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
		detail.cells[cellIdx] = roleHeader
	end
	roleHeader:ClearAllPoints()
	roleHeader:SetPoint("TOPLEFT", detail, "TOPLEFT", xOff, -(DETAIL_PADDING + 6))
	roleHeader:SetWidth(FIXED_ROLE_WIDTH)
	roleHeader:SetText("")
	roleHeader:Show()
	xOff = xOff + FIXED_ROLE_WIDTH

	-- Dynamic stat headers
	for _, col in ipairs(visibleStats) do
		cellIdx = cellIdx + 1
		local cell = detail.cells[cellIdx]
		if not cell then
			cell = detail:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
			detail.cells[cellIdx] = cell
		end
		cell:ClearAllPoints()
		cell:SetPoint("TOPLEFT", detail, "TOPLEFT", xOff, -(DETAIL_PADDING + 6))
		cell:SetWidth(col.width)
		cell:SetJustifyH("LEFT")
		cell:SetText(col.label)
		cell:SetTextColor(dc.accent[1], dc.accent[2], dc.accent[3])
		cell:Show()
		xOff = xOff + col.width
	end

	-- Gold accent line under header
	local headerLine = detail.headerLine
	if not headerLine then
		headerLine = detail:CreateTexture(nil, "ARTWORK")
		detail.headerLine = headerLine
	end
	headerLine:ClearAllPoints()
	headerLine:SetHeight(1)
	headerLine:SetPoint("TOPLEFT", detail, "TOPLEFT", DETAIL_PADDING, -(DETAIL_PADDING + DETAIL_HEADER_HEIGHT))
	headerLine:SetPoint("RIGHT", detail, "RIGHT", -DETAIL_PADDING, 0)
	headerLine:SetColorTexture(dc.accentDim[1], dc.accentDim[2], dc.accentDim[3], 0.4)
	headerLine:Show()

	-- ── Member rows ─────────────────────────────────────────────
	for mIdx, member in ipairs(members) do
		local stats = (run.playerStats or {})[member.guid] or {}
		local topY = DETAIL_PADDING + DETAIL_HEADER_HEIGHT + DETAIL_GAP + (mIdx - 1) * (DETAIL_ROW_HEIGHT + DETAIL_GAP)
		local nameRealm = member.name .. "-" .. (member.realm or "")
		local inViewList = self:IsViewMvp(nameRealm)
		local inLocalList = self:IsMvp(nameRealm)
		local isMvp = inViewList or inLocalList
		local r, g, b = self:GetClassColor(member.class)

		-- Row card background (alternating)
		local rowBg = detail.rowBgs[mIdx]
		if not rowBg then
			rowBg = detail:CreateTexture(nil, "BACKGROUND", nil, 1)
			detail.rowBgs[mIdx] = rowBg
		end
		local cardColor = (mIdx % 2 == 1) and dc.cardOdd or dc.cardEven
		rowBg:ClearAllPoints()
		rowBg:SetPoint("TOPLEFT", detail, "TOPLEFT", DETAIL_PADDING, -topY)
		rowBg:SetPoint("RIGHT", detail, "RIGHT", -DETAIL_PADDING, 0)
		rowBg:SetHeight(DETAIL_ROW_HEIGHT)
		rowBg:SetColorTexture(cardColor[1], cardColor[2], cardColor[3], 1)
		rowBg:Show()

		-- Class-colored left bar
		local classBar = detail.classBars[mIdx]
		if not classBar then
			classBar = detail:CreateTexture(nil, "ARTWORK")
			detail.classBars[mIdx] = classBar
		end
		classBar:ClearAllPoints()
		classBar:SetWidth(CLASS_BAR_WIDTH)
		classBar:SetPoint("TOPLEFT", detail, "TOPLEFT", DETAIL_PADDING, -topY)
		classBar:SetHeight(DETAIL_ROW_HEIGHT)
		classBar:SetColorTexture(r, g, b, 1)
		classBar:Show()

		-- Clickable name button
		local nameBtn = detail.nameButtons[mIdx]
		if not nameBtn then
			nameBtn = CreateFrame("Button", nil, detail)
			nameBtn:SetHeight(DETAIL_ROW_HEIGHT)

			nameBtn.star = nameBtn:CreateTexture(nil, "OVERLAY")
			nameBtn.star:SetSize(16, 16)
			nameBtn.star:SetPoint("LEFT", nameBtn, "LEFT", 2, 0)
			nameBtn.star:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
			nameBtn.star:SetVertexColor(1, 0.85, 0)    -- fixed gold (theme-independent)

			nameBtn.label = nameBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
			nameBtn.label:SetPoint("LEFT", nameBtn, "LEFT", 22, 0)
			nameBtn.label:SetJustifyH("LEFT")

			local highlight = nameBtn:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints()
			highlight:SetColorTexture(MPT.C.bubbleHover[1], MPT.C.bubbleHover[2], MPT.C.bubbleHover[3], 0.04)

			detail.nameButtons[mIdx] = nameBtn
		end

		nameBtn:ClearAllPoints()
		nameBtn:SetPoint("TOPLEFT", detail, "TOPLEFT", DETAIL_PADDING + CLASS_BAR_WIDTH + 3, -topY)
		nameBtn:SetWidth(FIXED_NAME_WIDTH)
		nameBtn:SetHeight(DETAIL_ROW_HEIGHT)

		if isMvp then
			nameBtn.star:Show()
			if self:IsViewingRemote() then
				if inViewList and inLocalList then
					nameBtn.star:SetDesaturated(true)
					nameBtn.star:SetVertexColor(0.2, 1, 0.2)    -- bright green
				elseif inViewList then
					nameBtn.star:SetDesaturated(true)
					nameBtn.star:SetVertexColor(0.3, 0.7, 1)    -- light vibrant blue
				else
					nameBtn.star:SetDesaturated(false)
					nameBtn.star:SetVertexColor(1, 0.85, 0)    -- fixed gold (theme-independent)
				end
			else
				nameBtn.star:SetDesaturated(false)
				nameBtn.star:SetVertexColor(1, 0.85, 0)    -- fixed gold (theme-independent)
			end
		else
			nameBtn.star:Hide()
		end

		nameBtn.label:SetText(nameRealm)
		nameBtn.label:SetWidth(FIXED_NAME_WIDTH - 24)
		nameBtn.label:SetTextColor(r, g, b)

		nameBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		if MPT:IsViewingRemote() then
			nameBtn:SetScript("OnClick", function()
				if not MPT:IsMvp(nameRealm) then
					local remoteNote
					if MPT.viewingData and MPT.viewingData.mvps and MPT.viewingData.mvps[nameRealm] then
						remoteNote = MPT.viewingData.mvps[nameRealm].note
					end
					MPT:AddMvp(nameRealm, UnitName("player"), member.class, remoteNote)
					MPT:OnMvpChanged()
				else
					MPT:RemoveMvp(nameRealm)
					MPT:OnMvpChanged()
				end
			end)
			nameBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local remoteNote = MPT:GetViewMvpNote(nameRealm)
				if remoteNote and remoteNote ~= "" then
					local ownerName = (MPT.viewingPlayer or ""):match("^([^%-]+)") or "Their"
					GameTooltip:AddLine(MPT:NoteLabel(ownerName, MPT.viewingClass), 1, 1, 1)
					GameTooltip:AddLine(remoteNote, MPT.NOTE_TEXT[1], MPT.NOTE_TEXT[2], MPT.NOTE_TEXT[3], true)
					GameTooltip:AddLine(" ")
				end
				if MPT:IsMvp(nameRealm) then
					GameTooltip:AddLine("In your MVP list", 1, 0.82, 0)
					GameTooltip:AddLine("Click to remove from your MVPs", 1, 0.5, 0.5)
				else
					GameTooltip:AddLine("Click to add to your MVPs", 0.5, 1, 0.5)
				end
				GameTooltip:Show()
			end)
			nameBtn:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		else
			nameBtn:SetScript("OnClick", function(self, button)
				if button == "RightButton" then
					if not MPT:IsMvp(nameRealm) then
						MPT:AddMvp(nameRealm, UnitName("player"), member.class)
						MPT:OnMvpChanged()
					end
					MPT:ShowNotePopup(nameRealm, self, member.class)
				else
					if MPT:IsMvp(nameRealm) then
						local note = MPT:GetMvpNote(nameRealm)
						if note and note ~= "" then
							MPT:ShowRemoveMvpConfirm(nameRealm, member.class)
						else
							MPT:RemoveMvp(nameRealm)
							MPT:OnMvpChanged()
						end
					else
						MPT:AddMvp(nameRealm, UnitName("player"), member.class)
						MPT:OnMvpChanged()
					end
				end
			end)

			nameBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				if MPT:IsMvp(nameRealm) then
					local note = MPT:GetMvpNote(nameRealm)
					if note and note ~= "" then
						GameTooltip:AddLine("MVP Note", MPT.NOTE_LABEL[1], MPT.NOTE_LABEL[2], MPT.NOTE_LABEL[3])
						GameTooltip:AddLine(note, MPT.NOTE_TEXT[1], MPT.NOTE_TEXT[2], MPT.NOTE_TEXT[3], true)
						GameTooltip:AddLine(" ")
					end
					GameTooltip:AddLine("Left-click to remove from MVPs", 1, 0.5, 0.5)
					GameTooltip:AddLine("Right-click to edit note", 0.7, 0.7, 0.7)
				else
					GameTooltip:AddLine("Left-click to add as MVP", 0.5, 1, 0.5)
					GameTooltip:AddLine("Right-click to add as MVP with note", 0.7, 0.7, 0.7)
				end
				GameTooltip:Show()
			end)
			nameBtn:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end

		nameBtn:Show()

		-- Role icon (pictogram atlas)
		local roleIcon = detail.roleIcons[mIdx]
		if not roleIcon then
			roleIcon = detail:CreateTexture(nil, "OVERLAY")
			roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
			detail.roleIcons[mIdx] = roleIcon
		end
		roleIcon:ClearAllPoints()
		xOff = DETAIL_PADDING + CLASS_BAR_WIDTH + 3 + FIXED_NAME_WIDTH
		roleIcon:SetPoint("TOPLEFT", detail, "TOPLEFT", xOff + 4, -(topY + 5))
		local coords = ROLE_COORDS[member.role]
		if coords then
			roleIcon:SetTexture(ROLE_TEX)
			roleIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			roleIcon:SetVertexColor(1, 1, 1)
			roleIcon:Show()
		else
			roleIcon:Hide()
		end

		-- Stat cells (dynamic, based on visible stat columns)
		xOff = DETAIL_PADDING + CLASS_BAR_WIDTH + 6 + FIXED_NAME_WIDTH + FIXED_ROLE_WIDTH
		for _, col in ipairs(visibleStats) do
			cellIdx = cellIdx + 1
			local cell = detail.cells[cellIdx]
			if not cell then
				cell = detail:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
				detail.cells[cellIdx] = cell
			end
			cell:ClearAllPoints()
			cell:SetPoint("TOPLEFT", detail, "TOPLEFT", xOff, -(topY + 7))
			cell:SetWidth(col.width)
			cell:SetJustifyH("LEFT")

			local raw = stats[col.key]
			local val
			if raw == nil then
				val = "-"
			elseif COUNT_STATS[col.key] then
				val = tostring(raw)
			else
				val = self:AbbreviateNumber(raw)
			end
			cell:SetText(val)
			cell:SetTextColor(dc.text[1], dc.text[2], dc.text[3])
			cell:Show()

			xOff = xOff + col.width
		end
	end

	-- Hide leftover cells from previous renders with more columns
	for i = cellIdx + 1, #detail.cells do
		detail.cells[i]:Hide()
	end

	-- ── Action bar background zone ─────────────────────────────
	local actionZoneBg = detail.actionZoneBg
	if not actionZoneBg then
		actionZoneBg = detail:CreateTexture(nil, "BACKGROUND", nil, 1)
		detail.actionZoneBg = actionZoneBg
	end
	actionZoneBg:ClearAllPoints()
	actionZoneBg:SetPoint("BOTTOMLEFT", detail, "BOTTOMLEFT", DETAIL_PADDING, DETAIL_PADDING - 2)
	actionZoneBg:SetPoint("RIGHT", detail, "RIGHT", -DETAIL_PADDING, 0)
	actionZoneBg:SetHeight(ACTION_BAR_HEIGHT + 4)
	actionZoneBg:SetColorTexture(dc.actionBg[1], dc.actionBg[2], dc.actionBg[3], 1)
	actionZoneBg:Show()

	-- Divider line above action bar
	local actionDiv = detail.actionDiv
	if not actionDiv then
		actionDiv = detail:CreateTexture(nil, "ARTWORK")
		detail.actionDiv = actionDiv
	end
	actionDiv:ClearAllPoints()
	actionDiv:SetHeight(1)
	actionDiv:SetPoint("BOTTOMLEFT", actionZoneBg, "TOPLEFT", 0, 0)
	actionDiv:SetPoint("RIGHT", actionZoneBg, "TOPRIGHT", 0, 0)
	actionDiv:SetColorTexture(dc.divider[1], dc.divider[2], dc.divider[3], 1)
	actionDiv:Show()

	-- ── Action bar ──────────────────────────────────────────────
	if not detail.actionBar then
		local actionBar = CreateFrame("Frame", nil, detail)
		actionBar:SetPoint("BOTTOMLEFT", detail, "BOTTOMLEFT", DETAIL_PADDING + CLASS_BAR_WIDTH + 6, DETAIL_PADDING)
		actionBar:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -DETAIL_PADDING, DETAIL_PADDING)
		actionBar:SetHeight(ACTION_BAR_HEIGHT)

		local editLinkBtn = self:CreateModernButton(actionBar, 70, 20, "Edit Link")
		editLinkBtn:SetPoint("LEFT", actionBar, "LEFT", 0, 0)
		actionBar.editLinkBtn = editLinkBtn

		local editDescBtn = self:CreateModernButton(actionBar, 80, 20, "Edit Desc")
		editDescBtn:SetPoint("LEFT", editLinkBtn, "RIGHT", 8, 0)
		actionBar.editDescBtn = editDescBtn

		local deathText = actionBar:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		actionBar.deathText = deathText

		local intText = actionBar:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		actionBar.intText = intText

		detail.actionBar = actionBar
	end

	-- Position death/interrupt totals under their respective stat columns
	local totalInterrupts = 0
	if run.playerStats then
		for _, ps in pairs(run.playerStats) do
			totalInterrupts = totalInterrupts + (ps.interrupts or 0)
		end
	end

	local abXOff = FIXED_NAME_WIDTH + FIXED_ROLE_WIDTH
	detail.actionBar.deathText:Hide()
	detail.actionBar.intText:Hide()
	for _, col in ipairs(visibleStats) do
		if col.key == "deaths" then
			detail.actionBar.deathText:ClearAllPoints()
			detail.actionBar.deathText:SetPoint("LEFT", detail.actionBar, "LEFT", abXOff, 0)
			detail.actionBar.deathText:SetWidth(col.width)
			detail.actionBar.deathText:SetJustifyH("LEFT")
			detail.actionBar.deathText:SetText(tostring(run.totalDeaths or 0))
			detail.actionBar.deathText:SetTextColor(dc.textMuted[1], dc.textMuted[2], dc.textMuted[3])
			detail.actionBar.deathText:Show()
		elseif col.key == "interrupts" then
			detail.actionBar.intText:ClearAllPoints()
			detail.actionBar.intText:SetPoint("LEFT", detail.actionBar, "LEFT", abXOff, 0)
			detail.actionBar.intText:SetWidth(col.width)
			detail.actionBar.intText:SetJustifyH("LEFT")
			detail.actionBar.intText:SetText(tostring(totalInterrupts))
			detail.actionBar.intText:SetTextColor(dc.textMuted[1], dc.textMuted[2], dc.textMuted[3])
			detail.actionBar.intText:Show()
		end
		abXOff = abXOff + col.width
	end

	if self:IsViewingRemote() then
		if run.link and run.link ~= "" then
			detail.actionBar.editLinkBtn:Show()
			detail.actionBar.editLinkBtn.label:SetText("Copy Link")
			detail.actionBar.editLinkBtn:SetScript("OnClick", function(self)
				MPT:ShowLinkCopyPopup(run.link, self, true)
			end)
		else
			detail.actionBar.editLinkBtn:Hide()
		end
		detail.actionBar.editDescBtn:Hide()
	else
		detail.actionBar.editLinkBtn:Show()
		detail.actionBar.editLinkBtn.label:SetText("Edit Link")
		detail.actionBar.editLinkBtn:SetScript("OnClick", function(self)
			MPT:ShowEditPopup(run.id, "link", run.link, self)
		end)
		detail.actionBar.editDescBtn:Show()
		detail.actionBar.editDescBtn:SetScript("OnClick", function(self)
			MPT:ShowEditPopup(run.id, "description", run.description, self)
		end)
	end

	detail.actionBar:Show()
	detail:Show()
end

function MPT:CollapseRow(row)
	if row.detailFrame then
		row.detailFrame:Hide()
	end
end
