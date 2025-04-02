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

local CHAR_DELAYS = {
	[","] = 0.3,
	["."] = 0.8,
	["!"] = 0.9,
	["|"] = 1.0
}

local FORMAT_TO_REMOVE = {
	["|"] = true,
	["_"] = true
}

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

--[=[
	Calculates the pause duration dictated by `CHAR_DELAYS`
]=]
local function get_pause_duration(char)
	return CHAR_DELAYS[char] or 0
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
			local current_char = self.characters[self.next_char_index - 1]
			local pause_time = 0

			if current_char and current_char.char then
				pause_time = get_pause_duration(current_char.char)
			end


			if pause_time > 0 and current_char and current_char.state == "fading" then
				self.last_char_time += pause_time
				return updated
			end

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
			cps = cps or 20,				-- Characters per second
			fade_time = fade_time or 0.2,	-- Time to fade in each character
			max_fades = max_fades or 3		-- Maximum simultaneous fading characters
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
	config = config or DialogueConfig.new()
	local renderer = CharMapRenderer.new(label)
	renderer:set_original_text(text)

	local text_formatted = parse_string_format(text)
	local visible_text = ""
	local start_time = tick()

	for _, segment in ipairs(text_formatted) do
		local seg_text = segment.text
		local processor = DiaSegmentProcessor.new(seg_text)

		if segment.skip then
			for i = 1, #processor.characters do
				processor.characters[i].state = "visible"
			end
			visible_text = visible_text .. seg_text
			renderer.label.Text = visible_text
		else
			local segment_complete = false
			local segment_start_time = tick()

			while not segment_complete do
				local current_time = tick() - segment_start_time
				local needs_update = false

				local charUpdated = processor:advance_characters(current_time, 1/config.cps)
				local fadeUpdated = processor:update_fading_characters(config.fade_time, config.max_fades)

				needs_update = charUpdated or fadeUpdated

				if needs_update then
					local current_segment_text = ""
					for i = 1, #processor.characters do
						local char = processor.characters[i]
						if char.state == "visible" then
							current_segment_text = current_segment_text .. char.char
						elseif char.state == "fading" then
							current_segment_text = current_segment_text .. string.format('<font transparency="%.2f">%s</font>', 1-char.progress, char.char)
						end
					end

					renderer.label.Text = visible_text .. current_segment_text
				end

				segment_complete = processor:is_complete()

				task.wait()
			end

			visible_text = visible_text .. seg_text
		end
	end

	renderer:render_final()

	return true
end

return DiaSegmentMap