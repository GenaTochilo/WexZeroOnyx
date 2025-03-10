// At minimum every mob has a hear_say proc.

/mob/proc/hear_say(message, verb = "says", datum/language/language = null, alt_name = "", italics = FALSE, mob/speaker = null, sound/speech_sound, sound_vol)
	if(!client)
		return

	var/dist_speech = get_dist(speaker, src)
	var/near = dist_speech <= world.view

	if(speaker && !speaker.client && isghost(src) && get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH && !near)
			//Does the speaker have a client?  It's either random stuff that observers won't care about (Experiment 97B says, 'EHEHEHEHEHEHEHE')
			//Or someone snoring.  So we make it where they won't hear it.
		return

	//make sure the air can transmit speech - hearer's side
	var/turf/T = get_turf(src)
	if(T && !isghost(src)) //Ghosts can hear even in vacuum.
		var/datum/gas_mixture/environment = T.return_air()
		var/pressure = (environment) ? environment.return_pressure() : 0
		if(pressure < SOUND_MINIMUM_PRESSURE && dist_speech > 1)
			return

		if (pressure < ONE_ATMOSPHERE*0.4) //sound distortion pressure, to help clue people in that the air is thin, even if it isn't a vacuum yet
			italics = TRUE
			sound_vol *= 0.5 //muffle the sound a bit, so it's like we're actually talking through contact

	if(sleeping || stat == UNCONSCIOUS)
		hear_sleep(message)
		return

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if (language?.flags & NONVERBAL)
		if (!speaker || (src.sdisabilities & BLIND || src.blinded) || !near)
			message = stars(message)

	if(!(language && (language.flags & INNATE))) // skip understanding checks for INNATE languages
		if(!say_understands(speaker,language))
			if(istype(speaker,/mob/living/simple_animal))
				var/understand_animals = FALSE
				if(istype(src, /mob/living/carbon))
					var/mob/living/carbon/C = src
					understand_animals = C.is_hallucinating() && prob(15)
				if(!understand_animals)
					var/mob/living/simple_animal/S = speaker
					message = pick(S.speak)
			else
				if(language)
					message = language.scramble(message)
				else
					message = stars(message)

	var/speaker_name = "Unknown"
	if(speaker)
		speaker_name = speaker.name

	if(istype(speaker, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = speaker
		speaker_name = H.GetVoice()

	if(istype(src, /mob/living/carbon))
		var/mob/living/carbon/C = src
		var/mob/fake_speaker = C.get_fake_appearance(speaker)
		if(fake_speaker)
			if(istype(fake_speaker, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = fake_speaker
				speaker_name = H.GetVoice()
			else
				speaker_name = fake_speaker.name

	if(italics)
		message = "<i>[message]</i>"

	if(copytext_char(message, -2) == "!!") // two or more exclamation marks make them yell
		message = "<b>[message]</b>"

	var/track = null
	if(isghost(src))
		if(speaker?.real_name && speaker_name != speaker.real_name)
			speaker_name = "[speaker.real_name] ([speaker_name])"
		track = "([ghost_follow_link(speaker, src)]) "
		if(get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH && near)
			message = "<b>[message]</b>"

	if(is_deaf())
		if(!language || !(language.flags & INNATE)) // INNATE is the flag for audible-emote-language, so we don't want to show an "x talks but you cannot hear them" message if it's set
			if(speaker == src)
				to_chat(src, SPAN("warning", "You cannot hear yourself speak!"))
			else if(!is_blind())
				to_chat(src, "[SPAN("name", "[speaker_name]")][alt_name] talks but you cannot hear \him.")
	else
		if(istype(src,/mob/living) && src.mind && src.mind.syndicate_awareness == SYNDICATE_SUSPICIOUSLY_AWARE)
			message = highlight_codewords(message, GLOB.code_phrase_highlight_rule)  //  Same can be done with code_response or any other list of words, using regex created by generate_code_regex(). You can also add the name of CSS class as argument to change highlight style.
		if(language)
			var/nverb = null
			if(!say_understands(speaker,language) || language.name == LANGUAGE_GALCOM) //Check to see if we can understand what the speaker is saying. If so, add the name of the language after the verb. Don't do this for Galactic Common.
				on_hear_say(SPAN("game say", "[SPAN("name", "[speaker_name]")][alt_name] [track][language.format_message(message, verb)]"))
			else //Check if the client WANTS to see language names.
				switch(src.get_preference_value(/datum/client_preference/language_display))
					if(GLOB.PREF_FULL) // Full language name
						nverb = "[verb] in [language.name]"
					if(GLOB.PREF_SHORTHAND) //Shorthand codes
						nverb = "[verb] ([language.shorthand])"
					if(GLOB.PREF_OFF)//Regular output
						nverb = verb
				on_hear_say(SPAN("game say", "[SPAN("name", "[speaker_name]")][alt_name] [track][language.format_message(message, nverb)]"))

		else
			on_hear_say(SPAN("game say", "[SPAN("name", "[speaker_name]")][alt_name] [track][verb], [SPAN("message", SPAN("body", "\"[message]\""))]"))
		if(speech_sound && speaker && (dist_speech <= world.view && src.z == speaker.z))
			var/turf/source = get_turf(speaker)
			src.playsound_local(source, speech_sound, sound_vol, 1)
		if(get_preference_value(/datum/client_preference/runechat) == GLOB.PREF_YES)
			create_chat_message(speaker, message)

/mob/proc/on_hear_say(message)
	to_chat(src, message)

/mob/living/silicon/on_hear_say(message)
	var/time = say_timestamp()
	to_chat(src, "[time] [message]")

/mob/proc/hear_radio(message, verb="says", datum/language/language=null, part_a, part_b, part_c, mob/speaker = null, hard_to_hear = 0, vname ="", loud)

	if(!client)
		return

	if(sleeping || stat == UNCONSCIOUS)
		hear_sleep(message)
		return

	var/track = null

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if (language?.flags & NONVERBAL)
		if (!speaker || (src.sdisabilities & BLIND || src.blinded) || !(speaker in view(src)))
			message = stars(message)

	if(!(language?.flags & INNATE)) // skip understanding checks for INNATE languages
		if(!say_understands(speaker, language))
			if(istype(speaker,/mob/living/simple_animal))
				var/mob/living/simple_animal/S = speaker
				if(S.speak?.len)
					message = pick(S.speak)
				else
					return
			else
				if(language)
					message = language.scramble(message)
				else
					message = stars(message)

		if(hard_to_hear)
			if(hard_to_hear <= 5)
				message = stars(message)
			else // Used for compression
				message = RadioChat(null, message, 80, 1+(hard_to_hear/10))

	if(copytext_char(message, -2) == "!!")
		message = "<b>[message]</b>"

	var/speaker_name = vname ? vname : speaker?.name

	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		if(H.voice)
			speaker_name = H.voice

	if(hard_to_hear)
		speaker_name = "Unknown"

	var/changed_voice = FALSE

	if(isAI(src) && !hard_to_hear)
		var/jobname // the mob's "job"
		var/mob/living/carbon/human/impersonating //The crew member being impersonated, if any.

		if(ishuman(speaker))
			var/mob/living/carbon/human/H = speaker

			if(H.wear_mask && istype(H.wear_mask, /obj/item/clothing/mask/chameleon/voice))
				changed_voice = TRUE
				var/list/impersonated = new()
				var/mob/living/carbon/human/I = impersonated[speaker_name]

				if(!I)
					for(var/mob/living/carbon/human/M in SSmobs.mob_list)
						if(M.real_name == speaker_name)
							I = M
							impersonated[speaker_name] = I
							break

				// If I's display name is currently different from the voice name and using an agent ID then don't impersonate
				// as this would allow the AI to track I and realize the mismatch.
				if(I && !(I.name != speaker_name && I.wear_id && istype(I.wear_id,/obj/item/card/id/syndicate)))
					impersonating = I
					jobname = impersonating.get_assignment()
				else
					jobname = "Unknown"
			else
				jobname = H.get_assignment()

		else if (iscarbon(speaker)) // Nonhuman carbon mob
			jobname = "No id"
		else if (isAI(speaker))
			jobname = "AI"
		else if (isrobot(speaker))
			jobname = "Cyborg"
		else if (istype(speaker, /mob/living/silicon/pai))
			jobname = "Personal AI"
		else
			jobname = "Unknown"

		if(changed_voice)
			if(impersonating)
				track = "<a href='byond://?src=\ref[src];trackname=[html_encode(speaker_name)];track=\ref[impersonating]'>[speaker_name] ([jobname])</a>"
			else
				track = "[speaker_name] ([jobname])"
		else
			track = "<a href='byond://?src=\ref[src];trackname=[html_encode(speaker_name)];track=\ref[speaker]'>[speaker_name] ([jobname])</a>"

	if(isghost(src))
		if(speaker?.real_name && speaker_name != speaker.real_name && !isAI(speaker)) //Announce computer and various stuff that broadcasts doesn't use it's real name but AI's can't pretend to be other mobs.
			speaker_name = "[speaker.real_name] ([speaker_name])"
		track = "[speaker_name] ([ghost_follow_link(speaker, src)])"

	if(istype(src,/mob/living) && src.mind && src.mind.syndicate_awareness == SYNDICATE_SUSPICIOUSLY_AWARE)
		message = highlight_codewords(message, GLOB.code_phrase_highlight_rule) //  Same can be done with code_response or any other list of words, using regex created by generate_code_regex(). You can also add the name of CSS class as argument to change highlight style.
	var/formatted
	if(language)
		if(!say_understands(speaker, language) || language.name == LANGUAGE_GALCOM) //Check if we understand the message. If so, add the language name after the verb. Don't do this for Galactic Common.
			formatted = language.format_message_radio(message, verb)
		else
			var/nverb = null
			switch(src.get_preference_value(/datum/client_preference/language_display))
				if(GLOB.PREF_FULL) // Full language name
					nverb = "[verb] in [language.name]"
				if(GLOB.PREF_SHORTHAND) //Shorthand codes
					nverb = "[verb] ([language.shorthand])"
				if(GLOB.PREF_OFF)//Regular output
					nverb = verb
			formatted = language.format_message_radio(message, nverb)
	else
		formatted = "[verb], [SPAN("body", "\"[message]\"")]"
	if(sdisabilities & DEAF || ear_deaf)
		var/mob/living/carbon/human/H = src
		if(istype(H) && H.has_headset_in_ears() && prob(20))
			to_chat(src, SPAN("warning", "You feel your headset vibrate [loud ? "really hard " : ""]but can hear nothing from it!"))
	else
		on_hear_radio(part_a, speaker_name, track, part_b, part_c, formatted, loud)

/proc/say_timestamp()
	return SPAN("say_quote", "\[[stationtime2text()]\]")

/mob/proc/on_hear_radio(part_a, speaker_name, track, part_b, part_c, formatted, loud)
	var/text = "[part_a][speaker_name][part_b][formatted][part_c]"
	if(loud)
		text = FONT_LARGE(text)
	to_chat(src, text)

/mob/observer/ghost/on_hear_radio(part_a, speaker_name, track, part_b, part_c, formatted, loud)
	var/text = "[part_a][track][part_b][formatted][part_c]"
	if(loud)
		text = FONT_LARGE(text)
	to_chat(src, text)

/mob/living/silicon/on_hear_radio(part_a, speaker_name, track, part_b, part_c, formatted, loud)
	var/text = "[say_timestamp()][part_a][speaker_name][part_b][formatted][part_c]"
	if(loud)
		text = FONT_LARGE(text)
	to_chat(src, text)

/mob/living/silicon/ai/on_hear_radio(part_a, speaker_name, track, part_b, part_c, formatted, loud)
	var/text = "[say_timestamp()][part_a][track][part_b][formatted][part_c]"
	if(loud)
		text = FONT_LARGE(text)
	to_chat(src, text)

/mob/proc/hear_signlang(message, verb = "gestures", datum/language/language, mob/speaker = null)
	if(!client)
		return

	if(sleeping || stat == UNCONSCIOUS)
		return FALSE

	if(say_understands(speaker, language))
		var/nverb = null
		switch(src.get_preference_value(/datum/client_preference/language_display))
			if(GLOB.PREF_FULL) // Full language name
				nverb = "[verb] in [language.name]"
			if(GLOB.PREF_SHORTHAND) //Shorthand codes
				nverb = "[verb] ([language.shorthand])"
			if(GLOB.PREF_OFF)//Regular output
				nverb = verb
		message = "<B>[speaker]</B> [nverb], \"[message]\""
	else
		var/adverb
		var/length = length(message) * pick(0.8, 0.9, 1.0, 1.1, 1.2)	//Inserts a little fuzziness.
		switch(length)
			if(0 to 12) 	adverb = " briefly"
			if(12 to 30)	adverb = " a short message"
			if(30 to 48)	adverb = " a message"
			if(48 to 90)	adverb = " a lengthy message"
			else        	adverb = " a very lengthy message"
		message = "<B>[speaker]</B> [verb][adverb]."

	if(src.status_flags & PASSEMOTES)
		for(var/obj/item/holder/H in src.contents)
			H.show_message(message)
		for(var/mob/living/M in src.contents)
			M.show_message(message)
	src.show_message(message)

/mob/proc/hear_sleep(message)
	var/heard = ""
	if(prob(15))
		var/list/punctuation = list(",", "!", ".", ";", "?")
		var/list/messages = splittext(message, " ")
		var/R = rand(1, messages.len)
		var/heardword = messages[R]
		if(copytext(heardword, 1, 1) in punctuation)
			heardword = copytext(heardword, 2)
		if(copytext(heardword, -1) in punctuation)
			heardword = copytext(heardword, 1, length(heardword))
		heard = SPAN("game_say", "...<i>You hear something about</i>... <i>[heardword]</i>...")

	else
		heard = SPAN("game_say", "...<i>You almost hear someone talking</i>...")

	to_chat(src, heard)
