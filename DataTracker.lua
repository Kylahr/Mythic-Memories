local _, MPT = ...

-- ── DataTracker ─────────────────────────────────────────────────
-- Collects per-player stats from C_DamageMeter and run metadata
-- from C_ChallengeMode at M+ run end. Builds a full run record
-- and saves it via AddRun.
--
-- Per-player stats are only available for completed/reset runs
-- (C_DamageMeter data is wiped on zone-out). Abandoned runs get
-- totalDeaths from a cached C_ChallengeMode.GetDeathCount().

local GRACE_PERIOD = 15
local COLLECT_DELAY = 1.0

-- ── Affix display formatting ──────────────────────────────────
-- Storage keeps raw affix names; these tables drive display only.

local AFFIX_SKIP = {
	["Lindormi's Guidance"] = true,
}

local AFFIX_ABBREV = {
	["Tyrannical"] = "T",
	["Fortified"]  = "F",
}

local XALATATH_PREFIX = "Xal'atath's Bargain: "

local function FormatSingleAffix(name)
	if AFFIX_SKIP[name] then return nil end
	if AFFIX_ABBREV[name] then return AFFIX_ABBREV[name] end
	if name:sub(1, #XALATATH_PREFIX) == XALATATH_PREFIX then
		return name:sub(#XALATATH_PREFIX + 1)
	end
	return name
end

function MPT:FormatAffixDisplay(affixStr)
	if not affixStr or affixStr == "" then return "" end
	local parts = {}
	for affix in affixStr:gmatch("[^,]+") do
		affix = affix:match("^%s*(.-)%s*$")
		local formatted = FormatSingleAffix(affix)
		if formatted then
			parts[#parts + 1] = formatted
		end
	end
	return table.concat(parts, " \194\183 ")  -- " · " (UTF-8 middle dot)
end

function MPT:FormatAffixForFilter(name)
	if AFFIX_SKIP[name] then return nil end
	if name:sub(1, #XALATATH_PREFIX) == XALATATH_PREFIX then
		return name:sub(#XALATATH_PREFIX + 1)
	end
	return name
end

local STAT_TYPES = {
	{ key = "damage",    dpsKey = "dps", enum = Enum.DamageMeterType.DamageDone,          mergePets = true },
	{ key = "healing",   dpsKey = "hps", enum = Enum.DamageMeterType.HealingDone,         mergePets = true },
	{ key = "damageTaken",               enum = Enum.DamageMeterType.DamageTaken,          mergePets = false },
	{ key = "avoidable",                 enum = Enum.DamageMeterType.AvoidableDamageTaken, mergePets = false },
	{ key = "deaths",                    enum = Enum.DamageMeterType.Deaths,               mergePets = false },
	{ key = "interrupts",               enum = Enum.DamageMeterType.Interrupts,            mergePets = false },
	{ key = "dispels",                   enum = Enum.DamageMeterType.Dispels,              mergePets = false },
}

-- ── Enable ──────────────────────────────────────────────────────

function MPT:DataTracker_Enable()
	self:RegisterEvent("CHALLENGE_MODE_START", "DT_OnStart")
	self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "DT_OnCompleted")
	self:RegisterEvent("CHALLENGE_MODE_RESET", "DT_OnReset")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "DT_OnZoneChanged")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "DT_OnZoneChanged")
end

-- ── GUID helpers ────────────────────────────────────────────────

local function isPetGUID(guid)
	return guid and (guid:match("^Pet%-") or guid:match("^Creature%-"))
end

-- ── Member snapshot ─────────────────────────────────────────────

function MPT:DT_SnapshotMembers()
	local members = {}
	local units = { "player", "party1", "party2", "party3", "party4" }
	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			local name, realm = UnitName(unit)
			realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
			local _, classFilename = UnitClass(unit)
			local role = UnitGroupRolesAssigned(unit)
			local guid = UnitGUID(unit)
			members[#members + 1] = {
				name = name,
				realm = realm,
				class = classFilename,
				role = role,
				guid = guid,
			}
		end
	end
	return members
end

-- ── Run metadata ────────────────────────────────────────────────

function MPT:DT_CaptureStartMetadata()
	local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()
	local dungeonName = mapID and C_ChallengeMode.GetMapUIInfo(mapID) or "Unknown"

	local affixNames = {}
	local filteredIDs = {}
	for _, id in ipairs(affixIDs or {}) do
		local name = C_ChallengeMode.GetAffixInfo(id)
		if name and not AFFIX_SKIP[name] then
			affixNames[#affixNames + 1] = name
			filteredIDs[#filteredIDs + 1] = id
		end
	end

	return {
		level = level,
		mapID = mapID,
		dungeon = dungeonName,
		affixIDs = filteredIDs,
		affix = table.concat(affixNames, ", "),
	}
end

-- ── Live death cache ────────────────────────────────────────────

function MPT:DT_SnapshotDeaths()
	if not self.activeRun then return end
	local deaths = select(1, C_ChallengeMode.GetDeathCount())
	if deaths and deaths > 0 then
		self.activeRun.cachedDeathCount = deaths
	end
end

-- ── Pet cache ───────────────────────────────────────────────────

function MPT:DT_RefreshPetCache()
	self.petToOwner = self.petToOwner or {}
	wipe(self.petToOwner)
	local playerPetGUID = UnitGUID("pet")
	if playerPetGUID then
		self.petToOwner[playerPetGUID] = UnitGUID("player")
	end
	for i = 1, 4 do
		local petGUID = UnitGUID("party" .. i .. "pet")
		local ownerGUID = UnitGUID("party" .. i)
		if petGUID and ownerGUID then
			self.petToOwner[petGUID] = ownerGUID
		end
	end
end

function MPT:DT_ResolveOwner(sourceGUID)
	if not isPetGUID(sourceGUID) then
		return sourceGUID
	end
	return self.petToOwner and self.petToOwner[sourceGUID] or nil
end

-- ── Stat collection (fresh query from C_DamageMeter) ────────────

function MPT:DT_CollectAllStats(members)
	local available = C_DamageMeter.IsDamageMeterAvailable()
	if not available then return nil end

	local stats = {}
	for _, m in ipairs(members) do
		stats[m.guid] = {
			name = m.name,
			class = m.class,
			role = m.role,
			damage = 0, dps = 0,
			healing = 0, hps = 0,
			damageTaken = 0, avoidable = 0,
			deaths = 0, interrupts = 0, dispels = 0,
		}
	end

	-- Build member GUID lookup
	local memberGUIDs = {}
	for _, m in ipairs(members) do
		memberGUIDs[m.guid] = true
	end

	for _, def in ipairs(STAT_TYPES) do
		local session = C_DamageMeter.GetCombatSessionFromType(
			Enum.DamageMeterSessionType.Overall,
			def.enum
		)
		if session and session.combatSources then
			-- Sum per owner (handles pet merging)
			-- Deaths: each source entry = one death event, count entries per GUID
			local isDeaths = (def.key == "deaths")
			local totals = {}
			local dpsVals = {}
			for _, src in ipairs(session.combatSources) do
				local ownerGUID = src.sourceGUID
				if def.mergePets and isPetGUID(ownerGUID) then
					ownerGUID = self:DT_ResolveOwner(ownerGUID)
				end
				if ownerGUID and memberGUIDs[ownerGUID] then
					if isDeaths then
						totals[ownerGUID] = (totals[ownerGUID] or 0) + 1
					else
						totals[ownerGUID] = (totals[ownerGUID] or 0) + (src.totalAmount or 0)
					end
					if def.dpsKey and src.amountPerSecond and not isPetGUID(src.sourceGUID) then
						dpsVals[ownerGUID] = src.amountPerSecond
					end
				end
			end
			for guid, total in pairs(totals) do
				if stats[guid] then
					stats[guid][def.key] = total
				end
			end
			if def.dpsKey then
				for guid, dps in pairs(dpsVals) do
					if stats[guid] then
						stats[guid][def.dpsKey] = dps
					end
				end
			end
		end
	end

	return stats
end

-- ── Build run records ───────────────────────────────────────────

function MPT:DT_BuildRunRecord(completionInfo)
	local run = self.activeRun
	if not run then return nil end

	local ts = time()
	local playerStats = self:DT_CollectAllStats(run.members)

	local totalDeaths = 0
	if playerStats then
		for _, ps in pairs(playerStats) do
			totalDeaths = totalDeaths + (ps.deaths or 0)
		end
	end

	return {
		id = ts,
		date = self:FormatDate(ts),
		timestamp = ts,
		dungeon = run.dungeon or "Unknown",
		mapID = run.mapID or 0,
		level = run.level or 0,
		timeMs = completionInfo and completionInfo.time or 0,
		timeStr = self:FormatTime(completionInfo and completionInfo.time or 0),
		affix = run.affix or "",
		affixIDs = run.affixIDs or {},
		bonus = completionInfo and completionInfo.keystoneUpgradeLevels or 0,
		onTime = completionInfo and completionInfo.onTime or false,
		members = run.members,
		playerStats = playerStats,
		totalDeaths = totalDeaths,
		link = "",
		description = "",
	}
end

function MPT:DT_BuildFailedRecord()
	local run = self.activeRun
	if not run then return nil end

	local ts = time()
	local playerStats = self:DT_CollectAllStats(run.members)

	-- For abandoned runs, per-player stats are unavailable (Blizzard wipes
	-- C_DamageMeter on zone-out). Set per-player deaths to nil so the UI
	-- can distinguish "no data" from "0 deaths". totalDeaths uses the
	-- cached value from C_ChallengeMode.GetDeathCount().
	local hasData = false
	if playerStats then
		for _, ps in pairs(playerStats) do
			if ps.damage > 0 or ps.healing > 0 or ps.deaths > 0 or ps.interrupts > 0 then
				hasData = true
				break
			end
		end
		if not hasData then
			for _, ps in pairs(playerStats) do
				ps.deaths = nil
			end
		end
	end

	local totalDeaths = run.cachedDeathCount or 0

	return {
		id = ts,
		date = self:FormatDate(ts),
		timestamp = ts,
		dungeon = run.dungeon or "Unknown",
		mapID = run.mapID or 0,
		level = run.level or 0,
		timeMs = math.floor((GetTime() - (run.startTime or GetTime())) * 1000),
		timeStr = self:FormatTime(math.floor((GetTime() - (run.startTime or GetTime())) * 1000)),
		affix = run.affix or "",
		affixIDs = run.affixIDs or {},
		bonus = 0,
		onTime = false,
		members = run.members,
		playerStats = playerStats,
		totalDeaths = totalDeaths,
		link = "",
		description = "",
	}
end

-- ── Cleanup ─────────────────────────────────────────────────────

function MPT:DT_CleanupActiveRun()
	if self.zoneLeaveTimer then
		self.zoneLeaveTimer:Cancel()
		self.zoneLeaveTimer = nil
	end
	if self.collectTimer then
		self.collectTimer:Cancel()
		self.collectTimer = nil
	end
	self.completionPending = nil
	self._regenCollectFn = nil
	self.activeRun = nil
end

-- ── Delayed collection ──────────────────────────────────────────

function MPT:DT_ScheduleCompletedCollection(completionInfo)
	if not self.activeRun then return end

	local function doCollect()
		if not self.activeRun then return end
		local record = self:DT_BuildRunRecord(completionInfo)
		if record then
			self:AddRun(record)
			local status = record.onTime and "timed" or "depleted"
			self:Print("Run saved — " .. record.dungeon .. " +" .. record.level .. " (" .. status .. ")")
		end
		self:DT_CleanupActiveRun()
	end

	if InCombatLockdown() then
		self._regenCollectFn = doCollect
	else
		self.collectTimer = C_Timer.After(COLLECT_DELAY, doCollect)
	end
end

function MPT:DT_ScheduleFailedCollection()
	if not self.activeRun then return end

	local function doCollect()
		if not self.activeRun then return end
		local record = self:DT_BuildFailedRecord()
		if record then
			self:AddRun(record)
			self:Print("Run saved — " .. record.dungeon .. " +" .. record.level .. " (depleted)")
		end
		self:DT_CleanupActiveRun()
	end

	if InCombatLockdown() then
		self._regenCollectFn = doCollect
	else
		self.collectTimer = C_Timer.After(COLLECT_DELAY, doCollect)
	end
end

-- ── Event Handlers ──────────────────────────────────────────────

function MPT:DT_OnStart()
	if self.zoneLeaveTimer then
		self.zoneLeaveTimer:Cancel()
		self.zoneLeaveTimer = nil
	end
	if self.collectTimer then
		self.collectTimer:Cancel()
		self.collectTimer = nil
	end
	self.completionPending = nil

	local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	local meta = self:DT_CaptureStartMetadata()

	self.activeRun = {
		members = self:DT_SnapshotMembers(),
		startTime = GetTime(),
		instanceMapID = instanceMapID,
		level = meta.level,
		mapID = meta.mapID,
		dungeon = meta.dungeon,
		affixIDs = meta.affixIDs,
		affix = meta.affix,
	}

	self:DT_RefreshPetCache()
	self:RegisterEvent("UNIT_PET", "DT_OnUnitPet")
	self:RegisterEvent("PLAYER_DEAD", "DT_SnapshotDeaths")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "DT_OnRegenDuringRun")
end

function MPT:DT_OnRegenDuringRun()
	-- Cache death count after each pull
	self:DT_SnapshotDeaths()
	-- If a run end is pending collection, fire it now
	if self._regenCollectFn then
		local fn = self._regenCollectFn
		self._regenCollectFn = nil
		self.collectTimer = C_Timer.After(COLLECT_DELAY, fn)
	end
end

function MPT:DT_OnUnitPet()
	if self.activeRun then
		self:DT_RefreshPetCache()
	end
end

function MPT:DT_OnCompleted()
	if not self.activeRun then return end
	self.completionPending = true
	local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
	self:DT_ScheduleCompletedCollection(completionInfo)
end

function MPT:DT_OnReset()
	if not self.activeRun then return end
	self:DT_ScheduleFailedCollection()
end

function MPT:DT_OnZoneChanged(event)
	if not self.activeRun then return end
	if self.completionPending then return end

	local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()

	if instanceMapID == self.activeRun.instanceMapID then
		if self.zoneLeaveTimer then
			self.zoneLeaveTimer:Cancel()
			self.zoneLeaveTimer = nil
		end
		return
	end

	if not self.zoneLeaveTimer then
		self.zoneLeaveTimer = C_Timer.After(GRACE_PERIOD, function()
			if not self.activeRun then return end
			local record = self:DT_BuildFailedRecord()
			if record then
				record.abandoned = true
				self:AddRun(record)
				self:Print("Run saved — " .. record.dungeon .. " +" .. record.level .. " (abandoned)")
			end
			self:DT_CleanupActiveRun()
		end)
	end
end
