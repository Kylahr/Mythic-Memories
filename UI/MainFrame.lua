local _, MPT = ...

local ROW_HEIGHT = 32
local VISIBLE_ROWS = 15
local HEADER_HEIGHT = 28
local MVP_PANEL_WIDTH = 200

-- ── Sepia/grey palette (wider contrast range) ────────────────
local C = {
	bg         = { 0.12, 0.12, 0.09 },     -- main frame / dark shell
	titleBar   = { 0.30, 0.29, 0.23 },     -- title strip (kept for column headers)
	filterBar  = { 0.16, 0.16, 0.13 },     -- filter bar strip
	panelBg    = { 0.20, 0.19, 0.16 },     -- elevated card/panel bg
	contentBg  = { 0.18, 0.17, 0.14 },     -- lighter content area inset
	headerBg   = { 0.30, 0.29, 0.23 },     -- column header bar
	rowBase    = { 0.18, 0.18, 0.15 },     -- odd rows
	rowAlt     = { 0.22, 0.21, 0.17 },     -- even rows
	inputBg    = { 0.30, 0.29, 0.24 },     -- interactive surface, clearly visible on cards
	btnBg      = { 0.25, 0.24, 0.20 },     -- button background
	btnHover   = { 0.33, 0.31, 0.25 },     -- button hover
	accent     = { 1, 0.82, 0 },           -- gold accent
	accentDim  = { 0.7, 0.57, 0 },         -- dimmed gold
	textPrimary= { 0.92, 0.90, 0.84 },     -- warm cream
	textMuted  = { 0.50, 0.48, 0.42 },     -- muted warm grey
	textLabel  = { 0.65, 0.63, 0.56 },     -- label text
	divider    = { 0.28, 0.26, 0.21 },     -- dividers
	highlight  = { 1, 0.95, 0.8, 0.06 },   -- row hover
	popupBg    = { 0.20, 0.19, 0.16 },     -- popup/dialog backgrounds (matches panelBg)
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
function MPT:CreateSearchInput(parent, name, width, showClearX)
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

	if showClearX then
		local clearBtn = CreateFrame("Button", nil, container)
		clearBtn:SetSize(14, 14)
		clearBtn:SetPoint("RIGHT", container, "RIGHT", -4, 0)
		local clearLabel = clearBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
		clearLabel:SetPoint("CENTER", 0, 0)
		clearLabel:SetText("x")
		clearLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		clearBtn:SetScript("OnEnter", function()
			clearLabel:SetTextColor(1, 0.3, 0.3)
		end)
		clearBtn:SetScript("OnLeave", function()
			clearLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		end)
		clearBtn:SetScript("OnClick", function()
			editBox:SetText("")
			editBox:ClearFocus()
			clearBtn:Hide()
			MPT:ApplyFilters()
		end)
		clearBtn:Hide()
		editBox:SetPoint("BOTTOMRIGHT", -18, 2)

		local function updateClearBtn()
			if editBox:GetText() ~= "" then
				clearBtn:Show()
			else
				clearBtn:Hide()
			end
		end
		editBox:SetScript("OnTextChanged", updateClearBtn)
	end

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

-- ── Custom dropdown widget ────────────────────────────────────
function MPT:CreateDropdown(parent, width, defaultText)
	local dropdown = CreateFrame("Frame", nil, parent)
	dropdown:SetSize(width, 22)

	local bg = dropdown:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)

	local selectedText = dropdown:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	selectedText:SetPoint("LEFT", 6, 0)
	selectedText:SetPoint("RIGHT", -18, 0)
	selectedText:SetJustifyH("LEFT")
	selectedText:SetText(defaultText)
	selectedText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	dropdown.selectedText = selectedText

	local arrow = dropdown:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	arrow:SetPoint("RIGHT", -4, 0)
	arrow:SetText("v")
	arrow:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

	dropdown._value = ""
	dropdown._defaultText = defaultText
	dropdown._listFrame = nil

	dropdown.SetValue = function(self, value, displayText)
		self._value = value
		if value == "" then
			self.selectedText:SetText(self._defaultText)
			self.selectedText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		else
			self.selectedText:SetText(displayText or value)
			self.selectedText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
		if self._listFrame then self._listFrame:Hide() end
	end
	dropdown.GetValue = function(self) return self._value end

	dropdown.SetItems = function(self, items)
		self._items = items
	end

	local btn = CreateFrame("Button", nil, dropdown)
	btn:SetAllPoints()
	btn:SetScript("OnEnter", function()
		bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
	end)
	btn:SetScript("OnLeave", function()
		bg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)
	end)
	btn:SetScript("OnClick", function()
		if dropdown._listFrame and dropdown._listFrame:IsShown() then
			dropdown._listFrame:Hide()
			return
		end
		MPT:ShowDropdownList(dropdown)
	end)

	return dropdown
end

