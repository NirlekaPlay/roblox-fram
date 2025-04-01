-- DiaSegmentMap.lua
-- NirlekaDev
-- March 30, 2025 // Idul Fitr!!

--[=[
	@class DiaSegmentMap

	Represents dialogue segments.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Array = require("Array")
local CharMap = require("CharMap")

local function parse_string_format(text)
	local segments = Array()
	local currentIndex = 1

	while currentIndex <= #text do
		local startUnderscore = text:find("_", currentIndex)

		if startUnderscore then
			if startUnderscore > currentIndex then
				table.insert(segments, {
					text = text:sub(currentIndex, startUnderscore - 1),
					skip = false
				})
			end

			local endUnderscore = text:find("_", startUnderscore + 1)
			if endUnderscore then
				local word = text:sub(startUnderscore + 1, endUnderscore - 1)

				local nextCharIndex = endUnderscore + 1
				local spaces = ""
				while nextCharIndex <= #text and text:sub(nextCharIndex, nextCharIndex) == " " do
					spaces = spaces .. " "
					nextCharIndex = nextCharIndex + 1
				end

				table.insert(segments, {
					text = word .. spaces,
					skip = true
				})

				currentIndex = nextCharIndex
			else
				table.insert(segments, {
					text = text:sub(currentIndex),
					skip = false
				})
				break
			end
		else
			table.insert(segments, {
				text = text:sub(currentIndex),
				skip = false
			})
			break
		end
	end

	return segments
end

local CharState
do
	CharState = {}
	CharState.__index = CharState

	function CharState.new(char, state)
		return setmetatable({
			char = char,
			state = state or "pending", -- pending/fading/visible
			progress = 0,
			start_time = nil
		}, CharState)
	end
end

local DiaSegmentProcessor
do
	DiaSegmentProcessor = {}
	DiaSegmentProcessor.__index = DiaSegmentProcessor

	function DiaSegmentProcessor.new(text)
		return setmetatable({
			characters = CharMap(text):ExplodeToClass(function(char)
				return CharState.new(char)
			end),
			next_char_index = 1,
			last_char_time = 0
		}, DiaSegmentProcessor)
	end

	function DiaSegmentProcessor:advance_characters(current_time, char_delay)
		local updated = false

		while self.next_char_index <= #self.characters and current_time >= self.last_char_time + char_delay do
			self.characters[self.next_char_index].state = "fading"
			self.characters[self.next_char_index].start_time = tick()
			self.last_char_time += char_delay
			self.next_char_index += 1
			updated = true
		end

		return updated
	end

	function DiaSegmentProcessor:update_fading_characters(fade_time, max_fades)
		local updated = false
		local active_fades = 0

		for i = 1, #self.characters do
			local char = self.characters[i]
			if char.state == "fading" then
				active_fades = active_fades + 1
				char.progress = math.min(1, (tick() - char.start_time)/fade_time)
				if char.progress >= 1 then
					char.state = "visible"
				end
				updated = true

				if max_fades and active_fades >= max_fades then
					break
				end
			end
		end

		return updated
	end

	function DiaSegmentProcessor:is_complete()
		if self.next_char_index <= #self.characters then
			return false
		end

		for _, char in ipairs(self.characters) do
			if char.state ~= "visible" then
				return false
			end
		end

		return true
	end
end

local CharMapRenderer
do
	CharMapRenderer = {}
	CharMapRenderer.__index = CharMapRenderer

	function CharMapRenderer.new(label)
		label.RichText = true
		return setmetatable({
			label = label,
			original_text = ""
		}, CharMapRenderer)
	end

	function CharMapRenderer:set_original_text(text)
		self.original_text = text
		self.label.Text = ""
	end

	function CharMapRenderer:render_characters(characters)
		local visibleText = ""
		local fadingText = ""

		for i = 1, #characters do
			local char = characters[i]
			if char.state == "visible" then
				visibleText = visibleText .. char.char
				elseif char.state == "fading" then
				fadingText = fadingText .. string.format('<font transparency="%.2f">%s</font>', 1-char.progress, char.char)
			end
		end

		self.label.Text = visibleText .. fadingText
	end

	function CharMapRenderer:render_final()
		self.label.Text = self.original_text
	end
end

local DialogueConfig
do
	DialogueConfig = {}
	DialogueConfig.__index = DialogueConfig

	function DialogueConfig.new(cps, fade_time, max_fades)
		return setmetatable({
			cps = cps or 20,		-- Characters per second
			fade_time = fade_time or 0.2,	-- Time to fade in each character
			max_fades = max_fades or 3	-- Maximum simultaneous fading characters
		}, DialogueConfig)
	end
end

local DiaSegmentMap = {}
DiaSegmentMap.__index = DiaSegmentMap

function DiaSegmentMap.new(text: string)
	return setmetatable({
		_charMap = CharMap(text),
		_map = parse_string_format(text)
	}, DiaSegmentMap)
end

function DiaSegmentMap.from(what)
	if type(what) == "string" then
		return DiaSegmentMap.new(what)
	elseif type(what) == "table" and CharMap.IsCharMap(what) then
		return DiaSegmentMap.new(what:ToString())
	end
end

function DiaSegmentMap.IsDiaSegmentMap(value)
	return getmetatable(value) == DiaSegmentMap
end

function DiaSegmentMap.StepAndRender(text: string, label: TextLabel, config)
	config = DialogueConfig.new()
	local processor = DiaSegmentProcessor.new(text)
	local renderer = CharMapRenderer.new(label)

	renderer:set_original_text(text)

	local startTime = tick()

	while true do
		local current_time = tick() - startTime
		local needs_update = false

		-- Process character state updates
		local charUpdated = processor:advance_characters(current_time, 1/config.cps)
		local fadeUpdated = processor:update_fading_characters(config.fade_time, config.max_fades)

		needs_update = charUpdated or fadeUpdated

		-- Render if needed
		if needs_update then
		renderer:render_characters(processor.characters)
		end

		-- Check if complete
		if processor:is_complete() then
		renderer:render_final()
		break
		end

		task.wait()
	end

	return true
end

return DiaSegmentMap