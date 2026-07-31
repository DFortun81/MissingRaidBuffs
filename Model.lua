local MRB, C, L = unpack(select(2, ...))
MRB.Model = {
    playerBuffCache = {},
    Status = {
        ALIVE = 1,
        DEAD = 2,
        DISCONNECTED = 3,
    }
}

MRB.Model.callbacks = LibStub("CallbackHandler-1.0"):New(MRB.Model)


function MRB.Model:SetPlayerStatus(unit, status)
	local cache = MRB.Model.playerBuffCache[unit];
    if cache and cache.status ~= status then
        cache.status = status
        MRB.Model.callbacks:Fire("updatedModel", unit)
    end
end

function MRB.Model:SetPlayerBuff(unit, missingBuffs, status)
    if #missingBuffs <= 0 then
        MRB.Model.playerBuffCache[unit] = nil
    else
        MRB.Model.playerBuffCache[unit] = {
            ["missingBuffs"] = missingBuffs,
            ["status"] = status
        }
    end

    MRB.Model.callbacks:Fire("updatedModel", unit)
end

function MRB.Model:RemoveAll()
    MRB.Model.playerBuffCache = {}
end

function MRB.Model:Get()
    return MRB.Model.playerBuffCache
end
