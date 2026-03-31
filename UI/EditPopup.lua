local _, MPT = ...
local function P() return MPT.C end

-- ── Shared border helper ─────────────────────────────────────
local function addBorder(parent, point1, rel1, point2, rel2, w, h)
	local line = parent:CreateTexture(nil, "BORDER")
	line:SetPoint(point1, parent, rel1)
	line:SetPoint(point2, parent, rel2)
	if w then line:SetWidth(w) end
	if h then line:SetHeight(h) end
	line:SetColorTexture(P().borderColor[1], P().borderColor[2], P().borderColor[3], 1)
end

-- ── Popup mutual exclusion ─────────────────────────────────────

function MPT:HideAllPopups()
	if self.editPopup then self.editPopup:Hide() end
	if self.linkCopyPopup then self.linkCopyPopup:Hide() end
	if self.optionsPanel then self.optionsPanel:Hide() end
	if self.resetDialog then self.resetDialog:Hide() end
	if self.notePopup then self.notePopup:Hide() end
	if self.removeMvpDialog then self.removeMvpDialog:Hide() end
	if self.helpPanel then
		self.helpPanel:Hide()
		if self.helpLabel then
			self.helpLabel:SetTextColor(P().textMuted[1], P().textMuted[2], P().textMuted[3])
		end
	end
	if self.addNoteDialog then self.addNoteDialog:Hide() end
	if self.filterPopup then
		self.filterPopup:Hide()
		if self.filterBtn then
			self.filterBtn.bg:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 1)
			self.filterBtn.label:SetTextColor(P().textNeutral[1], P().textNeutral[2], P().textNeutral[3])
		end
	end
	if self.rowContextMenu then self.rowContextMenu:Hide() end
	if self.remoteMvpContextMenu then self.remoteMvpContextMenu:Hide() end
	if self.moveSubmenu then self.moveSubmenu:Hide() end
	if self.deleteRunDialog then self.deleteRunDialog:Hide() end
	if self.tableManagerPanel then
		self.tableManagerPanel:Hide()
		if self.tableBtn then
			self.tableBtn.bg:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 1)
			self.tableBtn.label:SetTextColor(P().textPrimary[1], P().textPrimary[2], P().textPrimary[3])
		end
	end
	if self.tableRowContextMenu then self.tableRowContextMenu:Hide() end
	if self.deleteTableDialog then self.deleteTableDialog:Hide() end
	if self.loadingFrame then self.loadingFrame:Hide() end
	if self.remoteTableListFrame then self.remoteTableListFrame:Hide() end
	if self.statsPopup then
		self.statsPopup:Hide()
		if self.statsBtn then
			self.statsBtn.bg:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 1)
			self.statsBtn.label:SetTextColor(P().textPrimary[1], P().textPrimary[2], P().textPrimary[3])
		end
	end
	-- Close any open dropdown lists
	if self._activeDropdown and self._activeDropdown._listFrame then
		self._activeDropdown._listFrame:Hide()
		self._activeDropdown = nil
	end
end

