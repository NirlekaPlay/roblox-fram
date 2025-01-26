--[[
		// FileName: SceneManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages scene loading.

				CLIENT ONLY.
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Provider = require("Provider")

local folder_storage_scenes = game:GetService("ServerStorage").Scenes
local folder_workspace_scenes = workspace.Scenes
local scenes_array = {}
local current_loaded_scene = nil

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
end

function SceneManager.LoadScene(alias: string)
	local scene = scenes_array[alias]
	if not scene then
		error(string.format(":: SceneManager :: Scene '%s' does not exist.", alias))
	end

	if current_loaded_scene then
		current_loaded_scene.Parent = folder_storage_scenes
		current_loaded_scene = nil
	end
	Provider.PreloadAsyncDescendants(scene)
	current_loaded_scene = scene
	scene.Parent = folder_workspace_scenes

	warn(string.format(":: SceneManager :: Scene '%s' loaded.", alias))

	return scene
end

function SceneManager.GetCurrentSceneCameraSockets()
	if not current_loaded_scene then
		error(string.format(":: SceneManager :: Failed to get camera sockets. There is no scene loaded."))
	end

	return current_loaded_scene.CameraSockets
end

return SceneManager