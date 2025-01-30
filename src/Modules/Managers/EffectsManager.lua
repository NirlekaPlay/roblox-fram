--[[
		// FileName: EffectsManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages visual effects on the client.

				CLIENT ONLY.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Camera = workspace.Camera or workspace.CurrentCamera

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local newInstance = require("inst").create

local SETTINGS = {
	DefaultBlurOnEscOpen = 16
}

local TWEEN_INFOS = {
	TweenInfoExp = TweenInfo.new(1, Enum.EasingStyle.Exponential)
}

local EFFECTS_OBJECTS = {
	Blur = newInstance("BlurEffect", nil, Camera, {Size = 0}),
	CC = newInstance("ColorCorrectionEffect", nil, Camera)
}

local ANIMATIONS = {
	FocusReleasedGreyBlur = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			tweenInfo = TWEEN_INFOS.TweenInfoExp,
			properties = {Size = SETTINGS.DefaultBlurOnEscOpen}
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			tweenInfo = TWEEN_INFOS.TweenInfoExp,
			properties = {Contrast = 1, Saturation = -1}
		}
	},
	FocusGainedGreyBlur = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			tweenInfo = TWEEN_INFOS.TweenInfoExp,
			properties = {Size = 0}
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			tweenInfo = TWEEN_INFOS.TweenInfoExp,
			properties = {Contrast = 0, Saturation = 0}
		}
	}
}

local Player_Values = {
	IsMouseLock = true,
	IsMenuOpened = false,
	IsDevConsoleOpen = false
}

export type TweenInfoStack = {
	instance: Instance,
	tweenInfo: TweenInfo,
	properties: {[string]: any}
}

local EffectsManager = {}
EffectsManager.ClassName = "EffectsManager"
EffectsManager.RunContext = "Client"

function EffectsManager._ready()
	local function handleFocusChange(isFocused)
		Player_Values.IsMenuOpened = isFocused
		local animationAlias
		if isFocused then
			animationAlias = "FocusGainedGreyBlur"
		else
			animationAlias = "FocusReleasedGreyBlur"
		end
		EffectsManager.PlayAnimationAlias(animationAlias)
	end

	handleFocusChange((GuiService.MenuIsOpen ~= true))

	GuiService.MenuOpened:Connect(function()
		handleFocusChange(false)
	end)

	GuiService.MenuClosed:Connect(function()
		handleFocusChange(true)
	end)

	UserInputService.WindowFocused:Connect(function()
		handleFocusChange(true)
	end)

	UserInputService.WindowFocusReleased:Connect(function()
		handleFocusChange(false)
	end)
end

function EffectsManager.PlayInstanceTween(tweenInfoStack: TweenInfoStack)
	for property, value in pairs(tweenInfoStack.properties) do
		TweenService:Create(tweenInfoStack.instance, tweenInfoStack.tweenInfo, {[property] = value}):Play()
	end
end

function EffectsManager.PlayInstanceTweenArray(array: {TweenInfoStack})
	for _, tis in pairs(array) do
		EffectsManager.PlayInstanceTween(tis)
	end
end

function EffectsManager.PlayAnimationAlias(alias: string)
	local animation = ANIMATIONS[alias]
	if not animation then
		return
	end

	EffectsManager.PlayInstanceTweenArray(animation)
end

return EffectsManager