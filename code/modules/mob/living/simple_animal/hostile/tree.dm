/mob/living/simple_animal/hostile/tree
	name = "pine tree"
	desc = "A pissed off tree-like alien. It seems annoyed with the festivities..."
	icon = 'icons/obj/flora/pinetrees.dmi'
	icon_state = "pine_1"
	icon_living = "pine_1"
	icon_dead = "pine_1"
	icon_gib = "pine_1"
	speak_chance = 0
	turns_per_move = 5
	meat_type = /obj/item/reagent_containers/food/carpmeat
	response_help = "brushes"
	response_disarm = "pushes"
	response_harm = "hits"
	speed = -1
	maxHealth = 250
	health = 250

	pixel_x = -16

	harm_intent_damage = 5
	melee_damage_lower = 8
	melee_damage_upper = 12
	attacktext = "bitten"
	attack_sound = 'sound/weapons/bite.ogg'
	bodyparts = /decl/simple_animal_bodyparts/tree

	//Space carp aren't affected by atmos.
	min_gas = null
	max_gas = null
	minbodytemp = 0

	faction = "floral"

/mob/living/simple_animal/hostile/tree/find_target()
	. = ..()
	if(.)
		audible_emote("growls at [.]")

/mob/living/simple_animal/hostile/tree/AttackingTarget()
	. =..()
	var/mob/living/L = .
	if(istype(L))
		if(prob(15))
			L.Weaken(3)
			L.visible_message(SPAN("danger", "\The [src] knocks down \the [L]!"))

/mob/living/simple_animal/hostile/tree/death(gibbed, deathmessage, show_dead_message)
	..(null,"is hacked into pieces!", show_dead_message)
	new /obj/item/stack/material/wood(loc)
	qdel(src)

/decl/simple_animal_bodyparts/tree
	hit_zones = list("trunk", "branches", "twigs")