function MPT:ShowDropdownList(dropdown)
	-- Hide any other open dropdown lists
	if self._activeDropdown and self._activeDropdown ~= dropdown and self._activeDropdown._listFrame then
		self._activeDropdown._listFrame:Hide()
	end
	self._activeDropdown = dropdown

	local items = dropdown._items or {}
	local ITEM_HEIGHT = 20
	local MAX_VISIBLE = 10
	local listWidth = dropdown:GetWidth()
	local visibleCount = math.min(#items + 1, MAX_VISIBLE)  -- +1 for "All" option
	local listHeight = visibleCount * ITEM_HEIGHT + 4

	if not dropdown._listFrame then
		local list = CreateFrame("Frame", nil, dropdown)
		list:SetFrameStrata("TOOLTIP")
		list:SetWidth(listWidth)
		list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
		list:SetClipsChildren(true)

		local listBg = list:CreateTexture(nil, "BACKGROUND")
		listBg:SetAllPoints()
		listBg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)

		list.scrollOffset = 0
		list.buttons = {}
		list:EnableMouseWheel(true)
		list:SetScript("OnMouseWheel", function(_, delta)
			local totalItems = #(dropdown._items or {}) + 1
			local maxOffset = math.max(0, totalItems - MAX_VISIBLE)
			list.scrollOffset = math.max(0, math.min(maxOffset, list.scrollOffset - delta))
			MPT:RefreshDropdownList(dropdown)
		end)

		dropdown._listFrame = list
	end

	local list = dropdown._listFrame
	list:SetHeight(listHeight)
	list.scrollOffset = 0

	-- Create enough buttons
	local totalSlots = visibleCount
	for i = #list.buttons + 1, totalSlots do
		local itemBtn = CreateFrame("Button", nil, list)
		itemBtn:SetHeight(ITEM_HEIGHT)
		itemBtn:SetPoint("TOPLEFT", list, "TOPLEFT", 2, -(i - 1) * ITEM_HEIGHT - 2)
		itemBtn:SetPoint("TOPRIGHT", list, "TOPRIGHT", -2, -(i - 1) * ITEM_HEIGHT - 2)

		local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
		itemBg:SetAllPoints()
		itemBg:SetColorTexture(0, 0, 0, 0)
		itemBtn._bg = itemBg

		local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		itemText:SetPoint("LEFT", 6, 0)
		itemText:SetPoint("RIGHT", -6, 0)
		itemText:SetJustifyH("LEFT")
		itemBtn._text = itemText

		itemBtn:SetScript("OnEnter", function(self)
			self._bg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.15)
		end)
		itemBtn:SetScript("OnLeave", function(self)
			self._bg:SetColorTexture(0, 0, 0, 0)
		end)

		list.buttons[i] = itemBtn
	end

	self:RefreshDropdownList(dropdown)
	list:Show()
end

