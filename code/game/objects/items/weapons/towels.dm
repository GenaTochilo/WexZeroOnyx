/obj/item/towel
	name = "towel"
	icon = 'icons/obj/weapons.dmi'
	icon_state = "towel"
	item_flags = ITEM_FLAG_IS_BELT
	slot_flags = SLOT_HEAD | SLOT_BELT | SLOT_OCLOTHING
	force = 0.5
	w_class = ITEM_SIZE_NORMAL
	mod_weight = 0.5
	mod_reach = 0.75
	mod_handy = 0.25
	attack_verb = list("whipped")
	hitsound = 'sound/weapons/towelwhip.ogg'
	desc = "A soft cotton towel."

/obj/item/towel/attack_self(mob/living/user as mob)
	user.visible_message(SPAN("notice", "[user] uses \the [src] to towel themselves off."))
	playsound(user, 'sound/weapons/towelwipe.ogg', 25, 1)

/obj/item/towel/random/New()
	..()
	color = get_random_colour()

/obj/item/towel/fleece // loot from the king of goats. it's a golden towel
	name = "golden fleece"
	desc = "The legendary Golden Fleece of Jason made real."
	color = "#ffd700"
	force = 1
	attack_verb = list("smote")
