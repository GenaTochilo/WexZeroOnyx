/obj/item/storage/secure/guncase
	name = "guncase"
	icon = 'icons/obj/storage.dmi'
	force = 8
	throw_range = 4
	w_class = ITEM_SIZE_LARGE
	mod_weight = 1.4
	mod_reach = 0.7
	mod_handy = 1
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = DEFAULT_BACKPACK_STORAGE
	var/guntype = ""
	var/gunspawned = FALSE

/obj/item/storage/secure/guncase/proc/spawn_set(set_name)
	return


/obj/item/storage/secure/guncase/detective
	name = "detective's gun case"
	icon_state = "guncasedet"
	item_state = "guncasedet"
	desc = "A heavy-duty container with a digital locking system. This one has a wooden coating and its locks are the color of brass."

/obj/item/storage/secure/guncase/detective/attackby(obj/item/W, mob/user)
	var/obj/item/card/id/I = W.get_id_card()
	if(I)
		if(!(access_forensics_lockers in I.GetAccess()))
			to_chat(user, SPAN("warning", "Access denied!"))
			return
		if(!guntype)
			to_chat(user, SPAN("warning", "\The [src] blinks red. You need to make a choice first."))
			return
		if(!gunspawned)
			spawn_set(guntype)
			lock_menu.close(user)
		locked = !locked
		to_chat(user, SPAN("notice", "You [locked ? "" : "un"]lock \the [src]."))
		overlays.Cut()
		if(!locked)
			overlays += image(icon, opened_overlay_icon_state)
		return
	return ..()

/obj/item/storage/secure/guncase/detective/show_lock_menu(mob/user)
	if(user.incapacitated() || !user.Adjacent(src) || !user.client)
		return
	user.set_machine(src)

	var/dat = "The case can be unlocked by swiping your ID card across the lock."
	dat += "\n"
	dat += text("<p><HR>\nChosen Gun: []", guntype)
	if(!gunspawned)
		dat += text("<p>\n Be careful! Once you chose your weapon and unlock the gun case, you won't be able to change it.")
		dat += text("<HR><p>\n<A href='?src=\ref[];type=m1911'>M1911</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=legacy'>S&W Legacy</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=saw620'>S&W 620</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=m2019'>M2019 Detective Special</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=det_m9'>T9 Patrol</A>", src)
	dat += text("<HR>")
	if(guntype)
		if(guntype == "M1911")
			dat += text("<p>\n A cheap Martian knock-off of a Colt M1911. Uses .45 rounds. Extremely popular among space detectives nowadays.")
			if(!gunspawned)
				dat += text("<p>\n Comes with two .45 seven round magazines and two .45 rubber seven round magazines.")
		else if(guntype == "S&W Legacy")
			dat += text("<p>\n A cheap Martian knock-off of a Smith & Wesson Model 10. Uses .38-Special rounds. Used to be NanoTrasen's service weapon for detectives.")
			if(!gunspawned)
				dat += text("<p>\n Comes with two .38 six round speedloaders and two .38 rubber six round speedloaders.")
		else if(guntype == "S&W 620")
			dat += text("<p>\n A cheap Martian knock-off of a Smith & Wesson Model 620. Uses .38-Special rounds. Quite popular among professionals.")
			if(!gunspawned)
				dat += text("<p>\n Comes with two .38 six round speedloaders and two .38 rubber six round speedloaders.")
		else if(guntype == "M2019")
			dat += text("<p>\n Quite a controversial weapon. Combining both pros and cons of revolvers and railguns, it's extremely versatile, yet requires a lot of care.")
			if(!gunspawned)
				dat += text("<p>\n Comes with three .38 SPEC five round speedloaders, two .38 CHEM five round speedloaders, and two replaceable power cells.")
				dat += text("<p>\n Brief instructions: <p>\n - M2019 Detective Special can be loaded with any type .38 rounds, yet works best with .38 CHEM and .38 SPEC.")
				dat += text("<p>\n - With a powercell installed, M2019 can be used in two modes: non-lethal and lethal.")
				dat += text("<p>\n - .38 SPEC no cell - works like a rubber bullet. <p>\n - .38 SPEC non-lethal - stuns the target. <p>\n - .38 SPEC lethal - accelerates the bullet, deals great damage and pierces medium armor.")
				dat += text("<p>\n - .38 CHEM no cell - works like a flash bullet. <p>\n - .38 CHEM non-lethal - emmits a weak electromagnetic impulse. <p>\n - .38 CHEM lethal - not supposed to be used like this. The cartride reaches extremely high temperature and melts.")
		else if(guntype == "T9 Patrol")
			dat += text("<p>\n A relatively cheap and reliable knock-off of a Beretta M9. Uses 9mm rounds. Used to be a standart-issue gun in almost every security company.")
			if(!gunspawned)
				dat += text("<p>\n Comes with three ten round 9mm magazines and two 9mm flash ten round magazines.")

	if(!lock_menu || lock_menu.user != user)
		lock_menu = new /datum/browser(user, "mob[name]", "<B>[src]</B>", 300, 280)
		lock_menu.set_content(dat)
	else
		lock_menu.set_content(dat)
		lock_menu.update()
	return

