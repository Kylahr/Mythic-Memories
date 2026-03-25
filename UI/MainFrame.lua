local _, MPT = ...

local ROW_HEIGHT = 32
local VISIBLE_ROWS = 15
local HEADER_HEIGHT = 28
local MVP_PANEL_WIDTH = 200
local MVP_SEARCH_HEIGHT = 28

-- ── Theme system ──────────────────────────────────────────────
-- Each theme is a full palette table. Add new themes below.
-- Source hex values in comments for easy tweaking.

local THEMES = {}

-- Coffee: #D9A883 Toasty, #A98062 Espresso Foam, #956643 Mocha Latte,
--         #623528 Cold Brew, #343434 Espresso Noir
THEMES["coffee"] = {
	bg         = { 0.13, 0.12, 0.11 },     -- main frame / dark shell
	titleBar   = { 0.24, 0.15, 0.11 },     -- title strip — Cold Brew darkened
	filterBar  = { 0.17, 0.15, 0.13 },     -- filter bar strip
	panelBg    = { 0.20, 0.17, 0.14 },     -- elevated card/panel bg
	contentBg  = { 0.18, 0.16, 0.14 },     -- content area inset
	headerBg   = { 0.28, 0.18, 0.14 },     -- column header bar — Cold Brew
	rowBase    = { 0.17, 0.15, 0.13 },     -- odd rows
	rowAlt     = { 0.21, 0.18, 0.15 },     -- even rows
	inputBg    = { 0.28, 0.22, 0.17 },     -- input fields
	btnBg      = { 0.26, 0.20, 0.15 },     -- button background
	btnHover   = { 0.34, 0.25, 0.19 },     -- button hover
	accent     = { 0.85, 0.66, 0.51 },     -- Toasty — primary accent
	accentDim  = { 0.58, 0.40, 0.26 },     -- Mocha Latte — dimmed accent
	textPrimary= { 0.92, 0.80, 0.65 },     -- lighter Toasty — primary text
	textMuted  = { 0.50, 0.38, 0.30 },     -- muted — dark Espresso Foam
	textLabel  = { 0.66, 0.50, 0.38 },     -- Espresso Foam — labels
	divider    = { 0.30, 0.19, 0.14 },     -- Cold Brew — dividers
	highlight  = { 0.85, 0.66, 0.51, 0.06 }, -- Toasty glow — row hover
	popupBg    = { 0.20, 0.17, 0.14 },     -- popup/dialog (matches panelBg)
	mvpPanelBg = { 0.10, 0.09, 0.08 },     -- deep espresso
	mvpRowBase = { 0.14, 0.12, 0.10 },     -- MVP odd rows
	mvpRowAlt  = { 0.18, 0.15, 0.12 },     -- MVP even rows
	mvpInputBg = { 0.22, 0.18, 0.14 },     -- MVP search bar

	-- Detail/tree view (RowDetail)
	detailBg      = { 0.15, 0.13, 0.11 },   -- detail background
	detailCardOdd = { 0.22, 0.18, 0.14 },   -- brighter card
	detailCardEven= { 0.18, 0.16, 0.13 },   -- darker card
	detailHeaderBg= { 0.25, 0.20, 0.15 },   -- header strip
	detailActionBg= { 0.18, 0.16, 0.13 },   -- action bar zone

	-- Semantic colors
	dangerText   = { 1, 0.4, 0.4 },         -- delete/reset button text
	dangerHover  = { 1, 0.3, 0.3 },         -- delete icon hover
	dangerBg     = { 0.25, 0.10, 0.08 },    -- delete button hover bg
	successText  = { 0.4, 1, 0.4 },         -- "Copied!" confirmation
	successDim   = { 0.6, 0.9, 0.6 },       -- copy hint text
	checkGreen   = { 0, 1, 0 },             -- MVP checkmark
	levelText    = { 0.2, 0.8, 0.2 },       -- level column
	textNeutral  = { 0.92, 0.82, 0.68 },    -- neutral warm text (dialogs)
	bubbleHover  = { 1, 0.95, 0.8, 0.05 },  -- MVP bubble hover
	borderColor  = { 0.18, 0.16, 0.13 },    -- popup borders
	scrollBg     = { 0.30, 0.24, 0.18 },    -- scrollable area / input containers
	charCount    = { 0.50, 0.38, 0.30 },     -- character count text
}

-- Forest: #BEB982 Sage, #C1B052 Golden Olive, #081B18 Deep Forest,
--         #203B37 Dark Teal, #5AAF76 Green, #06C0B0 Bright Teal
THEMES["forest"] = {
	bg         = { 0.03, 0.11, 0.09 },     -- Deep Forest — dark shell
	titleBar   = { 0.13, 0.23, 0.22 },     -- Dark Teal — title strip
	filterBar  = { 0.07, 0.15, 0.13 },     -- between forest and teal
	panelBg    = { 0.10, 0.20, 0.18 },     -- elevated card/panel
	contentBg  = { 0.08, 0.17, 0.15 },     -- content area inset
	headerBg   = { 0.13, 0.23, 0.22 },     -- Dark Teal — column headers
	rowBase    = { 0.06, 0.14, 0.12 },     -- odd rows
	rowAlt     = { 0.09, 0.18, 0.16 },     -- even rows
	inputBg    = { 0.13, 0.23, 0.22 },     -- input fields — Dark Teal
	btnBg      = { 0.11, 0.21, 0.19 },     -- button background
	btnHover   = { 0.16, 0.28, 0.26 },     -- button hover
	accent     = { 0.35, 0.69, 0.46 },     -- Green #5AAF76
	accentDim  = { 0.76, 0.69, 0.32 },     -- Golden Olive #C1B052
	textPrimary= { 0.80, 0.78, 0.58 },     -- lighter Sage
	textMuted  = { 0.45, 0.50, 0.40 },     -- muted sage
	textLabel  = { 0.60, 0.62, 0.46 },     -- mid sage
	divider    = { 0.13, 0.23, 0.22 },     -- Dark Teal — dividers
	highlight  = { 0.35, 0.69, 0.46, 0.06 }, -- Green glow — row hover
	popupBg    = { 0.10, 0.20, 0.18 },     -- popup/dialog
	mvpPanelBg = { 0.02, 0.08, 0.07 },     -- deeper than shell
	mvpRowBase = { 0.05, 0.13, 0.11 },     -- MVP odd rows
	mvpRowAlt  = { 0.08, 0.17, 0.15 },     -- MVP even rows
	mvpInputBg = { 0.11, 0.21, 0.19 },     -- MVP search bar

	detailBg      = { 0.05, 0.13, 0.11 },   -- detail background
	detailCardOdd = { 0.09, 0.18, 0.16 },   -- brighter card
	detailCardEven= { 0.06, 0.15, 0.13 },   -- darker card
	detailHeaderBg= { 0.13, 0.23, 0.22 },   -- header strip
	detailActionBg= { 0.06, 0.15, 0.13 },   -- action bar zone

	dangerText   = { 1, 0.4, 0.4 },
	dangerHover  = { 1, 0.3, 0.3 },
	dangerBg     = { 0.25, 0.10, 0.08 },
	successText  = { 0.4, 1, 0.4 },
	successDim   = { 0.6, 0.9, 0.6 },
	checkGreen   = { 0, 1, 0 },
	levelText    = { 0.02, 0.75, 0.69 },    -- Bright Teal #06C0B0
	textNeutral  = { 0.80, 0.78, 0.58 },    -- Sage neutral
	bubbleHover  = { 0.35, 0.69, 0.46, 0.05 }, -- Green glow
	borderColor  = { 0.08, 0.17, 0.15 },
	scrollBg     = { 0.13, 0.23, 0.22 },
	charCount    = { 0.45, 0.50, 0.40 },
}

-- Crimson: #3D1E38 Aubergine, #6B1634 Claret, #C54110 Madder Lake,
--          #F0B734 Rain Boots, #1B3D54 Prussian Blue
THEMES["crimson"] = {
	bg         = { 0.06, 0.08, 0.12 },     -- Prussian Blue darkened — dark shell
	titleBar   = { 0.18, 0.10, 0.16 },     -- Aubergine — title strip
	filterBar  = { 0.10, 0.10, 0.14 },     -- between Prussian and Aubergine
	panelBg    = { 0.14, 0.12, 0.17 },     -- elevated card/panel
	contentBg  = { 0.12, 0.11, 0.15 },     -- content area inset
	headerBg   = { 0.24, 0.08, 0.14 },     -- Claret darkened — column headers
	rowBase    = { 0.09, 0.09, 0.13 },     -- odd rows
	rowAlt     = { 0.12, 0.11, 0.16 },     -- even rows
	inputBg    = { 0.20, 0.12, 0.18 },     -- Aubergine — input fields
	btnBg      = { 0.18, 0.11, 0.16 },     -- button background
	btnHover   = { 0.26, 0.14, 0.20 },     -- button hover
	accent     = { 0.94, 0.72, 0.20 },     -- Rain Boots #F0B734
	accentDim  = { 0.77, 0.25, 0.06 },     -- Madder Lake #C54110
	textPrimary= { 0.92, 0.82, 0.70 },     -- warm light
	textMuted  = { 0.50, 0.42, 0.45 },     -- muted purple-grey
	textLabel  = { 0.65, 0.55, 0.55 },     -- mid warm
	divider    = { 0.28, 0.12, 0.18 },     -- Claret — dividers
	highlight  = { 0.94, 0.72, 0.20, 0.06 }, -- Rain Boots glow
	popupBg    = { 0.14, 0.12, 0.17 },     -- popup/dialog
	mvpPanelBg = { 0.04, 0.05, 0.08 },     -- deeper than shell
	mvpRowBase = { 0.08, 0.08, 0.12 },     -- MVP odd rows
	mvpRowAlt  = { 0.11, 0.10, 0.15 },     -- MVP even rows
	mvpInputBg = { 0.18, 0.11, 0.16 },     -- MVP search bar

	detailBg      = { 0.08, 0.08, 0.12 },   -- detail background
	detailCardOdd = { 0.12, 0.11, 0.16 },   -- brighter card
	detailCardEven= { 0.09, 0.09, 0.13 },   -- darker card
	detailHeaderBg= { 0.20, 0.10, 0.16 },   -- header strip
	detailActionBg= { 0.09, 0.09, 0.13 },   -- action bar zone

	dangerText   = { 1, 0.4, 0.4 },
	dangerHover  = { 1, 0.3, 0.3 },
	dangerBg     = { 0.25, 0.10, 0.08 },
	successText  = { 0.4, 1, 0.4 },
	successDim   = { 0.6, 0.9, 0.6 },
	checkGreen   = { 0, 1, 0 },
	levelText    = { 0.94, 0.72, 0.20 },    -- Rain Boots
	textNeutral  = { 0.92, 0.82, 0.70 },
	bubbleHover  = { 0.94, 0.72, 0.20, 0.05 },
	borderColor  = { 0.12, 0.11, 0.15 },
	scrollBg     = { 0.20, 0.12, 0.18 },
	charCount    = { 0.50, 0.42, 0.45 },
}

-- Theme list for dropdown (display name → key)
local THEME_LIST = {
	{ key = "coffee", name = "Coffee" },
	{ key = "forest", name = "Forest" },
	{ key = "crimson", name = "Crimson" },
}

