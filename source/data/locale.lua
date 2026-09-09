if Locale ~= nil then return Locale end

local love = require "love"
-- require "source.data.json"
Locale = {
    fallback = "en_US",
    current = "en_US",

    languages = {},
    ilanguages = {},
    mappings = {}
}

function Locale.loadMappings()
    for k, _ in pairs(Locale.mappings) do Locale.mappings[k] = nil end
    local translationFiles = love.filesystem.getDirectoryItems("translations")

    for _, transfile in ipairs(translationFiles) do
        local lang = string.gsub(transfile, ".xln", "")
        local result = {}

        Locale.languages[#Locale.languages + 1] = lang
        for line in love.filesystem.lines("translations/" .. transfile) do
            if (string.sub(line, 1, 2) ~= '//') then
                local lines = string.split(line, " \\: ")
                if #lines <= 2 then
                    result[lines[1]] = lines[2] or ''
                end
            end
        end

        -- local jsonencode = JSONEncoder.encode(result, '  ')
        -- love.filesystem.write('' .. lang .. '.xjson', jsonencode)
        Locale.mappings[lang] = result
    end

    Locale.ilanguages = invert(Locale.languages)
end

-- We should make sure to clear this when switching languages
-- or when it starts to cache too much
local localizeCache = {}
function Locale.localizeText(text)
    if localizeCache[text] then return localizeCache[text] end

    for key, string in pairs(Locale.mappings[Locale.current]) do
        text = string.gsub(text, key, string)
    end

    for key, string in pairs(Locale.mappings[Locale.fallback]) do
        text = string.gsub(text, key, string)
    end

    localizeCache[text] = text
    return text
end

function Locale.changeLanguage(language)
    if language ~= Locale.current then
        Locale.current = language
        localizeCache = {}
        reloadFonts()
        return true
    end
    return false
end

function Locale.convertNumberToSitelenPona(number)
    -- not dealing with floats
    number = math.floor(number)

    if number == 0 then
        return "󱤂"
    elseif number < 0 then
        -- unofficial system for negative numbers
        local name = Locale.convertNumberToSitelenPona(-number)
        return name .. "󱥶"
    end

    local function below100(n)
        if n == 0 then return "" end

        local mute, below20 = math.floor(n / 20), math.fmod(number, 20)
        local luka, below5 = math.floor(below20 / 5), math.fmod(below20, 5)
        local tu, below2 = math.floor(below5 / 2), math.fmod(below5, 2)
        local wan = below2 == 1 and 1 or 0

        return string.rep("󱤼", mute)
            .. string.rep("󱤭", luka)
            .. string.rep("󱥮", tu)
            .. string.rep("󱥳", wan)
    end

    local ale, rest = math.floor(number / 100), math.fmod(number, 100)

    if ale == 0 then
        return below100(rest)
    else
        return Locale.convertNumberToSitelenPona(ale) .. "󱤄" .. below100(rest)
    end
end

function Locale.levelNumberSitelenPona(s)
    local str = s
    if string.sub(s, 1, 1) == "C" then
        str = string.sub(s, 2)
        str = "-" .. str
    end
    local num = tonumber(str)
    if num == nil then
        return s
    end
    return Locale.convertNumberToSitelenPona(num)
end

return Locale
