
/obj/item/backwear
	name = "backwear"
	desc = "An unwieldy, heavy backpack."
	slot_flags = SLOT_BACK
	icon = 'icons/obj/backwear.dmi'
	icon_state = null
	w_class = ITEM_SIZE_HUGE
	force = 17.5
	mod_weight = 1.75
	mod_reach = 1.0
	mod_handy = 0.5
	var/base_icon = null
	var/gear_detachable = FALSE
	var/obj/item/gear = null

/obj/item/backwear/Initialize()
	. = ..()
	if(ispath(gear))
		if(!gear_detachable)
			gear = new gear(src, src)
		else
			gear = new gear(src)
	update_icon()

/obj/item/backwear/Destroy()
	. = ..()
	if(gear)
		if(gear_detachable)
			gear.forceMove(get_turf(src.loc))
			gear.update_icon()
			gear = null
		else
			QDEL_NULL(gear)

/obj/item/backwear/reagent/update_icon()
	..()
	if(!gear_detachable)
		if(gear && gear.loc == src)
			icon_state = "[base_icon]1"
			return
		icon_state = "[base_icon]0"
		return
	icon_state = base_icon

/obj/item/backwear/attackby(obj/item/W, mob/user)
	if(W == gear)
		reattach_gear(user)
		return
	..()

/obj/item/backwear/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return 0
	return 1

/obj/item/backwear/proc/reattach_gear(mob/user)
	if(!gear)
		return
	if(gear.loc == src)
		return

	if(ismob(gear.loc))
		var/mob/M = gear.loc
		M.drop(gear, src, TRUE)
	else
		gear.forceMove(src)
	if(user)
		to_chat(user, SPAN("notice", "\The [gear] snaps back into \the [src]."))
	update_icon()

/obj/item/backwear/proc/detach_gear(mob/user)
	if(!gear_detachable)
		return
	if(!gear)
		return
	if(gear.loc != src)
		to_chat(user, SPAN("warning", "You need to put \the [gear] back first."))
		return
	to_chat(user, SPAN("notice", "You detach \the [gear] from \the [src]."))
	gear.forceMove(get_turf(src.loc))
	gear.update_icon()
	gear = null

/obj/item/backwear/verb/grab_gear()
	set name = "Grab Gear"
	set category = "Object"

	if(istype(usr, /mob/living/carbon/human))
		resolve_grab_gear(usr)

/obj/item/backwear/proc/resolve_grab_gear(mob/living/carbon/human/user)
	if(!gear)
		to_chat(user, SPAN("warning", "\The [src] has no additional gear."))
		return 0
	if(gear.loc != src)
		reattach_gear(user)
		return 0
	if(!slot_check())
		to_chat(user, SPAN("warning", "You need to equip \the [src] before taking out \the [gear]."))
	else
		if(!usr.put_in_hands(gear))
			to_chat(user, SPAN("warning", "You need a free hand to hold \the [gear]!"))
			return 0
		update_icon()
	return 1

/obj/item/backwear/dropped(mob/user)
	..()
	reattach_gear(user)

/obj/item/backwear/attack_hand(mob/user)
	if(loc == user)
		grab_gear()
	else
		..()

/obj/item/backwear/MouseDrop()
	if(ismob(loc))
		if(!CanMouseDrop(src))
			return
		var/mob/M = loc
		if(!M.drop(src))
			return
		add_fingerprint(usr)
		M.pick_or_drop(src)


///// These use power cells to function
/obj/item/backwear/powered
	var/obj/item/cell/bcell = null

/obj/item/backwear/powered/update_icon()
	..()
	overlays.Cut()
	if(!bcell)
		overlays += image(icon = 'icons/obj/backwear.dmi', icon_state = "[base_icon]_nocell")

/obj/item/backwear/powered/Initialize()
	. = ..()
	if(ispath(bcell))
		bcell = new bcell(src)
	update_icon()

/obj/item/backwear/powered/Destroy()
	. = ..()
	QDEL_NULL(bcell)

/obj/item/backwear/powered/_examine_text(mob/user)
	. = ..()
	if(bcell)
		. += "\nIt has \the [bcell] installed."
		. += "\nThe charge meter reads [round(bcell.percent(), 0.1)]%"
	else
		. += "\nIt has no power cell installed!"

/obj/item/backwear/powered/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/cell))
		if(bcell)
			to_chat(user, SPAN("notice", "\The [src] already has a cell."))
		else
			if(!user.drop(W, src))
				return
			bcell = W
			to_chat(user, SPAN("notice", "You install \the [W] into \the [src]."))
			update_icon()

	else if(isScrewdriver(W))
		if(bcell)
			bcell.update_icon()
			bcell.forceMove(get_turf(src.loc))
			bcell = null
			to_chat(user, SPAN("notice", "You remove \the [W] from \the [src]."))
			update_icon()
	else
		return ..()


///// These contain reagents
/obj/item/backwear/reagent
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	var/initial_capacity = 500
	var/initial_reagent_types  // A list of reagents and their ratio relative the initial capacity. list(/datum/reagent/water = 0.5) would fill the dispenser halfway to capacity.
	var/amount_per_transfer_from_this = 10
	var/possible_transfer_amounts = "5;10;25;50;100"

/obj/item/backwear/reagent/Initialize()
	. = ..()
	create_reagents(initial_capacity)

	for(var/reagent_type in initial_reagent_types)
		var/reagent_ratio = initial_reagent_types[reagent_type]
		reagents.add_reagent(reagent_type, reagent_ratio * initial_capacity)

	if(!possible_transfer_amounts)
		src.verbs -= /obj/item/backwear/reagent/verb/set_APTFT

/obj/item/backwear/reagent/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) > 2)
		return
	. += "\n"
	. += SPAN("notice", "It contains:")
	if(reagents.reagent_list.len) // OOP be cool
		for(var/datum/reagent/R in reagents.reagent_list)
			. += "\n"
			. += SPAN("notice", "[R.volume] units of [R.name]")
	else
		. += "\n"
		. += SPAN("notice", "Nothing.")

/obj/item/backwear/reagent/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in view(1)
	var/N = input("Amount per transfer from this:","[src]") as null|anything in cached_number_list_decode(possible_transfer_amounts)
	if(N)
		amount_per_transfer_from_this = N

/obj/item/backwear/reagent/AltClick(mob/user)
	if(possible_transfer_amounts)
		if(CanPhysicallyInteract(user))
			set_APTFT()
		return
	..()

/obj/item/backwear/reagent/proc/standard_dispenser_refill(mob/user, obj/structure/reagent_dispensers/target)
	if(!istype(target))
		return 0

	if(!target.reagents || !target.reagents.total_volume)
		to_chat(user, SPAN("notice", "[target] is empty."))
		return 1

	if(reagents && !reagents.get_free_space())
		to_chat(user, SPAN("notice", "[src] is full."))
		return 1

	var/trans = target.reagents.trans_to_obj(src, target.amount_per_transfer_from_this)
	playsound(target, 'sound/effects/using/sink/fast_filling1.ogg', 75, TRUE)
	to_chat(user, SPAN("notice", "You fill [src] with [trans] units of the contents of [target]."))
	return 1
