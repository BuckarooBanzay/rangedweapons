
local modpath = minetest.get_modpath(minetest.get_current_modname())

-- global namespace
rangedweapons = {

}

if minetest.global_exists("armor") and armor.attributes then
	table.insert(armor.attributes, "bullet_res")
end
if minetest.global_exists("armor") and armor.attributes then
	table.insert(armor.attributes, "ammo_save")
end
if minetest.global_exists("armor") and armor.attributes then
	table.insert(armor.attributes, "ranged_dmg")
end

minetest.register_node("rangedweapons:antigun_block", {
	description = "" ..core.colorize("#35cdff","Anti-gun block\n")..core.colorize("#FFFFFF", "Prevents people from using guns, in 10 node radius to each side from this block"),
	tiles = {"rangedweapons_antigun_block.png"},
	groups = {choppy = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_wood_defaults(),
})


dofile(modpath.."/common.lua")
dofile(modpath.."/cooldown_stuff.lua")
dofile(modpath.."/skills.lua")
dofile(modpath.."/misc.lua")
dofile(modpath.."/bullet_knockback.lua")
dofile(modpath.."/ammo.lua")
dofile(modpath.."/crafting.lua")

if minetest.settings:get_bool("rangedweapons_shurikens", true) then
	dofile(modpath.."/shurikens.lua")
end

if minetest.settings:get_bool("rangedweapons_handguns", true) then
	dofile(modpath.."/makarov.lua")
	dofile(modpath.."/luger.lua")
	dofile(modpath.."/beretta.lua")
	dofile(modpath.."/m1991.lua")
	dofile(modpath.."/glock17.lua")
	dofile(modpath.."/deagle.lua")
end

if minetest.settings:get_bool("rangedweapon_forceguns", true) then
	dofile(modpath.."/forcegun.lua")
end

if minetest.settings:get_bool("rangedweapons_javelins", true) then
	dofile(modpath.."/javelin.lua")
end

if minetest.settings:get_bool("rangedweapons_power_weapons", true) then
	dofile(modpath.."/generator.lua")
	dofile(modpath.."/laser_blaster.lua")
	dofile(modpath.."/laser_rifle.lua")
	dofile(modpath.."/laser_shotgun.lua")
end

if minetest.settings:get_bool("rangedweapons_machine_pistols", true) then
	dofile(modpath.."/tmp.lua")
	dofile(modpath.."/tec9.lua")
	dofile(modpath.."/uzi.lua")
	dofile(modpath.."/kriss_sv.lua")
end
if minetest.settings:get_bool("rangedweapons_shotguns", true) then
	dofile(modpath.."/remington.lua")
	dofile(modpath.."/spas12.lua")
	dofile(modpath.."/benelli.lua")
end
if minetest.settings:get_bool("rangedweapons_auto_shotguns", true) then
	dofile(modpath.."/jackhammer.lua")
	dofile(modpath.."/aa12.lua")
end
if minetest.settings:get_bool("rangedweapons_smgs", true) then
	dofile(modpath.."/mp5.lua")
	dofile(modpath.."/ump.lua")
	dofile(modpath.."/mp40.lua")
	dofile(modpath.."/thompson.lua")
end
if minetest.settings:get_bool("rangedweapons_rifles", true) then
	dofile(modpath.."/awp.lua")
	dofile(modpath.."/svd.lua")
	dofile(modpath.."/m200.lua")
end
if minetest.settings:get_bool("rangedweapons_heavy_machineguns", true) then
	dofile(modpath.."/m60.lua")
	dofile(modpath.."/rpk.lua")
	dofile(modpath.."/minigun.lua")
end
if minetest.settings:get_bool("rangedweapons_revolvers", true) then
	dofile(modpath.."/python.lua")
	dofile(modpath.."/taurus.lua")
end
if minetest.settings:get_bool("rangedweapons_assault_rifles", true) then
	dofile(modpath.."/m16.lua")
	dofile(modpath.."/g36.lua")
	dofile(modpath.."/ak47.lua")
	dofile(modpath.."/scar.lua")
end

if minetest.settings:get_bool("rangedweapons_explosives", true) then
	dofile(modpath.."/explosives.lua")
	dofile(modpath.."/m79.lua")
	dofile(modpath.."/milkor.lua")
	dofile(modpath.."/rpg.lua")
	dofile(modpath.."/hand_grenade.lua")
end

if minetest.settings:get_bool("rangedweapons_glass_breaking", true) then
	dofile(modpath.."/glass_breaking.lua")
--[[ What is this good for?
minetest.register_abm({
	nodenames = {"rangedweapons:broken_glass"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if minetest.get_node(pos).name == "rangedweapons:broken_glass" then
			node.name = "default:glass"
			minetest.set_node(pos, node)
		end
	end
})
end
--]]
end

local rangedweapons_empty_shell = {
	physical = false,
	timer = 0,
	visual = "wielditem",
	visual_size = {x=0.3, y=0.3},
	textures = {"rangedweapons:shelldrop"},
	lastpos= {},
	collisionbox = {0, 0, 0, 0, 0, 0},
}

rangedweapons_empty_shell.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	if self.lastpos.y ~= nil then
		if minetest.registered_nodes[node.name]~= nil then
			if minetest.registered_nodes[node.name].walkable then
				local vel = self.object:get_velocity()
				local acc = self.object:get_acceleration()
				self.object:set_velocity({x=vel.x*-0.3, y=vel.y*-0.75, z=vel.z*-0.3})
				minetest.sound_play("rangedweapons_shellhit", {pos = self.lastpos, gain = 0.8}, true)
				self.object:set_acceleration({x=acc.x, y=acc.y, z=acc.z})
			end
		end
	end
	if self.timer > 1.69 then
		minetest.sound_play("rangedweapons_bulletdrop", {pos = self.lastpos, gain = 0.8}, true)
		self.object:remove()
	end
	self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
end

minetest.register_entity("rangedweapons:empty_shell", rangedweapons_empty_shell )

-- note: this looks like a node-cleanup for hidden doorparts if the visible part gets blown away
minetest.register_abm({
	nodenames = {"doors:hidden"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		pos.y = pos.y-1
		if minetest.get_node(pos).name == "air" then
			pos.y = pos.y+1
			node.name = "air"
			minetest.set_node(pos, node)
		end
	end
})

