local _, MPT = ...

MPT.DB_DEFAULTS = {
	global = {
		minimap = { hide = false },
		runs = {},
		mvps = {},
		shareTable = true,
	},
}

function MPT:AddRun(runData)
	runData.id = runData.id or time()
	table.insert(self.db.global.runs, 1, runData)
	return runData
end

function MPT:GetRun(id)
	for _, run in ipairs(self.db.global.runs) do
		if run.id == id then
			return run
		end
	end
	return nil
end

function MPT:GetRuns(filterOpts)
	local sourceRuns = self.viewingData and self.viewingData.runs or self.db.global.runs

	if not filterOpts then
		return sourceRuns
	end

	local results = {}
	for _, run in ipairs(sourceRuns) do
		local match = true

		if filterOpts.dungeon and filterOpts.dungeon ~= "" then
			if not run.dungeon:lower():find(filterOpts.dungeon:lower(), 1, true) then
				match = false
			end
		end

		if match and filterOpts.player and filterOpts.player ~= "" then
			local found = false
			local search = filterOpts.player:lower()
			for _, m in ipairs(run.members or {}) do
				if m.name:lower():find(search, 1, true) then
					found = true
					break
				end
			end
			if not found then match = false end
		end

		if match and filterOpts.realm and filterOpts.realm ~= "" then
			local found = false
			local search = filterOpts.realm:lower()
			for _, m in ipairs(run.members or {}) do
				if m.realm:lower():find(search, 1, true) then
					found = true
					break
				end
			end
			if not found then match = false end
		end

		if match then
			table.insert(results, run)
		end
	end
	return results
end

function MPT:UpdateRunField(id, field, value)
	local run = self:GetRun(id)
	if run then
		run[field] = value
		return true
	end
	return false
end

function MPT:AddMvp(nameRealm, addedBy, class, note)
	if not self.db.global.mvps[nameRealm] then
		local truncNote = note
		if truncNote and #truncNote > 250 then
			truncNote = truncNote:sub(1, 250)
		end
		self.db.global.mvps[nameRealm] = {
			addedDate = time(),
			addedBy = addedBy or "Unknown",
			class = class,
			note = truncNote,
		}
		return true
	end
	-- Update class if it was missing before
	if class and not self.db.global.mvps[nameRealm].class then
		self.db.global.mvps[nameRealm].class = class
	end
	return false
end

function MPT:RemoveMvp(nameRealm)
	if self.db.global.mvps[nameRealm] then
		self.db.global.mvps[nameRealm] = nil
		return true
	end
	return false
end

function MPT:IsMvp(nameRealm)
	return self.db.global.mvps[nameRealm] ~= nil
end

function MPT:SetMvpNote(nameRealm, note)
	if not self.db.global.mvps[nameRealm] then return false end
	if note and #note > 250 then
		note = note:sub(1, 250)
	end
	self.db.global.mvps[nameRealm].note = note
	return true
end

function MPT:GetMvpNote(nameRealm)
	local data = self.db.global.mvps[nameRealm]
	return data and data.note or nil
end

function MPT:GetViewMvpNote(nameRealm)
	if self.viewingData and self.viewingData.mvps[nameRealm] then
		return self.viewingData.mvps[nameRealm].note or nil
	end
	return nil
end

function MPT:IsViewMvp(nameRealm)
	if self.viewingData then
		return self.viewingData.mvps[nameRealm] ~= nil
	end
	return self:IsMvp(nameRealm)
end

function MPT:FormatTime(ms)
	local totalSeconds = math.floor(ms / 1000)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, seconds)
	end
	return string.format("%d:%02d", minutes, seconds)
end

function MPT:GetBonusColor(bonus, onTime)
	if not onTime and bonus == 0 then
		return 0.8, 0, 0
	end
	if bonus >= 3 then
		return 0, 0.8, 0
	elseif bonus == 2 then
		return 0.6, 0.8, 0
	elseif bonus == 1 then
		return 0.9, 0.7, 0
	else
		return 0.9, 0.4, 0
	end
end

function MPT:GetClassColor(classFilename)
	if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename] then
		local c = RAID_CLASS_COLORS[classFilename]
		return c.r, c.g, c.b
	end
	return 1, 1, 1
end

function MPT:ResetData(resetRuns, resetMvps)
	local parts = {}
	if resetRuns then
		self.db.global.runs = {}
		parts[#parts + 1] = "runs"
	end
	if resetMvps then
		self.db.global.mvps = {}
		parts[#parts + 1] = "MVPs"
	end
	self.expandedRunId = nil
	self:HideAllPopups()
	if self.mvpsSidePanel and self.mvpsSidePanel:IsShown() then
		self:RefreshMvpsSidePanel()
	end
	self:RefreshTable()
	if #parts > 0 then
		self:Print(table.concat(parts, " and ") .. " have been deleted.")
	end
end
