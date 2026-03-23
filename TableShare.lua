local _, MPT = ...

local COMM_PREFIX = "MPT"
MPT.COMM_PREFIX = COMM_PREFIX
local MAX_SHARED_RUNS = 50
local REQUEST_TIMEOUT = 10
local LibDeflate = LibStub and LibStub("LibDeflate", true) or nil

-- ── Central comm dispatcher ──────────────────────────────────────

function MPT:TableShare_Enable()
	C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
	self:RegisterComm(COMM_PREFIX, "OnCommReceived")

	-- Override ChatThrottleLib's conservative defaults (same as TRP3/Chomp)
	if ChatThrottleLib then
		ChatThrottleLib.MAX_CPS = math.max(ChatThrottleLib.MAX_CPS, 2048)
		ChatThrottleLib.BURST = math.max(ChatThrottleLib.BURST, 6144)
		ChatThrottleLib.MSG_OVERHEAD = math.min(32, ChatThrottleLib.MSG_OVERHEAD)
	end
end

function MPT:OnCommReceived(prefix, message, distribution, sender)
	local myName = UnitName("player")
	local myRealm = GetRealmName()
	if sender == myName or sender == myName .. "-" .. myRealm then return end

	local ok, msgType, data = self:Deserialize(message)
	if not ok then return end

	-- For YELL-based messages, check if we are the intended target
	if distribution == "YELL" and data and data._target then
		local myFullName = myName .. "-" .. (GetNormalizedRealmName and GetNormalizedRealmName() or myRealm:gsub(" ", ""))
		if data._target ~= myName and data._target ~= myFullName then return end
	end

	-- Table sharing messages
	if msgType == "TABLE_REQ" then
		self:OnTableRequest(sender, data, distribution)
	elseif msgType == "TABLE_LIST_REQ" then
		self:OnTableListRequest(sender, distribution)
	elseif msgType == "TABLE_LIST_RESP" then
		self:OnTableListResponse(sender, data)
	elseif msgType == "TABLE_RESP" then
		self:OnTableResponse(sender, data)
	elseif msgType == "TABLE_RESP_Z" then
		self:OnTableResponseCompressed(sender, data)
	elseif msgType == "TABLE_DENIED" then
		self:OnTableDenied(sender)
	-- Party MVP browse (lightweight name-only list)
	elseif msgType == "BROWSE_MVPS" then
		self:OnBrowseMvpsReceived(sender, data)
	-- Player detect (lightweight presence check)
	elseif msgType == "PING" then
		self:OnPingReceived(sender, distribution)
	elseif msgType == "PONG" then
		self:PlayerDetect_OnPong(sender, data)
	end
end

-- ── Player detect (PING/PONG) ────────────────────────────────────

function MPT:OnPingReceived(sender, distribution)
	-- Only respond if sharing is enabled
	if self.db.global.shareTable == false then return end
	-- Dedup: sender sends via both WHISPER and YELL; only respond once
	local now = GetTime()
	self._lastPingFrom = self._lastPingFrom or {}
	if self._lastPingFrom[sender] and (now - self._lastPingFrom[sender]) < 5 then return end
	self._lastPingFrom[sender] = now
	local pongData = { runs = self.db.global.totalRuns or 0 }
	if distribution == "YELL" then
		pongData._target = sender
		local msg = self:Serialize("PONG", pongData)
		self:SendCommMessage(COMM_PREFIX, msg, "YELL")
	else
		local msg = self:Serialize("PONG", pongData)
		self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", sender)
	end
end

-- ── Table request / response ─────────────────────────────────────

function MPT:RequestTable(name, realm, tableName)
	if self.pendingTableRequest then
		self:Print("Already waiting for a table response...")
		return
	end

	local target = name
	if realm and realm ~= "" then
		target = name .. "-" .. realm
	end

	self:Print("Requesting M+ table from " .. target .. "...")
	self.pendingTableRequest = target

	local data = { _target = target }
	if tableName then data.tableName = tableName end
	local msg = self:Serialize("TABLE_REQ", data)
	self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", target)
	-- Also send via YELL for cross-faction (WHISPER is blocked cross-faction)
	self:SendCommMessage(COMM_PREFIX, msg, "YELL")

	-- Show loading indicator when switching remote tables
	if tableName and self:IsViewingRemote() then
		self:ShowRemoteTableLoading()
	end

	-- Timeout
	self.tableRequestTimer = C_Timer.After(REQUEST_TIMEOUT, function()
		if self.pendingTableRequest then
			self:Print(self.pendingTableRequest .. " did not respond. They may not have Mythic Memories or sharing is disabled.")
			self.pendingTableRequest = nil
			self:HideRemoteTableLoading()
		end
	end)
