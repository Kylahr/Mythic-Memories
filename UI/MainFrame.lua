local _, MPT = ...

local ROW_HEIGHT = 32
local VISIBLE_ROWS = 15
local HEADER_HEIGHT = 28
local MVP_PANEL_WIDTH = 200

-- ── Sepia/grey palette (wider contrast range) ────────────────
local C = {
	bg         = { 0.12, 0.12, 0.09 },     -- main frame / canvas
	titleBar   = { 0.20, 0.20, 0.16 },     -- title strip
	filterBar  = { 0.16, 0.16, 0.13 },     -- filter bar strip
	panelBg    = { 0.14, 0.14, 0.11 },     -- table card / MVP card
	headerBg   = { 0.23, 0.22, 0.18 },     -- column header bar
	rowBase    = { 0.18, 0.18, 0.15 },     -- odd rows
	rowAlt     = { 0.22, 0.21, 0.17 },     -- even rows
	inputBg    = { 0.10, 0.10, 0.08 },     -- search input fields
	btnBg      = { 0.25, 0.24, 0.20 },     -- button background
	btnHover   = { 0.33, 0.31, 0.25 },     -- button hover
	accent     = { 1, 0.82, 0 },           -- gold accent
	accentDim  = { 0.7, 0.57, 0 },         -- dimmed gold
	textPrimary= { 0.92, 0.90, 0.84 },     -- warm cream
	textMuted  = { 0.50, 0.48, 0.42 },     -- muted warm grey
	textLabel  = { 0.65, 0.63, 0.56 },     -- label text
	divider    = { 0.28, 0.26, 0.21 },     -- dividers
	highlight  = { 1, 0.95, 0.8, 0.06 },   -- row hover
	popupBg    = { 0.13, 0.13, 0.10 },     -- popup backgrounds
}

-- ── Custom font objects ───────────────────────────────────────
local FONT_FILE = "Fonts\\FRIZQT__.TTF"
local MPTFont_Title = CreateFont("MPTFont_Title")
MPTFont_Title:SetFont(FONT_FILE, 14, "")
MPTFont_Title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

local MPTFont_Header = CreateFont("MPTFont_Header")
MPTFont_Header:SetFont(FONT_FILE, 11, "")
MPTFont_Header:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

local MPTFont_Cell = CreateFont("MPTFont_Cell")
MPTFont_Cell:SetFont(FONT_FILE, 11, "")
MPTFont_Cell:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])

local MPTFont_Label = CreateFont("MPTFont_Label")
MPTFont_Label:SetFont(FONT_FILE, 10, "")
MPTFont_Label:SetTextColor(C.textLabel[1], C.textLabel[2], C.textLabel[3])

local MPTFont_Small = CreateFont("MPTFont_Small")
MPTFont_Small:SetFont(FONT_FILE, 10, "")
MPTFont_Small:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
local COLUMNS = {
	{ key = "date",      label = "DATE",    width = 82 },
	{ key = "dungeon",   label = "DUNGEON", width = 155 },
	{ key = "level",     label = "LVL",     width = 40 },
	{ key = "time",      label = "TIME",    width = 60 },
	{ key = "affix",     label = "AFFIX",   width = 140 },
	{ key = "bonus",     label = "BONUS",   width = 55 },
	{ key = "role",      label = "ROLE",    width = 55 },
	{ key = "mvp",       label = "MVP",     width = 35 },
	{ key = "desc",      label = "DESC",    width = 40 },
	{ key = "link",      label = "LINK",    width = 40 },
}

local ROLE_LABELS = {
	TANK = "Tank",
	HEALER = "Healer",
	DAMAGER = "DPS",
}

MPT.COLUMNS = COLUMNS
MPT.ROW_HEIGHT = ROW_HEIGHT
MPT.VISIBLE_ROWS = VISIBLE_ROWS

-- ── Modern UI helpers ───────────────────────────────────────────

function MPT:CreateModernButton(parent, width, height, text)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width, height)

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
	btn.bg = bg

	local label = btn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	label:SetPoint("CENTER")
	label:SetText(text or "")
	label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	btn.label = label

	btn.SetText = function(self, t) self.label:SetText(t) end
	btn.GetText = function(self) return self.label:GetText() end

	btn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	btn:SetScript("OnLeave", function(self)
		self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
		self.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	end)

	return btn
end

-- Custom styled search input (replaces ugly InputBoxTemplate)
function MPT:CreateSearchInput(parent, name, width)
	local container = CreateFrame("Frame", nil, parent)
	container:SetSize(width, 22)

	local bg = container:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)

	local editBox = CreateFrame("EditBox", name, container)
	editBox:SetPoint("TOPLEFT", 6, -2)
	editBox:SetPoint("BOTTOMRIGHT", -6, 2)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("MPTFont_Cell")

	container.editBox = editBox
	return container
end

-- Custom modern checkbox (replaces UICheckButtonTemplate)
function MPT:CreateModernCheckbox(parent, label, size)
	size = size or 16
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(size, size)

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)
	btn.bg = bg

	-- Checkmark (a simple filled inner square)
	local check = btn:CreateTexture(nil, "OVERLAY")
	check:SetSize(size - 6, size - 6)
	check:SetPoint("CENTER")
	check:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
	check:Hide()
	btn.check = check

	btn._checked = false
	btn.SetChecked = function(self, val)
		self._checked = val and true or false
		if self._checked then self.check:Show() else self.check:Hide() end
	end
	btn.GetChecked = function(self) return self._checked end

	btn:SetScript("OnClick", function(self)
		self:SetChecked(not self._checked)
		if self._onToggle then self._onToggle(self._checked) end
	end)
	btn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
	end)
	btn:SetScript("OnLeave", function(self)
		self.bg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)
	end)

	-- Label text
	if label then
		local text = btn:GetParent():CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		text:SetPoint("LEFT", btn, "RIGHT", 6, 0)
		text:SetText(label)
		text:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		btn.label = text
	end

	return btn
end

