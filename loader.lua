local module = {}
local RunService = game:GetService("RunService")
--[[
if RunService:IsStudio() then
	return module 
end
]]
local ChaCha20 = require(script.Parent.ChaCha20)
task.wait(0.5)

local function generatebyte(length)
	local bytes = {}
	for i = 1, length do
		table.insert(bytes, string.char(math.random(0, 255)))
	end
	return table.concat(bytes)
end

function module.generatekey()
	return generatebyte(32)
end

function module.generateNonce()
	return generatebyte(12)
end

function module.Code(code)
	local loader = require(script.lol)
	local key = module.generatekey()
	local nonce = module.generateNonce()

	loader.encryptAndRun(key, nonce, code)


end

return module
