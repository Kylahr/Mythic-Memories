local _, MPT = ...

local hookedFrames = {}

function MPT:GroupFinderHook_Enable()
	-- LFGListFrame is load-on-demand (Blizzard_GroupFinder).
	-- Try immediately in case it's already loaded, otherwise wait.
	if not self:TryHookGroupFinder() then
		self:RegisterEvent("ADDON_LOADED", "OnGroupFinderAddonLoaded")
	end

end

function MPT:OnGroupFinderAddonLoaded(event, addonName)
	if addonName == "Blizzard_GroupFinder" then
		self:UnregisterEvent("ADDON_LOADED")
		-- Defer one frame so the UI is fully initialized
		C_Timer.After(0, function()
			MPT:TryHookGroupFinder()
		end)
	end
end

function MPT:TryHookGroupFinder()
	local appOk = self:TryHookApplicationViewer()
	local searchOk = self:TryHookSearchPanel()
	return appOk or searchOk
end

function MPT:TryHookApplicationViewer()
	local scrollBox = LFGListFrame
		and LFGListFrame.ApplicationViewer
		and LFGListFrame.ApplicationViewer.ScrollBox

	if not scrollBox then return false end

	local ok, err = pcall(function()
		if ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnUpdate then
			-- Fire once for any already-visible frames
			local frames = scrollBox.GetFrames and scrollBox:GetFrames()
			if frames then
				self:OnApplicantFramesChanged(frames)
			end
			-- Register for future updates
			scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnUpdate, function()
				C_Timer.After(0, function()
					local f = scrollBox:GetFrames()
					if f then
						MPT:OnApplicantFramesChanged(f)
					end
				end)
			end, self)
		end
	end)

	if not ok then
		self:Print("Mythic Memories: Group Finder hook error — " .. tostring(err))
	end

	return ok
end

function MPT:OnApplicantFramesChanged(frames)
	for _, frame in ipairs(frames) do
		-- Hook member sub-frames for tooltip (once per frame)
		if not hookedFrames[frame] then
			hookedFrames[frame] = true
			if frame.Members then
				for _, memberFrame in ipairs(frame.Members) do
					self:HookMemberFrame(memberFrame)
				end
			end
		end
		-- Always update marks (data may have changed even if frames are the same)
		self:UpdateApplicantMarks(frame)
	end
end