function MPT:CreateCloseButton(parent)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(22, 22)

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER", 0, 0)
	label:SetText("X")
	label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

	btn:SetScript("OnEnter", function()
		label:SetTextColor(1, 0.3, 0.3)
	end)
	btn:SetScript("OnLeave", function()
		label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	btn:SetScript("OnClick", function()
		parent:Hide()
	end)

	return btn
end

local function getTotalWidth()
	local total = 0
	for _, col in ipairs(COLUMNS) do
		total = total + col.width
	end
	return total
end

function MPT:CreateMainFrame()
	if self.mainFrame then return end

	local PADDING = 8
	local SCROLLBAR_WIDTH = 18
	local tableWidth = getTotalWidth()
	local tableAreaWidth = math.max(tableWidth + SCROLLBAR_WIDTH + 12, 730)
	local totalWidth = PADDING + tableAreaWidth + 4 + MVP_PANEL_WIDTH + PADDING  -- 4px gap between cards
	local totalHeight = HEADER_HEIGHT + (ROW_HEIGHT * VISIBLE_ROWS) + 100

	local frame = CreateFrame("Frame", "MPTMainFrame", UIParent)
	frame:SetSize(totalWidth, totalHeight)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("HIGH")
	tinsert(UISpecialFrames, "MPTMainFrame")

	-- Main background
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)

	-- ── Title bar strip (different hue) ────────────────────────
	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	titleBar:SetHeight(32)
	local titleBarBg = titleBar:CreateTexture(nil, "BACKGROUND")
	titleBarBg:SetAllPoints()
	titleBarBg:SetColorTexture(C.titleBar[1], C.titleBar[2], C.titleBar[3], 1)
	titleBarBg:SetDrawLayer("BACKGROUND", 2)

	local title = frame:CreateFontString(nil, "OVERLAY", "MPTFont_Title")
	title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
	title:SetText("Mythic Memories")
	self.mainTitle = title

	local closeBtn = self:CreateCloseButton(frame)
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

	-- Back button (visible only in view mode)
	local backBtn = self:CreateModernButton(frame, 60, 20, "< Back")
	backBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
	backBtn:SetScript("OnClick", function()
		MPT:ExitViewMode()
	end)
	backBtn:Hide()
	self.backBtn = backBtn

	-- Help button (top-left, hidden in view mode) — click to toggle help panel
	local helpBtn = CreateFrame("Button", nil, frame)
	helpBtn:SetSize(20, 20)
	helpBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)

	local helpLabel = helpBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	helpLabel:SetPoint("CENTER", 0, 0)
	helpLabel:SetText("?")
	helpLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

	helpBtn:SetScript("OnEnter", function()
		helpLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	helpBtn:SetScript("OnLeave", function()
		helpLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	helpBtn:SetScript("OnClick", function()
		MPT:ToggleHelpPanel()
	end)
	self.helpBtn = helpBtn

	frame:SetScript("OnHide", function()
		MPT:HideAllPopups()
		MPT.expandedRunId = nil
		-- Clear view mode when closing
		if MPT.viewingPlayer then
			MPT.viewingPlayer = nil
			MPT.viewingData = nil
			MPT:UpdateViewModeUI()
		end
	end)

	-- ── Filter bar card ─────────────────────────────────────────
	self:CreateFilterBar(frame)

	-- ── Table card (elevated panel for headers + rows) ──────────
	local tableCard = CreateFrame("Frame", nil, frame)
	tableCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -62)
	tableCard:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	tableCard:SetWidth(tableAreaWidth)
	local tcBg = tableCard:CreateTexture(nil, "BACKGROUND")
	tcBg:SetAllPoints()
	tcBg:SetColorTexture(C.panelBg[1], C.panelBg[2], C.panelBg[3], 1)
	tcBg:SetDrawLayer("BACKGROUND", 2)
	self.tableCard = tableCard

	self:CreateColumnHeaders(tableCard)
	self:CreateScrollFrame(tableCard, tableWidth)

	-- ── MVP card (elevated panel) ──────────────────────────────
	self:CreateMvpsSidePanel(frame, PADDING, tableCard)

	frame:Hide()
	self.mainFrame = frame
end

function MPT:CreateFilterBar(parent)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -32)
	bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -32)
	bar:SetHeight(28)
	-- Filter bar background (slightly different hue from title and table)
	local barBg = bar:CreateTexture(nil, "BACKGROUND")
	barBg:SetAllPoints()
	barBg:SetColorTexture(C.filterBar[1], C.filterBar[2], C.filterBar[3], 1)
	barBg:SetDrawLayer("BACKGROUND", 2)

	local playerLabel = bar:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	playerLabel:SetPoint("LEFT", bar, "LEFT", 10, 0)
	playerLabel:SetText("Player")

	local playerInput = self:CreateSearchInput(bar, "MPTFilterPlayer", 85)
	playerInput:SetPoint("LEFT", playerLabel, "RIGHT", 6, 0)
	local playerBox = playerInput.editBox
	playerBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		MPT:ApplyFilters()
	end)

	local realmLabel = bar:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	realmLabel:SetPoint("LEFT", playerInput, "RIGHT", 12, 0)
	realmLabel:SetText("Realm")

	local realmInput = self:CreateSearchInput(bar, "MPTFilterRealm", 85)
	realmInput:SetPoint("LEFT", realmLabel, "RIGHT", 6, 0)
	local realmBox = realmInput.editBox
	realmBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		MPT:ApplyFilters()
	end)

	local dungeonLabel = bar:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	dungeonLabel:SetPoint("LEFT", realmInput, "RIGHT", 12, 0)
	dungeonLabel:SetText("Dungeon")

	local dungeonInput = self:CreateSearchInput(bar, "MPTFilterDungeon", 85)
	dungeonInput:SetPoint("LEFT", dungeonLabel, "RIGHT", 6, 0)
	local dungeonBox = dungeonInput.editBox
	dungeonBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		MPT:ApplyFilters()
	end)

	local searchBtn = self:CreateModernButton(bar, 55, 20, "Search")
	searchBtn:SetPoint("LEFT", dungeonInput, "RIGHT", 12, 0)
	searchBtn:SetScript("OnClick", function()
		MPT:ApplyFilters()
	end)

	local clearBtn = self:CreateModernButton(bar, 50, 20, "Clear")
	clearBtn:SetPoint("LEFT", searchBtn, "RIGHT", 4, 0)
	clearBtn:SetScript("OnClick", function()
		playerBox:SetText("")
		dungeonBox:SetText("")
		realmBox:SetText("")
		MPT:ApplyFilters()
	end)

	-- Options button
	local optionsBtn = self:CreateModernButton(bar, 65, 20, "Options")
	optionsBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
	optionsBtn:SetScript("OnClick", function()
		MPT:ToggleOptionsPanel()
	end)
	self.optionsBtn = optionsBtn

	self.filterBar = bar
	self.filterPlayerBox = playerBox
	self.filterDungeonBox = dungeonBox
	self.filterRealmBox = realmBox
