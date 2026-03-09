local ADDON_NAME, MPT = ...

LibStub("AceAddon-3.0"):NewAddon(MPT, ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")

function MPT:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MythicMemoriesDB", self.DB_DEFAULTS)
	self:MigrateMvpKeys()

	self:RegisterChatCommand("mm", "SlashCommand")

	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
		type = "launcher",
		text = "Mythic Memories",
		icon = "Interface\\AddOns\\MythicMemories\\icon",
		OnClick = function(_, button)
			if button == "LeftButton" then
				MPT:ToggleUI()
			end
		end,
		OnTooltipShow = function(tt)
			tt:AddLine("Mythic Memories")
			tt:AddLine("Click to toggle M+ run history", 1, 1, 1)
		end,
	})
	LibStub("LibDBIcon-1.0"):Register(ADDON_NAME, ldb, self.db.global.minimap)
end

function MPT:OnEnable()
	self:Print("Mythic Memories loaded. Type /mm to view your run history.")
	-- Apply saved theme
	if self.ApplyTheme and self.db.global.theme then
		self:ApplyTheme(self.db.global.theme)
	end
	self:TableShare_Enable()
	self:DataTracker_Enable()
	self:MvpSync_Enable()
	self:GroupFinderHook_Enable()
	self:HookUnitMenus()
	self:PartyMvpBrowse_Enable()
end

-- ── Party MVP browse (crown sharing for Group Finder) ───────────

function MPT:PartyMvpBrowse_Enable()
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")
	self:RegisterEvent("GROUP_LEFT", "OnGroupLeft")
	self.partyMvpMembers = {}  -- track known members to detect joins
end

function MPT:OnGroupRosterUpdate()
	-- Purge cache entries for members who left
	self:PurgePartyMvpCache()

	if not IsInGroup() then
		self.partyMvpMembers = {}
		return
	end

	-- Detect new members and broadcast our list to the party
	local currentMembers = {}
	local prefix = IsInRaid() and "raid" or "party"
	local count = GetNumGroupMembers()
	local hasNew = false

	for i = 1, count do
		local unit = (prefix == "party") and (i < count and ("party" .. i) or "player") or ("raid" .. i)
		local name = UnitName(unit)
		if name then
			currentMembers[name] = true
			if not self.partyMvpMembers[name] then
				hasNew = true
			end
		end
	end

	if hasNew then
		-- Check new members for MVP status
		local mvpJoiners = {}
		for i = 1, count do
			local unit = (prefix == "party") and (i < count and ("party" .. i) or "player") or ("raid" .. i)
			local name, realm = UnitName(unit)
			local myName = UnitName("player")
			if name and name ~= myName and not self.partyMvpMembers[name] then
				if not realm or realm == "" then
					realm = GetRealmName()
				end
				local nameRealm = name .. "-" .. realm
				local _, class = UnitClass(unit)
				local matched = self:MatchMvpName(nameRealm) or self:MatchMvpName(name)
				if matched then
					local note = self:GetMvpNote(matched)
					mvpJoiners[#mvpJoiners + 1] = {
						name = matched,
						class = class,
						note = note,
					}
				end
			end
		end

		if #mvpJoiners > 0 and self.db.global.mvpNotifications ~= false then
			self:ShowMvpJoinNotification(mvpJoiners)
		end

		-- Small delay so the new member's addon is ready to receive
		C_Timer.After(1, function()
			MPT:BroadcastBrowseMvps()
		end)
	end
	self.partyMvpMembers = currentMembers
end

function MPT:OnGroupLeft()
	self.partyMvpCache = {}
	self.partyMvpMembers = {}
end

function MPT:SlashCommand(input)
	local cmd = (input or ""):trim():lower()
	if cmd == "" then
		self:ToggleUI()
	elseif cmd == "mockdata" then
		self:LoadMockData()
	elseif cmd == "mvps" then
		self:Print("MVPs list:")
		local count = 0
		for name, data in pairs(self.db.global.mvps) do
			local note = data.note or "(no note)"
			self:Print("  " .. name .. " (added by " .. data.addedBy .. ") note: " .. note)
			count = count + 1
		end
		if count == 0 then
			self:Print("  (empty)")
		end
	elseif cmd:match("^limit") then
		local n = tonumber(cmd:match("^limit%s+(%d+)"))
		if n and n > 0 then
			self.shareLimit = n
			self:Print("Share limit set to " .. n .. " runs.")
		else
			self:Print("Current share limit: " .. (self.shareLimit or 50) .. ". Usage: /mm limit <number>")
		end
	elseif cmd == "dev" then
		self:ToggleDevMode()
	elseif cmd == "endrun" then
		self:EndDevRun()
	else
		self:Print("Usage: /mm - toggle UI")
	end
