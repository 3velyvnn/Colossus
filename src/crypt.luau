--!strict
local crypto = require("@lute/crypto")

const BLOCK_SIZE = 64

local function xorByte(a: number, b: number): number
	return bit32.bxor(a, b)
end

--[=[
    Computes the HMAC-SHA1 of a message using a given key.

    @param key The secret key as a buffer.
    @param message The message to be hashed as a buffer.
    @return The HMAC-SHA1 result as a buffer.
]=]

local crypt = {}
function crypt.hmacSha1(key: buffer, message: buffer): buffer
	if buffer.len(key) > BLOCK_SIZE then
		key = crypto.digest(crypto.hash.sha1, key)
	end

	local paddedKey = buffer.create(BLOCK_SIZE)
	buffer.copy(paddedKey, 0, key, 0, buffer.len(key))

	local ipad = buffer.create(BLOCK_SIZE)
	local opad = buffer.create(BLOCK_SIZE)

	for i = 0, BLOCK_SIZE - 1 do
		local keyByte = buffer.readu8(paddedKey, i)

		buffer.writeu8(ipad, i, xorByte(keyByte, 0x36))
		buffer.writeu8(opad, i, xorByte(keyByte, 0x5C))
	end

	-- inner = SHA1(ipad || message)
	local inner = buffer.create(BLOCK_SIZE + buffer.len(message))
	buffer.copy(inner, 0, ipad)
	buffer.copy(inner, BLOCK_SIZE, message)

	local innerHash = crypto.digest(crypto.hash.sha1, inner)

	-- outer = SHA1(opad || innerHash)
	local outer = buffer.create(BLOCK_SIZE + buffer.len(innerHash))
	buffer.copy(outer, 0, opad)
	buffer.copy(outer, BLOCK_SIZE, innerHash)

	return crypto.digest(crypto.hash.sha1, outer)
end

--[=[
	Generates a cryptographically random 32-byte key.

	@return A random 32-byte buffer.
]=]

function crypt.generateKey(): buffer
	return crypto.secretbox.keygen()
end

return crypt