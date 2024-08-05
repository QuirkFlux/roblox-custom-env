--ChaCha20

local app, concat = table.insert, table.concat
local bit32 = bit32

------------------------------------------------------------

-- chacha quarter round (rotl inlined)
local function qround(st,x,y,z,w)
	-- st is a chacha state: an array of 16 u32 words
	-- x,y,z,w are indices in st
	local a, b, c, d = st[x], st[y], st[z], st[w]
	local t
	a = (a + b) % 0x100000000
	--d = rotl32(d ~ a, 16)
	t = bit32.bxor(d, a); d = bit32.bor(bit32.lshift(t, 16), bit32.rshift(t, 16))
	c = (c + d) % 0x100000000
	--b = rotl32(b ~ c, 12)
	t = bit32.bxor(b, c); b = bit32.bor(bit32.lshift(t, 12), bit32.rshift(t, 20))
	a = (a + b) % 0x100000000
	--d = rotl32(d ~ a, 8)
	t = bit32.bxor(d, a); d = bit32.bor(bit32.lshift(t, 8), bit32.rshift(t, 24))
	c = (c + d) % 0x100000000
	--b = rotl32(b ~ c, 7)
	t = bit32.bxor(b, c); b = bit32.bor(bit32.lshift(t, 7), bit32.rshift(t, 25))
	st[x], st[y], st[z], st[w] = a, b, c, d
	return st
end

-- chacha20 state and working state are allocated once and reused
-- by each invocation of chacha20_block()
local chacha20_state = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local chacha20_working_state = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

local chacha20_block = function(key, counter, nonce)
	-- key: u32[8]
	-- counter: u32
	-- nonce: u32[3]
	local st = chacha20_state 		-- state
	local wst = chacha20_working_state 	-- working state
	-- initialize state
	st[1], st[2], st[3], st[4] =
		0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
	for i = 1, 8 do st[i+4] = key[i] end
	st[13] = counter
	for i = 1, 3 do st[i+13] = nonce[i] end
	-- copy state to working_state
	for i = 1, 16 do wst[i] = st[i] end
	-- run 20 rounds, ie. 10 iterations of 8 quarter rounds
	for _ = 1, 10 do           --RFC reference:
		qround(wst, 1,5,9,13)  --1.  QUARTERROUND ( 0, 4, 8,12)
		qround(wst, 2,6,10,14) --2.  QUARTERROUND ( 1, 5, 9,13)
		qround(wst, 3,7,11,15) --3.  QUARTERROUND ( 2, 6,10,14)
		qround(wst, 4,8,12,16) --4.  QUARTERROUND ( 3, 7,11,15)
		qround(wst, 1,6,11,16) --5.  QUARTERROUND ( 0, 5,10,15)
		qround(wst, 2,7,12,13) --6.  QUARTERROUND ( 1, 6,11,12)
		qround(wst, 3,8,9,14)  --7.  QUARTERROUND ( 2, 7, 8,13)
		qround(wst, 4,5,10,15) --8.  QUARTERROUND ( 3, 4, 9,14)
	end
	-- add working_state to state
	for i = 1, 16 do st[i] = (st[i] + wst[i]) % 0x100000000 end
	-- return st, an array of 16 u32 words used as a keystream
	return st
end --chacha20_block()

-- Functions to pack and unpack strings as little-endian 32-bit integers
local function pack_u32_le(...)
	local args = {...}
	local s = ""
	for _, v in ipairs(args) do
		s = s .. string.char(bit32.band(v, 0xFF), bit32.band(bit32.rshift(v, 8), 0xFF), bit32.band(bit32.rshift(v, 16), 0xFF), bit32.band(bit32.rshift(v, 24), 0xFF))
	end
	return s
end

local function unpack_u32_le(s, i)
	i = i or 1
	local values = {}
	for j = i, #s, 4 do
		local b1, b2, b3, b4 = string.byte(s, j, j + 3)
		local v = b1 + bit32.lshift(b2, 8) + bit32.lshift(b3, 16) + bit32.lshift(b4, 24)
		table.insert(values, v)
	end
	return table.unpack(values)
end

