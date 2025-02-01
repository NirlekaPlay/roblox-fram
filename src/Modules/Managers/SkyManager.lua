--[[
		// FileName: SkyManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages the sky. Currently only
				matches the client's local time to the Sky's
				time of day.

				CLIENT ONLY.
]]

local Lighting = game:GetService("Lighting")

local sync_time = true
local clock_time_aliases = {
	midnight = 0,
	day = 12
}

local SkyManager = {}
SkyManager.ClassName = "SkyManager"
SkyManager.RunContext = "Client"

function SkyManager._run()
	if sync_time then
		SkyManager.SyncTimeOfDay()
	end
end

function SkyManager.getTimeOfDay()
	local currentHour = tonumber(os.date("%H")) -- Hour (0-23)
	local currentMinute = tonumber(os.date("%M")) -- Minute (0-59)
	local currentSecond = tonumber(os.date("%S")) -- Second (0-59)

	return currentHour + (currentMinute / 60) + (currentSecond / 3600)
end

function SkyManager.SyncTimeOfDay()
	if not sync_time then
		sync_time = true
	end
	Lighting.ClockTime = SkyManager.getTimeOfDay()
end

function SkyManager.SetTimeOfDay(alias: string)
	local clock_time = clock_time_aliases[alias]
	if clock_time then
		sync_time = false
		Lighting.ClockTime = clock_time
	end
end

return SkyManager