function MPT:RefreshDropdownList(dropdown)
	local list = dropdown._listFrame
	if not list then return end
	local items = dropdown._items or {}
	local offset = list.scrollOffset or 0
	local MAX_VISIBLE = 10
	local ITEM_HEIGHT = 20

	-- Build display list: "All" + items
	local allItems = { { value = "", display = dropdown._defaultText } }
	for _, item in ipairs(items) do
		if type(item) == "table" then
			allItems[#allItems + 1] = item
		else
			allItems[#allItems + 1] = { value = item, display = item }
		end
	end

	local visibleCount = math.min(#allItems, MAX_VISIBLE)
	list:SetHeight(visibleCount * ITEM_HEIGHT + 4)

	for i, btn in ipairs(list.buttons) do
		local idx = i + offset
		if idx <= #allItems then
			local item = allItems[idx]
			btn._text:SetText(item.display)
			if item.value == dropdown._value then
				btn._text:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
			else
				btn._text:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
			end
			btn:SetScript("OnClick", function()
				dropdown:SetValue(item.value, item.display)
			end)
			btn:Show()
		else
			btn:Hide()
		end
	end
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
	local totalWidth = MVP_PANEL_WIDTH + 2 + tableAreaWidth  -- MVP left, 2px gap, table (scrollbar flush right)
	-- 26 (title bar) + 30 (filter bar gap) + HEADER_HEIGHT + rows = exact fit
	local totalHeight = 26 + 30 + HEADER_HEIGHT + (ROW_HEIGHT * VISIBLE_ROWS)

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
	titleBarBg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)
	titleBarBg:SetDrawLayer("BACKGROUND", 2)

	local title = frame:CreateFontString(nil, "OVERLAY", "MPTFont_Title")
	title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
	title:SetText("Mythic Memories")
	self.mainTitle = title

	local closeBtn = self:CreateCloseButton(frame)
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -4)

	-- Back button (visible only in view mode)
	local backBtn = self:CreateModernButton(frame, 60, 20, "< Back")
	backBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -4)
	backBtn:SetScript("OnClick", function()
		MPT:ExitViewMode()
	end)
	backBtn:Hide()
	self.backBtn = backBtn

	-- Help button (top-right, next to close) — click to toggle help panel
	local helpBtn = CreateFrame("Button", nil, frame)
	helpBtn:SetSize(20, 20)
	helpBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

	local helpLabel = helpBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	helpLabel:SetPoint("CENTER", 0, 0)
	helpLabel:SetText("?")
	helpLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

	helpBtn:SetScript("OnEnter", function()
		helpLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	helpBtn:SetScript("OnLeave", function()
		if not (MPT.helpPanel and MPT.helpPanel:IsShown()) then
			helpLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		end
	end)
	helpBtn:SetScript("OnClick", function()
		MPT:ToggleHelpPanel()
	end)
	self.helpBtn = helpBtn
	self.helpLabel = helpLabel

	-- Options (cog) button — top-right, next to help
	local optionsBtn = CreateFrame("Button", nil, frame)
	optionsBtn:SetSize(20, 20)
	optionsBtn:SetPoint("RIGHT", helpBtn, "LEFT", -4, 0)

	local cogIcon = optionsBtn:CreateTexture(nil, "ARTWORK")
	cogIcon:SetSize(14, 14)
	cogIcon:SetPoint("CENTER")
	cogIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
	cogIcon:SetDesaturated(true)
	cogIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	optionsBtn.cogIcon = cogIcon

	optionsBtn:SetScript("OnEnter", function()
		cogIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	optionsBtn:SetScript("OnLeave", function()
		cogIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	optionsBtn:SetScript("OnClick", function()
		MPT:ToggleOptionsPanel()
	end)
	self.optionsBtn = optionsBtn

	frame:SetScript("OnHide", function()
		MPT:HideAllPopups()
		MPT.expandedRunId = nil
		-- Reset filters on close
		MPT:ResetFilterPopup()
		MPT.advancedFilters = nil
		-- Clear view mode when closing
		if MPT.viewingPlayer then
			MPT.viewingPlayer = nil
			MPT.viewingData = nil
			MPT:UpdateViewModeUI()
		end
	end)

	-- ── Content card (lighter inset area for filter + table) ────
	local tableCard = CreateFrame("Frame", nil, frame)
	tableCard:SetPoint("TOPLEFT", frame, "TOPLEFT", MVP_PANEL_WIDTH + 2, -26)
	tableCard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	local tcBg = tableCard:CreateTexture(nil, "BACKGROUND")
	tcBg:SetAllPoints()
	tcBg:SetColorTexture(C.contentBg[1], C.contentBg[2], C.contentBg[3], 1)
	tcBg:SetDrawLayer("BACKGROUND", 3)
	self.tableCard = tableCard

	-- Filter bar inside the content card
	self:CreateFilterBar(tableCard)

	self:CreateColumnHeaders(tableCard)
	self:CreateScrollFrame(tableCard, tableWidth)

	-- ── MVP card (elevated panel) ──────────────────────────────
	self:CreateMvpsSidePanel(frame, PADDING, tableCard)

	frame:Hide()
	self.mainFrame = frame
end

function MPT:CreateFilterBar(parent)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
	bar:SetHeight(28)
	-- Filter bar background (slightly different hue from title and table)
	local barBg = bar:CreateTexture(nil, "BACKGROUND")
	barBg:SetAllPoints()
	barBg:SetColorTexture(C.contentBg[1], C.contentBg[2], C.contentBg[3], 1)
	barBg:SetDrawLayer("BACKGROUND", 2)

	local playerLabel = bar:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	playerLabel:SetPoint("LEFT", bar, "LEFT", 10, 0)
	playerLabel:SetText("Player")

	local playerInput = self:CreateSearchInput(bar, "MPTFilterPlayer", 85, true)
	playerInput:SetPoint("LEFT", playerLabel, "RIGHT", 6, 0)
	local playerBox = playerInput.editBox
	playerBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		MPT:ApplyFilters()
	end)

	local realmLabel = bar:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	realmLabel:SetPoint("LEFT", playerInput, "RIGHT", 12, 0)
	realmLabel:SetText("Realm")

	local realmInput = self:CreateSearchInput(bar, "MPTFilterRealm", 85, true)
	realmInput:SetPoint("LEFT", realmLabel, "RIGHT", 6, 0)
	local realmBox = realmInput.editBox
	realmBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		MPT:ApplyFilters()
	end)

	local searchBtn = CreateFrame("Button", nil, bar)
	searchBtn:SetSize(20, 20)
	searchBtn:SetPoint("LEFT", realmInput, "RIGHT", 8, 0)
	local searchIcon = searchBtn:CreateTexture(nil, "ARTWORK")
	searchIcon:SetSize(14, 14)
	searchIcon:SetPoint("CENTER")
	searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
	searchIcon:SetDesaturated(true)
	searchIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	searchBtn:SetScript("OnEnter", function()
		searchIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	searchBtn:SetScript("OnLeave", function()
		searchIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	searchBtn:SetScript("OnClick", function()
		MPT:ApplyFilters()
	end)

	-- Favourites toggle star (flat pictogram, no border/shadow)
	local favBtn = CreateFrame("Button", nil, bar)
	favBtn:SetSize(24, 24)
	favBtn:SetPoint("LEFT", searchBtn, "RIGHT", 8, 0)
	local favIcon = favBtn:CreateTexture(nil, "ARTWORK")
	favIcon:SetSize(20, 20)
	favIcon:SetPoint("CENTER")
	favIcon:SetAtlas("PetJournal-FavoritesIcon")
	favIcon:SetDesaturated(true)
	favIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	self.favToggleIcon = favIcon
	favBtn:SetScript("OnEnter", function()
		if not MPT.showFavouritesOnly then
			favIcon:SetDesaturated(false)
			favIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
		end
	end)
	favBtn:SetScript("OnLeave", function()
		if not MPT.showFavouritesOnly then
			favIcon:SetDesaturated(true)
			favIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		end
	end)
	favBtn:SetScript("OnClick", function()
		MPT:ToggleFavouritesFilter()
	end)

	local filterBtn = self:CreateModernButton(bar, 55, 20, "Filter")
	filterBtn:SetPoint("LEFT", favBtn, "RIGHT", 8, 0)
	filterBtn:SetScript("OnClick", function()
		MPT:ToggleFilterPopup()
	end)
	filterBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	filterBtn:SetScript("OnLeave", function(self)
		if not (MPT.filterPopup and MPT.filterPopup:IsShown()) then
			self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			self.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
	end)
	self.filterBtn = filterBtn

	self.filterBar = bar
	self.filterPlayerBox = playerBox
	self.filterRealmBox = realmBox
end

function MPT:CreateColumnHeaders(parent)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -30)
	header:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
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
	scrollParent:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -30 - HEADER_HEIGHT)
	scrollParent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	scrollParent:SetClipsChildren(true)
	-- Fill empty space below rows with the base row color so no contentBg strip shows
	local scrollBg = scrollParent:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetAllPoints()
	scrollBg:SetColorTexture(C.rowBase[1], C.rowBase[2], C.rowBase[3], 1)

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

	-- Custom thin scrollbar track — parented to tableCard so it spans header + rows flush right
	local track = CreateFrame("Frame", nil, parent)
	track:SetWidth(6)
	track:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
	track:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	local trackBg = track:CreateTexture(nil, "BACKGROUND")
	trackBg:SetAllPoints()
	trackBg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)

	-- Thumb guide — thumb travels from column header top to bottom (not into filter bar)
	local thumbGuide = CreateFrame("Frame", nil, track)
	thumbGuide:SetWidth(6)
	thumbGuide:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -29)
	thumbGuide:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 0, 0)

	-- Thumb
	local thumb = CreateFrame("Frame", nil, thumbGuide)
	thumb:SetWidth(6)
	thumb:SetHeight(40)
	thumb:SetPoint("TOP", thumbGuide, "TOP")
	thumb:EnableMouse(true)
	thumb:SetMovable(true)
	local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
	thumbTex:SetAllPoints()
	thumbTex:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
	self.mainScrollTrack = track
	self.mainScrollThumbGuide = thumbGuide
	self.mainScrollThumb = thumb

	-- Mouse wheel scrolling on the scroll parent
	scrollParent:EnableMouseWheel(true)
	scrollParent:SetScript("OnMouseWheel", function(_, delta)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar then
			local cur = scrollBar:GetValue()
			local newVal = cur - (delta * (ROW_HEIGHT / 2))
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
		local scale = thumbGuide:GetEffectiveScale()
		cursorY = cursorY / scale
		local top = thumbGuide:GetTop()
		local trackH = thumbGuide:GetHeight()
		local thumbH = self:GetHeight()
		local scrollRatio = math.max(0, math.min(1, (top - cursorY - thumbH / 2) / (trackH - thumbH)))
		local runs = MPT:GetFilteredRuns()
		local maxOffset = math.max(0, MPT:GetTotalVirtualRows(runs) - VISIBLE_ROWS)
		local newOffset = math.floor(scrollRatio * maxOffset + 0.5)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar and scrollBar.SetValue then
			scrollBar:SetValue(newOffset * ROW_HEIGHT)
		end
	end)

	self.rows = {}
	-- Create one extra row for the expanded row that scrolls off the top
	for i = 1, VISIBLE_ROWS + 1 do
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

	-- Favourite accent bar (thin gold left edge)
	local favBar = row:CreateTexture(nil, "ARTWORK")
	favBar:SetWidth(3)
	favBar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	favBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	favBar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.8)
	favBar:Hide()
	row.favBar = favBar

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
	mvpStar:SetSize(16, 16)
	mvpStar:SetPoint("CENTER", row, "LEFT", mvpOff + mvpW / 2, 0)
	mvpStar:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
	mvpStar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
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

	-- Underline sweep (hidden by default, used for scroll-to highlight)
	local sweepLine = row:CreateTexture(nil, "ARTWORK", nil, 4)
	sweepLine:SetHeight(2)
	sweepLine:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	sweepLine:SetWidth(0)
	sweepLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
	sweepLine:Hide()
	row.shimmerTex = sweepLine

	-- Mouse wheel passthrough to scroll the table
	row:EnableMouseWheel(true)
	row:SetScript("OnMouseWheel", function(_, delta)
		local scrollBar = _G["MPTScrollFrameScrollBar"]
		if scrollBar then
			local cur = scrollBar:GetValue()
			scrollBar:SetValue(cur - (delta * (ROW_HEIGHT / 2)))
		end
	end)

	-- Row click: left = expand/collapse, right = context menu
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetScript("OnClick", function(self, button)
		if not row.runData then return end
		if button == "RightButton" then
			MPT:ShowRowContextMenu(row)
		else
			MPT:ToggleRowExpansion(row)
		end
	end)

	return row
