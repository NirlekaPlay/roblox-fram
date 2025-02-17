--[[
		// FileName: SceneManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages scene loading.

				CLIENT ONLY.
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Provider = require("Provider")
local Signal = require("Signal")

local folder_storage_scenes = game.ReplicatedStorage.Scenes
local folder_workspace_scenes = workspace.Scenes
local scenes_array = {}
local current_loaded_scene = nil
local ready = false

local SceneManager = {}
SceneManager.ClassName = "SceneManager"
SceneManager.RunContext = "Client"
SceneManager.SceneLoaded = Signal.new()
SceneManager.Ready = Signal.new()

local function preloadSceneAssets(scene_folder)
	task.spawn(function()
		Provider.PreloadAsyncDescendants(scene_folder)
		current_loaded_scene = scene_folder
		scene_folder.Parent = folder_workspace_scenes

		SceneManager.SceneLoaded:Fire(scene_folder)
		warn(string.format(":: SceneManager :: Scene '%s' loaded.", scene_folder.Name))
	end)
end

function SceneManager._ready()
	for _, inst in ipairs(folder_storage_scenes:GetChildren()) do
		if not inst:IsA("Folder") then
			continue
		end

		scenes_array[inst.Name] = inst
	end

	for _, inst in ipairs(folder_workspace_scenes:GetChildren()) do
		if inst:IsA("Folder") then
			SceneManager.LoadCurrentWorkspaceScene(inst)
		end
	end

	ready = true
	SceneManager.Ready:Fire()
end

function SceneManager:IsSceneLoaded()
	return current_loaded_scene ~= nil
end

function SceneManager:IsManagerReady()
	return ready
end

function SceneManager.LoadScene(alias: string)
	local scene = scenes_array[alias]
	if not scene then
		error(string.format(":: SceneManager :: Scene '%s' does not exist.", alias))
	end
	if current_loaded_scene == scene then
		warn(string.format(":: SceneManager :: Scene '%s' is already loaded.", alias))
		return
	end

	if current_loaded_scene then
		current_loaded_scene.Parent = folder_storage_scenes
		current_loaded_scene = nil
	end

	preloadSceneAssets(scene)

	return SceneManager.SceneLoaded
end

function SceneManager.LoadCurrentWorkspaceScene(scene_folder: Folder)
	scenes_array[scene_folder.Name] = scene_folder

	if current_loaded_scene then
		current_loaded_scene.Parent = folder_storage_scenes
		current_loaded_scene = nil
	end

	preloadSceneAssets(scene_folder)

	return SceneManager.SceneLoaded
end

function SceneManager.GetCurrentSceneCameraSockets()
	if not current_loaded_scene then
		error(string.format(":: SceneManager :: Failed to get camera sockets. There is no scene loaded."))
	end

	return current_loaded_scene.CameraSockets:GetChildren()
end

return SceneManager