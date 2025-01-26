-- inst.lua
-- NirlekaDev
-- January 26, 2025

--[[
	Simple and useful Instance functions.
]]

local lib = {}

function lib.create(class: string, name: string , parent: Instance, properties: {[string]:any}): Instance
	local instance = Instance.new(class)

	if properties then
		for k, v in pairs(properties) do
			instance[k] = v
		end
	end
	instance.Name = name or instance.Name
	instance.Parent = parent or instance.Parent

	return instance
end

function lib.clone(instance: Instance, parent: Instance): Instance
	local clone = instance:Clone()
	local cloneDesc = clone:GetDescendants()

	if #cloneDesc > 0 then
		for _, inst in ipairs(cloneDesc) do
			inst:Destroy()
		end
	end
	clone.Parent = parent

	return clone
end

function lib.deepClone(instance: Instance, parent: Instance)
	local clone = instance:Clone()
	clone.Parent = parent

	return clone
end

return lib