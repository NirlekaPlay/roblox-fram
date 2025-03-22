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
local Promise = require(game.ReplicatedStorage.Modules._index.Library.Promise)

local DASAR_STRING_HEADER = ":: Dasar :: "
local ERR_CIRCULAR_DEPENDENCY = "Circular dependency detected on path: %s!"
local ERR_MODULE_INIT = "Attempted to call %s::_ready() \n%s"
local ERR_MODULE_LOCATIONS = "No module locations configured in module_locations!"
local ERR_MODULE_REQUIRE = "Attempted to require('%s') of path '%s' \n%s"
local ERR_MODULE_NIL = "Module '%s' does not exist!"
local WARN_DASAR_INIT = "Initializing Dasar. . ."
local WARN_DASAR_INIT_FINNISHED = "Initiliazation finnished; Time: %s"
local WARN_MODULE_INIT = "Initialized module '%s'"

local FOLDER_LOCATIONS = {
	game.ReplicatedStorage.Modules._index
}

local FOLDER_TYPES = {
	"Managers",
	"Service"
}

local dasar_states = {
	isStarted = false,
	isStarting = false,
	requiredModules = {},
	requiredModulesCache = {},
	requiredModulesIndex = 0,
	requiredModulesLoadedPaths = {},
	requiredModulesMaxIndex = 0,
	runServiceConnection = nil,
	runServiceModules = {},
	start_time = 0
}

local function err_msg(msg, traceback)
	local f_msg = DASAR_STRING_HEADER.. msg .."/n/n%s"
	error(string.format(f_msg, traceback))
end

local function err_msg_traceback(msg)
	local f_msg = DASAR_STRING_HEADER.. msg .."/n/n%s"
	error(string.format(f_msg, debug.traceback(2)))
end

local function err_type(value, value_name, e_type)
	local value_type = typeof(value)
	if value_type == e_type then
		return true
	end

	err_msg_traceback(string.format("'%s' must be a %s, got '%s'", value_name, e_type, value_type))
end

local function err_instance(value, value_name, e_class)
	err_type(value, value_name, "Instance")

	if value:IsA(e_class) then
		return true
	end

	err_msg_traceback(string.format("'%s' must be a %s, got '%s'", value_name, e_class, value.ClassName))
end

local function warn_err(msg, traceback)
	local f_msg = DASAR_STRING_HEADER.. msg .."\n%s"
	warn(string.format(f_msg, traceback))
end

local function warn_normal(msg)
	local f_msg = DASAR_STRING_HEADER.. msg
	warn(f_msg)
end

--[[
	All _run() functions from modules will be called on a seperate thread.
	Note that _run() always uses RunService.Heartbeat
]]
local function callRunFunctions(dt)
	for _, func in pairs(dasar_states.runServiceModules) do
		task.spawn(func, dt)
	end
end

--[[
	Finds the actual ModuleScript Instance from all the folders in `FOLDER_LOCATIONS`
	If there is a previously required ModuleScript, it will return it.
]]
local function findModule(moduleName)
	for _, location in ipairs(FOLDER_LOCATIONS) do
		for _, module in pairs(location:GetDescendants()) do
			if module:IsA("ModuleScript") and module.Name == moduleName then
				dasar_states.requiredModulesCache[moduleName] = module
				return module
			end
		end
	end
	return nil
end

--[[
	The default recursive function used in `Dasar.PreloadModule()`
	This recursive is called when the module is finnished preloading.
	So the children(s) of the module will be preloaded too AFTER the module.
]]
local function initRecursive(_, moduleInstance, preloadHandler)
	if dasar_states.requiredModulesIndex == dasar_states.requiredModulesMaxIndex then
		warn_normal(string.format(WARN_DASAR_INIT_FINNISHED, tick() - dasar_states.start_time))
		return
	end
	local module_children = moduleInstance:GetChildren()
	if #module_children <= 0 then
		return
	end

	for _, child_module in ipairs(module_children) do
		if not child_module:IsA("ModuleScript") then
			continue
		end

		preloadHandler(child_module, initRecursive)
	end
end

--[[
	Normal `pcall()` can not give you the detailed traceback.
	This uses `xpcall()`, which lets you have a custom error handler.
]]
local function pcall_traceback(f, ...)
	local traceback
	local success, msg = xpcall(f, function(err_msg)
		traceback = debug.traceback()
		return err_msg
	end, ...)

	return success, msg, traceback
