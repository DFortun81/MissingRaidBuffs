local MRB, C, L = unpack(select(2, ...))
local MODULE_NAME = "config"

-- Globals cache
local ipairs, pairs, next, type, select, strsplit, tinsert, tremove, C_CreatureInfo, GetSpellInfo
	= ipairs, pairs, next, type, select, strsplit, tinsert, tremove, C_CreatureInfo, GetSpellInfo

---------------------------------------------
-- CONSTANTS
---------------------------------------------
local PLAYER_CLASS = select(2,UnitClass("player"));
local IS_ALLIANCE = UnitFactionGroup("player")~="Horde"
local IS_PRIEST = PLAYER_CLASS == "PRIEST"
local IS_MAGE = PLAYER_CLASS == "MAGE"
local IS_DRUID = PLAYER_CLASS == "DRUID"
local IS_PALADIN = PLAYER_CLASS == "PALADIN"
local PLAYER_LEVEL = UnitLevel("player");
local MAX_LEVEL = 60

-- Classic Raid Buffs
local POWER_WORD_FORTITUDE_SPELLID = 10938	-- Power Word: Fortitude (Rank 6)
local PRAYER_OF_FORTITUDE_SPELLID = 21564	-- Prayer of Fortitude (Rank 2)
local DIVINE_SPIRIT_SPELLID = 27841	-- Divine Spirit (Rank 4)
local PRAYER_OF_SPIRIT_SPELLID = 27681	-- Prayer of Spirit (Rank 1)
local SHADOW_PROTECTION_SPELLID = 10958	-- Shadow Protection (Rank 3)
local PRAYER_OF_SHADOW_PROTECTION_SPELLID = 27683	-- Prayer of Shadow Protection (Rank 1)
local ARCANE_INTELLECT_SPELLID = 10157	-- Arcane Intellect (Rank 5)
local ARCANE_BRILLIANCE_SPELLID = 23028	-- Arcane Brilliance (Rank 1)
local MARK_OF_THE_WILD_SPELLID = 9885	-- Mark of the Wild (Rank 7)
local GIFT_OF_THE_WILD_SPELLID = 21849	-- Gift of the Wild (Rank 1)
local BLESSING_OF_KINGS_SPELLID = 20217	-- Blessing of Kings
local GREATER_BLESSING_OF_KINGS_SPELLID = 25898	-- Greater Blessing of Kings
local BLESSING_OF_LIGHT_SPELLID = 19979	-- Blessing of Light (Rank 3)
local GREATER_BLESSING_OF_LIGHT_SPELLID = 25890	-- Greater Blessing of Light (Rank 1)
local BLESSING_OF_MIGHT_SPELLID = 25291	-- Blessing of Might (Rank 7)
local GREATER_BLESSING_OF_MIGHT_SPELLID = 25916	-- Greater Blessing of Might (Rank 2)
local BLESSING_OF_WISDOM_SPELLID = 25290	-- Blessing of Wisdom (Rank 6)
local GREATER_BLESSING_OF_WISDOM_SPELLID = 25918	-- Greater Blessing of Wisdom (Rank 2)
local BLESSING_OF_SALVATION_SPELLID = 1038	-- Blessing of Salvation
local GREATER_BLESSING_OF_SALVATION_SPELLID = 25895	-- Greater Blessing of Salvation
local BLESSING_OF_SANCTUARY_SPELLID = 20914	-- Blessing of Sanctuary (Rank 4)
local GREATER_BLESSING_OF_SANCTUARY_SPELLID = 25899	-- Greater Blessing of Sanctuary (Rank 1)

