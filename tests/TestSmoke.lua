-- Loads the whole addon into a mocked client and drives it through login.
-- The shared body lives in build/Lua/SmokeTest.lua.

local fw = require("TestFramework")
local smoke = require("SmokeTest")
local WowMock = require("WowMock")

---The header's subtitle is built by the framework and never handed back to the addon, so a
---test finds it the way a player reads it, by its words.
---@param text string
---@return boolean
local function HasText(text)
	for _, frame in ipairs(WowMock.Frames) do
		for _, region in ipairs({ frame:GetRegions() }) do
			if region.GetText and region:GetText() == text then
				return true
			end
		end
	end

	return false
end

---A checkbox is drawn with its label as a child font string, so a test finds it the way a
---player does.
---@param text string
---@return table?
local function FindCheckbox(text)
	for _, frame in ipairs(WowMock.Frames) do
		if frame.Text and frame.Text.GetText and frame.Text:GetText() == text then
			return frame
		end
	end
end

---The client draws nothing in the mock, so a test stands in for the tooltip and reads back
---what the hover asked it to show.
---@param frame table
---@return string? title, string? body
local function TooltipOn(frame)
	local title, body
	local realSetText, realAddLine = GameTooltip.SetText, GameTooltip.AddLine

	GameTooltip.SetText = function(_, text)
		title = text
	end

	GameTooltip.AddLine = function(_, text)
		body = text
	end

	local ok, err = pcall(frame:GetScript("OnEnter"), frame)

	GameTooltip.SetText, GameTooltip.AddLine = realSetText, realAddLine

	if not ok then
		error(err, 0)
	end

	return title, body
end

---A control that shares a row carries one point, so its own row centre is the only thing
---placing it.
---@param frame table
---@param leftOf table
---@param what string
---@return number the horizontal step between the two
local function AssertSameRow(frame, leftOf, what)
	fw.eq(frame:GetNumPoints(), 1, what .. " is placed by one point")

	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)

	fw.eq(point, "LEFT", what .. " is anchored by its own left edge")
	fw.eq(relativeTo, leftOf, what .. " hangs off the toggle to its left")
	fw.eq(relativePoint, "LEFT", what .. " measures from that toggle's left edge")
	fw.eq(y, 0, what .. " sits on the same row, not below")
	fw.truthy(x > 0, what .. " steps right into the next column")

	return x
end

smoke.Run("MiniTabTarget", {
	extra = function(context)
		fw.eq(context.Addon.Framework.CustomStyling, true, "custom styling on")
		fw.eq(context.Addon.Framework.CustomStylingOverrides.Button, false, "stock buttons")
		fw.truthy(HasText("Tab targeting that makes sense."), "the subtitle under the panel title")

		fw.eq(FindCheckbox("Rated Battleground"), nil, "the merged toggle leaves no separate checkbox")

		local soloShuffle = FindCheckbox("Solo Shuffle")
		fw.not_nil(soloShuffle, "the solo shuffle checkbox")

		local soloTitle, soloBody = TooltipOn(soloShuffle)
		fw.eq(soloTitle, "Solo Shuffle", "the solo shuffle tooltip is titled with the label")
		fw.eq(soloBody, "Rated solo shuffle.", "the solo shuffle tooltip wording")

		local battleground = FindCheckbox("Battleground")
		fw.not_nil(battleground, "the battleground checkbox")

		local bgTitle, bgBody = TooltipOn(battleground)
		fw.eq(bgTitle, "Battleground", "the battleground tooltip is titled with the label")
		fw.eq(bgBody, "Rated/unrated/epic battlegrounds and Blitz.", "the battleground tooltip wording")

		local arena = FindCheckbox("Arena")
		fw.not_nil(arena, "the arena checkbox")

		local soloStep = AssertSameRow(soloShuffle, arena, "the solo shuffle toggle")
		local bgStep = AssertSameRow(battleground, soloShuffle, "the battleground toggle")

		fw.eq(bgStep, soloStep, "all three toggles sit on one evenly spaced row")
	end,
})
