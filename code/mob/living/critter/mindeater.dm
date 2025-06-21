/mob/living/critter/mindeater
	name = "mindeater"
	real_name = "mindeater"
	desc = "What sort of eldritch abomination is this thing???"
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "intruder"

	custom_hud_type = /datum/hud/critter/mindeater

	hand_count = 1

	can_bleed = FALSE
	can_lie = FALSE
	can_implant = FALSE
	metabolizes = FALSE
	reagent_capacity = 0

	/*
	speechverb_say = "hums"
	speechverb_gasp = "hums"
	speechverb_stammer = "hums"
	speechverb_exclaim = "hums"
	speechverb_ask = "hums"
	*/

	/// shows whether this mindeater is visible to all or not
	var/image/mindeater_visibility_indicator/vis_indicator
	/// shows health of the mindeater
	var/image/mindeater_health_indicator/hp_indicator
	/// currently casting paralyze ability
	var/casting_paralyze = FALSE
	/// what this mindeater's disguise is set to
	var/set_disguise = MINDEATER_DISGUISE_HUMAN
	/// if this mindeater is using a disguise
	var/disguised = FALSE
	/// fake human disguise, stored as a var to prevent unnecessary creation/deletion over and over since humans don't GC well
	var/mob/living/carbon/human/normal/assistant/human_disguise_dummy

	var/lives = 3 // temporary lives for playtesting

	/// can fire psi bolts when disguised
	var/can_fire_when_disguised = TRUE

	New()
		src.name = "???" // set here so that in respawn popups the name doesn't appear as "???"
		..()
		APPLY_ATOM_PROPERTY(src, PROP_MOB_HEATPROT, src, 100)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_COLDPROT, src, 100)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_RADPROT_INT, src, 100)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_NIGHTVISION, src)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_NO_MOVEMENT_PUFFS, src)
		remove_lifeprocess(/datum/lifeprocess/radiation)
		remove_lifeprocess(/datum/lifeprocess/chems)
		remove_lifeprocess(/datum/lifeprocess/blood)
		remove_lifeprocess(/datum/lifeprocess/mutations)

		QDEL_NULL(src.organHolder)

		src.add_ability_holder(/datum/abilityHolder/mindeater)

		src.see_invisible = INVIS_INTRUDER

		src.vis_indicator = new (loc = src)

		src.hp_indicator = new (loc = src)

		src.demanifest()

		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).add_mob(src)
		get_image_group(CLIENT_IMAGE_GROUP_MINDEATER_STRUCTURE_VISION).add_mob(src)

		src.ensure_speech_tree().AddSpeechOutput(SPEECH_OUTPUT_INTRUDERCHAT)
		src.ensure_listen_tree().AddListenInput(LISTEN_INPUT_INTRUDERCHAT)

		src.human_disguise_dummy = new

	disposing()
		..()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).remove_mob(src)
		get_image_group(CLIENT_IMAGE_GROUP_MINDEATER_STRUCTURE_VISION).remove_mob(src)
		QDEL_NULL(src.vis_indicator)
		QDEL_NULL(src.hp_indicator)

		src.ensure_speech_tree().RemoveSpeechOutput(SPEECH_OUTPUT_INTRUDERCHAT)
		src.ensure_listen_tree().RemoveListenInput(LISTEN_INPUT_INTRUDERCHAT)

		QDEL_NULL(src.human_disguise_dummy)

	Life()
		. = ..()
		if (src.is_intangible())
			return
		if (istype(get_turf(src), /turf/space) && !istype(get_turf(src), /turf/space/fluid))
			src.TakeDamage("All", 10, 10)
		if (src.disguised)
			return
		if (src.pulling)
			src.reveal(FALSE)
			return
		if (actions.hasAction(src, /datum/action/bar/private/mindeater_brain_drain) || src.casting_paralyze || actions.hasAction(src, /datum/action/bar/mindeater_pierce_the_veil))
			return
		if (src.on_bright_turf())
			src.delStatus("mindeater_cloaking")
			if (!src.hasStatus("mindeater_appearing") && !src.is_visible())
				src.setStatus("mindeater_appearing", 10 SECONDS)
		else
			src.delStatus("mindeater_appearing")
			if (!src.hasStatus("mindeater_cloaking") && src.is_visible())
				src.setStatus("mindeater_cloaking", 5 SECONDS)

	death(gibbed)
		gibbed = FALSE
		if (src.lives < 0)
			return ..()
		src.lives--
		. = ..()
		src.full_heal()
		src.demanifest()
		for (var/datum/statusEffect/status in src.statusEffects)
			qdel(status)
		var/datum/abilityHolder/abil_holder = src.get_ability_holder(/datum/abilityHolder/mindeater)
		var/datum/targetable/critter/mindeater/manifest/abil = abil_holder.getAbility(/datum/targetable/critter/mindeater/manifest/)
		abil_holder.deductPoints(abil_holder.points)
		abil.doCooldown()

	gib()
		src.death(FALSE)

	setup_healths()
		add_hh_flesh(62, 1)
		add_hh_flesh_burn(62, 1)

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[1]
		HH.name = "psionic-kinetic bolt"
		HH.limb = new /datum/limb/gun/kinetic/mindeater
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.icon_state = "psi_bolt"
		HH.limb_name = "psi bolt"
		HH.can_hold_items = FALSE
		HH.can_range_attack = TRUE

	TakeDamage(zone, brute, burn, tox, damage_type, disallow_limb_loss)
		if (src.is_intangible())
			return
		..()
		src.hp_indicator.set_icon_state(round(src.get_health_percentage() * 100, 20))
		if (brute > 0 || burn > 0 || tox > 0)
			src.reveal()

	attack_hand(mob/living/M)
		..()
		if (M.a_intent == INTENT_HARM)
			for (var/datum/statusEffect/pierce_the_veil_channel_shield/shield in src.statusEffects)
				shield.process_hit()

	attackby(obj/item/I, mob/M)
		..()
		for (var/datum/statusEffect/pierce_the_veil_channel_shield/shield in src.statusEffects)
			shield.process_hit()

	bullet_act(obj/projectile/P)
		..()
		if (!istype(P.proj_data, /datum/projectile/special/psi_bolt))
			for (var/datum/statusEffect/pierce_the_veil_channel_shield/shield in src.statusEffects)
				shield.process_hit()

	bump(atom/A)
		..()
		if (A.density && A.material?.getProperty("reflective") > 7)
			src.set_loc(get_turf(A))
		else if (istype(A, /obj/machinery/door/airlock) && !istype(A, /obj/machinery/door/airlock/pyro/weapons/secure))
			var/obj/machinery/door/airlock/airlock = A
			airlock.open()

	do_disorient(stamina_damage, knockdown, stunned, unconscious, disorient, remove_stamina_below_zero, target_type, stack_stuns)
		stamina_damage = 0
		src.reveal()
		..()

	apply_flash(animation_duration, knockdown, stun, misstep, eyes_blurry, eyes_damage, eye_tempblind, burn, uncloak_prob, stamina_damage, disorient_time)
		stamina_damage = 0
		src.reveal()
		..()

	is_heat_resistant()
		return TRUE

	is_cold_resistant()
		return TRUE

	is_spacefaring()
		return src.is_intangible()

	movement_delay()
		. = ..()
		if (src.is_intangible())
			return . / 3

	nauseate(stacks)
		return

	can_pull(atom/A)
		. = ..()
		if (src.is_intangible())
			return FALSE

	set_pulling(atom/movable/AM)
		..()
		if (src.pulling)
			src.reveal(FALSE)

	//say_understands(var/other)
	//	return 1

	//understands_language(langname)
	//	if (langname == src.say_language || langname == "feather" || langname == "english") // understands but can't speak flock
	//		return TRUE
	//	return FALSE

	shock(atom/origin, wattage, zone = "chest", stun_multiplier = 1, ignore_gloves = 0)
		if (src.is_intangible())
			return
		src.reveal()
		return ..()

	ex_act(severity)
		if (src.is_intangible())
			return
		src.reveal()
		return ..()

	/// returns if the turf is bright enough to reveal the mindeater
	proc/on_bright_turf()
		var/turf/T = get_turf(src)
		return T.is_lit()

	/// if the mindeater is effectively intangible
	proc/is_intangible()
		return src.event_handler_flags & MOVE_NOCLIP

	/// if the mindeater is visible to all humans
	proc/is_visible()
		return src.invisibility == INVIS_NONE

	/// reveal the mindeater's true form to all
	proc/reveal(remove_disguise = TRUE)
		src.delStatus("mindeater_appearing")
		src.delStatus("mindeater_cloaking")
		src.vis_indicator.set_visible(TRUE)
		src.invisibility = INVIS_NONE
		if (remove_disguise)
			src.undisguise()

	/// set the mindeater invisible to humans
	proc/set_invisible()
		src.delStatus("mindeater_appearing")
		src.delStatus("mindeater_cloaking")
		src.vis_indicator.set_visible(FALSE)
		src.invisibility = INVIS_INTRUDER

	/// move from intangible to tangible state
	proc/manifest()
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/manifest)
		src.event_handler_flags &= ~(MOVE_NOCLIP | IMMUNE_OCEAN_PUSH | IMMUNE_SINGULARITY | IMMUNE_TRENCH_WARP)
		src.flags &= ~UNCRUSHABLE
		src.density = TRUE
		src.set_invisible()
		src.alpha = 255
		REMOVE_ATOM_PROPERTY(src, PROP_MOB_ACTING_INTANGIBLE, src)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/brain_drain)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/regenerate)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/project)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/spatial_swap)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/paralyze)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/cosmic_light)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/pierce_the_veil)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/set_disguise)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/disguise)

	/// move from tangible to intangible state
	proc/demanifest()
		src.event_handler_flags |= (MOVE_NOCLIP | IMMUNE_OCEAN_PUSH | IMMUNE_SINGULARITY | IMMUNE_TRENCH_WARP)
		src.flags |= UNCRUSHABLE
		src.density = FALSE
		src.set_invisible()
		src.alpha = 150
		APPLY_ATOM_PROPERTY(src, PROP_MOB_ACTING_INTANGIBLE, src)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/brain_drain)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/regenerate)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/project)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/spatial_swap)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/paralyze)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/cosmic_light)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/pierce_the_veil)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/set_disguise)
		src.abilityHolder.removeAbility(/datum/targetable/critter/mindeater/disguise)
		src.abilityHolder.addAbility(/datum/targetable/critter/mindeater/manifest)

		src.remove_pulling()

	/// gain intellect points from target mob
	proc/collect_intellect(mob/living/carbon/human/H, points)
		APPLY_ATOM_PROPERTY(H, PROP_MOB_INTELLECT_COLLECTED, H, min(GET_ATOM_PROPERTY(H, PROP_MOB_INTELLECT_COLLECTED) + points, 100))
		if (GET_ATOM_PROPERTY(H, PROP_MOB_INTELLECT_COLLECTED) >= 100)
			H.brain_level.set_icon_state("complete")
		else
			H.brain_level.set_icon_state(floor(GET_ATOM_PROPERTY(H, PROP_MOB_INTELLECT_COLLECTED) / 10) * 10, INTRUDER_MAX_INTELLECT_THRESHOLD)

		var/datum/abilityHolder/abil_holder = src.get_ability_holder(/datum/abilityHolder/mindeater)
		if (H.reagents.has_reagent("ethanol"))
			abil_holder.addPoints(points * 5 / 6)
		else if (H.reagents.has_reagent("morphine"))
			abil_holder.addPoints(points / 2)
		else if (H.reagents.has_reagent("haloperidol"))
			abil_holder.addPoints(points / 3)
		else
			abil_holder.addPoints(points)

	/// disguise as an entity
	proc/disguise()
		var/mob/living/temp
		switch (src.set_disguise)
			if (MINDEATER_DISGUISE_MOUSE)
				temp = new /mob/living/critter/small_animal/mouse
				src.icon = temp.icon
				src.icon_state = temp.icon_state
				src.flags |= (TABLEPASS | DOORPASS)
				src.name = temp.real_name
				src.desc = temp.get_desc(0, src)
				src.bioHolder.mobAppearance.gender = temp.bioHolder.mobAppearance.gender
			if (MINDEATER_DISGUISE_COCKROACH)
				temp = new /mob/living/critter/small_animal/cockroach
				src.icon = temp.icon
				src.icon_state = temp.icon_state
				src.flags |= (TABLEPASS | DOORPASS)
				src.name = temp.real_name
				src.desc = temp.get_desc(0, src)
				src.bioHolder.mobAppearance.gender = temp.bioHolder.mobAppearance.gender
			if (MINDEATER_DISGUISE_HUMAN)
				randomize_look(src.human_disguise_dummy, change_name = FALSE)

				var/icon/front = getFlatIcon(src.human_disguise_dummy, SOUTH)
				var/icon/back = getFlatIcon(src.human_disguise_dummy, NORTH)
				var/icon/left = getFlatIcon(src.human_disguise_dummy, WEST)
				var/icon/right = getFlatIcon(src.human_disguise_dummy, EAST)
				var/icon/guise = new
				guise.Insert(front, dir = SOUTH)
				guise.Insert(back, dir = NORTH)
				guise.Insert(left, dir = WEST)
				guise.Insert(right, dir = EAST)

				src.icon = guise

				src.name = src.human_disguise_dummy.real_name
				src.desc = src.human_disguise_dummy.get_desc(TRUE, TRUE)
				src.bioHolder.mobAppearance.gender = src.human_disguise_dummy.bioHolder.mobAppearance.gender

		src.update_name_tag(src.name)
		qdel(temp)

		src.disguised = TRUE
		REMOVE_ATOM_PROPERTY(src, PROP_ATOM_FLOATING, src)
		REMOVE_ATOM_PROPERTY(src, PROP_MOB_NO_MOVEMENT_PUFFS, src)

	/// undisguise as disguised entity
	proc/undisguise()
		src.name = initial(src.name)
		src.desc = initial(src.desc)
		src.icon = initial(src.icon)
		src.icon_state = initial(src.icon_state)
		src.bioHolder.mobAppearance.gender = initial(src.gender)
		src.update_name_tag(src.name)

		src.flags &= ~(TABLEPASS | DOORPASS)

		src.disguised = FALSE
		APPLY_ATOM_PROPERTY(src, PROP_ATOM_FLOATING, src)
		APPLY_ATOM_PROPERTY(src, PROP_MOB_NO_MOVEMENT_PUFFS, src)

		var/datum/targetable/critter/mindeater/disguise/abil = src.abilityHolder.getAbility(/datum/targetable/critter/mindeater/disguise)
		abil.reset()

	/// turns psi bolt firing on/off when disguised
	proc/toggle_psi_bolt()
		src.can_fire_when_disguised = !src.can_fire_when_disguised

		if (src.can_fire_when_disguised)
			boutput(src, SPAN_NOTICE("You can now fire psi bolts when disguised."))
		else
			boutput(src, SPAN_NOTICE("You will no longer fire psi bolts when disguised."))

