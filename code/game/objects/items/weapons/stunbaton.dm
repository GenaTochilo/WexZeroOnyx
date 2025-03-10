//replaces our stun baton code with /tg/station's code
/obj/item/melee/baton
	name = "stunbaton"
	desc = "A stun baton for incapacitating people with."
	description_info = "The baton needs to be turned on to apply the stunning effect. Use it in your hand to toggle it on or off. \
	To stun your target with the enabled baton, use the 'help' intent. \
	If your intent is set to 'harm', you will inflict brute damage, regardless of the enabled state. \
	Each stun reduces the baton's charge, which can be replenished by putting it inside a weapon recharger."
	icon_state = "stunbaton"
	item_state = "baton"
	icon = 'icons/obj/weapons.dmi'
	slot_flags = SLOT_BELT
	force = 15
	sharp = 0
	edge = 0
	throwforce = 7
	w_class = ITEM_SIZE_NORMAL
	mod_weight = 1.25
	mod_reach = 1.25
	mod_handy = 1.45
	origin_tech = list(TECH_COMBAT = 2)
	attack_verb = list("beaten")
	var/stunforce = 6
	var/agonyforce = 75
	var/status = 0		//whether the thing is on or not
	var/obj/item/cell/bcell
	var/hitcost = 10

/obj/item/melee/baton/loaded
	bcell = /obj/item/cell/device/high

/obj/item/melee/baton/New()
	if(ispath(bcell))
		bcell = new bcell(src)
		update_icon()
	..()

/obj/item/melee/baton/Destroy()
	if(bcell && !ispath(bcell))
		qdel(bcell)
		bcell = null
	return ..()

/obj/item/melee/baton/proc/deductcharge(chrgdeductamt)
	if(bcell)
		if(bcell.checked_use(chrgdeductamt))
			return 1
		else
			status = 0
			update_icon()
			return 0
	return null

/obj/item/melee/baton/update_icon()
	if(status)
		icon_state = "[initial(name)]_active"
	else if(!bcell)
		icon_state = "[initial(name)]_nocell"
	else
		icon_state = "[initial(name)]"

	if(icon_state == "[initial(name)]_active")
		set_light(0.4, 0.1, 1, 2, "#ff6a00")
	else
		set_light(0)

/obj/item/melee/baton/_examine_text(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return
	. += "\n[examine_cell()]"
	return

// Addition made by Techhead0, thanks for fullfilling the todo!
/obj/item/melee/baton/proc/examine_cell()
	if(bcell)
		return SPAN("notice", "The baton is [round(bcell.percent())]% charged.")
	else
		return SPAN("warning", "The baton does not have a power source installed.")

/obj/item/melee/baton/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/cell/device))
		if(!bcell && user.drop(W, src))
			bcell = W
			to_chat(user, SPAN("notice", "You install a cell into the [src]."))
			update_icon()
		else
			to_chat(user, SPAN("notice", "[src] already has a cell."))
	else if(isScrewdriver(W))
		if(bcell)
			bcell.update_icon()
			bcell.dropInto(loc)
			bcell = null
			to_chat(user, SPAN("notice", "You remove the cell from the [src]."))
			status = 0
			update_icon()
	else
		..()

/obj/item/melee/baton/attack_self(mob/user)
	set_status(!status, user)
	add_fingerprint(user)

/obj/item/melee/baton/proc/set_status(newstatus, mob/user)
	if(bcell && bcell.charge >= hitcost)
		if(status != newstatus)
			change_status(newstatus)
			to_chat(user, SPAN("notice", "[src] is now [status ? "on" : "off"]."))
			playsound(loc, 'sound/effects/electric/spark2.ogg', 50, 1, -1)
	else
		change_status(0)
		if(!bcell)
			to_chat(user, SPAN("warning", "[src] does not have a power source!"))
		else
			to_chat(user,  SPAN("warning", "[src] is out of charge."))

// Proc to -actually- change the status, and update the icons as well.
// Also exists to ease "helpful" admin-abuse in case an bug prevents attack_self
// to occur would appear. Hopefully it wasn't necessary.
/obj/item/melee/baton/proc/change_status(s)
	if (status != s)
		status = s
		update_icon()

/obj/item/melee/baton/attack(mob/M, mob/user)
	if(status && (MUTATION_CLUMSY in user.mutations) && prob(50))
		to_chat(user, SPAN("danger", "You accidentally hit yourself with the [src]!"))
		user.Weaken(30)
		user.Stun(30)
		deductcharge(hitcost)
		return
	return ..()

