// TODO(rufus): move customs to DB and build a UI for editing them, also clean up this outdated code
// Switch this out to use a database at some point. Each ckey is
// associated with a list of custom item datums. When the character
// spawns, the list is checked and all appropriate datums are spawned.
// See config/example/custom_items.txt for a more detailed overview
// of how the config system works.

// CUSTOM ITEM ICONS:
// Inventory icons must be in CUSTOM_ITEM_OBJ with state name [item_icon].
// On-mob icons must be in CUSTOM_ITEM_MOB with state name [item_icon].
// Inhands must be in CUSTOM_ITEM_MOB as [icon_state]_l and [icon_state]_r.

// Kits must have mech icons in CUSTOM_ITEM_OBJ under [kit_icon].
// Broken must be [kit_icon]-broken and open must be [kit_icon]-open.

// Kits must also have hardsuit icons in CUSTOM_ITEM_MOB as [kit_icon]_suit
// and [kit_icon]_helmet, and in CUSTOM_ITEM_OBJ as [kit_icon].

/var/list/custom_items = list()

/datum/custom_item
	var/assoc_key
	var/character_name
	var/inherit_inhands = 1 //if unset, and inhands are not provided, then the inhand overlays will be invisible.
	var/item_icon
	var/item_desc
	var/name
	var/item_path = /obj/item
	var/item_path_as_string
	var/req_access = 0
	var/list/req_titles = list()
	var/kit_name
	var/kit_desc
	var/kit_icon
	var/additional_data

/datum/custom_item/proc/is_valid(checker)
	if(!item_path)
		to_chat(checker, SPAN("warning", "The given item path, [item_path_as_string], is invalid and does not exist."))
		return FALSE
	if(item_icon && !(item_icon in icon_states(CUSTOM_ITEM_OBJ)))
		to_chat(checker, SPAN("warning", "The given item icon, [item_icon], is invalid and does not exist."))
		return FALSE
	return TRUE

/datum/custom_item/proc/spawn_item(newloc)
	var/obj/item/citem = new item_path(newloc)
	apply_to_item(citem)
	return citem

/datum/custom_item/proc/apply_to_item(obj/item/item)
	if(!item)
		return
	if(name)
		item.SetName(name)
	if(item_desc)
		item.desc = item_desc
	if(item_icon)
		if(!istype(item))
			item.icon = CUSTOM_ITEM_OBJ
			item.set_icon_state(item_icon)
			return
		else
			if(inherit_inhands)
				apply_inherit_inhands(item)
			else
				item.item_state_slots = null
				item.item_icons = null

			item.icon = CUSTOM_ITEM_OBJ
			item.set_icon_state(item_icon)
			item.item_state = null
			item.icon_override = CUSTOM_ITEM_MOB

		var/obj/item/clothing/under/U = item
		if(istype(U))
			U.worn_state = U.icon_state
			U.update_rolldown_status()

	// Kits are dumb so this is going to have to be hardcoded/snowflake.
	if(istype(item, /obj/item/device/kit))
		var/obj/item/device/kit/K = item
		K.new_name = kit_name
		K.new_desc = kit_desc
		K.new_icon = kit_icon
		K.new_icon_file = CUSTOM_ITEM_OBJ
		if(istype(item, /obj/item/device/kit/paint))
			var/obj/item/device/kit/paint/kit = item
			kit.allowed_types = splittext(additional_data, ", ")
		else if(istype(item, /obj/item/device/kit/suit))
			var/obj/item/device/kit/suit/kit = item
			kit.new_light_overlay = additional_data
			kit.new_mob_icon_file = CUSTOM_ITEM_MOB

	return item

/datum/custom_item/proc/apply_inherit_inhands(obj/item/item)
	var/list/new_item_icons = list()
	var/list/new_item_state_slots = list()

	var/list/available_states = icon_states(CUSTOM_ITEM_MOB)

	//If l_hand or r_hand are not present, preserve them using item_icons/item_state_slots
	//Then use icon_override to make every other slot use the custom sprites by default.
	//This has to be done before we touch any of item's vars
	if(!("[item_icon]_l" in available_states))
		new_item_state_slots[slot_l_hand_str] = get_state(item, slot_l_hand_str, "_l")
		new_item_icons[slot_l_hand_str] = get_icon(item, slot_l_hand_str, 'icons/mob/onmob/items/lefthand.dmi')
	if(!("[item_icon]_r" in available_states))
		new_item_state_slots[slot_r_hand_str] = get_state(item, slot_r_hand_str, "_r")
		new_item_icons[slot_r_hand_str] = get_icon(item, slot_r_hand_str, 'icons/mob/onmob/items/righthand.dmi')

	item.item_state_slots = new_item_state_slots
	item.item_icons = new_item_icons