/obj/dummy/fake_mindeater
	name = "???"
	real_name = "mindeater"
	desc = "What sort of eldritch abomination is this thing???"
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "intruder"
	flags = LONG_GLIDE
	density = FALSE
	anchored = UNANCHORED

	attack_hand(mob/user)
		..()
		src.reveal_fake()

	attackby(obj/item/I, mob/user)
		..()
		src.reveal_fake()

	proc/reveal_fake()
		animate_wave(src, 5)
		animate(src, 1 SECOND, flags = ANIMATION_PARALLEL, alpha = 0)
		SPAWN(1 SECOND)
			qdel(src)

	bump(atom/A)
		..()
		if (A.density && A.material?.getProperty("reflective") > 7)
			src.set_loc(get_turf(A))
		else if (istype(A, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/airlock = A
			airlock.open()

	Crossed(atom/movable/AM)
		. = ..()
		var/obj/projectile/P = AM
		if (istype(P) && !istype(P.proj_data, /datum/projectile/special/psi_bolt))
			src.reveal_fake()

/obj/dummy/mindeater_structure
	name = "spire"
	real_name = "mindeater"
	desc = "Some sort of ancient structure. You feel your mind slipping away just looking at it."
	icon = null
	icon_state = null
	density = FALSE
	anchored = ANCHORED_ALWAYS
	var/image/mob_appearance

	New(turf/newLoc)
		..()
		SPAWN(rand(30, 60) SECONDS)
			src.reveal_fake()

		src.mob_appearance = image('icons/mob/critter/nonhuman/intruder.dmi', src, "spire")
		src.mob_appearance.alpha = 0
		animate(src.mob_appearance, alpha = 255, time = 1 SECOND)
		get_image_group(CLIENT_IMAGE_GROUP_MINDEATER_STRUCTURE_VISION).add_image(src.mob_appearance)

	disposing()
		..()
		get_image_group(CLIENT_IMAGE_GROUP_MINDEATER_STRUCTURE_VISION).remove_image(src.mob_appearance)
		QDEL_NULL(src.mob_appearance)

	attack_hand(mob/user)
		..()
		src.reveal_fake()

	attackby(obj/item/I, mob/user)
		..()
		src.reveal_fake()

	proc/reveal_fake()
		animate_wave(src, 5)
		animate(src, 1 SECOND, flags = ANIMATION_PARALLEL, alpha = 0)
		SPAWN(1 SECOND)
			qdel(src)

	Crossed(atom/movable/AM)
		. = ..()
		var/obj/projectile/P = AM
		if (istype(P) && !istype(P.proj_data, /datum/projectile/special/psi_bolt))
			src.reveal_fake()

/image/mindeater_visibility_indicator
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "invisible"
	plane = PLANE_HUD
	layer = HUD_LAYER_BASE
	appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR
	pixel_x = 16
	pixel_y = -16

	New(icon, loc, icon_state, layer, dir)
		..()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).add_image(src)

	disposing()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).remove_image(src)
		..()

	proc/set_visible(vis)
		src.icon_state = vis ? "visible" : "invisible"