end

function MPT:ApplyFilters()
	self.currentFilters = {
		player = self.filterPlayerBox and self.filterPlayerBox:GetText() or "",
		realm = self.filterRealmBox and self.filterRealmBox:GetText() or "",
		favouritesOnly = self.showFavouritesOnly or false,
	}
	-- Merge advanced filters from filter popup
	if self.advancedFilters then
		for k, v in pairs(self.advancedFilters) do
			self.currentFilters[k] = v
		end
	end
	self:RefreshTable()
end

function MPT:GetFilteredRuns()
	return self:GetRuns(self.currentFilters)
end

function MPT:UpdateMainScrollThumb()
	local thumb = self.mainScrollThumb
	local guide = self.mainScrollThumbGuide
	if not thumb or not guide then return end

	local runs = self:GetFilteredRuns()
	local totalRows = self:GetTotalVirtualRows(runs)
	if totalRows <= VISIBLE_ROWS then
		thumb:Hide()
		return
	end

	thumb:Show()
	local guideH = guide:GetHeight()
	local ratio = VISIBLE_ROWS / totalRows
	local thumbH = math.max(20, guideH * ratio)
	thumb:SetHeight(thumbH)

	local offset = FauxScrollFrame_GetOffset(self.scrollFrame)
	local maxOffset = totalRows - VISIBLE_ROWS
	local scrollRatio = (maxOffset > 0) and (offset / maxOffset) or 0
	thumb:ClearAllPoints()
	thumb:SetPoint("TOP", guide, "TOP", 0, -scrollRatio * (guideH - thumbH))
