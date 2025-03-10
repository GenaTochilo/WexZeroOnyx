/datum/artifact_effect/gravity
	name = "gravity"
	effect_type = EFFECT_ENERGY

	var/pull_strength


/datum/artifact_effect/gravity/New()
	..()
	effectrange = rand(3,12)
	pull_strength = pick(STAGE_ONE,STAGE_TWO,STAGE_THREE,STAGE_FOUR,10;STAGE_FIVE)

/datum/artifact_effect/gravity/DoEffectTouch()
	gravitypull(effectrange)

/datum/artifact_effect/gravity/DoEffectAura()
	gravitypull(round(effectrange/3))

/datum/artifact_effect/gravity/DoEffectPulse()
	gravitypull(effectrange)

/datum/artifact_effect/gravity/proc/gravitypull(range)
	for(var/atom/X in orange(effectrange, holder))
		if(X.type == /atom/movable/lighting_overlay)
			continue
		if(istype(X, /mob/living) && X.Adjacent(holder))
			var/mob/living/L = X
			to_chat(L, SPAN("warning", "You are [pull_strength >= STAGE_FOUR ? "painfully crushed onto" : "pulled against"] \the [holder]!"))
			if(pull_strength >= STAGE_FOUR)
				L.take_overall_damage(10)
			continue
		X.singularity_pull(holder, pull_strength, 0)
