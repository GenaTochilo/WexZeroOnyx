/mob/living/carbon/human
	hud_type = /datum/hud/human

/datum/hud/human/FinalizeInstantiation(ui_style='icons/mob/screen1_white.dmi', ui_color = "#ffffff", ui_alpha = 255)
	var/mob/living/carbon/human/target = mymob
	var/datum/hud_data/hud_data
	if(!istype(target))
		hud_data = new()
	else
		hud_data = target.species.hud

	if(hud_data.icon)
		ui_style = hud_data.icon

	src.adding = list()
	src.other = list()
	src.hotkeybuttons = list() //These can be disabled for hotkey usersx

	var/list/hud_elements = list()
	var/obj/screen/using
	var/obj/screen/inventory/inv_box

	// Draw the various inventory equipment slots.
	var/has_hidden_gear
	for(var/gear_slot in hud_data.gear)

		inv_box = new /obj/screen/inventory()
		inv_box.icon = ui_style
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha

		var/list/slot_data =  hud_data.gear[gear_slot]
		inv_box.SetName(gear_slot)
		inv_box.screen_loc =  slot_data["loc"]
		inv_box.slot_id =     slot_data["slot"]
		inv_box.icon_state =  slot_data["state"]

		if(slot_data["dir"])
			inv_box.set_dir(slot_data["dir"])

		if(slot_data["toggle"])
			src.other += inv_box
			has_hidden_gear = TRUE
		else
			src.adding += inv_box

	if(has_hidden_gear)
		using = new /obj/screen()
		using.SetName("toggle")
		using.icon = ui_style
		using.icon_state = "other"
		using.screen_loc = ui_inventory
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

	// Draw the attack intent dialogue.
	if(hud_data.has_a_intent)

		using = new /obj/screen/intent()
		using.icon = ui_style
		src.adding += using
		action_intent = using

		hud_elements |= using

	if(hud_data.has_m_intent)
		using = new /obj/screen()
		using.SetName("mov_intent")
		using.icon = ui_style
		using.icon_state = (mymob.m_intent == M_RUN ? "running" : "walking")
		using.screen_loc = ui_movi
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using
		move_intent = using

	if(hud_data.has_drop)
		using = new /obj/screen()
		using.SetName("drop")
		using.icon = ui_style
		using.icon_state = "act_drop"
		using.screen_loc = ui_drop_throw
		using.color = ui_color
		using.alpha = ui_alpha
		src.hotkeybuttons += using

	if(hud_data.has_rest)
		using = new /obj/screen()
		using.SetName("rest")
		using.icon = ui_style
		using.icon_state = "rest"
		using.screen_loc = ui_rest_act
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using


	if(hud_data.has_hands)

		using = new /obj/screen()
		using.SetName("equip")
		using.icon = ui_style
		using.icon_state = "act_equip"
		using.screen_loc = ui_equip
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

		inv_box = new /obj/screen/inventory()
		inv_box.SetName("r_hand")
		inv_box.icon = ui_style
		inv_box.icon_state = "r_hand_inactive"
		if(mymob && !mymob.hand)	//This being FALSE or null means the right hand is in use
			inv_box.icon_state = "r_hand_active"
		inv_box.screen_loc = ui_rhand
		inv_box.slot_id = slot_r_hand
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha

		src.r_hand_hud_object = inv_box
		src.adding += inv_box

		inv_box = new /obj/screen/inventory()
		inv_box.SetName("l_hand")
		inv_box.icon = ui_style
		inv_box.icon_state = "l_hand_inactive"
		if(mymob && mymob.hand)	//This being TRUE means the left hand is in use
			inv_box.icon_state = "l_hand_active"
		inv_box.screen_loc = ui_lhand
		inv_box.slot_id = slot_l_hand
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha
		src.l_hand_hud_object = inv_box
		src.adding += inv_box

		using = new /obj/screen/inventory()
		using.SetName("hand")
		using.icon = ui_style
		using.icon_state = "hand1"
		using.screen_loc = ui_swaphand1
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

		using = new /obj/screen/inventory()
		using.SetName("hand")
		using.icon = ui_style
		using.icon_state = "hand2"
		using.screen_loc = ui_swaphand2
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

	if(hud_data.has_resist)
		using = new /obj/screen()
		using.SetName("resist")
		using.icon = ui_style
		using.icon_state = "act_resist"
		using.screen_loc = ui_pull_resist
		using.color = ui_color
		using.alpha = ui_alpha
		src.hotkeybuttons += using

	if(hud_data.has_throw)
		mymob.throw_icon = new /obj/screen()
		mymob.throw_icon.icon = ui_style
		mymob.throw_icon.icon_state = "act_throw_off"
		mymob.throw_icon.SetName("throw")
		mymob.throw_icon.screen_loc = ui_drop_throw
		mymob.throw_icon.color = ui_color
		mymob.throw_icon.alpha = ui_alpha
		src.hotkeybuttons += mymob.throw_icon
		hud_elements |= mymob.throw_icon

		mymob.pullin = new /obj/screen()
		mymob.pullin.icon = ui_style
		mymob.pullin.icon_state = "pull0"
		mymob.pullin.SetName("pull")
		mymob.pullin.screen_loc = ui_pull_resist
		src.hotkeybuttons += mymob.pullin
		hud_elements |= mymob.pullin

	if(hud_data.has_block)
		mymob.block_icon = new /obj/screen()
		mymob.block_icon.icon = ui_style
		mymob.block_icon.icon_state = "act_block0"
		mymob.block_icon.SetName("block")
		mymob.block_icon.screen_loc = ui_block
		mymob.block_icon.color = ui_color
		mymob.block_icon.alpha = ui_alpha
		src.hotkeybuttons += mymob.block_icon
		hud_elements |= mymob.block_icon

	if(hud_data.has_blockswitch)
		mymob.blockswitch_icon = new /obj/screen()
		mymob.blockswitch_icon.icon = ui_style
		mymob.blockswitch_icon.icon_state = "act_blockswitch0"
		mymob.blockswitch_icon.SetName("blockswitch")
		mymob.blockswitch_icon.screen_loc = ui_blockswitch
		mymob.blockswitch_icon.color = ui_color
		mymob.blockswitch_icon.alpha = ui_alpha
		src.hotkeybuttons += mymob.blockswitch_icon
		hud_elements |= mymob.blockswitch_icon

	if(hud_data.has_internals)
		mymob.internals = new /obj/screen()
		mymob.internals.icon = ui_style
		mymob.internals.icon_state = "internal0"
		mymob.internals.SetName("internal")
		mymob.internals.screen_loc = ui_internal
		hud_elements |= mymob.internals

	if(hud_data.has_warnings)
		mymob.oxygen = new /obj/screen()
		mymob.oxygen.icon = ui_style
		mymob.oxygen.icon_state = "oxy0"
		mymob.oxygen.SetName("oxygen")
		mymob.oxygen.screen_loc = ui_oxygen
		hud_elements |= mymob.oxygen

		mymob.toxin = new /obj/screen()
		mymob.toxin.icon = ui_style
		mymob.toxin.icon_state = "tox0"
		mymob.toxin.SetName("toxin")
		mymob.toxin.screen_loc = ui_toxin
		hud_elements |= mymob.toxin

		mymob.fire = new /obj/screen()
		mymob.fire.icon = ui_style
		mymob.fire.icon_state = "fire0"
		mymob.fire.SetName("fire")
		mymob.fire.screen_loc = ui_fire
		hud_elements |= mymob.fire

	if(hud_data.has_pain)
		mymob.pains = new /obj/screen()
		mymob.pains.icon = ui_style
		mymob.pains.icon_state = "pain0"
		mymob.pains.SetName("pain")
		mymob.pains.screen_loc = ui_health
		hud_elements |= mymob.pains

	if(hud_data.has_health)
		mymob.healths = new /obj/screen()
		mymob.healths.icon = ui_style
		mymob.healths.icon_state = "health0"
		mymob.healths.SetName("health")
		mymob.healths.screen_loc = ui_health
		hud_elements |= mymob.healths

	if(hud_data.has_pressure)
		mymob.pressure = new /obj/screen()
		mymob.pressure.icon = ui_style
		mymob.pressure.icon_state = "pressure0"
		mymob.pressure.SetName("pressure")
		mymob.pressure.screen_loc = ui_pressure
		hud_elements |= mymob.pressure

	if(hud_data.has_bodytemp)
		mymob.bodytemp = new /obj/screen()
		mymob.bodytemp.icon = ui_style
		mymob.bodytemp.icon_state = "temp1"
		mymob.bodytemp.SetName("body temperature")
		mymob.bodytemp.screen_loc = ui_temp
		hud_elements |= mymob.bodytemp

	if(target.isSynthetic())
		target.cells = new /obj/screen()
		target.cells.icon = 'icons/mob/screen1_robot.dmi'
		target.cells.icon_state = "charge-empty"
		target.cells.SetName("cell")
		target.cells.screen_loc = ui_nutrition
		hud_elements |= target.cells

	else if(hud_data.has_nutrition)
		mymob.nutrition_icon = new /obj/screen()
		mymob.nutrition_icon.icon = ui_style
		mymob.nutrition_icon.icon_state = "nutrition0"
		mymob.nutrition_icon.SetName("nutrition")
		mymob.nutrition_icon.screen_loc = ui_nutrition
		hud_elements |= mymob.nutrition_icon

	if(hud_data.has_poise)
		mymob.poise_icon = new /obj/screen()
		mymob.poise_icon.icon = 'icons/mob/screen1_poise.dmi'
		mymob.poise_icon.icon_state = "50"
		mymob.poise_icon.SetName("poise")
		mymob.poise_icon.screen_loc = ui_health
		hud_elements |= mymob.poise_icon


	mymob.pain = new /obj/screen/fullscreen/pain( null )
	hud_elements |= mymob.pain

	mymob.zone_sel = new /obj/screen/zone_sel( null )
	mymob.zone_sel.icon = ui_style
	mymob.zone_sel.color = ui_color
	mymob.zone_sel.alpha = ui_alpha
	mymob.zone_sel.overlays.Cut()
	mymob.zone_sel.overlays += image('icons/mob/zone_sel.dmi', "[mymob.zone_sel.selecting]")
	hud_elements |= mymob.zone_sel

	//Handle the gun settings buttons
	mymob.gun_setting_icon = new /obj/screen/gun/mode(null)
	mymob.gun_setting_icon.icon = ui_style
	mymob.gun_setting_icon.color = ui_color
	mymob.gun_setting_icon.alpha = ui_alpha
	hud_elements |= mymob.gun_setting_icon

	mymob.item_use_icon = new /obj/screen/gun/item(null)
	mymob.item_use_icon.icon = ui_style
	mymob.item_use_icon.color = ui_color
	mymob.item_use_icon.alpha = ui_alpha

	mymob.gun_move_icon = new /obj/screen/gun/move(null)
	mymob.gun_move_icon.icon = ui_style
	mymob.gun_move_icon.color = ui_color
	mymob.gun_move_icon.alpha = ui_alpha

	mymob.radio_use_icon = new /obj/screen/gun/radio(null)
	mymob.radio_use_icon.icon = ui_style
	mymob.radio_use_icon.color = ui_color
	mymob.radio_use_icon.alpha = ui_alpha

	mymob.client.screen = list()

	mymob.client.screen += hud_elements
	mymob.client.screen += src.adding + src.hotkeybuttons
	inventory_shown = FALSE

/mob/living/carbon/human/verb/toggle_hotkey_verbs()
	set category = "OOC"
	set name = "Toggle hotkey buttons"
	set desc = "This disables or enables the user interface buttons which can be used with hotkeys."

	if(hud_used.hotkey_ui_hidden)
		client.screen += hud_used.hotkeybuttons
		hud_used.hotkey_ui_hidden = FALSE
	else
		client.screen -= hud_used.hotkeybuttons
		hud_used.hotkey_ui_hidden = TRUE

/mob/living/carbon/human/rejuvenate()
	. = ..()
	full_pain = 0
	// And restore all internal organs...
	for (var/obj/item/organ/internal/I in internal_organs)
		I.rejuvenate()
