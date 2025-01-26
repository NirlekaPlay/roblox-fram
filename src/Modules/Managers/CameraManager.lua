--[[
		// FileName: CameraManager.lua
		// Written by: NirlekaDev
		// Description:
				A replacement from the Camera.lua class.
				Enables direct interaction with the camera,
				instead of having to create another class of it.

				CLIENT ONLY.
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local CameraSocket = require("CameraSocket")
local MathLib = require("math")
local SceneManager = require("SceneManager")
local SmoothValue = require("SmoothValue")

local camera = workspace.CurrentCamera or workspace.Camera
local currentCframe: CFrame
local currentFov : number
local currentSocket : string
local dur = 1.5
local elapsed = 0
local mouse = game.Players.LocalPlayer:GetMouse()
local moving = false
local socketArray = CameraSocket.fromArray(SceneManager.GetCurrentSceneCameraSockets())
local speaker_pan
local tiltMouse = false

local maxTilt = 15
local smoothTime = 1
local smoothTiltX = SmoothValue.new(Vector3.new(0, 0, 0), smoothTime)
local smoothTiltY = SmoothValue.new(Vector3.new(0, 0, 0), smoothTime)

local ease = MathLib.ease
local lerp = MathLib.lerp

local CameraManager = {}
CameraManager.ClassName = "CameraManager"
CameraManager.RunContext = "Client"

function CameraManager._ready()
	camera.CameraType = Enum.CameraType.Scriptable
end

function CameraManager._run(dt)
	CameraManager.LerpMovement(dt)
end

function CameraManager.BeginLerp(socketName: string, playSound: boolean)
	local activeSocket = socketArray[socketName]
	if activeSocket then
		currentSocket = activeSocket
		currentCframe = camera.CFrame
		currentFov = camera.FieldOfView
		elapsed = 0
		moving = true
	end

	if playSound then
		CameraManager.PanSound()
	end
end

function CameraManager.PanSound()
	if speaker_pan then
		local pitch = math.random(.5, 1)
		speaker_pan.pitch_scale = pitch
		speaker_pan.play()
	end
end

function CameraManager.LerpMovement(dt: number)
	if moving then
		elapsed += dt
		local c = math.clamp(elapsed / dur, 0.0, 1.0)
		c = ease(c, 0.2)
		local cframe = camera.CFrame:Lerp(currentSocket.cframe, c)
		local fov = lerp(currentFov, currentSocket.fov, c)
		camera.FieldOfView = fov
		camera.CFrame = cframe

		if camera.CFrame == cframe and camera.FieldOfView == fov then
			moving = false
		end
	end
end

function CameraManager.TiltCameraToMouse()
	if tiltMouse then
		local goalTiltX = (((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY) * -maxTilt)
		local goalTiltY = (((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX) * -maxTilt)

		local smoothX = smoothTiltX:Update(Vector3.new(math.rad(goalTiltX), 0, 0))
		local smoothY = smoothTiltY:Update(Vector3.new(0, math.rad(goalTiltY), 0))

		camera.CFrame = currentSocket.cframe * CFrame.Angles(
			smoothX.X,
			smoothY.Y,
			0
		)
	end
end

return CameraManager