local function chacha20_encrypt_block(key, counter, nonce, pt, ptidx)
	-- encrypt a 64-byte block of plain text.
	-- key: 32 bytes as an array of 8 uint32
	-- counter: an uint32 (must be incremented for each block)
	-- nonce: 12 bytes as an array of 3 uint32
	-- pt: plain text string,
	-- ptidx: index of beginning of block in plain text (origin=1)
	-- if less than 64 bytes are left at position ptidx, it is padded
	--    with null bytes before encryption and result is stripped
	--    accordingly.
	-- return encrypted block as a string  (length <= 16)
	local rbn = #pt - ptidx + 1 -- number of remaining bytes in pt
	if rbn < 64 then
		local tmp = string.sub(pt, ptidx)
		pt = tmp .. string.rep('\0', 64 - rbn) --pad last block
		ptidx = 1
	end
	assert(#pt >= 64)
	local ba = {unpack_u32_le(pt, ptidx)}
	local keystream = chacha20_block(key, counter, nonce)
	for i = 1, 16 do
		ba[i] = bit32.bxor(ba[i], keystream[i])
	end
	local es = pack_u32_le(table.unpack(ba))
	if rbn < 64 then
		es = string.sub(es, 1, rbn)
	end
	return es
end --chacha20_encrypt_block

local chacha20_encrypt = function(key, counter, nonce, pt)
	-- encrypt plain text 'pt', return encrypted text
	-- key: 32 bytes as a string
	-- counter: an uint32 (must be incremented for each block)
	-- nonce: 8 bytes as a string
	-- pt: plain text string,

	-- ensure counter can fit an uint32 --although it's unlikely
	-- that we hit this wall with pure Lua encryption :-)
	assert((counter + #pt // 64 + 1) < 0xffffffff,
		"block counter must fit an uint32")
	assert(#key == 32, "#key must be 32")
	assert(#nonce == 12, "#nonce must be 12")
	local keya = {unpack_u32_le(key)}
	local noncea = {unpack_u32_le(nonce)}
	local t = {} -- used to collect all encrypted blocks
	local ptidx = 1
	while ptidx <= #pt do
		app(t, chacha20_encrypt_block(keya, counter, noncea, pt, ptidx))
		ptidx = ptidx + 64
		counter = counter + 1
	end
	local et = concat(t)
	return et
end --chacha20_encrypt()

local function hchacha20(key, nonce16)
	-- key: string(32)
	-- nonce16: string(16)
	local keya = {unpack_u32_le(key)}
	local noncea = {unpack_u32_le(nonce16)}
	local st = {}  -- chacha working state
	-- initialize state
	st[1], st[2], st[3], st[4] =
		0x61707865, 0x3320646e, 0x79622d32, 0x6b206574
	for i = 1, 8 do st[i+4] = keya[i] end
	for i = 1, 4 do st[i+12] = noncea[i] end
	-- run 20 rounds, ie. 10 iterations of 8 quarter rounds
	for _ = 1, 10 do              --RFC reference:
		qround(st, 1,5,9,13)  --1.  QUARTERROUND ( 0, 4, 8,12)
		qround(st, 2,6,10,14) --2.  QUARTERROUND ( 1, 5, 9,13)
		qround(st, 3,7,11,15) --3.  QUARTERROUND ( 2, 6,10,14)
		qround(st, 4,8,12,16) --4.  QUARTERROUND ( 3, 7,11,15)
		qround(st, 1,6,11,16) --5.  QUARTERROUND ( 0, 5,10,15)
		qround(st, 2,7,12,13) --6.  QUARTERROUND ( 1, 6,11,12)
		qround(st, 3,8,9,14)  --7.  QUARTERROUND ( 2, 7, 8,13)
		qround(st, 4,5,10,15) --8.  QUARTERROUND ( 3, 4, 9,14)
	end	
	local subkey = pack_u32_le(
		st[1], st[2], st[3], st[4],
		st[13], st[14], st[15], st[16] )
	return subkey
end --hchacha20()

local function xchacha20_encrypt(key, counter, nonce, pt)
	assert(#key == 32, "#key must be 32")
	assert(#nonce == 24, "#nonce must be 24")
	local subkey = hchacha20(key, nonce:sub(1, 16))
	local nonce12 = '\0\0\0\0'..nonce:sub(17)
	return chacha20_encrypt(subkey, counter, nonce12, pt)
end --xchacha20_encrypt()

------------------------------------------------------------
return {
	chacha20_encrypt = chacha20_encrypt,
	chacha20_decrypt = chacha20_encrypt, -- xor encryption is symmetric
	encrypt = chacha20_encrypt, --alias
	decrypt = chacha20_encrypt, --alias
	hchacha20 = hchacha20,
	xchacha20_encrypt = xchacha20_encrypt,
	xchacha20_decrypt = xchacha20_encrypt,
	--
	key_size = 32,
	nonce_size = 12,  -- nonce size for chacha20_encrypt
	xnonce_size = 24, -- nonce size for xchacha20_encrypt
}