function MPT:HookMemberFrame(memberFrame)
	if hookedFrames[memberFrame] then return end
	hookedFrames[memberFrame] = true

	-- Append MVP info to the existing tooltip (runs after Blizzard's OnEnter)
	memberFrame:HookScript("OnEnter", function(self)
		local nr = self.mptMvpName
		local vouchedBy = self.mptVouchedBy
		local vouches = self.mptVouches or {}
		if not nr and not vouchedBy then return end
		GameTooltip:AddLine(" ")
		if nr and vouchedBy then
			GameTooltip:AddLine("MVP", 0.2, 1, 0.2)
			local names = {}
			for _, v in ipairs(vouches) do names[#names + 1] = v.sender end
			GameTooltip:AddLine("In your list and " .. table.concat(names, ", ") .. "'s list", 0.8, 0.8, 0.8, true)
		elseif nr then
			GameTooltip:AddLine("MVP", 1, 0.85, 0)
		else
			GameTooltip:AddLine("MVP", 0.3, 0.7, 1)
			local names = {}
			for _, v in ipairs(vouches) do names[#names + 1] = v.sender end
			GameTooltip:AddLine("Vouched by " .. table.concat(names, ", "), 0.8, 0.8, 0.8, true)
		end
		if nr then
			local note = MPT:GetMvpNote(nr)
			if note and note ~= "" then
				GameTooltip:AddLine(note, 1, 1, 1, true)
			end
		end
		for _, v in ipairs(vouches) do
			if v.note and v.note ~= "" then
				GameTooltip:AddLine(v.sender .. "'s note: " .. v.note, 0.7, 0.85, 1, true)
			end
		end
		GameTooltip:Show()
	end)

end

function MPT:ApplyMvpStar(memberFrame, inLocal, vouchedBy)
	if not memberFrame.Name then return end
	if not memberFrame.mptStar then
		local star = memberFrame:CreateTexture(nil, "OVERLAY", nil, 7)
		star:SetSize(14, 14)
		star:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
		memberFrame.mptStar = star
	end

	-- Color coding: gold (yours), blue (party), green (both)
	if inLocal and vouchedBy then
		memberFrame.mptStar:SetDesaturated(true)
		memberFrame.mptStar:SetVertexColor(0.2, 1, 0.2)
	elseif inLocal then
		memberFrame.mptStar:SetDesaturated(false)
		memberFrame.mptStar:SetVertexColor(1, 0.85, 0)
	else
		memberFrame.mptStar:SetDesaturated(true)
		memberFrame.mptStar:SetVertexColor(0.3, 0.7, 1)
	end

	-- Position after the name text
	local nameWidth = memberFrame.Name:GetStringWidth() or 0
	memberFrame.mptStar:ClearAllPoints()
	memberFrame.mptStar:SetPoint("LEFT", memberFrame.Name, "LEFT", nameWidth + 2, 0)
	memberFrame.mptStar:Show()
end

function MPT:UpdateApplicantMarks(frame)
	if not frame.Members or not frame.applicantID then return end

	for _, memberFrame in ipairs(frame.Members) do
		local memberIdx = memberFrame.memberIdx
		if memberIdx then
			self:MarkMvpInLFG(memberFrame, frame.applicantID, memberIdx)
		end
	end
end

function MPT:MatchMvpName(name)
	if not name then return nil end
	name = self:NormalizeNameRealm(name)
	local nameLower = name:lower()
	local inputBase = name:match("^([^%-]+)")
	local inputBaseLower = inputBase and inputBase:lower()

	local inputHasRealm = name:find("%-") ~= nil

	for mvpName, _ in pairs(self.db.global.mvps) do
		-- Exact match
		if mvpName == name then
			return mvpName
		end
		-- Case-insensitive exact match
		if mvpName:lower() == nameLower then
			return mvpName
		end
		local mvpBase = mvpName:match("^([^%-]+)")
		local mvpHasRealm = mvpName:find("%-") ~= nil
		-- MVP has realm, input doesn't (base name match)
		if not inputHasRealm and mvpBase and mvpBase:lower() == nameLower then
			return mvpName
		end
		-- Input has realm, MVP doesn't (base name match only when MVP has no realm)
		if inputHasRealm and not mvpHasRealm and inputBaseLower and mvpBase and mvpBase:lower() == inputBaseLower then
			return mvpName
		end
	end
	return nil
end

function MPT:MarkMvpInLFG(memberFrame, appID, memberIdx)
	if not memberFrame then return end
	if not C_LFGList or not C_LFGList.GetApplicantMemberInfo then return end

	local ok, name = pcall(C_LFGList.GetApplicantMemberInfo, appID, memberIdx)
	if not ok or not name then
		self:HideMvpMark(memberFrame)
		return
	end

	local inLocal = self:MatchMvpName(name)
	local vouches = self:CheckPartyMvp(name)
	local vouchedBy = vouches[1] and vouches[1].sender or nil

	if not inLocal and not vouchedBy then
		self:HideMvpMark(memberFrame)
		return
	end

	memberFrame.mptMvpName = inLocal
	memberFrame.mptVouchedBy = vouchedBy
	memberFrame.mptVouches = vouches
	self:ApplyMvpStar(memberFrame, inLocal, vouchedBy)
end

function MPT:HideMvpMark(memberFrame)
	memberFrame.mptMvpName = nil
	memberFrame.mptVouchedBy = nil
	memberFrame.mptVouches = nil
	if memberFrame.mptStar then memberFrame.mptStar:Hide() end
end

-- ── Search Panel: Crown on group listings with MVP leaders ──────

function MPT:TryHookSearchPanel()
	local scrollBox = LFGListFrame
		and LFGListFrame.SearchPanel
		and LFGListFrame.SearchPanel.ScrollBox

	if not scrollBox then return false end

	local ok, err = pcall(function()
		if ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnUpdate then
			local frames = scrollBox.GetFrames and scrollBox:GetFrames()
			if frames then
				self:OnSearchFramesChanged(frames)
			end
			scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnUpdate, function()
				C_Timer.After(0, function()
					local f = scrollBox:GetFrames()
					if f then
						MPT:OnSearchFramesChanged(f)
					end
				end)
			end, "MPT_SearchPanel")
		end
	end)

	if not ok then
		self:Print("Mythic Memories: Search Panel hook error — " .. tostring(err))
	end

	return ok
end

function MPT:OnSearchFramesChanged(frames)
	for _, frame in ipairs(frames) do
		self:UpdateSearchResultCrown(frame)
	end
end

function MPT:GetSearchResultID(frame)
	-- ScrollBox frames expose element data via GetElementData
	if frame.GetElementData then
		local data = frame:GetElementData()
		if data then
			-- Data can be the searchResultID directly (number) or a table with the ID
			if type(data) == "number" then
				return data
			elseif type(data) == "table" then
				return data.searchResultID or data.resultID
			end
		end
	end
	return nil
end

function MPT:CreateCrown(frame)
	local crown = CreateFrame("Frame", nil, frame)
	crown:SetSize(18, 18)
	crown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, 0)
	crown:SetFrameLevel(frame:GetFrameLevel() + 10)

	crown.icon = crown:CreateTexture(nil, "OVERLAY", nil, 7)
	crown.icon:SetAllPoints()
	crown.icon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
	crown.icon:SetVertexColor(1, 0.85, 0)

	-- Tooltip on hover
	crown:EnableMouse(true)
	crown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.mptTooltipLines then
			for _, line in ipairs(self.mptTooltipLines) do
				GameTooltip:AddLine(line.text, line.r, line.g, line.b, line.wrap)
			end
		end
		GameTooltip:Show()
	end)
	crown:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	frame.mptCrown = crown
	return crown
