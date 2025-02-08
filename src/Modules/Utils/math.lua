-- math.lua
-- NirlekaDev
-- January 25, 2025

--[[
	More advanced and some simple math functions.
]]

local random = Random.new(tick())

local lib = {}

function lib.ease(p_x, p_c)
	if p_x < 0 then
		p_x = 0
	elseif (p_x > 1.0) then
		p_x = 1.0
	end
	if p_c > 0 then
		if (p_c < 1.0) then
			return 1.0 - math.pow(1.0 - p_x, 1.0 / p_c);
		else
			return math.pow(p_x, p_c);
		end
	elseif (p_c < 0) then
		if p_x < 0.5 then
			return math.pow(p_x * 2.0, -p_c) * 0.5;
		else
			return (1.0 - math.pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		end
	else
		return 0
	end
end

function lib.lerp(a, b, t)
	return a + (b - a) * t
end

function lib.isEven(n)
	return n % 2 == 0
end

function lib.isOdd(n)
	return not (n % 2 == 0)
end

function lib.Randomize(seed)
	seed = seed or tick()
	random = Random.new(seed)
end

function lib.randf()
	return random:NextNumber(0, 1)
end

function lib.randf_range(min, max)
	return random:NextNumber(min, max)
end

return lib