/obj/item/storage/secure/guncase/detective/Topic(href, href_list)
	if((usr.stat || usr.restrained()) || (get_dist(src, usr) > 1))
		return
	if(href_list["type"])
		if (href_list["type"] == "m1911")
			guntype = "M1911"
		else if(href_list["type"] == "legacy")
			guntype = "S&W Legacy"
		else if(href_list["type"] == "saw620")
			guntype = "S&W 620"
		else if(href_list["type"] == "m2019")
			guntype = "M2019"
		else if(href_list["type"] == "det_m9")
			guntype = "T9 Patrol"
		for(var/mob/M in viewers(1, src.loc))
			if((M.client && M.machine == src))
				show_lock_menu(M)
	return

/obj/item/storage/secure/guncase/detective/spawn_set(set_name)
	if(gunspawned)
		return
	switch(set_name)
		if("M1911")
			new /obj/item/gun/projectile/pistol/colt/detective(src)
			new /obj/item/ammo_magazine/c45m/rubber(src)
			new /obj/item/ammo_magazine/c45m/rubber(src)
			new /obj/item/ammo_magazine/c45m/stun(src)
			new /obj/item/ammo_magazine/c45m/stun(src)
			new /obj/item/ammo_magazine/c45m(src)
			new /obj/item/ammo_magazine/c45m(src)
		if("S&W Legacy")
			new /obj/item/gun/projectile/revolver/detective(src)
			new /obj/item/ammo_magazine/c38/rubber(src)
			new /obj/item/ammo_magazine/c38/rubber(src)
			new /obj/item/ammo_magazine/c38(src)
			new /obj/item/ammo_magazine/c38(src)
		if("S&W 620")
			new /obj/item/gun/projectile/revolver/detective/saw620(src)
			new /obj/item/ammo_magazine/c38/rubber(src)
			new /obj/item/ammo_magazine/c38/rubber(src)
			new /obj/item/ammo_magazine/c38(src)
			new /obj/item/ammo_magazine/c38(src)
		if("M2019")
			new /obj/item/gun/projectile/revolver/m2019/detective(src)
			new /obj/item/ammo_magazine/c38/spec(src)
			new /obj/item/ammo_magazine/c38/spec(src)
			new /obj/item/ammo_magazine/c38/spec(src)
			new /obj/item/ammo_magazine/c38/chem(src)
			new /obj/item/ammo_magazine/c38/chem(src)
			new /obj/item/cell/device/high(src)
		if("T9 Patrol")
			new /obj/item/gun/projectile/pistol/det_m9(src)
			new /obj/item/ammo_magazine/mc9mm(src)
			new /obj/item/ammo_magazine/mc9mm(src)
			new /obj/item/ammo_magazine/mc9mm(src)
			new /obj/item/ammo_magazine/mc9mm/flash(src)
			new /obj/item/ammo_magazine/mc9mm/flash(src)
		else
			return
	gunspawned = TRUE


/obj/item/storage/secure/guncase/security
	name = "security hardcase"
	icon_state = "guncasesec"
	item_state = "guncase"
	desc = "A heavy-duty container with an ID-based locking system. This one is painted in NT Security colors."
	override_w_class = list(/obj/item/gun/energy/security)
	max_storage_space = null
	storage_slots = 7

/obj/item/storage/secure/guncase/security/attackby(obj/item/W, mob/user)
	var/obj/item/card/id/I = W.get_id_card()
	if(I) // For IDs and PDAs and wallets with IDs
		if(!(access_security in I.GetAccess()))
			to_chat(user, SPAN("warning", "Access denied!"))
			return
		if(!guntype)
			to_chat(user, SPAN("warning", "\The [src] blinks red. You need to make a choice first."))
			return
		if(!gunspawned)
			spawn_set(guntype)
			lock_menu.close(user)
			for(var/thing in contents)
				if(istype(thing, /obj/item/gun/energy/security))
					var/obj/item/gun/energy/security/gun = thing
					gun.owner = I.registered_name
		to_chat(user, SPAN("notice", "You [locked ? "un" : ""]lock \the [src]."))
		locked = !locked
		overlays.Cut()
		if(!locked)
			overlays += image(icon, opened_overlay_icon_state)
		return
	return ..()

