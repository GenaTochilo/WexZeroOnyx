/obj/item/device/taperecorder
	name = "universal recorder"
	desc = "A device that can record to cassette tapes, and play them. It automatically translates the content in playback."
	icon_state = "taperecorder"
	item_state = "analyzer"
	w_class = ITEM_SIZE_SMALL

	matter = list(MATERIAL_STEEL = 60, MATERIAL_GLASS = 30)

	var/emagged = 0.0
	var/recording = 0.0
	var/playing = 0.0
	var/playsleepseconds = 0.0
	var/obj/item/device/tape/mytape = /obj/item/device/tape/random
	var/canprint = 1
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT
	throwforce = 2
	throw_range = 20

/obj/item/device/taperecorder/New()
	..()

	if(ispath(mytape))
		mytape = new mytape(src)

	GLOB.listening_objects += src
	update_icon()

/obj/item/device/taperecorder/empty
	mytape = null

/obj/item/device/taperecorder/Destroy()
	GLOB.listening_objects -= src
	if(mytape)
		qdel(mytape)
		mytape = null
	return ..()


/obj/item/device/taperecorder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/device/tape))
		if(mytape)
			to_chat(user, SPAN("notice", "There's already a tape inside."))
			return
		if(!user.drop(I, src))
			return
		mytape = I
		to_chat(user, SPAN("notice", "You insert [I] into [src]."))
		update_icon()
		return
	..()


/obj/item/device/taperecorder/fire_act()
	if(mytape)
		mytape.ruin() //Fires destroy the tape
	return ..()


/obj/item/device/taperecorder/attack_hand(mob/user)
	if(user.get_inactive_hand() == src)
		if(mytape)
			eject()
			return
	..()


/obj/item/device/taperecorder/verb/eject()
	set name = "Eject Tape"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(!mytape)
		to_chat(usr, SPAN("notice", "There's no tape in \the [src]."))
		return
	if(emagged)
		to_chat(usr, SPAN("notice", "The tape seems to be stuck inside."))
		return

	if(playing || recording)
		stop()
	to_chat(usr, SPAN("notice", "You remove [mytape] from [src]."))
	usr.pick_or_drop(mytape)
	mytape = null
	update_icon()


/obj/item/device/taperecorder/hear_talk(mob/living/M as mob, msg, verb="says", datum/language/speaking=null)
	if(mytape && recording)

		if(speaking)
			if(!speaking.machine_understands)
				msg = speaking.scramble(msg)
			mytape.record_speech("[M.GetVoice()] [speaking.format_message_plain(msg, verb)]")
		else
			mytape.record_speech("[M.GetVoice()] [verb], \"[msg]\"")


/obj/item/device/taperecorder/see_emote(mob/M as mob, text, emote_type)
	if(emote_type != AUDIBLE_MESSAGE) //only hearable emotes
		return
	if(mytape && recording)
		mytape.record_speech("[strip_html_properly(text)]")


/obj/item/device/taperecorder/show_message(msg, type, alt, alt_type)
	var/recordedtext
	if (msg && type == AUDIBLE_MESSAGE) //must be hearable
		recordedtext = msg
	else if (alt && alt_type == AUDIBLE_MESSAGE)
		recordedtext = alt
	else
		return
	if(mytape && recording)
		mytape.record_noise("[strip_html_properly(recordedtext)]")

/obj/item/device/taperecorder/emag_act(remaining_charges, mob/user)
	if(emagged == 0)
		emagged = 1
		recording = 0
		to_chat(user, SPAN("warning", "PZZTTPFFFT"))
		update_icon()
		return 1
	else
		to_chat(user, SPAN("warning", "It is already emagged!"))

/obj/item/device/taperecorder/proc/explode()
	var/turf/T = get_turf(loc)
	if(ismob(loc))
		var/mob/M = loc
		to_chat(M, SPAN("danger", "\The [src] explodes!"))
	if(T)
		T.hotspot_expose(700,125)
		explosion(T, -1, -1, 0, 4)
	qdel(src)
	return

/obj/item/device/taperecorder/verb/record()
	set name = "Start Recording"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(!mytape)
		to_chat(usr, SPAN("notice", "There's no tape!"))
		return
	if(mytape.ruined || emagged)
		audible_message(SPAN("warning", "The tape recorder makes a scratchy noise."), runechat_message = "*schtsch*")
		return
	if(recording)
		to_chat(usr, SPAN("notice", "You're already recording!"))
		return
	if(playing)
		to_chat(usr, SPAN("notice", "You can't record when playing!"))
		return
	if(mytape.used_capacity < mytape.max_capacity)
		playsound(src.loc, 'sound/effects/recorder/start1.ogg', 15)
		to_chat(usr, SPAN("notice", "Recording started."))
		recording = 1
		update_icon()

		mytape.record_speech("Recording started.")

		//count seconds until full, or recording is stopped
		while(mytape && recording && mytape.used_capacity < mytape.max_capacity)
			sleep(10)
			mytape.used_capacity++
			if(mytape.used_capacity >= mytape.max_capacity)
				if(ismob(loc))
					var/mob/M = loc
					to_chat(M, SPAN("notice", "The tape is full."))
				stop_recording()


		update_icon()
		return
	else
		to_chat(usr, SPAN("notice", "The tape is full."))