end

function MPT:CreateColumnHeaders(parent)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
	header:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
	header:SetHeight(HEADER_HEIGHT)

	local bg = header:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.headerBg[1], C.headerBg[2], C.headerBg[3], 1)

	local xOff = 0
	for _, col in ipairs(COLUMNS) do
		local text = header:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
		text:SetPoint("LEFT", header, "LEFT", xOff + 4, 0)
		text:SetWidth(col.width - 8)
		text:SetJustifyH("LEFT")
		text:SetText(col.label)
		xOff = xOff + col.width
	end

	self.headerFrame = header
end

function MPT:CreateScrollFrame(parent, tableWidth)
	local scrollParent = CreateFrame("Frame", nil, parent)
	scrollParent:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2 - HEADER_HEIGHT)
	scrollParent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
	scrollParent:SetClipsChildren(true)

	local scrollFrame = CreateFrame("ScrollFrame", "MPTScrollFrame", scrollParent, "FauxScrollFrameTemplate")
	scrollFrame:SetAllPoints()
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function()
			MPT:RefreshTable()
		end)
	end)

	-- Hide the default FauxScrollFrame scrollbar visually but keep it functional
	-- (it must retain its anchors/height so FauxScrollFrame_Update can set min/max)
	local defaultBar = _G["MPTScrollFrameScrollBar"]
	if defaultBar then
		defaultBar:SetAlpha(0)
		defaultBar:SetWidth(1)
	end
	for _, suffix in ipairs({"ScrollBarScrollUpButton", "ScrollBarScrollDownButton"}) do
		local btn = _G["MPTScrollFrame" .. suffix]
		if btn then btn:SetSize(1, 1); btn:SetAlpha(0) end
	end

	-- Custom thin scrollbar track
	local track = CreateFrame("Frame", nil, scrollParent)
	track:SetWidth(6)
	track:SetPoint("TOPRIGHT", scrollParent, "TOPRIGHT", -2, 0)
	track:SetPoint("BOTTOMRIGHT", scrollParent, "BOTTOMRIGHT", -2, 0)
	local trackBg = track:CreateTexture(nil, "BACKGROUND")
	trackBg:SetAllPoints()
	trackBg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)

	-- Thumb
	local thumb = CreateFrame("Frame", nil, track)
	thumb:SetWidth(6)
	thumb:SetHeight(40)
	thumb:SetPoint("TOP", track, "TOP")
	thumb:EnableMouse(true)
	thumb:SetMovable(true)
	local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
	thumbTex:SetAllPoints()
	thumbTex:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
	self.mainScrollTrack = track
	self.mainScrollThumb = thumb

	-- Mouse wheel scrolling on the scroll parent
	scrollParent:EnableMouseWheel(true)
	scrollParent:SetScript("OnMouseWheel", function(_, delta)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar then
			local cur = scrollBar:GetValue()
			local newVal = cur - (delta * ROW_HEIGHT)
			scrollBar:SetValue(newVal)
		end
	end)

	-- Thumb dragging
	thumb:RegisterForDrag("LeftButton")
	thumb:SetScript("OnDragStart", function(self) self.dragging = true end)
	thumb:SetScript("OnDragStop", function(self) self.dragging = false end)
	thumb:SetScript("OnUpdate", function(self)
		if not self.dragging then return end
		local _, cursorY = GetCursorPosition()
		local scale = track:GetEffectiveScale()
		cursorY = cursorY / scale
		local top = track:GetTop()
		local trackH = track:GetHeight()
		local thumbH = self:GetHeight()
		local scrollRatio = math.max(0, math.min(1, (top - cursorY - thumbH / 2) / (trackH - thumbH)))
		local runs = MPT:GetFilteredRuns()
		local maxOffset = math.max(0, #runs - VISIBLE_ROWS)
		local newOffset = math.floor(scrollRatio * maxOffset + 0.5)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar and scrollBar.SetValue then
			scrollBar:SetValue(newOffset * ROW_HEIGHT)
		end
	end)

	self.rows = {}
	for i = 1, VISIBLE_ROWS do
		self.rows[i] = self:CreateRow(scrollParent, i)
	end

	self.scrollParent = scrollParent
	self.scrollFrame = scrollFrame
end

function MPT:CreateRow(parent, index)
	local row = CreateFrame("Button", "MPTRow" .. index, parent)
	row:SetHeight(ROW_HEIGHT)

	local bg = row:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.rowBase[1], C.rowBase[2], C.rowBase[3], 1)
	row.bg = bg

	local highlight = row:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], C.highlight[4])

	-- Data cells
	row.cells = {}
	local xOff = 0
	for colIdx, col in ipairs(COLUMNS) do
		local cell = row:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		cell:SetPoint("LEFT", row, "LEFT", xOff + 4, 0)
		cell:SetWidth(col.width - 8)
		cell:SetJustifyH("LEFT")
		row.cells[colIdx] = cell
		xOff = xOff + col.width
	end

	-- Find column positions by key for interactive zones
	local function getColOffset(key)
		local off = 0
		for _, col in ipairs(COLUMNS) do
			if col.key == key then return off, col.width end
			off = off + col.width
		end
		return off, 0
	end

	-- MVP star icon (centered in MVP column)
	local mvpOff, mvpW = getColOffset("mvp")
	local mvpStar = row:CreateTexture(nil, "OVERLAY")
	mvpStar:SetSize(24, 24)
	mvpStar:SetPoint("CENTER", row, "LEFT", mvpOff + mvpW / 2, 0)
	mvpStar:SetTexture("Interface\\COMMON\\FavoritesIcon")
	mvpStar:SetVertexColor(1, 0.9, 0)
	mvpStar:Hide()
	row.mvpStar = mvpStar

	-- MVP tooltip zone
	local mvpZone = CreateFrame("Button", nil, row)
	mvpZone:SetPoint("LEFT", row, "LEFT", mvpOff, 0)
	mvpZone:SetSize(mvpW, ROW_HEIGHT)
	mvpZone:SetScript("OnEnter", function(self)
		if row.runData and row.mvpNames and #row.mvpNames > 0 then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("MVPs", 1, 0.82, 0)
			for _, name in ipairs(row.mvpNames) do
				local note = MPT:GetMvpNote(name)
				if note and note ~= "" then
					GameTooltip:AddLine(name .. " - " .. note, 1, 1, 1, true)
				else
					GameTooltip:AddLine(name, 1, 1, 1)
				end
			end
			GameTooltip:Show()
		end
	end)
	mvpZone:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row.mvpZone = mvpZone

	-- Link click zone — opens edit popup
	local linkOff, linkW = getColOffset("link")
	local linkZone = CreateFrame("Button", nil, row)
	linkZone:SetPoint("LEFT", row, "LEFT", linkOff, 0)
	linkZone:SetSize(linkW, ROW_HEIGHT)
	linkZone:SetScript("OnClick", function(self)
		if row.runData then
			MPT:ShowEditPopup(row.runData.id, "link", row.runData.link, self)
		end
	end)
	local linkHighlight = linkZone:CreateTexture(nil, "HIGHLIGHT")
	linkHighlight:SetAllPoints()
	linkHighlight:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.08)
	row.linkZone = linkZone

	-- Link icon (shown when run has a link)
	local linkIcon = linkZone:CreateTexture(nil, "OVERLAY")
	linkIcon:SetSize(14, 14)
	linkIcon:SetPoint("CENTER", linkZone, "CENTER", 0, 0)
	linkIcon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-MOTD-Up")
	linkIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	linkIcon:Hide()
	row.linkIcon = linkIcon

	-- Description click zone — opens edit popup, tooltip on hover
	local descOff, descW = getColOffset("desc")
	local descZone = CreateFrame("Button", nil, row)
	descZone:SetPoint("LEFT", row, "LEFT", descOff, 0)
	descZone:SetSize(descW, ROW_HEIGHT)
	descZone:SetScript("OnClick", function(self)
		if row.runData then
			MPT:ShowEditPopup(row.runData.id, "description", row.runData.description, self)
		end
	end)
	descZone:SetScript("OnEnter", function(self)
		if row.runData and row.runData.description and row.runData.description ~= "" then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(row.runData.description, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	descZone:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	local descHighlight = descZone:CreateTexture(nil, "HIGHLIGHT")
	descHighlight:SetAllPoints()
	descHighlight:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.08)
	row.descZone = descZone

	-- Description file icon (shown when run has a description)
	local descIcon = descZone:CreateTexture(nil, "OVERLAY")
	descIcon:SetSize(16, 16)
	descIcon:SetPoint("CENTER", descZone, "CENTER", 0, 0)
	descIcon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up")
	descIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	descIcon:Hide()
	row.descIcon = descIcon

	-- Highlight indicator (hidden by default, used for scroll-to highlight)
	local shimmerTex = row:CreateTexture(nil, "ARTWORK")
	shimmerTex:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	shimmerTex:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	shimmerTex:SetWidth(3)
	shimmerTex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
	shimmerTex:SetAlpha(0)
	shimmerTex:Hide()
	row.shimmerTex = shimmerTex

	-- Mouse wheel passthrough to scroll the table
	row:EnableMouseWheel(true)
	row:SetScript("OnMouseWheel", function(_, delta)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar then
			local cur = scrollBar:GetValue()
			scrollBar:SetValue(cur - (delta * ROW_HEIGHT))
		end
	end)

	-- Row click expands/collapses tree view
	row:SetScript("OnClick", function()
		if row.runData then
			MPT:ToggleRowExpansion(row)
		end
	end)

	return row
end

function MPT:ApplyFilters()
	self.currentFilters = {
		player = self.filterPlayerBox and self.filterPlayerBox:GetText() or "",
		dungeon = self.filterDungeonBox and self.filterDungeonBox:GetText() or "",
		realm = self.filterRealmBox and self.filterRealmBox:GetText() or "",
	}
	self:RefreshTable()
end

function MPT:GetFilteredRuns()
	return self:GetRuns(self.currentFilters)
end

function MPT:UpdateMainScrollThumb()
	local thumb = self.mainScrollThumb
	local track = self.mainScrollTrack
	if not thumb or not track then return end

	local runs = self:GetFilteredRuns()
	local totalRows = #runs
	if totalRows <= VISIBLE_ROWS then
		thumb:Hide()
		return
	end

	thumb:Show()
	local trackH = track:GetHeight()
	local ratio = VISIBLE_ROWS / totalRows
	local thumbH = math.max(20, trackH * ratio)
	thumb:SetHeight(thumbH)

	local offset = FauxScrollFrame_GetOffset(self.scrollFrame)
	local maxOffset = totalRows - VISIBLE_ROWS
	local scrollRatio = (maxOffset > 0) and (offset / maxOffset) or 0
	thumb:ClearAllPoints()
	thumb:SetPoint("TOP", track, "TOP", 0, -scrollRatio * (trackH - thumbH))
end

function MPT:RefreshTable()
	if not self.scrollFrame then return end

	local runs = self:GetFilteredRuns()
	local offset = FauxScrollFrame_GetOffset(self.scrollFrame)

	FauxScrollFrame_Update(self.scrollFrame, #runs, VISIBLE_ROWS, ROW_HEIGHT)
	self:UpdateMainScrollThumb()

	local yOffset = 0
	local maxY = VISIBLE_ROWS * ROW_HEIGHT

	for i = 1, VISIBLE_ROWS do
		local row = self.rows[i]
		local dataIdx = offset + i

		if dataIdx <= #runs and yOffset < maxY then
			local run = runs[dataIdx]
			row.runData = run

			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", self.scrollParent, "TOPLEFT", 0, -yOffset)
			row:SetPoint("RIGHT", self.scrollParent, "RIGHT", -10, 0)

			-- Alternating row background
			if dataIdx % 2 == 0 then
				row.bg:SetColorTexture(C.rowAlt[1], C.rowAlt[2], C.rowAlt[3], 1)
			else
				row.bg:SetColorTexture(C.rowBase[1], C.rowBase[2], C.rowBase[3], 1)
			end

			self:PopulateRow(row, run)
			row:Show()

			-- Shimmer the row if it matches scroll-to target
			if self.shimmerRunId and run.id == self.shimmerRunId then
				self:ShimmerRow(row)
				self.shimmerRunId = nil
			end

			yOffset = yOffset + ROW_HEIGHT

			if self.expandedRunId and run.id == self.expandedRunId then
				self:ExpandRow(row)
				yOffset = yOffset + row.detailFrame:GetHeight()
			else
				if row.detailFrame then row.detailFrame:Hide() end
				row.expanded = false
			end
		else
			row.runData = nil
			row:Hide()
			if row.detailFrame then row.detailFrame:Hide() end
		end
	end
end

function MPT:ShimmerRow(row)
	local tex = row.shimmerTex
	if not tex then return end
	tex:Show()
	tex:SetAlpha(1)
	-- Fade out smoothly over 1.5 seconds in many small steps
	local duration = 1.5
	local steps = 30
	local interval = duration / steps
	for i = 1, steps do
		C_Timer.After(i * interval, function()
			local alpha = 1 - (i / steps)
			tex:SetAlpha(alpha)
			if i == steps then
				tex:Hide()
			end
		end)
	end
end

function MPT:ScrollToPlayerRun(nameRealm)
	local runs = self:GetFilteredRuns()
	local targetIdx = nil

	-- Find the most recent run (first in list) containing this player
	for i, run in ipairs(runs) do
		for _, m in ipairs(run.members or {}) do
			local nr = m.name .. "-" .. (m.realm or "")
			if nr == nameRealm then
				targetIdx = i
				break
			end
		end
		if targetIdx then break end
	end

	if not targetIdx then return end

	local targetRun = runs[targetIdx]

	-- Expand the target row
	self.expandedRunId = targetRun.id

	-- Calculate scroll offset to place target row near the top
	local offset = math.max(0, targetIdx - 1)
	local maxOffset = math.max(0, #runs - VISIBLE_ROWS)
	offset = math.min(offset, maxOffset)

	-- Store target for shimmer (RefreshTable will pick this up)
	self.shimmerRunId = targetRun.id

	-- Scroll the FauxScrollFrame to the target position
	local scrollBar = _G["MPTScrollFrameScrollBar"]
	if scrollBar and scrollBar.SetValue then
		scrollBar:SetValue(offset * ROW_HEIGHT)
	end

	-- Ensure refresh happens even if scrollbar didn't change
	self:RefreshTable()
end

function MPT:PopulateRow(row, run)
	local bonusText
	if not run.onTime and run.bonus == 0 then
		bonusText = "Dep"
	else
		bonusText = "+" .. run.bonus
	end

	-- Find the relevant player's member entry for the Role column
	-- In remote view: show the table owner's role; locally: show our own role
	local lookupName = self:IsViewingRemote() and self.viewingPlayer or UnitName("player")
	-- Strip realm suffix if present (comm sender may include it cross-realm)
	local lookupShort = lookupName and lookupName:match("^([^%-]+)") or lookupName
	local playerMember = nil
	for _, m in ipairs(run.members or {}) do
		if m.name == lookupName or m.name == lookupShort then
			playerMember = m
			break
		end
	end
	local roleText = playerMember and (ROLE_LABELS[playerMember.role] or playerMember.role) or ""

	-- Collect MVP names for this run
	local mvpNames = {}
	for _, m in ipairs(run.members or {}) do
		local nameRealm = m.name .. "-" .. (m.realm or "")
		if self:IsViewMvp(nameRealm) then
			mvpNames[#mvpNames + 1] = nameRealm
		end
	end
	row.mvpNames = mvpNames

	-- Show/hide star icon in MVP column
	if #mvpNames > 0 then
		row.mvpStar:Show()
	else
		row.mvpStar:Hide()
	end

	local values = {
		run.date or "",
		run.dungeon or "",
		tostring(run.level or ""),
		run.timeStr or "",
		run.affix or "",
		bonusText,
		roleText,
		"",  -- MVP column uses star icon, not text
		"",  -- Desc column uses icon, not text
		"",  -- Link column uses icon, not text
	}

	local isViewing = self:IsViewingRemote()

	for colIdx, val in ipairs(values) do
		row.cells[colIdx]:SetText(val)
		row.cells[colIdx]:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	end

	-- Disable interactive zones in view mode (but allow link copying)
	if isViewing then
		if run.link and run.link ~= "" then
			row.linkZone:SetScript("OnClick", function(self)
				MPT:ShowLinkCopyPopup(row.runData.link, self, true)
			end)
		else
			row.linkZone:SetScript("OnClick", nil)
		end
		row.descZone:SetScript("OnClick", nil)
	else
		row.linkZone:SetScript("OnClick", function(self)
			if row.runData then
				MPT:ShowEditPopup(row.runData.id, "link", row.runData.link, self)
			end
		end)
		row.descZone:SetScript("OnClick", function(self)
			if row.runData then
				MPT:ShowEditPopup(row.runData.id, "description", row.runData.description, self)
			end
		end)
	end

	-- Role column class color (column 7)
	if playerMember then
		local r, g, b = self:GetClassColor(playerMember.class)
		row.cells[7]:SetTextColor(r, g, b)
	end

	-- Bonus text color from heatmap
	local hr, hg, hb = self:GetBonusColor(run.bonus, run.onTime)
	row.cells[6]:SetTextColor(hr, hg, hb)

	-- Description icon
	if run.description and run.description ~= "" then
		row.descIcon:Show()
	else
		row.descIcon:Hide()
	end

	-- Link icon
	if run.link and run.link ~= "" then
		row.linkIcon:Show()
	else
		row.linkIcon:Hide()
	end
end

-- ── MVPs side panel ──────────────────────────────────────

local MVP_BUBBLE_HEIGHT = 28
local MVP_BUBBLE_SPACING = 3

function MPT:CreateMvpsSidePanel(parent, padding, tableCard)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetWidth(MVP_PANEL_WIDTH)
	-- Flush with table card
	panel:SetPoint("TOPLEFT", tableCard, "TOPRIGHT", 0, 0)
	panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

	-- Panel background
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.panelBg[1], C.panelBg[2], C.panelBg[3], 1)
	bg:SetDrawLayer("BACKGROUND", 2)

	-- Header bar (matches table column header style)
	local header = CreateFrame("Frame", nil, panel)
	header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	header:SetHeight(HEADER_HEIGHT)
	local headerBg = header:CreateTexture(nil, "BACKGROUND", nil, 3)
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(C.headerBg[1], C.headerBg[2], C.headerBg[3], 1)

	local title = header:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
	title:SetPoint("LEFT", header, "LEFT", 10, 0)
	title:SetText("MVPs")
	panel.title = title

	-- Import button (view mode only)
	local importBtn = self:CreateModernButton(panel, 50, 18, "Import")
	importBtn:SetPoint("RIGHT", header, "RIGHT", -6, 0)
	importBtn:SetScript("OnClick", function()
		MPT:ImportViewedMvps()
	end)
	importBtn:Hide()
	panel.importBtn = importBtn
	self.mvpImportBtn = importBtn

	local SCROLL_BAR_WIDTH = 4

	local scrollParent = CreateFrame("Frame", nil, panel)
	scrollParent:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(HEADER_HEIGHT + 4))
	scrollParent:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6 - SCROLL_BAR_WIDTH - 2, 6)
	scrollParent:SetClipsChildren(true)
	panel.scrollParent = scrollParent
	panel.bubbles = {}
	panel.mvpScrollOffset = 0

	-- Scrollbar track
	local track = CreateFrame("Frame", nil, panel)
	track:SetWidth(SCROLL_BAR_WIDTH)
	track:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -(HEADER_HEIGHT + 4))
	track:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 6)
	local trackBg = track:CreateTexture(nil, "BACKGROUND")
	trackBg:SetAllPoints()
	trackBg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)
	panel.scrollTrack = track

	-- Scrollbar thumb
	local thumb = CreateFrame("Frame", nil, track)
	thumb:SetWidth(SCROLL_BAR_WIDTH)
	thumb:SetPoint("TOP", track, "TOP", 0, 0)
	thumb:SetHeight(30)
	local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
	thumbTex:SetAllPoints()
	thumbTex:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
	panel.scrollThumb = thumb
	thumb:Hide()

	-- Mouse wheel scrolling
	scrollParent:EnableMouseWheel(true)
	scrollParent:SetScript("OnMouseWheel", function(_, delta)
		local step = (MVP_BUBBLE_HEIGHT + MVP_BUBBLE_SPACING) * 2
		panel.mvpScrollOffset = panel.mvpScrollOffset - (delta * step)
		MPT:RefreshMvpBubblePositions()
	end)

	self.mvpsSidePanel = panel
