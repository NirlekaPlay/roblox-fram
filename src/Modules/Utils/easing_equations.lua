-- easing_equations.lua
-- NirlekaDev
-- January 25, 2025

--[[
	Easing equation functions.
]]

local math = math

local easing = {}

easing.linear = {}
function easing.linear.in_(t, b, c, d)
	return c * t / d + b
end

easing.sine = {}
function easing.sine.in_(t, b, c, d)
	return -c * math.cos(t / d * (math.pi / 2)) + c + b
end

function easing.sine.out(t, b, c, d)
	return c * math.sin(t / d * (math.pi / 2)) + b
end

function easing.sine.in_out(t, b, c, d)
	return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end

function easing.sine.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.sine.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.sine.in_(t * 2 - d, b + h, h, d)
end

easing.quint = {}
function easing.quint.in_(t, b, c, d)
	return c * (t / d)^5 + b
end

function easing.quint.out(t, b, c, d)
	return c * ((t / d - 1)^5 + 1) + b
end

function easing.quint.in_out(t, b, c, d)
	t = t / d * 2

	if (t < 1) then
		return c / 2 * t^5 + b
	end
	return c / 2 * ((t - 2)^5 + 2) + b
end

function easing.quint.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.quint.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.quint.in_(t * 2 - d, b + h, h, d)
end

easing.quart = {}
function easing.quart.in_(t, b, c, d)
	return c * (t / d)^4 + b
end

function easing.quart.out(t, b, c, d)
	return -c * ((t / d - 1)^4 - 1) + b
end

function easing.quart.in_out(t, b, c, d)
	t = t / d * 2

	if (t < 1) then
		return c / 2 * t^4 + b
	end
	return -c / 2 * ((t - 2)^4 - 2) + b
end

function easing.quart.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.quart.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.quart.in_(t * 2 - d, b + h, h, d)
end

easing.quad = {}
function easing.quad.in_(t, b, c, d)
	return c * (t / d)^2 + b
end

