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
	TweenInfoExp = TweenInfo.new(1, Enum.EasingStyle.Exponential),
	TweenInfoInstant = TweenInfo.new(0.3, Enum.EasingStyle.Exponential),
}

local EFFECTS_OBJECTS = {
	Blur = newInstance("BlurEffect", nil, Camera, {Size = 0}),
	CC = newInstance("ColorCorrectionEffect", nil, Camera),
	CCOcclude = newInstance("ColorCorrectionEffect", nil, Camera)
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
	},
	LightShutOff = {
		{
			instance = EFFECTS_OBJECTS.CCOcclude,
			tweenInfo = TWEEN_INFOS.TweenInfoInstant,
			properties = {Brightness = -1}
		}
	},
	LightShutOn = {
		{
			instance = EFFECTS_OBJECTS.CCOcclude,
			tweenInfo = TWEEN_INFOS.TweenInfoInstant,
			properties = {Brightness = 0}
		}
	},
	FadeOut = {
		{
			instance = EFFECTS_OBJECTS.CCOcclude,
			tweenInfo = TWEEN_INFOS.TweenInfoExp,
			properties = {Brightness = -1}
		}
	}
}

local Player_Values = {
	IsMouseLock = true,
	IsMenuOpened = false,
	IsWindowFocused = true,
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
	local function handleFocusChange()
		local animationAlias
		if (not Player_Values.IsMenuOpened) and Player_Values.IsWindowFocused then
			animationAlias = "FocusGainedGreyBlur"
		else
			animationAlias = "FocusReleasedGreyBlur"
		end
		EffectsManager.PlayAnimationAlias(animationAlias)
	end

	handleFocusChange((GuiService.MenuIsOpen ~= true))

	GuiService.MenuOpened:Connect(function()
		Player_Values.IsMenuOpened = true
		handleFocusChange()
	end)

	GuiService.MenuClosed:Connect(function()
		Player_Values.IsMenuOpened = false
		handleFocusChange()
	end)

	UserInputService.WindowFocused:Connect(function()
		Player_Values.IsWindowFocused = true
		handleFocusChange()
	end)

	UserInputService.WindowFocusReleased:Connect(function()
		Player_Values.IsWindowFocused = false
		handleFocusChange()
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