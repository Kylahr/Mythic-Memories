local _, MPT = ...

MPT.DB_DEFAULTS = {
	global = {
		minimap = { hide = false },
		tables = {
			{ name = "All Runs", runs = {} },
		},
		activeTableIndex = 1, -- legacy, kept for migration
		charActiveTable = {}, -- { ["Name-Realm"] = index }
		mvps = {},
		favourites = {},
		shareTable = true,
		mvpNotifications = true,
		mvpSound = true,
		syncMessages = true,
		notificationPos = { point = "TOP", x = 0, y = -200 },
		scanBtnPos = { point = "CENTER", x = 200, y = -200 },
		theme = "coffee",
		mvpPanelOpen = true,
		totalRuns = 0,
	},
}

-- Migration: count total runs across all tables
function MPT:MigrateTotalRuns()
	if self.db.global.totalRunsMigrated then return end
	local total = 0
	for _, tbl in ipairs(self.db.global.tables or {}) do
		total = total + #tbl.runs
	end
	self.db.global.totalRuns = total
	self.db.global.totalRunsMigrated = true
end

-- Migration: wrap flat db.global.runs into tables[1]
function MPT:MigrateToTables()
	local g = self.db.global
	if g.tables and #g.tables > 0 then return end
	g.tables = {
		{ name = "All Runs", runs = g.runs or {} },
	}
	g.activeTableIndex = 1
	g.runs = nil
end

------------------------------------------------------------
-- Character key for per-char active table
------------------------------------------------------------
function MPT:GetCharKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Unknown"
	return name .. "-" .. realm
end

-- Migration: move legacy global activeTableIndex into charActiveTable
function MPT:MigrateCharActiveTable()
	local g = self.db.global
	if not g.charActiveTable then g.charActiveTable = {} end
	local charKey = self:GetCharKey()
	local _, classFile = UnitClass("player")
	local entry = g.charActiveTable[charKey]
	-- Migrate old format (plain number) to new format (table with index + class)
	if type(entry) == "number" then
		g.charActiveTable[charKey] = { index = entry, class = classFile }
		entry = g.charActiveTable[charKey]
	end
	if not entry then
		local legacy = g.activeTableIndex or 1
		if not g.tables[legacy] then legacy = 1 end
		g.charActiveTable[charKey] = { index = legacy, class = classFile }
		entry = g.charActiveTable[charKey]
	end
	-- Always update class (may have been nil on old entries)
	entry.class = classFile
	-- Clamp if index is out of range
	if not g.tables[entry.index] then
		entry.index = 1
	end
end

------------------------------------------------------------
-- Table accessors
------------------------------------------------------------
function MPT:GetActiveTableIndex()
	local g = self.db.global
	local charKey = self:GetCharKey()
	local entry = g.charActiveTable and g.charActiveTable[charKey]
	local idx = (type(entry) == "table" and entry.index) or 1
	if not g.tables[idx] then idx = 1 end
	return idx
end

function MPT:GetActiveTable()
	return self.db.global.tables[self:GetActiveTableIndex()]
end

function MPT:GetActiveRuns()
	return self:GetActiveTable().runs
end

-- Viewed table: which table is currently displayed (transient, not saved)
function MPT:GetViewedTableIndex()
	local idx = self.viewedTableIndex or self:GetActiveTableIndex()
	if not self.db.global.tables[idx] then idx = 1 end
	return idx
end

function MPT:GetViewedTable()
	return self.db.global.tables[self:GetViewedTableIndex()]
end

function MPT:GetViewedRuns()
	return self:GetViewedTable().runs
end

function MPT:GetViewedTableName()
	return self:GetViewedTable().name
end

