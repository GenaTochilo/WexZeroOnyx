/obj/item/organ/internal/cell
	name = "microbattery"
	desc = "A small, powerful cell for use in fully prosthetic bodies."
	icon = 'icons/mob/human_races/organs/cyber.dmi'
	icon_state = "cell"
	dead_icon = "cell-br"
	organ_tag = BP_CELL
	parent_organ = BP_CHEST
	vital = 1
	override_species_icon = TRUE
	var/open
	var/obj/item/cell/cell = /obj/item/cell/high
	//at 0.8 completely depleted after 60ish minutes of constant walking or 130 minutes of standing still
	var/servo_cost = 0.8


/obj/item/organ/internal/cell/New()
	robotize()
	if(ispath(cell))
		cell = new cell(src)
	..()

/obj/item/organ/internal/cell/proc/percent()
	if(!cell)
		return 0
	return get_charge()/cell.maxcharge * 100

/obj/item/organ/internal/cell/proc/get_charge()
	if(!cell)
		return 0
	if(status & ORGAN_DEAD)
		return 0
	return round(cell.charge*(1 - damage/max_damage))

/obj/item/organ/internal/cell/proc/check_charge(amount)
	return get_charge() >= amount

/obj/item/organ/internal/cell/proc/use(amount)
	if(check_charge(amount))
		cell.use(amount)
		return 1

/obj/item/organ/internal/cell/think()
	..()
	if(!owner)
		return
	if(owner.stat == DEAD)	//not a drain anymore
		return
	if(!is_usable())
		owner.Paralyse(3)
		return
	var/standing = !owner.lying && !owner.buckled //on the edge
	var/drop
	if(!check_charge(servo_cost)) //standing is pain
		drop = 1
	else if(standing)
		use(servo_cost)
		if(world.time - owner.l_move_time < 15) //so is
			if(!use(servo_cost))
				drop = 1
	if(drop)
		if(standing)
			to_chat(owner, SPAN("warning", "You don't have enough energy to stand!"))
		owner.Weaken(2)

/obj/item/organ/internal/cell/emp_act(severity)
	..()
	if(cell)
		cell.emp_act(severity)

/obj/item/organ/internal/cell/attackby(obj/item/W, mob/user)
	if(isScrewdriver(W))
		if(open)
			open = 0
			to_chat(user, SPAN("notice", "You screw the battery panel in place."))
		else
			open = 1
			to_chat(user, SPAN("notice", "You unscrew the battery panel."))

	if(isCrowbar(W))
		if(open)
			if(cell)
				user.pick_or_drop(cell)
				to_chat(user, SPAN("notice", "You remove \the [cell] from \the [src]."))
				cell = null

	if (istype(W, /obj/item/cell))
		if(open)
			if(cell)
				to_chat(user, SPAN("warning", "There is a power cell already installed."))
			else if(user.drop(W, src))
				cell = W
				to_chat(user, SPAN("notice", "You insert \the [cell]."))

/obj/item/organ/internal/cell/replaced()
	..()
	// This is very ghetto way of rebooting an IPC. TODO better way.
	// It's time to do it. This code doesn't allow to resurrect a organic human this way.
	if(owner && owner.stat == DEAD && BP_IS_ROBOTIC(owner.organs_by_name[parent_organ]))
		owner.set_stat(CONSCIOUS)
		owner.visible_message(SPAN_DANGER("\The [owner] twitches visibly!"))

/obj/item/organ/internal/cell/listen()
	if(get_charge())
		return "faint hum of the power bank"

// Used for an MMI or posibrain being installed into a human.
/obj/item/organ/internal/mmi_holder
	name = "brain interface"
	icon = 'icons/mob/human_races/organs/cyber.dmi'
	icon_state = "brain-prosthetic"
	organ_tag = BP_BRAIN
	parent_organ = BP_HEAD
	vital = 1
	override_species_icon = TRUE
	var/obj/item/device/mmi/stored_mmi
	var/datum/mind/persistantMind //Mind that the organ will hold on to after being removed, used for transfer_and_delete
	var/ownerckey // used in the event the owner is out of body

/obj/item/organ/internal/mmi_holder/Destroy()
	stored_mmi = null
	return ..()

/obj/item/organ/internal/mmi_holder/New(mob/living/carbon/human/new_owner, internal)
	..(new_owner, internal)
	if(!stored_mmi)
		stored_mmi = new(src)
	sleep(-1)
	update_from_mmi()
	persistantMind = owner.mind
	ownerckey = owner.ckey

/obj/item/organ/internal/mmi_holder/proc/update_from_mmi()

	if(!stored_mmi.brainmob)
		stored_mmi.brainmob = new(stored_mmi)
		stored_mmi.brainobj = new(stored_mmi)
		stored_mmi.brainmob.container = stored_mmi
		stored_mmi.brainmob.real_name = owner.real_name
		stored_mmi.brainmob.SetName(stored_mmi.brainmob.real_name)
		stored_mmi.SetName("[initial(stored_mmi.name)] ([owner.real_name])")

	if(!owner) return

	name = stored_mmi.name
	desc = stored_mmi.desc
	icon = stored_mmi.icon

	stored_mmi.icon_state = "mmi_full"
	icon_state = stored_mmi.icon_state

	if(owner && owner.stat == DEAD)
		owner.set_stat(CONSCIOUS)
		owner.switch_from_dead_to_living_mob_list()
		owner.visible_message(SPAN("danger", "\The [owner] twitches visibly!"))

/obj/item/organ/internal/mmi_holder/cut_away(mob/living/user)
	var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
	if(istype(parent))
		removed(user, 0)
		parent.implants += transfer_and_delete()

/obj/item/organ/internal/mmi_holder/removed()
	if(owner && owner.mind)
		persistantMind = owner.mind
		if(owner.ckey)
			ownerckey = owner.ckey
	..()

/obj/item/organ/internal/mmi_holder/proc/transfer_and_delete()
	if(stored_mmi)
		. = stored_mmi
		stored_mmi.forceMove(src.loc)
		if(persistantMind)
			persistantMind.transfer_to(stored_mmi.brainmob)
		else
			var/response = input(find_dead_player(ownerckey, 1), "Your [initial(stored_mmi.name)] has been removed from your body. Do you wish to return to life?", "Robotic Rebirth") as anything in list("Yes", "No")
			if(response == "Yes")
				persistantMind.transfer_to(stored_mmi.brainmob)
		stored_mmi.update_icon()
	qdel(src)
