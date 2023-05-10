/mob/living/critter/bloodling
	name = "bloodling"
	desc = "A force of pure sorrow and evil. They shy away from that which is holy."
	icon_state = "bling"

	density = 1
	hand_count = 1

	ai_type = /datum/aiHolder/bloodling
	is_npc = TRUE

	can_burn = FALSE
	canbegrabbed = FALSE
	throws_can_hit_me = FALSE
	reagent_capacity = 0
	can_bleed = FALSE // has custom bleed effects already
	metabolizes = FALSE
	use_stamina = FALSE

	var/obj/decal/cleanable/cleanable_type = /obj/decal/cleanable/blood
	var/what_is_sucked_out = "blood"

	New()
		UpdateParticles(new/particles/bloody_aura, "bloodaura")

		remove_lifeprocess(/datum/lifeprocess/blood)
		remove_lifeprocess(/datum/lifeprocess/chems)
		remove_lifeprocess(/datum/lifeprocess/fire)
		remove_lifeprocess(/datum/lifeprocess/mutations)
		remove_lifeprocess(/datum/lifeprocess/organs)
		remove_lifeprocess(/datum/lifeprocess/skin)
		remove_lifeprocess(/datum/lifeprocess/stuns_lying)
		remove_lifeprocess(/datum/lifeprocess/viruses)
		remove_lifeprocess(/datum/lifeprocess/blindness)
		remove_lifeprocess(/datum/lifeprocess/radiation)

		APPLY_ATOM_PROPERTY(src, PROP_MOB_RADPROT_INT, src, 100)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_RADPROT_EXT, src, 100)
		APPLY_ATOM_PROPERTY(src, PROP_ATOM_FLOATING, src)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_NIGHTVISION, src)
		..()

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.limb = new /datum/limb/bloodling_suck
		HH.name = "blood suck"
		HH.limb_name = HH.name
		HH.can_hold_items = FALSE

	setup_healths()
		src.add_hh_flesh(25, 0.5)
		src.add_hh_flesh_burn(25, 1)

	movement_delay(atom/move_target = 0, running = 0)
		. = BASE_SPEED

	Life(datum/controller/process/mobs/parent)
		..()
		if (prob(80))
			return
		if (!(locate(src.cleanable_type) in src.loc))
			playsound(src.loc, 'sound/impact_sounds/Slimy_Splat_1.ogg', 30, TRUE, -1)
			new src.cleanable_type(get_turf(src))

	seek_target(range = 5)
		. = list()
		for (var/mob/living/C in hearers(range, src))
			if (!iscarbon(C))
				continue
			if (isdead(C))
				continue
			if (istype(C, src.type))
				continue
			. += C

	attack_hand(mob/user)
		boutput(user, "<span class='combat'><b>Your hand passes right through \the [src]!</b></span>")

	attackby(obj/item/I, mob/living/user)
		if (I.reagents)
			if (I.reagents.has_reagent("water_holy"))
				..()
				boutput(user, "\the [src] screams!")
				src.death()
				return
			return ..()
		boutput(user, "<span class='combat'>Hitting it with [I] is ineffective!</span>")

	do_disorient(stamina_damage, weakened, stunned, paralysis, disorient = 60, remove_stamina_below_zero = 0, target_type = DISORIENT_BODY, stack_stuns = 1)
		return

	death(gibbed, do_drop_equipment)
		playsound(src.loc, 'sound/impact_sounds/Slimy_Splat_1.ogg', 30, TRUE, -1)
		new src.cleanable_type(get_turf(src))
		..()
		qdel(src)

/datum/limb/bloodling_suck

	harm(mob/living/target, mob/living/user)
		if (!iscarbon(target))
			return
		if (GET_COOLDOWN(user, "bloodsuck"))
			return
		ON_COOLDOWN(user, "bloodsuck", 0.5 SECONDS)

		playsound(user.loc, 'sound/effects/ghost2.ogg', 30, TRUE, -1)

		var/mob/living/critter/bloodling/bloodling = user

		if (prob(66))
			random_brute_damage(target, rand(5, 10))
			take_bleeding_damage(target, null, rand(10, 35), DAMAGE_CRUSH, 5, get_turf(target))
			boutput(target, "<span class='combat'><b>You feel [bloodling.what_is_sucked_out] getting drawn out through your skin!</b></span>")
		else
			boutput(target, "<span class='combat'>You feel uncomfortable. Your [bloodling.what_is_sucked_out] seeks to escape you.</span>")
			target.changeStatus("slowed", 3 SECONDS, 3)

// for admin gimmicks
/mob/living/critter/bloodling/ketchupling
	name = "Ketchupling"
	desc = "A force of pure tomato and evil. They shy away from that which is holy."
	cleanable_type = /obj/decal/cleanable/tomatosplat
	what_is_sucked_out = "ketchup"