function easing.quad.out(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

function easing.quad.in_out(t, b, c, d)
	t = t / d * 2

	if (t < 1) then
		return c / 2 * t^2 + b
	end
	return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end

function easing.quad.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.quad.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.quad.in_(t * 2 - d, b + h, h, d)
end

easing.expo = {}
function easing.expo.in_(t, b, c, d)
	if (t == 0) then
		return b
	end
	return c * 2^(10 * (t / d - 1)) + b - c * 0.001
end

function easing.expo.out(t, b, c, d)
	if (t == d) then
		return b + c
	end
	return c * 1.001 * (-(2^(-10 * t / d)) + 1) + b
end

function easing.expo.in_out(t, b, c, d)
	if (t == 0) then
		return b
	end

	if (t == d) then
		return b + c
	end

	t = t / d * 2

	if (t < 1) then
		return c / 2 * 2^(10 * (t - 1)) + b - c * 0.0005
	end
	return c / 2 * 1.0005 * (-(2^(-10 * (t - 1))) + 2) + b
end

function easing.expo.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.expo.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.expo.in_(t * 2 - d, b + h, h, d)
end

easing.elastic = {}
function easing.elastic.in_(t, b, c, d)
	if (t == 0) then
		return b
	end

	t = t / d
	if (t == 1) then
		return b + c
	end

	t = t - 1
	local p = d * 0.3
	local a = c * 2^(10 * t)
	local s = p / 4

	return -(a * math.sin((t * d - s) * (2 * math.pi) / p)) + b
end

function easing.elastic.out(t, b, c, d)
	if (t == 0) then
		return b
	end

	t = t / d
	if (t == 1) then
		return b + c
	end

	local p = d * 0.3
	local s = p / 4

	return (c * 2^(-10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b)
end

function easing.elastic.in_out(t, b, c, d)
	if (t == 0) then
		return b
	end

	if ((t / (d / 2)) == 2) then
		return b + c
	end

	local p = d * (0.3 * 1.5)
	local a = c
	local s = p / 4

	if (t < d / 2) then
		t = t - 1
		a = a * 2^(10 * t)
		return -0.5 * (a * math.sin((t * d - s) * (2 * math.pi) / p)) + b
	end

	t = t - 1
	a = a * 2^(-10 * t)
	return a * math.sin((t * d - s) * (2 * math.pi) / p) * 0.5 + c + b
end

function easing.elastic.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.elastic.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.elastic.in_(t * 2 - d, b + h, h, d)
end

easing.cubic = {}
function easing.cubic.in_(t, b, c, d)
	t = t / d
	return c * t * t * t + b
end

function easing.cubic.out(t, b, c, d)
	t = t / d - 1
	return c * (t * t * t + 1) + b
end

function easing.cubic.in_out(t, b, c, d)
	t = t / (d / 2)
	if (t < 1) then
		return c / 2 * t * t * t + b
	end

	t = t - 2
	return c / 2 * (t * t * t + 2) + b
end

function easing.cubic.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.cubic.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.cubic.in_(t * 2 - d, b + h, h, d)
end

easing.circ = {}
function easing.circ.in_(t, b, c, d)
	t = t / d
	return -c * (math.sqrt(1 - t * t) - 1) + b
end

function easing.circ.out(t, b, c, d)
	t = t / d - 1
	return c * math.sqrt(1 - t * t) + b
end

function easing.circ.in_out(t, b, c, d)
	t = t / (d / 2)
	if (t < 1) then
		return -c / 2 * (math.sqrt(1 - t * t) - 1) + b
	end

	t = t - 2
	return c / 2 * (math.sqrt(1 - t * t) + 1) + b
end

function easing.circ.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.circ.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.circ.in_(t * 2 - d, b + h, h, d)
end

easing.bounce = {}
function easing.bounce.out(t, b, c, d)
	t = t / d

	if (t < (1 / 2.75)) then
		return c * (7.5625 * t * t) + b
	end

	if (t < (2 / 2.75)) then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	end

	if (t < (2.5 / 2.75)) then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	end

	t = t - (2.625 / 2.75)
	return c * (7.5625 * t * t + 0.984375) + b
end

function easing.bounce.in_(t, b, c, d)
	return c - easing.bounce.out(d - t, 0, c, d) + b
end

function easing.bounce.in_out(t, b, c, d)
	if (t < d / 2) then
		return easing.bounce.in_(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.bounce.out(t * 2 - d, b + h, h, d)
end

function easing.bounce.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.bounce.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.bounce.in_(t * 2 - d, b + h, h, d)
end

easing.back = {}
function easing.back.in_(t, b, c, d)
	local s = 1.70158
	t = t / d

	return c * t * t * ((s + 1) * t - s) + b
end

function easing.back.out(t, b, c, d)
	local s = 1.70158
	t = t / d - 1

	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

function easing.back.in_out(t, b, c, d)
	local s = 1.70158 * 1.525
	t = t / (d / 2)

	if (t < 1) then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	end

	t = t - 2
	return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end

function easing.back.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.back.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.back.in_(t * 2 - d, b + h, h, d)
end

easing.spring = {}
function easing.spring.out(t, b, c, d)
	t = t / d
	local s = 1.0 - t
	t = (math.sin(t * math.pi * (0.2 + 2.5 * t * t * t)) * s^2.2 + t) * (1.0 + (1.2 * s))
	return c * t + b
end

function easing.spring.in_(t, b, c, d)
	return c - easing.spring.out(d - t, 0, c, d) + b
end

function easing.spring.in_out(t, b, c, d)
	if (t < d / 2) then
		return easing.spring.in_(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.spring.out(t * 2 - d, b + h, h, d)
end

function easing.spring.out_in(t, b, c, d)
	if (t < d / 2) then
		return easing.spring.out(t * 2, b, c / 2, d)
	end
	local h = c / 2
	return easing.spring.in_(t * 2 - d, b + h, h, d)
end

return easing