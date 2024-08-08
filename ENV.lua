local MyModule = {}

-- Required dependencies
local customEnv = {}

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

-- Copy global functions to customEnv
customEnv.print = print
customEnv.require = require
customEnv.select = select
customEnv.unpack = table.unpack
customEnv.error = error
customEnv.pairs = pairs
customEnv.ipairs = ipairs
customEnv.tonumber = tonumber
customEnv.bit32 = deepCopy(bit32 or {})
customEnv.tostring = tostring
customEnv.warn = warn

-- Copy string functions to customEnv
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

-- Add chacha20 encryption and decryption functions to customEnv
customEnv.chacha20_encrypt = require(script.Parent.Parent.ChaCha20).chacha20_encrypt
customEnv.chacha20_decrypt = require(script.Parent.Parent.ChaCha20).chacha20_decrypt

-- Define a custom require function that calls the global require
local function globalRequire(moduleId)
	return require(moduleId)
end

local function runner(func)
	local result, runtimeError = pcall(func)
	if not result then
		warn("Error executing function: " .. runtimeError)
		return nil, runtimeError
	end
	return result
end

function MyModule.ChaCha20_encrypt(key, nonce, message)
	assert(#key == 32, "Key must be 32 bytes")
	assert(#nonce == 12, "Nonce must be 12 bytes")

	local counter = 0 -- Initial counter value
	local encrypted_message = customEnv.chacha20_encrypt(key, counter, nonce, message)

	return encrypted_message
end

function MyModule.ChaCha20_decrypt(key, nonce, encrypted_message)
	assert(#key == 32, "Key must be 32 bytes")
	assert(#nonce == 12, "Nonce must be 12 bytes")

	local counter = 0 -- Initial counter value
	local decrypted_message = customEnv.chacha20_decrypt(key, counter, nonce, encrypted_message)

	return decrypted_message
end

function MyModule.encryptAndRun(key, nonce, sourceCode)
	local encryptedCode = MyModule.ChaCha20_encrypt(key, nonce, sourceCode)
	local decryptedCode = MyModule.ChaCha20_decrypt(key, nonce, encryptedCode)
	MyModule.compileAndRunSource(decryptedCode)
end

function MyModule.compileAndRunSource(sourceCode)
	local compiledFunc, compileError = globalRequire(18182274046)(sourceCode, customEnv)
	if not compiledFunc then
		--warn("Error compiling source code: " .. compileError)
		return
	end

	local result, runtimeError = pcall(function()
		return runner(compiledFunc)
	end)
	if not result then
		warn("Error running compiled function: " .. runtimeError)
	end
end

return MyModule
