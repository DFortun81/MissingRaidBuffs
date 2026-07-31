local MRB, C, L = unpack(select(2, ...))
local UnitIsConnected, UnitIsDeadOrGhost
	= UnitIsConnected, UnitIsDeadOrGhost

MRB.Model = {
    playerBuffCache = {},
    Status = {
        ALIVE = 1,
        DEAD = 2,
        DISCONNECTED = 3,
    }
}

MRB.Model.callbacks = LibStub("CallbackHandler-1.0"):New(MRB.Model)

local function DetermineUnitStatus(unit)
    if not UnitIsConnected(unit) then
        return MRB.Model.Status.DISCONNECTED
    elseif UnitIsDeadOrGhost(unit) then
        return MRB.Model.Status.DEAD
    end
	return MRB.Model.Status.ALIVE;
end

function MRB.Model:UpdatePlayerStatus(unit)
	local cache = MRB.Model.playerBuffCache[unit];
	if cache then
		local status = DetermineUnitStatus(unit)
		if cache.status ~= status then
			cache.status = status
			MRB.Model.callbacks:Fire("updatedModel", unit)
		end
	end
end

function MRB.Model:SetPlayerBuff(unit, missingBuffs)
    if #missingBuffs <= 0 then
        MRB.Model.playerBuffCache[unit] = nil
    else
		local cache = MRB.Model.playerBuffCache[unit];
		if not cache then
			cache = {};
			MRB.Model.playerBuffCache[unit] = cache;
		end
		
		cache.status = DetermineUnitStatus(unit)
        cache.missingBuffs = missingBuffs
    end

    MRB.Model.callbacks:Fire("updatedModel", unit)
end

function MRB.Model:RemoveAll()
    MRB.Model.playerBuffCache = {}
end

function MRB.Model:Get()
    return MRB.Model.playerBuffCache
end
