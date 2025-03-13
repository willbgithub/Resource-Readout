local FollowText = GLOBAL.require "widgets.followtext"
local blacklist = {
    "spider_whistle",
    "lucy"
}

local function getPlayerInventories()
    local items = {}
    for _, player in ipairs(GLOBAL.AllPlayers) do
        if player and player.components.inventory then
            player.components.inventory:ForEachItem(function(item)
                local count = item.components.stackable and item.components.stackable.stacksize or 1
                if items[item.prefab] then
                    items[item.prefab] = items[item.prefab] + count
                else
                    items[item.prefab] = count
                end
            end)
        end
    end
    return items
end
local function mergeResourceTables(tables)
    local mergedTable = {}
    for _, table in pairs(tables) do
      for item, amount in pairs(table) do
        if mergedTable[item] then
          mergedTable[item] = mergedTable[item] + amount
        else
          mergedTable[item] = amount
        end
      end
    end
    return mergedTable
end
local function resourceTableToString(table)
    local string = ""
    for item, amount in pairs(table) do
      string = string .. item .. ": " .. amount .. "\n"
    end
    string = string.gsub(string, "\n$", "")
    return string
end
local function tableContains(table, element)
    for _, item in pairs(table) do
        if item == element then
          return true
        end
    end
    return false
end
local function isBlacklisted(prefab)
    return tableContains(blacklist, prefab)
end
local function convertPrefabstoDisplayNames(table)
    local displayTable = {}
    for prefab, count in pairs(table) do
        if not isBlacklisted(prefab) then
            local displayName = GLOBAL.STRINGS.NAMES[string.upper(prefab)] or prefab
            displayTable[displayName] = count
        end
    end
    return displayTable
end
local function getResources()
    local playerInventories = getPlayerInventories()
    local resources = mergeResourceTables({playerInventories})
    resources = convertPrefabstoDisplayNames(resources)
    return resources
end
local function updateAllPlayersHUD(player)
    local resources = resourceTableToString(getResources())
    for _, player in ipairs(GLOBAL.AllPlayers) do
        player.headwidget.text:SetString(resources)
    end
end
local function OnItemChanged(player)
    GLOBAL.TheWorld:DoTaskInTime(0.05, updateAllPlayersHUD)
end
local function SendResourceReadoutRPC()
	SendModRPCToServer(GetModRPC("resourceReadoutRPC", "OnItemChanged"))
end

AddPlayerPostInit(function (player)
    player:DoTaskInTime(1, function(player)
        if player and player.HUD then
            player.headwidget = player.HUD:AddChild(FollowText(GLOBAL.TALKINGFONT, 35))
            player.headwidget:SetHUD(player.HUD.inst)
            player.headwidget:SetOffset(GLOBAL.Vector3(0, -500, 0))
            player.headwidget:SetTarget(player)
            player.headwidget.text:SetColour(1, 1, 1, 1)
            player.headwidget.text:SetString("GLORP!")
            player.headwidget:Show()

        end
    end)
end)

AddModRPCHandler("resourceReadoutRPC", "OnItemChanged", OnItemChanged)

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
    SendResourceReadoutRPC()
end)

-- EVIL PINK ERRORS BEGONE
if false then
    print("FLORG: something terrible has happened")
    Class = Class
    DEFAULTFONT = DEFAULTFONT
    ANCHOR_MIDDLE = ANCHOR_MIDDLE
    GLOBAL = GLOBAL
    AddPlayerPostInit = AddPlayerPostInit
    TheWorld = TheWorld
    AddPrefabPostInit = AddPrefabPostInit
    AddModRPCHandler = AddModRPCHandler
    SendModRPCToServer = SendModRPCToServer
    GetModRPC = GetModRPC
    AddSimPostInit = AddSimPostInit
    TheFrontEnd = TheFrontEnd
    TextScreen = TextScreen
    Text = Text
end