end

function MPT:GetExpandedDetailHeight(runs)
	if not self.expandedRunId then return 0 end
	for _, run in ipairs(runs) do
		if run.id == self.expandedRunId then
			local members = run.members or {}
			-- Mirror RowDetail.lua constants: DETAIL_PADDING=10, DETAIL_HEADER_HEIGHT=26,
			-- DETAIL_GAP=3, DETAIL_ROW_HEIGHT=28, ACTION_BAR_HEIGHT=32
			return 10 + 26 + 3 + (#members * (28 + 3)) + 1 + 32 + 10
		end
	end
	return 0
end

function MPT:GetTotalVirtualRows(runs)
	local total = #runs
	-- Always add bottom padding so there's room to view tree details
	-- on any row, even the last one
	local maxMembers = 5  -- typical M+ group size
	local defaultDetailHeight = 10 + 26 + 3 + (maxMembers * (28 + 3)) + 1 + 32 + 10
	local extraRows = math.ceil(defaultDetailHeight / ROW_HEIGHT)
	-- If a row is actually expanded, use its real height if larger
	local detailHeight = self:GetExpandedDetailHeight(runs)
	if detailHeight > 0 then
		local expandedExtra = math.ceil(detailHeight / ROW_HEIGHT)
		if expandedExtra > extraRows then
			extraRows = expandedExtra
		end
	end
	return total + extraRows
end

function MPT:RefreshTable()
	if not self.scrollFrame then return end

	local runs = self:GetFilteredRuns()
	local offset = FauxScrollFrame_GetOffset(self.scrollFrame)

	local totalVirtualRows = self:GetTotalVirtualRows(runs)
	FauxScrollFrame_Update(self.scrollFrame, totalVirtualRows, VISIBLE_ROWS, ROW_HEIGHT)
	self:UpdateMainScrollThumb()

	local yOffset = 0
	local maxY = VISIBLE_ROWS * ROW_HEIGHT
	-- When the expanded row scrolls above the visible range, keep rendering it
	-- above the clip boundary so its detail frame scrolls out gradually.
	local peekRow = self.rows[VISIBLE_ROWS + 1]
	local peekUsed = false
	if self.expandedRunId and offset > 0 then
		local expandedIdx = nil
		for idx, run in ipairs(runs) do
			if run.id == self.expandedRunId then
				expandedIdx = idx
				break
			end
		end
		if expandedIdx and expandedIdx <= offset then
			local detailHeight = self:GetExpandedDetailHeight(runs)
			-- Row is (offset - expandedIdx + 1) rows above the visible top
			local rowsAbove = offset - expandedIdx + 1
			-- The detail starts ROW_HEIGHT below the row's top, so its top
			-- relative to scrollParent top is: -(rowsAbove * ROW_HEIGHT) + ROW_HEIGHT = -((rowsAbove - 1) * ROW_HEIGHT)
			-- The visible portion of detail = detailHeight - (rowsAbove - 1) * ROW_HEIGHT
			local detailVisible = detailHeight - (rowsAbove - 1) * ROW_HEIGHT
			if detailVisible > 0 then
				peekUsed = true
				peekRow.runData = runs[expandedIdx]
				-- Position row above the visible area; clipping hides it
				local rowTop = rowsAbove * ROW_HEIGHT
				peekRow:ClearAllPoints()
				peekRow:SetPoint("TOPLEFT", self.scrollParent, "TOPLEFT", 0, rowTop)
				peekRow:SetPoint("RIGHT", self.scrollParent, "RIGHT", -10, 0)
				peekRow:Show()
				self:ExpandRow(peekRow)
				-- Detail frame uses default anchoring (BOTTOMLEFT of row),
				-- so it will be partially visible through the clip region
				yOffset = detailVisible
			end
		end
	end
	if not peekUsed then
		peekRow.runData = nil
		peekRow:Hide()
		if peekRow.detailFrame then peekRow.detailFrame:Hide() end
	end

	for i = 1, VISIBLE_ROWS do
		local row = self.rows[i]
		local dataIdx = offset + i

		if dataIdx <= #runs and yOffset < maxY then
			local run = runs[dataIdx]
			row.runData = run

			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", self.scrollParent, "TOPLEFT", 0, -yOffset)
			row:SetPoint("RIGHT", self.scrollParent, "RIGHT", -6, 0)

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

	local rowWidth = row:GetWidth()
	if rowWidth <= 0 then rowWidth = 800 end

	tex:SetWidth(0)
	tex:SetAlpha(1)
	tex:Show()

	-- Phase 1: sweep across (0.4s)
	local sweepDuration = 0.4
	local sweepSteps = 20
	local sweepInterval = sweepDuration / sweepSteps
	for i = 1, sweepSteps do
		C_Timer.After(i * sweepInterval, function()
			local progress = i / sweepSteps
			tex:SetWidth(rowWidth * progress)
		end)
	end

	-- Phase 2: hold briefly then fade out (0.8s)
	local fadeStart = sweepDuration + 0.3
	local fadeDuration = 0.8
	local fadeSteps = 16
	local fadeInterval = fadeDuration / fadeSteps
	for i = 1, fadeSteps do
		C_Timer.After(fadeStart + i * fadeInterval, function()
			local alpha = 1 - (i / fadeSteps)
			tex:SetAlpha(alpha)
			if i == fadeSteps then
				tex:Hide()
				tex:SetWidth(0)
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

	-- Role column — same as other text
	row.cells[7]:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])

	-- Level column — green
	row.cells[3]:SetTextColor(0.2, 0.8, 0.2)

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

	-- Favourite accent bar
	if row.favBar then
		if self:IsFavourite(run.id) then
			row.favBar:Show()
		else
			row.favBar:Hide()
		end
	end
