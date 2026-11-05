--[[
    KeySystem_Executor.lua
    Put this at the TOP of your executor script.

    Validates against your Python API.
    Binds key to Roblox UserId (one-time).
    Re-checks while in-game → kicks if expired/revoked.
]]

-- ===================== CONFIG =====================
local CONFIG = {
    -- Your PUBLIC HTTPS API (must be online, not 127.0.0.1)
    API_URL = "https://YOUR_PUBLIC_API_URL/validate",

    -- How often to re-validate while in game (seconds)
    RECHECK_INTERVAL = 60,

    -- Set true to remember the key in a workspace file
    SAVE_KEY = true,
    KEY_FILE = "license_key.txt",

    -- Messages
    MSG_EXPIRED = "Your key has expired!",
    MSG_INVALID = "Invalid or revoked key.",
    MSG_SHARING = "Key revoked: sharing detected.",
    MSG_NETWORK = "Could not reach license server.",
    MSG_INPUT   = "Enter your license key:",
}

-- ==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ---------- HTTP (works on most executors) ----------
local function httpRequest(opts)
    local req = (syn and syn.request)
        or http_request
        or (http and http.request)
        or request

    if not req then
        error("[KeySystem] No HTTP request function found on this executor")
    end
    return req(opts)
end

-- ---------- File helpers (optional key save) ----------
local function readSavedKey()
    if not CONFIG.SAVE_KEY then return nil end
    if isfile and isfile(CONFIG.KEY_FILE) then
        local ok, data = pcall(readfile, CONFIG.KEY_FILE)
        if ok and data and #data > 0 then
            return data:gsub("%s+", "")
        end
    end
    return nil
end

local function saveKey(key)
    if not CONFIG.SAVE_KEY then return end
    if writefile then
        pcall(writefile, CONFIG.KEY_FILE, key)
    end
end

-- ---------- Validate against your API ----------
local function validate(key)
    local body = HttpService:JSONEncode({
        key = key,
        device_fingerprint = tostring(LocalPlayer.UserId),
    })

    local ok, res = pcall(function()
        return httpRequest({
            Url = CONFIG.API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
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

    local bodyStr = res.Body or res.body or res.Payload or ""
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

-- ---------- Kick / stop ----------
local function fail(reason)
    local msg = CONFIG.MSG_INVALID
    if reason == "expired" or reason == "invalid" then
        msg = CONFIG.MSG_EXPIRED
    elseif reason == "sharing" then
        msg = CONFIG.MSG_SHARING
    elseif reason == "network" then
        msg = CONFIG.MSG_NETWORK
    end

    LocalPlayer:Kick(msg)
    -- hard stop in case kick is delayed
    while true do task.wait(9e9) end
end

-- ---------- Get key from user ----------
local function getKey()
    local saved = readSavedKey()
    if saved and #saved > 5 then
        return saved
    end

    -- Executor input
    local key
    if syn and syn.request then
        -- most modern executors have this
        key = input and input(CONFIG.MSG_INPUT) or nil
    end
    if not key and typeof(getfenv().input) == "function" then
        key = getfenv().input(CONFIG.MSG_INPUT)
    end
    if not key then
        -- fallback: print + wait for clipboard-style (user pastes in console if needed)
        print("[KeySystem] " .. CONFIG.MSG_INPUT)
        if setclipboard then
            print("[KeySystem] (paste key into the input box if your executor supports it)")
        end
        key = input and input(CONFIG.MSG_INPUT) or ""
    end

    if type(key) ~= "string" then
        key = ""
    end
    return key:gsub("%s+", "")
end

-- ---------- Main auth ----------
local function authenticate()
    local key = getKey()
    if not key or #key < 3 then
        fail("invalid")
    end

    print("[KeySystem] Checking key...")
    local ok, reason = validate(key)

    if not ok then
        fail(reason or "invalid")
    end

    saveKey(key)
    print("[KeySystem] Key accepted.")

    -- Background re-check (expiration / revoke / sharing while in game)
    task.spawn(function()
        while true do
            task.wait(CONFIG.RECHECK_INTERVAL)
            local stillOk, why = validate(key)
            if not stillOk then
                fail(why == "sharing" and "sharing" or "expired")
            end
        end
    end)

    return true
end

-- Run auth before anything else
authenticate()

-- ============================================================
-- YOUR SCRIPT GOES BELOW THIS LINE
-- (ESP, aimbot, etc. only runs if key is valid)
-- ============================================================

print("[KeySystem] Authenticated — loading script...")
