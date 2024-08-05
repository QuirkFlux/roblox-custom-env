

local MyModule = {}

-- Required dependencies
local compileAndRun = require(18182274046)
local debugger = require(18387864102)
local chacha20 = require(script.Parent.ChaCha20)

local customEnv = {}


local function deepCpy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCpy(v)
		end
		copy[k] = v
	end
	return copy
end

customEnv.print = print
customEnv.select = select
customEnv.unpack = table.unpack 
customEnv.error = error
customEnv.pairs = pairs
customEnv.require = require
customEnv.ipairs = ipairs
customEnv.tonumber = tonumber
customEnv.bit32 = deepCpy(bit32 or {})
customEnv.tostring = tostring


customEnv.string = {
	byte = string.byte,
	char = string.char,
	find = string.find,
	format = string.format,
	gmatch = string.gmatch,
	gsub = string.gsub,
	len = string.len,
	lower = string.lower,
	match = string.match,
	rep = string.rep,
	reverse = string.reverse,
	sub = string.sub,
	upper = string.upper,
}
customEnv.chacha20_encrypt = chacha20.chacha20_encrypt
customEnv.chacha20_decrypt = chacha20.chacha20_decrypt

local function runner(func, env)

	local i = 1

	while true do

		local name = debug.getupvalue(func, i)

		if not name then break end

		if name == "" then
			local success, err = pcall(debugger.setupValue, func, i, env)

			if not success then
				warn("Error setting up custom environment: " .. err)
				return nil, err
			end
			break 
		end

		i = i + 1
	end

	local result, runtimeError = pcall(func)

	if not result then
		warn("Error executing function in custom environment: " .. runtimeError)
		return nil, runtimeError
	end
	return result
end

function MyModule.ChaCha20_encrypt(key, nonce, message)
	assert(#key == 32, "Key must be 32 bytes")
	assert(#nonce == 12, "Nonce must be 12 bytes")

	local counter = 0 -- Initial counter value
	local encrypted_message = chacha20.chacha20_encrypt(key, counter, nonce, message)

	return encrypted_message

end



function MyModule.ChaCha20_decrypt(key, nonce, encrypted_message)
	assert(#key == 32, "Key must be 32 bytes")
	assert(#nonce == 12, "Nonce must be 12 bytes")

	local counter = 0 -- Initial counter value
	local decrypted_message = chacha20.chacha20_decrypt(key, counter, nonce, encrypted_message)

	return decrypted_message
end


function MyModule.encryptAndRun(key, nonce, sourceCode)
	local encryptedCode = MyModule.ChaCha20_encrypt(key, nonce, sourceCode)
	local decryptedCode = MyModule.ChaCha20_decrypt(key, nonce, encryptedCode)
	MyModule.compileAndRunSource(decryptedCode)
end






function MyModule.compileAndRunSource(sourceCode)
	local compiledFunc, compileError = compileAndRun(sourceCode, customEnv)
	if not compiledFunc then


		return
	end


	local result, runtimeError = pcall(function()
		return runner(compiledFunc, customEnv)
	end)
	if not result then

	end
end





return MyModule






