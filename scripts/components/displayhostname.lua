

local Text = require "widgets/text" -- Our widget used for our UI
local _DisplayHostName -- pre-defining the component name, it will be defined later. fns with _ before it are server fns, but this is the whole component
STRINGS.DISPLAYHOSTNAME = -- We need STRINGS for our UI
{
	NONE = "Nobody",
	HOSTNAME = "Host: {name}", -- we will use subfmt for the things in brackets {}
}

local function OnHostNameDirty(inst) -- Client: When the server signals us that the host name has updated, we will do the following
	_DisplayHostName.host_name = _DisplayHostName.net_host_name:value() -- Update our clientside host_name to the Server's net_string
	_DisplayHostName:UpdateUI() -- Updating UI. This will not be run because the server knows the host before we join in.
end

local function OnPlayerActivated(world, inst) -- If you have a Clientside UI, you could probably initialize it here
	print("PLAYERACTIVATED", world, inst) -- This will be printed in your client_log.txt. Notice that this prints twice if you're on the character select screen, without an inst or world
	if inst:IsValid() then
		print("I am valid!")
		_DisplayHostName:UpdateUI() -- Updating UI for the first time
	end
end

local function _SetHostName(self, val) -- Server
	self.host_name = val -- We must set the server's local hostname as well so the server's widget can update
	self.net_host_name:set(val) -- We will now officially set the Host name and trigger a chain of changes on the network
end

local function _OnPlayerJoined(world, inst) c_announce(tostring(world)..", "..tostring(inst)) -- Server
	if TheNet:GetIsHosting(inst.Network) then -- Players will have a Network (same as their own TheNet) for the Server that's available when they join
		_SetHostName(_DisplayHostName, tostring(inst:GetDisplayName()).." ("..tostring(inst.prefab)..")") -- Using tostring because it's a good idea to ensure everything you send to the net is accurate because the server will stop if it recieves a bad input
	end
end

local function _OnServer(self) -- Made it a local function so it's private. I don't think this is neccessary, but this is more of an indication that this is classified info. Everything in this fn is defined later
	-- ms_ usually indicates server-side events
	self.inst:ListenForEvent("ms_playerjoined", _OnPlayerJoined, TheWorld) -- Whether you put TheWorld/inst in the third arg determines where this component will listen, whether Client or on the Server
	-- You may need to use RemoveEventCallback, passing in the same arguments if you need to remove the listener. 
end

local DisplayHostName = Class(function(self, inst)
    _DisplayHostName = self -- our net component is now available anywhere in the file
	self.inst = inst
	
	-- setting up local and net variables that both the server and client uses
	self.host_name = "" -- Initializing strings as empty to ensure we initialized data correctly
	-- First arg is the GUID this net_var resides on, basically an address for the variables
	-- The second arg ("displayhost_hostname") is the Server Event that gets pushed when the variable changes
	-- The third arg ("displayhost_hostnamedirty") is the Client Event that gets pushed when the variable changes. This is commonly referred to as dirty because it means we are unsynced with the server and have to listen to this event to have our data "clean" again
	self.net_host_name = net_string(self.inst.GUID, "displayhost_hostname", "displayhost_hostnamedirty")
	
	self.inst:ListenForEvent("playeractivated", OnPlayerActivated, TheWorld) -- Server listens for when player activates into a world, and makes the client do something
	-- Both the player (Client) and Server will read this component, we want it to do different things based on whether we're the Client or Server
	if TheWorld.ismastersim then  -- if we are the Server, use the server fn
		_SetHostName(self, STRINGS.DISPLAYHOSTNAME.NONE) -- Set our host name to our default value
		_OnServer(self)
	else -- If we are the Client, use the client fn
		self:Client() 
	end
	
	self.inst:StartUpdatingComponent(self) -- The net component will now do an OnUpdate that both client and server reads
end)

function DisplayHostName:Client() -- What the component does when we are a client
	self.inst:ListenForEvent("displayhost_hostnamedirty", OnHostNameDirty) -- The client will listen for the event that happens when the net_var changes
end

function DisplayHostName:ConstructHostNameData() -- Server/Client
	return subfmt(STRINGS.DISPLAYHOSTNAME.HOSTNAME, -- return a formatted string with our data
	{
		name = self.host_name,
	})
end

function DisplayHostName:UpdateUI() -- Server/Client
	if not self.host_widget then return end
	self.host_widget:SetString(self:ConstructHostNameData())
end

function DisplayHostName:ServerOnUpdate(dt) -- Server Only
	if #AllPlayers == 0 then
        return -- Don't do anything from this point on if there's no players. There's no point.
    end 
	if self.host_name and self.host_widget then -- If we have data and we have a widget, then update it. We will only have this happen if we are both ThePlayer and Server, which can happen when you are on single shards. You will have more accurate data in this situation.
		self:UpdateUI() -- Created a general fn for updating UI because it's so small
	end
end

function DisplayHostName:OnUpdate(dt) -- Client/Server
	if ThePlayer and not self.host_widget then -- Clientside UI. Right when ThePlayer exists, create the UI. ThePlayer will not exist yet if you're loading in or on the character select
		self.host_widget = ThePlayer.HUD.overlayroot:AddChild(Text(UIFONT, 40)) -- Initializing a new text widget
		self.host_widget:SetVAnchor(ANCHOR_TOP)
        self.host_widget:SetHAnchor(ANCHOR_MIDDLE)
        self.host_widget:SetPosition(0, -100)
	end
	if TheWorld.ismastersim then -- If we are the server, use this fn
		self:ServerOnUpdate(dt)
	end
end

return DisplayHostName -- net component fn