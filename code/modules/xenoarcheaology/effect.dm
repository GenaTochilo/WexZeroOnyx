/datum/artifact_effect
	var/name = "unknown"
	var/effect = EFFECT_TOUCH
	var/effectrange = 4
	var/trigger = TRIGGER_TOUCH
	var/atom/holder
	var/activated = FALSE
	var/is_visible_toggle = TRUE
	var/chargelevel = 0
	var/chargelevelmax = 10
	var/artifact_id = ""
	var/effect_type = EFFECT_UNKNOWN

/datum/artifact_effect/New(atom/location, visible_toggle = TRUE)
	..()
	holder = location
	is_visible_toggle = visible_toggle

	effect = pick(EFFECTS_LIST)
	trigger = pick(TRIGGERS_LIST)

	//this will be replaced by the excavation code later, but it's here just in case
	artifact_id = "[pick("kappa","sigma","antaeres","beta","omicron","iota","epsilon","omega","gamma","delta","tau","alpha")]-[rand(100,999)]"

	//random charge time and distance
	switch(pick(100;1, 50;2, 25;3))
		if(1)
			//short range, short charge time
			chargelevelmax = rand(3, 20)
			effectrange = rand(1, 3)
		if(2)
			//medium range, medium charge time
			chargelevelmax = rand(15, 40)
			effectrange = rand(5, 15)
		if(3)
			//large range, long charge time
			chargelevelmax = rand(20, 120)
			effectrange = rand(20, 200)

/datum/artifact_effect/proc/AdjustActivate(env_triggers)
	// Check that effect's trigger is in enviroment triggers and true. Also make value 1 or 0(TRUE or FALSE)
    var/is_activation_trigger = (trigger & TRIGGERS_ENVIROMENT & env_triggers)/trigger
    if(is_activation_trigger != activated)
        ToggleActivate()

/datum/artifact_effect/proc/ToggleActivate()
	//so that other stuff happens first
	spawn(0)
		activated = !activated
		if(is_visible_toggle && holder)
			if(istype(holder, /obj/machinery/artifact))
				var/obj/machinery/artifact/A = holder
				A.icon_state = "ano[A.icon_num][activated]"
			var/display_msg
			if(activated)
				display_msg = pick("momentarily glows brightly!","distorts slightly for a moment!","flickers slightly!","vibrates!","shimmers slightly for a moment!")
			else
				display_msg = pick("grows dull!","fades in intensity!","suddenly becomes very still!","suddenly becomes very quiet!")
			var/atom/toplevelholder = holder
			while(!istype(toplevelholder.loc, /turf) && !istype(toplevelholder.loc, /mob))
				toplevelholder = toplevelholder.loc
			toplevelholder.visible_message(SPAN("warning", "\icon[toplevelholder] [toplevelholder] [display_msg]"))

/datum/artifact_effect/proc/DoEffectTouch(mob/user)
/datum/artifact_effect/proc/DoEffectAura(atom/holder)
/datum/artifact_effect/proc/DoEffectPulse(atom/holder)
/datum/artifact_effect/proc/UpdateMove()

/datum/artifact_effect/proc/process()
	if(chargelevel < chargelevelmax)
		chargelevel++

	if(activated)
		if(effect & EFFECT_AURA)
			DoEffectAura()
		else if(effect & EFFECT_PULSE && chargelevel >= chargelevelmax)
			chargelevel = 0
			DoEffectPulse()

/datum/artifact_effect/proc/getDescription()
	. = "<b>"
	switch(effect_type)
		if(EFFECT_ENERGY)
			. += "Concentrated energy emissions"
		if(EFFECT_PSIONIC)
			. += "Intermittent psionic wavefront"
		if(EFFECT_ELECTRO)
			. += "Electromagnetic energy"
		if(EFFECT_PARTICLE)
			. += "High frequency particles"
		if(EFFECT_ORGANIC)
			. += "Organically reactive exotic particles"
		if(EFFECT_BLUESPACE)
			. += "Interdimensional/bluespace? phasing"
		if(EFFECT_SYNTH)
			. += "Atomic synthesis"
		else
			. += "Low level energy emissions"

	. += "</b> have been detected <b>"

	switch(effect)
		if(EFFECT_TOUCH)
			. += "interspersed throughout substructure and shell."
		if(EFFECT_AURA)
			. += "emitting in an ambient energy field."
		if(EFFECT_PULSE)
			. += "emitting in periodic bursts."
		else
			. += "emitting in an unknown way."

	. += "</b>"

	switch(trigger)
		if(TRIGGER_TOUCH, TRIGGER_WATER, TRIGGER_ACID, TRIGGER_VOLATILE, TRIGGER_TOXIN)
			. += " Activation index involves <b>physical interaction</b> with artifact surface."
		if(TRIGGER_FORCE, TRIGGER_ENERGY, TRIGGER_HEAT, TRIGGER_COLD)
			. += " Activation index involves <b>energetic interaction</b> with artifact surface."
		if(TRIGGER_PLASMA, TRIGGER_OXY, TRIGGER_CO2, TRIGGER_NITRO)
			. += " Activation index involves <b>precise local atmospheric conditions</b>."
		else
			. += " Unable to determine any data about activation trigger."

//returns 0..1, with 1 being no protection and 0 being fully protected
/proc/GetAnomalySusceptibility(mob/living/carbon/human/H)
	if(!istype(H))
		return 1

	var/protected = 0

	//anomaly suits give best protection, but excavation suits are almost as good
	if(istype(H.back,/obj/item/rig/hazmat) || istype(H.back, /obj/item/rig/security))
		var/obj/item/rig/rig = H.back
		if(rig.suit_is_deployed() && !rig.offline)
			protected += 1

	if(istype(H.wear_suit,/obj/item/clothing/suit/bio_suit/anomaly))
		protected += 0.6
	else if(istype(H.wear_suit,/obj/item/clothing/suit/space/void/excavation))
		protected += 0.5

	if(istype(H.head,/obj/item/clothing/head/bio_hood/anomaly))
		protected += 0.3
	else if(istype(H.head,/obj/item/clothing/head/helmet/space/void/excavation))
		protected += 0.2

	//latex gloves and science goggles also give a bit of bonus protection
	if(istype(H.gloves,/obj/item/clothing/gloves/latex))
		protected += 0.1

	var/obj/item/clothing/glasses/hud/G = H.glasses
	if(istype(G) && istype(G.matrix, /obj/item/device/hudmatrix/science))
		protected += 0.1

	return max(1 - protected, 0)