-- Active palette — independent copy so theme switching doesn't corrupt source tables
local C = {}
for k, v in pairs(THEMES["coffee"]) do C[k] = v end

-- Expose palette globally so other files (EditPopup, RowDetail) can access it
MPT.C = C

-- Fixed note colors (theme-independent) — easy to tweak in one place
local NOTE_LABEL = { 1, 0.82, 0 }       -- yellow — "Note", "MVP Note" labels
local NOTE_TEXT  = { 0.7, 0.85, 1 }      -- light blue — actual note content
local NOTE_LABEL_HEX = "FFD100"          -- hex of NOTE_LABEL for inline color codes
MPT.NOTE_LABEL = NOTE_LABEL
MPT.NOTE_TEXT  = NOTE_TEXT
MPT.NOTE_LABEL_HEX = NOTE_LABEL_HEX

-- Build a note label with name in class color + "Note" in yellow
-- e.g. "|cFF00FF96Kylahr's|r |cFFFFD100Note:|r"
function MPT:NoteLabel(name, class)
	local cr, cg, cb = self:GetClassColor(class)
	local classHex = string.format("%02X%02X%02X", math.floor(cr * 255), math.floor(cg * 255), math.floor(cb * 255))
	return "|cFF" .. classHex .. name .. "'s|r |cFF" .. NOTE_LABEL_HEX .. "Note:|r"
end

function MPT:ApplyTheme(themeKey)
	local theme = THEMES[themeKey]
	if not theme then return end
	self.db.global.theme = themeKey
	-- Update the palette reference (C is upvalue for all UI code)
	for k, v in pairs(theme) do
		C[k] = v
	end
	self.C = C
	-- Update font objects to new palette colors
	MPTFont_Title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	MPTFont_Header:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	MPTFont_Cell:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	MPTFont_Label:SetTextColor(C.textLabel[1], C.textLabel[2], C.textLabel[3])
	MPTFont_Small:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	-- Rebuild UI to apply
	if self.mainFrame then
		self:HideAllPopups()
		-- Destroy globally-named frames so templates reinitialize cleanly
		local globalNames = {
			"MPTMainFrame", "MPTScrollFrame", "MPTScrollFrameScrollBar",
			"MPTScrollFrameScrollBarScrollUpButton", "MPTScrollFrameScrollBarScrollDownButton",
			"MPTMvpSearch", "MPTHelpPanel", "MPTDeleteRunDialog",
			"MPTFilterPopup", "MPTNotification", "MPTOptionsPanel", "MPTResetDialog",
			"MPTTableManagerPanel", "MPTDeleteTableDialog", "MPTNewTableInput",
		}
		for _, name in ipairs(globalNames) do
			local f = _G[name]
			if f and f.Hide then f:Hide() end
			if f and f.SetParent then f:SetParent(nil) end
			_G[name] = nil
		end
		-- Clear row globals
		for i = 1, 50 do
			local name = "MPTRow" .. i
			local f = _G[name]
			if f then
				f:Hide()
				f:SetParent(nil)
				_G[name] = nil
			end
		end
		self.mainFrame:Hide()
		self.mainFrame:SetParent(nil)
		self.mainFrame = nil
		self.optionsPanel = nil
		self.mvpsSidePanel = nil
		self.editPopup = nil
		self.filterPopup = nil
		self.helpPanel = nil
		self.resetDialog = nil
		self.deleteRunDialog = nil
		self.notePopup = nil
		self.removeMvpDialog = nil
		self.addNoteDialog = nil
		self.rowContextMenu = nil
		self.mvpDropdown = nil
		self.notifFrame = nil
		self.linkCopyPopup = nil
		self.expandedRunId = nil
		self.tableManagerPanel = nil
		self.tableBtn = nil
		self.tableNameLabel = nil
		self.deleteTableDialog = nil
		self.tableRowContextMenu = nil
		self.tableManagerRows = nil
		self.remoteTableDD = nil
		self.remoteTableListFrame = nil
		self.viewTitleFrame = nil
		self.viewTitle = nil
		self.viewTitleCrown = nil
		self.loadingFrame = nil
		self.moveSubmenu = nil
		if self.PlayerDetect_DestroyUI then
			self:PlayerDetect_DestroyUI()
		end
		self:CreateMainFrame()
		self.mainFrame:Show()
		self:RefreshTable()
		self:RefreshMvpsSidePanel()
	end
end

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

-- Expose for tests
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
			clearLabel:SetTextColor(C.dangerHover[1], C.dangerHover[2], C.dangerHover[3])
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
		label:SetTextColor(C.dangerHover[1], C.dangerHover[2], C.dangerHover[3])
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

	-- Build display list: optionally "All" + items
	local allItems = {}
	if not dropdown._noDefault then
		allItems[1] = { value = "", display = dropdown._defaultText }
	end
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
				if dropdown._onSelect then
					dropdown._onSelect(item.value, item.display)
				end
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

local function calcFrameWidth()
	local mainColWidth = getTotalWidth()
	local statWidth = MPT:GetStatColumnsTotalWidth()
	-- NAME(160) + role(30) + stat columns + detail padding (~42)
	local detailWidth = 160 + 30 + statWidth + 42
	return math.max(mainColWidth + 30, detailWidth, 730)
end

function MPT:ResizeMainFrame()
	if not self.mainFrame then return end
	local newWidth = calcFrameWidth()
	self.mainFrame:SetWidth(newWidth)
end

function MPT:CreateMainFrame()
	if self.mainFrame then return end

	local totalWidth = calcFrameWidth()
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

	local tableName = frame:CreateFontString(nil, "OVERLAY", "MPTFont_Label")
	tableName:SetPoint("LEFT", title, "RIGHT", 8, 0)
	tableName:SetText("(" .. self:GetViewedTableName() .. ")")
	tableName:SetTextColor(C.textLabel[1], C.textLabel[2], C.textLabel[3])
	self.tableNameLabel = tableName

	local closeBtn = self:CreateCloseButton(frame)
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -4)

	-- MVP panel toggle button (arrow, title bar left edge)
	local mvpToggleBtn = CreateFrame("Button", nil, frame)
	mvpToggleBtn:SetSize(26, 26)
	mvpToggleBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 2)
	local arrowLabel = mvpToggleBtn:CreateFontString(nil, "OVERLAY")
	arrowLabel:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
	arrowLabel:SetPoint("CENTER", 0, 0)
	arrowLabel:SetText("\194\171") -- «
	arrowLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	mvpToggleBtn.arrowLabel = arrowLabel
	mvpToggleBtn:SetScript("OnEnter", function()
		arrowLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	mvpToggleBtn:SetScript("OnLeave", function()
		arrowLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	mvpToggleBtn:SetScript("OnClick", function()
		MPT:ToggleMvpPanel()
	end)
	self.mvpToggleBtn = mvpToggleBtn

	-- Back button (visible only in view mode, chained right of toggle)
	local backBtn = self:CreateModernButton(frame, 60, 20, "< Back")
	backBtn:SetPoint("LEFT", mvpToggleBtn, "RIGHT", 4, 0)
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
		MPT.currentFilters = nil
		-- Clear view mode when closing
		if MPT.viewingPlayer then
			MPT.viewingPlayer = nil
			MPT.viewingClass = nil
			MPT.viewingData = nil
			MPT.remoteTableList = nil
			MPT.remoteTableOwner = nil
			MPT:UpdateViewModeUI()
		end
	end)

	-- ── Content card (lighter inset area for filter + table) ────
	local tableCard = CreateFrame("Frame", nil, frame)
	tableCard:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -26)
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
	self:CreateMvpsSidePanel(frame)

	frame:Hide()
	self.mainFrame = frame

	-- Apply saved MVP panel state
	if self.db and self.db.global.mvpPanelOpen == false then
		self:SetMvpPanelOpen(false)
	end
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
			favIcon:SetVertexColor(1, 0.85, 0)    -- fixed gold (theme-independent)
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

	local tableBtn = self:CreateModernButton(bar, 55, 20, "Tables")
	tableBtn:SetPoint("LEFT", filterBtn, "RIGHT", 8, 0)
	tableBtn:SetScript("OnClick", function()
		MPT:ToggleTableManagerPanel()
	end)
	tableBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	tableBtn:SetScript("OnLeave", function(self)
		if not (MPT.tableManagerPanel and MPT.tableManagerPanel:IsShown()) then
			self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			self.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
	end)
	self.tableBtn = tableBtn

	-- Stats column toggle button
	local statsBtn = self:CreateModernButton(bar, 45, 20, "Stats")
	statsBtn:SetPoint("LEFT", tableBtn, "RIGHT", 8, 0)
	statsBtn:SetScript("OnClick", function()
		MPT:ToggleStatsPopup()
	end)
	statsBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end)
	statsBtn:SetScript("OnLeave", function(self)
		if not (MPT.statsPopup and MPT.statsPopup:IsShown()) then
			self.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			self.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
	end)
	self.statsBtn = statsBtn

	self.filterBar = bar
	self.filterPlayerBox = playerBox
	self.filterRealmBox = realmBox
end

function MPT:CreateColumnHeaders(parent)
	local header = CreateFrame("Frame", nil, parent)
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -30)
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
	scrollParent:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -30 - HEADER_HEIGHT)
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
	favBar:SetColorTexture(1, 0.85, 0, 0.8)    -- fixed gold (theme-independent)
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
	mvpStar:SetVertexColor(1, 0.85, 0)    -- fixed gold (theme-independent)
	mvpStar:Hide()
	row.mvpStar = mvpStar

	-- MVP tooltip zone
	local mvpZone = CreateFrame("Button", nil, row)
	mvpZone:SetPoint("LEFT", row, "LEFT", mvpOff, 0)
	mvpZone:SetSize(mvpW, ROW_HEIGHT)
	mvpZone:SetScript("OnEnter", function(self)
		if row.runData and row.mvpNames and #row.mvpNames > 0 then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("MVPs", NOTE_LABEL[1], NOTE_LABEL[2], NOTE_LABEL[3])
			for _, name in ipairs(row.mvpNames) do
				local displayName = MPT:StripRealm(name)
				local note = MPT:GetMvpNote(name)
				if note and note ~= "" then
					GameTooltip:AddLine(displayName, 1, 1, 1)
					GameTooltip:AddLine(note, NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3], true)
				else
					GameTooltip:AddLine(displayName, 1, 1, 1)
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
	row.cells[3]:SetTextColor(C.levelText[1], C.levelText[2], C.levelText[3])

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