end

-- ── MVPs side panel ──────────────────────────────────────

local MVP_BUBBLE_HEIGHT = 28
local MVP_BUBBLE_SPACING = 3

function MPT:CreateMvpsSidePanel(parent, padding, tableCard)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetWidth(MVP_PANEL_WIDTH)
	-- Left side, part of dark shell
	panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -4)
	panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)

	-- Panel background (matches dark shell)
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)
	bg:SetDrawLayer("BACKGROUND", 2)

	-- Header bar (blends with dark shell)
	local SCROLL_BAR_WIDTH = 4
	local header = CreateFrame("Frame", nil, panel)
	header:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -4)
	header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6 - SCROLL_BAR_WIDTH - 2, -4)
	header:SetHeight(HEADER_HEIGHT)
	local headerBg = header:CreateTexture(nil, "BACKGROUND", nil, 3)
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)

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

	local scrollParent = CreateFrame("Frame", nil, panel)
	scrollParent:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(HEADER_HEIGHT + 8))
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
	trackBg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 1)
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
				MPT:ShowNotePopup(nameRealm, self, class)
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

	local function addIconLine(texture, r, g, b, text, desat)
		local icon = panel:CreateTexture(nil, "OVERLAY")
		icon:SetSize(14, 14)
		icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff - 1)
		icon:SetTexture(texture)
		if desat then icon:SetDesaturated(true) end
		icon:SetVertexColor(r, g, b)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 30, yOff)
		fs:SetWidth(278)
		fs:SetJustifyH("LEFT")
		fs:SetText(text)
		fs:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		yOff = yOff - (fs:GetStringHeight() + 4)
	end

	addHeader("Table")
	addLine("Left-click a row to expand per-player stats.")
	addLine("Right-click a row to favourite/unfavourite it.")
	addLine("Click LINK or DESC cells to edit them.")
	addSpacer()
	addHeader("Favourites")
	addIconLine("Interface\\COMMON\\FavoritesIcon", C.accent[1], C.accent[2], C.accent[3], "Toggle favourites filter in the toolbar.")
	addLine("Favourited runs show a gold accent bar.")
	addSpacer()
	addHeader("Filters")
	addLine("Use Player/Realm search bars for quick filtering.")
	addLine("Click Filter for advanced options (dungeon, affix, bonus, role, level).")
	addSpacer()
	addHeader("MVPs")
	addLine("Left-click a name in the tree view to toggle MVP.")
	addLine("Right-click a name to add MVP with a note.")
	addLine("MVP list is always visible on the left.")
	addSpacer()
	addHeader("Icons")
	addIconLine("Interface\\GroupFrame\\UI-Group-AssistantIcon", 1, 0.82, 0, "Your MVP")
	addIconLine("Interface\\GroupFrame\\UI-Group-AssistantIcon", 0.3, 0.7, 1, "Their MVP (viewing shared table)", true)
	addIconLine("Interface\\GroupFrame\\UI-Group-AssistantIcon", 0.2, 1, 0.2, "Shared MVP (in both lists)", true)
	addSpacer()
	addHeader("Sharing")
	addLine("Right-click a player portrait to view their M+ table or add them as MVP.")
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
		if self.helpLabel then
			self.helpLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		end
	else
		self.helpPanel:Show()
		if self.helpLabel then
			self.helpLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		end
	end
end

-- ── Row context menu ────────────────────────────────────────────

function MPT:ShowRowContextMenu(row)
	if not row.runData then return end
	if self.rowContextMenu then self.rowContextMenu:Hide() end

	local runId = row.runData.id
	local menu = CreateFrame("Frame", nil, self.mainFrame)
	menu:SetSize(130, 48)
	menu:SetFrameStrata("TOOLTIP")

	local bg = menu:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local function createMenuBtn(yOffset, label, textColor, onClick)
		local btn = CreateFrame("Button", nil, menu)
		btn:SetHeight(22)
		btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, yOffset)
		btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, yOffset)
		local btnText = btn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		btnText:SetPoint("LEFT", 10, 0)
		btnText:SetText(label)
		btnText:SetTextColor(textColor[1], textColor[2], textColor[3])
		local btnBg = btn:CreateTexture(nil, "BACKGROUND")
		btnBg:SetAllPoints()
		btnBg:SetColorTexture(0, 0, 0, 0)
		btn:SetScript("OnEnter", function()
			btnBg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.15)
		end)
		btn:SetScript("OnLeave", function()
			btnBg:SetColorTexture(0, 0, 0, 0)
		end)
		btn:SetScript("OnClick", function()
			menu:Hide()
			onClick()
		end)
		return btn
	end

	local isFav = self:IsFavourite(runId)
	local favLabel = isFav and "Unfavourite" or "Favourite"
	createMenuBtn(-2, favLabel, C.textPrimary, function()
		MPT:ToggleFavourite(runId)
		MPT:RefreshTable()
	end)

	createMenuBtn(-24, "Delete Run", {1, 0.4, 0.4}, function()
		MPT:ShowDeleteRunConfirm(runId)
	end)

	-- Position at cursor
	local scale = UIParent:GetEffectiveScale()
	local x, y = GetCursorPosition()
	menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	menu:Show()

	self.rowContextMenu = menu

	-- Close on next click anywhere else
	menu:SetScript("OnUpdate", function(self)
		if not self:IsMouseOver() and IsMouseButtonDown("LeftButton") then
			self:Hide()
		end
	end)
