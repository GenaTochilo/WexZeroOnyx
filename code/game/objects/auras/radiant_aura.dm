/obj/aura/radiant_aura
	name = "radiant aura"
	icon = 'icons/effects/effects.dmi'
	icon_state = "fire_goon"
	layer = ABOVE_WINDOW_LAYER

/obj/aura/radiant_aura/New()
	..()
	to_chat(user,SPAN("notice", "A bubble of light appears around you, exuding protection and warmth."))
	set_light(0.6, 1, 6, 2, "#e09d37")

/obj/aura/radiant_aura/Destroy()
	to_chat(user, SPAN("warning", "Your protective aura dissipates, leaving you feeling cold and unsafe."))
	return ..()

/obj/aura/radiant_aura/bullet_act(obj/item/projectile/P, def_zone)
	if(P.check_armour == "laser")
		user.visible_message(SPAN("warning", "\The [P] refracts, bending into \the [user]'s aura."))
		return AURA_FALSE
	return 0
