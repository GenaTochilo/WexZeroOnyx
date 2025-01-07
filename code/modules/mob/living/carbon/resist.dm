/mob/living/carbon/process_resist()

	//drop && roll
	if(on_fire && !buckled)
		fire_stacks -= 1.2
		Weaken(3)
		spin(32,2)
		visible_message(
			SPAN("danger", "[src] rolls on the floor, trying to put themselves out!"),
			SPAN("notice", "You stop, drop, and roll!")
			)
		sleep(30)
		if(fire_stacks <= 0)
			visible_message(
				SPAN("danger", "[src] has successfully extinguished themselves!"),
				SPAN("notice", "You extinguish yourself.")
				)
			ExtinguishMob()
		return TRUE

	if(istype(buckled, /obj/effect/vine))
		var/obj/effect/vine/V = buckled
		spawn() V.manual_unbuckle(src)
		return TRUE

	if(..())
		return TRUE

	if(handcuffed)
		spawn() escape_handcuffs()

/mob/living/carbon/proc/escape_handcuffs()
	//if(!(last_special <= world.time)) return

	//This line represent a significant buff to grabs...
	// We don't have to check the click cooldown because /mob/living/verb/resist() has done it for us, we can simply set the delay
	setClickCooldown(100)

	if(can_break_cuffs()) //Don't want to do a lot of logic gating here.
		break_handcuffs()
		return

	var/obj/item/handcuffs/HC = handcuffed

	//A default in case you are somehow handcuffed with something that isn't an obj/item/handcuffs type
	var/breakouttime = 1200
	var/displaytime = 2 //Minutes to display in the "this will take X minutes."
	//If you are handcuffed with actual handcuffs... Well what do I know, maybe someone will want to handcuff you with toilet paper in the future...
	if(istype(HC))
		breakouttime = HC.breakouttime
		displaytime = breakouttime / 600 //Minutes

	var/mob/living/carbon/human/H = src
	if(istype(H) && H.gloves && istype(H.gloves,/obj/item/clothing/gloves/rig))
		breakouttime /= 2
		displaytime /= 2

	visible_message(
		SPAN("danger", "\The [src] attempts to remove \the [HC]!"),
		SPAN("warning", "You attempt to remove \the [HC]. (This will take around [displaytime] minutes and you need to stand still)")
		)

	if(do_after(src, breakouttime, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		if(!handcuffed || buckled)
			return
		visible_message(
			SPAN("danger", "\The [src] manages to remove \the [handcuffed]!"),
			SPAN("notice", "You successfully remove \the [handcuffed].")
			)
		drop(handcuffed, force = TRUE)

/mob/living/carbon/proc/can_break_cuffs()
	if(MUTATION_HULK in mutations)
		return 1

/mob/living/carbon/proc/break_handcuffs()
	visible_message(
		SPAN("danger", "[src] is trying to break \the [handcuffed]!"),
		SPAN("warning", "You attempt to break your [handcuffed.name]. (This will take around 5 seconds and you need to stand still)")
		)

	if(do_after(src, 5 SECONDS, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		if(!handcuffed || buckled)
			return

		visible_message(
			SPAN("danger", "[src] manages to break \the [handcuffed]!"),
			SPAN("warning", "You successfully break your [handcuffed.name].")
			)

		say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))

		qdel(handcuffed)
		handcuffed = null
		if(buckled && buckled.buckle_require_restraints)
			buckled.unbuckle_mob()
		update_inv_handcuffed()

/mob/living/carbon/human/can_break_cuffs()
	if(species.can_shred(src,1))
		return 1
	return ..()

/mob/living/carbon/escape_buckle()
	if(handcuffed && istype(buckled, /obj/effect/energy_net))
		var/obj/effect/energy_net/N = buckled
		N.escape_net(src) //super snowflake but is literally used NOWHERE ELSE.-Luke
		return

	if(!buckled)
		return

	if(!restrained())
		..()
	else
		setClickCooldown(100)
		visible_message(SPAN_DANGER("[src] attempts to unbuckle themself!"),
						SPAN_WARNING("You attempt to unbuckle yourself. (This will take around 2 minutes and you need to stand still)"))

		if(do_after(src, 2 MINUTES, incapacitation_flags = INCAPACITATION_DEFAULT & ~(INCAPACITATION_RESTRAINED | INCAPACITATION_BUCKLED_FULLY)))
			if(!buckled)
				return
			visible_message(SPAN_DANGER("\The [src] manages to unbuckle themself!"),
							SPAN_NOTICE("You successfully unbuckle yourself."))
			buckled.user_unbuckle_mob(src)
