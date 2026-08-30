--!strict
local totp = require("../src/totp")
local otpauth = require("../src/otpauth")
local task = require("@lute/task")
local io = require("@lute/io")

local secret = totp.generateSecret()

local uri = otpauth.create({
	secret = secret,
	account = "user@example.com",
	issuer = "Colossus",
})

print("Secret: " .. secret)
print("URI: " .. uri)

while true do
	local now = os.time()
	local elapsed = now % 30
	local remaining = 30 - elapsed

	local code = totp.generate(secret, now, 30, 6)

	io.write(
        "\rTOTP: " .. string.format("%06d", code)
        .. " [" .. string.rep("█", math.floor((remaining / 30) * 30))
        .. string.rep("░", math.ceil((elapsed / 30) * 30)) .. "] "
        .. remaining .. "s   "
    )

	task.wait(1)
end