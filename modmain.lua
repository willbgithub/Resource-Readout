-- local FollowText = GLOBAL.require "widgets.followtext"
-- local blacklist = {
--     "spider_whistle",
--     "lucy",
--     "wortox_soul"
-- }

-- local function getPlayerInventories()
--     print("getPlayerInventories")
--     local items = {}
--     for _, player in ipairs(GLOBAL.AllPlayers) do
--         if player and player.components.inventory then
--             player.components.inventory:ForEachItem(function(item)
--                 local count = item.components.stackable and item.components.stackable.stacksize or 1
--                 if items[item.prefab] then
--                     items[item.prefab] = items[item.prefab] + count
--                 else
--                     items[item.prefab] = count
--                 end
--             end)
--         end
--     end
--     return items
-- end
-- local function mergeResourceTables(tables)
--     print("mergeResourceTables")
--     local mergedTable = {}
--     for _, table in pairs(tables) do
--       for item, amount in pairs(table) do
--         if mergedTable[item] then
--           mergedTable[item] = mergedTable[item] + amount
--         else
--           mergedTable[item] = amount
--         end
--       end
--     end
--     return mergedTable
-- end
-- local function resourceTableToString(table)
--     print("resourceTableToString")
--     local string = ""
--     for item, amount in pairs(table) do
--       string = string .. item .. ": " .. amount .. "\n"
--     end
--     string = string.gsub(string, "\n$", "")
--     return string
-- end
-- local function tableContains(table, element)
--     for _, item in pairs(table) do
--         if item == element then
--           return true
--         end
--     end
--     return false
-- end
-- local function isBlacklisted(prefab)
--     return tableContains(blacklist, prefab)
-- end
-- local function convertPrefabstoDisplayNames(table)
--     print("convertPrefabstoDisplayNames")
--     local displayTable = {}
--     for prefab, count in pairs(table) do
--         if not isBlacklisted(prefab) then
--             local displayName = GLOBAL.STRINGS.NAMES[string.upper(prefab)] or prefab
--             displayTable[displayName] = count
--         end
--     end
--     return displayTable
-- end
-- local function getResources()
--     print("getResources")
--     local playerInventories = getPlayerInventories()
--     local resources = mergeResourceTables({playerInventories})
--     resources = convertPrefabstoDisplayNames(resources)
--     return resources
-- end
-- local function OnItemChanged(player)
--     print(player)
--     print("OnItemChanged")
--     if player.components.talker then
--         player.components.talker:Say(tostring(player))
--     else
--         print(tostring(player).." has no talker component")
--     end
-- end
-- local function SendResourceReadoutRPC()
--     print("SendResourceReadoutRPC")
-- 	SendModRPCToServer(GetModRPC("resourceReadoutRPC", "OnItemChanged"))
-- end
-- AddModRPCHandler("resourceReadoutRPC", "OnItemChanged", OnItemChanged)
-- GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_R, function()
--     SendResourceReadoutRPC()
-- end)



-- *** env _G *** --
-- const
_G = GLOBAL
unpack = _G.unpack
TheNet = _G.TheNet
modstamp = "[".._G.KnownModIndex:GetModInfo(modname).name.."] "
--fn
runscript = function(name) modimport("scripts/"..name) end
print_old = print
print = function(a, ...) print_old(modstamp..tostring(a), ...) end
_G.d_getitems = function(inst) 
	local inst = inst or _G.ThePlayer or _G.ConsoleCommandPlayer()
	local inventory = inst.components.inventory
	if not inventory then return end
	local result = "Nothing"
	local count = 0
	for i = 1, inventory.maxslots do 
		local item = inventory.itemslots[i] 
		if item then
			_G.dumptable(item)
			local stackable = item.components.stackable
			local finiteuses = item.components.finiteuses
			count = count + 1
			local name = "["..i.."] "..item:GetDisplayName()
			if count == 1 then
				result = name
			else
				result = result..", "..name
			end
			if stackable then
				result = result.." ("..stackable.stacksize.."/"..stackable.maxsize..")"
			end
			if finiteuses then
				result = result.." ("..string.format("%d",(finiteuses.current/finiteuses.total)*100).."%)"
			end
		end 
	end 
	return inst:GetDisplayName().." has: "..result
end

local function NetHandler(inst)
	if TheNet:GetServerGameMode() ~= "survival" then
		print("Unexpected results will come from enabling this with another gamemode, be warned.")
	end
	inst:AddComponent"globalinventory"
end
AddPrefabPostInit("forest_network", NetHandler)
AddPrefabPostInit("cave_network", NetHandler)



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
    AddClientModRPCHandler = AddClientModRPCHandler
    SendModRPCToClient = SendModRPCToClient
    GetClientModRPC = GetClientModRPC
    net_string = net_string
    modname = modname
    runscript = runscript
end