--[[
    loader.lua
    Host this file (GitHub raw / your site) and load it like:

    script_key = "YOUR_KEY_HERE"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wasabi00ramen-coder/Test1234567/main/loader.lua"))()
]]

-- ===================== CONFIG =====================
local API_URL = "http://127.0.0.1:8787/validate"  -- your public HTTPS /validate endpoint
local SCRIPT_URL = "https://raw.githubusercontent.com/wasabi00ramen-coder/prestige/refs/heads/main/prestige.lua"
local RECHECK_INTERVAL = 60
-- ==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function httpRequest(opts)
    local req = (syn and syn.request) or http_request or (http and http.request) or request
    if not req then
        error("[Auth] No HTTP request function on this executor")
    end
    return req(opts)
end

local function validate(key)
    local body = HttpService:JSONEncode({
        key = key,
        device_fingerprint = tostring(LocalPlayer.UserId),
    })

    local ok, res = pcall(function()
        return httpRequest({
            Url = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)

    if not ok or not res then
        return false, "network"
    end

    local status = res.StatusCode or res.Status or res.status_code
    if status ~= 200 then
        return false, "network"
    end

    local bodyStr = res.Body or res.body or ""
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(bodyStr)
    end)

    if not decodeOk or type(data) ~= "table" then
        return false, "network"
    end

    if data.valid == true then
        return true, nil
    end
    if data.reason == "sharing" then
        return false, "sharing"
    end
    return false, "invalid"
end

local function fail(reason)
    local msg = "Invalid or revoked key."
    if reason == "expired" or reason == "invalid" then
        msg = "Your key has expired!"
    elseif reason == "sharing" then
        msg = "Key revoked: sharing detected."
    elseif reason == "network" then
        msg = "Could not reach license server."
    elseif reason == "nokey" then
        msg = "No key provided. Set script_key before loading."
    end
    LocalPlayer:Kick(msg)
    while true do task.wait(9e9) end
end

-- Require script_key
local key = rawget(getfenv() or _G, "script_key") or rawget(_G, "script_key")
if type(key) ~= "string" or #key < 3 then
    -- also check the global from loadstring env
    key = script_key
end
if type(key) ~= "string" or #key < 3 then
    fail("nokey")
end
key = key:gsub("%s+", "")

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 4,
        })
    end)
end

print("[Auth] Checking key...")
local ok, reason = validate(key)
if not ok then
    fail(reason or "invalid")
end
print("[Auth] Key accepted.")
notify("Access granted", "Key accepted. Loading script...")

-- Background re-check
task.spawn(function()
    while true do
        task.wait(RECHECK_INTERVAL)
        local stillOk, why = validate(key)
        if not stillOk then
            fail(why == "sharing" and "sharing" or "expired")
        end
    end
end)

-- Load the real script
local scriptSrc
local fetchOk, fetchErr = pcall(function()
    scriptSrc = game:HttpGet(SCRIPT_URL)
end)
if not fetchOk or not scriptSrc or #scriptSrc < 10 then
    error("[Auth] Failed to fetch script: " .. tostring(fetchErr))
end

local runOk, runErr = pcall(function()
    loadstring(scriptSrc)()
end)
if not runOk then
    error("[Auth] Script error: " .. tostring(runErr))
end
