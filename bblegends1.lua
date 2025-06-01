local ORIGINAL_SIG1= "https://pastefy.app/NJ3KPS5z/raw"
local function generateBypassScript()
    local id = game:GetService("RbxAnalyticsService"):GetClientId()
    return "return { [1] = '" .. id .. "' }"
end

local function rewrite(url)
    if type(url) == "string" and url:find(ORIGINAL_SIG1, 1, true) then
        return generateBypassScript(), true
    end
    return url, false
end

-- HttpGet hook
do
    local mt = getrawmetatable(game) 
    setreadonly(mt, false)

    local origIndex = mt.__index
    local origNamecall = mt.__namecall

    mt.__index = function(self, key)
        if self == game and (key == "HttpGet" or key == "HttpGetAsync") then
            return function(_, url, ...)
                local replacement, fake = rewrite(url)
                if fake then return replacement end
                return origIndex(self, key)(self, url, ...)
            end
        end
        return origIndex(self, key)
    end

    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if self == game and (method == "HttpGet" or method == "HttpGetAsync") then
            local args = {...}
            local replacement, fake = rewrite(args[1])
            if fake then return replacement end
            return origNamecall(self, unpack(args))
        end
        return origNamecall(self, ...)
    end

    setreadonly(mt, true)
end

loadstring(game:httpget("https://raw.githubusercontent.com/lilsketty/sketty-helpers/refs/heads/main/bblegendssigma"))()
