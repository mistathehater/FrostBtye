
local HttpService = game:GetService("HttpService")

-- Get environment functions
local getgenv = getgenv or function() return _G end

-- Configuration data
local PlaceName = game.PlaceId
local ScriptVersion = "Universal" -- Default version
local ExecutorName = identifyexecutor and identifyexecutor() or "Unknown"
local HWID = nil

-- Webhook URLs (redacted for security)
local WEBHOOK_START = "https://discord.com/api/webhooks/1325742458226741348/I-4zPn5SdhlEvQMCDEEoaQdGmWwMCIsqUVG33FepVfFJqi_I6QtfOZNkAohY8Fr8mtIL"
local WEBHOOK_SPECIAL = "https://discord.com/api/webhooks/1325742458226741348/I-4zPn5SdhlEvQMCDEEoaQdGmWwMCIsqUVG33FepVfFJqi_I6QtfOZNkAohY8Fr8mtIL"
local WEBHOOK_ERRORS = "https://discord.com/api/webhooks/1325742458226741348/I-4zPn5SdhlEvQMCDEEoaQdGmWwMCIsqUVG33FepVfFJqi_I6QtfOZNkAohY8Fr8mtIL"

-- Formatting functions
local function FormatField(Name, Value)
    return {name = Name, value = Value, inline = true}
end

local function FormatColor(Color)
    return tonumber("0x"..Color:ToHex())
end

-- Hardware ID collection
local function GetHWID()
    if not HWID then
        local Body = HttpService:JSONDecode(
            HttpService:GetAsync("https://httpbin.org/get")
        )
        
        for k,v in pairs(Body.headers) do
            if k:lower():find("fingerprint") then
                HWID = v
                break
            end
        end
    end
    return HWID
end

-- Webhook sender
local function SendWebhook(Info)
    local Fields = Info.Fields or {}
    
    -- Add default tracking fields
    table.insert(Fields, FormatField("Script Version", ScriptVersion))
    table.insert(Fields, FormatField("Executor", ExecutorName))
    table.insert(Fields, FormatField("Identifier", GetHWID()))
    table.insert(Fields, FormatField("Platform", game:GetService("UserInputService"):GetPlatform().Name))
    
    local Data = {
        username = Info.Username,
        avatar_url = "https://cdn.discordapp.com/avatars/1322648594506973235/59c76f027ea559310a3e99da0d8bbb47.png?size=4096",
        embeds = {{
            title = PlaceName,
            color = FormatColor(Info.Color),
            fields = Fields
        }}
    }
    
    HttpService:PostAsync(Info.Url, HttpService:JSONEncode(Data))
end

-- Execution tracking
getgenv().FrostByteStarted = function()
    SendWebhook({
        Username = "Executions v3",
        Url = WEBHOOK_START,
        Color = Color3.fromRGB(0, 201, 99)
    })
    
    -- Special executor tracking
    if getgenv().Role and ScriptVersion ~= "Universal" then
        local Player = game:GetService("Players").LocalPlayer
        SendWebhook({
            Username = "Special Executions v1",
            Url = WEBHOOK_SPECIAL,
            Color = Color3.fromRGB(0, 255, 217),
            Fields = {
                FormatField("Role", getgenv().Role),
                FormatField("Username", Player.Name)
            }
        })
    end
    
    -- Error tracking
    getgenv().HandleConnection = function(Connection, Name)
        Connection:Connect(function(Message, MessageType)
            if Message:find("â") or Message:find("Rayfield") then return end
            
            SendWebhook({
                Username = "Callback Errors v2",
                Url = WEBHOOK_ERRORS,
                Color = Color3.fromRGB(81, 119, 201),
                Fields = {
                    FormatField("Callback Error", "```"..Message.."```")
                }
            })
        end)
    end
    
    HandleConnection(game:GetService("LogService").MessageOut, "AnalyticsMessageOut")
end

-- Anti-tampering
local CallbackBlacklist = {
    "attempt to index nil with 'CurrentValue'",
    "attempt to index boolean with 'CurrentValue'",
    "ServerScriptService.",
    "ServerStorage",
    "not enough memory",
    "invalid argument #1 to 'setfenv' (number expected, got table)"
}

local LoadstringBlacklist = {
    "BLOCKED file path",
    "Error while loading Rayfield",
    "invalid argument #1 to 'setfenv' (number expected, got table)"
}

-- Memory protection
getgenv().FrostByteHandleFunction = function(Callback)
    local Success, Result = pcall(Callback)
    if not Success and Result:find(":") then
        for _, Pattern in pairs(LoadstringBlacklist) do
            if Result:find(Pattern) then return end
        end
        
        SendWebhook({
            Username = "Loadstring Errors v1",
            Url = WEBHOOK_ERRORS,
            Color = Color3.fromRGB(170, 43, 43),
            Fields = {
                FormatField("Loadstring Error", "```"..Result.."```")
            }
        })
    end
end