-- Switch the desired spellIDs based on the game flavor
local version = select(7, GetBuildInfo());
if version >= 20000 then
	-- TBC Raid Buffs
	MAX_LEVEL = 70
	POWER_WORD_FORTITUDE_SPELLID = 25389	-- Power Word: Fortitude (Rank 7)
	PRAYER_OF_FORTITUDE_SPELLID = 25392	-- Prayer of Fortitude (Rank 3)
	DIVINE_SPIRIT_SPELLID = 25312	-- Divine Spirit (Rank 5)
	PRAYER_OF_SPIRIT_SPELLID = 32999	-- Prayer of Spirit (Rank 2)
	SHADOW_PROTECTION_SPELLID = 25433	-- Shadow Protection (Rank 4)
	PRAYER_OF_SHADOW_PROTECTION_SPELLID = 39374	-- Prayer of Shadow Protection (Rank 2)
	ARCANE_INTELLECT_SPELLID = 27126	-- Arcane Intellect (Rank 6)
	ARCANE_BRILLIANCE_SPELLID = 27127	-- Arcane Brilliance (Rank 2)
	MARK_OF_THE_WILD_SPELLID = 26990	-- Mark of the Wild (Rank 8)
	GIFT_OF_THE_WILD_SPELLID = 26991	-- Gift of the Wild (Rank 3)
	BLESSING_OF_LIGHT_SPELLID = 27144	-- Blessing of Light (Rank 4)
	GREATER_BLESSING_OF_LIGHT_SPELLID = 27145	-- Greater Blessing of Light (Rank 2)
	BLESSING_OF_MIGHT_SPELLID = 27140	-- Blessing of Might (Rank 8)
	GREATER_BLESSING_OF_MIGHT_SPELLID = 27141	-- Greater Blessing of Might (Rank 3)
	BLESSING_OF_WISDOM_SPELLID = 27142	-- Blessing of Wisdom (Rank 7)
	GREATER_BLESSING_OF_WISDOM_SPELLID = 27143	-- Greater Blessing of Wisdom (Rank 3)
	BLESSING_OF_SANCTUARY_SPELLID = 27168	-- Blessing of Sanctuary (Rank 5)
	GREATER_BLESSING_OF_SANCTUARY_SPELLID = 27169	-- Greater Blessing of Sanctuary (Rank 2)
end


---------------------------------------------
-- VARIABLES
---------------------------------------------
local db
local optionListeners = LibStub("CallbackHandler-1.0"):New(C, "RegisterListener", "UnregisterListener", false)
local buffsDatatype


---------------------------------------------
-- UTILITIES
---------------------------------------------
local function clone(instance)
    local obj = {}
    local k,v = next(instance)
    while ( k ~= nil ) do
        obj[k] = ( type(v) == "table" ) and clone(v) or v
        k,v = next(instance, k)
    end
    return obj;
end

local function recreateBuffsDatatype()
    buffsDatatype = {
        List = {},
        Mapping = {}
    }

    for key,details in ipairs(db.profile.Auras) do
        if details.Enabled and details.Visible then
            tinsert(buffsDatatype.List, key)
            for _,spellId in ipairs(details.Spells) do
                buffsDatatype.Mapping[spellId] = key
            end
        end
    end
	
	-- For non-max level players, only match by the name rather than the exact spellID.
	PLAYER_LEVEL = UnitLevel("player");
	if PLAYER_LEVEL < MAX_LEVEL or not C:is("MaxRanksOnly") then
		for _,key in ipairs(buffsDatatype.List) do
			local details = db.profile.Auras[key];
			for _,spellId in ipairs(details.Spells) do
				local buffname = GetSpellInfo(spellId)
				if buffname then
					buffsDatatype.Mapping[buffname] = key
				end
			end
		end
	end

    --DevTools_Dump({buffsDatatype})
end

---------------------------------------------
-- CONFIG METHODS
---------------------------------------------
function C:is(option)
    local value = C:get(option)
    --assert(type(value) == "boolean", "boolean type of required for is(..)")
    return value == true
end

function C:get(option)
    if ( db ) then
        -- Walk the path until we have a final value
        local path = { strsplit("./", option) }
        local obj = db.profile
        for _,v in ipairs(path) do
            obj = obj[v]
            if ( obj == nil ) then
                error("Failed to find option '" .. option .. "'")
            end
        end
        return obj
    end

    return nil
end

function C:GetBuffMapping()
    return buffsDatatype.Mapping
end

function C:GetEnabledBuffs()
    return buffsDatatype.List
end

function C:GetAllBuffs()
    return db.profile.Auras
end

function C:BuffIsEnabled(buffIndex)
    return db.profile.Auras[buffIndex].Enabled
end

function C:BuffIsRequiredForClassRole(className, role, buffIndex)
	local aura = db.profile.Auras[buffIndex];
	if aura.Enabled then
		return aura.Filters[className] and aura.Roles[role]
	end
	return false;
end