/obj/item/storage/secure/guncase/security/attack_self(mob/user)
	if(locked && !gunspawned)
		show_lock_menu(user)
		if(lock_menu?.user == user)
			lock_menu.open()
	attack_hand(user)

/obj/item/storage/secure/guncase/security/spawn_set(set_name)
	if(gunspawned)
		return
	var/obj/item/gun/energy/security/gun = null
	switch(set_name)
		if("Pistol")
			gun = new /obj/item/gun/energy/security(src)
			gun.subtype = decls_repository.get_decl(/decl/taser_types/pistol)
			gun.update_subtype()
			new /obj/item/shield/barrier(src)
		if("SMG")
			gun = new /obj/item/gun/energy/security(src)
			gun.subtype = decls_repository.get_decl(/decl/taser_types/smg)
			gun.update_subtype()
			new /obj/item/shield/barrier(src)
		if("Rifle")
			gun = new /obj/item/gun/energy/security(src)
			gun.subtype = decls_repository.get_decl(/decl/taser_types/rifle)
			gun.update_subtype()
			new /obj/item/shield/barrier(src)
		if("Classic")
			new /obj/item/gun/energy/classictaser(src)
			if(prob(70))
				new /obj/item/reagent_containers/vessel/bottle/small/darkbeer(src)
			else
				new /obj/item/reagent_containers/vessel/bottle/whiskey(src)
		else
			return
	new /obj/item/melee/baton/loaded(src)
	new /obj/item/handcuffs(src)
	new /obj/item/handcuffs(src)
	new /obj/item/reagent_containers/food/donut/normal(src)
	new /obj/item/reagent_containers/food/donut/normal(src)
	gunspawned = TRUE

/obj/item/storage/secure/guncase/security/show_lock_menu(mob/user)
	if(user.incapacitated() || !user.Adjacent(src) || !user.client)
		return
	user.set_machine(src)
	var/dat = text("It can be locked and unlocked by swiping your ID card across the lock.<br>")

	dat += text("<p><HR>\nChosen Gun: []", "[guntype ? guntype : "none"]")
	if(!gunspawned)
		dat += text("<p>\n Be careful! Once you chose your weapon and unlock the gun case, you won't be able to change it.")
		dat += text("<HR><p>\n<A href='?src=\ref[];type=Pistol'>Taser Pistol</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=SMG'>Taser SMG</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=Rifle'>Taser Rifle</A>", src)
		dat += text("<p>\n<A href='?src=\ref[];type=Classic'>Rusty Classic</A>", src)
	dat += text("<HR>")
	if(guntype)
		switch(guntype)
			if("Pistol")
				dat += text("<p>\n A taser pistol. The smallest of all the tasers. It only has a single fire mode, but each shot wields power.")
				dat += text("<p>\n Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts.")
			if("SMG")
				dat += text("<p>\n A taser SMG. This model is not as powerful as pistols, but is capable of launching electrodes left and right with its remarkable rate of fire.")
				dat += text("<p>\n Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts.")
			if("Rifle")
				dat += text("<p>\n A taser rifle. Bulky and heavy, it must be wielded with both hands. Although its rate of fire is way below average, it is capable of shooting stun beams.")
				dat += text("<p>\n Comes with a baton, a handheld barrier, a couple of handcuffs, and a pair of donuts.")
			if("Classic")
				dat += text("<p>\n A rusty-and-trusty taser. It's overall worse than the modern baseline tasers, but it still does its job. Useful for those who want to assert their robust dominance. Or, maybe, for old farts.")
				dat += text("<p>\n Comes with a baton, a couple of handcuffs, a pair of donuts, and a drink to stay cool.")

	if(!lock_menu || lock_menu.user != user)
		lock_menu = new /datum/browser(user, "mob[name]", "<B>[src]</B>", 300, 280)
		lock_menu.set_content(dat)
	else
		lock_menu.set_content(dat)
		lock_menu.update()
	return

/obj/item/storage/secure/guncase/security/Topic(href, href_list)
	if((usr.stat || usr.restrained()) || (get_dist(src, usr) > 1))
		return
	if(href_list["type"])
		guntype = href_list["type"]
		for(var/mob/M in viewers(1, loc))
			if((M.client && M.machine == src))
				show_lock_menu(M)
	return