function MPT:CreateMvpsSidePanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetWidth(MVP_PANEL_WIDTH)
	-- Extends to the LEFT of the main frame
	panel:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
	panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", 0, 0)

	-- Panel background (full height, covers title bar area on the left)
	local SCROLL_BAR_WIDTH = 4
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.mvpPanelBg[1], C.mvpPanelBg[2], C.mvpPanelBg[3], 1)
	bg:SetDrawLayer("BACKGROUND", 5)

	-- Header bar
	local header = CreateFrame("Frame", nil, panel)
	header:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -2)
	header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6 - SCROLL_BAR_WIDTH - 2, -2)
	header:SetHeight(HEADER_HEIGHT)
	-- No header background — sits in the title bar zone, uses main bg behind it

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

	-- Search bar
	local searchBar = CreateFrame("Frame", nil, panel)
	searchBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(HEADER_HEIGHT + 6))
	searchBar:SetPoint("RIGHT", panel, "RIGHT", -6 - SCROLL_BAR_WIDTH - 2, 0)
	searchBar:SetHeight(22)

	local searchBg = searchBar:CreateTexture(nil, "BACKGROUND", nil, 3)
	searchBg:SetAllPoints()
	searchBg:SetColorTexture(C.mvpInputBg[1], C.mvpInputBg[2], C.mvpInputBg[3], 1)

	local searchBox = CreateFrame("EditBox", "MPTMvpSearch", searchBar)
	searchBox:SetPoint("TOPLEFT", 6, -2)
	searchBox:SetPoint("BOTTOMRIGHT", -18, 2)
	searchBox:SetAutoFocus(false)
	searchBox:SetFontObject("MPTFont_Cell")

	-- Placeholder text
	local placeholder = searchBar:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	placeholder:SetPoint("LEFT", searchBar, "LEFT", 6, 0)
	placeholder:SetText("Search...")
	placeholder:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.6)

	-- Clear X button
	local clearBtn = CreateFrame("Button", nil, searchBar)
	clearBtn:SetSize(14, 14)
	clearBtn:SetPoint("RIGHT", searchBar, "RIGHT", -4, 0)
	local clearLabel = clearBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	clearLabel:SetPoint("CENTER", 0, 0)
	clearLabel:SetText("x")
	clearLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	clearBtn:SetScript("OnEnter", function()
		clearLabel:SetTextColor(C.dangerHover[1], C.dangerHover[2], C.dangerHover[3])
	end)
	clearBtn:SetScript("OnLeave", function()
		clearLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	end)
	clearBtn:SetScript("OnClick", function()
		searchBox:SetText("")
		searchBox:ClearFocus()
		clearBtn:Hide()
		MPT:RefreshMvpsSidePanel()
	end)
	clearBtn:Hide()

	searchBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text ~= "" then
			clearBtn:Show()
			placeholder:Hide()
		else
			clearBtn:Hide()
			placeholder:Show()
		end
		MPT:RefreshMvpsSidePanel()
	end)
	searchBox:SetScript("OnEditFocusGained", function()
		placeholder:Hide()
	end)
	searchBox:SetScript("OnEditFocusLost", function()
		if searchBox:GetText() == "" then
			placeholder:Show()
		end
	end)
	searchBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
		MPT:RefreshMvpsSidePanel()
	end)

	panel.searchBox = searchBox
	self.mvpSearchBox = searchBox

	local scrollParent = CreateFrame("Frame", nil, panel)
	scrollParent:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -(HEADER_HEIGHT + 6 + MVP_SEARCH_HEIGHT))
	scrollParent:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6 - SCROLL_BAR_WIDTH - 2, 6)
	scrollParent:SetClipsChildren(true)
	panel.scrollParent = scrollParent
	panel.bubbles = {}
	panel.mvpScrollOffset = 0

	-- Scrollbar track
	local track = CreateFrame("Frame", nil, panel)
	track:SetWidth(SCROLL_BAR_WIDTH)
	track:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -(HEADER_HEIGHT + 6 + MVP_SEARCH_HEIGHT))
	track:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 6)
	local trackBg = track:CreateTexture(nil, "BACKGROUND")
	trackBg:SetAllPoints()
	trackBg:SetColorTexture(C.mvpPanelBg[1], C.mvpPanelBg[2], C.mvpPanelBg[3], 1)
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
	removeBtn:SetScript("OnEnter", function() xLabel:SetTextColor(C.dangerHover[1], C.dangerHover[2], C.dangerHover[3]) end)
	removeBtn:SetScript("OnLeave", function() xLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3]) end)
	bubble.removeBtn = removeBtn

	-- Party-vouched right accent bar (3px, green)
	local rightBar = bubble:CreateTexture(nil, "ARTWORK")
	rightBar:SetWidth(3)
	rightBar:SetPoint("TOPRIGHT", bubble, "TOPRIGHT", 0, 0)
	rightBar:SetPoint("BOTTOMRIGHT", bubble, "BOTTOMRIGHT", 0, 0)
	rightBar:SetColorTexture(0.2, 1, 0.2, 1)
	rightBar:Hide()
	bubble.rightBar = rightBar

	-- Highlight on hover
	local hl = bubble:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(C.bubbleHover[1], C.bubbleHover[2], C.bubbleHover[3], C.bubbleHover[4])

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
	local runSource = isViewing and (self.viewingData and self.viewingData.runs or {}) or self:GetViewedRuns()

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

	panel.mvpVisibleCount = 0

	-- Filter by search text
	local searchText = ""
	if self.mvpSearchBox then
		searchText = (self.mvpSearchBox:GetText() or ""):lower()
	end

	-- Reset scroll only when search text or view mode changed
	local prevSearch = panel.lastMvpSearchText or ""
	local prevViewing = panel.lastMvpViewMode or false
	if searchText ~= prevSearch or isViewing ~= prevViewing then
		panel.mvpScrollOffset = 0
	end
	panel.lastMvpSearchText = searchText
	panel.lastMvpViewMode = isViewing

	local yOff = 0
	local idx = 0
	for nameRealm, data in pairs(mvpSource) do
		-- Apply search filter
		if searchText ~= "" and not nameRealm:lower():find(searchText, 1, true) then
			-- skip this MVP
		else
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
			bubble.bg:SetColorTexture(C.mvpRowAlt[1], C.mvpRowAlt[2], C.mvpRowAlt[3], 1)
		else
			bubble.bg:SetColorTexture(C.mvpRowBase[1], C.mvpRowBase[2], C.mvpRowBase[3], 1)
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

		-- Shared MVP right bar (green = you or a party member also has this MVP)
		local vouches = self:CheckPartyMvp(nameRealm)
		-- In remote view, filter out the person whose list we're viewing (redundant)
		if isViewing and self.viewingPlayer then
			local viewBase = (self.viewingPlayer:match("^([^%-]+)") or self.viewingPlayer):lower()
			local filtered = {}
			for _, v in ipairs(vouches) do
				local senderBase = (MPT:StripRealm(v.sender):match("^([^%-]+)") or MPT:StripRealm(v.sender)):lower()
				if senderBase ~= viewBase then
					filtered[#filtered + 1] = v
				end
			end
			vouches = filtered
		end
		local vouchedBy = vouches[1] and vouches[1].sender or nil
		if not vouchedBy and isViewing then
			local normalized = self:NormalizeNameRealm(nameRealm)
			local localMvps = self.db.global.mvps or {}
			if localMvps[normalized] then
				vouchedBy = "you"
				vouches = { { sender = "you", note = localMvps[normalized].note } }
			end
		end
		if vouchedBy and bubble.rightBar then
			bubble.rightBar:Show()
			-- Green if you have them locally, blue if only party members do
			local normalized = self:NormalizeNameRealm(nameRealm)
			local inLocal = self.db.global.mvps and self.db.global.mvps[normalized]
			if inLocal then
				bubble.rightBar:SetColorTexture(0.2, 1, 0.2, 1)
			else
				bubble.rightBar:SetColorTexture(0.3, 0.7, 1, 1)
			end
			bubble.vouchedBy = vouchedBy
			bubble.vouches = vouches
		elseif bubble.rightBar then
			bubble.rightBar:Hide()
			bubble.vouchedBy = nil
			bubble.vouches = nil
		end

		-- Tooltip with note on hover
		bubble:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if isViewing then
				local remoteNote = data.note
				if remoteNote and remoteNote ~= "" then
					local ownerName = (MPT.viewingPlayer or ""):match("^([^%-]+)") or "Their"
					GameTooltip:AddLine(MPT:NoteLabel(ownerName, MPT.viewingClass), 1, 1, 1)
					GameTooltip:AddLine(remoteNote, NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3], true)
					GameTooltip:AddLine(" ")
				end
			else
				local note = MPT:GetMvpNote(nameRealm)
				if note and note ~= "" then
					GameTooltip:AddLine(note, NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3], true)
					GameTooltip:AddLine(" ")
				end
			end
			if self.vouches and #self.vouches > 0 then
				for _, v in ipairs(self.vouches) do
					if MPT:StripRealm(v.sender) == "you" then
						GameTooltip:AddLine("Also in your list", 0.2, 1, 0.2)
						if v.note and v.note ~= "" then
							GameTooltip:AddLine("|cFF" .. NOTE_LABEL_HEX .. "Your note:|r " .. v.note, NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3], true)
						end
					else
						GameTooltip:AddLine("Also in " .. MPT:StripRealm(v.sender) .. "'s list", 0.2, 1, 0.2)
						if v.note and v.note ~= "" then
							GameTooltip:AddLine("|cFF" .. NOTE_LABEL_HEX .. MPT:StripRealm(v.sender) .. "'s note:|r " .. v.note, NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3], true)
						end
					end
				end
				GameTooltip:AddLine(" ")
			end
			GameTooltip:AddLine("Left-click to scroll to run", 0.7, 0.7, 0.7)
			if isViewing then
				local alreadyLocal = MPT.db.global.mvps[MPT:NormalizeNameRealm(nameRealm)]
				if not alreadyLocal then
					GameTooltip:AddLine("Right-click to add to your list", 0.7, 0.7, 0.7)
				end
			else
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
			elseif button == "RightButton" and isViewing then
				MPT:ShowRemoteMvpContextMenu(nameRealm, class, data)
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
		end -- else (search filter)
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
		bubble.bg:SetColorTexture(C.mvpRowBase[1], C.mvpRowBase[2], C.mvpRowBase[3], 1)
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

	local COL_WIDTH = 280
	local COL_GAP = 20
	local PAD = 14
	local panelW = PAD + COL_WIDTH + COL_GAP + COL_WIDTH + PAD

	local panel = CreateFrame("Frame", "MPTHelpPanel", self.mainFrame)
	panel:SetSize(panelW, 300)  -- height adjusted below
	panel:SetPoint("TOPRIGHT", self.helpBtn, "BOTTOMRIGHT", 4, -4)
	panel:SetFrameStrata("DIALOG")

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	-- Two-column layout helpers
	local yLeft = -PAD
	local yRight = -PAD
	local colLeftX = PAD
	local colRightX = PAD + COL_WIDTH + COL_GAP

	local function addHeader(col, text)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
		local x = col == 1 and colLeftX or colRightX
		local y = col == 1 and yLeft or yRight
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		fs:SetText(text)
		if col == 1 then yLeft = yLeft - 16 else yRight = yRight - 16 end
	end

	local function addLine(col, text)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		local x = col == 1 and colLeftX or colRightX
		local y = col == 1 and yLeft or yRight
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		fs:SetWidth(COL_WIDTH)
		fs:SetJustifyH("LEFT")
		fs:SetText(text)
		fs:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		local h = fs:GetStringHeight() + 4
		if col == 1 then yLeft = yLeft - h else yRight = yRight - h end
	end

	local function addSpacer(col)
		if col == 1 then yLeft = yLeft - 6 else yRight = yRight - 6 end
	end

	local function addIconLine(col, texture, r, g, b, text, desat)
		local x = col == 1 and colLeftX or colRightX
		local y = col == 1 and yLeft or yRight
		local icon = panel:CreateTexture(nil, "OVERLAY")
		icon:SetSize(14, 14)
		icon:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y - 1)
		icon:SetTexture(texture)
		if desat then icon:SetDesaturated(true) end
		icon:SetVertexColor(r, g, b)
		local fs = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", x + 18, y)
		fs:SetWidth(COL_WIDTH - 18)
		fs:SetJustifyH("LEFT")
		fs:SetText(text)
		fs:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		local h = fs:GetStringHeight() + 4
		if col == 1 then yLeft = yLeft - h else yRight = yRight - h end
	end

	-- ── LEFT COLUMN ──
	addHeader(1, "Getting Started")
	addLine(1, "Every M+ run is recorded automatically — stats, group, and all.")
	addSpacer(1)

	addHeader(1, "Run Table")
	addLine(1, "Click a row to expand per-player stats.")
	addLine(1, "Right-click a row to open the context menu.")
	addSpacer(1)

	addHeader(1, "Tables")
	addLine(1, "Organize runs into multiple tables. The active table (gold dot) receives new runs.")
	addLine(1, "Tables button opens the Table Manager. Right-click a table for options.")
	addSpacer(1)

	addHeader(1, "Filters")
	addIconLine(1, "Interface\\COMMON\\FavoritesIcon", 1, 0.85, 0, "Toolbar star filters favourites only.")
	addLine(1, "Filter button opens advanced filters: dungeon, affix, level, role, and more.")
	addSpacer(1)

	addHeader(1, "Table Sharing")
	addLine(1, "Right-click a portrait to view their runs or add them as MVP.")
	addLine(1, "Browse their tables with the dropdown. Import their MVPs to your list.")
	addSpacer(1)

	addHeader(1, "Slash Commands")
	addLine(1, "/mm — Toggle this window")
	addLine(1, "/mm mvps — List your MVPs in chat")

	-- ── RIGHT COLUMN ──
	addHeader(2, "MVP System")
	addLine(2, "Mark standout players you want to remember.")
	addLine(2, "Click a name in the stat breakdown to toggle MVP. Right-click to add with a note.")
	addLine(2, "The arrow button toggles the MVP side panel.")
	addLine(2, "MVPs are global — shared across all tables.")
	addSpacer(2)

	addHeader(2, "MVP Crowns")
	addIconLine(2, "Interface\\GroupFrame\\UI-Group-AssistantIcon", 1, 0.82, 0, "Your MVP")
	addIconLine(2, "Interface\\GroupFrame\\UI-Group-AssistantIcon", 0.3, 0.7, 1, "Party member's MVP", true)
	addIconLine(2, "Interface\\GroupFrame\\UI-Group-AssistantIcon", 0.2, 1, 0.2, "Both lists", true)
	addLine(2, "Crowns appear in Group Finder, world tooltips, and the remote view title bar.")
	addSpacer(2)

	addHeader(2, "Party Awareness")
	addLine(2, "Your party shares MVP lists automatically.")
	addLine(2, "A green bar on the right of an MVP bubble means a party member also has them.")
	addLine(2, "MVPs joining your party trigger a popup notification.")
	addSpacer(2)

	addHeader(2, "Player Detection")
	addLine(2, "Hover over a player to see the MM icon in their tooltip if they have the addon.")
	addLine(2, "Target an addon user and a small button appears — click to view their table.")
	addLine(2, "Drag the button to reposition it. Click again to close their table. X to dismiss.")
	addSpacer(2)

	addHeader(2, "Themes & Options")
	addLine(2, "Colour themes, sharing, notifications, and data reset — all in Options (cog icon).")

	-- Version at bottom
	local bottomY = math.min(yLeft, yRight) - 8
	local ver = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	ver:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, bottomY)
	local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	ver:SetText("v" .. (getMetadata and getMetadata("MythicMemories", "Version") or "?"))
	ver:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
	bottomY = bottomY - 14

	panel:SetHeight(math.abs(bottomY) + PAD)

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
		self:HideAllPopups()
		self.helpPanel:Show()
		if self.helpLabel then
			self.helpLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		end
	end