end

-- ── Compact wire format ──────────────────────────────────────────
-- Short keys, merged stats into members, no redundancy.
-- ~300 bytes/run instead of ~900. 12 runs fits in one burst.

function MPT:PackRunForShare(run)
	local members = {}
	for _, m in ipairs(run.members or {}) do
		local s = (run.playerStats or {})[m.guid] or {}
		local entry = {
			n = m.name,
			r = m.realm,
			c = m.class,
			rl = m.role,
		}
		-- Only include non-zero stats
		if (s.damage or 0) > 0 then entry.dm = s.damage end
		if (s.dps or 0) > 0 then entry.dp = s.dps end
		if (s.healing or 0) > 0 then entry.hl = s.healing end
		if (s.hps or 0) > 0 then entry.hp = s.hps end
		if (s.deaths or 0) > 0 then entry.dt = s.deaths end
		if (s.interrupts or 0) > 0 then entry.ir = s.interrupts end
		members[#members + 1] = entry
	end

	local packed = {
		i = run.id,
		d = run.date,
		dn = run.dungeon,
		l = run.level,
		t = run.timeStr,
		a = run.affix,
		b = run.bonus,
		o = run.onTime,
		td = run.totalDeaths,
		m = members,
	}
	if run.link and run.link ~= "" then packed.lk = run.link end
	if run.description and run.description ~= "" then packed.dc = run.description end
	return packed
end

function MPT:UnpackSharedRun(packed)
	local members = {}
	local playerStats = {}
	for idx, pm in ipairs(packed.m or {}) do
		local guid = "shared-" .. idx
		members[#members + 1] = {
			name = pm.n,
			realm = pm.r,
			class = pm.c,
			role = pm.rl,
			guid = guid,
		}
		playerStats[guid] = {
			name = pm.n,
			class = pm.c,
			role = pm.rl,
			damage = pm.dm or 0,
			dps = pm.dp or 0,
			healing = pm.hl or 0,
			hps = pm.hp or 0,
			deaths = pm.dt or 0,
			interrupts = pm.ir or 0,
		}
	end

	return {
		id = packed.i,
		date = packed.d,
		dungeon = packed.dn,
		level = packed.l,
		timeStr = packed.t,
		affix = packed.a,
		bonus = packed.b,
		onTime = packed.o,
		totalDeaths = packed.td or 0,
		members = members,
		playerStats = playerStats,
		link = packed.lk or "",
		description = packed.dc or "",
	}
end

function MPT:OnTableRequest(sender, data, distribution)
	-- Dedup: sender sends via both WHISPER and YELL; only respond once
	local now = GetTime()
	self._lastTableReqFrom = self._lastTableReqFrom or {}
	if self._lastTableReqFrom[sender] and (now - self._lastTableReqFrom[sender]) < 5 then return end
	self._lastTableReqFrom[sender] = now

	if self.db.global.shareTable == false then
		local denied = { _target = sender }
		local msg = self:Serialize("TABLE_DENIED", denied)
		if distribution == "YELL" then
			self:SendCommMessage(COMM_PREFIX, msg, "YELL")
		else
			self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", sender)
		end
		return
	end

	-- Find the requested table (default to active if no name specified)
	local requestedName = data and data.tableName or nil
	local runs
	if requestedName then
		for _, tbl in ipairs(self.db.global.tables or {}) do
			if tbl.name == requestedName then
				runs = tbl.runs
				break
			end
		end
	end
	if not runs then
		runs = self:GetActiveRuns()
	end

	local packed = {}
	local limit = self.shareLimit or MAX_SHARED_RUNS
	local count = math.min(#runs, limit)
	for i = 1, count do
		packed[i] = self:PackRunForShare(runs[i])
	end

	-- MVPs: nameRealm -> { class, note }
	local mvps = {}
	for nameRealm, mvpData in pairs(self.db.global.mvps or {}) do
		mvps[nameRealm] = {
			c = mvpData.class or nil,
			n = mvpData.note or nil,
		}
	end

	local _, myClass = UnitClass("player")
	local payload = { r = packed, v = mvps, sc = myClass, _target = sender }

	local serialized = self:Serialize("TABLE_RESP", payload)

	-- Compress with LibDeflate if available
	if LibDeflate then
		local compressed = LibDeflate:CompressDeflate(serialized, { level = 6 })
		local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
		local msg = self:Serialize("TABLE_RESP_Z", { _target = sender, z = encoded })
		if distribution == "YELL" then
			self:SendCommMessage(COMM_PREFIX, msg, "YELL", nil, "ALERT")
		else
			self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", sender, "ALERT")
		end
	else
		if distribution == "YELL" then
			self:SendCommMessage(COMM_PREFIX, serialized, "YELL", nil, "ALERT")
		else
			self:SendCommMessage(COMM_PREFIX, serialized, "WHISPER", sender, "ALERT")
		end
	end
end

function MPT:CancelTableRequestTimer()
	if self.tableRequestTimer then
		self.tableRequestTimer:Cancel()
		self.tableRequestTimer = nil
	end
end

function MPT:OnTableResponse(sender, data)
	if not self.pendingTableRequest then return end

	self.pendingTableRequest = nil
	self:CancelTableRequestTimer()

	if not data or not data.r then
		self:Print("Received invalid data from " .. sender)
		return
	end

	-- Unpack compact format back to normal run objects
	local runs = {}
	for i, packed in ipairs(data.r) do
		runs[i] = self:UnpackSharedRun(packed)
	end

	-- Unpack MVPs: value is table { c=class, n=note } or legacy class/true
	local mvps = {}
	for nameRealm, val in pairs(data.v or {}) do
		nameRealm = self:NormalizeNameRealm(nameRealm)
		if type(val) == "table" then
			mvps[nameRealm] = {
				class = val.c or nil,
				note = val.n or nil,
			}
		else
			-- Legacy format: value is class string or true
			mvps[nameRealm] = {
				class = (val ~= true) and val or nil,
			}
		end
	end

	self:EnterViewMode(sender, { runs = runs, mvps = mvps, senderClass = data.sc })

	-- Also request their table list for the remote dropdown
	local name, realm = sender:match("^([^%-]+)%-?(.*)$")
	self:RequestTableList(name, realm)
end

function MPT:OnTableResponseCompressed(sender, encoded)
	if not self.pendingTableRequest then return end

	-- Support wrapped format { z = encoded, _target = ... } from YELL responses
	if type(encoded) == "table" then encoded = encoded.z end

	if not LibDeflate or not encoded then
		self:Print("Received compressed data but LibDeflate is not available.")
		self.pendingTableRequest = nil
		return
	end

	local compressed = LibDeflate:DecodeForWoWAddonChannel(encoded)
	if not compressed then
		self:Print("Failed to decode data from " .. sender)
		self.pendingTableRequest = nil
		return
	end

	local serialized = LibDeflate:DecompressDeflate(compressed)
	if not serialized then
		self:Print("Failed to decompress data from " .. sender)
		self.pendingTableRequest = nil
		return
	end

	local ok, msgType, data = self:Deserialize(serialized)
	if not ok or msgType ~= "TABLE_RESP" then
		self:Print("Received invalid data from " .. sender)
		self.pendingTableRequest = nil
		return
	end

	self:OnTableResponse(sender, data)
end

function MPT:OnTableDenied(sender)
	if not self.pendingTableRequest then return end

	self.pendingTableRequest = nil
	self:CancelTableRequestTimer()
	self:Print(sender .. " has table sharing disabled.")
end

-- ── View mode ────────────────────────────────────────────────────

function MPT:EnterViewMode(playerName, data)
	-- Ensure mainFrame exists BEFORE setting viewingData
	-- (CreateMainFrame ends with frame:Hide() which triggers OnHide,
	--  and OnHide clears viewingData if viewingPlayer is set)
	if not self.mainFrame then
		self:CreateMainFrame()
	end

	self.viewingPlayer = playerName
	self.viewingData = {
		runs = data.runs or {},
		mvps = data.mvps or {},
	}

	self.expandedRunId = nil
	self:HideAllPopups()

	self:HideRemoteTableLoading()
	self:UpdateViewModeUI()
	self.mainFrame:Show()
	self:RefreshTable()
	self:RefreshMvpsSidePanel()

	self:Print("Viewing " .. playerName .. "'s M+ table (" .. #self.viewingData.runs .. " runs)")
end

function MPT:ExitViewMode()
	self.viewingPlayer = nil
	self.viewingClass = nil
	self.viewingData = nil
	self.remoteTableList = nil
	self.remoteTableOwner = nil

	self.expandedRunId = nil
	self:HideAllPopups()

	self:UpdateViewModeUI()
	self:RefreshTable()
	self:RefreshMvpsSidePanel()
end

function MPT:ImportViewedMvps()
	if not self.viewingData or not self.viewingData.mvps then
		self:Print("No MVP data to import.")
		return
	end

	local added = 0
	local skipped = 0
	local playerName = UnitName("player")

	for nameRealm, data in pairs(self.viewingData.mvps) do
		if self:AddMvp(nameRealm, playerName, data.class, data.note) then
			added = added + 1
		else
			skipped = skipped + 1
		end
	end

	if added > 0 then
		self:OnMvpChanged()
	end

	self:Print("Imported " .. added .. " new MVP(s). " .. skipped .. " already in your list.")
end

-- ── Table list request / response ──────────────────────────────

function MPT:RequestTableList(name, realm)
	local target = name
	if realm and realm ~= "" then
		target = name .. "-" .. realm
	end
	local msg = self:Serialize("TABLE_LIST_REQ", { _target = target })
	self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", target)
	-- Also send via YELL for cross-faction
	self:SendCommMessage(COMM_PREFIX, msg, "YELL")
end

function MPT:OnTableListRequest(sender, distribution)
	-- Dedup: sender sends via both WHISPER and YELL; only respond once
	local now = GetTime()
	self._lastTableListReqFrom = self._lastTableListReqFrom or {}
	if self._lastTableListReqFrom[sender] and (now - self._lastTableListReqFrom[sender]) < 5 then return end
	self._lastTableListReqFrom[sender] = now

	if self.db.global.shareTable == false then return end
	local names = {}
	for _, tbl in ipairs(self.db.global.tables or {}) do
		names[#names + 1] = tbl.name
	end
	local respData = { tables = names, _target = sender }
	local msg = self:Serialize("TABLE_LIST_RESP", respData)
	if distribution == "YELL" then
		self:SendCommMessage(COMM_PREFIX, msg, "YELL")
	else
		self:SendCommMessage(COMM_PREFIX, msg, "WHISPER", sender)
	end
end

function MPT:OnTableListResponse(sender, data)
	if not data or not data.tables then return end
	self.remoteTableList = data.tables
	self.remoteTableOwner = sender
	if self.UpdateRemoteTableDropdown then
		self:UpdateRemoteTableDropdown()
	end
end

function MPT:IsViewingRemote()
	return self.viewingPlayer ~= nil
end

-- ── Party MVP browsing (name-only list for Group Finder crowns) ──

-- Transient cache: { ["Sender-Realm"] = { ["MvpName-Realm"] = true, ... } }
MPT.partyMvpCache = {}

function MPT:BuildBrowseMvpsPayload()
	local mvps = {}
	for nameRealm, data in pairs(self.db.global.mvps or {}) do
		mvps[nameRealm] = data.note or ""
	end
	return self:Serialize("BROWSE_MVPS", { mvps = mvps })
end

function MPT:BroadcastBrowseMvps()
	if not IsInGroup() then return end
	self:SendCommMessage(COMM_PREFIX, self:BuildBrowseMvpsPayload(), "PARTY")
end

function MPT:WhisperBrowseMvps(targetName)
	if not targetName then return end
	self:SendCommMessage(COMM_PREFIX, self:BuildBrowseMvpsPayload(), "WHISPER", targetName)
end

function MPT:OnBrowseMvpsReceived(sender, data)
	if not data then return end

	if data.mvps then
		self.partyMvpCache[sender] = data.mvps
	end

	-- Refresh tooltip if currently showing a player affected by this update
	self:RefreshTooltipAfterMvpSync()

	-- Debounce: print summary once no more lists arrive for 2 seconds
	if self._browseMvpTimer then
		self._browseMvpTimer:Cancel()
	end
	self._browseMvpTimer = C_Timer.NewTimer(2, function()
		MPT._browseMvpTimer = nil
		if MPT.db and MPT.db.global.syncMessages == false then return end
		local names = {}
		for name in pairs(MPT.partyMvpCache) do
			names[#names + 1] = name:match("^([^%-]+)") or name
		end
		if #names > 0 then
			MPT:Print("|cFF808080Synced MVP lists:|r " .. table.concat(names, ", "))
		end
	end)
end

function MPT:PurgePartyMvpCache()
	-- Remove entries for players no longer in the group
	if not IsInGroup() then
		self.partyMvpCache = {}
		return
	end

	local groupMembers = {}
	local prefix = IsInRaid() and "raid" or "party"
	local count = GetNumGroupMembers()
	for i = 1, count do
		local unit = (prefix == "party") and (i < count and ("party" .. i) or "player") or ("raid" .. i)
		local name, realm = UnitName(unit)
		if name then
			if realm and realm ~= "" then
				groupMembers[name .. "-" .. realm] = true
			else
				groupMembers[name] = true
			end
		end
	end

	for sender in pairs(self.partyMvpCache) do
		-- Match sender (may or may not have realm) against group members
		if not groupMembers[sender] then
			local baseName = sender:match("^([^%-]+)")
			if not groupMembers[baseName] then
				self.partyMvpCache[sender] = nil
			end
		end
	end
end

function MPT:CheckPartyMvp(leaderName)
	-- Returns list of { sender, note } tables (empty table if no matches)
	if not leaderName then return {} end
	leaderName = self:NormalizeNameRealm(leaderName)
	local leaderBase = leaderName:match("^([^%-]+)")

	local results = {}
	for sender, mvpList in pairs(self.partyMvpCache) do
		local found = false
		-- Check exact match
		if mvpList[leaderName] ~= nil then
			results[#results + 1] = { sender = sender, note = mvpList[leaderName] }
			found = true
		end
		-- Check base name match (leader might be "Name" or "Name-Realm")
		if not found and leaderBase then
			for mvpName, note in pairs(mvpList) do
				local mvpBase = mvpName:match("^([^%-]+)")
				if mvpBase and mvpBase == leaderBase then
					results[#results + 1] = { sender = sender, note = note }
					break
				end
			end
		end
	end
	return results
end

-- ── Unit menu hook (TWW 11.x Menu API) ──────────────────────────

function MPT:HookUnitMenus()
	if not Menu or not Menu.ModifyMenu then return end

	local menuTags = {
		"MENU_UNIT_PLAYER",
		"MENU_UNIT_PARTY",
		"MENU_UNIT_RAID",
		"MENU_UNIT_RAID_PLAYER",
		"MENU_UNIT_FRIEND",
		"MENU_UNIT_ENEMY_PLAYER",
	}

	for _, menuTag in ipairs(menuTags) do
		Menu.ModifyMenu(menuTag, function(owner, rootDescription, contextData)
			if not owner or owner:IsForbidden() then return end
			if not contextData then return end

			-- Get player name and server from context (like TRP3 does)
			local name = contextData.name
			local server = contextData.server

			if not name then return end
			if not server or server == "" then
				server = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
			end

			-- Don't show for self
			local myName = UnitName("player")
			if name == myName then return end

			rootDescription:CreateButton("View M+ Table", function()
				MPT:RequestTable(name, server)
			end)

			local nameRealm = name .. "-" .. server
			-- UnitClass needs a unitId; try owner's unit, mouseover, then scan party/raid
			local unit = owner and not owner:IsForbidden() and owner.GetAttribute and owner:GetAttribute("unit")
			local _, class = UnitClass(unit or "mouseover")
			if not class then
				-- Scan party/raid units to find this player's class
				local prefix = IsInRaid() and "raid" or "party"
				local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
				for ci = 1, count do
					local uid = prefix .. ci
					local uName, uRealm = UnitName(uid)
					if uName == name then
						_, class = UnitClass(uid)
						break
					end
				end
			end
			if not class then
				-- Fall back to run history
				for _, tbl in ipairs(MPT.db.global.tables) do
					for _, run in ipairs(tbl.runs) do
						for _, m in ipairs(run.members or {}) do
							local mName = m.name:match("^([^%-]+)") or m.name
							if mName == name and m.class then
								class = m.class
								break
							end
						end
						if class then break end
					end
					if class then break end
				end
			end

			local matchedMvp = MPT:MatchMvpName(nameRealm)
			if matchedMvp then
				rootDescription:CreateButton("Remove from MVP List", function()
					local note = MPT:GetMvpNote(matchedMvp)
					if note and note ~= "" then
						MPT:ShowRemoveMvpConfirm(matchedMvp, class)
					else
						MPT:RemoveMvp(matchedMvp)
						MPT:OnMvpChanged()
					end
				end)
			else
				rootDescription:CreateButton("Add to MVP List", function()
					MPT:AddMvp(nameRealm, myName, class)
					MPT:OnMvpChanged()
					MPT:ShowAddNoteDialog(nameRealm, class)
				end)
			end
		end)
	end
end