end

function MPT:CreateMvpBubble(parent)
	local bubble = CreateFrame("Button", nil, parent)
	bubble:SetHeight(MVP_BUBBLE_HEIGHT)

	-- Background (set per-row for alternating)
	local bg = bubble:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.rowBase[1], C.rowBase[2], C.rowBase[3], 1)
	bubble.bg = bg

	-- Class-colored left accent (3px)
	local leftBar = bubble:CreateTexture(nil, "ARTWORK")
	leftBar:SetWidth(3)
	leftBar:SetPoint("TOPLEFT", bubble, "TOPLEFT", 0, 0)
	leftBar:SetPoint("BOTTOMLEFT", bubble, "BOTTOMLEFT", 0, 0)
	leftBar:SetColorTexture(1, 1, 1, 1)
	bubble.leftBar = leftBar

	-- Name text
	local nameText = bubble:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	nameText:SetPoint("LEFT", bubble, "LEFT", 12, 0)
	nameText:SetPoint("RIGHT", bubble, "RIGHT", -38, 0)
	nameText:SetJustifyH("LEFT")
	bubble.nameText = nameText

	-- Note icon (yellow file icon)
	local noteIcon = bubble:CreateTexture(nil, "OVERLAY")
	noteIcon:SetSize(12, 12)
	noteIcon:SetPoint("RIGHT", bubble, "RIGHT", -22, 0)
	noteIcon:SetTexture("Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up")
	noteIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	noteIcon:Hide()
	bubble.noteIcon = noteIcon

	-- Remove X button
	local removeBtn = CreateFrame("Button", nil, bubble)
	removeBtn:SetSize(16, 16)
	removeBtn:SetPoint("RIGHT", bubble, "RIGHT", -2, 0)
	local xLabel = removeBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	xLabel:SetPoint("CENTER")
	xLabel:SetText("x")
	xLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	removeBtn:SetScript("OnEnter", function() xLabel:SetTextColor(1, 0.3, 0.3) end)
	removeBtn:SetScript("OnLeave", function() xLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3]) end)
	bubble.removeBtn = removeBtn

	-- Highlight on hover
	local hl = bubble:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 0.95, 0.8, 0.05)

	return bubble
