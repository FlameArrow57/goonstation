/datum/aiHolder/bloodling
	New()
		..()
		default_task = get_instance(/datum/aiTask/prioritizer/critter/bloodling, list(src))

/datum/aiTask/prioritizer/critter/bloodling/New()
	..()
	transition_tasks += holder.get_instance(/datum/aiTask/timed/wander/critter/aggressive, list(src.holder, src))
	transition_tasks += holder.get_instance(/datum/aiTask/sequence/goalbased/critter/attack/bloodling, list(src.holder, src))

/datum/aiTask/sequence/goalbased/critter/attack/bloodling

/datum/aiTask/sequence/goalbased/critter/attack/bloodling/New(parentHolder, transTask)
	..()
	src.subtasks -= /datum/aiTask/succeedable/critter/attack
	add_task(holder.get_instance(/datum/aiTask/succeedable/critter/attack/bloodling, list(src.holder)))

/datum/aiTask/succeedable/critter/attack/bloodling

/datum/aiTask/succeedable/critter/attack/bloodling/failed()
	. = ..()
	if (!src.holder.owner || !src.holder.target)
		return
	var/mob/living/critter/bloodling = src.holder.owner
	if (narrator_mode)
		playsound(bloodling.loc, 'sound/vox/ghost.ogg', 50, TRUE, -1)
	else
		playsound(bloodling.loc, 'sound/effects/ghost.ogg', 30, TRUE, -1)
	if (prob(50))
		var/mob/living/carbon/C = src.holder.target
		boutput(C, "<span class='combat'><b>You are forced to the ground by \the [bloodling]!</b></span>")
		random_brute_damage(C, rand(0, 5))
		C.changeStatus("stunned", 5 SECONDS)
		C.changeStatus("weakened", 5 SECONDS)