/obj/item/device/taperecorder/proc/stop_recording()
	//Sanity checks skipped, should not be called unless actually recording
	recording = 0
	update_icon()
	mytape.record_speech("Recording stopped.")
	if(ismob(loc))
		var/mob/M = loc
		to_chat(M, SPAN("notice", "Recording stopped."))


/obj/item/device/taperecorder/verb/stop()
	set name = "Stop"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(recording)
		playsound(src.loc, 'sound/effects/recorder/stop1.ogg', 15)
		stop_recording()
		return
	else if(playing)
		playsound(src.loc, 'sound/effects/recorder/stop1.ogg', 15)
		playing = 0
		update_icon()
		to_chat(usr, SPAN("notice", "Playback stopped."))
		return
	else
		to_chat(usr, SPAN("notice", "Stop what?"))


/obj/item/device/taperecorder/verb/wipe_tape()
	set name = "Wipe Tape"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(emagged || mytape.ruined)
		audible_message(SPAN("warning", "The tape recorder makes a scratchy noise."), runechat_message = "*schtsch*")
		return
	if(recording || playing)
		to_chat(usr, SPAN("notice", "You can't wipe the tape while playing or recording!"))
		return
	else
		playsound(src.loc, 'sound/effects/recorder/stop1.ogg', 15)
		playsound(src.loc, 'sound/effects/recorder/wipe1.ogg', 15)
		if(mytape.storedinfo)	mytape.storedinfo.Cut()
		if(mytape.timestamp)	mytape.timestamp.Cut()
		mytape.used_capacity = 0
		to_chat(usr, SPAN("notice", "You wipe the tape."))
		return


/obj/item/device/taperecorder/verb/playback_memory()
	set name = "Playback Tape"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(!mytape)
		to_chat(usr, SPAN("notice", "There's no tape!"))
		return
	if(mytape.ruined)
		audible_message(SPAN("warning", "The tape recorder makes a scratchy noise."), runechat_message = "*schtsch*")
		return
	if(recording)
		to_chat(usr, SPAN("notice", "You can't playback when recording!"))
		return
	if(playing)
		to_chat(usr, SPAN("notice", "You're already playing!"))
		return
	playsound(src.loc, 'sound/effects/recorder/start1.ogg', 15)
	playsound(src.loc, 'sound/effects/recorder/playback1.ogg', 15)
	playing = 1
	update_icon()
	to_chat(usr, SPAN("notice", "Audio playback started."))
	for(var/i=1 , i < mytape.max_capacity , i++)
		if(!mytape || !playing)
			break
		if(mytape.storedinfo.len < i)
			break

		var/turf/T = get_turf(src)
		var/playedmessage = mytape.storedinfo[i]
		if (findtextEx(playedmessage,"*",1,2)) //remove marker for action sounds
			playedmessage = copytext(playedmessage,2)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: [playedmessage]</font>", runechat_message = "<font color=Maroon>[playedmessage]</font>")

		if(mytape.storedinfo.len < i+1)
			playsleepseconds = 1
			sleep(10)
			T = get_turf(src)
			T.audible_message("<font color=Maroon><B>Tape Recorder</B>: End of recording.</font>", runechat_message = "<font color=Maroon>End of recording</font>")
			break
		else
			playsleepseconds = mytape.timestamp[i+1] - mytape.timestamp[i]

		if(playsleepseconds > 14)
			sleep(10)
			T = get_turf(src)
			T.audible_message("<font color=Maroon><B>Tape Recorder</B>: Skipping [playsleepseconds] seconds of silence</font>", runechat_message = "<font color=Maroon>Skipping [playsleepseconds] seconds</font>")
			playsleepseconds = 1
		sleep(10 * playsleepseconds)


	playing = 0
	update_icon()

	if(emagged)
		var/turf/T = get_turf(src)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: This tape recorder will self-destruct in... Five.</font>", runechat_message = "<font color=Maroon>Self-destruct in... Five</font>")
		sleep(10)
		T = get_turf(src)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: Four.</font>", runechat_message = "<font color=Maroon>Four</font>")
		sleep(10)
		T = get_turf(src)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: Three.</font>", runechat_message = "<font color=Maroon>Three</font>")
		sleep(10)
		T = get_turf(src)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: Two.</font>", runechat_message = "<font color=Maroon>Two</font>")
		sleep(10)
		T = get_turf(src)
		T.audible_message("<font color=Maroon><B>Tape Recorder</B>: One.</font>", runechat_message = "<font color=Maroon>One</font>")
		sleep(10)
		explode()


