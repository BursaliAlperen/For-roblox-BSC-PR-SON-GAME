-- AFTERFALL: THE LAST SHIFT
-- SERVER BOOTSTRAP
-- Put in ServerScriptService as a normal Script.
-- Requires: Game Settings > Security > Allow HTTP Requests.
-- This script downloads the live server package from your GitHub repo.

local HttpService = game:GetService("HttpService")

local PACKAGE_URL = "https://raw.githubusercontent.com/BursaliAlperen/For-roblox-BSC-PR-SON-GAME/main/Roblox/Afterfall/ServerPackage.lua"

local function fetch(url)
	local ok, body = pcall(function()
		return HttpService:GetAsync(url, true)
	end)
	if not ok then
		error("[AFTERFALL] GitHub download failed: " .. tostring(body))
	end
	if type(body) ~= "string" or #body < 50 then
		error("[AFTERFALL] GitHub returned an invalid package.")
	end
	return body
end

local source = fetch(PACKAGE_URL)

if not loadstring then
	error("[AFTERFALL] loadstring is disabled. Enable ServerScriptService.LoadStringEnabled first.")
end

local chunk, compileError = loadstring(source, "@Afterfall/ServerPackage")
if not chunk then
	error("[AFTERFALL] Package compile error: " .. tostring(compileError))
end

local ok, runtimeError = pcall(chunk)
if not ok then
	error("[AFTERFALL] Package runtime error: " .. tostring(runtimeError))
end

print("[AFTERFALL] GitHub server package loaded.")
