--!strict

local totp = require("../src/totp")
local crypt = require("../src/crypt")
local base32 = require("../src/base32")
local io = require("@lute/io")

const secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
const decoded = base32.decode(secret)

print("Decoded:", buffer.tostring(decoded))
print("Length:", buffer.len(decoded))
print("HOTP 0:", string.format("%06d", totp.hotp(decoded, 0)))
print("HOTP 1:", string.format("%06d", totp.hotp(decoded, 1)))
print("TOTP 59:", string.format("%06d", totp.generate(secret, 59, 30, 6)))

local counterBuffer = buffer.create(8)

for i = 0, 7 do
	buffer.writeu8(
		counterBuffer,
		7 - i,
		bit32.band(bit32.rshift(1, i * 8), 0xFF)
	)
end

local message = buffer.create(8)

for i = 0, 7 do
	buffer.writeu8(
		message,
		7 - i,
		bit32.band(bit32.rshift(1, i * 8), 0xFF)
	)
end

local digest = crypt.hmacSha1(decoded, message)

print("Key:")
for i = 0, buffer.len(decoded) - 1 do
	io.write(string.format("%02x", buffer.readu8(decoded, i)))
end
print()

print("Message:")
for i = 0, buffer.len(message) - 1 do
	io.write(string.format("%02x", buffer.readu8(message, i)))
end
print()

print("HMAC:")
for i = 0, buffer.len(digest) - 1 do
	io.write(string.format("%02x", buffer.readu8(digest, i)))
end
print()