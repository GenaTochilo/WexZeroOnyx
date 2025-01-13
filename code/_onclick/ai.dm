// AI click handling overrides default /mob/ClicnOn() handling with a much cleaner implementation since
// AI doesn't have a `restrained()` state, doesn't use items, and has no need for `Adjacent()` checks.
/mob/living/silicon/ai/ClickOn(atom/A, params)
	if(world.time <= next_click)
		return
	next_click = world.time + 1

	if(incapacitated())
		return

	var/list/modifiers = params2list(params)
	if(modifiers["ctrl"] && modifiers["alt"])
		CtrlAltClickOn(A)
		return
	if(modifiers["shift"] && modifiers["ctrl"])
		CtrlShiftClickOn(A)
		return
	if(modifiers["middle"])
		if(modifiers["shift"])
			ShiftMiddleClickOn(A)
		else
			MiddleClickOn(A)
		return
	if(modifiers["shift"])
		ShiftClickOn(A)
		return
	if(modifiers["alt"]) // alt and alt-gr (rightalt)
		AltClickOn(A)
		return
	if(modifiers["ctrl"])
		CtrlClickOn(A)
		return

	face_atom(A) // change direction to face what you clicked on

	if(control_disabled || !canClick())
		return

	if(multitool_mode && isobj(A))
		var/obj/O = A
		var/datum/extension/interactive/multitool/MT = get_extension(O, /datum/extension/interactive/multitool)
		if(MT)
			MT.interact(aiMulti, src)
			return

	if(silicon_camera.in_camera_mode)
		silicon_camera.camera_mode_off()
		silicon_camera.captureimage(A, usr)
		return

	A.add_hiddenprint(src)
	A.attack_ai(src)

/mob/living/silicon/ai/DblClickOn(atom/A, params)
	if(control_disabled || stat) return

	if(ismob(A))
		ai_actual_track(A)
	else
		A.move_camera_by_click()
/*
	AI has no need for the UnarmedAttack() and RangedAttack() procs,
	because the AI code is not generic;	attack_ai() is used instead.
	The below is only really for safety, or you can alter the way
	it functions and re-insert it above.
*/
/mob/living/silicon/ai/UnarmedAttack(atom/A)
	A.attack_ai(src)
/mob/living/silicon/ai/RangedAttack(atom/A)
	A.attack_ai(src)
/mob/living/silicon/ai/MouseDrop() //AI cant user crawl
	return


/*
	Since the AI handles shift, ctrl, and alt-click differently
	than anything else in the game, atoms have separate procs
	for AI shift, ctrl, and alt clicking.
*/

/mob/living/silicon/ai/CtrlAltClickOn(atom/A)
	if(!control_disabled && A.AICtrlAltClick(src))
		return
	..()

/mob/living/silicon/ai/ShiftClickOn(atom/A)
	if(!control_disabled && A.AIShiftClick(src))
		return
	..()

/mob/living/silicon/ai/CtrlClickOn(atom/A)
	if(!control_disabled && A.AICtrlClick(src))
		return
	..()

/mob/living/silicon/ai/AltClickOn(atom/A)
	if(!control_disabled && A.AIAltClick(src))
		return
	..()

/mob/living/silicon/ai/MiddleClickOn(atom/A)
	if(!control_disabled && A.AIMiddleClick(src))
		return
	..()

/*
	The following criminally helpful code is just the previous code cleaned up;
	I have no idea why it was in atoms.dm instead of respective files.
*/

/atom/proc/AICtrlAltClick()
	return FALSE

/obj/machinery/door/airlock/AICtrlAltClick() // Electrifies doors.
	if(usr.incapacitated())
		return FALSE
	if(!electrified_until)
		// permanent shock
		Topic(src, list("command"="electrify_permanently", "activate" = "1"))
	else
		// disable/6 is not in Topic; disable/5 disables both temporary and permanent shock
		Topic(src, list("command"="electrify_permanently", "activate" = "0"))
	return TRUE

/atom/proc/AICtrlShiftClick()
	return FALSE

/atom/proc/AIShiftClick()
	return FALSE

/obj/machinery/door/airlock/AIShiftClick()  // Opens and closes doors!
	if(usr.incapacitated())
		return FALSE
	if(density)
		Topic(src, list("command"="open", "activate" = "1"))
	else
		Topic(src, list("command"="open", "activate" = "0"))
	return TRUE

/atom/proc/AICtrlClick()
	return FALSE

/obj/machinery/door/airlock/AICtrlClick() // Bolts doors
	if(usr.incapacitated())
		return FALSE
	if(locked)
		Topic(src, list("command"="bolts", "activate" = "0"))
	else
		Topic(src, list("command"="bolts", "activate" = "1"))
	return TRUE

/obj/machinery/power/apc/AICtrlClick() // turns off/on APCs.
	if(usr.incapacitated())
		return FALSE
	Topic(src, list("breaker"="1"))
	return TRUE

/obj/machinery/turretid/AICtrlClick() //turns off/on Turrets
	if(usr.incapacitated())
		return FALSE
	Topic(src, list("command"="enable", "value"="[!enabled]"))
	return TRUE

/atom/proc/AIAltClick(atom/A)
	AltClick(A)
	return TRUE

/obj/machinery/turretid/AIAltClick() //toggles lethal on turrets
	if(usr.incapacitated())
		return FALSE
	Topic(src, list("command"="lethal", "value"="[!lethal]"))
	return TRUE

/obj/machinery/atmospherics/binary/pump/AIAltClick()
	return AltClick()

/atom/proc/AIMiddleClick(mob/living/silicon/user)
	return FALSE

/obj/machinery/door/airlock/AIMiddleClick() // Toggles door bolt lights.
	if(usr.incapacitated())
		return FALSE
	if(..())
		return FALSE

	if(!src.lights)
		Topic(src, list("command"="lights", "activate" = "1"))
	else
		Topic(src, list("command"="lights", "activate" = "0"))
	return TRUE

//
// Override AdjacentQuick for AltClicking
//

/mob/living/silicon/ai/TurfAdjacent(turf/T)
	return (cameranet && cameranet.is_turf_visible(T))

/mob/living/silicon/ai/face_atom(atom/A)
	if(eyeobj)
		eyeobj.face_atom(A)


/turf/AICtrlClick(mob/user)
	var/obj/machinery/door/airlock/AL = locate(/obj/machinery/door/airlock) in contents
	if(AL)
		AL.AICtrlClick(user)
		return
	return ..()

/turf/AIAltClick(mob/user)
	var/obj/machinery/door/airlock/AL = locate(/obj/machinery/door/airlock) in contents
	if(AL)
		AL.AIAltClick(user)
		return
	return ..()

/turf/AIShiftClick(mob/user)
	var/obj/machinery/door/airlock/AL = locate(/obj/machinery/door/airlock) in contents
	if(AL)
		AL.AIShiftClick(user)
		return
	return ..()