-- ── Shared scrollable multi-line edit area ────────────────────
-- Returns: area (Frame), editBox (EditBox)
local function CreateScrollableEditBox(parent, scrollName, editBoxName, opts)
	opts = opts or {}
	local area = CreateFrame("Frame", nil, parent)
	area:SetHeight(opts.height or 105)

	local areaBg = area:CreateTexture(nil, "BACKGROUND")
	areaBg:SetAllPoints()
	areaBg:SetColorTexture(P().scrollBg[1], P().scrollBg[2], P().scrollBg[3], 1)

	-- Thin border
	addBorder(area, "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
	addBorder(area, "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
	addBorder(area, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
	addBorder(area, "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)

	-- ScrollFrame
	local scroll = CreateFrame("ScrollFrame", scrollName, area)
	scroll:SetPoint("TOPLEFT", 6, -4)
	scroll:SetPoint("BOTTOMRIGHT", -14, 4)

	-- Multi-line EditBox
	local editBox = CreateFrame("EditBox", editBoxName, scroll)
	editBox:SetWidth(scroll:GetWidth() > 0 and scroll:GetWidth() or 310)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("ChatFontNormal")
	if opts.maxLetters then editBox:SetMaxLetters(opts.maxLetters) end
	editBox:SetScript("OnEscapePressed", function() parent:Hide() end)
	scroll:SetScrollChild(editBox)

	-- Click anywhere in the area to focus the EditBox
	area:EnableMouse(true)
	area:SetScript("OnMouseDown", function()
		editBox:SetFocus()
	end)

	-- Thin dark scrollbar track
	local track = CreateFrame("Frame", nil, area)
	track:SetWidth(6)
	track:SetPoint("TOPRIGHT", area, "TOPRIGHT", -3, -4)
	track:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -3, 4)
	local trackBg = track:CreateTexture(nil, "BACKGROUND")
	trackBg:SetAllPoints()
	trackBg:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 0.9)

	-- Thumb
	local thumb = CreateFrame("Frame", nil, track)
	thumb:SetWidth(6)
	thumb:SetHeight(30)
	thumb:SetPoint("TOP", track, "TOP")
	thumb:EnableMouse(true)
	thumb:SetMovable(true)
	local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
	thumbTex:SetAllPoints()
	thumbTex:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 1)

	local function UpdateThumb()
		local max = scroll:GetVerticalScrollRange()
		local trackH = track:GetHeight()
		if max <= 0 then
			thumb:Hide()
			return
		end
		thumb:Show()
		local ratio = scroll:GetVerticalScroll() / max
		local thumbH = math.max(20, trackH * (trackH / (trackH + max)))
		thumb:SetHeight(thumbH)
		thumb:ClearAllPoints()
		thumb:SetPoint("TOP", track, "TOP", 0, -ratio * (trackH - thumbH))
	end

	scroll:SetScript("OnVerticalScroll", UpdateThumb)
	scroll:SetScript("OnScrollRangeChanged", function() UpdateThumb() end)

	-- Mouse wheel
	local function onWheel(_, delta)
		local cur = scroll:GetVerticalScroll()
		local max = scroll:GetVerticalScrollRange()
		scroll:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
	end
	area:EnableMouseWheel(true)
	area:SetScript("OnMouseWheel", onWheel)
	editBox:EnableMouseWheel(true)
	editBox:SetScript("OnMouseWheel", onWheel)

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
		local offset = math.max(0, math.min(1, (top - cursorY - thumbH / 2) / (trackH - thumbH)))
		scroll:SetVerticalScroll(offset * scroll:GetVerticalScrollRange())
	end)

	return area, editBox, scroll
end

-- ── Edit popup (link / description) ────────────────────────────

function MPT:ShowEditPopup(runId, field, currentValue, anchorFrame)
	-- Toggle: if already showing the same field for the same run, close it
	if self.editPopup and self.editPopup:IsShown() and self.editPopup.runId == runId and self.editPopup.field == field then
		self:HideAllPopups()
		return
	end
	self:HideAllPopups()

	if not self.editPopup then
		self:CreateEditPopup()
	end

	local popup = self.editPopup
	popup.runId = runId
	popup.field = field

	if field == "description" then
		popup:SetHeight(180)
		popup.title:SetText("Edit Description")
		popup.descArea:Show()
		popup.linkContainer:Hide()
		popup.linkBox:Hide()
		popup.descBox:SetText(currentValue or "")
		popup.descBox:SetFocus()
		popup.descBox:HighlightText()
	else
		popup:SetHeight(90)
		popup.title:SetText("Edit Link")
		popup.descArea:Hide()
		popup.linkContainer:Show()
		popup.linkBox:Show()
		popup.linkBox:SetText(currentValue or "")
		popup.linkBox:SetFocus()
		popup.linkBox:HighlightText()
	end

	if anchorFrame then
		popup:ClearAllPoints()
		popup:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -2)
	else
		popup:ClearAllPoints()
		popup:SetPoint("CENTER", UIParent, "CENTER")
	end

	popup:Show()
end

