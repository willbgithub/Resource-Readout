

local Text = require "widgets/text"
local _GlobalInventory

local function GetPlayerIndex(inst)
	for i,player in ipairs(AllPlayers) do
		if player == inst then
			return i
		end
	end
	return 0
end

local function AddString(stack, str) -- something something garbage collection. a stack is {""} or larger
	table.insert(stack, str) -- push into the the stack
	for i = #stack - 1, 1, -1 do
		if string.len(stack[i]) > string.len(stack[i+1]) then
			break
		end
		stack[i] = stack[i]..table.remove(stack)
	end
end -- table.concat(stack)

local function OnPrefabDirty(inst)
	local self = inst.components.globalinventory
    self.last_prefab = self.net_last_prefab:value()
end

local function OnInventoryDirty(inst)
	local self = inst.components.globalinventory
	self.count = self.count + 1
	self.last_inventory = self.net_last_inventory:value()
	self.inventory_widget:SetString(self:ConstructData())
end

local function _OnServer(self)
	self._onitemupdate = function(inst, data) --c_announce(tostring(self.count+1)..", "..tostring(inst)..", "..tostring(data.item))
		self.count = self.count + 1
		local item = data.item
		local prefab = item and item.prefab or "nil"
		self:SetLastPrefab(prefab)
		local stackable = item and item.components.stackable
		local quantity = stackable and stackable.stacksize or 0
		local finiteuses = item and item.components.finiteuses
		local percent = finiteuses and math.ceil((finiteuses.current/finiteuses.total)*100) or 0
		self:SetLastInventory({
			GetPlayerIndex(inst),
			data.slot or 0,
			data.eslot or 0,
			quantity,
			percent,
		})
	end
	local protocols =
	{
		"newactiveitem", -- data.slot
		"itemget", -- data.slot, data.item, data.src_pos
		"itemlose", -- data.slot
		"equip", -- data.eslot, data.item
		"unequip", -- data.eslot
	}
	self.inst:ListenForEvent("ms_playerjoined", function(inst, player)
		for _,prot in pairs(protocols) do
			_GlobalInventory.inst:ListenForEvent(prot, self._onitemupdate, player)
		end
	end, TheWorld)
	self.inst:ListenForEvent("ms_playerleft", function(inst, player)
		for _,prot in pairs(protocols) do
			_GlobalInventory.inst:RemoveEventCallback(prot, self._onitemupdate, player)
		end
	end, TheWorld)
end

local GlobalInventory = Class(function(self, inst)
    _GlobalInventory = self
	self.inst = inst
	
	self.count = 0 -- just for visuals
	self.last_prefab = ""
	self.net_last_prefab = net_string(self.inst.GUID, "globinv_prefab", "globinv_prefabdirty")
	self.last_inventory = -- don't know if im overcomplicating it. bytes only go up to 256
	{
		0, -- playerindex
		0, -- slot
		0, -- eslot
		0, -- quantity
		0, -- percent
	}
	self.net_last_inventory = net_bytearray(self.inst.GUID, "globinv_inventory", "globinv_inventorydirty")
	
	if TheWorld.ismastersim then
		_OnServer(self)
	else
		self:Client()
	end
	
	self.inst:StartUpdatingComponent(self)
end)

function GlobalInventory:SetLastPrefab(prefab)
	self.last_prefab = prefab
	self.net_last_prefab:set(prefab)
end

function GlobalInventory:SetLastInventory(inventory)
	local net_inventory = {}
	for _,v in ipairs(inventory) do
		local num = tonumber(v)
		if type(num) == "number" then
			if num > 256 then
				num = 256
			end
		else
			num = 0
		end
		table.insert(net_inventory, num)
	end
	self.last_inventory = net_inventory
	self.net_last_inventory:set(net_inventory)
end

function GlobalInventory:Client()
	self.inst:ListenForEvent("globinv_prefabdirty", OnPrefabDirty)
	self.inst:ListenForEvent("globinv_inventorydirty", OnInventoryDirty)
end

function GlobalInventory:ConstructData()
	local str = {""}
	AddString(str, "("..self.count..")")
	AddString(str, self.last_prefab.." {")
	for _,data in pairs(self.last_inventory) do
		AddString(str, data..", ")
	end
	AddString(str, "}")
	return table.concat(str)
end

function GlobalInventory:ServerOnUpdate(dt) -- Server Only
	if #AllPlayers == 0 then return end
	if self.last_prefab and self.last_inventory and self.inventory_widget then
		self.inventory_widget:SetString(self:ConstructData())
	end
end

function GlobalInventory:OnUpdate(dt) -- Client/Server
	if ThePlayer and not self.inventory_widget then -- Clientside UI
		self.inventory_widget = ThePlayer.HUD.overlayroot:AddChild(Text(UIFONT, 30))
		self.inventory_widget:SetVAnchor(ANCHOR_TOP)
        self.inventory_widget:SetHAnchor(ANCHOR_MIDDLE)
        self.inventory_widget:SetPosition(0, -45)
        self.inventory_widget:SetString(self:ConstructData())
	end
	if TheWorld.ismastersim then
		self:ServerOnUpdate(dt)
	end
end

if false then
    print("FLORG: something terrible has happened")
    Class = Class
    DEFAULTFONT = DEFAULTFONT
    ANCHOR_MIDDLE = ANCHOR_MIDDLE
    GLOBAL = GLOBAL
    AddPlayerPostInit = AddPlayerPostInit
    TheWorld = TheWorld
    ThePlayer = ThePlayer
    AllPlayers = AllPlayers
    net_bytearray = net_bytearray
    UIFONT = UIFONT
    ANCHOR_TOP = ANCHOR_TOP
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

return GlobalInventory