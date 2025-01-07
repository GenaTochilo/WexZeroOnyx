#define NO_GUARANTEE_NO_EXTRA_COST_DESC(X) "Installs an uplink into " + X + " if, and only if, found on your person. Has no TC cost."

#define SETUP_FAILED TRUE

GLOBAL_LIST_INIT(default_uplink_source_priority, list(
	/decl/uplink_source/pda,
	/decl/uplink_source/radio,
	/decl/uplink_source/unit))

/decl/uplink_source
	var/name
	var/desc

/decl/uplink_source/proc/setup_uplink_source(mob/M, amount)
	return SETUP_FAILED

/decl/uplink_source/pda
	name = "PDA"
	desc = NO_GUARANTEE_NO_EXTRA_COST_DESC("a PDA")

/decl/uplink_source/pda/setup_uplink_source(mob/M, amount)
	var/obj/item/device/pda/P = find_in_mob(M, /obj/item/device/pda)
	if(!P)
		return SETUP_FAILED

	var/pda_pass = "[rand(100,999)] [pick(GLOB.greek_letters)]"
	var/obj/item/device/uplink/T = new(P, M.mind, amount)
	P.hidden_uplink = T
	P.lock_code = pda_pass
	to_chat(M, SPAN("notice", "A portable object teleportation relay has been installed in your [P.name]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features."))
	M.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([P.name]).")

/decl/uplink_source/radio
	name = "Radio"
	desc = NO_GUARANTEE_NO_EXTRA_COST_DESC("a radio")

/decl/uplink_source/radio/setup_uplink_source(mob/M, amount)
	var/obj/item/device/radio/R = find_in_mob(M, /obj/item/device/radio)
	if(!R)
		return SETUP_FAILED

	var/freq = PUBLIC_LOW_FREQ
	var/list/freqlist = list()
	while (freq <= PUBLIC_HIGH_FREQ)
		if (freq < 1451 || freq > PUB_FREQ)
			freqlist += freq
		freq += 2
		if ((freq % 2) == 0)
			freq += 1

	freq = freqlist[rand(1, freqlist.len)]
	var/obj/item/device/uplink/T = new(R, M.mind, amount)
	R.hidden_uplink = T
	R.traitor_frequency = freq
	to_chat(M, SPAN("notice", "A portable object teleportation relay has been installed in your [R.name]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features."))
	M.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name]).")

/decl/uplink_source/implant
	name = "Implant"
	desc = "Teleports an uplink implant into your head. Costs at least half the initial TC amount."

/decl/uplink_source/implant/setup_uplink_source(mob/living/carbon/human/H, amount)
	if(!istype(H))
		return SETUP_FAILED

	var/obj/item/organ/external/head = H.organs_by_name[BP_HEAD]
	if(!head)
		return SETUP_FAILED

	var/obj/item/implant/uplink/U = new(H, IMPLANT_TELECRYSTAL_AMOUNT(amount))
	U.imp_in = H
	U.implanted = TRUE
	U.part = head
	head.implants += U

	U.implanted(H) // This proc handles the installation feedback

/decl/uplink_source/unit
	name = "Uplink Unit"
	desc = "Teleports an uplink unit to your location. Grants you three extra TCs."

/decl/uplink_source/unit/setup_uplink_source(mob/M, amount)
	var/obj/item/device/radio/uplink/U = new(M, M.mind, round(amount * 1.25))
	put_on_mob(M, U, "\A [U]")

/decl/uplink_source/telecrystals
	name = "Telecrystals"
	desc = "Get your telecrystals in pure form, without the means to trade them for goods."

/decl/uplink_source/telecrystals/setup_uplink_source(mob/M, amount)
	var/obj/item/stack/telecrystal/TC = new(M, amount)
	put_on_mob(M, TC, "[amount] telecrystal\s")

/decl/uplink_source/proc/find_in_mob(mob/M, type)
	for(var/item in M.get_equipped_items(TRUE))
		if(!istype(item, type))
			continue
		var/obj/item/I = item
		if(!I.hidden_uplink)
			return I

/decl/uplink_source/proc/put_on_mob(mob/M, atom/movable/AM, text)
	var/obj/O = M.equip_to_storage(AM)
	if(O)
		to_chat(M, SPAN("notice", "[text] can be found in your [O.name]."))
	else if(M.pick_or_drop(AM))
		to_chat(M, SPAN("notice", "[text] appear in your hands."))
	else
		to_chat(M, SPAN("notice", "[text] appear at your location."))

/proc/setup_uplink_source(mob/M, amount = DEFAULT_TELECRYSTAL_AMOUNT)
	if(!istype(M) || !M.mind)
		return FALSE

	var/list/priority_order
	if(M.client && M.client.prefs)
		priority_order = M.client.prefs.uplink_sources

	if(!priority_order || !priority_order.len)
		priority_order = list()
		for(var/entry in GLOB.default_uplink_source_priority)
			priority_order += decls_repository.get_decl(entry)

	for(var/entry in priority_order)
		var/decl/uplink_source/US = entry
		if(US.setup_uplink_source(M, amount) != SETUP_FAILED)
			return TRUE

	to_chat(M, SPAN("warning", "Either by choice or circumstance you will be without an uplink."))
	return FALSE

#undef NO_GUARANTEE_NO_EXTRA_COST_DESC
#undef SETUP_FAILED