/obj/item/device/taperecorder/verb/print_transcript()
	set name = "Print Transcript"
	set category = "Object"

	if(usr.incapacitated())
		return
	if(!mytape)
		to_chat(usr, SPAN("notice", "There's no tape!"))
		return
	if(mytape.ruined || emagged)
		audible_message(SPAN("warning", "The tape recorder makes a scratchy noise."), runechat_message = "*schtsch*")
		return
	if(!canprint)
		to_chat(usr, SPAN("notice", "The recorder can't print that fast!"))
		return
	if(recording || playing)
		to_chat(usr, SPAN("notice", "You can't print the transcript while playing or recording!"))
		return

	to_chat(usr, SPAN("notice", "Transcript printed."))
	var/t1 = "<B>Transcript:</B><BR><BR>"
	for(var/i in 1 to mytape.storedinfo.len)
		var/printedmessage = mytape.storedinfo[i]
		if (findtextEx(printedmessage,"*",1,2)) //replace action sounds
			printedmessage = "\[[time2text(mytape.timestamp[i]*10,"mm:ss")]\] (Unrecognized sound)"
		t1 += "[printedmessage]<BR>"
	var/obj/item/paper/P = new /obj/item/paper(get_turf(src))
	P.set_content(t1, "Transcript", TRUE)
	canprint = 0
	sleep(300)
	canprint = 1


/obj/item/device/taperecorder/attack_self(mob/user)
	if(recording || playing)
		stop()
	else
		record()


/obj/item/device/taperecorder/update_icon()
	if(!mytape)
		icon_state = "[initial(icon_state)]_empty"
	else if(recording)
		icon_state = "[initial(icon_state)]_recording"
	else if(playing)
		icon_state = "[initial(icon_state)]_playing"
	else
		icon_state = "[initial(icon_state)]_idle"

/obj/item/device/tape
	name = "bluespace tape"
	desc = "A tape that can hold an infinite amount of correspondence."
	icon_state = "tape_white"
	item_state = "analyzer"
	w_class = ITEM_SIZE_TINY
	matter = list(MATERIAL_STEEL=20, MATERIAL_GLASS=5)
	force = 1
	throwforce = 0
	var/max_capacity = 9e40 // Literal infinite storage
	var/used_capacity = 0
	var/list/storedinfo = new /list()
	var/list/timestamp = new /list()
	var/ruined = 0


/obj/item/device/tape/update_icon()
	overlays.Cut()
	if(ruined)
		overlays += "ribbonoverlay"


/obj/item/device/tape/fire_act()
	ruin()

/obj/item/device/tape/attack_self(mob/user)
	if(!ruined)
		to_chat(user, SPAN("notice", "You pull out all the tape!"))
		ruin()


/obj/item/device/tape/proc/ruin()
	ruined = 1
	update_icon()


/obj/item/device/tape/proc/fix()
	ruined = 0
	update_icon()


/obj/item/device/tape/proc/record_speech(text)
	timestamp += used_capacity
	storedinfo += "\[[time2text(used_capacity*10,"mm:ss")]\] [text]"


//shows up on the printed transcript as (Unrecognized sound)
/obj/item/device/tape/proc/record_noise(text)
	timestamp += used_capacity
	storedinfo += "*\[[time2text(used_capacity*10,"mm:ss")]\] [text]"


/obj/item/device/tape/attackby(obj/item/I, mob/user, params)
	if(ruined && isScrewdriver(I))
		to_chat(user, SPAN("notice", "You start winding the tape back in..."))
		if(do_after(user, 120, target = src))
			to_chat(user, SPAN("notice", "You wound the tape back in."))
			fix()
		return
	else if(istype(I, /obj/item/pen))
		if(loc == user && !user.incapacitated())
			var/new_name = sanitize(input(user, "What would you like to label the tape?", "Tape labeling") as null|text)
			if(isnull(new_name)) return
			new_name = sanitizeSafe(new_name)
			if(new_name)
				SetName("tape - '[new_name]'")
				to_chat(user, SPAN("notice", "You label the tape '[new_name]'."))
			else
				SetName("tape")
				to_chat(user, SPAN("notice", "You scratch off the label."))
		return
	..()


//Random colour tapes
/obj/item/device/tape/random/New()
	icon_state = "tape_[pick("white", "blue", "red", "yellow", "purple")]"
