-- Fusor.lua
-- NirlekaDev
-- December 20, 2024

--[[
	THIS TOOK 5 DAYS TO FIGURE OUT.
]]

-- Constants (SI units for consistency)
local p0 = 101325  -- Pressure at sea level in Pascals
local chamber_diameter = 0.2 -- meters (20 cm)
local chamber_surfaceArea = 4 * math.pi * (chamber_diameter / 2)^2 -- m^2
local chamber_volume = (4/3) * math.pi * (chamber_diameter / 2)^3 -- m^3
local chamber_leakRate = 1e-7 -- m^3/s (Adjusted for realism)
local chamber_outgassingRate = 1e-9 -- m^3/s/m^2 (Adjusted for realism)

local pump_roughing_speed = 5e-3 -- 5 L/s = 0.005 m^3/s
local pump_highPressure_speed = 5e-4 -- 0.5 L/s = 0.0005 m^3/s
local pump_roughing_on = false
local pump_highPressure_on = false

local chamber_pressure = p0

local function calculatePumping(P_current, S, V, dt)
	if S > 0 then
		local dP = -(S * P_current * dt) / V
		return dP
	else
		return 0
	end
end

local function calculateGasLoad(V, leakRate, outgassingRate, surfaceArea, dt)
	local dP = ((leakRate + (outgassingRate * surfaceArea)) * p0 * dt) / V
	return dP
end

local function roughingPumpSpeed(pressure)
	if pressure > 100 then return pump_roughing_speed end -- Pa
	return pump_roughing_speed * (pressure / 100) -- Linear decrease below 100 Pa
end

local function turboPumpSpeed(pressure)
	if pressure < 1 then return pump_highPressure_speed end -- Pa
	return pump_highPressure_speed * (1/pressure)
end

function _run(dt)
	CalculateChamberPressure(dt)
end

function CalculateChamberPressure(dt)
	local dP_pumping = 0
	local dP_gasLoad = 0

	if chamber_pressure > 1 then -- Roughing pump stage
		dP_pumping += calculatePumping(chamber_pressure, roughingPumpSpeed(chamber_pressure), chamber_volume, dt)
	elseif chamber_pressure > 1e-4 then -- Turbo pump stage
		dP_pumping += calculatePumping(chamber_pressure, turboPumpSpeed(chamber_pressure), chamber_volume, dt)
	end

	if chamber_pressure < p0 then
		dP_gasLoad = calculateGasLoad(chamber_volume, chamber_leakRate, chamber_outgassingRate, chamber_surfaceArea, dt)
	end

	chamber_pressure += dP_pumping + dP_gasLoad
	chamber_pressure = math.max(chamber_pressure, 1e-7)
end