/image/mindeater_health_indicator
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "health-100"
	plane = PLANE_HUD
	layer = HUD_LAYER_BASE
	appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR
	pixel_x = 30
	pixel_y = -16

	New(icon, loc, icon_state, layer, dir)
		..()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).add_image(src)

	disposing()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).remove_image(src)
		..()

	proc/set_icon_state(pct)
		src.icon_state = "health-[pct]"

/image/mindeater_brain_drain_targeted
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "brain_drain_targeted"
	plane = PLANE_HUD
	layer = HUD_LAYER_BASE
	appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR
	pixel_x = 18
	pixel_y = 0

	New(icon, loc, icon_state, layer, dir)
		..()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).add_image(src)

	disposing()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).remove_image(src)
		..()

/image/intrusion_brain_level
	icon = 'icons/mob/critter/nonhuman/intruder.dmi'
	icon_state = "brain-0"
	plane = PLANE_HUD
	layer = HUD_LAYER_BASE
	appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR
	pixel_x = 18
	pixel_y = 10

	New(icon, loc, icon_state, layer, dir)
		..()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).add_image(src)

	disposing()
		get_image_group(CLIENT_IMAGE_GROUP_INTRUSION_OVERLAYS).remove_image(src)
		..()

	proc/set_icon_state(pct)
		src.icon_state = "brain-[pct]"

