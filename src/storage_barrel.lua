--------------------------------------------------------------------------------
-- malcontent_xdecor_addon
--
-- Inspired by:
-- X-Decor-libre by Wuzzy (https://codeberg.org/Wuzzy/xdecor-libre),
-- a drop-in replacement for the original Xdecor mod by kilbith
-- (https://github.com/minetest-mods/xdecor)
--
-- Copyright (c) 2015-2021 kilbith <jeanpatrick.guerrero@gmail.com> 
-- Code: BSD-3-Clause
-- Textures: CC0 (credits: Gambit, kilbith, Cisoun, Malfal)
--
-- Additions:
-- storage barrel based on the combination of the decorative barrel
-- and storage cabinet
--
-- Todo: add support for more translations
-- Todo: remove unused code
--------------------------------------------------------------------------------
screwdriver = screwdriver or {}
local S = core.get_translator("malcontent_xdecor_addon")

function malcontent_xdecor_addon.get_inventory_drops(pos, listnames)
	local drops = {}
	for l=1, #listnames do
		default.get_inventory_drops(pos, listnames[l], drops)
	end
	return drops
end

malcontent_xdecor_addon.xbg = default.gui_bg .. default.gui_bg_img .. default.gui_slots
local default_inventory_size = 32

local default_inventory_formspecs = {
	["8"] = [[ size[8,6]
		list[context;main;0,0;8,1;]
		list[current_player;main;0,2;8,4;]
		listring[current_player;main]
		listring[context;main] ]] ..
		default.get_hotbar_bg(0,2),

	["16"] = [[ size[8,7]
		list[context;main;0,0;8,2;]
		list[current_player;main;0,3;8,4;]
		listring[current_player;main]
		listring[context;main] ]] ..
		default.get_hotbar_bg(0,3),

	["24"] = [[ size[8,8]
		list[context;main;0,0;8,3;]
		list[current_player;main;0,4;8,4;]
		listring[current_player;main]
		listring[context;main]" ]] ..
		default.get_hotbar_bg(0,4),

	["32"] = [[ size[8,9]
		list[context;main;0,0.3;8,4;]
		list[current_player;main;0,4.85;8,1;]
		list[current_player;main;0,6.08;8,3;8]
		listring[current_player;main]
		listring[context;main] ]] ..
		default.get_hotbar_bg(0,4.85)
}

local function get_formspec_by_size(size)
	local formspec = default_inventory_formspecs[tostring(size)]
	return formspec or default_inventory_formspecs
end

local default_can_dig = function(pos)
	local inv = core.get_meta(pos):get_inventory()
	return inv:is_empty("main")
end

function malcontent_xdecor_addon.register(name, def)
	def.drawtype = def.drawtype or (def.mesh and "mesh") or (def.node_box and "nodebox")
	def.sounds = def.sounds or default.node_sound_defaults()

	if not (def.drawtype == "normal" or def.drawtype == "signlike" or
			def.drawtype == "plantlike" or def.drawtype == "glasslike_framed" or
			def.drawtype == "glasslike_framed_optional") then
		def.paramtype2 = def.paramtype2 or "facedir"
	end

	local infotext = def.infotext
	local inventory = def.inventory
	def.inventory = nil

	if inventory then
		def.on_construct = def.on_construct or function(pos)
			local meta = core.get_meta(pos)
			if infotext then meta:set_string("infotext", infotext) end

			local size = inventory.size or default_inventory_size
			local inv = meta:get_inventory()

			inv:set_size("main", size)
			meta:set_string("formspec",
				(inventory.formspec or get_formspec_by_size(size)) .. malcontent_xdecor_addon.xbg)
		end

		def.can_dig = def.can_dig or default_can_dig

	elseif infotext and not def.on_construct then
		def.on_construct = function(pos)
			local meta = core.get_meta(pos)
			meta:set_string("infotext", infotext)
		end
	end

	core.register_node("malcontent_xdecor_addon:" .. name, def)
end

local ALPHA_OPAQUE = core.features.use_texture_alpha_string_modes and "opaque" or false

local function blast_storage(pos)
	local drops = malcontent_xdecor_addon.get_inventory_drops(pos, {"main"})
	core.remove_node(pos)
	return drops
end

local function register_storage(name, desc, def)
	malcontent_xdecor_addon.register(name, {
		description = desc,
		_tt_help = def._tt_help,
		inventory = {size = def.inv_size or 24},
		infotext = desc,
		tiles = def.tiles,
		use_texture_alpha = ALPHA_OPAQUE,
		node_box = def.node_box,
		on_rotate = def.on_rotate,
		on_place = def.on_place,
		on_blast = blast_storage,
		groups = def.groups or {choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
		is_ground_content = false,
		sounds = default.node_sound_wood_defaults()
	})
end

register_storage("storage_barrel", S("Storage Barrel"), {
	_tt_help = S("24 inventory slots"),
	on_rotate = screwdriver.rotate_simple,
	on_place = core.rotate_node,
	tiles = {
		"malcontent_xdecor_addon_storage_barrel_top.png", "malcontent_xdecor_addon_storage_barrel_bottom.png",
		"malcontent_xdecor_addon_storage_barrel_sides.png", "malcontent_xdecor_addon_storage_barrel_sides.png",
		"malcontent_xdecor_addon_storage_barrel_sides.png", "malcontent_xdecor_addon_storage_barrel_sides.png"
	}
})

--------------------------------------------------------------------------------
-- register crafting recipe for malcontent_xdecor_addon:storage_barrel
--
-- note: this crafting recipe is consistent with the barrel and cabinet crafting
-- recipes in xdecor
--------------------------------------------------------------------------------
core.register_craft({
	output = "malcontent_xdecor_addon:storage_barrel",
	recipe = {
		{"group:wood", "doors:trapdoor", "group:wood"},
		{"default:iron_lump", "", "default:iron_lump"},
		{"group:wood", "group:wood", "group:wood"}
	}
})

--------------------------------------------------------------------------------
-- register fuel recipe for malcontent_xdecor_addon:storage:barrel
--
-- note: this fuel recipe is consistent with the barrel and cabinet fuel recipes
-- in xdecor
--------------------------------------------------------------------------------
core.register_craft({
	type = "fuel",
	recipe = "malcontent_xdecor_addon:storage_barrel",
	burntime = 30,
})