end

function MPT:RefreshMvpsSidePanel()
	local panel = self.mvpsSidePanel
	if not panel then return end

	for _, bubble in ipairs(panel.bubbles) do
		bubble:Hide()
	end

	local isViewing = self:IsViewingRemote()
	local mvpSource = isViewing and (self.viewingData and self.viewingData.mvps or {}) or self.db.global.mvps
	local runSource = isViewing and (self.viewingData and self.viewingData.runs or {}) or (self.db.global.runs or {})

	if self.mvpImportBtn then
		if isViewing then self.mvpImportBtn:Show() else self.mvpImportBtn:Hide() end
	end

	-- Build a lookup of nameRealm -> class from all runs
	local classLookup = {}
	for _, run in ipairs(runSource) do
		for _, m in ipairs(run.members or {}) do
			local nr = m.name .. "-" .. (m.realm or "")
			if m.class and not classLookup[nr] then
				classLookup[nr] = m.class
			end
		end
	end

	panel.mvpScrollOffset = 0
	panel.mvpVisibleCount = 0

	local yOff = 0
	local idx = 0
	for nameRealm, data in pairs(mvpSource) do
		idx = idx + 1
		local bubble = panel.bubbles[idx]
		if not bubble then
			bubble = self:CreateMvpBubble(panel.scrollParent)
			panel.bubbles[idx] = bubble
		end

		bubble:ClearAllPoints()
		bubble:SetPoint("TOPLEFT", panel.scrollParent, "TOPLEFT", 0, -yOff)
		bubble:SetPoint("RIGHT", panel.scrollParent, "RIGHT", 0, 0)

		-- Alternating background
		if idx % 2 == 0 then
			bubble.bg:SetColorTexture(C.rowAlt[1], C.rowAlt[2], C.rowAlt[3], 1)
		else
			bubble.bg:SetColorTexture(C.rowBase[1], C.rowBase[2], C.rowBase[3], 1)
		end

		-- Resolve class: stored in MVP data, or look up from run history
		local class = data.class or classLookup[nameRealm]
		if class and not data.class then
			data.class = class  -- backfill for future
		end

		-- Set class color on left border and name text
		local r, g, b = self:GetClassColor(class)
		bubble.leftBar:SetColorTexture(r, g, b, 1)

		bubble.nameText:SetText(nameRealm)
		bubble.nameText:SetTextColor(r, g, b)

		-- Note icon
		local hasNote
		if isViewing then
			hasNote = data.note and data.note ~= ""
		else
			local note = self:GetMvpNote(nameRealm)
			hasNote = note and note ~= ""
		end
		if hasNote then
			bubble.noteIcon:Show()
		else
			bubble.noteIcon:Hide()
		end

		-- Tooltip with note on hover
		bubble:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if isViewing then
				local remoteNote = data.note
				if remoteNote and remoteNote ~= "" then
					GameTooltip:AddLine("Their Note", 0.5, 0.8, 1)
					GameTooltip:AddLine(remoteNote, 1, 1, 1, true)
					GameTooltip:AddLine(" ")
				end
			else
				local note = MPT:GetMvpNote(nameRealm)
				if note and note ~= "" then
					GameTooltip:AddLine("Note", 1, 0.82, 0)
					GameTooltip:AddLine(note, 1, 1, 1, true)
					GameTooltip:AddLine(" ")
				end
			end
			GameTooltip:AddLine("Left-click to scroll to run", 0.7, 0.7, 0.7)
			if not isViewing then
				GameTooltip:AddLine("Right-click to edit note", 0.7, 0.7, 0.7)
			end
			GameTooltip:Show()
		end)
		bubble:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Left-click → scroll to run, Right-click → edit note
		bubble:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		bubble:SetScript("OnClick", function(self, button)
			if button == "RightButton" and not isViewing then
				MPT:ShowNotePopup(nameRealm, self)
			else
				MPT:ScrollToPlayerRun(nameRealm)
			end
		end)

		if isViewing then
			bubble.removeBtn:Hide()
		else
			bubble.removeBtn:Show()
			bubble.removeBtn:SetScript("OnClick", function()
				MPT:RemoveMvp(nameRealm)
				MPT:OnMvpChanged()
			end)
		end

		bubble:Show()
		yOff = yOff + MVP_BUBBLE_HEIGHT + MVP_BUBBLE_SPACING
	end

	panel.mvpVisibleCount = idx
	panel.mvpContentHeight = yOff

	if idx == 0 then
		local bubble = panel.bubbles[1]
		if not bubble then
			bubble = self:CreateMvpBubble(panel.scrollParent)
			panel.bubbles[1] = bubble
		end
		bubble:ClearAllPoints()
		bubble:SetPoint("TOPLEFT", panel.scrollParent, "TOPLEFT", 0, 0)
		bubble:SetPoint("RIGHT", panel.scrollParent, "RIGHT", 0, 0)
		bubble.bg:SetColorTexture(C.headerBg[1], C.headerBg[2], C.headerBg[3], 1)
		bubble.leftBar:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
		bubble.nameText:SetText("No MVPs yet")
		bubble.nameText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		bubble.removeBtn:Hide()
		bubble.noteIcon:Hide()
		bubble:SetScript("OnClick", nil)
		bubble:Show()
	end

	self:RefreshMvpBubblePositions()