end

--[[
	Attempts to require(module) in a seperate thread
	and catches any errors.
]]
local function requireModule(moduleInstance)
	return Promise.new(function(resolve)
		local moduleName = moduleInstance.Name
		local modulePath = moduleInstance:GetFullName()

		task.spawn(function()
			local success, attemptRequire, traceback = pcall_traceback(function()
				return require(moduleInstance)
			end)

			if not success then
				warn_err(string.format(ERR_MODULE_REQUIRE, moduleName, modulePath, attemptRequire), traceback)
				resolve(nil)
				return
			end

			dasar_states.requiredModulesIndex += 1
			dasar_states.requiredModules[moduleName] = attemptRequire
			resolve(attemptRequire)
		end)
	end)
end

local Dasar = {}

function Dasar.extract_and_preload_modules(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if not child:IsA("ModuleScript") then
			continue
		end

		dasar_states.requiredModulesMaxIndex += 1
	end

	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("ModuleScript") then
			continue
		elseif child:IsA("Folder") then
			Dasar.extract_and_preload_modules(child)
		end

		task.spawn(Dasar.PreloadModule, child, initRecursive)
	end
end

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
	err_type(moduleName, "moduleName", "string")

	local module = findModule(moduleName)
	if not module then
		err_msg_traceback(ERR_MODULE_NIL)
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
function Dasar.PreloadModule(moduleInstance, recursive)
	return Promise.new(function(resolve)
		err_instance(moduleInstance, "moduleInstance", "ModuleScript")
		recursive = recursive or initRecursive

		requireModule(moduleInstance):andThen(function(attemptRequire)
			if not attemptRequire then
				resolve()
				return
			end

			local modulePath = moduleInstance:GetFullName()

			if dasar_states.requiredModulesLoadedPaths[modulePath] then
				resolve()
				return
			end

			dasar_states.requiredModulesLoadedPaths[modulePath] = true

			local moduleConstructor = attemptRequire["new"]
			local moduleRun = attemptRequire["_run"]
			local moduleReady = attemptRequire["_ready"]

			if moduleConstructor and type(moduleConstructor) == "function" then
				resolve()
				return
			end

			if moduleRun and type(moduleRun) == "function" then
				table.insert(dasar_states.runServiceModules, moduleRun)
			end

			if moduleReady and type(moduleReady) == "function" then
				-- Always run moduleReady in a separate thread to prevent yield propagation
				task.spawn(function()
					local success, errorMsg, traceback = pcall_traceback(function()
						moduleReady()
					end)

					if not success then
						warn_err(string.format(ERR_MODULE_INIT, moduleInstance.Name, errorMsg), traceback)
					end

					-- No matter what happens with moduleReady, still run recursive
					if recursive then
						task.spawn(function()
							recursive(attemptRequire, moduleInstance, Dasar.PreloadModule)
							dasar_states.requiredModulesLoadedPaths[modulePath] = nil
						end)
					else
						dasar_states.requiredModulesLoadedPaths[modulePath] = nil
					end
				end)
			else
				-- If no moduleReady, still handle recursive
				if recursive then
					task.spawn(function()
						recursive(attemptRequire, moduleInstance, Dasar.PreloadModule)
						dasar_states.requiredModulesLoadedPaths[modulePath] = nil
					end)
				else
					dasar_states.requiredModulesLoadedPaths[modulePath] = nil
				end
			end

			resolve()
		end)
	end)
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
	if dasar_states.isStarted or dasar_states.isStarting then return end

	dasar_states.isStarting = true
	dasar_states.start_time = tick()
	warn_normal(WARN_DASAR_INIT)

	Provider.AwaitAllAssetsAsync()

	for _, location in pairs(FOLDER_LOCATIONS) do
		for _, folder_type in ipairs(FOLDER_TYPES) do
			local p_folder = location[folder_type]
			if p_folder then
				task.spawn(Dasar.extract_and_preload_modules, p_folder)
			end
		end
	end

	dasar_states.runServiceConnection = RunService.Heartbeat:Connect(function(dt)
		callRunFunctions(dt)
	end)

	dasar_states.isStarting = false
	dasar_states.isStarted = true
end

return Dasar