end

-- ── Remote MVP context menu (right-click a bubble in remote view) ──

function MPT:ShowRemoteMvpContextMenu(nameRealm, class, data)
	self:HideAllPopups()

	local normalized = self:NormalizeNameRealm(nameRealm)
	local alreadyLocal = self.db.global.mvps[normalized]

	local menuHeight = alreadyLocal and 26 or 48
	local menu = CreateFrame("Frame", nil, self.mainFrame)
	menu:SetSize(190, menuHeight)
	menu:SetFrameStrata("TOOLTIP")

	local bg = menu:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local function createMenuBtn(yOffset, label, textColor, onClick, disabled)
		local btn = CreateFrame("Button", nil, menu)
		btn:SetHeight(22)
		btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, yOffset)
		btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, yOffset)
		local btnText = btn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		btnText:SetPoint("LEFT", 10, 0)
		btnText:SetText(label)
		if disabled then
			btnText:SetTextColor(0.5, 0.5, 0.5)
		else
			btnText:SetTextColor(textColor[1], textColor[2], textColor[3])
		end
		local btnBg = btn:CreateTexture(nil, "BACKGROUND")
		btnBg:SetAllPoints()
		btnBg:SetColorTexture(0, 0, 0, 0)
		if not disabled then
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
		end
		return btn
	end

	if alreadyLocal then
		createMenuBtn(-2, "Already in your list", C.textMuted, nil, true)
	else
		local remoteNote = data and data.note or nil
		createMenuBtn(-2, "Add to my MVPs", C.textPrimary, function()
			self:AddMvp(normalized, UnitName("player"), class, remoteNote)
			self:OnMvpChanged()
			self:Print(nameRealm .. " added to your MVP list.")
		end)
		createMenuBtn(-24, "Add + Edit Note", C.textPrimary, function()
			self:AddMvp(normalized, UnitName("player"), class, remoteNote)
			self:OnMvpChanged()
			self:ShowNotePopup(normalized, nil, class)
		end)
	end

	-- Position at cursor
	local scale = UIParent:GetEffectiveScale()
	local x, y = GetCursorPosition()
	menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	menu:Show()

	self.remoteMvpContextMenu = menu

	-- Close on next click elsewhere
	menu:SetScript("OnUpdate", function(self)
		if not self:IsMouseOver() and IsMouseButtonDown("LeftButton") then
			self:Hide()
		end
	end)
end

-- ── Row context menu ────────────────────────────────────────────

function MPT:ShowRowContextMenu(row)
	if not row.runData then return end
	if self:IsViewingRemote() then return end
	self:HideAllPopups()

	local runId = row.runData.id
	-- Calculate menu height: 2 base items + optional Move to Table
	local tables = self:GetTableList()
	local showMoveItem = #tables > 1
	local menuHeight = showMoveItem and 70 or 48

	local menu = CreateFrame("Frame", nil, self.mainFrame)
	menu:SetSize(160, menuHeight)
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

	-- "Move to Table" submenu (only in local mode with multiple tables)
	local deleteYOffset = showMoveItem and -46 or -24
	if showMoveItem then
		local moveBtn = CreateFrame("Button", nil, menu)
		moveBtn:SetHeight(22)
		moveBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -24)
		moveBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, -24)
		local moveText = moveBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		moveText:SetPoint("LEFT", 10, 0)
		moveText:SetText("Move to Table  >")
		moveText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		local moveBg = moveBtn:CreateTexture(nil, "BACKGROUND")
		moveBg:SetAllPoints()
		moveBg:SetColorTexture(0, 0, 0, 0)

		local viewedIdx = self:GetViewedTableIndex()

		moveBtn:SetScript("OnEnter", function()
			moveBg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.15)
			-- Show submenu
			if MPT.moveSubmenu then MPT.moveSubmenu:Hide() end
			local targets = {}
			for _, t in ipairs(tables) do
				if t.index ~= viewedIdx then
					targets[#targets + 1] = t
				end
			end
			local sub = CreateFrame("Frame", nil, menu)
			sub:SetSize(150, #targets * 22 + 4)
			sub:SetPoint("TOPLEFT", moveBtn, "TOPRIGHT", 0, 2)
			sub:SetFrameStrata("TOOLTIP")
			local subBg = sub:CreateTexture(nil, "BACKGROUND")
			subBg:SetAllPoints()
			subBg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)
			for si, t in ipairs(targets) do
				local sbtn = CreateFrame("Button", nil, sub)
				sbtn:SetHeight(22)
				sbtn:SetPoint("TOPLEFT", sub, "TOPLEFT", 0, -(si - 1) * 22 - 2)
				sbtn:SetPoint("RIGHT", sub, "RIGHT", 0, 0)
				local sText = sbtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
				sText:SetPoint("LEFT", 10, 0)
				sText:SetText(t.name)
				sText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
				local sBg = sbtn:CreateTexture(nil, "BACKGROUND")
				sBg:SetAllPoints()
				sBg:SetColorTexture(0, 0, 0, 0)
				sbtn:SetScript("OnEnter", function()
					sBg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.15)
				end)
				sbtn:SetScript("OnLeave", function()
					sBg:SetColorTexture(0, 0, 0, 0)
				end)
				sbtn:SetScript("OnClick", function()
					MPT:MoveRunToTable(runId, t.index)
					menu:Hide()
					if MPT.moveSubmenu then MPT.moveSubmenu:Hide() end
					MPT:RefreshTable()
				end)
			end
			sub:Show()
			MPT.moveSubmenu = sub
		end)
		moveBtn:SetScript("OnLeave", function()
			-- Don't hide submenu on leave — let user mouse into it
			if MPT.moveSubmenu and not MPT.moveSubmenu:IsMouseOver() then
				moveBg:SetColorTexture(0, 0, 0, 0)
			end
		end)
	end

	createMenuBtn(deleteYOffset, "Delete Run", {C.dangerText[1], C.dangerText[2], C.dangerText[3]}, function()
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
		local overMenu = self:IsMouseOver()
		local overSub = MPT.moveSubmenu and MPT.moveSubmenu:IsShown() and MPT.moveSubmenu:IsMouseOver()
		if not overMenu and not overSub and IsMouseButtonDown("LeftButton") then
			if MPT.moveSubmenu then MPT.moveSubmenu:Hide() end
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
		text:SetTextColor(C.textNeutral[1], C.textNeutral[2], C.textNeutral[3])
		dialog.text = text

		local yesBtn = self:CreateModernButton(dialog, 100, 26, "Yes, Delete")
		yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 14)
		yesBtn.label:SetTextColor(C.dangerText[1], C.dangerText[2], C.dangerText[3])
		yesBtn:SetScript("OnEnter", function(self)
			self.bg:SetColorTexture(C.dangerBg[1], C.dangerBg[2], C.dangerBg[3], 1)
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
		self.favToggleIcon:SetVertexColor(1, 0.85, 0)    -- fixed gold
	else
		self.favToggleIcon:SetDesaturated(true)
		self.favToggleIcon:SetVertexColor(0.5, 0.5, 0.5)    -- fixed muted grey
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

	-- Sync player/realm from popup to filter bar (including clears)
	local popupPlayer = p.playerBox:GetText()
	local popupRealm = p.realmBox:GetText()
	if self.filterPlayerBox then
		self.filterPlayerBox:SetText(popupPlayer)
	end
	if self.filterRealmBox then
		self.filterRealmBox:SetText(popupRealm)
	end

	self:ApplyFilters()
	self.filterPopup:Hide()
end

function MPT:ToggleFilterPopup()
	if not self.filterPopup then
		self:CreateFilterPopup()
	end

	if self.filterPopup:IsShown() then
		self.filterPopup:Hide()
		if self.filterBtn then
			self.filterBtn.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			self.filterBtn.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
	else
		self:HideAllPopups()
		self:PopulateFilterDropdowns()
		self.filterPopup:Show()
		if self.filterBtn then
			self.filterBtn.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
			self.filterBtn.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		end
	end
end

-- ── MVP join notification ────────────────────────────────────────

function MPT:CreateNotificationFrame()
	if self.notifFrame then return self.notifFrame end

	local f = CreateFrame("Frame", "MPTNotification", UIParent)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)

	-- Restore saved position
	local pos = self.db.global.notificationPos
	if pos then
		f:SetPoint(pos.point or "TOP", UIParent, pos.point or "TOP", pos.x or 0, pos.y or -200)
	else
		f:SetPoint("TOP", UIParent, "TOP", 0, -200)
	end

	-- Background
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 0.95)

	-- Timer bar (gold line at top, shrinks over time)
	local timerBar = f:CreateTexture(nil, "ARTWORK")
	timerBar:SetHeight(2)
	timerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	timerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	timerBar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.8)
	f.timerBar = timerBar

	-- Content container
	f.lines = {}
	f:SetWidth(260)
	f:EnableMouse(true)

	-- Always draggable — save position on drop
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint(1)
		MPT.db.global.notificationPos = { point = point, x = x, y = y }
	end)

	-- Hover: pause timer bar and fade
	f:SetScript("OnEnter", function()
		if f.fadeTimer then f.fadeTimer:Cancel() end
		f:SetScript("OnUpdate", nil)
		f:SetAlpha(1)
		-- Reset bar to full
		f.timerBar:ClearAllPoints()
		f.timerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		f.timerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	end)
	f:SetScript("OnLeave", function()
		MPT:StartNotificationTimer()
	end)

	f:Hide()
	self.notifFrame = f
	return f
