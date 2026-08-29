--!strict
-- HOTP tests based on RFC 4226 test vectors

local totp = require("../src/totp")

local secret = buffer.fromstring("12345678901234567890")

local expected = {
	"755224",
	"287082",
	"359152",
	"969429",
	"338314",
	"254676",
	"287922",
	"162583",
	"399871",
	"520489",
}

for counter, expectedCode in ipairs(expected) do
	local actual = totp.hotp(secret, counter - 1)

	assert(
		string.format("%06d", actual) == expectedCode,
		`Counter {counter - 1}: expected {expectedCode}, got {actual}`
	)

	print(`Counter {counter - 1}: {expectedCode} ✓`)
end

return true