end

function MPT:ToggleUI()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:HideAllPopups()
		self.expandedRunId = nil
		self.mainFrame:Hide()
	else
		if not self.mainFrame then
			self:CreateMainFrame()
		end
		self.mainFrame:Show()
		self:RefreshTable()
		self:RefreshMvpsSidePanel()
	end
end

function MPT:LoadMockData()
	local now = time()
	local day = 86400

	local dungeons = {
		{ name = "Ara-Kara, City of Echoes", mapID = 501 },
		{ name = "City of Threads",          mapID = 502 },
		{ name = "The Stonevault",           mapID = 503 },
		{ name = "The Dawnbreaker",          mapID = 504 },
		{ name = "Mists of Tirna Scithe",    mapID = 375 },
		{ name = "The Necrotic Wake",        mapID = 376 },
		{ name = "Siege of Boralus",         mapID = 353 },
		{ name = "Grim Batol",               mapID = 507 },
	}

	local mockRuns = {
		{ dIdx = 1, level = 15, timeMs = 1965000, bonus = 2, onTime = true,  deaths = 3,  affix = "Tyrannical, Storming",     daysAgo = 0 },
		{ dIdx = 2, level = 14, timeMs = 2100000, bonus = 1, onTime = true,  deaths = 5,  affix = "Fortified, Entangling",    daysAgo = 1 },
		{ dIdx = 3, level = 16, timeMs = 2400000, bonus = 0, onTime = false, deaths = 12, affix = "Tyrannical, Incorporeal",  daysAgo = 1 },
		{ dIdx = 4, level = 12, timeMs = 1500000, bonus = 3, onTime = true,  deaths = 1,  affix = "Fortified, Spiteful",      daysAgo = 2 },
		{ dIdx = 5, level = 13, timeMs = 1800000, bonus = 2, onTime = true,  deaths = 2,  affix = "Tyrannical, Bolstering",   daysAgo = 3 },
		{ dIdx = 6, level = 11, timeMs = 1650000, bonus = 3, onTime = true,  deaths = 0,  affix = "Fortified, Sanguine",      daysAgo = 4 },
		{ dIdx = 7, level = 17, timeMs = 2700000, bonus = 0, onTime = false, deaths = 15, affix = "Tyrannical, Bursting",     daysAgo = 5 },
		{ dIdx = 8, level = 14, timeMs = 1900000, bonus = 1, onTime = true,  deaths = 4,  affix = "Fortified, Storming",      daysAgo = 5 },
		{ dIdx = 1, level = 10, timeMs = 1350000, bonus = 3, onTime = true,  deaths = 0,  affix = "Tyrannical, Entangling",   daysAgo = 6 },
		{ dIdx = 3, level = 15, timeMs = 2050000, bonus = 2, onTime = true,  deaths = 6,  affix = "Fortified, Incorporeal",   daysAgo = 7 },
		{ dIdx = 5, level = 18, timeMs = 2900000, bonus = 0, onTime = false, deaths = 18, affix = "Tyrannical, Spiteful",     daysAgo = 8 },
		{ dIdx = 2, level = 13, timeMs = 1750000, bonus = 2, onTime = true,  deaths = 3,  affix = "Fortified, Bolstering",    daysAgo = 9 },
	}

	local tankNames   = { "Ironwall",   "Shieldbro",  "Bulwark"    }
	local healerNames = { "Lifebloom",  "Mendweaver", "Holynova"   }
	local dpsNames    = { "Darkblade", "Firestorm", "Shadowfang", "Arcblast", "Venomstrike", "Frostbite" }
	local tankClasses   = { "WARRIOR", "PALADIN", "DEATHKNIGHT" }
	local healerClasses = { "PRIEST", "DRUID", "SHAMAN" }
	local dpsClasses    = { "ROGUE", "MAGE", "WARLOCK", "HUNTER", "DEMONHUNTER", "EVOKER" }

	-- Player info for the Role column
	local playerName, playerRealm = UnitName("player")
	if not playerRealm or playerRealm == "" then
		playerRealm = GetRealmName()
	end
	local _, playerClass = UnitClass("player")
	local playerGUID = UnitGUID("player") or "Player-1-999"
	-- Vary the player's role across runs
	local playerRoles = { "DAMAGER", "DAMAGER", "HEALER", "DAMAGER", "TANK", "DAMAGER", "DAMAGER", "HEALER", "DAMAGER", "DAMAGER", "TANK", "DAMAGER" }

	for idx, mr in ipairs(mockRuns) do
		local d = dungeons[mr.dIdx]
		local ti = math.floor(idx / 3) + 1
		local hi = math.floor(idx / 4) + 1
		local d1i = ((idx) % #dpsNames) + 1
		local d2i = ((idx + 2) % #dpsNames) + 1
		local myRole = playerRoles[idx] or "DAMAGER"

		local members = {
			{ name = tankNames[(ti - 1) % #tankNames + 1],     realm = "Silvermoon",  class = tankClasses[(ti - 1) % #tankClasses + 1],     role = "TANK",    guid = "Player-1-" .. (100 + ti) },
			{ name = healerNames[(hi - 1) % #healerNames + 1], realm = "Silvermoon",  class = healerClasses[(hi - 1) % #healerClasses + 1], role = "HEALER",  guid = "Player-1-" .. (200 + hi) },
			{ name = dpsNames[d1i],                             realm = "Silvermoon",  class = dpsClasses[d1i],                               role = "DAMAGER", guid = "Player-1-" .. (300 + d1i) },
			{ name = dpsNames[d2i],                             realm = "Ravencrest",  class = dpsClasses[d2i],                               role = "DAMAGER", guid = "Player-1-" .. (300 + d2i) },
			{ name = playerName or "You",                       realm = playerRealm,   class = playerClass or "WARRIOR",                      role = myRole,    guid = playerGUID },
		}

		local playerStats = {}
		for _, m in ipairs(members) do
			local baseDmg = m.role == "TANK" and 800000 or (m.role == "HEALER" and 200000 or 2000000)
			local baseHeal = m.role == "HEALER" and 1500000 or (m.role == "TANK" and 300000 or 50000)
			local baseDmgTaken = m.role == "TANK" and 3000000 or (m.role == "HEALER" and 500000 or 800000)
			playerStats[m.guid] = {
				name = m.name,
				class = m.class,
				role = m.role,
				damage = baseDmg + math.floor(idx * 50000),
				dps = math.floor((baseDmg + idx * 50000) / (mr.timeMs / 1000)),
				healing = baseHeal + math.floor(idx * 20000),
				hps = math.floor((baseHeal + idx * 20000) / (mr.timeMs / 1000)),
				damageTaken = baseDmgTaken + math.floor(idx * 100000),
				deaths = m.role == "DAMAGER" and math.floor(mr.deaths / 3) or 0,
				interrupts = m.role == "TANK" and 15 or (m.role == "DAMAGER" and 8 or 2),
			}
		end

		local ts = now - (mr.daysAgo * day) - (idx * 3600)
		local runData = {
			id = ts,
			date = date("!%d-%m-%Y", ts),
			timestamp = ts,
			dungeon = d.name,
			mapID = d.mapID,
			level = mr.level,
			timeStr = self:FormatTime(mr.timeMs),
			timeMs = mr.timeMs,
			affix = mr.affix,
			affixIDs = {},
			bonus = mr.bonus,
			onTime = mr.onTime,
			members = members,
			link = (idx % 3 == 0) and "https://raider.io/example" or "",
			description = (idx % 4 == 0) and "Good run, clean pulls" or "",
			mvps = {},
			playerStats = playerStats,
			totalDeaths = mr.deaths,
		}

		self:AddRun(runData)
	end

	-- Add some mock MVPs with notes
	self:AddMvp("Ironwall-Silvermoon", playerName or "You", "WARRIOR", "Great tank, always uses CDs properly")
	self:AddMvp("Lifebloom-Silvermoon", playerName or "You", "PRIEST", "Amazing healer, never lets anyone die")
	self:AddMvp("Darkblade-Silvermoon", playerName or "You", "ROGUE", nil) -- MVP without a note

	self:Print("Loaded " .. #mockRuns .. " mock runs + 3 MVPs. Type /mm to view.")
	if self.mainFrame and self.mainFrame:IsShown() then
		self:RefreshTable()
		self:RefreshMvpsSidePanel()
	end
end