end

function MPT:ShowDeleteRunConfirm(runId)
	self:HideAllPopups()

	if not self.deleteRunDialog then
		local dialog = CreateFrame("Frame", "MPTDeleteRunDialog", UIParent)
		dialog:SetSize(300, 100)
		dialog:SetPoint("CENTER", UIParent, "CENTER")
		dialog:SetFrameStrata("FULLSCREEN_DIALOG")
		dialog:EnableMouse(true)

		local bg = dialog:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

		local text = dialog:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		text:SetPoint("TOP", dialog, "TOP", 0, -18)
		text:SetWidth(270)
		text:SetJustifyH("CENTER")
		text:SetTextColor(0.92, 0.90, 0.84)
		dialog.text = text

		local yesBtn = self:CreateModernButton(dialog, 100, 26, "Yes, Delete")
		yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 14)
		yesBtn.label:SetTextColor(1, 0.4, 0.4)
		yesBtn:SetScript("OnEnter", function(self)
			self.bg:SetColorTexture(0.25, 0.10, 0.08, 1)
		end)
		yesBtn:SetScript("OnLeave", function(self)
			self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
		end)
		yesBtn:SetScript("OnClick", function()
			if dialog.runId then
				MPT:DeleteRun(dialog.runId)
				if MPT.expandedRunId == dialog.runId then
					MPT.expandedRunId = nil
				end
				MPT:RefreshTable()
			end
			dialog:Hide()
		end)

		local cancelBtn = self:CreateModernButton(dialog, 100, 26, "Cancel")
		cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 14)
		cancelBtn:SetScript("OnClick", function()
			dialog:Hide()
		end)

		dialog:Hide()
		self.deleteRunDialog = dialog
	end

	local run = self:GetRun(runId)
	local desc = run and run.dungeon or "this run"
	self.deleteRunDialog.runId = runId
	self.deleteRunDialog.text:SetText("|cFFFFD100Delete|r " .. desc .. "? This cannot be undone.")
	self.deleteRunDialog:Show()
end

-- ── Favourites toggle ───────────────────────────────────────────

function MPT:ToggleFavouritesFilter()
	self.showFavouritesOnly = not self.showFavouritesOnly
	if self.showFavouritesOnly then
		self.favToggleIcon:SetDesaturated(false)
		self.favToggleIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3])
	else
		self.favToggleIcon:SetDesaturated(true)
		self.favToggleIcon:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end
	self:ApplyFilters()
end

-- ── Filter popup ────────────────────────────────────────────────

