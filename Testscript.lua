--[[
    loader.lua
    Usage:
        script_key = "YOUR_KEY_HERE"
        loadstring(game:HttpGet("YOUR_LOADER_RAW_URL"))()
]]

-- ===================== CONFIG =====================
-- MUST be a PUBLIC https URL. 127.0.0.1 will NEVER work from Roblox.
local API_URL = "http://127.0.0.1:8787/validate"

-- Your main script
local SCRIPT_URL = "https://raw.githubusercontent.com/wasabi00ramen-coder/Test1234567/refs/heads/main/Testscript.lua"

local RECHECK_INTERVAL = 60
-- ==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
        })
    end)
end

local function httpRequest(opts)
    local req = (syn and syn.request)
        or http_request
        or (http and http.request)
        or request
    if not req then
        error("[Auth] This executor has no HTTP request function")
    end
    return req(opts)
end

local function getKey()
    local key = rawget(_G, "script_key")
    if type(key) ~= "string" or #key < 3 then
        key = typeof(script_key) == "string" and script_key or nil
    end
    if type(key) ~= "string" or #key < 3 then
        if typeof(input) == "function" then
            key = input("Enter license key:")
        end
    end
    if type(key) ~= "string" then
        return nil
    end
    return key:gsub("%s+", "")
end

local function validate(key)
    print("[Auth] Sending key to API...")
    print("[Auth] API:", API_URL)

    local body = HttpService:JSONEncode({
        key = key,
        device_fingerprint = tostring(LocalPlayer.UserId),
    })

    local ok, res = pcall(function()
        return httpRequest({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = body,
        })
    end)

    if not ok then
        print("[Auth] Request failed:", res)
        return false, "network", tostring(res)
    end

    if not res then
        return false, "network", "empty response"
    end

    local status = res.StatusCode or res.Status or res.status_code or 0
    local bodyStr = res.Body or res.body or res.Payload or ""
    print("[Auth] Status:", status)
    print("[Auth] Body:", bodyStr)

    if status ~= 200 then
        return false, "network", "HTTP " .. tostring(status)
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(bodyStr)
    end)

    if not decodeOk or type(data) ~= "table" then
        return false, "network", "bad JSON"
    end

    if data.valid == true then
        return true, nil, nil
    end

    if data.reason == "sharing" then
        return false, "sharing", data.message or "sharing"
    end

    return false, "invalid", "valid=false"
end

local function fail(reason, detail)
    local msg = "Invalid or revoked key."
    if reason == "expired" or reason == "invalid" then
        msg = "Your key has expired!"
    elseif reason == "sharing" then
        msg = "Key revoked: sharing detected."
    elseif reason == "network" then
        msg = "Could not reach license server."
    elseif reason == "nokey" then
        msg = "No key provided. Set script_key first."
    elseif reason == "config" then
        msg = "API URL not configured."
    end

    print("[Auth] FAILED:", msg, detail or "")
    notify("Access denied", msg, 6)
    task.wait(1.5)
    LocalPlayer:Kick(msg)
    while true do task.wait(9e9) end
end

-- ---------- boot ----------
print("========== KEY AUTH ==========")

if API_URL:find("YOUR_PUBLIC_API_URL") or API_URL:find("127.0.0.1") or API_URL:find("localhost") then
    fail("config", "API_URL is still local/placeholder. Deploy the API to public HTTPS first.")
end

local key = getKey()
if not key or #key < 3 then
    fail("nokey")
end

print("[Auth] Key:", key)
print("[Auth] UserId:", LocalPlayer.UserId)

local ok, reason, detail = validate(key)
if not ok then
    fail(reason or "invalid", detail)
end

print("[Auth] Key accepted.")
notify("Access granted", "Key accepted. Loading script...", 4)

-- re-check loop
task.spawn(function()
    while true do
        task.wait(RECHECK_INTERVAL)
        local stillOk, why = validate(key)
        if not stillOk then
            fail(why == "sharing" and "sharing" or "expired")
        end
    end
end)

-- load main script
print("[Auth] Fetching script...")
print("[Auth] URL:", SCRIPT_URL)

local src
local fetchOk, fetchErr = pcall(function()
    src = game:HttpGet(SCRIPT_URL)
end)

if not fetchOk or not src or #src < 5 then
    print("[Auth] HttpGet failed:", fetchErr)
    notify("Error", "Failed to load main script", 5)
    error("[Auth] Failed to fetch main script: " .. tostring(fetchErr))
end

print("[Auth] Script fetched (" .. #src .. " bytes). Running...")
local runOk, runErr = pcall(function()
    loadstring(src)()
end)

if not runOk then
    print("[Auth] Script error:", runErr)
    notify("Script error", tostring(runErr), 6)
    error("[Auth] " .. tostring(runErr))
end

print("[Auth] Done.")