end

function MPT:RefreshMvpBubblePositions()
	local panel = self.mvpsSidePanel
	if not panel then return end

	local contentHeight = panel.mvpContentHeight or 0
	local visibleHeight = panel.scrollParent:GetHeight()
	local maxScroll = math.max(0, contentHeight - visibleHeight)

	-- Clamp scroll offset
	if panel.mvpScrollOffset < 0 then panel.mvpScrollOffset = 0 end
	if panel.mvpScrollOffset > maxScroll then panel.mvpScrollOffset = maxScroll end

	local offset = panel.mvpScrollOffset
	local count = panel.mvpVisibleCount or 0

	for i = 1, count do
		local bubble = panel.bubbles[i]
		if bubble then
			local naturalY = (i - 1) * (MVP_BUBBLE_HEIGHT + MVP_BUBBLE_SPACING)
			bubble:ClearAllPoints()
			bubble:SetPoint("TOPLEFT", panel.scrollParent, "TOPLEFT", 0, -(naturalY - offset))
			bubble:SetPoint("RIGHT", panel.scrollParent, "RIGHT", 0, 0)
		end
	end

	-- Update scrollbar thumb
	if maxScroll > 0 and count > 0 then
		local trackHeight = panel.scrollTrack:GetHeight()
		local thumbHeight = math.max(20, (visibleHeight / contentHeight) * trackHeight)
		local thumbOffset = (offset / maxScroll) * (trackHeight - thumbHeight)

		panel.scrollThumb:SetHeight(thumbHeight)
		panel.scrollThumb:ClearAllPoints()
		panel.scrollThumb:SetPoint("TOP", panel.scrollTrack, "TOP", 0, -thumbOffset)
		panel.scrollThumb:Show()
		panel.scrollTrack:Show()
	else
		panel.scrollThumb:Hide()
		panel.scrollTrack:Hide()
	end
