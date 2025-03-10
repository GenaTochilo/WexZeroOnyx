/obj/machinery/computer/teleporter
	name = "Teleporter Control Console"
	desc = "Used to control a linked teleportation hub and station."
	icon_keyboard = "teleport_key"
	icon_screen = "teleport"
	circuit = /obj/item/circuitboard/teleporter
	dir = 4
	var/obj/machinery/teleport/station/station = null
	var/obj/machinery/teleport/hub/hub = null
	var/obj/item/locked = null
	var/id = null
	var/one_time_use = 0 //Used for one-time-use teleport cards (such as clown planet coordinates.)
						 //Setting this to 1 will set src.locked to null after a player enters the portal and will not allow hand-teles to open portals to that location.

/obj/machinery/computer/teleporter/New()
	id = "[random_id(/obj/machinery/computer/teleporter, 1000, 9999)]"
	..()
	underlays.Cut()
	underlays += image('icons/obj/stationobjs.dmi', icon_state = "telecomp-wires")
	return

/obj/machinery/computer/teleporter/Initialize()
	. = ..()
	station = locate(/obj/machinery/teleport/station, get_step(src, dir))
	if(station)
		hub = locate(/obj/machinery/teleport/hub, get_step(station, dir))

	if(istype(station))
		station.com = hub
		station.set_dir(dir)

	if(istype(hub))
		hub.com = src
		hub.set_dir(dir)

/obj/machinery/computer/teleporter/_examine_text(mob/user)
	. = ..()
	if(locked)
		var/turf/T = get_turf(locked)
		. += "\n"
		. += SPAN("notice", "The console is locked on to \[[T.loc.name]\].")


/obj/machinery/computer/teleporter/attackby(I as obj, mob/living/user as mob)
	if(istype(I, /obj/item/card/data/))
		var/obj/item/card/data/C = I
		if(stat & (NOPOWER|BROKEN) & (C.function != "teleporter"))
			attack_hand()

		var/obj/L = null

		for(var/obj/effect/landmark/sloc in GLOB.landmarks_list)
			if(sloc.name != C.data)
				continue
			if(locate(/mob/living) in sloc.loc)
				continue
			L = sloc
			break

		if(!L)
			L = locate("landmark*[C.data]") // use old stype


		if(istype(L, /obj/effect/landmark/) && istype(L.loc, /turf))
			to_chat(usr, "You insert the coordinates into the machine.")
			to_chat(usr, "A message flashes across the screen reminding the traveller that the nuclear authentication disk is to remain on the [station_name()] at all times.")
			qdel(I)

			if(C.data == "Clown Land")
				//whoops
				for(var/mob/O in hearers(src, null))
					O.show_message(SPAN("warning", "Incoming bluespace portal detected, unable to lock in."), 2)

				for(var/obj/machinery/teleport/hub/H in range(1))
					var/amount = rand(2,5)
					for(var/i=0;i<amount;i++)
						new /mob/living/simple_animal/hostile/carp(get_turf(H))
				//
			else
				for(var/mob/O in hearers(src, null))
					O.show_message(SPAN("notice", "Locked In"), 2)
				locked = L
				one_time_use = 1

			add_fingerprint(usr)
	else
		..()

	return

/obj/machinery/teleport/station/attack_ai()
	attack_hand()

/obj/machinery/computer/teleporter/attack_hand(mob/user)
	if(..()) return

	/* Ghosts can't use this one because it's a direct selection */
	if(isobserver(user)) return

	var/list/L = list()
	var/list/areaindex = list()

	for(var/obj/item/device/radio/beacon/R in world)
		var/turf/T = get_turf(R)
		if (!T)
			continue
		if(!(T.z in GLOB.using_map.get_levels_without_trait(ZTRAIT_SEALED)))
			continue
		var/tmpname = T.loc.name
		if(areaindex[tmpname])
			tmpname = "[tmpname] ([++areaindex[tmpname]])"
		else
			areaindex[tmpname] = 1
		L[tmpname] = R

	for (var/obj/item/implant/tracking/I in world)
		if (!I.implanted || !ismob(I.loc))
			continue
		else
			var/mob/M = I.loc
			if (M.stat == 2)
				if (M.timeofdeath + 6000 < world.time)
					continue
			var/turf/T = get_turf(M)
			if(!T)
				continue
			if(!(T.z in GLOB.using_map.get_levels_without_trait(ZTRAIT_SEALED)))
				continue
			var/tmpname = M.real_name
			if(areaindex[tmpname])
				tmpname = "[tmpname] ([++areaindex[tmpname]])"
			else
				areaindex[tmpname] = 1
			L[tmpname] = I

	var/desc = input("Please select a location to lock in.", "Locking Computer") in L|null
	if(!desc)
		return
	if(get_dist(src, usr) > 1 && !issilicon(usr))
		return

	playsound(src.loc, 'sound/signals/typing3.ogg', 25)

	locked = L[desc]
	for(var/mob/O in hearers(src, null))
		O.show_message(SPAN("notice", "Locked In"), 2)
	return

