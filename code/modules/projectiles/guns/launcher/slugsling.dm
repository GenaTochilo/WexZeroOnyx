/obj/item/slugegg
	name = "slugegg"
	desc = "A pulsing, disgusting door to new life."
	force = 1
	throwforce = 6
	icon = 'icons/obj/weapons.dmi'
	icon_state = "slugegg"
	var/break_on_impact = 1 //There are two modes to the eggs.
							//One breaks the egg on hit,

/obj/item/slugegg/Initialize()
	. = ..()
	proximity_monitor = new(src, 0)

/obj/item/slugegg/throw_impact(atom/hit_atom, speed)
	if(break_on_impact)
		squish()
	return ..()

/obj/item/slugegg/attack_self(mob/living/user)
	user.drop(src)
	squish()

/obj/item/slugegg/HasProximity(atom/movable/AM)
	if(isliving(AM))
		if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			if(H.species && H.species.name == SPECIES_VOX)
				return
		else
			var/mob/living/L = AM
			if(L.faction == SPECIES_VOX)
				return
		squish()

/obj/item/slugegg/proc/squish()
	src.visible_message(SPAN("warning", "\The [src] bursts open!"))
	new /mob/living/simple_animal/hostile/voxslug(get_turf(src))
	playsound(src.loc,'sound/effects/attackblob.ogg',100, 1)
	qdel(src)

//a slug sling basically launches a small egg that hatches (either on a person or on the floor), releasing a terrible blood thirsty monster.
//Balanced due to the non-spammy nature of the gun, as well as the frailty of the creatures.
/obj/item/gun/launcher/alien/slugsling
	name = "slug sling"
	desc = "A bulbous looking rifle. It feels like holding a plastic bag full of meat."
	w_class = ITEM_SIZE_LARGE
	icon_state = "slugsling"
	item_state = "spikethrower"
	fire_sound_text = "a strange noise"
	fire_sound = 'sound/weapons/towelwhip.ogg'
	release_force = 2
	ammo_name = "slug"
	ammo_type = /obj/item/slugegg
	max_ammo = 3
	ammo = 3
	ammo_gen_time = 200
	var/mode = "Impact"

/obj/item/gun/launcher/alien/slugsling/consume_next_projectile()
	var/obj/item/slugegg/S = ..()
	if(S)
		S.break_on_impact = (mode == "Impact")
	return S


/obj/item/gun/launcher/alien/slugsling/attack_self(mob/living/user)
	mode = mode == "Impact" ? "Sentry" : "Impact"
	to_chat(user,SPAN("notice", "You switch \the [src]'s mode to \"[mode]\""))