end

-- ── Help panel (click-toggle) ───────────────────────────────────

function MPT:CreateHelpPanel()
	if self.helpPanel then return end

	local panel = CreateFrame("Frame", "MPTHelpPanel", self.mainFrame)
	panel:SetSize(320, 300)
	panel:SetPoint("TOPLEFT", self.helpBtn, "BOTTOMLEFT", -4, -4)
	panel:SetFrameStrata("DIALOG")

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local yOff = -12
	local function addHeader(text)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
		fs:SetText(text)
		yOff = yOff - 16
	end
	local function addLine(text)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
		fs:SetWidth(296)
		fs:SetJustifyH("LEFT")
		fs:SetText(text)
		fs:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		yOff = yOff - (fs:GetStringHeight() + 4)
	end
	local function addSpacer()
		yOff = yOff - 6
	end

	addHeader("Table")
	addLine("Click a row to expand per-player stats.")
	addLine("Click LINK or DESC cells to edit them.")
	addSpacer()
	addHeader("MVPs")
	addLine("Left-click a name in expanded stats to toggle MVP.")
	addLine("Right-click a name to add MVP with a note.")
	addLine("Your MVP list is always visible on the right.")
	addSpacer()
	addHeader("Star Colors (viewing another player)")
	addLine("|cFFFFD100Gold|r = Your MVP   |cFF4D80FFBlue|r = Their MVP   |cFF33FF33Green|r = Shared")
	addSpacer()
	addHeader("Sharing")
	addLine("Right-click a player portrait to view their M+ table.")
	addLine("Use Import in the MVP list to save their MVPs.")
	addSpacer()
	addHeader("Slash Commands")
	addLine("/mm — Toggle this window")
	addSpacer()
	local ver = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	ver:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	ver:SetText("v" .. (getMetadata and getMetadata("MythicMemories", "Version") or "?"))
	ver:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	yOff = yOff - 14

	-- Resize to fit content
	panel:SetHeight(math.abs(yOff) + 12)

	panel:Hide()
	self.helpPanel = panel