end

function MPT:ShowMvpJoinNotification(mvpList)
	local f = self:CreateNotificationFrame()

	-- Cancel any existing timer/fade
	if f.fadeTimer then f.fadeTimer:Cancel() end
	f:SetAlpha(1)

	-- Clear old lines
	for _, line in ipairs(f.lines) do
		line:Hide()
	end

	local PADDING = 10
	local yOff = -PADDING - 2  -- below top accent line

	-- Header: crown icon + "MVP joined"
	local headerText = #mvpList == 1 and "MVP joined" or "MVPs joined"
	local header = f.lines[1]
	if not header then
		header = f:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
		f.lines[1] = header
	end
	header:ClearAllPoints()
	header:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING + 2, yOff)
	header:SetText(headerText)
	header:SetTextColor(1, 0.85, 0)
	header:Show()
	yOff = yOff - 16

	local lineIdx = 2
	for _, mvp in ipairs(mvpList) do
		-- Name line (class colored)
		local nameLine = f.lines[lineIdx]
		if not nameLine then
			nameLine = f:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
			f.lines[lineIdx] = nameLine
		end
		nameLine:ClearAllPoints()
		nameLine:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING + 4, yOff)
		nameLine:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
		nameLine:SetJustifyH("LEFT")

		nameLine:SetText(mvp.name)
		local cr, cg, cb = self:GetClassColor(mvp.class)
		nameLine:SetTextColor(cr, cg, cb)
		nameLine:Show()
		lineIdx = lineIdx + 1
		yOff = yOff - 15

		-- Note line (if exists)
		if mvp.note and mvp.note ~= "" then
			local noteLine = f.lines[lineIdx]
			if not noteLine then
				noteLine = f:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
				f.lines[lineIdx] = noteLine
			end
			noteLine:ClearAllPoints()
			noteLine:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING + 8, yOff)
			noteLine:SetPoint("RIGHT", f, "RIGHT", -PADDING, 0)
			noteLine:SetJustifyH("LEFT")
			noteLine:SetWordWrap(true)
			noteLine:SetText(mvp.note)
			noteLine:SetTextColor(NOTE_TEXT[1], NOTE_TEXT[2], NOTE_TEXT[3])
			noteLine:Show()
			lineIdx = lineIdx + 1
			local noteHeight = noteLine:GetStringHeight() or 12
			yOff = yOff - noteHeight - 2
		end

		yOff = yOff - 4  -- spacing between MVPs
	end

	f:SetHeight(math.abs(yOff) + PADDING)
	f:Show()

	-- Play subtle sound (if enabled)
	if self.db.global.mvpSound ~= false then
		PlaySound(SOUNDKIT.IG_PLAYER_INVITE)
	end

	-- Start dismiss timer
	self:StartNotificationTimer()
end

local NOTIF_TIMER_DURATION = 6
local NOTIF_FADE_DURATION = 1.5

function MPT:StartNotificationTimer()
	local f = self.notifFrame
	if not f then return end

	if f.fadeTimer then f.fadeTimer:Cancel() end

	-- Animate the timer bar shrinking from right to left
	local barElapsed = 0
	f.timerBar:ClearAllPoints()
	f.timerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	f.timerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

	f:SetScript("OnUpdate", function(self, dt)
		barElapsed = barElapsed + dt

		if barElapsed <= NOTIF_TIMER_DURATION then
			-- Shrink the bar
			local pct = 1 - (barElapsed / NOTIF_TIMER_DURATION)
			local barWidth = f:GetWidth() * pct
			f.timerBar:ClearAllPoints()
			f.timerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
			f.timerBar:SetWidth(math.max(barWidth, 0.1))
		else
			-- Fade out
			local fadeElapsed = barElapsed - NOTIF_TIMER_DURATION
			local alpha = 1 - (fadeElapsed / NOTIF_FADE_DURATION)
			if alpha <= 0 then
				self:Hide()
				self:SetAlpha(1)
				self:SetScript("OnUpdate", nil)
			else
				self:SetAlpha(alpha)
			end
		end
	end)
end

-- ── Options panel ────────────────────────────────────────────────

function MPT:CreateOptionsPanel()
	if self.optionsPanel then return end

	local panel = CreateFrame("Frame", "MPTOptionsPanel", self.mainFrame)
	panel:SetSize(220, 264)
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

	-- MVP Notifications checkbox
	local notifCheck = self:CreateModernCheckbox(panel, "MVP Join Alerts")
	notifCheck:SetPoint("TOPLEFT", shareCheck, "BOTTOMLEFT", 0, -6)
	notifCheck._onToggle = function(val)
		MPT.db.global.mvpNotifications = val
	end
	panel.notifCheck = notifCheck

	-- Notification Sound checkbox
	local soundCheck = self:CreateModernCheckbox(panel, "Notification Sound")
	soundCheck:SetPoint("TOPLEFT", notifCheck, "BOTTOMLEFT", 0, -6)
	soundCheck._onToggle = function(val)
		MPT.db.global.mvpSound = val
	end
	panel.soundCheck = soundCheck

	-- Theme divider
	local themeDiv = panel:CreateTexture(nil, "ARTWORK")
	themeDiv:SetHeight(1)
	themeDiv:SetPoint("TOPLEFT", soundCheck, "BOTTOMLEFT", -2, -10)
	themeDiv:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
	themeDiv:SetColorTexture(C.divider[1], C.divider[2], C.divider[3], 1)

	-- Theme label
	local themeLabel = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
	themeLabel:SetPoint("TOPLEFT", themeDiv, "BOTTOMLEFT", 2, -8)
	themeLabel:SetText("Theme")

	-- Theme dropdown (custom, matches filter dropdowns)
	local themeDD = self:CreateDropdown(panel, 190, "Coffee")
	themeDD._noDefault = true
	themeDD:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -4)

	-- Build items from THEME_LIST
	local themeItems = {}
	local currentThemeName = "Coffee"
	for _, entry in ipairs(THEME_LIST) do
		themeItems[#themeItems + 1] = { value = entry.key, display = entry.name }
		if entry.key == (self.db.global.theme or "coffee") then
			currentThemeName = entry.name
		end
	end
	themeDD:SetItems(themeItems)
	themeDD:SetValue(self.db.global.theme or "coffee", currentThemeName)
	themeDD._onSelect = function(value, display)
		MPT:ApplyTheme(value)
	end
	panel.themeDD = themeDD

	-- Divider before reset
	local div = panel:CreateTexture(nil, "ARTWORK")
	div:SetHeight(1)
	div:SetPoint("TOPLEFT", themeDD, "BOTTOMLEFT", 0, -10)
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
	resetBtn.label:SetTextColor(C.dangerText[1], C.dangerText[2], C.dangerText[3])
	resetBtn:SetScript("OnClick", function()
		local runs = panel.resetRunsCheck:GetChecked()
		local mvps = panel.resetMvpsCheck:GetChecked()
		if runs or mvps then
			MPT:ShowResetConfirmDialog(runs, mvps)
		end
	end)
	resetBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(C.dangerBg[1], C.dangerBg[2], C.dangerBg[3], 1)
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
		self:HideAllPopups()
		self.optionsPanel.shareCheck:SetChecked(self.db.global.shareTable)
		self.optionsPanel.notifCheck:SetChecked(self.db.global.mvpNotifications ~= false)
		self.optionsPanel.soundCheck:SetChecked(self.db.global.mvpSound ~= false)
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
		yesBtn.label:SetTextColor(C.dangerText[1], C.dangerText[2], C.dangerText[3])
		yesBtn:SetScript("OnEnter", function(self)
			self.bg:SetColorTexture(C.dangerBg[1], C.dangerBg[2], C.dangerBg[3], 1)
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

-- ── Table name in title bar ───────────────────────────────────
function MPT:UpdateTableNameInTitle()
	if self.tableNameLabel then
		self.tableNameLabel:SetText("(" .. self:GetViewedTableName() .. ")")
	end
end

-- ── Table Manager panel ──────────────────────────────────────

function MPT:ToggleTableManagerPanel()
	if self.tableManagerPanel and self.tableManagerPanel:IsShown() then
		self.tableManagerPanel:Hide()
		if self.tableBtn then
			self.tableBtn.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			self.tableBtn.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
		return
	end
	self:HideAllPopups()
	self:CreateTableManagerPanel()
	self:RefreshTableManagerList()
	self.tableManagerPanel:Show()
	if self.tableBtn then
		self.tableBtn.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.tableBtn.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end
end

function MPT:CreateTableManagerPanel()
	if self.tableManagerPanel then return end

	local panel = CreateFrame("Frame", "MPTTableManagerPanel", self.mainFrame)
	panel:SetSize(260, 300)
	panel:SetPoint("TOPLEFT", self.tableBtn, "BOTTOMLEFT", 0, -4)
	panel:SetFrameStrata("DIALOG")

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local border = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)

	local titleText = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
	titleText:SetPoint("TOPLEFT", 12, -10)
	titleText:SetText("Tables")

	-- List container
	local listContainer = CreateFrame("Frame", nil, panel)
	listContainer:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
	listContainer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 44)
	listContainer:SetClipsChildren(true)
	panel.listContainer = listContainer

	-- New table input at bottom (plain EditBox, no WoW template)
	local newInputContainer = CreateFrame("Frame", "MPTNewTableInput", panel)
	newInputContainer:SetSize(170, 22)
	newInputContainer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 12)
	local newInputBg = newInputContainer:CreateTexture(nil, "BACKGROUND")
	newInputBg:SetAllPoints()
	newInputBg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)

	local newInput = CreateFrame("EditBox", nil, newInputContainer)
	newInput:SetAllPoints()
	newInput:SetAutoFocus(false)
	newInput:SetFontObject(MPTFont_Cell)
	newInput:SetMaxLetters(40)
	newInput:SetTextInsets(6, 6, 0, 0)

	local addBtn = self:CreateModernButton(panel, 55, 22, "+ New")
	addBtn:SetPoint("LEFT", newInputContainer, "RIGHT", 6, 0)
	addBtn:SetScript("OnClick", function()
		local name = newInput:GetText()
		if name and name:trim() ~= "" then
			MPT:CreateTable(name:trim())
			newInput:SetText("")
			MPT:RefreshTableManagerList()
		end
	end)
	newInput:SetScript("OnEnterPressed", function(self)
		local name = self:GetText()
		if name and name:trim() ~= "" then
			MPT:CreateTable(name:trim())
			self:SetText("")
			MPT:RefreshTableManagerList()
		end
		self:ClearFocus()
	end)
	newInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	panel:Hide()
	self.tableManagerPanel = panel
