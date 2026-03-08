local _, MPT = ...

local CHANNEL_NAME = "mptmvps"
local COMM_PREFIX = "MPT"

function MPT:MvpSync_Enable()
	-- Comm registration is handled centrally in TableShare_Enable
	local channelIndex = self:JoinSyncChannel()
	self.syncChannelIndex = channelIndex

	-- Delayed sync request after login (channel join needs time)
	C_Timer.After(3, function()
		self:RequestMvpSync()
	end)
end

function MPT:JoinSyncChannel()
	return JoinChannelByName(CHANNEL_NAME)
end

function MPT:GetSyncChannelIndex()
	if self.syncChannelIndex then
		return self.syncChannelIndex
	end
	local id = GetChannelName(CHANNEL_NAME)
	self.syncChannelIndex = id
	return id
end

function MPT:RequestMvpSync()
	local msg = self:Serialize("SYNC_REQUEST", {})
	local channel = self:GetSyncChannelIndex()
	if channel and channel > 0 then
		self:SendCommMessage(COMM_PREFIX, msg, "CHANNEL", tostring(channel))
	end
end

function MPT:BroadcastMvpAdd(nameRealm)
	local mvpData = self.db.global.mvps[nameRealm]
	local msg = self:Serialize("MVP_ADD", {
		name = nameRealm,
		addedBy = UnitName("player"),
		date = time(),
		class = mvpData and mvpData.class or nil,
		note = mvpData and mvpData.note or nil,
	})
	local channel = self:GetSyncChannelIndex()
	if channel and channel > 0 then
		self:SendCommMessage(COMM_PREFIX, msg, "CHANNEL", tostring(channel))
	end
end

function MPT:BroadcastMvpRemove(nameRealm)
	local msg = self:Serialize("MVP_REMOVE", {
		name = nameRealm,
	})
	local channel = self:GetSyncChannelIndex()
	if channel and channel > 0 then
		self:SendCommMessage(COMM_PREFIX, msg, "CHANNEL", tostring(channel))
	end
end

function MPT:SendFullMvpList(target)
	local list = {}
	for nameRealm, data in pairs(self.db.global.mvps) do
		table.insert(list, {
			name = nameRealm,
			addedBy = data.addedBy,
			addedDate = data.addedDate,
			class = data.class,
			note = data.note,
		})
	end
	local msg = self:Serialize("SYNC_FULL", list)
	local channel = self:GetSyncChannelIndex()
	if channel and channel > 0 then
		self:SendCommMessage(COMM_PREFIX, msg, "CHANNEL", tostring(channel))
	end
end

-- OnMvpCommReceived logic moved to central dispatcher in TableShare.lua

function MPT:MergeMvpList(list)
	for _, entry in ipairs(list) do
		if entry.name and not self:IsMvp(entry.name) then
			self:AddMvp(entry.name, entry.addedBy or "Synced", entry.class, entry.note)
		end
	end
end
