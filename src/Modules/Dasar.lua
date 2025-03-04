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
local Promise = require(game.ReplicatedStorage.Modules.Promise) -- User's Promise library

local DASAR_STRING_HEADER = ":: Dasar :: "
local ERR_CIRCULAR_DEPENDENCY = "Circular dependency detected on path: %s!"
local ERR_MODULE_INIT = "Attempted to call %s::_ready() \n%s"
local ERR_MODULE_LOCATIONS = "No module locations configured in module_locations!"
local ERR_MODULE_REQUIRE = "Attempted to require('%s') of path '%s' \n%s"
local ERR_MODULE_NIL = "Module '%s' does not exist!"
local WARN_DASAR_INIT = "Initializing Dasar. . ."
local WARN_DASAR_INIT_FINNISHED = "Initialization finished; Time: %s"
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
	error(string.format(DASAR_STRING_HEADER .. msg .. "\n\n%s", traceback))
end

local function err_msg_traceback(msg)
	error(string.format(DASAR_STRING_HEADER .. msg .. "\n\n%s", debug.traceback(2)))
end

local function warn_err(msg, traceback)
	warn(string.format(DASAR_STRING_HEADER .. msg .. "\n\n%s", traceback))
end

local function warn_normal(msg)
	warn(DASAR_STRING_HEADER .. msg)
end

local function callRunFunctions(dt)
	for _, func in pairs(dasar_states.runServiceModules) do
		task.spawn(func, dt)
	end
end

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

local function pcall_traceback(f, ...)
	local traceback
	local success, msg = xpcall(f, function(err_msg)
		traceback = debug.traceback()
		return err_msg
	end, ...)

	return success, msg, traceback
end

local function requireModule(moduleInstance)
	return Promise.new(function(resolve, reject)
		task.spawn(function()
			local moduleName = moduleInstance.Name
			local modulePath = moduleInstance:GetFullName()

			local success, moduleResult, traceback = pcall_traceback(function()
				return require(moduleInstance)
			end)

			if not success then
				warn_err(string.format(ERR_MODULE_REQUIRE, moduleName, modulePath, moduleResult), traceback)
				reject(moduleResult)
				return
			end

			dasar_states.requiredModulesIndex += 1
			dasar_states.requiredModules[moduleName] = moduleResult

			resolve(moduleResult)
		end)
	end)
end

local Dasar = {}

function Dasar.extract_and_preload_modules(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA("ModuleScript") then
			dasar_states.requiredModulesMaxIndex += 1
		end
	end

	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ModuleScript") then
			Dasar.PreloadModule(child)
		elseif child:IsA("Folder") then
			Dasar.extract_and_preload_modules(child)
		end
	end
end

function Dasar.Require(moduleName: string)
	local module = findModule(moduleName)
	if not module then
		err_msg_traceback(ERR_MODULE_NIL)
		return
	end
	return require(module)
end

function Dasar.PreloadModule(moduleInstance: ModuleScript)
	if not moduleInstance:IsA("ModuleScript") then
		return
	end

	local modulePath = moduleInstance:GetFullName()
	if dasar_states.requiredModulesLoadedPaths[modulePath] then
		return
	end
	dasar_states.requiredModulesLoadedPaths[modulePath] = true

	requireModule(moduleInstance):andThen(function(attemptRequire)
		if not attemptRequire then
			return
		end

		local moduleConstructor = attemptRequire["new"]
		local moduleRun = attemptRequire["_run"]
		local moduleReady = attemptRequire["_ready"]

		if moduleConstructor and type(moduleConstructor) == "function" then
			return
		end

		if moduleRun and type(moduleRun) == "function" then
			table.insert(dasar_states.runServiceModules, moduleRun)
		end

		if moduleReady and type(moduleReady) == "function" then
			return Promise.new(function(resolve, reject)
				task.spawn(function()
					local success, errorMsg, traceback = pcall_traceback(moduleReady)

					if not success then
						warn_err(string.format(ERR_MODULE_INIT, moduleInstance.Name, errorMsg), traceback)
						reject(errorMsg)
						return
					end

					resolve()
				end)
			end)
		end
	end):catch(function(err)
		warn("Module failed to load:", err)
	end)

	dasar_states.requiredModulesLoadedPaths[modulePath] = nil
end

function Dasar.Start()
	if dasar_states.isStarted or dasar_states.isStarting then
		return
	end

	dasar_states.isStarting = true
	dasar_states.start_time = tick()
	warn_normal(WARN_DASAR_INIT)

	Provider.AwaitAllAssetsAsync()

	for _, location in pairs(FOLDER_LOCATIONS) do
		for _, folder_type in ipairs(FOLDER_TYPES) do
			local p_folder = location[folder_type]
			if p_folder then
				Dasar.extract_and_preload_modules(p_folder)
			end
		end
	end

	dasar_states.runServiceConnection = RunService.Heartbeat:Connect(function(dt)
		callRunFunctions(dt)
	end)

	dasar_states.isStarting = false
	dasar_states.isStarted = true
	warn_normal(string.format(WARN_DASAR_INIT_FINNISHED, tick() - dasar_states.start_time))
end

return Dasar