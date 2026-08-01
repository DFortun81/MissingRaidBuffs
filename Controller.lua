local MRB, C, L = unpack(select(2, ...))
local MODULE_NAME = "Controller"

-- Globals cache
local ipairs, tinsert, BUFF_MAX_DISPLAY
	= ipairs, tinsert, BUFF_MAX_DISPLAY;
local UnitBuff, UnitInParty, UnitInRaid, GetNumGroupMembers, GetNumSubgroupMembers, UnitClass, UnitGroupRolesAssigned
	= UnitBuff, UnitInParty, UnitInRaid, GetNumGroupMembers, GetNumSubgroupMembers, UnitClass, UnitGroupRolesAssigned;

---------------------------------------------
-- CONSTANTS
---------------------------------------------
local PLAYER_NAME = UnitName("player")
local COMBATLOG_OBJECT_AFFILIATION_RAID_OR_PARTY = bit.bor(COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_MINE)


---------------------------------------------
-- UTILITIES
---------------------------------------------
local function isUnitAllowed(unit)
	if UnitInRaid("player") then
		return unit:match("^raid%d+$")
	end
	return unit == "player" or (UnitInParty("player") and unit:match("^party%d+$"))
end


---------------------------------------------
-- TRACK BUFFS
---------------------------------------------
local function updateUnitBuffs(unit)
	-- Determine what mapped buffs are on the unit
	local cache = {};
	local buffMapping = C:GetBuffMapping();
	for buffId = 1,BUFF_MAX_DISPLAY do
		local name, icon, _, debuffType, _, _, _, _, _, spellId = UnitBuff(unit, buffId)
		if spellId then
			local buffIndex = buffMapping[spellId] or (name and buffMapping[name]);
			if buffIndex then cache[buffIndex] = true; end
		else
			break;
		end
	end

	-- Determine which of the required buffs were not cached on the unit
	local missing = {}
	local role = UnitGroupRolesAssigned(unit)
	local className = select(2, UnitClass(unit))
	for _,buffIndex in ipairs(C:GetEnabledBuffs()) do
		if not cache[buffIndex] and C:BuffIsRequiredForClassRole(className, role, buffIndex) then
			tinsert(missing, buffIndex)
		end
	end
	MRB.Model:SetPlayerBuff(unit, missing)
end

local function refreshAllPartyRaidBuffs()
    MRB.Model:RemoveAll()
    if UnitInRaid("player") then
        for raidId = 1,GetNumGroupMembers() do
            updateUnitBuffs("raid"..raidId)
        end
    else
		if UnitInParty("player") then
			for partyId = 1,GetNumSubgroupMembers() do
				updateUnitBuffs("party"..partyId)
			end
		end
		updateUnitBuffs("player")
	end
end


---------------------------------------------
-- INITIALIZE
---------------------------------------------
MRB.RegisterCallback(MODULE_NAME, "initialize", function()
    -- Watch for buff applied/removed
    MRB.RegisterEvent(MODULE_NAME, "UNIT_AURA", function(event, unit)
		if isUnitAllowed(unit) then
			updateUnitBuffs(unit)
		end
    end)

    -- Reload all buffs when we first enter the world
    MRB.RegisterEvent(MODULE_NAME, "PLAYER_ENTERING_WORLD", refreshAllPartyRaidBuffs)

    -- Reload all buffs when group updates
    MRB.RegisterEvent(MODULE_NAME, "GROUP_ROSTER_UPDATE", refreshAllPartyRaidBuffs)

    -- Reload all buffs when configured buffs upates
    C.RegisterListener(MODULE_NAME, "updateBuffs", refreshAllPartyRaidBuffs)
end)
