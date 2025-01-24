-- CharacterManager.lua
-- NirlekaDev
-- January 24, 2025

--[[
	Manages all things related to the player's character.
]]

local Players = game:GetService("Players")

local local_player = Players.LocalPlayer
local camera = workspace.CurrentCamera or workspace.Camera
local turn_head = true
local connections = {}

local SETTINGS = {
	HeadFolVertFactor = 1,
	HeadFolHorFactor = 0.5,
	HeadFolHorSpeed = 0.3
}

local CONSTANTS = {
	originalNeckCFrame0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
}

local function characterSetup(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		turn_head = true
		connections["humanoidDied"] = humanoid.Died:Connect(function()
			turn_head = false
			connections["humanoidDied"]:Disconnect()
		end)
	end
	connections["characterDestroying"] = character.Destroying:Connect(function()
		turn_head = false
		connections["characterDestroying"]:Disconnect()
	end)
end

local CharacterManager = {}

function CharacterManager._ready()
	local character = local_player.Character
	if character then
		characterSetup(character)
	end
	local_player.CharacterAdded:Connect(function(char)
		characterSetup(char)
	end)
end

function CharacterManager._run()
	if turn_head then
		CharacterManager.TurnHeadRelativeToCamera(
			local_player.Character, true, camera.CFrame.Position,
			SETTINGS.HeadFolVertFactor, SETTINGS.HeadFolHorFactor, SETTINGS.HeadFolHorSpeed
		)
	end
end

function CharacterManager.TurnHeadRelativeToCamera(character, inverted, pos, vertFactor, horFactor, speed)
	local Head = character.Head
	local Torso = character.Torso
	local Neck = character.Torso.Neck

	local distance = (Head.CFrame.Position - pos).Magnitude
	local difference = Head.CFrame.Y - pos.Y

	local diffUnit = ((Head.Position - pos).Unit)
	local torsoLV = Torso.CFrame.LookVector

	local angle = CFrame.Angles(
		math.asin(difference / distance) * vertFactor,
		0,
		diffUnit:Cross(torsoLV).Y * horFactor
	)
	if inverted then
		angle = CFrame.Angles(
			-(math.asin(difference / distance) * vertFactor),
			0,
			-diffUnit:Cross(torsoLV).Y * horFactor
		)
	end

	Neck.C0 = Neck.C0:Lerp(CONSTANTS.originalNeckCFrame0 * angle, speed / 2)
end

return CharacterManager