function MPT:CreateFilterPopup()
	if self.filterPopup then return end

	local POPUP_WIDTH = 280
	local DROPDOWN_WIDTH = 170
	local panel = CreateFrame("Frame", "MPTFilterPopup", self.mainFrame)
	panel:SetWidth(POPUP_WIDTH)
	panel:SetPoint("TOPLEFT", self.filterBtn, "BOTTOMLEFT", 0, -4)
	panel:SetFrameStrata("DIALOG")

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local yOff = -12

	-- Helper: add a label + dropdown row
	local function addDropdownRow(labelText)
		local lbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
		lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
		lbl:SetText(labelText)
		lbl:SetWidth(70)
		lbl:SetJustifyH("LEFT")

		local dd = MPT:CreateDropdown(panel, DROPDOWN_WIDTH, "All")
		dd:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
		yOff = yOff - 28
		return dd
	end

	-- Player input
	local playerLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	playerLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	playerLbl:SetText("Player")
	playerLbl:SetWidth(70)
	playerLbl:SetJustifyH("LEFT")
	local playerInput = self:CreateSearchInput(panel, "MPTFilterPopupPlayer", DROPDOWN_WIDTH, true)
	playerInput:SetPoint("LEFT", playerLbl, "RIGHT", 8, 0)
	panel.playerBox = playerInput.editBox
	yOff = yOff - 28

	-- Realm input
	local realmLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	realmLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	realmLbl:SetText("Realm")
	realmLbl:SetWidth(70)
	realmLbl:SetJustifyH("LEFT")
	local realmInput = self:CreateSearchInput(panel, "MPTFilterPopupRealm", DROPDOWN_WIDTH, true)
	realmInput:SetPoint("LEFT", realmLbl, "RIGHT", 8, 0)
	panel.realmBox = realmInput.editBox
	yOff = yOff - 22

	-- Divider
	local div1 = panel:CreateTexture(nil, "ARTWORK")
	div1:SetHeight(1)
	div1:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	div1:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
	div1:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
	yOff = yOff - 12

	-- Dungeon dropdown
	panel.dungeonDD = addDropdownRow("Dungeon")

	-- Dungeon search (for old dungeons not in dropdown)
	local dungSearchLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	dungSearchLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 90, yOff + 4)
	dungSearchLbl:SetText("or search:")
	local dungSearchInput = self:CreateSearchInput(panel, "MPTFilterDungeonSearch", DROPDOWN_WIDTH - 60)
	dungSearchInput:SetPoint("LEFT", dungSearchLbl, "RIGHT", 4, 0)
	panel.dungeonSearchBox = dungSearchInput.editBox
	yOff = yOff - 26

	-- Level range
	local levelLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	levelLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	levelLbl:SetText("Level")
	levelLbl:SetWidth(70)
	levelLbl:SetJustifyH("LEFT")

	local minLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	minLbl:SetPoint("LEFT", levelLbl, "RIGHT", 8, 0)
	minLbl:SetText("Min")
	local minInput = self:CreateSearchInput(panel, "MPTFilterLevelMin", 40)
	minInput:SetPoint("LEFT", minLbl, "RIGHT", 4, 0)
	panel.levelMinBox = minInput.editBox
	minInput.editBox:SetNumeric(true)

	local maxLbl = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	maxLbl:SetPoint("LEFT", minInput, "RIGHT", 8, 0)
	maxLbl:SetText("Max")
	local maxInput = self:CreateSearchInput(panel, "MPTFilterLevelMax", 40)
	maxInput:SetPoint("LEFT", maxLbl, "RIGHT", 4, 0)
	panel.levelMaxBox = maxInput.editBox
	maxInput.editBox:SetNumeric(true)
	yOff = yOff - 28

	-- Affix dropdown
	panel.affixDD = addDropdownRow("Affix")

	-- Bonus dropdown
	panel.bonusDD = addDropdownRow("Bonus")
	panel.bonusDD:SetItems({
		{ value = "3", display = "+3" },
		{ value = "2", display = "+2" },
		{ value = "1", display = "+1" },
		{ value = "depleted", display = "Depleted" },
	})

	-- Role dropdown
	panel.roleDD = addDropdownRow("Role")
	panel.roleDD:SetItems({
		{ value = "TANK", display = "Tank" },
		{ value = "HEALER", display = "Healer" },
		{ value = "DAMAGER", display = "DPS" },
	})

	-- Divider
	local div2 = panel:CreateTexture(nil, "ARTWORK")
	div2:SetHeight(1)
	div2:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	div2:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
	div2:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)
	yOff = yOff - 10

	-- Checkboxes: Has Description, Has Link
	local hasDescCheck = self:CreateModernCheckbox(panel, "Has Description")
	hasDescCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	panel.hasDescCheck = hasDescCheck
	yOff = yOff - 24

	local hasLinkCheck = self:CreateModernCheckbox(panel, "Has Link")
	hasLinkCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, yOff)
	panel.hasLinkCheck = hasLinkCheck
	yOff = yOff - 32

	-- Buttons: Apply + Clear
	local applyBtn = self:CreateModernButton(panel, 80, 22, "Apply")
	applyBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -90, 10)
	applyBtn:SetScript("OnClick", function()
		MPT:ApplyFilterPopup()
	end)

	local clearFilterBtn = self:CreateModernButton(panel, 80, 22, "Clear")
	clearFilterBtn:SetPoint("LEFT", applyBtn, "RIGHT", 4, 0)
	clearFilterBtn:SetScript("OnClick", function()
		MPT:ResetFilterPopup()
		MPT.advancedFilters = nil
		MPT:ApplyFilters()
		MPT.filterPopup:Hide()
	end)

	panel:SetHeight(math.abs(yOff) + 16)
	panel:Hide()
	self.filterPopup = panel
end

function MPT:ResetFilterPopup()
	local p = self.filterPopup
	if not p then return end
	p.dungeonDD:SetValue("")
	p.dungeonSearchBox:SetText("")
	p.affixDD:SetValue("")
	p.bonusDD:SetValue("")
	p.roleDD:SetValue("")
	p.levelMinBox:SetText("")
	p.levelMaxBox:SetText("")
	p.hasDescCheck:SetChecked(false)
	p.hasLinkCheck:SetChecked(false)
	p.playerBox:SetText("")
	p.realmBox:SetText("")
end

function MPT:PopulateFilterDropdowns()
	local dungeons, affixes = self:CollectFilterValues()
	if self.filterPopup then
		self.filterPopup.dungeonDD:SetItems(dungeons)
		self.filterPopup.affixDD:SetItems(affixes)
	end
end

function MPT:ApplyFilterPopup()
	local p = self.filterPopup
	if not p then return end

	-- Dungeon: dropdown takes priority, fallback to search box
	local dungeonVal = p.dungeonDD:GetValue()
	if dungeonVal == "" then
		dungeonVal = p.dungeonSearchBox:GetText()
	end

	self.advancedFilters = {
		dungeon = dungeonVal,
		affix = p.affixDD:GetValue(),
		bonus = p.bonusDD:GetValue(),
		role = p.roleDD:GetValue(),
		levelMin = p.levelMinBox:GetText(),
		levelMax = p.levelMaxBox:GetText(),
		hasDesc = p.hasDescCheck:GetChecked(),
		hasLink = p.hasLinkCheck:GetChecked(),
	}

	-- Sync player/realm from popup to filter bar
	local popupPlayer = p.playerBox:GetText()
	local popupRealm = p.realmBox:GetText()
	if popupPlayer ~= "" and self.filterPlayerBox then
		self.filterPlayerBox:SetText(popupPlayer)
	end
	if popupRealm ~= "" and self.filterRealmBox then
		self.filterRealmBox:SetText(popupRealm)
	end

	self:ApplyFilters()
	self.filterPopup:Hide()
end

function MPT:ResetFilterBtnStyle()
	if self.filterBtn then
		self.filterBtn.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
		self.filterBtn.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	end
end

function MPT:ToggleFilterPopup()
	if not self.filterPopup then
		self:CreateFilterPopup()
	end

	if self.filterPopup:IsShown() then
		self.filterPopup:Hide()
		self:ResetFilterBtnStyle()
	else
		self:PopulateFilterDropdowns()
		self.filterPopup:Show()
		if self.filterBtn then
			self.filterBtn.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
			self.filterBtn.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		end
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
