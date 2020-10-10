PlayedAll = {}
PlayedAll.name = "PlayedAll"
PlayedAll.version = "1.1"

local savedVariables
local charName = GetUnitName("player")

local function formatCharNames(charNames)
    local allNames = ''
    local index, name = next(charNames, nil)
    while index do
        local nextIndex, nextName = next(charNames, index)
        local isFirst = string.len(allNames) == 0
        if not isFirst then
            allNames = allNames .. (nextIndex and ', ' or GetString(SI_PLAYEDALL_AND))
        end
        allNames = allNames .. name
        index, name = nextIndex, nextName
    end
    return allNames
end

local function displayTotalPlayedTime(charNames, time)
    local playedTime = ZO_FormatTime(time, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
    CHAT_SYSTEM:AddMessage(zo_strformat(SI_CHAT_MESSAGE_PLAYED_TIME, formatCharNames(charNames), playedTime))
end

local function getSavedVariables()
    local username = GetDisplayName()
    local playedAllVars = _G['PlayedAllVars']
    if not playedAllVars then
        playedAllVars = {}
        _G['PlayedAllVars'] = playedAllVars
    end
    local savedVariables = PlayedAllVars[username]
    if not savedVariables then
        savedVariables = {}
        PlayedAllVars[username] = savedVariables
    end
    return savedVariables
end

local function updatePlayedTime()
    savedVariables[charName] = GetSecondsPlayed()
end

local function setupHooks()
    ZO_PreHook("ReloadUI", updatePlayedTime)

    ZO_PreHook("Logout", updatePlayedTime)

    ZO_PreHook("SetCVar", updatePlayedTime)

    ZO_PreHook("Quit", updatePlayedTime)
end

local function initialize()
    local playedCommand = GetString(SI_SLASH_PLAYED_TIME)
    local normalPlayed = SLASH_COMMANDS[playedCommand]

    savedVariables = getSavedVariables()
    updatePlayedTime()

    SLASH_COMMANDS[playedCommand] = function (args)
        formattedArgs = string.lower(args)

        updatePlayedTime()
        if formattedArgs ~= 'all' then
            normalPlayed(formattedArgs)
            return
        end

        local charNames = {}
        local totalPlayed = 0

        for name, time in pairs(savedVariables) do
            table.insert(charNames, name)
            totalPlayed = totalPlayed + time
        end

        displayTotalPlayedTime(charNames, totalPlayed)
    end

    setupHooks()

    EVENT_MANAGER:UnregisterForEvent(PlayedAll.name, EVENT_ADD_ON_LOADED)
end

local function onAddOnLoaded(_, addonName)
    if addonName ~= PlayedAll.name then return end
    initialize()
end

-- register addon load
EVENT_MANAGER:RegisterForEvent(PlayedAll.name, EVENT_ADD_ON_LOADED, onAddOnLoaded)