-- SkyManager.lua
-- NirlekaDev
-- January 25, 2024

local Lighting = game:GetService("Lighting")

local SkyManager = {}

function SkyManager._run()
	SkyManager.SyncTimeOfDay()
end

function SkyManager.getTimeOfDay()
	local currentHour = tonumber(os.date("%H")) -- Hour (0-23)
	local currentMinute = tonumber(os.date("%M")) -- Minute (0-59)
	local currentSecond = tonumber(os.date("%S")) -- Second (0-59)

	return currentHour + (currentMinute / 60) + (currentSecond / 3600)
end

function SkyManager.SyncTimeOfDay()
	Lighting.ClockTime = SkyManager.getTimeOfDay()
end

return SkyManager