function MPT:GetTableList()
	local list = {}
	for i, tbl in ipairs(self.db.global.tables) do
		list[#list + 1] = { index = i, name = tbl.name }
	end
	return list
end

------------------------------------------------------------
-- Table CRUD
------------------------------------------------------------
function MPT:CreateTable(name)
	local tables = self.db.global.tables
	table.insert(tables, { name = name, runs = {} })
	return #tables
end

function MPT:RenameTable(index, newName)
	local tbl = self.db.global.tables[index]
	if tbl then
		tbl.name = newName
		return true
	end
	return false
end

function MPT:DeleteTable(index)
	local tables = self.db.global.tables
	if #tables <= 1 then return false end
	-- Clean orphaned favourites and decrement total run count
	local removedCount = #tables[index].runs
	for _, run in ipairs(tables[index].runs) do
		if self.db.global.favourites then
			self.db.global.favourites[run.id] = nil
		end
	end
	table.remove(tables, index)
	self.db.global.totalRuns = math.max(0, (self.db.global.totalRuns or 0) - removedCount)
	-- Adjust all per-character active table indices
	local cat = self.db.global.charActiveTable or {}
	for charKey, entry in pairs(cat) do
		if type(entry) == "table" then
			if entry.index == index then
				entry.index = math.max(1, index - 1)
			elseif entry.index > index then
				entry.index = entry.index - 1
			end
		end
	end
	-- Fix viewedTableIndex too
	if self.viewedTableIndex then
		if self.viewedTableIndex == index then
			self.viewedTableIndex = self:GetActiveTableIndex()
		elseif self.viewedTableIndex > index then
			self.viewedTableIndex = self.viewedTableIndex - 1
		end
	end
	return true
end

function MPT:SetActiveTable(index)
	if not self.db.global.tables[index] then return false end
	local charKey = self:GetCharKey()
	if not self.db.global.charActiveTable then self.db.global.charActiveTable = {} end
	local entry = self.db.global.charActiveTable[charKey]
	if type(entry) == "table" then
		entry.index = index
	else
		local _, classFile = UnitClass("player")
		self.db.global.charActiveTable[charKey] = { index = index, class = classFile }
	end
	return true
end

-- Reorder: swap table at index with table at targetIndex
function MPT:SwapTables(fromIndex, toIndex)
	local tables = self.db.global.tables
	if not tables[fromIndex] or not tables[toIndex] then return false end
	tables[fromIndex], tables[toIndex] = tables[toIndex], tables[fromIndex]
	-- Update all per-character active table indices to follow the swap
	local cat = self.db.global.charActiveTable or {}
	for charKey, entry in pairs(cat) do
		if type(entry) == "table" then
			if entry.index == fromIndex then
				entry.index = toIndex
			elseif entry.index == toIndex then
				entry.index = fromIndex
			end
		end
	end
	-- Update viewedTableIndex to follow the swap
	if self.viewedTableIndex then
		if self.viewedTableIndex == fromIndex then
			self.viewedTableIndex = toIndex
		elseif self.viewedTableIndex == toIndex then
			self.viewedTableIndex = fromIndex
		end
	end
	return true
end

-- Get map of table index -> list of { name, class } that have it active
function MPT:GetCharActiveMap()
	local result = {}
	local cat = self.db.global.charActiveTable or {}
	for charKey, entry in pairs(cat) do
		local idx = type(entry) == "table" and entry.index or entry
		local class = type(entry) == "table" and entry.class or nil
		if not result[idx] then result[idx] = {} end
		local name = charKey:match("^([^%-]+)") or charKey
		result[idx][#result[idx] + 1] = { name = name, class = class }
	end
	return result
end

function MPT:ViewTable(index)
	if not self.db.global.tables[index] then return false end
	self.viewedTableIndex = index
	self.expandedRunId = nil
	if self.mainFrame and self.mainFrame:IsShown() then
		self:UpdateTableNameInTitle()
		self:RefreshTable()
	end
	return true
end

function MPT:MoveRunToTable(runId, targetTableIndex)
	local sourceRuns = self:GetViewedRuns()
	local targetTable = self.db.global.tables[targetTableIndex]
	if not targetTable then return false end
	for i, run in ipairs(sourceRuns) do
		if run.id == runId then
			table.remove(sourceRuns, i)
			table.insert(targetTable.runs, 1, run)
			return true
		end
	end
	return false
end

function MPT:AddRun(runData)
	runData.id = runData.id or time()
	table.insert(self:GetActiveRuns(), 1, runData)
	self.db.global.totalRuns = (self.db.global.totalRuns or 0) + 1
	return runData
end

function MPT:GetRun(id)
	for _, run in ipairs(self:GetViewedRuns()) do
		if run.id == id then
			return run
		end
	end
	return nil
end

function MPT:GetRuns(filterOpts)
	local sourceRuns = self.viewingData and self.viewingData.runs or self:GetViewedRuns()

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
	local sourceRuns = self.viewingData and self.viewingData.runs or self:GetViewedRuns()
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

function MPT:DeleteRun(id)
	for i, run in ipairs(self:GetViewedRuns()) do
		if run.id == id then
			table.remove(self:GetViewedRuns(), i)
			if self.db.global.favourites then
				self.db.global.favourites[id] = nil
			end
			self.db.global.totalRuns = math.max(0, (self.db.global.totalRuns or 0) - 1)
			return true
		end
	end
	return false
end

function MPT:UpdateRunField(id, field, value)
	local run = self:GetRun(id)
	if run then
		run[field] = value
		return true
	end
	return false
end

function MPT:NormalizeNameRealm(nameRealm)
	local name, realm = nameRealm:match("^([^%-]+)%-(.+)$")
	if name and realm then
		return name .. "-" .. realm:gsub(" ", "")
	end
	return nameRealm
end

function MPT:MigrateMvpKeys()
	local mvps = self.db.global.mvps
	local toRename = {}
	for key, data in pairs(mvps) do
		local normalized = self:NormalizeNameRealm(key)
		if normalized ~= key then
			toRename[#toRename + 1] = { old = key, new = normalized, data = data }
		end
	end
	for _, entry in ipairs(toRename) do
		if not mvps[entry.new] then
			mvps[entry.new] = entry.data
		end
		mvps[entry.old] = nil
	end
end

function MPT:AddMvp(nameRealm, addedBy, class, note)
	nameRealm = self:NormalizeNameRealm(nameRealm)
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
	nameRealm = self:NormalizeNameRealm(nameRealm)
	if self.db.global.mvps[nameRealm] then
		self.db.global.mvps[nameRealm] = nil
		return true
	end
	return false
end

function MPT:IsMvp(nameRealm)
	nameRealm = self:NormalizeNameRealm(nameRealm)
	return self.db.global.mvps[nameRealm] ~= nil
end

function MPT:SetMvpNote(nameRealm, note)
	nameRealm = self:NormalizeNameRealm(nameRealm)
	if not self.db.global.mvps[nameRealm] then return false end
	if note and #note > 250 then
		note = note:sub(1, 250)
	end
	self.db.global.mvps[nameRealm].note = note
	return true
end

function MPT:GetMvpNote(nameRealm)
	nameRealm = self:NormalizeNameRealm(nameRealm)
	local data = self.db.global.mvps[nameRealm]
	return data and data.note or nil
end

function MPT:GetViewMvpNote(nameRealm)
	nameRealm = self:NormalizeNameRealm(nameRealm)
	if self.viewingData and self.viewingData.mvps[nameRealm] then
		return self.viewingData.mvps[nameRealm].note or nil
	end
	return nil
end

function MPT:IsViewMvp(nameRealm)
	nameRealm = self:NormalizeNameRealm(nameRealm)
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

-- Date format resolved once at load time
local DATE_FMT = (GetCurrentRegion and GetCurrentRegion() == 1) and "!%m-%d-%Y" or "!%d-%m-%Y"

function MPT:FormatDate(ts)
	return date(DATE_FMT, ts or time())
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
		local removedCount = #self:GetViewedTable().runs
		self:GetViewedTable().runs = {}
		self.db.global.totalRuns = math.max(0, (self.db.global.totalRuns or 0) - removedCount)
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
