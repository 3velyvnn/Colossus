--!strict

local totp = require("../src/totp")

local secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"

local tests = {
	{ timestamp = 59, expected = "94287082" },
	{ timestamp = 1111111109, expected = "07081804" },
	{ timestamp = 1111111111, expected = "14050471" },
	{ timestamp = 1234567890, expected = "89005924" },
	{ timestamp = 2000000000, expected = "69279037" },
	{ timestamp = 20000000000, expected = "65353130" },
}

for _, test in tests do
	local actual = totp.generate(secret, test.timestamp, 30, 8)
	local formatted = string.format("%08d", actual)

	assert(
		formatted == test.expected,
		`Timestamp {test.timestamp}: expected {test.expected}, got {formatted}`
	)

	print(`Timestamp {test.timestamp}: {formatted} ✓`)
end

return true