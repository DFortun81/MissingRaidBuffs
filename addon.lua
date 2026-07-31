local ADDON_NAME, ADDON = ...
local MODULE_NAME = "addon"

-- Globals cache
local print
	= print;

ADDON[1] = {} -- MRB, Addon
ADDON[2] = {} -- C, Config
ADDON[3] = setmetatable({}, { -- L, Locale
	__index = function(t, key)
		-- When a locale is not found, use the key (English) as the localization until a proper one is made
		t[key] = key;
		return key;
	end,
});
local MRB, C = unpack(ADDON)


---------------------------------------------
-- CONSTANTS
---------------------------------------------
MRB.ADDON_NAME = ADDON_NAME
MRB.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON_NAME, "Version")


---------------------------------------------
-- EVENTS & CALLBACKS
---------------------------------------------
MRB.callbacks = LibStub("CallbackHandler-1.0"):New(MRB)
MRB.eventCallbacks = LibStub("CallbackHandler-1.0"):New(MRB, "RegisterEvent", "UnregisterEvent", false)

local frame = CreateFrame("frame")
frame:SetScript("OnEvent", function(self, event, ...)
    MRB.eventCallbacks:Fire(event, ...)
end)

function MRB.eventCallbacks:OnUsed(target, event)
    frame:RegisterEvent(event)
end
function MRB.eventCallbacks:OnUnused(target, event)
    frame:UnregisterEvent(event)
end


---------------------------------------------
-- INITIALIZE
---------------------------------------------
MRB.RegisterEvent(MODULE_NAME, "ADDON_LOADED", function(event, addonName)
    if ( addonName == MRB.ADDON_NAME ) then
        MRB.UnregisterEvent(MODULE_NAME, "ADDON_LOADED")

        C:Load()

        -- Initialize addon modules
        MRB.callbacks:Fire("initialize")
    end
end)