function MPT:CreateEditPopup()
	local popup = CreateFrame("Frame", "MPTEditPopup", UIParent)
	popup:SetSize(360, 180)
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("DIALOG")
	popup:EnableMouse(true)

	local bg = popup:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(P().popupBg[1], P().popupBg[2], P().popupBg[3], 1)

	local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", popup, "TOP", 0, -10)
	title:SetText("Edit")
	popup.title = title

	-- ── Link: custom styled single-line EditBox ──────────────
	local linkContainer = CreateFrame("Frame", nil, popup)
	linkContainer:SetSize(334, 28)
	linkContainer:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -32)
	local linkContainerBg = linkContainer:CreateTexture(nil, "BACKGROUND")
	linkContainerBg:SetAllPoints()
	linkContainerBg:SetColorTexture(P().scrollBg[1], P().scrollBg[2], P().scrollBg[3], 1)
	-- Border (matching desc/note area)
	addBorder(linkContainer, "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
	addBorder(linkContainer, "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
	addBorder(linkContainer, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
	addBorder(linkContainer, "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)
	popup.linkContainer = linkContainer

	local linkBox = CreateFrame("EditBox", "MPTEditLinkBox", linkContainer)
	linkBox:SetPoint("TOPLEFT", 8, -5)
	linkBox:SetPoint("BOTTOMRIGHT", -8, 5)
	linkBox:SetAutoFocus(false)
	linkBox:SetFontObject("MPTFont_Cell")
	linkBox:SetScript("OnEscapePressed", function() popup:Hide() end)
	linkBox:SetScript("OnEnterPressed", function()
		self:SaveEditPopup()
	end)
	linkBox:Hide()
	popup.linkBox = linkBox

	-- ── Description: dark inset area with scrollable EditBox ──
	local descArea, descBox = CreateScrollableEditBox(popup, "MPTEditDescScroll", "MPTEditDescBox", { maxLetters = 250 })
	descArea:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -30)
	descArea:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
	descArea:Hide()
	popup.descArea = descArea
	popup.descBox = descBox

	-- ── Save / Cancel buttons ─────────────────────────────────
	local saveBtn = self:CreateModernButton(popup, 70, 22, "Save")
	saveBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -4, 8)
	saveBtn:SetScript("OnClick", function()
		self:SaveEditPopup()
	end)

	local cancelBtn = self:CreateModernButton(popup, 70, 22, "Cancel")
	cancelBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 4, 8)
	cancelBtn:SetScript("OnClick", function()
		popup:Hide()
	end)

	popup.saveBtn = saveBtn
	popup.cancelBtn = cancelBtn

	popup:Hide()
	self.editPopup = popup
end

function MPT:SaveEditPopup()
	local popup = self.editPopup
	if not popup or not popup.runId or not popup.field then return end

	local text
	if popup.field == "description" then
		text = popup.descBox:GetText()
	else
		text = popup.linkBox:GetText()
	end

	MPT:UpdateRunField(popup.runId, popup.field, text)
	if MPT.mainFrame and MPT.mainFrame:IsShown() then
		MPT:RefreshTable()
	end
	popup:Hide()
end

-- ── Link copy popup ────────────────────────────────────────────

function MPT:ShowLinkCopyPopup(url, anchorFrame, isRemote)
	if self.linkCopyPopup and self.linkCopyPopup:IsShown() then
		self:HideAllPopups()
		return
	end
	self:HideAllPopups()

	if not self.linkCopyPopup then
		self:CreateLinkCopyPopup()
	end

	local popup = self.linkCopyPopup
	popup.editBox:SetText(url or "")

	if anchorFrame then
		popup:ClearAllPoints()
		popup:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2)
	else
		popup:ClearAllPoints()
		popup:SetPoint("CENTER", UIParent, "CENTER")
	end

	popup.hint:SetText("Ctrl+C to copy")
	popup.hint:SetTextColor(P().successDim[1], P().successDim[2], P().successDim[3])
	popup.hint:SetAlpha(1)

	if isRemote then
		popup.warning:Show()
		popup:SetHeight(78)
	else
		popup.warning:Hide()
		popup:SetHeight(48)
	end

	popup:Show()
	popup.editBox:SetFocus()
	popup.editBox:HighlightText()
end

