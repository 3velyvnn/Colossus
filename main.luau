--!strict

--[[
local totp = require("./src/totp")

local secret = buffer.fromstring("12345678901234567890")

local code = totp.hotp(secret, 0)

print("Generated:", code)
print("Valid:", totp.verifyHOTP(secret, 0, code))
print("Invalid:", totp.verifyHOTP(secret, 0, 123456))
]]--

local totp = require("./src/totp")
local task = require("@lute/task")
local io = require("@lute/io")

const secret = totp.generateSecret()
const timeStep = 30
const barWidth = 30

while true do
	local now = os.time()

    -- The TOTP window is synchronized to Unix time.
	local elapsed = now % timeStep
	local remaining = timeStep - elapsed

	local filled = math.floor((remaining / timeStep) * barWidth)
	local empty = barWidth - filled

	local bar = string.rep("█", filled) .. string.rep("░", empty)

	local code = totp.generate(secret, now, timeStep)

	io.write(
		"\rTOTP: " .. string.format("%06d", code)
		.. " [" .. bar .. "] "
		.. remaining .. "s   "
	)

	task.wait(0.1)
end