function C:ToggleBuff(buffIndex)
    local buff = db.profile.Auras[buffIndex]
    buff.Enabled = not buff.Enabled
    recreateBuffsDatatype()
    optionListeners:Fire("updateBuffs")
end

function C:RefreshOnlyMaxRanks()
    recreateBuffsDatatype()
    optionListeners:Fire("updateBuffs")
end

function C:GetBuffInfo(buffIndex)
    local buff = db.profile.Auras[buffIndex]
    local spellName, _, texture = GetSpellInfo(buff.Spells[1])
    return buff.Enabled, spellName, texture
end


---------------------------------------------
-- OPTIONS
---------------------------------------------
local CURRENT_DB_VERSION = 1
C.DEFAULT_DB = {
    profile = {
        ["Show"] = true,
        ["Locked"] = false,
        ["HideWhenEmpty"] = false, -- false by default so initial users can position windows
        ["HideWhenInCombat"] = false,
        ["HideWhenNotInGroup"] = false,
		["MaxRanksOnly"] = true,
        ["FilterGroupSize"] = 15,
        ["ShowAllGroups"] = false,
        ["GroupAssignments"] = {
            ["group1"] = true,
            ["group2"] = true,
            ["group3"] = true,
            ["group4"] = true,
            ["group5"] = true,
            ["group6"] = true,
            ["group7"] = true,
            ["group8"] = true
        },
        ["Auras"] = {
            { -- "Power Word: Fortitude"
                Enabled = IS_PRIEST,
				Visible = true,
                Spells = {
                    POWER_WORD_FORTITUDE_SPELLID,
                    PRAYER_OF_FORTITUDE_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
            { -- "Divine Spirit"
                Enabled = IS_PRIEST, -- and has divine spirit talent
				Visible = true,
                Spells = {
                    DIVINE_SPIRIT_SPELLID,
                    PRAYER_OF_SPIRIT_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = false,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = false,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
            { -- "Shadow Protection"
                Enabled = false,
				Visible = true,
                Spells = {
                    SHADOW_PROTECTION_SPELLID,
                    PRAYER_OF_SHADOW_PROTECTION_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
            { -- "Arcane Intellect"
                Enabled = IS_MAGE,
				Visible = true,
                Spells = {
                    ARCANE_INTELLECT_SPELLID,
                    ARCANE_BRILLIANCE_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = false,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = false,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
            { -- "Mark of the Wild"
                Enabled = IS_DRUID,
				Visible = true,
                Spells = {
                    MARK_OF_THE_WILD_SPELLID,
                    GIFT_OF_THE_WILD_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Kings"
                Enabled = IS_PALADIN,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_KINGS_SPELLID,
                    GREATER_BLESSING_OF_KINGS_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Might"
                Enabled = IS_PALADIN,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_MIGHT_SPELLID,
                    GREATER_BLESSING_OF_MIGHT_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = false,
                    ["PALADIN"] = true,
                    ["PRIEST"] = false,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = false,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = false,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Wisdom"
                Enabled = IS_PALADIN,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_WISDOM_SPELLID,
                    GREATER_BLESSING_OF_WISDOM_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = false,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = false,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Light"
                Enabled = IS_PALADIN,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_LIGHT_SPELLID,
                    GREATER_BLESSING_OF_LIGHT_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Salvation"
                Enabled = IS_PALADIN,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_SALVATION_SPELLID,
                    GREATER_BLESSING_OF_SALVATION_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = false,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
			{ -- "Blessing of Sanctuary"
                Enabled = false,
				Visible = version >= 20000 or IS_ALLIANCE,
                Spells = {
                    BLESSING_OF_SANCTUARY_SPELLID,
                    GREATER_BLESSING_OF_SANCTUARY_SPELLID
                },
                Filters = {
                    ["DRUID"] = true,
                    ["HUNTER"] = true,
                    ["MAGE"] = true,
                    ["PALADIN"] = true,
                    ["PRIEST"] = true,
                    ["ROGUE"] = true,
                    ["SHAMAN"] = true,
                    ["WARLOCK"] = true,
                    ["WARRIOR"] = true,
                },
				Roles = {
					["TANK"] = true,
					["HEALER"] = true,
					["DAMAGER"] = true,
					["NONE"] = true,
				},
            },
        },
    }
}
function C:upgradeDB()
    if ( db.profile.DBVersion == nil ) then
        db.profile.DBVersion = CURRENT_DB_VERSION
    end
end

local function getOption(info)
    return C:get(info.arg)
end

local function setOption(info, value)
    if ( db ) then
        -- Walk the path until we have a final value
        local path = { strsplit("./", info.arg) }
        local o = db.profile
        local finalArg = tremove(path, #path)
        for _,v in ipairs(path) do
            o = o[v]
        end
        o[finalArg] = value

        optionListeners:Fire(info.arg, value)
    end
end

---------------------------------------------
-- CONFIG
---------------------------------------------
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local MRBConfigTable = {
    type = "group",
    name = L["Missing Raid Buffs"],
    args = {
        general = {
            order = 1,
            type = "group",
            name = GENERAL,
            args = {
                resetDefaults = {
                    order = 9000,
                    type = "execute",
                    name = L["Reset to Defaults"],
                    desc = L["Reset all options, frame sizing, and position to defaults"],
                    func = function()
                        MissingRaidBuffsListView:ClearAllPoints()
                        MissingRaidBuffsListView:SetPoint("CENTER", UIParent)
                        MissingRaidBuffsListView:SetSize(150, 100)
                        db:ResetProfile()
                        --MissingRaidBuffsDB = clone(C.DEFAULT_DB)
                        optionListeners:Fire("Locked", C:get("Locked"))
                    end
                },
                desc = {
                    order = 1,
                    type = "description",
                    name = L["List missing raid buffs for party & raid members"],
                    width = "full"
                },
                emptySpace = {
                    order = 3,
                    type = "description",
                    name = " ",
                    width = "full"
                },
                show = {
                    order = 10,
                    type = "toggle",
                    name = L["Show window"],
                    desc = L["Show the Missing Raid Buffs frame"],
                    set = setOption,
                    get = getOption,
                    width = "full",
                    arg = "Show"
                },
                lock = {
                    order = 20,
                    type = "toggle",
                    name = L["Lock window"],
                    desc = L["Disable dragging and resizing of the window"],
                    set = setOption,
                    get = getOption,
                    width = "full",
                    arg = "Locked"
                },
                hideWhenEmpty = {
                    order = 30,
                    type = "toggle",
                    name = L["Hide when empty"],
                    desc = L["Hide window when there are no missing buffs"],
                    set = setOption,
                    get = getOption,
                    width = "full",
                    arg = "HideWhenEmpty"
                },
                hideWhenInCombat = {
                    order = 40,
                    type = "toggle",
                    name = L["Hide frame when in combat"],
                    desc = L["Hide window during combat"],
                    set = setOption,
                    get = getOption,
                    width = "full",
                    arg = "HideWhenInCombat"
                },
                hideWhenNotInGroup = {
                    order = 60,
                    type = "toggle",
                    name = L["Hide when not in group"],
                    desc = L["Hide window when not in party or raid"],
                    set = setOption,
                    get = getOption,
                    width = "full",
                    arg = "HideWhenNotInGroup"
                },
				maxRanksOnly = {
					order = 70,
					type = "toggle",
					name = L["Max Ranks Only"],
					desc = L["Whether or not to only detect Max Ranks of spells.\n\nThis setting is automatically ignored on non-max level characters."],
                    set = setOption,
                    get = getOption,
                    width = "full",
					arg = "MaxRanksOnly"
				},
                groupAssignments = {
                    order = 200,
                    type = "group",
                    name = L["Group Assignments"],
                    inline = true,
                    args = {
                        filterGroupSize = {
                            order = 10,
                            type = "select",
                            name = L["Group size"],
                            desc = L["Do not apply group assignments to groups smaller than the selected size"],
                            set = setOption,
                            get = getOption,
                            values = {
                                [2] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE2PLAYERS,
                                [3] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE3PLAYERS,
                                [5] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE5PLAYERS,
                                [10] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE10PLAYERS,
                                [15] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE15PLAYERS,
                                [20] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE20PLAYERS,
                                [40] = COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE40PLAYERS,
                            },
                            width = "normal",
                            arg = "FilterGroupSize"
                        },
                        filterGroupSize_spacer = {
                            order = 19,
                            type = "description",
                            name = "",
                            width = "double",
                        },
                        showAllGroups = {
                            order = 20,
                            type = "select",
                            name = DISPLAY,
                            desc = L["Determine how your assigned groups are displayed"],
                            set = setOption,
                            get = getOption,
                            values = {
                                [false] = L["Show only my assigned groups"],
                                [true] = L["Show all groups, prioritizing my assigned groups"],
                            },
                            width = "double",
                            arg = "ShowAllGroups"
                        },
                        showAllGroups_spacer = {
                            order = 29,
                            type = "description",
                            name = "",
                            width = "normal",
                        },
                        group_spacer = {
                            order = 30,
                            type = "description",
                            name = " ",
                            width = "full"
                        },
                        group1 = {
                            order = 40,
                            type = "toggle",
                            name = L["Group %d"]:format(1),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group1"
                        },
                        group2 = {
                            order = 45,
                            type = "toggle",
                            name = L["Group %d"]:format(2),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group2"
                        },
                        row1spacer = {
                            order = 49,
                            type = "description",
                            name = "",
                            width = "normal",
                        },
                        group3 = {
                            order = 50,
                            type = "toggle",
                            name = L["Group %d"]:format(3),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group3"
                        },
                        group4 = {
                            order = 55,
                            type = "toggle",
                            name = L["Group %d"]:format(4),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group4"
                        },
                        row2spacer = {
                            order = 59,
                            type = "description",
                            name = "",
                            width = "normal",
                        },
                        group5 = {
                            order = 60,
                            type = "toggle",
                            name = L["Group %d"]:format(5),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group5"
                        },
                        group6 = {
                            order = 65,
                            type = "toggle",
                            name = L["Group %d"]:format(6),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group6"
                        },
                        row3spacer = {
                            order = 69,
                            type = "description",
                            name = "",
                            width = "normal",
                        },
                        group7 = {
                            order = 70,
                            type = "toggle",
                            name = L["Group %d"]:format(7),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group7"
                        },
                        group8 = {
                            order = 75,
                            type = "toggle",
                            name = L["Group %d"]:format(8),
                            set = setOption,
                            get = getOption,
                            width = "normal",
                            arg = "GroupAssignments/group8"
                        },
                        row4spacer = {
                            order = 79,
                            type = "description",
                            name = "",
                            width = "normal",
                        },
                    },
                },
            },
        },
        --[[auras = {
            order = 20,
            type = "group",
            name = L["Buffs"],
            args = {
                -- dynamically generated based on DB.Auras
            },
        },]]
        profiles = {
            order = 30,
            type = "group",
            name = L["Profiles"],
            args = {
                currentProfileLabel = {
                    order = 1,
                    type = "description",
                    name = L["Current profile:"],
                    width = "normal"
                },
                currentProfile = {
                    order = 2,
                    type = "description",
                    name = function() return db:GetCurrentProfile() end,
                    width = "double"
                },
            }
        },
    },
}
AceConfigRegistry:RegisterOptionsTable(MRB.ADDON_NAME, MRBConfigTable, true)

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local configPanes = {}
configPanes.general = AceConfigDialog:AddToBlizOptions(MRB.ADDON_NAME, MRB.ADDON_NAME, nil, "general")
--configPanes.auras = AceConfigDialog:AddToBlizOptions(MRB.ADDON_NAME, L["Buffs"], MRB.ADDON_NAME, "auras")
configPanes.profiles = AceConfigDialog:AddToBlizOptions(MRB.ADDON_NAME, L["Profiles"], MRB.ADDON_NAME, "profiles")
C.GENERAL_OPTIONS = configPanes.general.name

function C:reloadDB()
    self:upgradeDB()
    recreateBuffsDatatype()
end

---------------------------------------------
-- INITIALIZE
---------------------------------------------
function C:Load()
    db = LibStub("AceDB-3.0"):New("MissingRaidBuffsDB", C.DEFAULT_DB)
    db.RegisterCallback(C, "OnProfileChanged", "reloadDB")
    db.RegisterCallback(C, "OnProfileCopied", "reloadDB")
    db.RegisterCallback(C, "OnProfileReset", "reloadDB")
    C:upgradeDB()
end

MRB.RegisterCallback(MODULE_NAME, "initialize", function()
    C:reloadDB()
end)