end

function MPT:UpdateSearchResultCrown(frame)
	local searchResultID = self:GetSearchResultID(frame)
	if not searchResultID then
		if frame.mptCrown then frame.mptCrown:Hide() end
		return
	end

	-- Get leader name from search result
	local ok, resultData = pcall(C_LFGList.GetSearchResultInfo, searchResultID)
	if not ok or not resultData then
		if frame.mptCrown then frame.mptCrown:Hide() end
		return
	end

	local leaderName = resultData.leaderName
	if not leaderName then
		if frame.mptCrown then frame.mptCrown:Hide() end
		return
	end

	-- Check local MVP list
	local inLocal = self:MatchMvpName(leaderName)
	-- Check party members' MVP lists
	local vouches = self:CheckPartyMvp(leaderName)
	local vouchedBy = vouches[1] and vouches[1].sender or nil

	if not inLocal and not vouchedBy then
		if frame.mptCrown then frame.mptCrown:Hide() end
		frame.mptLeaderMvpInfo = nil
		return
	end

	-- Get leader class for coloring (API first, then fall back to MVP DB)
	local leaderClass = nil
	local numMembers = resultData.numMembers or 0
	for i = 1, numMembers do
		local pOk, playerInfo = pcall(C_LFGList.GetSearchResultPlayerInfo, searchResultID, i)
		if pOk and playerInfo and playerInfo.isLeader then
			leaderClass = playerInfo.classFilename
			break
		end
	end
	if not leaderClass and inLocal then
		local mvpData = self.db.global.mvps[inLocal]
		if mvpData then leaderClass = mvpData.class end
	end
	local classR, classG, classB = self:GetClassColor(leaderClass)

	-- Create crown if needed
	local crown = frame.mptCrown or self:CreateCrown(frame)

	-- Hook the search result frame tooltip (once) to append MVP info
	if not frame.mptSearchTooltipHooked then
		frame.mptSearchTooltipHooked = true
		frame:HookScript("OnEnter", function(self)
			if not self.mptLeaderMvpInfo then return end
			local info = self.mptLeaderMvpInfo
			GameTooltip:AddLine(" ")
			-- Leader name in class color
			GameTooltip:AddLine(info.leaderName, info.classR, info.classG, info.classB)
			if info.inLocal and info.vouchedBy then
				GameTooltip:AddLine("MVP", 0.2, 1, 0.2)
				local names = {}
				for _, v in ipairs(info.vouches) do names[#names + 1] = v.sender end
				GameTooltip:AddLine("In your list and " .. table.concat(names, ", ") .. "'s list", 0.8, 0.8, 0.8, true)
			elseif info.inLocal then
				GameTooltip:AddLine("MVP", 1, 0.85, 0)
			else
				GameTooltip:AddLine("MVP", 0.3, 0.7, 1)
				local names = {}
				for _, v in ipairs(info.vouches) do names[#names + 1] = v.sender end
				GameTooltip:AddLine("Vouched by " .. table.concat(names, ", "), 0.8, 0.8, 0.8, true)
			end
			if info.localNote and info.localNote ~= "" then
				GameTooltip:AddLine(info.localNote, 1, 1, 1, true)
			end
			for _, v in ipairs(info.vouches) do
				if v.note and v.note ~= "" then
					GameTooltip:AddLine(v.sender .. "'s note: " .. v.note, 0.7, 0.85, 1, true)
				end
			end
			GameTooltip:Show()
		end)
	end

	-- Store info for the frame tooltip
	local localNote = inLocal and self:GetMvpNote(inLocal) or nil
	frame.mptLeaderMvpInfo = {
		leaderName = leaderName,
		classR = classR,
		classG = classG,
		classB = classB,
		inLocal = inLocal,
		vouchedBy = vouchedBy,
		vouches = vouches,
		localNote = localNote,
	}

	-- Set color based on who has them as MVP
	local tooltipLines = {}
	-- Crown tooltip: leader name in class color
	tooltipLines[#tooltipLines + 1] = { text = leaderName, r = classR, g = classG, b = classB }
	if inLocal and vouchedBy then
		crown.icon:SetDesaturated(true)
		crown.icon:SetVertexColor(0.2, 1, 0.2)
		local names = {}
		for _, v in ipairs(vouches) do names[#names + 1] = v.sender end
		tooltipLines[#tooltipLines + 1] = { text = "MVP — in your list and " .. table.concat(names, ", ") .. "'s list", r = 0.2, g = 1, b = 0.2, wrap = true }
	elseif inLocal then
		crown.icon:SetDesaturated(false)
		crown.icon:SetVertexColor(1, 0.85, 0)
		tooltipLines[#tooltipLines + 1] = { text = "MVP", r = 1, g = 0.85, b = 0 }
	else
		crown.icon:SetDesaturated(true)
		crown.icon:SetVertexColor(0.3, 0.7, 1)
		local names = {}
		for _, v in ipairs(vouches) do names[#names + 1] = v.sender end
		tooltipLines[#tooltipLines + 1] = { text = "MVP — vouched by " .. table.concat(names, ", "), r = 0.3, g = 0.7, b = 1, wrap = true }
	end
	if localNote and localNote ~= "" then
		tooltipLines[#tooltipLines + 1] = { text = localNote, r = 1, g = 1, b = 1, wrap = true }
	end
	for _, v in ipairs(vouches) do
		if v.note and v.note ~= "" then
			tooltipLines[#tooltipLines + 1] = { text = v.sender .. "'s note: " .. v.note, r = 0.7, g = 0.85, b = 1, wrap = true }
		end
	end

	crown.mptTooltipLines = tooltipLines
	crown:Show()
end