/obj/machinery/computer/teleporter/verb/set_id(t as text)
	set category = "Object"
	set name = "Set teleporter ID"
	set src in oview(1)
	set desc = "ID Tag:"

	if(stat & (NOPOWER|BROKEN) || !istype(usr,/mob/living))
		return
	if(t)
		src.id = t
	return

/proc/find_loc(obj/R as obj)
	if (!R)	return null
	var/turf/T = R.loc
	while(!istype(T, /turf))
		T = T.loc
		if(!T || istype(T, /area))	return null
	return T

/obj/machinery/teleport
	name = "teleport"
	icon = 'icons/obj/stationobjs.dmi'
	density = 1
	anchored = 1.0
	var/lockeddown = 0


/obj/machinery/teleport/hub
	name = "teleporter hub"
	desc = "It's the hub of a teleporting machine."
	density = FALSE
	icon_state = "tele0"
	dir = 4
	idle_power_usage = 10 WATTS
	active_power_usage = 2 KILO WATTS
	var/obj/machinery/computer/teleporter/com


/obj/machinery/teleport/hub/New()
	..()
	underlays.Cut()
	underlays += image('icons/obj/stationobjs.dmi', icon_state = "tele-wires")

/obj/machinery/teleport/hub/Crossed(M as mob|obj)
	if(src.icon_state == "tele1")
		teleport(M)
		use_power_oneoff(5000)

/obj/machinery/teleport/hub/proc/teleport(atom/movable/M as mob|obj)
	if(!com)
		return
	if(QDELETED(com.locked))
		com.locked = null // If com is still locked to a deleted item
		for(var/mob/O in hearers(src, null))
			O.show_message(SPAN("warning", "Failure: Cannot authenticate locked on coordinates. Please reinstate coordinate matrix."))
		return
	do_teleport(M, com.locked)
	if(com.one_time_use) //Make one-time-use cards only usable one time!
		com.one_time_use = 0
		com.locked = null
	return

/obj/machinery/teleport/station
	name = "station"
	desc = "It's the station thingy of a teleport thingy." //seriously, wtf.
	icon_state = "controller"
	dir = 4
	var/active = 0
	var/engaged = 0
	idle_power_usage = 10 WATTS
	active_power_usage = 2 KILO WATTS
	var/obj/machinery/teleport/hub/com

/obj/machinery/teleport/station/New()
	..()
	overlays.Cut()
	overlays += image('icons/obj/stationobjs.dmi', icon_state = "controller-wires")

/obj/machinery/teleport/station/attackby(obj/item/W)
	attack_hand()

/obj/machinery/teleport/station/attack_ai()
	attack_hand()

/obj/machinery/teleport/station/attack_hand()
	if(engaged)
		disengage()
	else
		engage()

/obj/machinery/teleport/station/proc/engage()
	if(stat & (BROKEN|NOPOWER))
		return

	if(com)
		com.icon_state = "tele1"
		use_power_oneoff(5000)
		update_use_power(POWER_USE_ACTIVE)
		com.update_use_power(POWER_USE_ACTIVE)
		for(var/mob/O in hearers(src, null))
			O.show_message(SPAN("notice", "Teleporter engaged!"), 2)
	src.add_fingerprint(usr)
	src.engaged = 1
	return

/obj/machinery/teleport/station/proc/disengage()
	if(stat & (BROKEN|NOPOWER))
		return

	if(com)
		com.icon_state = "tele0"
		com.update_use_power(POWER_USE_IDLE)
		update_use_power(POWER_USE_IDLE)
		audible_message(SPAN("notice", "Teleporter disengaged!"))
	src.add_fingerprint(usr)
	src.engaged = 0
	return

/obj/machinery/teleport/station/update_icon()
	if(stat & NOPOWER)
		icon_state = "controller-p"

		if(com)
			com.icon_state = "tele0"
	else
		icon_state = "controller"
