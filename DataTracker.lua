local _, MPT = ...

function MPT:DataTracker_Enable()
	self:RegisterEvent("CHALLENGE_MODE_START", "OnChallengeModeStart")
	self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnChallengeModeCompleted")
	self:RegisterEvent("CHALLENGE_MODE_RESET", "OnChallengeModeReset")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
	self.devMode = false
end

function MPT:SnapshotParty()
	local members = {}
	local units = { "player", "party1", "party2", "party3", "party4" }
	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			local name, realm = UnitName(unit)
			local _, classFilename = UnitClass(unit)
			local role = UnitGroupRolesAssigned(unit)
			local guid = UnitGUID(unit)
			if not realm or realm == "" then
				realm = GetRealmName()
			end
			table.insert(members, {
				name = name,
				realm = realm,
				class = classFilename,
				role = role or "DAMAGER",
				guid = guid,
			})
		end
	end
	return members
end

function MPT:OnChallengeModeStart()
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()
	local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
	local dungeonName = C_ChallengeMode.GetMapUIInfo(mapID)

	local affixNames = {}
	for _, id in ipairs(affixIDs or {}) do
		local name = C_ChallengeMode.GetAffixInfo(id)
		if name then
			table.insert(affixNames, name)
		end
	end

	self.activeRun = {
		mapID = mapID,
		level = level,
		affixIDs = affixIDs or {},
		affix = table.concat(affixNames, ", "),
		dungeon = dungeonName or "Unknown",
		members = self:SnapshotParty(),
		startTime = GetTime(),
	}
	self.interruptCounts = {}

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCLEU")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
end

function MPT:OnCLEU()
	local info = { CombatLogGetCurrentEventInfo() }
	local subEvent = info[2]
	local sourceGUID = info[4]

	if subEvent == "SPELL_INTERRUPT" and sourceGUID then
		-- Merge pet interrupts to owner
		local resolvedGUID = sourceGUID
		if not sourceGUID:match("^Player%-") then
			-- Check if this is a party member's pet
			local units = { "player", "party1", "party2", "party3", "party4" }
			for _, unit in ipairs(units) do
				local petGUID = UnitGUID(unit .. "pet")
				if petGUID and petGUID == sourceGUID then
					resolvedGUID = UnitGUID(unit)
					break
				end
			end
			-- If still not a player GUID, skip it (unknown NPC/creature)
			if not resolvedGUID:match("^Player%-") then return end
		end
		self.interruptCounts[resolvedGUID] = (self.interruptCounts[resolvedGUID] or 0) + 1
	end
end

function MPT:OnZoneChanged()
	if not self.activeRun then return end

	local currentMapID = C_ChallengeMode.GetActiveChallengeMapID()
	if not C_ChallengeMode.IsChallengeModeActive() or not currentMapID then
		self:SaveFailedRun()
	end
end

function MPT:CollectDamageMeterStats()
	local stats = {}
	if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then
		return stats
	end

	-- Build pet-to-owner mapping so pet stats merge into the player
	local petOwnerMap = {}
	local units = { "player", "party1", "party2", "party3", "party4" }
	for _, unit in ipairs(units) do
		local ownerGUID = UnitGUID(unit)
		if ownerGUID then
			local petGUID = UnitGUID(unit .. "pet")
			if petGUID then
				petOwnerMap[petGUID] = ownerGUID
			end
		end
	end

	local sessionTypes = {
		{ field = "damage", dpsField = "dps", type = 0 },
		{ field = "damageTaken", type = 1 },
		{ field = "healing", hpsField = "hps", type = 2 },
		{ field = "interrupts", type = 5 },
		{ field = "deaths", type = 9 },
	}

	for _, st in ipairs(sessionTypes) do
		local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, 0, st.type)
		if ok and session and session.combatSources then
			for _, source in ipairs(session.combatSources) do
				local sourceOk, guid = pcall(function() return source.sourceGUID end)
				if sourceOk and guid and guid ~= "" then
					-- Redirect pet GUID to owner, skip non-player/non-pet GUIDs
					local resolvedGUID = petOwnerMap[guid] or guid
					if not resolvedGUID:match("^Player%-") then
						resolvedGUID = nil -- skip creatures/NPCs that aren't mapped pets
					end

					if resolvedGUID then
						if not stats[resolvedGUID] then
							stats[resolvedGUID] = { damage = 0, dps = 0, healing = 0, hps = 0, damageTaken = 0, deaths = 0, interrupts = 0 }
						end
						local amt = (pcall(function() return source.totalAmount end)) and source.totalAmount or 0
						-- For merged pet stats, add to existing values
						stats[resolvedGUID][st.field] = (stats[resolvedGUID][st.field] or 0) + amt
						if st.dpsField then
							local aps = (pcall(function() return source.amountPerSecond end)) and source.amountPerSecond or 0
							stats[resolvedGUID][st.dpsField] = (stats[resolvedGUID][st.dpsField] or 0) + aps
						end
						if st.hpsField then
							local aps = (pcall(function() return source.amountPerSecond end)) and source.amountPerSecond or 0
							stats[resolvedGUID][st.hpsField] = (stats[resolvedGUID][st.hpsField] or 0) + aps
						end
						if st.field == "deaths" then
							local dts = (pcall(function() return source.deathTimeSeconds end)) and source.deathTimeSeconds or 0
							if dts and dts > 0 then
								stats[resolvedGUID].deaths = (stats[resolvedGUID].deaths or 0) + 1
							end
						end
					end
				end
			end
		end
	end
	return stats
end