function MPT:CreateLinkCopyPopup()
	local popup = CreateFrame("Frame", "MPTLinkCopyPopup", UIParent)
	popup:SetSize(300, 48)
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("DIALOG")
	popup:EnableMouse(true)

	local bg = popup:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(P().popupBg[1], P().popupBg[2], P().popupBg[3], 1)

	-- Custom styled input
	local container = CreateFrame("Frame", nil, popup)
	container:SetSize(280, 28)
	container:SetPoint("TOP", popup, "TOP", 0, -5)
	local containerBg = container:CreateTexture(nil, "BACKGROUND", nil, 1)
	containerBg:SetAllPoints()
	containerBg:SetColorTexture(P().scrollBg[1], P().scrollBg[2], P().scrollBg[3], 1)
	-- Border
	addBorder(container, "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
	addBorder(container, "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
	addBorder(container, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
	addBorder(container, "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)

	local editBox = CreateFrame("EditBox", "MPTLinkCopyBox", container)
	editBox:SetPoint("TOPLEFT", 8, -3)
	editBox:SetPoint("BOTTOMRIGHT", -8, 3)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("MPTFont_Cell")
	editBox:SetScript("OnEscapePressed", function()
		popup:Hide()
	end)
	editBox:SetScript("OnKeyUp", function(self, key)
		if key == "C" and IsControlKeyDown() then
			popup.hint:SetText("Copied!")
			popup.hint:SetTextColor(P().successText[1], P().successText[2], P().successText[3])
			popup.hint:SetAlpha(1)
			C_Timer.After(0.6, function()
				popup:Hide()
			end)
		end
	end)
	popup.editBox = editBox

	local hint = popup:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	hint:SetPoint("TOP", container, "BOTTOM", 0, -2)
	hint:SetText("Ctrl+C to copy")
	hint:SetTextColor(P().successDim[1], P().successDim[2], P().successDim[3])
	popup.hint = hint

	local warning = popup:CreateFontString(nil, "OVERLAY", "MPTFont_Small")
	warning:SetPoint("TOP", hint, "BOTTOM", 0, -2)
	warning:SetPoint("LEFT", popup, "LEFT", 10, 0)
	warning:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
	warning:SetJustifyH("CENTER")
	warning:SetText("Warning: This link is from another player\nand may be malicious.")
	warning:SetTextColor(P().dangerText[1], P().dangerText[2], P().dangerText[3])
	warning:Hide()
	popup.warning = warning

	popup:Hide()
	self.linkCopyPopup = popup
end

-- ── MVP Note popup ───────────────────────────────────────────

function MPT:ClassColoredName(nameRealm, class)
	if class then
		local r, g, b = self:GetClassColor(class)
		local hex = string.format("%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
		return "|cFF" .. hex .. nameRealm .. "|r"
	end
	return nameRealm
end

function MPT:ShowNotePopup(nameRealm, anchorFrame, class)
	if self.notePopup and self.notePopup:IsShown() and self.notePopup.nameRealm == nameRealm then
		self:HideAllPopups()
		return
	end
	self:HideAllPopups()

	if not self.notePopup then
		self:CreateNotePopup()
	end

	local popup = self.notePopup
	popup.nameRealm = nameRealm
	popup.title:SetText("|cFFFFD100Note:|r " .. self:ClassColoredName(nameRealm, class))

	local note = self:GetMvpNote(nameRealm) or ""
	popup.noteBox:SetText(note)
	popup.charCount:SetText(#note .. "/250")

	if anchorFrame then
		popup:ClearAllPoints()
		popup:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2)
	else
		popup:ClearAllPoints()
		popup:SetPoint("CENTER", UIParent, "CENTER")
	end

	popup:Show()
	popup.noteBox:SetFocus()
	popup.noteBox:HighlightText()
end

function MPT:CreateNotePopup()
	local popup = CreateFrame("Frame", "MPTNotePopup", UIParent)
	popup:SetSize(360, 180)
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("DIALOG")
	popup:EnableMouse(true)

	local bg = popup:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(P().popupBg[1], P().popupBg[2], P().popupBg[3], 1)

	local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", popup, "TOP", 0, -8)
	title:SetWidth(340)
	title:SetTextColor(P().textNeutral[1], P().textNeutral[2], P().textNeutral[3])
	popup.title = title

	-- Dark inset scrollable text area (same component as description editor)
	local noteArea, noteBox = CreateScrollableEditBox(popup, "MPTNoteScroll", "MPTNoteEditBox", { maxLetters = 250 })
	noteArea:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -30)
	noteArea:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
	noteBox:SetScript("OnTextChanged", function(self)
		local len = #self:GetText()
		popup.charCount:SetText(len .. "/250")
	end)
	popup.noteBox = noteBox

	local charCount = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	charCount:SetPoint("BOTTOMRIGHT", noteArea, "BOTTOMRIGHT", 0, -12)
	charCount:SetTextColor(P().charCount[1], P().charCount[2], P().charCount[3])
	popup.charCount = charCount

	local saveBtn = self:CreateModernButton(popup, 70, 22, "Save")
	saveBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -4, 6)
	saveBtn:SetScript("OnClick", function()
		MPT:SaveNotePopup()
	end)

	local cancelBtn = self:CreateModernButton(popup, 70, 22, "Cancel")
	cancelBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 4, 6)
	cancelBtn:SetScript("OnClick", function()
		popup:Hide()
	end)

	popup:Hide()
	self.notePopup = popup
end

function MPT:SaveNotePopup()
	local popup = self.notePopup
	if not popup or not popup.nameRealm then return end

	local text = popup.noteBox:GetText() or ""
	self:SetMvpNote(popup.nameRealm, text)

	if self.mvpsSidePanel and self.mvpsSidePanel:IsShown() then
		self:RefreshMvpsSidePanel()
	end

	popup:Hide()
end

-- ── Remove MVP confirmation (when note exists) ──────────────

function MPT:ShowRemoveMvpConfirm(nameRealm, class)
	self:HideAllPopups()

	if not self.removeMvpDialog then
		self:CreateRemoveMvpDialog()
	end

	local dialog = self.removeMvpDialog
	dialog.nameRealm = nameRealm
	local note = self:GetMvpNote(nameRealm) or ""
	local colored = self:ClassColoredName(nameRealm, class)
	dialog.text:SetText("|cFFFFD100Remove|r " .. colored .. " |cFFFFD100from MVPs?\nThis will delete their note:\n\"|r" .. note .. "|cFFFFD100\"|r")
	dialog:Show()
end

function MPT:CreateRemoveMvpDialog()
	local dialog = CreateFrame("Frame", "MPTRemoveMvpDialog", UIParent)
	dialog:SetSize(320, 130)
	dialog:SetPoint("CENTER", UIParent, "CENTER")
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")
	dialog:EnableMouse(true)

	local bg = dialog:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(P().popupBg[1], P().popupBg[2], P().popupBg[3], 1)

	local text = dialog:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	text:SetPoint("TOP", dialog, "TOP", 0, -16)
	text:SetWidth(290)
	text:SetJustifyH("CENTER")
	text:SetTextColor(P().textNeutral[1], P().textNeutral[2], P().textNeutral[3])
	dialog.text = text

	local yesBtn = self:CreateModernButton(dialog, 100, 26, "Yes, Remove")
	yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 14)
	yesBtn.label:SetTextColor(P().dangerText[1], P().dangerText[2], P().dangerText[3])
	yesBtn:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(P().dangerBg[1], P().dangerBg[2], P().dangerBg[3], 1)
	end)
	yesBtn:SetScript("OnLeave", function(self)
		self.bg:SetColorTexture(P().btnBg[1], P().btnBg[2], P().btnBg[3], 1)
	end)
	yesBtn:SetScript("OnClick", function()
		if dialog.nameRealm then
			MPT:RemoveMvp(dialog.nameRealm)
			MPT:OnMvpChanged()
		end
		dialog:Hide()
	end)

	local cancelBtn = self:CreateModernButton(dialog, 100, 26, "Cancel")
	cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 14)
	cancelBtn:SetScript("OnClick", function()
		dialog:Hide()
	end)

	dialog:Hide()
	self.removeMvpDialog = dialog
