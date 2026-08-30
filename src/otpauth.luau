--!strict
--@creator 3velyvnn
--@description Utilities for creating otpauth:// URIs

--[=[
	@class otpauth

	Utilities for creating Key URI Format links for authenticator applications.
]=]

local otpauth = {}

type Options = {
	secret: string,
	account: string,
	issuer: string?,
	algorithm: string?,
	digits: number?,
	period: number?,
}

--[=[
	Percent-encodes a string for use in a URI.

	@param value string -- The string to encode.
	@return string -- The percent-encoded string.
]=]
local function encodeURIComponent(value: string): string
	return (value:gsub("([^%w%-_%.~])", function(character: string): string
		return string.format("%%%02X", string.byte(character))
	end))
end

--[=[
	Creates an otpauth:// URI for use with authenticator applications.

	@param options Options -- The TOTP configuration.
	@return string -- The generated otpauth:// URI.
]=]
function otpauth.create(options: Options): string
	assert(options.secret ~= "", "secret must not be empty")
	assert(options.account ~= "", "account must not be empty")

	local issuer = options.issuer
	local algorithm = options.algorithm or "SHA1"
	local digits = options.digits or 6
	local period = options.period or 30

	assert(
		algorithm == "SHA1"
			or algorithm == "SHA256"
			or algorithm == "SHA512",
		"algorithm must be SHA1, SHA256, or SHA512"
	)

	assert(
		digits == 6 or digits == 8,
		"digits must be 6 or 8"
	)

	assert(period > 0, "period must be greater than 0")

	local label = encodeURIComponent(
		if issuer
			then issuer .. ":" .. options.account
			else options.account
	)

	local query = {
		"secret=" .. encodeURIComponent(options.secret),
	}

	if issuer then
		table.insert(query, "issuer=" .. encodeURIComponent(issuer))
	end

	if algorithm ~= "SHA1" then
		table.insert(query, "algorithm=" .. algorithm)
	end

	if digits ~= 6 then
		table.insert(query, "digits=" .. tostring(digits))
	end

	if period ~= 30 then
		table.insert(query, "period=" .. tostring(period))
	end

	return "otpauth://totp/" .. label .. "?" .. table.concat(query, "&")
end

return otpauth