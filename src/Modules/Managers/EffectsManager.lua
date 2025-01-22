-- EffectsManager.lua
-- NirlekaDev
-- January 18, 2024

--[[
	Handles all effects on the client.
]]

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Camera = workspace.Camera or workspace.CurrentCamera

local function newInstance(name, parent, properties): Instance
	local instance = Instance.new(name)

	if properties then
		for k, v in pairs(properties) do
			instance[k] = v
		end
	end
	instance.Parent = parent

	return instance
end

local SETTINGS = {
	DefaultBlurOnEscOpen = 16
}

local TWEEN_INFOS = {
	TweenInfoExp = TweenInfo.new(1, Enum.EasingStyle.Exponential)
}

local EFFECTS_OBJECTS = {
	Blur = newInstance("BlurEffect", Camera, {Size = 0}),
	CC = newInstance("ColorCorrectionEffect", Camera)
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

function EffectsManager._ready()
	if GuiService.MenuIsOpen then
		Player_Values.IsMenuOpened = true
		EffectsManager.PlayAnimationAlias("FocusReleasedGreyBlur")
	else
		Player_Values.IsMenuOpened = false
		EffectsManager.PlayAnimationAlias("FocusGainedGreyBlur")
	end
	GuiService.MenuOpened:Connect(function()
		Player_Values.IsMenuOpened = true
		EffectsManager.PlayAnimationAlias("FocusReleasedGreyBlur")
	end)
	GuiService.MenuClosed:Connect(function()
		Player_Values.IsMenuOpened = false
		EffectsManager.PlayAnimationAlias("FocusGainedGreyBlur")
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