/obj/item/melee/baton/apply_hit_effect(mob/living/target, mob/living/user, hit_zone)
	if(isrobot(target))
		return ..()

	var/agony = agonyforce
	var/stun = stunforce
	var/obj/item/organ/external/affecting = null
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		affecting = H.get_organ(hit_zone)

	if(ishuman(target) && ishuman(user))
		var/mob/living/carbon/human/H = target
		var/mob/living/carbon/human/U = user
		if(H.parrying)
			if(H.handle_parry(U, src))
				return 0
		if(H.blocking)
			if(H.handle_block_weapon(U, src))
				return 0

	if(user.a_intent != I_HELP)
		. = ..()
		if (!.)	//item/attack() does it's own messaging and logs
			return 0	// item/attack() will return 1 if they hit, 0 if they missed.

		//whacking someone causes a much poorer electrical contact than deliberately prodding them.
		stun *= 0.5
		if(status)		//Checks to see if the stunbaton is on.
			agony *= 0.5	//whacking someone causes a much poorer contact than prodding them.
		else
			agony = 0	//Shouldn't really stun if it's off, should it?
		//we can't really extract the actual hit zone from ..(), unfortunately. Just act like they attacked the area they intended to.

	else if(!status)
		if(affecting)
			target.visible_message(SPAN("warning", "[target] has been prodded in the [affecting.name] with [src] by [user]. Luckily it was off."))
		else
			target.visible_message(SPAN("warning", "[target] has been prodded with [src] by [user]. Luckily it was off."))
	else
		if(affecting)
			target.visible_message(SPAN("danger", "[target] has been prodded in the [affecting.name] with [src] by [user]!"))
		else
			target.visible_message(SPAN("danger", "[target] has been prodded with [src] by [user]!"))
		playsound(loc, 'sound/weapons/Egloves.ogg', 50, 1, -1)

	//stun effects
	if(status)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.handle_tasing(agony, stun, hit_zone, src)
		else
			target.stun_effect_act(stun, agony, hit_zone, src)
		msg_admin_attack("[key_name(user)] prodded [key_name(target)] with the [src].")

		deductcharge(hitcost)
	return 0

/obj/item/melee/baton/throw_impact(hit_atom, speed)
	. = ..()
	if(isliving(hit_atom) && status && prob(50))
		var/mob/living/L = hit_atom
		L.stun_effect_act(stun_amount = rand(2,5), agony_amount = rand(10, 90), def_zone = ran_zone(BP_CHEST, 75), used_weapon = src)
		playsound(L.loc, 'sound/weapons/Egloves.ogg', 50, 1, -1)
		deductcharge(hitcost)

/obj/item/melee/baton/emp_act(severity)
	if(bcell)
		bcell.emp_act(severity)	//let's not duplicate code everywhere if we don't have to please.
	..()

// Stunbaton module for Security synthetics
/obj/item/melee/baton/robot
	name = "mounted baton"
	// TODO(rufus): remove direct reference to the robot's cell, determine the cell to use at the moment of usage and
	//   call cell procs to use charge.
	bcell = null
	hitcost = 20
	icon_state = "mounted baton"

// Addition made by Techhead0, thanks for fullfilling the todo!
/obj/item/melee/baton/robot/examine_cell(mob/user, prefix)
	. += "\n"
	. += SPAN("notice", "The baton is running off an external power supply.")

/obj/item/melee/baton/robot/attack_self(mob/user)
	var/mob/living/silicon/robot/R = user
	if(!istype(R))
		to_chat(user, SPAN("warning", "You don't seem to be able to do anything with \the [src] on your own..."))
		add_fingerprint(user)
		return
	update_cell(R)
	..()

/obj/item/melee/baton/robot/attackby(obj/item/W, mob/user)
	return

/obj/item/melee/baton/robot/apply_hit_effect(mob/living/target, mob/living/user, hit_zone)
	update_cell(isrobot(user) ? user : null) // update the status before we apply the effects
	return ..()

// Updates the baton's cell to use user's own cell
// Otherwise, if null (when the user isn't a robot), render it unuseable
/obj/item/melee/baton/robot/proc/update_cell(mob/living/silicon/robot/user)
	if (!user)
		bcell = null
		set_status(0)
	else if (!bcell || bcell != user.cell)
		// TODO(rufus): remove direct reference to the robot's cell, determine the cell to use at the moment of usage and
		//   call cell procs to use charge.
		bcell = user.cell // if it is null, nullify it anyway

// Traitor variant for Engineering synthetics.
/obj/item/melee/baton/robot/electrified_arm
	name = "electrified arm"
	icon = 'icons/obj/device.dmi'
	icon_state = "electrified_arm"

/obj/item/melee/baton/robot/electrified_arm/update_icon()
	if(status)
		icon_state = "electrified_arm_active"
		set_light(0.4, 0.1, 1, 2, "#006aff")
	else
		icon_state = "electrified_arm"
		set_light(0)

//Makeshift stun baton. Replacement for stun gloves.
/obj/item/melee/baton/cattleprod
	name = "stunprod"
	desc = "An improvised stun baton."
	icon_state = "stunprod_nocell"
	item_state = "prod"
	force = 3
	mod_weight = 1.25
	mod_reach = 1.25
	mod_handy = 1.0
	throwforce = 5
	stunforce = 4
	agonyforce = 60	//same force as a stunbaton, but uses way more charge.
	hitcost = 25
	attack_verb = list("poked")
	slot_flags = null
