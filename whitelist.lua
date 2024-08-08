local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ui = script.UI:Clone()

local wl = "https://raw.githubusercontent.com/QuirkFlux/roblox-custom-env/main/whitelist.json"

local function fetchWhitelist()
	local success, response = pcall(function()
		return HttpService:GetAsync(wl)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		--print("Fetched whitelist:", response)  -- Debugging line
		return data
	else
		--warn("Failed to fetch whitelist:", response)
		return {}
	end
end

local function isWhitelisted(userId)
	local whitelist = fetchWhitelist()
	--print("Checking whitelist for UserId:", userId)  -- Debugging line
	for _, id in pairs(whitelist) do
		if userId == id then
			return true
		end
	end
	return false
end

local function loadUIForWhitelistedPlayer(player)
	if ui then
		local uiClone = ui:Clone()
		uiClone.Parent = player:WaitForChild("PlayerGui")
		--print("UI loaded for player:", player.Name)  -- Debugging line
	else
		--warn("UI template not found.")
	end
end

Players.PlayerAdded:Connect(function(player)
	if isWhitelisted(player.UserId) then
		loadUIForWhitelistedPlayer(player)
	else
		--print("Player not whitelisted:", player.Name)  -- Debugging line
	end
end)
