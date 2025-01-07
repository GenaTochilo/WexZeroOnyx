// Updated version of old powerswitch by Atlantis
// Has better texture, and is now considered electronic device
// AI has ability to toggle it in 5 seconds
// Humans need 30 seconds (AI is faster when it comes to complex electronics)
// Used for advanced grid control (read: Substations)

// TODO(rufus): update this whole machine, from magically appearing/disappearing cables
//   to cooldowns and unsanitized input (fellow hackermans, it's time to put your `alert("LMAO GET PWNED")` to work)
//   Current system of spawning/despawning cables and artificially connecting them is hacky, although reliably served
//   us for over ten years. This could be made into a more interactive and "modern" system,
//   with electronic switching of the connection, a proper UI, ability to rig the internals with a signaller etc,
//   giving engineers and traitors more power and tools to use.
/obj/machinery/power/breakerbox
	name = "Breaker Box"
	icon = 'icons/obj/power.dmi'
	icon_state = "bbox_off"
	//directwired = 0
	var/icon_state_on = "bbox_on"
	var/icon_state_off = "bbox_off"
	density = 1
	anchored = 1
	var/on = 0
	var/busy = 0
	var/directions = list(1,2,4,8,5,6,9,10)
	var/RCon_tag = "NO_TAG"
	var/update_locked = 0

/obj/machinery/power/breakerbox/Destroy()
	. = ..()
	for(var/datum/nano_module/rcon/R in world)
		R.FindDevices()

/obj/machinery/power/breakerbox/activated
	icon_state = "bbox_on"

	// Enabled on server startup. Used in substations to keep them in bypass mode.
/obj/machinery/power/breakerbox/activated/Initialize()
	set_state(1)
	. = ..()

/obj/machinery/power/breakerbox/_examine_text(mob/user)
	. = ..()
	. += "\n"
	. += "Large machine with heavy duty switching circuits used for advanced grid control."
	. += "\n"
	if(on)
		. += SPAN("good", "It seems to be online.")
	else
		. += SPAN("warning", "It seems to be offline.")

/obj/machinery/power/breakerbox/attack_ai(mob/user)
	if(update_locked)
		to_chat(user, SPAN("warning", "System locked. Please try again later."))
		return

	if(busy)
		to_chat(user, SPAN("warning", "System is busy. Please wait until current operation is finished before changing power settings."))
		return

	busy = 1
	to_chat(user, SPAN("good", "Updating power settings.."))
	if(do_after(user, 50, src))
		set_state(!on)
		to_chat(user, SPAN("good", "Update Completed. New setting:[on ? "on": "off"]"))
		update_locked = 1
		spawn(600)
			update_locked = 0
	busy = 0


/obj/machinery/power/breakerbox/attack_hand(mob/user)
	if(update_locked)
		to_chat(user, SPAN("warning", "System locked. Please try again later."))
		return

	if(busy)
		to_chat(user, SPAN("warning", "System is busy. Please wait until current operation is finished before changing power settings."))
		return

	busy = 1
	for(var/mob/O in viewers(user))
		O.show_message(SPAN("warning", "\The [user] started reprogramming \the [src]!"), VISIBLE_MESSAGE)

	if(do_after(user, 50,src))
		set_state(!on)
		user.visible_message(
		SPAN("notice", "[user.name] [on ? "enabled" : "disabled"] the breaker box!"),
		SPAN("notice", "You [on ? "enabled" : "disabled"] the breaker box!"))
		update_locked = 1
		spawn(600)
			update_locked = 0
	busy = 0

/obj/machinery/power/breakerbox/attackby(obj/item/W as obj, mob/user as mob)
	if(isMultitool(W))
		var/newtag = input(user, "Enter new RCON tag. Use \"NO_TAG\" to disable RCON or leave empty to cancel.", "SMES RCON system") as text
		if(newtag)
			RCon_tag = newtag
			to_chat(user, SPAN("notice", "You changed the RCON tag to: [newtag]"))





/obj/machinery/power/breakerbox/proc/set_state(state)
	on = state
	if(on)
		icon_state = icon_state_on
		var/list/connection_dirs = list()
		for(var/direction in directions)
			for(var/obj/structure/cable/C in get_step(src,direction))
				if(C.d1 == turn(direction, 180) || C.d2 == turn(direction, 180))
					connection_dirs += direction
					break

		for(var/direction in connection_dirs)
			var/obj/structure/cable/C = new /obj/structure/cable(src.loc)
			C.d1 = 0
			C.d2 = direction
			C.icon_state = "[C.d1]-[C.d2]"
			C.breaker_box = src

			var/datum/powernet/PN = new()
			PN.add_cable(C)

			C.mergeConnectedNetworks(C.d2)
			C.mergeConnectedNetworksOnTurf()

			if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
				C.mergeDiagonalsNetworks(C.d2)

	else
		icon_state = icon_state_off
		for(var/obj/structure/cable/C in src.loc)
			qdel(C)

// Used by RCON to toggle the breaker box.
/obj/machinery/power/breakerbox/proc/auto_toggle()
	if(!update_locked)
		set_state(!on)
		update_locked = 1
		spawn(600)
			update_locked = 0

/obj/machinery/power/breakerbox/Process()
	return 1
