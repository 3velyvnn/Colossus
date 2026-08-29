--!strict
--@creator 3velyvnn
--@description TOTP implementation using HMAC-SHA1

local crypt = require("./crypt")
local base32 = require("./base32")

local totp = {}

--[=[
	Generates an HOTP code.

	@param secret The secret key as a buffer.
	@param counter The HOTP counter.
	@param digits The number of digits for the HOTP code. Defaults to 6.
	@return The generated HOTP code.
]=]

function totp.hotp(secret: buffer, counter: number, digits: number?): number
	local counterBuffer = buffer.create(8)

	for i = 0, 7 do
		buffer.writeu8(
			counterBuffer,
			7 - i,
			bit32.band(bit32.rshift(counter, i * 8), 0xFF)
		)
	end

	local hmacResult = crypt.hmacSha1(secret, counterBuffer)

	local offset = bit32.band(
		buffer.readu8(hmacResult, buffer.len(hmacResult) - 1),
		0x0F
	)

	local truncatedHash =
		bit32.lshift(buffer.readu8(hmacResult, offset), 24)
		+ bit32.lshift(buffer.readu8(hmacResult, offset + 1), 16)
		+ bit32.lshift(buffer.readu8(hmacResult, offset + 2), 8)
		+ buffer.readu8(hmacResult, offset + 3)

	local digitCount = digits or 6

	assert(
		digitCount >= 1 and digitCount <= 9,
		"digits must be between 1 and 9"
	)

	return bit32.band(truncatedHash, 0x7FFFFFFF) % (10 ^ digitCount)
end

--[=[
	Generates a cryptographically random TOTP secret.

	@return A Base32-encoded TOTP secret.
]=]
function totp.generateSecret(): string
	local secret = crypt.generateKey()

	return base32.encode(secret)
end

--[=[
	Generates a TOTP code based on the current time.

	@param secret The Base32-encoded TOTP secret.
	@param timeStamp The current timestamp in seconds. Defaults to the current time.
	@param timeStep The time step in seconds. Defaults to 30.
	@param digits The number of digits for the TOTP code. Defaults to 6.
	
	@return The generated TOTP code.
]=]

function totp.generate(secret: string, timeStamp: number?, timeStep: number?, digits: number?): number
	local decodedSecret = base32.decode(secret)

	local currentTime = timeStamp or os.time()
	local step = timeStep or 30

	assert(
		step > 0,
		"timeStep must be greater than 0"
	)

	local counter = math.floor(currentTime / step)

	return totp.hotp(decodedSecret, counter, digits)
end

return totp