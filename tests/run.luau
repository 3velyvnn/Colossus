--!strict

local tests = {
	{ name = "Base32", path = "./base32" },
	{ name = "HOTP", path = "./hotp" },
	{ name = "TOTP", path = "./totp" },
}

local passed = 0

local function green(text: string): string
	return "\27[32m" .. text .. "\27[0m"
end

local function red(text: string): string
	return "\27[31m" .. text .. "\27[0m"
end

print("Colossus Tests")
print("")

for _, test in tests do
	local success, result = pcall(require, test.path)

	if success and result == true then
		print(`  {test.name}   {green("✓ PASS")}`)
		passed += 1
	else
		print(`  {test.name}   {red("✗ FAIL")}`)
	end
end

print("")
print(`{passed}/{#tests} tests passed`)