//this has to mirror the way update_inv_*_hand() selects the state
/datum/custom_item/proc/get_state(obj/item/item, slot_str, hand_str)
	var/t_state
	if(item.item_state_slots && item.item_state_slots[slot_str])
		t_state = item.item_state_slots[slot_str]
	else if(item.item_state)
		t_state = item.item_state
	else
		t_state = item.icon_state
	if(item.icon_override)
		t_state += hand_str
	return t_state

//this has to mirror the way update_inv_*_hand() selects the icon
/datum/custom_item/proc/get_icon(obj/item/item, slot_str, icon/hand_icon)
	var/icon/t_icon
	if(item.icon_override)
		t_icon = item.icon_override
	else if(item.item_icons && (slot_str in item.item_icons))
		t_icon = item.item_icons[slot_str]
	else
		t_icon = hand_icon
	return t_icon

// Parses the config file into the custom_items list.
/hook/startup/proc/load_custom_items()
	var/config_file_path = "config/custom_items/custom_items.json"
	if(!fexists(config_file_path))
		return TRUE
	if(GLOB.using_map.loadout_blacklist && (/datum/gear/custom_item in GLOB.using_map.loadout_blacklist))
		return
	var/list/config_json = json_decode(file2text(config_file_path))
	for(var/list/ckey_group in config_json["customs"])
		var/ckey = ckey_group["ckey"]
		for(var/list/item_data in ckey_group["items"])
			var/datum/custom_item/current_data = new()

			var/item_path = item_data["item"]?["path"]
			current_data.item_path_as_string = item_path
			item_path = text2path(item_path)
			ASSERT(ispath(item_path))

			current_data.name = item_data["item"]?["name"]
			current_data.item_icon = item_data["item"]?["icon"]
			current_data.item_desc = item_data["item"]?["desc"]

			current_data.kit_name = item_data["kit"]?["name"]
			current_data.kit_icon = item_data["kit"]?["icon"]
			current_data.kit_desc = item_data["kit"]?["desc"]

			current_data.inherit_inhands = item_data["inherit_inhands"]
			current_data.req_access = item_data["req_access"]
			current_data.req_titles = item_data["req_titles"]
			current_data.additional_data = item_data["additional_data"]

			current_data.assoc_key = ckey
			current_data.item_path = item_path
			var/datum/gear/custom_item/G = new(ckey, item_path, current_data)

			var/use_name = G.display_name
			var/use_category = G.sort_category

			if(!loadout_categories[use_category])
				loadout_categories[use_category] = new /datum/loadout_category(use_category)
			var/datum/loadout_category/LC = loadout_categories[use_category]
			gear_datums[use_name] = G
			hash_to_gear[G.gear_hash] = G
			LC.gear[use_name] = gear_datums[use_name]

	return TRUE

//gets the relevant list for the key from the listlist if it exists, check to make sure they are meant to have it and then calls the giving function
/proc/equip_custom_items(mob/living/carbon/human/M)
	var/list/key_list = custom_items[M.ckey]
	if(!key_list || key_list.len < 1)
		return

	for(var/datum/custom_item/citem in key_list)

		// Check for requisite ckey and character name.
		if((lowertext(citem.assoc_key) != lowertext(M.ckey)) || (lowertext(citem.character_name) != lowertext(M.real_name)))
			continue

		// Once we've decided that the custom item belongs to this player, validate it
		if(!citem.is_valid(M))
			return

		// Check for required access.
		var/obj/item/card/id/current_id = M.wear_id
		if(citem.req_access && citem.req_access > 0)
			if(!(istype(current_id) && (citem.req_access in current_id.access)))
				continue

		// Check for required job title.
		if(citem.req_titles && citem.req_titles.len > 0)
			var/has_title
			var/current_title = M.mind.role_alt_title ? M.mind.role_alt_title : M.mind.assigned_role
			for(var/title in citem.req_titles)
				if(title == current_title)
					has_title = 1
					break
			if(!has_title)
				continue

		// ID cards and PDAs are applied directly to the existing object rather than spawned fresh.
		var/obj/item/existing_item
		if(citem.item_path == /obj/item/card/id && istype(current_id)) //Set earlier.
			existing_item = M.wear_id
		else if(citem.item_path == /obj/item/device/pda)
			existing_item = locate(/obj/item/device/pda) in M.contents

		// Spawn and equip the item.
		if(existing_item)
			citem.apply_to_item(existing_item)
		else
			place_custom_item(M,citem)

// Places the item on the target mob.
/proc/place_custom_item(mob/living/carbon/human/M, datum/custom_item/citem)

	if(!citem) return
	var/obj/item/newitem = citem.spawn_item(M.loc)

	if(M.equip_to_appropriate_slot(newitem))
		return newitem

	if(M.equip_to_storage(newitem))
		return newitem

	return newitem
