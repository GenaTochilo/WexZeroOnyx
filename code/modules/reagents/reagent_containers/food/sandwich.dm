/obj/item/reagent_containers/food/slice/bread/attackby(obj/item/W as obj, mob/user as mob)

	if(istype(W,/obj/item/material/shard) || istype(W,/obj/item/reagent_containers/food))
		var/obj/item/reagent_containers/food/csandwich/S = new(get_turf(src))
		S.attackby(W,user)
		qdel(src)
	..()

/obj/item/reagent_containers/food/csandwich
	name = "sandwich"
	desc = "The best thing since sliced bread."
	icon_state = "breadslice"
	trash = /obj/item/trash/dish/plate
	bitesize = 2

	var/list/ingredients = list()

/obj/item/reagent_containers/food/csandwich/attackby(obj/item/W as obj, mob/user as mob)

	var/sandwich_limit = 4
	for(var/obj/item/O in ingredients)
		if(istype(O, /obj/item/reagent_containers/food/slice/bread))
			sandwich_limit += 4

	if(contents.len > sandwich_limit)
		to_chat(user, SPAN("wwarning", "If you put anything else on \the [src] it's going to collapse."))
		return
	else if(istype(W, /obj/item/material/shard))
		if(user.drop(W, src))
			to_chat(user, SPAN("warning", "You hide [W] in \the [src]."))
			update()
		return
	else if(istype(W, /obj/item/reagent_containers/food))
		if(!user.drop(W, src))
			return
		to_chat(user, SPAN("warning", "You layer [W] over \the [src]."))
		var/obj/item/reagent_containers/F = W
		F.reagents.trans_to_obj(src, F.reagents.total_volume)
		ingredients += W
		update()
		return
	..()

/obj/item/reagent_containers/food/csandwich/proc/update()
	var/fullname = "" //We need to build this from the contents of the var.
	var/i = 0

	overlays.Cut()

	for(var/obj/item/reagent_containers/food/O in ingredients)

		i++
		if(i == 1)
			fullname += "[O.name]"
		else if(i == ingredients.len)
			fullname += " and [O.name]"
		else
			fullname += ", [O.name]"

		var/image/I = new(src.icon, "sandwich_filling")
		I.color = O.filling_color
		I.pixel_x = pick(list(-1,0,1))
		I.pixel_y = (i*2)+1
		overlays += I

	var/image/T = new(src.icon, "sandwich_top")
	T.pixel_x = pick(list(-1,0,1))
	T.pixel_y = (ingredients.len * 2)+1
	overlays += T

	SetName(lowertext("[fullname] sandwich"))
	if(length(name) > 80) SetName("[pick(list("absurd","colossal","enormous","ridiculous"))] sandwich")
	w_class = ceil(Clamp((ingredients.len/2),2,4))

/obj/item/reagent_containers/food/csandwich/Destroy()
	for(var/obj/item/O in ingredients)
		qdel(O)

	return ..()

/obj/item/reagent_containers/food/csandwich/_examine_text(mob/user)
	. = ..()
	var/obj/item/O = pick(contents)
	. += "\n"
	. += SPAN("warning", "You think you can see [O.name] in there.")

/obj/item/reagent_containers/food/csandwich/attack(mob/M as mob, mob/user as mob, def_zone)

	var/obj/item/shard
	for(var/obj/item/O in contents)
		if(istype(O,/obj/item/material/shard))
			shard = O
			break

	var/mob/living/H
	if(istype(M,/mob/living))
		H = M

	if(H && shard && M == user) //This needs a check for feeding the food to other people, but that could be abusable.
		to_chat(H, SPAN("warning", "You lacerate your mouth on a [shard.name] in the sandwich!"))
		H.adjustBruteLoss(5) //TODO: Target head if human.
	..()
