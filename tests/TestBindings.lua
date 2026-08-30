-- Drives UpdateBindings through the mocked client: which action each key binds to per PvP
-- bracket, and how a bracket turned off falls back to the normal keys.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

-- WowMock.Install rebuilds C_PvP and SetBinding on every harness.Load, but this restore is here
-- for a suite that does not reinstall the mock.
local originalCPvP = _G.C_PvP
local originalSetBinding = _G.SetBinding

---Bindings SetBinding was last called with, keyed by the key it bound.
local bindings

local function RecordBinding(key, action)
	bindings[key] = action
end

---Loads the addon with a SetBinding recorder installed and the given saved-variable overrides.
local function LoginWith(dbOverrides)
	local context = harness.Load("MiniTabTarget")

	bindings = {}
	_G.SetBinding = RecordBinding

	-- written before ADDON_LOADED, which is where the addon reads its saved variables
	_G.MiniTabTargetDB = dbOverrides

	harness.Login(context)

	return context
end

---Sets the zone the addon sees and fires the event UpdateBindings listens for.
local function SetZone(instanceType)
	WowMock.State.InstanceType = instanceType
	WowMock.State.InInstance = instanceType ~= "none"
	WowMock.FireEvent("ZONE_CHANGED_NEW_AREA")
end

local function AssertKeys(targetAction, previousAction)
	fw.eq(bindings.TAB, targetAction, "target key")
	fw.eq(bindings["SHIFT-TAB"], previousAction, "previous-target key")
end

fw.describe("MiniTabTarget - bindings", function()
	fw.it("targets the nearest enemy outside an instance", function()
		LoginWith({})

		SetZone("none")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")
	end)

	fw.it("targets the nearest enemy player in arena when Arena is enabled", function()
		LoginWith({})

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMYPLAYER", "TARGETPREVIOUSENEMYPLAYER")
	end)

	fw.it("falls back to the normal keys in arena when Arena is disabled", function()
		LoginWith({ Arena = false })

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")
	end)

	fw.it("keeps solo shuffle independent of arena", function()
		LoginWith({ Arena = true, SoloShuffle = false })

		_G.C_PvP.IsSoloShuffle = function()
			return true
		end

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")
	end)

	fw.it("targets the nearest enemy player in a battleground when Battleground is enabled", function()
		LoginWith({ Battleground = true })

		SetZone("pvp")

		AssertKeys("TARGETNEARESTENEMYPLAYER", "TARGETPREVIOUSENEMYPLAYER")
	end)

	fw.it("falls back to the normal keys in a battleground when Battleground is disabled", function()
		LoginWith({ Battleground = false })

		SetZone("pvp")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")
	end)

	fw.it("follows Arena on a classic client with no C_PvP", function()
		LoginWith({ Arena = true })

		_G.C_PvP = nil

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMYPLAYER", "TARGETPREVIOUSENEMYPLAYER")
	end)

	fw.it("applies a binding change made during combat once combat ends", function()
		LoginWith({})

		WowMock.State.InCombat = true

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")

		WowMock.State.InCombat = false
		WowMock.FireEvent("PLAYER_REGEN_ENABLED")

		AssertKeys("TARGETNEARESTENEMYPLAYER", "TARGETPREVIOUSENEMYPLAYER")
	end)

	fw.it("re-reads the bracket when UPDATE_BATTLEFIELD_STATUS fires on its own", function()
		LoginWith({ SoloShuffle = false, Arena = true })

		SetZone("arena")

		AssertKeys("TARGETNEARESTENEMYPLAYER", "TARGETPREVIOUSENEMYPLAYER")

		-- The match type can settle after the zone change, with no zone change of its own.
		_G.C_PvP.IsSoloShuffle = function()
			return true
		end
		WowMock.FireEvent("UPDATE_BATTLEFIELD_STATUS")

		AssertKeys("TARGETNEARESTENEMY", "TARGETPREVIOUSENEMY")
	end)

	fw.it("folds a rated battleground left on into the merged Battleground toggle", function()
		local context = LoginWith({ Battleground = true, RatedBattleground = true })

		fw.eq(context.Addon.Db.Battleground, true, "battleground stays on")
		fw.eq(context.Addon.Db.RatedBattleground, nil, "the retired key is gone")
	end)

	fw.it("folds a rated battleground left off without disturbing an unrated toggle left on", function()
		local context = LoginWith({ Battleground = true, RatedBattleground = false })

		fw.eq(context.Addon.Db.Battleground, true, "battleground stays on")
		fw.eq(context.Addon.Db.RatedBattleground, nil, "the retired key is gone")
	end)

	fw.it("flips Battleground on when only the rated toggle was on", function()
		local context = LoginWith({ Battleground = false, RatedBattleground = true })

		fw.eq(context.Addon.Db.Battleground, true, "the on rated toggle wins the fold")
		fw.eq(context.Addon.Db.RatedBattleground, nil, "the retired key is gone")
	end)

	fw.it("leaves Battleground off when both old toggles were off", function()
		local context = LoginWith({ Battleground = false, RatedBattleground = false })

		fw.eq(context.Addon.Db.Battleground, false, "both toggles off stays off")
		fw.eq(context.Addon.Db.RatedBattleground, nil, "the retired key is gone")
	end)

	fw.it("does not repeat the fold on a later login, so turning Battleground off afterward sticks", function()
		local context = LoginWith({ Battleground = false, RatedBattleground = true })
		fw.eq(context.Addon.Db.Battleground, true, "the first login folds the rated toggle in")

		context.Addon.Db.Battleground = false

		-- Reinstalling without touching MiniTabTargetDB models a /reload.
		context = harness.Load("MiniTabTarget")
		harness.Login(context)

		fw.eq(context.Addon.Db.Battleground, false, "the player's later off choice is not reverted")
	end)

	_G.C_PvP = originalCPvP
	_G.SetBinding = originalSetBinding
end)
