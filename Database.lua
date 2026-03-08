local _, MPT = ...

MPT.DB_DEFAULTS = {
	global = {
		minimap = { hide = false },
		runs = {},
		mvps = {},
		favourites = {},
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

		-- Dungeon: exact match from dropdown or substring from search
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

		-- Affix: contains match (run.affix is comma-separated)
		if match and filterOpts.affix and filterOpts.affix ~= "" then
			if not run.affix or not run.affix:lower():find(filterOpts.affix:lower(), 1, true) then
				match = false
			end
		end

		-- Bonus: exact match on bonus value or depleted
		if match and filterOpts.bonus and filterOpts.bonus ~= "" then
			if filterOpts.bonus == "depleted" then
				if run.onTime ~= false or run.bonus ~= 0 then
					match = false
				end
			else
				local bonusNum = tonumber(filterOpts.bonus)
				if bonusNum then
					if run.bonus ~= bonusNum or not run.onTime then
						match = false
					end
				end
			end
		end

		-- Role: match player's role in the run
		if match and filterOpts.role and filterOpts.role ~= "" then
			local playerName = UnitName and UnitName("player") or ""
			local lookupName = playerName
			if self.viewingPlayer then
				lookupName = self.viewingPlayer:match("^([^%-]+)") or self.viewingPlayer
			end
			local foundRole = false
			for _, m in ipairs(run.members or {}) do
				local shortName = m.name:match("^([^%-]+)") or m.name
				if shortName == lookupName then
					if m.role == filterOpts.role then
						foundRole = true
					end
					break
				end
			end
			if not foundRole then match = false end
		end

		-- Level: min/max range
		if match and filterOpts.levelMin and filterOpts.levelMin ~= "" then
			local minLvl = tonumber(filterOpts.levelMin)
			if minLvl and (run.level or 0) < minLvl then
				match = false
			end
		end
		if match and filterOpts.levelMax and filterOpts.levelMax ~= "" then
			local maxLvl = tonumber(filterOpts.levelMax)
			if maxLvl and (run.level or 0) > maxLvl then
				match = false
			end
		end

		-- Has description
		if match and filterOpts.hasDesc then
			if not run.description or run.description == "" then
				match = false
			end
		end

		-- Has link
		if match and filterOpts.hasLink then
			if not run.link or run.link == "" then
				match = false
			end
		end

		-- Favourites only
		if match and filterOpts.favouritesOnly then
			if not self:IsFavourite(run.id) then
				match = false
			end
		end

		if match then
			table.insert(results, run)
		end
	end
	return results
end

-- Collect unique values from saved runs for filter dropdowns
function MPT:CollectFilterValues()
	local sourceRuns = self.viewingData and self.viewingData.runs or self.db.global.runs
	local dungeons = {}
	local affixes = {}
	local dungeonSet = {}
	local affixSet = {}

	for _, run in ipairs(sourceRuns) do
		-- Unique dungeons
		if run.dungeon and run.dungeon ~= "" and not dungeonSet[run.dungeon] then
			dungeonSet[run.dungeon] = true
			dungeons[#dungeons + 1] = run.dungeon
		end
		-- Unique individual affixes (split comma-separated)
		if run.affix and run.affix ~= "" then
			for affix in run.affix:gmatch("[^,]+") do
				affix = affix:match("^%s*(.-)%s*$")  -- trim whitespace
				if affix ~= "" and not affixSet[affix] then
					affixSet[affix] = true
					affixes[#affixes + 1] = affix
				end
			end
		end
	end

	table.sort(dungeons)
	table.sort(affixes)
	return dungeons, affixes
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

function MPT:ToggleFavourite(runId)
	if not self.db.global.favourites then
		self.db.global.favourites = {}
	end
	if self.db.global.favourites[runId] then
		self.db.global.favourites[runId] = nil
		return false
	else
		self.db.global.favourites[runId] = true
		return true
	end
end

function MPT:IsFavourite(runId)
	return self.db.global.favourites and self.db.global.favourites[runId] or false
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
		return 1.0, 0.3, 0.3
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
