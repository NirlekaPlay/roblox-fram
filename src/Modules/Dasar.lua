-- Dasar.lua
-- NirlekaDev
-- January 18, 2024

local RunService = game:GetService("RunService")
local Provider = require(game.ReplicatedStorage.Modules._index.Service.Provider)

local acquired_modules = {}
local required_modules = {}
local run_service_modules = {}

local dasar_string_header = ":: Dasar :: "
local dasar_is_started = false
local dasar_is_starting = false

local moduleLocations = {
	game.ReplicatedStorage.Modules._index
}
local moduleTypesLocations = {
	["Classes"] = moduleLocations["Class"],
	["Library"] = moduleLocations["Library"],
	["Managers"] = moduleLocations["Managers"],
	["Service"] = moduleLocations["Service"],
}

local function initializeModule(module, moduleName)
	local moduleConstructor = module["new"]
	local moduleRun = module["_run"]
	local moduleReady = module["_ready"]

	if moduleConstructor and type(moduleConstructor) == "function" then
		return
	end

	if moduleRun and type(moduleRun) == "function" then
		table.insert(run_service_modules, moduleRun)
	end

	if moduleReady and type(moduleReady) == "function" then
		task.spawn(function()
			local success, err = pcall(moduleReady)
			if not success then
				warn(dasar_string_header .. "Module initialization error: " .. tostring(err))
			else
				warn(string.format(dasar_string_header .. "Initialized module  '%s'", moduleName))
			end
		end)
	end
end

local function findModule(moduleName)
	for _, location in ipairs(moduleLocations) do
		for _, module in pairs(location:GetDescendants()) do
			if module:IsA("ModuleScript") and module.Name == moduleName then
				return module
			end
		end
	end
	return nil
end

local function requireModule(moduleInstance)
	local attemptRequire
	task.spawn(function()
		local moduleName = moduleInstance.Name
		local success, errorMsg = pcall(function()
			attemptRequire = require(moduleInstance)
		end)

		if not success then
			error(string.format(dasar_string_header.."Attempt to require('%s') error: \n %s \n",
			moduleName,
			errorMsg,
			debug.traceback()
			))
			return
		else
			required_modules[moduleName] = attemptRequire
			initializeModule(attemptRequire, moduleName)
		end
	end)

	return attemptRequire
end

local Dasar = {}

--[=[
	Acts similar to the require() function,
	but with the module's name instead of the path for the parameter.

	```lua
	local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
	local bar = require("Bar")
	```

	@param moduleName : string
	@return table?
]=]
function Dasar.Require(moduleName: string)
	assert(type(moduleName) == "string", string.format(dasar_string_header.."'moduleName' parameter must be a string. Got %s", typeof(moduleName)))

	local module = findModule(moduleName)
	if not module then
		error(string.format(dasar_string_header.."'%s' does not exist. \n %s", moduleName, debug.traceback()))
		return
	end

	return require(module)
end

--[=[
	Initializes all modules.
	Meaning all modules are required, if a module has a _run or _ready functions
	will be called.
]=]
function Dasar.Start()
	if dasar_is_started or dasar_is_starting then return end
	dasar_is_starting = true

	dasar_is_starting = false
	dasar_is_started = true
end

return Dasar