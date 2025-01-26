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

local SkyManager = {}
SkyManager.ClassName = "SkyManager"
SkyManager.RunContext = "Client"

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