/*
/obj/machinery/artifact/reality_breaker
	name = "artifact reality breaker"
	associated_datum = /datum/artifact/reality_breaker

/datum/artifact/reality_breaker
	associated_object = /obj/machinery/artifact/reality_breaker
	type_name = "Reality breaker"
	type_size = ARTIFACT_SIZE_LARGE
	rarity_weight = 300
	min_triggers = 1
	max_triggers = 1
	validtypes = list("wizard", "precursor")
	fault_blacklist = list(ITEM_ONLY_FAULTS)
	react_xray = list(15, 90, 90, 11, "VARYING")
	var/radius
	var/kind
	var/broken_atoms = list()

	New()
		..()
		radius = rand(1, 4)
		kind = rand(1, 2)

	effect_process(obj/machinery/artifact/reality_breaker/O)
		..()
		if (ON_COOLDOWN(O, "reality_break", 5 SECONDS))
			return
		var/list/nearby_atoms = range(O, radius)
		for (var/atom/A as anything in broken_atoms)
			if (!HAS_ATOM_PROPERTY(A, PROP_ATOM_REALITY_BROKEN))
				continue
			if (!(A in nearby_atoms))
				animate(A, flags = ANIMATION_END_NOW)
				A.pixel_x = 0
				A.pixel_y = 0
				A.transform = initial(A.transform)
				REMOVE_ATOM_PROPERTY(A, PROP_ATOM_REALITY_BROKEN, src)
		src.broken_atoms = list()
		for (var/atom/A in range(O, radius))
			if (ismob(A))
				continue
			if (!isturf(A) && !isitem(A))
				continue
			if (HAS_ATOM_PROPERTY(A, PROP_ATOM_REALITY_BROKEN))
				continue
			src.broken_atoms += A
			APPLY_ATOM_PROPERTY(A, PROP_ATOM_REALITY_BROKEN, O)
			if (prob(75) && isturf(A))
				animate(A, rand(5, 10) / 10 SECONDS, easing = SINE_EASING, pixel_x = rand(-5, 5), pixel_y = rand(-5, 5))
				continue
			switch (kind)
				if (1)
					animate_float(A, floatspeed = (2 + rand(-5, 5) / 10) SECONDS, vertical = pick(TRUE, FALSE), halfway = pick(TRUE, FALSE))
				if (2)
					animate_orbit(A, rand(1, 5), rand(1, 5), rand(1, 3), time = rand(10, 80) / 10 SECONDS, clockwise = pick(TRUE, FALSE))
*/
