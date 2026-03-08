local _, MPT = ...

local hookedFrames = {}

function MPT:GroupFinderHook_Enable()
	-- LFGListFrame is load-on-demand (Blizzard_GroupFinder).
	-- Try immediately in case it's already loaded, otherwise wait.
	if self:TryHookApplicationViewer() then return end
	self:RegisterEvent("ADDON_LOADED", "OnGroupFinderAddonLoaded")
end

function MPT:OnGroupFinderAddonLoaded(event, addonName)
	if addonName == "Blizzard_GroupFinder" then
		self:UnregisterEvent("ADDON_LOADED")
		-- Defer one frame so the UI is fully initialized
		C_Timer.After(0, function()
			MPT:TryHookApplicationViewer()
		end)
	end
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
				local f = scrollBox:GetFrames()
				if f then
					MPT:OnApplicantFramesChanged(f)
				end
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
		if not nr then return end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("MVP", 1, 0.82, 0)
		local note = MPT:GetMvpNote(nr)
		if note and note ~= "" then
			GameTooltip:AddLine(note, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)

end

function MPT:ApplyMvpStar(memberFrame)
	if not memberFrame.Name then return end
	if not memberFrame.mptStar then
		local star = memberFrame:CreateTexture(nil, "OVERLAY", nil, 7)
		star:SetSize(14, 14)
		star:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
		star:SetVertexColor(1, 0.9, 0)
		memberFrame.mptStar = star
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
	for mvpName, _ in pairs(self.db.global.mvps) do
		-- Exact match
		if mvpName == name then
			return mvpName
		end
		-- Match without realm (mvp is "Name-Realm", applicant might be just "Name")
		local baseName = mvpName:match("^(.+)%-")
		if baseName and baseName == name then
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

	local matchedMvp = self:MatchMvpName(name)

	if not matchedMvp then
		self:HideMvpMark(memberFrame)
		return
	end

	-- Store matched MVP name — star is applied via SetText hook
	memberFrame.mptMvpName = matchedMvp
	self:ApplyMvpStar(memberFrame)
end

function MPT:HideMvpMark(memberFrame)
	memberFrame.mptMvpName = nil
	if memberFrame.mptStar then memberFrame.mptStar:Hide() end
end
