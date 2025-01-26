--[[
		// FileName: SceneManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages scene loading.

				CLIENT ONLY.
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Provider = require("Provider")

local folder_storage_scenes = game.ReplicatedStorage.Scenes
local folder_workspace_scenes = workspace.Scenes
local scenes_array = {}
local current_loaded_scene = nil
local loading = true
local firstTimeLoading = true

local function waitForLoad()
	if loading then
		repeat task.wait() until not loading
	end
end

local SceneManager = {}
SceneManager.ClassName = "SceneManager"
SceneManager.RunContext = "Client"

function SceneManager._ready()
	for _, inst in ipairs(folder_storage_scenes:GetChildren()) do
		if not inst:IsA("Folder") then
			continue
		end

		scenes_array[inst.Name] = inst
	end

	for _, inst in ipairs(folder_workspace_scenes:GetChildren()) do
		if inst:IsA("Folder") then
			scenes_array[inst.Name] = inst
			SceneManager.LoadScene(inst.Name)
		end
	end

	loading = false
end

function SceneManager.LoadScene(alias: string)
	waitForLoad()
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
	Provider.PreloadAsyncDescendants(scene)
	current_loaded_scene = scene
	scene.Parent = folder_workspace_scenes

	if firstTimeLoading then
		firstTimeLoading = false
	end

	warn(string.format(":: SceneManager :: Scene '%s' loaded.", alias))

	return scene
end

function SceneManager.GetCurrentSceneCameraSockets()
	waitForLoad()
	if firstTimeLoading then
		repeat
			task.wait()
		until current_loaded_scene
	end
	if not current_loaded_scene then
		error(string.format(":: SceneManager :: Failed to get camera sockets. There is no scene loaded."))
	end

	return current_loaded_scene.CameraSockets:GetChildren()
end

return SceneManager