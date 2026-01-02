local addonName = ...
local db
local dbDefaults = {
	TargetKey = "TAB",
	TargetPreviousKey = "SHIFT-TAB",
}

local function CopyTable(src, dst)
	if type(dst) ~= "table" then
		dst = {}
	end

	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyTable(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end

	return dst
end

local function UpdateBindings()
	if InCombatLockdown() then
		return
	end

	local targetKey = db.TargetKey or dbDefaults.TargetKey
	local targetPreviousKey = db.TargetPreviousKey or dbDefaults.TargetPreviousKey
	local _, instanceType = IsInInstance()
	local isPvp = instanceType == "pvp" or instanceType == "arena"

	if isPvp then
		-- in pvp mode set tab to target player
		SetBinding(targetKey, "TARGETNEARESTENEMYPLAYER")
		SetBinding(targetPreviousKey, "TARGETPREVIOUSENEMYPLAYER")
	else
		-- in pve mode set tab to target enemy
		SetBinding(targetKey, "TARGETNEARESTENEMY")
		SetBinding(targetPreviousKey, "TARGETPREVIOUSENEMY")
	end
end

local function OnEvent()
	UpdateBindings()
end

local function Init()
	MiniTabTargetDB = MiniTabTargetDB or {}
	db = CopyTable(dbDefaults, MiniTabTargetDB)

	UpdateBindings()
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		Init()

		frame:UnregisterEvent("ADDON_LOADED")
		frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		frame:SetScript("OnEvent", OnEvent)
	end
end)
frame:RegisterEvent("ADDON_LOADED")
