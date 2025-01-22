-- Provider.lua
-- NirlekaDev
-- January 19, 2025

--[[
	An optimized system for preloading game assets,
	and provides information about the Player.
]]

local ContentProvider = game:GetService("ContentProvider")

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Promise = require("Promise")

local Provider = {}

local CONTENT_PROPERTIES = {
	MeshPart = {"TextureID", "MeshID"},
	Decal = {"Texture"},
	Texture = {"Texture"},
	Sound = {"SoundId"},
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

-- Configuration for retry behavior
local DEFAULT_CONFIG = {
	maxRetries = -1,           -- -1 means infinite retries
	retryDelay = 1,           -- Delay between retries in seconds
	exponentialBackoff = true, -- Whether to increase delay between retries
	maxDelay = 30,            -- Maximum delay between retries in seconds
	logErrors = true          -- Whether to log error messages
}

local function calculateBackoff(baseDelay: number, attempt: number, maxDelay: number): number
	if attempt <= 1 then
	return baseDelay
	end
	-- Calculate exponential delay: baseDelay * 2^(attempt-1)
	local delay = baseDelay * math.pow(2, attempt - 1)
	-- Ensure we don't exceed maxDelay
	return math.min(delay, maxDelay)
end

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
	if not properties then return urls end

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

	for _, child in ipairs(container:GetDescendants()) do
		if CONTENT_PROPERTIES[child.ClassName] then
			local urls = extractContentUrls(child)
			for _, url in ipairs(urls) do
				table.insert(assets, url)
			end
		end
	end

	return assets
end

--[=[
	Main function to load an asset with retries

	@param asset: string | Instance - The asset to load
	@param config: table? - Optional configuration for retry behavior
	@return Promise that resolves when asset is loaded or rejects if max retries reached
]=]
function Provider.LoadAssetWithRetry(asset: string | Instance, config: table?)
	-- Merge provided config with default config
	local settings = table.clone(DEFAULT_CONFIG)
	if config then
	for key, value in pairs(config) do
		settings[key] = value
		end
	end

	return Promise.new(function(resolve, reject)
	local attempts = 0

	local function attemptLoad()
		attempts += 1

		-- Log attempt if logging is enabled
		if settings.logErrors then
		print(string.format("[ContentLoader] Attempt %d to load asset: %s",
			attempts,
			typeof(asset) == "string" and asset or asset.Name))
		end

		-- Attempt to preload the asset
		local success, result = pcall(function()
		local status
		ContentProvider:PreloadAsync({asset}, function(_, loadStatus)
			status = loadStatus
		end)
		return status
		end)

		-- Handle the loading result
		if success and result == Enum.AssetFetchStatus.Success then
		-- Asset loaded successfully
		resolve(asset)
		else
		-- Loading failed - handle retry logic
		local errorMsg = string.format("Failed to load asset (Attempt %d): %s",
			attempts,
			if success then result else tostring(result))

		if settings.logErrors then
			warn(errorMsg)
		end

		-- Check if we should retry
		if settings.maxRetries == -1 or attempts < settings.maxRetries then
			-- Calculate delay for next attempt
			local delay = if settings.exponentialBackoff
			then calculateBackoff(settings.retryDelay, attempts, settings.maxDelay)
			else settings.retryDelay

			-- Log retry information
			if settings.logErrors then
			print(string.format("[ContentLoader] Retrying in %.1f seconds...", delay))
			end

			-- Wait and retry
			task.wait(delay)
			attemptLoad()
		else
			-- Max retries reached - reject the promise
			reject(string.format("Max retries (%d) reached. %s", settings.maxRetries, errorMsg))
		end
		end
	end

	attemptLoad()
	end)
end

function Provider.LoadAssetInfinite(asset: string | Instance)
	return Provider.LoadAssetWithRetry(asset, {
	maxRetries = -1,
	retryDelay = 1,
	exponentialBackoff = true,
	logErrors = true
	})
end

function Provider.LoadAssetLimited(asset: string | Instance, maxAttempts: number)
	return Provider.LoadAssetWithRetry(asset, {
	maxRetries = maxAttempts,
	retryDelay = 1,
	exponentialBackoff = true,
	logErrors = true
	})
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

	for _, asset in ipairs(collectAssets(workspace)) do
		table.insert(assets, asset)
	end

	for _, asset in ipairs(collectAssets(game:GetService("SoundService"))) do
		table.insert(assets, asset)
	end

	if game.ReplicatedStorage:FindFirstChild("Images") then
		for _, asset in ipairs(collectAssets(game.ReplicatedStorage.Images)) do
			table.insert(assets, asset)
		end
	end

	return Provider.AwaitAssetsAsync(assets)
end

return Provider