local ORIGINAL_SIG1 = "https://pastefy.app/NJ3KPS5z/raw"

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
do
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local origIndex = mt.__index
    local origNamecall = mt.__namecall

    mt.__index = function(self, key)
        if self == game and (key == "HttpGet" or key == "HttpGetAsync") then
            return function(_, url, ...)
                local replacement, fake = rewrite(url)
                if fake then
                    return replacement
                end
                return origIndex(self, key)(self, url, ...)
            end
        end
        return origIndex(self, key)
    end

    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if self == game and (method == "HttpGet" or method == "HttpGetAsync") then
            local args = { ... }
            local replacement, fake = rewrite(args[1])
            if fake then
                return replacement
            end
            return origNamecall(self, unpack(args))
        end
        return origNamecall(self, ...)
    end

    setreadonly(mt, true)
end

local function wrapHttpFunction(tbl, funcName)
    if tbl and rawget(tbl, funcName) then
        local origFunc = tbl[funcName]
        tbl[funcName] = function(opts)
            local url = opts and (opts.Url or opts.url or opts[1])
            if type(url) == "string" then
                local replacement, fake = rewrite(url)
                if fake then
                    return {
                        StatusCode = 200,
                        Body = replacement,
                        Success = true
                    }
                end
            end
            return origFunc(opts)
        end
    end
end
wrapHttpFunction(syn, "request")
wrapHttpFunction(http, "request")
if rawget(_G, "http_request") then
    local orig_http_request = http_request
    http_request = function(opts)
        local url = opts and (opts.Url or opts.url or opts[1])
        if type(url) == "string" then
            local replacement, fake = rewrite(url)
            if fake then
                return {
                    StatusCode = 200,
                    Body = replacement,
                    Success = true
                }
            end
        end
        return orig_http_request(opts)
    end
end
if rawget(_G, "request") then
    local orig_request = request
    request = function(opts)
        local url = opts and (opts.Url or opts.url or opts[1])
        if type(url) == "string" then
            local replacement, fake = rewrite(url)
            if fake then
                return {
                    StatusCode = 200,
                    Body = replacement,
                    Success = true
                }
            end
        end
        return orig_request(opts)
    end
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/lilsketty/sketty-helpers/refs/heads/main/bblegendssigma"))()