end

function MPT:RefreshTableManagerList()
	if not self.tableManagerPanel then return end
	local container = self.tableManagerPanel.listContainer
	if not container then return end

	-- Clear existing rows
	if self.tableManagerRows then
		for _, row in ipairs(self.tableManagerRows) do
			row:Hide()
			row:SetParent(nil)
		end
	end
	self.tableManagerRows = {}

	local tables = self.db.global.tables
	local activeIdx = self:GetActiveTableIndex()
	local viewedIdx = self:GetViewedTableIndex()
	local charActiveMap = self:GetCharActiveMap()
	local ROW_H = 30

	for i, tbl in ipairs(tables) do
		local row = CreateFrame("Button", nil, container)
		row:SetHeight(ROW_H)
		row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(i - 1) * ROW_H)
		row:SetPoint("RIGHT", container, "RIGHT", 0, 0)

		local rowBg = row:CreateTexture(nil, "BACKGROUND")
		rowBg:SetAllPoints()
		local isActive = (i == activeIdx)
		local isViewed = (i == viewedIdx)

		-- Viewed table gets highlight background
		if isViewed then
			rowBg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.15)
		else
			rowBg:SetColorTexture(0, 0, 0, 0)
		end
		row.rowBg = rowBg
		row._isViewed = isViewed

		-- Active indicator (gold dot — marks where THIS character's runs go)
		local dot = row:CreateTexture(nil, "ARTWORK")
		dot:SetSize(8, 8)
		dot:SetPoint("LEFT", row, "LEFT", 6, 0)
		dot:SetColorTexture(1, 0.85, 0)
		if not isActive then dot:Hide() end
		row.dot = dot

		-- Table name
		local nameText = row:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		nameText:SetPoint("LEFT", row, "LEFT", 20, 0)
		nameText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
		nameText:SetJustifyH("LEFT")
		nameText:SetText(tbl.name)
		if isViewed then
			nameText:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		else
			nameText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
		row.nameText = nameText

		local charNames = charActiveMap[i]

		-- Run count
		local countText = row:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
		countText:SetPoint("RIGHT", row, "RIGHT", -28, 0)
		countText:SetText(#tbl.runs)
		countText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

		-- Delete button (hidden for last table)
		local delBtn = CreateFrame("Button", nil, row)
		delBtn:SetSize(18, 18)
		delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		local delText = delBtn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		delText:SetPoint("CENTER")
		delText:SetText("X")
		delText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		delBtn:SetScript("OnEnter", function()
			delText:SetTextColor(C.dangerHover[1], C.dangerHover[2], C.dangerHover[3])
		end)
		delBtn:SetScript("OnLeave", function()
			delText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		end)
		local tableIndex = i
		delBtn:SetScript("OnClick", function()
			MPT:ShowDeleteTableConfirm(tableIndex, tbl.name, #tbl.runs)
		end)
		if #tables <= 1 then delBtn:Hide() end

		-- Hover: show tooltip with character assignments in class colors
		row:SetScript("OnEnter", function()
			if not row._isViewed then
				rowBg:SetColorTexture(C.highlight[1], C.highlight[2], C.highlight[3], 0.10)
			end
			if charNames and #charNames > 0 then
				GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
				GameTooltip:AddLine(tbl.name, C.accent[1], C.accent[2], C.accent[3])
				GameTooltip:AddLine("Active on:", C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
				for _, info in ipairs(charNames) do
					local r, g, b = MPT:GetClassColor(info.class)
					GameTooltip:AddLine("  " .. info.name, r, g, b)
				end
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", function()
			if not row._isViewed then
				rowBg:SetColorTexture(0, 0, 0, 0)
			end
			GameTooltip:Hide()
		end)

		-- Left-click to view table, right-click for context menu
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		row:SetScript("OnClick", function(_, button)
			if button == "RightButton" then
				MPT:ShowTableRowContextMenu(row, tableIndex, tbl.name)
			else
				MPT:ViewTable(tableIndex)
				MPT:RefreshTableManagerList()
			end
		end)

		self.tableManagerRows[#self.tableManagerRows + 1] = row
	end
end

function MPT:ShowTableRowContextMenu(anchor, tableIndex, tableName)
	if self.tableRowContextMenu then
		self.tableRowContextMenu:Hide()
	end

	local isAlreadyActive = (tableIndex == self:GetActiveTableIndex())
	local numTables = #self.db.global.tables
	local canMoveUp = tableIndex > 1
	local canMoveDown = tableIndex < numTables

	-- Calculate menu height based on visible options
	local itemCount = 1 -- Rename is always shown
	if not isAlreadyActive then itemCount = itemCount + 1 end
	if canMoveUp then itemCount = itemCount + 1 end
	if canMoveDown then itemCount = itemCount + 1 end
	local menuHeight = itemCount * 22 + 4

	local menu = CreateFrame("Frame", nil, self.mainFrame)
	menu:SetSize(140, menuHeight)
	menu:SetFrameStrata("TOOLTIP")

	local bg = menu:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local yOff = -2
	local function createCtxBtn(label, textColor, onClick)
		local btn = CreateFrame("Button", nil, menu)
		btn:SetHeight(22)
		btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, yOff)
		btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", 0, yOff)
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
		yOff = yOff - 22
		return btn
	end

	if not isAlreadyActive then
		createCtxBtn("Set Active", C.textPrimary, function()
			MPT:SetActiveTable(tableIndex)
			MPT:RefreshTableManagerList()
		end)
	end

	createCtxBtn("Rename", C.textPrimary, function()
		MPT:StartInlineRename(tableIndex)
	end)

	if canMoveUp then
		createCtxBtn("Move Up", C.textMuted, function()
			MPT:SwapTables(tableIndex, tableIndex - 1)
			MPT:RefreshTableManagerList()
		end)
	end

	if canMoveDown then
		createCtxBtn("Move Down", C.textMuted, function()
			MPT:SwapTables(tableIndex, tableIndex + 1)
			MPT:RefreshTableManagerList()
		end)
	end

	local scale = UIParent:GetEffectiveScale()
	local x, y = GetCursorPosition()
	menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
	menu:Show()
	self.tableRowContextMenu = menu

	menu:SetScript("OnUpdate", function(self)
		if not self:IsMouseOver() and IsMouseButtonDown("LeftButton") then
			self:Hide()
		end
	end)
end

function MPT:StartInlineRename(tableIndex)
	if not self.tableManagerRows or not self.tableManagerRows[tableIndex] then return end
	local row = self.tableManagerRows[tableIndex]
	local tbl = self.db.global.tables[tableIndex]
	if not tbl then return end

	row.nameText:Hide()

	local edit = CreateFrame("EditBox", nil, row)
	edit:SetSize(row.nameText:GetWidth(), 20)
	edit:SetPoint("LEFT", row, "LEFT", 20, 0)
	edit:SetFontObject(MPTFont_Cell)
	edit:SetAutoFocus(true)
	edit:SetText(tbl.name)
	edit:HighlightText()
	edit:SetMaxLetters(40)

	local editBg = edit:CreateTexture(nil, "BACKGROUND")
	editBg:SetAllPoints()
	editBg:SetColorTexture(C.inputBg[1], C.inputBg[2], C.inputBg[3], 1)

	local function finishRename()
		edit:SetScript("OnEditFocusLost", nil)
		local newName = edit:GetText()
		if newName and newName:trim() ~= "" then
			MPT:RenameTable(tableIndex, newName:trim())
			MPT:UpdateTableNameInTitle()
		end
		edit:Hide()
		edit:SetParent(nil)
		row.nameText:Show()
		MPT:RefreshTableManagerList()
	end

	edit:SetScript("OnEnterPressed", finishRename)
	edit:SetScript("OnEscapePressed", function()
		edit:Hide()
		edit:SetParent(nil)
		row.nameText:Show()
	end)
	edit:SetScript("OnEditFocusLost", finishRename)
end

function MPT:ShowDeleteTableConfirm(tableIndex, tableName, runCount)
	if self.deleteTableDialog then
		self.deleteTableDialog:Hide()
	end

	local dialog = CreateFrame("Frame", "MPTDeleteTableDialog", self.mainFrame)
	dialog:SetSize(300, 120)
	dialog:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")

	local bg = dialog:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	local border = dialog:CreateTexture(nil, "BACKGROUND", nil, 1)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)

	local msg = dialog:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	msg:SetPoint("TOP", dialog, "TOP", 0, -16)
	msg:SetWidth(260)
	msg:SetText("Delete table '" .. tableName .. "'?\n" .. runCount .. " run(s) will be permanently lost.")
	msg:SetTextColor(C.textNeutral[1], C.textNeutral[2], C.textNeutral[3])

	local yesBtn = self:CreateModernButton(dialog, 80, 24, "Delete")
	yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 14)
	yesBtn.bg:SetColorTexture(C.dangerBg[1], C.dangerBg[2], C.dangerBg[3], 1)
	yesBtn.label:SetTextColor(C.dangerText[1], C.dangerText[2], C.dangerText[3])
	yesBtn:SetScript("OnClick", function()
		MPT:DeleteTable(tableIndex)
		dialog:Hide()
		MPT:UpdateTableNameInTitle()
		MPT:RefreshTable()
		MPT:RefreshTableManagerList()
	end)

	local noBtn = self:CreateModernButton(dialog, 80, 24, "Cancel")
	noBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 14)
	noBtn:SetScript("OnClick", function()
		dialog:Hide()
	end)

	dialog:Show()
	self.deleteTableDialog = dialog
end

-- ── Remote table loading indicator ───────────────────────────

function MPT:ShowRemoteTableLoading()
	if not self.tableCard then return end
	if not self.loadingFrame then
		local f = CreateFrame("Frame", nil, self.tableCard)
		f:SetAllPoints()
		f:SetFrameLevel(self.tableCard:GetFrameLevel() + 10)
		local lbg = f:CreateTexture(nil, "BACKGROUND")
		lbg:SetAllPoints()
		lbg:SetColorTexture(C.contentBg[1], C.contentBg[2], C.contentBg[3], 0.85)
		local text = f:CreateFontString(nil, "OVERLAY", "MPTFont_Title")
		text:SetPoint("CENTER")
		text:SetText("Loading...")
		text:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		f._text = text
		f._dots = 0
		f:SetScript("OnUpdate", function(self, elapsed)
			self._timer = (self._timer or 0) + elapsed
			if self._timer > 0.5 then
				self._timer = 0
				self._dots = (self._dots + 1) % 4
				self._text:SetText("Loading" .. string.rep(".", self._dots))
			end
		end)
		self.loadingFrame = f
	end
	self.loadingFrame:Show()
end

function MPT:HideRemoteTableLoading()
	if self.loadingFrame then self.loadingFrame:Hide() end
end

-- ── Remote table dropdown in view mode ───────────────────────

function MPT:UpdateRemoteTableDropdown()
	if not self.remoteTableDD or not self.remoteTableList then return end
	-- Rebuild dropdown items
	self.remoteTableDD._items = self.remoteTableList
	-- Update display to show first table name if current isn't set
end

function MPT:CreateRemoteTableDropdown()
	if self.remoteTableDD then return end

	local dd = CreateFrame("Button", nil, self.viewTitleFrame)
	dd:SetSize(140, 22)
	dd:SetPoint("RIGHT", self.viewTitleFrame, "RIGHT", -60, 4)

	local ddBg = dd:CreateTexture(nil, "BACKGROUND")
	ddBg:SetAllPoints()
	ddBg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
	dd._bg = ddBg

	local ddText = dd:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	ddText:SetPoint("LEFT", 8, 0)
	ddText:SetPoint("RIGHT", -16, 0)
	ddText:SetJustifyH("LEFT")
	ddText:SetText("Select Table")
	ddText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
	dd._text = ddText

	local arrow = dd:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	arrow:SetPoint("RIGHT", dd, "RIGHT", -4, 0)
	arrow:SetText("v")
	arrow:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

	dd:SetScript("OnEnter", function()
		ddBg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
	end)
	dd:SetScript("OnLeave", function()
		ddBg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
	end)
	dd:SetScript("OnClick", function()
		MPT:ToggleRemoteTableList()
	end)

	dd._items = {}
	dd:Hide()
	self.remoteTableDD = dd
end

function MPT:ToggleRemoteTableList()
	if self.remoteTableListFrame and self.remoteTableListFrame:IsShown() then
		self.remoteTableListFrame:Hide()
		return
	end

	if not self.remoteTableDD or not self.remoteTableList or #self.remoteTableList == 0 then
		return
	end

	if self.remoteTableListFrame then
		self.remoteTableListFrame:Hide()
		self.remoteTableListFrame:SetParent(nil)
	end

	local items = self.remoteTableList
	local itemH = 22
	local listFrame = CreateFrame("Frame", nil, self.remoteTableDD)
	listFrame:SetSize(140, #items * itemH + 4)
	listFrame:SetPoint("TOPLEFT", self.remoteTableDD, "BOTTOMLEFT", 0, -2)
	listFrame:SetFrameStrata("TOOLTIP")

	local lbg = listFrame:CreateTexture(nil, "BACKGROUND")
	lbg:SetAllPoints()
	lbg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	for idx, tableName in ipairs(items) do
		local btn = CreateFrame("Button", nil, listFrame)
		btn:SetHeight(itemH)
		btn:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -(idx - 1) * itemH - 2)
		btn:SetPoint("RIGHT", listFrame, "RIGHT", 0, 0)

		local btnText = btn:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		btnText:SetPoint("LEFT", 10, 0)
		btnText:SetText(tableName)
		btnText:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])

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
			listFrame:Hide()
			self.remoteTableDD._text:SetText(tableName)
			-- Request this specific table from the remote player
			local name, realm = MPT.viewingPlayer:match("^([^%-]+)%-?(.*)$")
			MPT:RequestTable(name, realm, tableName)
		end)
	end

	listFrame:Show()
	self.remoteTableListFrame = listFrame

	listFrame:SetScript("OnUpdate", function(self)
		if not self:IsMouseOver() and not MPT.remoteTableDD:IsMouseOver() and IsMouseButtonDown("LeftButton") then
			self:Hide()
		end
	end)
