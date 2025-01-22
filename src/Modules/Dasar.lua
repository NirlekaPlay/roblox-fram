-- Dasar.lua
-- NirlekaDev
-- January 18, 2024

local RunService = game:GetService("RunService")
local Provider = require(game.ReplicatedStorage.Modules._index.Service.Provider)

local requiredModules = {}
local runServiceModules = {}

local dasar_string_header = ":: Dasar :: "
local dasar_is_started = false
local dasar_is_starting = false

local moduleLocations = {
	game.ReplicatedStorage.Modules._index
}

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

local function initializeModule(module)
	local moduleConstructor = module["new"]
	local moduleRun = module["_run"]
	local moduleReady = module["_ready"]
	if moduleConstructor then
		if type(moduleConstructor) == "function" then
			return
		end
	end

	if moduleRun then
		if type(moduleRun) == "function" then
			table.insert(requiredModules, moduleRun)
			return
		end
	end

	if moduleReady then
		if type(moduleReady) == "function" then
			task.spawn(function()
				pcall(moduleReady)
			end)
		end
	end
end

local Dasar = {}

--[=[
	Acts similar to the require() function,
	but with the module's name instead of the path for the parameter.
	Note that there will be a delay if Dasar hasnt started yet.

	@param moduleName : string
	@return table?
]=]
function Dasar.Require(moduleName: string)
	assert(type(moduleName) == "string", string.format(dasar_string_header.."'moduleName' parameter must be a string. Got %s", typeof(moduleName)))
	--[[if not dasar_is_started then
		repeat
			task.wait()
		until dasar_is_started
	end]]

	local module = findModule(moduleName)
	if not module then
		error(string.format(dasar_string_header.."'%s' does not exist.", moduleName))
		return
	end

	return require(module)
end

--[=[
	Initializes all modules.
	Meaning all modules are equired, if a module has a _run or _ready functions
	will be called.
]=]
function Dasar.Start()
	if dasar_is_started or dasar_is_starting then return end
	dasar_is_starting = true

	Provider.AwaitAllAssetsAsync()

	for _, location in ipairs(moduleLocations) do
		for _, module in ipairs(location:GetDescendants()) do
			if module:IsA("ModuleScript") then
				task.spawn(function()
					requiredModules[module.Name] = require(module)
				end)
			end
		end
	end

	for _, module in pairs(requiredModules) do
		initializeModule(module)
	end

	RunService.Heartbeat:Connect(function()
		for _, func in pairs(runServiceModules) do
			func()
		end
	end)

	dasar_is_starting = false
	dasar_is_started = true
end

return Dasar