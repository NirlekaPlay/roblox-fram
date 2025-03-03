-- error_macros
-- NirlekaDev
-- February 15, 2025

--[[
	Error macros.
	Standardized common error messages.
]]

local error = error
local format = string.format

local lib = {}

--[=[
	Throws an error.
]=]
function lib.ERR_THROW(msg: string)
	lib.ERR_TYPE(msg, "msg", "string")
	error(format("%s\n\n%s", msg, debug.traceback()), 4)
end

--[=[
	Throws an error if the given value is nil.
]=]
function lib.ERR_NIL(value: any, valueName: string)
	if value ~= nil then
		return
	end

	error(format("'%s' must not be nil.\n\n%s", valueName, debug.traceback()), 4)
end

--[=[
	Throws an error if the given value is a wrong type.
]=]
function lib.ERR_TYPE(value: any, valueName:string, expectedType: any)
	if typeof(value) == expectedType then
		return
	end

	error(format("'%s' must be of type %s. Got %s\n\n%s", valueName, expectedType, typeof(value), debug.traceback()), 4)
end

--[=[
	Throws an error if the given value is a Instance class.
]=]
function lib.ERR_TYPE_INSTANCE(value: Instance, valueName:string, expectedClassName: string)
	lib.ERR_TYPE_MSG(value, valueName, "Instance")

	if value.ClassName == expectedClassName then
		return
	end

	error(format("'%s' must be of Instance class %s. Got %s\n\n%s", valueName, expectedClassName, value.ClassName, debug.traceback()), 4)
end

--[=[
	Ensures that `cond` is false.
]=]
function lib.ERR_FAIL_COND_MSG(cond: any, msg: string)
	lib.ERR_TYPE(msg, "msg", "string")

	if cond then
		lib.ERR_THROW(msg)
	end
end

return lib