end

function MPT:ToggleHelpPanel()
	if not self.helpPanel then
		self:CreateHelpPanel()
	end
	if self.helpPanel:IsShown() then
		self.helpPanel:Hide()
	else
		self.helpPanel:Show()
	end
end

-- ── Options panel ────────────────────────────────────────────────

function MPT:CreateOptionsPanel()
	if self.optionsPanel then return end

	local panel = CreateFrame("Frame", "MPTOptionsPanel", self.mainFrame)
	panel:SetSize(220, 170)
	panel:SetPoint("TOPRIGHT", self.optionsBtn, "BOTTOMRIGHT", 0, -4)
	panel:SetFrameStrata("DIALOG")

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	-- Share checkbox
	local shareCheck = self:CreateModernCheckbox(panel, "Share Table")
	shareCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -14)
	shareCheck._onToggle = function(val)
		MPT.db.global.shareTable = val
	end
	panel.shareCheck = shareCheck

	-- Divider
	local div = panel:CreateTexture(nil, "ARTWORK")
	div:SetHeight(1)
	div:SetPoint("TOPLEFT", shareCheck, "BOTTOMLEFT", -2, -12)
	div:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
	div:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)

	-- Reset section header
	local resetHeader = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
	resetHeader:SetPoint("TOPLEFT", div, "BOTTOMLEFT", 2, -10)
	resetHeader:SetText("Reset")

	-- Reset checkboxes
	local resetRunsCheck = self:CreateModernCheckbox(panel, "Runs")
	resetRunsCheck:SetPoint("TOPLEFT", resetHeader, "BOTTOMLEFT", 0, -8)
	resetRunsCheck:SetChecked(true)
	panel.resetRunsCheck = resetRunsCheck

	local resetMvpsCheck = self:CreateModernCheckbox(panel, "MVPs")
	resetMvpsCheck:SetPoint("TOPLEFT", resetRunsCheck, "BOTTOMLEFT", 0, -6)
	resetMvpsCheck:SetChecked(true)
	panel.resetMvpsCheck = resetMvpsCheck

	-- Reset button
	local resetBtn = self:CreateModernButton(panel, 190, 24, "Reset Selected")
	resetBtn:SetPoint("TOPLEFT", resetMvpsCheck, "BOTTOMLEFT", -2, -10)
	resetBtn.label:SetTextColor(1, 0.4, 0.4)
	resetBtn:SetScript("OnClick", function()
		local runs = panel.resetRunsCheck:GetChecked()
		local mvps = panel.resetMvpsCheck:GetChecked()
		if runs or mvps then
			MPT:ShowResetConfirmDialog(runs, mvps)
		end
	end)
	resetBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(0.25, 0.10, 0.08, 1)
	end)
	resetBtn:SetScript("OnLeave", function(self)
		self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
	end)

	panel:Hide()
	self.optionsPanel = panel
end

function MPT:ToggleOptionsPanel()
	if not self.optionsPanel then
		self:CreateOptionsPanel()
	end

	if self.optionsPanel:IsShown() then
		self.optionsPanel:Hide()
	else
		self.optionsPanel.shareCheck:SetChecked(self.db.global.shareTable)
		self.optionsPanel:Show()
	end
end

-- ── Reset confirmation dialog ───────────────────────────────────

function MPT:ShowResetConfirmDialog(resetRuns, resetMvps)
	-- Build description of what will be deleted
	local parts = {}
	if resetRuns then parts[#parts + 1] = "runs" end
	if resetMvps then parts[#parts + 1] = "MVPs" end
	local what = table.concat(parts, " and ")

	if not self.resetDialog then
		local dialog = CreateFrame("Frame", "MPTResetDialog", UIParent)
		dialog:SetSize(300, 120)
		dialog:SetPoint("CENTER", UIParent, "CENTER")
		dialog:SetFrameStrata("FULLSCREEN_DIALOG")
		dialog:EnableMouse(true)

		local bg = dialog:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

		local text = dialog:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		text:SetPoint("TOP", dialog, "TOP", 0, -20)
		text:SetWidth(260)
		text:SetJustifyH("CENTER")
		dialog.text = text

		local yesBtn = self:CreateModernButton(dialog, 100, 26, "Yes, Delete")
		yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 16)
		yesBtn.label:SetTextColor(1, 0.4, 0.4)
		yesBtn:SetScript("OnEnter", function(self)
			self.bg:SetColorTexture(0.25, 0.10, 0.08, 1)
		end)
		yesBtn:SetScript("OnLeave", function(self)
			self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
		end)
		dialog.yesBtn = yesBtn

		local cancelBtn = self:CreateModernButton(dialog, 100, 26, "Cancel")
		cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 16)
		cancelBtn:SetScript("OnClick", function()
			dialog:Hide()
		end)

		self.resetDialog = dialog
	end

	local dialog = self.resetDialog
	dialog.text:SetText("Delete all " .. what .. "?\nThis cannot be undone.")
	dialog.yesBtn:SetScript("OnClick", function()
		MPT:ResetData(resetRuns, resetMvps)
		dialog:Hide()
		if MPT.optionsPanel then MPT.optionsPanel:Hide() end
	end)
	dialog:Show()
end

-- ── View mode UI updates ─────────────────────────────────────────

function MPT:UpdateViewModeUI()
	if not self.mainFrame then return end

	local isViewing = self:IsViewingRemote()

	if isViewing then
		local displayName = self.viewingPlayer or "Unknown"
		local shortName = displayName:match("^(.+)%-") or displayName
		self.mainTitle:SetText(shortName .. "'s M+ Table")
		self.backBtn:Show()
		if self.helpBtn then self.helpBtn:Hide() end
		if self.optionsBtn then self.optionsBtn:Hide() end
		if self.optionsPanel then self.optionsPanel:Hide() end
	else
		self.mainTitle:SetText("Mythic Memories")
		self.backBtn:Hide()
		if self.helpBtn then self.helpBtn:Show() end
		if self.optionsBtn then self.optionsBtn:Show() end
	end
end
