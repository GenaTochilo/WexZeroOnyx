/obj/machinery/seed_extractor
	name = "seed extractor"
	desc = "Extracts and bags seeds from produce."
	icon = 'icons/obj/hydroponics_machines.dmi'
	icon_state = "sextractor"
	layer = BELOW_OBJ_LAYER
	density = 1
	anchored = 1
	use_power = POWER_USE_ACTIVE
	idle_power_usage = 10 WATTS
	active_power_usage = 2 KILO WATTS

/obj/machinery/seed_extractor/attackby(obj/item/O, mob/user)
	// Fruits and vegetables.
	if(istype(O, /obj/item/reagent_containers/food/grown) || istype(O, /obj/item/grown))
		if(!user.drop(O))
			return

		var/datum/seed/new_seed_type
		if(istype(O, /obj/item/grown))
			var/obj/item/grown/F = O
			new_seed_type = SSplants.seeds[F.plantname]
		else
			var/obj/item/reagent_containers/food/grown/F = O
			new_seed_type = SSplants.seeds[F.plantname]

		if(new_seed_type)
			to_chat(user, SPAN("notice", "You extract some seeds from [O]."))
			var/produce = rand(1,4)
			for(var/i = 0;i<=produce;i++)
				var/obj/item/seeds/seeds = new(get_turf(src))
				seeds.seed_type = new_seed_type.name
				seeds.update_seed()
		else
			to_chat(user, "[O] doesn't seem to have any usable seeds inside it.")

		qdel(O)

	//Grass.
	else if(istype(O, /obj/item/stack/tile/grass))
		var/obj/item/stack/tile/grass/S = O
		if (S.use(1))
			to_chat(user, SPAN("notice", "You extract some seeds from the grass tile."))
			new /obj/item/seeds/grassseed(loc)

	else if(istype(O, /obj/item/fossil/plant)) // Fossils
		var/obj/item/seeds/random/R = new(get_turf(src))
		to_chat(user, "\The [src] scans \the [O] and spits out \a [R].")
		qdel(O)

	return