end

function MPT:UpdateViewModeUI()
	if not self.mainFrame then return end

	local isViewing = self:IsViewingRemote()

	if isViewing then
		local displayName = self.viewingPlayer or "Unknown"
		local shortName = displayName:match("^([^%-]+)") or displayName
		-- Look up class: sender's class from payload, then party units, then run data, then MVP lists
		local viewClass = self.viewingData and self.viewingData.senderClass or nil
		-- 1) Scan party for the player (they're likely in our group)
		for _, unit in ipairs({ "party1", "party2", "party3", "party4" }) do
			if UnitExists(unit) then
				local uName = UnitName(unit)
				if uName == shortName then
					local _, cls = UnitClass(unit)
					viewClass = cls
					break
				end
			end
		end
		-- 2) Search shared run members
		if not viewClass and self.viewingData and self.viewingData.runs then
			for _, run in ipairs(self.viewingData.runs) do
				for _, m in ipairs(run.members or {}) do
					if m.name == shortName and m.class then
						viewClass = m.class
						break
					end
				end
				if viewClass then break end
			end
		end
		-- 3) Check local MVP list
		if not viewClass then
			local matched = self:MatchMvpName(displayName) or self:MatchMvpName(shortName)
			if matched and self.db.global.mvps[matched] then
				viewClass = self.db.global.mvps[matched].class
			end
		end
		-- 4) Check remote player's own MVP list
		if not viewClass and self.viewingData and self.viewingData.mvps then
			for nameRealm, data in pairs(self.viewingData.mvps) do
				if nameRealm:match("^([^%-]+)") == shortName and data.class then
					viewClass = data.class
					break
				end
			end
		end
		self.viewingClass = viewClass
		local r, g, b = self:GetClassColor(viewClass)
		local hex = string.format("|cFF%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
		local goldHex = string.format("|cFF%02x%02x%02x", math.floor(C.accent[1] * 255), math.floor(C.accent[2] * 255), math.floor(C.accent[3] * 255))
		-- Create a view title overlay frame (renders above MVP panel)
		if not self.viewTitleFrame then
			local vtf = CreateFrame("Frame", nil, self.mainFrame)
			vtf:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, 0)
			vtf:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", 0, 0)
			vtf:SetHeight(32)
			vtf:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
			self.viewTitle = vtf:CreateFontString(nil, "OVERLAY")
			self.viewTitle:SetFont(FONT_FILE, 14, "")
			self.viewTitle:SetPoint("CENTER", vtf, "CENTER", 0, 4)
			-- Crown frame for MVP (anchored left of title text, interactive for tooltip)
			local crownFrame = CreateFrame("Frame", nil, vtf)
			crownFrame:SetSize(24, 24)
			crownFrame:SetPoint("RIGHT", self.viewTitle, "LEFT", -4, 0)
			crownFrame:SetFrameLevel(vtf:GetFrameLevel() + 2)
			crownFrame:EnableMouse(true)
			local crownIcon = crownFrame:CreateTexture(nil, "OVERLAY")
			crownIcon:SetAllPoints()
			crownIcon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
			crownIcon:SetVertexColor(1, 0.85, 0)
			crownFrame.icon = crownIcon
			crownFrame:SetScript("OnEnter", function(self)
				if self.tooltipLines then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					for _, line in ipairs(self.tooltipLines) do
						GameTooltip:AddLine(line.text, line.r, line.g, line.b, line.wrap)
					end
					GameTooltip:Show()
				end
			end)
			crownFrame:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			crownFrame:Hide()
			self.viewTitleCrown = crownFrame
			self.viewTitleFrame = vtf
		end
		self.viewTitle:SetTextColor(1, 1, 1)
		self.viewTitle:SetText(hex .. shortName .. "'s |r" .. goldHex .. "Table|r")
		-- Crown color coding: gold (mine), blue (party's), green (both)
		local inLocal = self:MatchMvpName(displayName) or self:MatchMvpName(shortName)
		local vouches = self:CheckPartyMvp(displayName)
		if #vouches == 0 then
			vouches = self:CheckPartyMvp(shortName)
		end
		local vouchedBy = vouches[1] and vouches[1].sender or nil
		local crown = self.viewTitleCrown
		if inLocal or vouchedBy then
			local tooltipLines = {}
			if inLocal and vouchedBy then
				crown.icon:SetDesaturated(true)
				crown.icon:SetVertexColor(0.2, 1, 0.2)
				local names = {}
				for _, v in ipairs(vouches) do names[#names + 1] = MPT:StripRealm(v.sender) end
				table.insert(tooltipLines, { text = "MVP \226\128\148 in your list and " .. table.concat(names, ", ") .. "'s list", r = 0.2, g = 1, b = 0.2 })
			elseif inLocal then
				crown.icon:SetDesaturated(false)
				crown.icon:SetVertexColor(1, 0.85, 0)
				table.insert(tooltipLines, { text = "MVP", r = 1, g = 0.85, b = 0 })
			else
				crown.icon:SetDesaturated(true)
				crown.icon:SetVertexColor(0.3, 0.7, 1)
				local names = {}
				for _, v in ipairs(vouches) do names[#names + 1] = MPT:StripRealm(v.sender) end
				table.insert(tooltipLines, { text = "MVP \226\128\148 vouched by " .. table.concat(names, ", "), r = 0.3, g = 0.7, b = 1 })
			end
			-- Local note
			if inLocal then
				local note = self:GetMvpNote(inLocal)
				if note and note ~= "" then
					table.insert(tooltipLines, { text = "|cFF" .. NOTE_LABEL_HEX .. "Note:|r " .. note, r = NOTE_TEXT[1], g = NOTE_TEXT[2], b = NOTE_TEXT[3], wrap = true })
				end
			end
			-- Party members' notes
			for _, v in ipairs(vouches) do
				if v.note and v.note ~= "" then
						table.insert(tooltipLines, { text = "|cFF" .. NOTE_LABEL_HEX .. MPT:StripRealm(v.sender) .. "'s note:|r " .. v.note, r = NOTE_TEXT[1], g = NOTE_TEXT[2], b = NOTE_TEXT[3], wrap = true })
				end
			end
			crown.tooltipLines = tooltipLines
			crown:Show()
		elseif crown then
			crown:Hide()
		end
		self.viewTitleFrame:Show()
		self.mainTitle:Hide()
		if self.tableNameLabel then self.tableNameLabel:Hide() end
		self.backBtn:Show()
		if self.helpBtn then self.helpBtn:Hide() end
		if self.optionsBtn then self.optionsBtn:Hide() end
		if self.optionsPanel then self.optionsPanel:Hide() end
		if self.tableBtn then self.tableBtn:Hide() end
		if self.tableManagerPanel then self.tableManagerPanel:Hide() end
		-- Show remote table dropdown
		self:CreateRemoteTableDropdown()
		if self.remoteTableDD then
			self.remoteTableDD:Show()
			if self.remoteTableList then
				self:UpdateRemoteTableDropdown()
			end
		end
	else
		self.mainTitle:Show()
		if self.tableNameLabel then self.tableNameLabel:Show() end
		if self.viewTitleFrame then self.viewTitleFrame:Hide() end
		self.backBtn:Hide()
		if self.helpBtn then self.helpBtn:Show() end
		if self.optionsBtn then self.optionsBtn:Show() end
		if self.tableBtn then self.tableBtn:Show() end
		if self.remoteTableDD then self.remoteTableDD:Hide() end
		if self.remoteTableListFrame then self.remoteTableListFrame:Hide() end
		self.remoteTableList = nil
		self.remoteTableOwner = nil
	end
end

function MPT:ToggleMvpPanel()
	if not self.mainFrame then return end
	local open = self.db.global.mvpPanelOpen ~= false
	self:SetMvpPanelOpen(not open)
end

function MPT:SetMvpPanelOpen(open)
	if not self.mainFrame then return end
	self.db.global.mvpPanelOpen = open

	-- Show/hide MVP panel
	if self.mvpsSidePanel then
		if open then
			self.mvpsSidePanel:Show()
		else
			self.mvpsSidePanel:Hide()
		end
	end

	-- Update arrow direction: « = panel open (collapse), » = panel closed (expand)
	if self.mvpToggleBtn and self.mvpToggleBtn.arrowLabel then
		self.mvpToggleBtn.arrowLabel:SetText(open and "\194\171" or "\194\187") -- « or »
	end
end

-- ── Stats Column Toggle Popup ───────────────────────────────────

function MPT:ToggleStatsPopup()
	if self.statsPopup and self.statsPopup:IsShown() then
		self:HideAllPopups()
		return
	end
	self:HideAllPopups()
	if not self.statsPopup then
		self:CreateStatsPopup()
	end
	-- Initialize working copy from saved settings
	self.statsWorkingCopy = {}
	for _, col in ipairs(self.db.global.statColumns) do
		self.statsWorkingCopy[#self.statsWorkingCopy + 1] = {
			key = col.key, label = col.label, width = col.width, visible = col.visible,
		}
	end
	self:RefreshStatsPopup()
	self.statsPopup:Show()
	-- Highlight the button
	if self.statsBtn then
		self.statsBtn.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 1)
		self.statsBtn.label:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	end
end

function MPT:CreateStatsPopup()
	local ROW_H = 26
	local POPUP_W = 230
	local ROWS = 9
	local POPUP_H = 30 + (ROWS * ROW_H) + 10 + 26 + 10 -- title + rows + gap + buttons + padding

	local panel = CreateFrame("Frame", "MPTStatsPopup", self.mainFrame)
	panel:SetSize(POPUP_W, POPUP_H)
	panel:SetPoint("TOP", self.statsBtn, "BOTTOM", 0, -4)
	panel:SetFrameStrata("DIALOG")
	panel:EnableMouse(true)

	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(C.popupBg[1], C.popupBg[2], C.popupBg[3], 1)

	-- Border
	local bTop = panel:CreateTexture(nil, "BORDER")
	bTop:SetPoint("TOPLEFT") bTop:SetPoint("TOPRIGHT") bTop:SetHeight(1)
	bTop:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)
	local bBot = panel:CreateTexture(nil, "BORDER")
	bBot:SetPoint("BOTTOMLEFT") bBot:SetPoint("BOTTOMRIGHT") bBot:SetHeight(1)
	bBot:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)
	local bLeft = panel:CreateTexture(nil, "BORDER")
	bLeft:SetPoint("TOPLEFT") bLeft:SetPoint("BOTTOMLEFT") bLeft:SetWidth(1)
	bLeft:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)
	local bRight = panel:CreateTexture(nil, "BORDER")
	bRight:SetPoint("TOPRIGHT") bRight:SetPoint("BOTTOMRIGHT") bRight:SetWidth(1)
	bRight:SetColorTexture(C.borderColor[1], C.borderColor[2], C.borderColor[3], 1)

	-- Title
	local title = panel:CreateFontString(nil, "OVERLAY", "MPTFont_Header")
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
	title:SetText("Stat Columns")
	title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

	-- Drag ghost (floating copy that follows cursor during drag)
	local ghost = CreateFrame("Frame", nil, panel)
	ghost:SetSize(POPUP_W - 20, ROW_H)
	ghost:SetFrameStrata("TOOLTIP")
	ghost:SetAlpha(0.7)
	local ghostBg = ghost:CreateTexture(nil, "BACKGROUND")
	ghostBg:SetAllPoints()
	ghostBg:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
	local ghostLabel = ghost:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	ghostLabel:SetPoint("LEFT", 26, 0)
	ghostLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	ghost.label = ghostLabel
	ghost:Hide()
	panel.ghost = ghost

	-- Drag state
	panel.dragIndex = nil

	-- Row container
	panel.rows = {}
	for i = 1, ROWS do
		local row = CreateFrame("Frame", nil, panel)
		row:SetSize(POPUP_W - 20, ROW_H)
		row:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -(28 + (i - 1) * ROW_H))
		row:EnableMouse(true)

		-- Row hover background
		local rowBg = row:CreateTexture(nil, "BACKGROUND")
		rowBg:SetAllPoints()
		rowBg:SetColorTexture(0, 0, 0, 0)
		row.bg = rowBg

		-- Drop indicator line
		local dropLine = row:CreateTexture(nil, "OVERLAY")
		dropLine:SetHeight(2)
		dropLine:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 1)
		dropLine:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 1)
		dropLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
		dropLine:Hide()
		row.dropLine = dropLine

		row:SetScript("OnEnter", function(self)
			if not panel.dragIndex then
				self.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 0.3)
			end
		end)
		row:SetScript("OnLeave", function(self)
			if not panel.dragIndex then
				self.bg:SetColorTexture(0, 0, 0, 0)
			end
			self.dropLine:Hide()
		end)

		-- Drag handle (the whole row area right of checkbox)
		local handle = CreateFrame("Frame", nil, row)
		handle:SetPoint("LEFT", row, "LEFT", 22, 0)
		handle:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		handle:SetHeight(ROW_H)
		handle:EnableMouse(true)
		handle:RegisterForDrag("LeftButton")
		handle.rowIndex = i

		-- Drag cursor icon
		local grip = handle:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		grip:SetPoint("RIGHT", handle, "RIGHT", -4, 0)
		grip:SetText("=")
		grip:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
		handle.grip = grip

		handle:SetScript("OnEnter", function(self)
			if not panel.dragIndex then
				self.grip:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
				row.bg:SetColorTexture(C.btnHover[1], C.btnHover[2], C.btnHover[3], 0.3)
			end
		end)
		handle:SetScript("OnLeave", function(self)
			if not panel.dragIndex then
				self.grip:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
				row.bg:SetColorTexture(0, 0, 0, 0)
			end
		end)

		handle:SetScript("OnDragStart", function(self)
			local idx = self.rowIndex
			panel.dragIndex = idx
			-- Clear all row highlights
			for _, r in ipairs(panel.rows) do
				r.bg:SetColorTexture(0, 0, 0, 0)
			end
			local wc = MPT.statsWorkingCopy[idx]
			if wc then
				ghost.label:SetText(wc.label)
				ghost:Show()
				ghost:SetScript("OnUpdate", function(g)
					local scale = g:GetEffectiveScale()
					local cx, cy = GetCursorPosition()
					g:ClearAllPoints()
					g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / scale, cy / scale)
				end)
			end
		end)

		handle:SetScript("OnDragStop", function(self)
			ghost:Hide()
			ghost:SetScript("OnUpdate", nil)
			local fromIdx = panel.dragIndex
			panel.dragIndex = nil

			if not fromIdx then return end

			-- Determine drop position from cursor Y
			local scale = panel:GetEffectiveScale()
			local _, cy = GetCursorPosition()
			cy = cy / scale

			local wc = MPT.statsWorkingCopy
			local toIdx = #wc -- default: drop at end

			for ri, r in ipairs(panel.rows) do
				if ri <= #wc then
					local top = r:GetTop()
					local bot = r:GetBottom()
					if top and bot and cy >= bot then
						toIdx = ri
						break
					end
				end
			end

			-- Hide all drop lines
			for _, r in ipairs(panel.rows) do
				r.dropLine:Hide()
				r.bg:SetColorTexture(0, 0, 0, 0)
			end

			if toIdx ~= fromIdx and toIdx ~= fromIdx then
				-- Remove from old position, insert at new
				local item = table.remove(wc, fromIdx)
				if toIdx > fromIdx then toIdx = toIdx - 1 end
				table.insert(wc, toIdx, item)
				MPT:RefreshStatsPopup()
			end
		end)

		row.handle = handle

		-- Checkbox (reuse CreateModernCheckbox)
		local cb = MPT:CreateModernCheckbox(row, nil, 16)
		cb:SetPoint("LEFT", row, "LEFT", 0, 0)
		cb.rowIndex = i
		cb._onToggle = function(checked)
			local wc = MPT.statsWorkingCopy[cb.rowIndex]
			if wc then
				wc.visible = checked
				MPT:RefreshStatsPopup()
			end
		end
		row.cb = cb

		-- Label
		local lbl = row:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
		lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
		lbl:SetWidth(130)
		lbl:SetJustifyH("LEFT")
		lbl:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		row.label = lbl

		panel.rows[i] = row
	end

	-- Default button
	local defaultBtn = self:CreateModernButton(panel, 70, 22, "Default")
	defaultBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 8)
	defaultBtn:SetScript("OnClick", function()
		-- Reset working copy to master defaults
		MPT.statsWorkingCopy = {}
		for _, col in ipairs(MPT.DB_DEFAULTS.global.statColumns) do
			MPT.statsWorkingCopy[#MPT.statsWorkingCopy + 1] = {
				key = col.key, label = col.label, width = col.width, visible = col.visible,
			}
		end
		MPT:RefreshStatsPopup()
	end)
	panel.defaultBtn = defaultBtn

	-- Apply button
	local applyBtn = self:CreateModernButton(panel, 70, 22, "Apply")
	applyBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 8)
	applyBtn:SetScript("OnClick", function()
		MPT.db.global.statColumns = MPT.statsWorkingCopy
		MPT.statsWorkingCopy = nil
		MPT.statsPopup:Hide()
		if MPT.statsBtn then
			MPT.statsBtn.bg:SetColorTexture(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
			MPT.statsBtn.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
		end
		MPT:ResizeMainFrame()
		if MPT.mainFrame and MPT.mainFrame:IsShown() then
			MPT:RefreshTable()
		end
	end)
	panel.applyBtn = applyBtn

	panel:Hide()
	self.statsPopup = panel
end

function MPT:RefreshStatsPopup()
	if not self.statsPopup or not self.statsWorkingCopy then return end

	local wc = self.statsWorkingCopy
	for i, row in ipairs(self.statsPopup.rows) do
		local col = wc[i]
		if col then
			row:Show()
			row.cb.rowIndex = i
			row.cb:SetChecked(col.visible)
			row.handle.rowIndex = i
			row.label:SetText(col.label)
			if col.visible then
				row.label:SetTextColor(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3])
			else
				row.label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
			end
			row.bg:SetColorTexture(0, 0, 0, 0)
			row.dropLine:Hide()
		else
			row:Hide()
		end
	end
end
