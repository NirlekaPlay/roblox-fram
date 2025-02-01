local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local instLibrary = require("inst")

local FOLDER_REMOTE_FUNCTIONS: Folder
local FOLDER_TEMP: Folder
local REMOTE_FUNCTION: RemoteFunction

local Middleware = {}

function Middleware._ready()
	if RunService:IsClient() then
		FOLDER_REMOTE_FUNCTIONS = ReplicatedStorage:WaitForChild("MiddleWareRemoteFuncs")
		REMOTE_FUNCTION = FOLDER_REMOTE_FUNCTIONS:WaitForChild("RemoteFunction")
		FOLDER_TEMP = ReplicatedStorage:WaitForChild("temp")
	else
		FOLDER_REMOTE_FUNCTIONS = instLibrary.create("Folder", "MiddleWareRemoteFuncs", ReplicatedStorage)
		REMOTE_FUNCTION = instLibrary.create("RemoteFunction", nil, FOLDER_REMOTE_FUNCTIONS)
		FOLDER_TEMP = instLibrary.create("Folder", "temp", ReplicatedStorage)

		REMOTE_FUNCTION.OnServerInvoke = function(plr: Player, requestName: string)
			if requestName == "GetServerStorageChildren" then
				local children = ServerStorage:GetChildren()
				local shits = {}
				for _, child in ipairs(children) do
					local cloneChild = instLibrary.deepClone(child, FOLDER_TEMP)
					table.insert(shits, cloneChild)
				end

				return shits
			elseif requestName == "LoadLocalCharacter" then
				plr:LoadCharacter()

				return plr.Character
			end
		end
	end
end

function Middleware.GetServerStorageContent()
	if RunService:IsClient() then
		local items, errorMsg = REMOTE_FUNCTION:InvokeServer("GetServerStorageChildren")
		if items then
			return items
		else
			warn(":: Middleware :: Attempt to get contents of ServerStorage failed: "..errorMsg)
		end
	end
end

function Middleware.LoadLocalCharacter()
	if RunService:IsClient() then
		REMOTE_FUNCTION:InvokeServer("LoadLocalCharacter")
	end
end

return Middleware
