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
			warn(string.format(dasar_string_header .. "Initializing module '%s'", moduleName))
			local success, err = pcall(moduleReady)
			if not success then
				warn(dasar_string_header .. "Module initialization error: " .. tostring(err))
			else
				warn(string.format(dasar_string_header .. "Initialized module  '%s'", moduleName))
			end
		end)
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

	local module = findModule(moduleName)
	if not module then
		error(string.format(dasar_string_header.."'%s' does not exist.", moduleName))
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
	local finnished = false
	local totalError = 0
	local startTime = tick()
	dasar_is_starting = true
	warn(dasar_string_header.."Initializing Dasar. . .")

	Provider.AwaitAllAssetsAsync()

	for _, location: Instance in ipairs(moduleLocations) do
		for _, module in ipairs(location:GetDescendants()) do
			if module:IsA("ModuleScript") then
				table.insert(acquired_modules, module)
			end
		end
	end

	for i, module in ipairs(acquired_modules) do
		task.spawn(function()
			local success, message = pcall(function()
				initializeModule(require(module), module.Name)
			end)

			if not success then
				warn(string.format(dasar_string_header .. "Error initializing module '%s': %s", module.Name, tostring(message)))
				totalError += 1
			end

			if i == #acquired_modules then
				finnished = true
				warn(string.format(dasar_string_header.."All modules loaded. Time: %d secs, Errors: %d", tick() - startTime, totalError))
			end
		end)
	end

	RunService.Heartbeat:Connect(function()
		for _, func in pairs(run_service_modules) do
			func()
		end
	end)

	dasar_is_starting = false
	dasar_is_started = true
end

return Dasar