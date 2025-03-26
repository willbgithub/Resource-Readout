local function AddNetComponent(component)
	local function NetComponentHandler(inst)
		inst:AddComponent(component)
	end
	AddPrefabPostInit("forest_network", NetComponentHandler) -- Must be added to both cave and forest network, or whatever network prefabs your gamemode uses.
	AddPrefabPostInit("cave_network", NetComponentHandler)
end
AddNetComponent("displayhostname")