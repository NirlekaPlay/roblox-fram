-- Provider.lua
-- NirlekaDev
-- January 19, 2025

--[[
	An optimized system for preloading game assets,
	and provides information about the Player.
]]

local ContentProvider = game:GetService("ContentProvider")

local Provider = {}

--[[
	Due to for some reason, there is a high chance of failure when loading a non-image asset.
	Leaving them as an Instance makes the chance of success higher.
]]
local CONTENT_PROPERTIES_IGNORE = {
	Sound = {"SoundId"},
	Animation = {"AnimationId"}
}

local CONTENT_PROPERTIES = {
	MeshPart = {"TextureID", "MeshID"},
	Decal = {"Texture"},
	Texture = {"Texture"},
	ParticleEmitter = {"Texture"},
	Trail = {"Texture"},
	Beam = {"Texture"},
	Sky = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"},
	ImageLabel = {"Image"},
	ImageButton = {"Image"},
	ViewportFrame = {"ImageColor3", "ImageTransparency"},
	VideoFrame = {"Video"},
	FileMesh = {"TextureId"},
	SpecialMesh = {"TextureId"},
}

local PARENTS_TO_SEARCH = {
	game:GetService("Workspace"),
	game:GetService("SoundService"),
	game:GetService("ReplicatedStorage").Images
}

local processedAssets = {}

local function waitForGameLoaded()
	if game:IsLoaded() then return end
	repeat
		task.wait()
	until game:IsLoaded()
end

local function extractContentUrls(instance)
	local urls = {}

	local properties = CONTENT_PROPERTIES[instance.ClassName]
	if CONTENT_PROPERTIES_IGNORE then
		return {instance}
	elseif not properties then
		return nil
	end

	for _, prop in ipairs(properties) do
		local success, result = pcall(function()
			return instance[prop]
		end)

		if success and result and typeof(result) == "string" and result:match("^rbxasset://") or result:match("^rbxassetid://") then
			local assetKey = result .. "_" .. prop
			if not processedAssets[assetKey] then
				table.insert(urls, result)
				processedAssets[assetKey] = true
			end
		end
	end

	return urls
end

local function collectAssets(container: Instance)
	local assets = {}

	for _, child in ipairs(container:GetChildren()) do
		local urls = extractContentUrls(child)
		if urls then
			for _, url in ipairs(urls) do
				table.insert(assets, url)
			end
		end

		if child:IsA("Folder") or child:IsA("Model") then
			local childAssets = collectAssets(child)
			for _, asset in ipairs(childAssets) do
				table.insert(assets, asset)
			end
		end
	end

	return assets
end

function Provider.AwaitAssetsAsync(assets)
	waitForGameLoaded()

	local max_assets = #assets
	local loaded_assets = {}
	local failed_assets = {}
	local timedout_assets = {}
	local start_time = tick()

	local completed = 0
	local function updateProgress(asset, status)
		completed = completed + 1
		if status == Enum.AssetFetchStatus.Success then
			table.insert(loaded_assets, asset)
		elseif status == Enum.AssetFetchStatus.TimedOut then
			table.insert(timedout_assets, asset)
		elseif status == Enum.AssetFetchStatus.Failure then
			table.insert(failed_assets, asset)
		end

		if completed % math.max(1, math.floor(max_assets / 10)) == 0 or completed == max_assets then
			local progress = (completed / max_assets) * 100
			warn(string.format(":: Provider :: Progress: %.1f%% (%d/%d)", progress, completed, max_assets))
		end
	end

	local BATCH_SIZE = 50
	for i = 1, #assets, BATCH_SIZE do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		ContentProvider:PreloadAsync(batch, updateProgress)
	end

	local elapsed = tick() - start_time
	warn(string.format(
		":: Provider :: Loading complete.\nLoaded: %d\nTimed Out: %d\nFailed: %d\nTime: %.2f seconds\nAverage: %.2f assets/second",
		#loaded_assets,
		#timedout_assets,
		#failed_assets,
		elapsed,
		max_assets / elapsed
	))

	return loaded_assets, timedout_assets, failed_assets
end

function Provider.AwaitAllAssetsAsync()
	waitForGameLoaded()

	local assets = {}

	for _, parent in ipairs(PARENTS_TO_SEARCH) do
		for _, asset in ipairs(collectAssets(parent)) do
			table.insert(assets, asset)
		end
	end

	return Provider.AwaitAssetsAsync(assets)
end

return Provider