function MPT:BuildPlayerStats(members, dmStats)
	local playerStats = {}
	for _, member in ipairs(members) do
		local guid = member.guid
		local dm = dmStats[guid] or {}
		playerStats[guid] = {
			name = member.name,
			class = member.class,
			role = member.role,
			damage = dm.damage or 0,
			dps = dm.dps or 0,
			healing = dm.healing or 0,
			hps = dm.hps or 0,
			damageTaken = dm.damageTaken or 0,
			deaths = dm.deaths or 0,
			interrupts = dm.interrupts or self.interruptCounts[guid] or 0,
		}
	end
	return playerStats
end

function MPT:OnChallengeModeCompleted()
	if not self.activeRun then return end

	local info = C_ChallengeMode.GetChallengeCompletionInfo()
	if not info then
		self:CleanupActiveRun()
		return
	end

	local deathCount = 0
	if C_ChallengeMode.GetDeathCount then
		deathCount = C_ChallengeMode.GetDeathCount() or 0
	end

	local dmStats = self:CollectDamageMeterStats()
	local members = self.activeRun.members

	local runData = {
		date = date("!%d-%m-%Y"),
		timestamp = time(),
		dungeon = self.activeRun.dungeon,
		mapID = self.activeRun.mapID,
		level = info.level or self.activeRun.level,
		timeStr = self:FormatTime(info.time or 0),
		timeMs = info.time or 0,
		affix = self.activeRun.affix,
		affixIDs = self.activeRun.affixIDs,
		bonus = info.keystoneUpgradeLevels or 0,
		onTime = info.onTime ~= false,
		members = members,
		link = "",
		description = "",
		mvps = {},
		playerStats = self:BuildPlayerStats(members, dmStats),
		totalDeaths = deathCount,
	}

	self:AddRun(runData)
	self:CleanupActiveRun()
end

function MPT:OnChallengeModeReset()
	if not self.activeRun then return end
	self:SaveFailedRun()
end

function MPT:SaveFailedRun()
	if not self.activeRun then return end

	local elapsed = (GetTime() - self.activeRun.startTime) * 1000
	local dmStats = self:CollectDamageMeterStats()

	local runData = {
		date = date("!%d-%m-%Y"),
		timestamp = time(),
		dungeon = self.activeRun.dungeon,
		mapID = self.activeRun.mapID,
		level = self.activeRun.level,
		timeStr = self:FormatTime(elapsed),
		timeMs = elapsed,
		affix = self.activeRun.affix,
		affixIDs = self.activeRun.affixIDs,
		bonus = 0,
		onTime = false,
		members = self.activeRun.members,
		link = "",
		description = "",
		mvps = {},
		playerStats = self:BuildPlayerStats(self.activeRun.members, dmStats),
		totalDeaths = 0,
	}

	self:AddRun(runData)
	self:CleanupActiveRun()
end

function MPT:CleanupActiveRun()
	self.activeRun = nil
	self.interruptCounts = {}
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
end

-- ── Dev Mode (heroic/normal dungeon testing) ─────────────────

function MPT:ToggleDevMode()
	self.devMode = not self.devMode
	if self.devMode then
		self:Print("Dev mode ENABLED — enter any dungeon to start tracking. Use /mm endrun to save.")
	else
		self:Print("Dev mode DISABLED.")
		if self.activeRun and self.activeRun.isDev then
			self:CleanupActiveRun()
		end
	end
end

function MPT:OnPlayerEnteringWorld()
	if not self.devMode then return end
	if self.activeRun then return end

	local name, instanceType, difficultyID, difficultyName = GetInstanceInfo()
	if instanceType ~= "party" then return end

	-- Skip M+ (difficultyID 8) — that's handled by CHALLENGE_MODE_START
	if difficultyID == 8 then return end

	self.activeRun = {
		isDev = true,
		dungeon = name or "Unknown",
		mapID = 0,
		level = 0,
		affixIDs = {},
		affix = difficultyName or "",
		members = self:SnapshotParty(),
		startTime = GetTime(),
	}
	self.interruptCounts = {}

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCLEU")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnDevZoneChanged")

	self:Print("Dev: tracking started in " .. (name or "Unknown") .. " (" .. (difficultyName or "Unknown") .. ")")
end

function MPT:OnDevZoneChanged()
	if not self.activeRun or not self.activeRun.isDev then return end

	local _, instanceType = GetInstanceInfo()
	if instanceType ~= "party" then
		self:Print("Dev: left dungeon — saving run.")
		self:EndDevRun()
	end
end

function MPT:EndDevRun()
	if not self.activeRun then
		self:Print("Dev: no active run to save.")
		return
	end

	local elapsed = (GetTime() - self.activeRun.startTime) * 1000
	local dmStats = self:CollectDamageMeterStats()
	local members = self.activeRun.members

	-- Count deaths from damage meter stats
	local totalDeaths = 0
	for _, dm in pairs(dmStats) do
		totalDeaths = totalDeaths + (dm.deaths or 0)
	end

	local runData = {
		date = date("!%d-%m-%Y"),
		timestamp = time(),
		dungeon = self.activeRun.dungeon,
		mapID = self.activeRun.mapID,
		level = self.activeRun.level,
		timeStr = self:FormatTime(elapsed),
		timeMs = elapsed,
		affix = self.activeRun.affix,
		affixIDs = self.activeRun.affixIDs,
		bonus = 0,
		onTime = true,
		members = members,
		link = "",
		description = "",
		mvps = {},
		playerStats = self:BuildPlayerStats(members, dmStats),
		totalDeaths = totalDeaths,
	}

	self:AddRun(runData)
	self:CleanupActiveRun()
	self:Print("Dev: run saved — " .. runData.dungeon .. " (" .. runData.timeStr .. ")")

	if self.mainFrame and self.mainFrame:IsShown() then
		self:RefreshTable()
	end
end
