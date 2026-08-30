--!strict
--@creator 3velyvnn
--@description TOTP implementation using HMAC-SHA1

--[=[
	@class totp

	Utilities for generating Time-based One-Time Passwords.
]=]

local crypt = require("./crypt")
local base32 = require("./base32")

local totp = {}

--[=[
	Generates an HOTP code.

	@param secret buffer -- The secret key.
	@param counter number -- The HOTP counter.
	@param digits number? -- The number of digits for the HOTP code. Defaults to 6.
	@return number -- The generated HOTP code.
]=]
function totp.hotp(secret: buffer, counter: number, digits: number?): number
	local counterBuffer = buffer.create(8)

	for i = 0, 7 do
		buffer.writeu8(counterBuffer, 7 - i, bit32.band(bit32.rshift(counter, i * 8), 0xFF))
	end

	local hmacResult = crypt.hmacSha1(secret, counterBuffer)
	local offset = bit32.band(buffer.readu8(hmacResult, buffer.len(hmacResult) - 1), 0x0F)

	local truncatedHash = bit32.byteswap(buffer.readu32(hmacResult, offset))

	local digitCount = digits or 6
	assert(digitCount >= 1 and digitCount <= 9, "digits must be between 1 and 9")

	return bit32.band(truncatedHash, 0x7FFFFFFF) % (10 ^ digitCount)
end

--[=[
	Verifies an HOTP code against a secret and counter.

	@param secret buffer -- The secret key.
	@param counter number -- The HOTP counter.
	@param code number -- The HOTP code to verify.
	@param digits number? -- The number of digits for the HOTP code. Defaults to 6.
	@return boolean -- Whether the supplied code matches the generated HOTP code.
]=]
function totp.verifyHOTP(secret: buffer, counter: number, code: number, digits: number?): boolean
	return totp.hotp(secret, counter, digits) == code
end

--[=[
	Generates a cryptographically random TOTP secret.

	@return string -- A Base32-encoded TOTP secret.
]=]
function totp.generateSecret(): string
	local secret = crypt.generateKey()
	return base32.encode(secret)
end

--[=[
	Generates a TOTP code based on the current time.

	@param secret string -- The Base32-encoded TOTP secret.
	@param timeStamp number? -- The current timestamp in seconds. Defaults to the current time.
	@param timeStep number? -- The time step in seconds. Defaults to 30.
	@param digits number? -- The number of digits for the TOTP code. Defaults to 6.
	@return number -- The generated TOTP code.
]=]
function totp.generate(secret: string, timeStamp: number?, timeStep: number?, digits: number?): number
	local decodedSecret = base32.decode(secret)
	local currentTime = timeStamp or os.time()
	local step = timeStep or 30

	assert(step > 0, "timeStep must be greater than 0")

	local counter = math.floor(currentTime / step)
	return totp.hotp(decodedSecret, counter, digits)
end

--[=[
	Verifies a TOTP code against a secret and timestamp.

	@param secret string -- The Base32-encoded TOTP secret.
	@param code number -- The TOTP code to verify.
	@param timeStamp number? -- The timestamp in seconds. Defaults to the current time.
	@param timeStep number? -- The time step in seconds. Defaults to 30.
	@param digits number? -- The number of digits for the TOTP code. Defaults to 6.
	@return boolean -- Whether the supplied code matches the generated TOTP code.
]=]
function totp.verifyTOTP(secret: string, code: number, timeStamp: number?, timeStep: number?, digits: number?): boolean
	return totp.generate(secret, timeStamp, timeStep, digits) == code
end

return totp
