-- Dasar.lua
-- NirlekaDev
-- January 18, 2024

--[=[
	@class Dasar

	A module management system that handles module initialization, dependency management,
	and lifecycle events.

	@interface ModuleStructure
	.new() -> Instance? -- Constructors are ignored.
	._ready() -> nil    -- Called when module is initialized
	._run() -> nil      -- Called each frame after initialization
]=]

local RunService = game:GetService("RunService")
local Provider = require(game.ReplicatedStorage.Modules._index.Service.Provider)

local dasar_string_header = ":: Dasar :: "
local loadedPaths = {}
local moduleCache = {}
local runServiceConnection: RBXScriptConnection
local start_time
local DasarState = {
	isStarted = false,
	isStarting = false,
	requiredModules = {},
	requiredModulesIndex = 0,
	requiredModulesMaxIndex = 0,
	runServiceModules = {}
}
local moduleLocations = {
	game.ReplicatedStorage.Modules._index
}
local moduleTypesLocations

local function findModule(moduleName)
	if moduleCache[moduleName] then
		return moduleCache[moduleName]
	end
	for _, location in ipairs(moduleLocations) do
		for _, module in pairs(location:GetDescendants()) do
			if module:IsA("ModuleScript") and module.Name == moduleName then
				moduleCache[moduleName] = module
				return module
			end
		end
	end
	return nil
end

local function callRunFunctions(dt)
	for _, func in pairs(DasarState.runServiceModules) do
		task.spawn(func, dt)
	end
end

local function initializeModule(module, moduleInstance, recursive)
	local modulePath = moduleInstance:GetFullName()
	if loadedPaths[modulePath] then
		warn(dasar_string_header .. "Circular dependency detected: " .. modulePath)
		return
	end
	loadedPaths[modulePath] = true

	local moduleConstructor = module["new"]
	local moduleRun = module["_run"]
	local moduleReady = module["_ready"]

	if moduleConstructor and type(moduleConstructor) == "function" then
		return
	end

	if moduleRun and type(moduleRun) == "function" then
		table.insert(DasarState.runServiceModules, moduleRun)
	end

	if moduleReady and type(moduleReady) == "function" then
		task.spawn(function()
			local success, err = pcall(moduleReady)
			if not success then
				warn(dasar_string_header .. "Module initialization error: " .. tostring(err))
			else
				warn(string.format(dasar_string_header .. "Initialized module  '%s'", moduleInstance.Name))
			end

			if recursive then
				recursive(module, moduleInstance)
			end
		end)
	end

	loadedPaths[modulePath] = nil
end

local function requireModule(moduleInstance)
	if #moduleLocations == 0 then
		error(dasar_string_header .. "No module locations configured")
	end
	local attemptRequire
	task.spawn(function()
		local moduleName = moduleInstance.Name
		local modulePath = moduleInstance:GetFullName()
		local success, errorMsg = pcall(function()
			attemptRequire = require(moduleInstance)
		end)

		if not success then
			warn(string.format(
				"%sModule '%s' failed to load:\nPath: %s\nError: %s\nStack: %s",
				dasar_string_header,
				moduleInstance.Name,
				modulePath,
				errorMsg,
				debug.traceback()
				))
			return
		end

		DasarState.requiredModulesIndex += 1
		DasarState.requiredModules[moduleName] = attemptRequire
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
	Requires a module and catches any errors during the require.
	Then runs any functions such as _ready() or _run().
	Classes or OOP objects with a new() function will be ignored.

	```lua
	local Bar = require(path.to.bar)
	Dasar.PreloadModule(bar)
	```
]=]
function Dasar.PreloadModule(modelInstance: ModuleScript, recursive: any?)
	assert(typeof(modelInstance) == "Instance" and modelInstance:IsA("ModuleScript"), string.format(dasar_string_header.."'moduleInstance' parameter must be an Instance. Got %s", typeof(modelInstance)))

	local attemptRequire = requireModule(modelInstance)
	if not attemptRequire then
		return
	end

	local function initRecursive(module, moduleInstance)
		if DasarState.requiredModulesIndex == DasarState.requiredModulesMaxIndex then
			warn(string.format(dasar_string_header .. "Initialization finnished. Time: %s", tick() - start_time))
		end
		local module_children = moduleInstance:GetChildren()
		if #module_children <= 0 then
			return
		end

		for _, child_module in ipairs(module_children) do
			if not child_module:IsA("ModuleScript") then
				continue
			end

			Dasar.PreloadModule(child_module, initRecursive)
		end
	end

	recursive = recursive or initRecursive

	initializeModule(attemptRequire, modelInstance, recursive)
end

--[=[
	Initializes all modules.
	Meaning all modules are required, if a module has a _run or _ready functions
	will be called.

	```lua
	local Dasar = require(game:GetService("ReplicatedStorage").Modules.Dasar)
	Dasar.Start()
	```
]=]
function Dasar.Start()
	if DasarState.isStarted or DasarState.isStarting then return end
	DasarState.isStarting = true
	start_time = tick()
	warn(dasar_string_header .. "Initializing Dasar. . .")

	Provider.AwaitAllAssetsAsync()

	moduleTypesLocations = {
		Managers = moduleLocations[1]["Managers"],
		Service = moduleLocations[1]["Service"]
	}

	for _, location: Folder in pairs(moduleTypesLocations) do
		for _, child in ipairs(location:GetDescendants()) do
			if not child:IsA("ModuleScript") then
				continue
			end

			DasarState.requiredModulesMaxIndex += 1
		end

		for _, child in ipairs(location:GetChildren()) do
			if not child:IsA("ModuleScript") then
				continue
			end

			Dasar.PreloadModule(child)
		end
	end

	runServiceConnection = RunService.Heartbeat:Connect(function(dt)
		callRunFunctions(dt)
	end)

	DasarState.isStarting = false
	DasarState.isStarted = true
end

return Dasar