end

-- ── "Add note?" dialog (world view right-click MVP add) ──────

function MPT:ShowAddNoteDialog(nameRealm, class)
	self:HideAllPopups()

	if not self.addNoteDialog then
		self:CreateAddNoteDialog()
	end

	local dialog = self.addNoteDialog
	dialog.nameRealm = nameRealm
	dialog.class = class
	local colored = self:ClassColoredName(nameRealm, class)
	dialog.text:SetText("|cFFFFD100Add note for|r " .. colored .. "|cFFFFD100?|r")
	dialog:Show()
end

function MPT:CreateAddNoteDialog()
	local dialog = CreateFrame("Frame", "MPTAddNoteDialog", UIParent)
	dialog:SetSize(320, 100)
	dialog:SetPoint("CENTER", UIParent, "CENTER")
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")
	dialog:EnableMouse(true)

	local bg = dialog:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(P().popupBg[1], P().popupBg[2], P().popupBg[3], 1)

	local text = dialog:CreateFontString(nil, "OVERLAY", "MPTFont_Cell")
	text:SetPoint("TOP", dialog, "TOP", 0, -20)
	text:SetWidth(290)
	text:SetJustifyH("CENTER")
	text:SetTextColor(P().textNeutral[1], P().textNeutral[2], P().textNeutral[3])
	dialog.text = text

	local yesBtn = self:CreateModernButton(dialog, 80, 26, "Yes")
	yesBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 14)
	yesBtn:SetScript("OnClick", function()
		dialog:Hide()
		MPT:ShowNotePopup(dialog.nameRealm, nil, dialog.class)
	end)

	local noBtn = self:CreateModernButton(dialog, 80, 26, "No")
	noBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 14)
	noBtn:SetScript("OnClick", function()
		dialog:Hide()
	end)

	dialog:Hide()
	self.addNoteDialog = dialog
end
