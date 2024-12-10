ABSTRACT_TYPE(/datum/targetable/critter/ice_phoenix)
/datum/targetable/critter/ice_phoenix

/datum/targetable/critter/ice_phoenix/sail
	name = "Sail"
	desc = "Channel to gain a large movement speed buff while in space for 10 seconds"
	cooldown = 10 SECONDS // 120 seconds
	cooldown_after_action = TRUE

	tryCast()
		if (!istype(get_turf(src.holder.owner), /turf/space))
			boutput(src.holder.owner, SPAN_ALERT("You need to be in space to use this ability!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		return ..()

	cast(atom/target)
		. = ..()
		var/mob/living/L = src.holder.owner
		if (L.throwing)
			return
		EndSpacePush(L)
		// 10 seconds below
		SETUP_GENERIC_ACTIONBAR(src.holder.owner, null, 3 SECONDS, /mob/living/critter/ice_phoenix/proc/on_sail, null, \
			'icons/mob/critter/nonhuman/icephoenix.dmi', "icephoenix", null, INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_ATTACKED | INTERRUPT_STUNNED | INTERRUPT_ACTION)

/datum/targetable/critter/ice_phoenix/ice_barrier
	name = "Ice Barrier"
	desc = "Gives yourself a hardened ice barrier, reducing the damage of the next attack against you by 50%."
	cooldown = 2 SECONDS // 20 SECONDS

	cast(atom/target)
		. = ..()
		src.holder.owner.setStatus("phoenix_ice_barrier", 7 SECONDS)

/datum/targetable/critter/ice_phoenix/glacier
	name = "Glacier"
	desc = "Create a 5 tile wide compacted snow wall, perpendicular to the cast direction, or otherwise in a random direction. Can be destroyed by heat or force."
	cooldown = 2 SECONDS // 20 SECONDS
	targeted = TRUE
	target_anything = TRUE

	cast(atom/target)
		. = ..()
		var/wall_style

		var/turf/T = get_turf(target)
		if (T == get_turf(src.holder.owner))
			wall_style = pick("vertical", "horizontal")
		else
			var/angle = get_angle(src.holder.owner, T)
			if ((angle > 45 && angle < 135) || (angle > -135 && angle < -45))
				wall_style = "vertical"
			else if ((angle > -45 && angle < 45) || (angle < -135 && angle > 135))
				wall_style = "horizontal"
			else
				wall_style = pick("vertical", "horizontal")

		src.create_ice_wall(T, wall_style)

	proc/create_ice_wall(turf/center, spread_type)
		var/turf/T
		if (spread_type == "vertical")
			if (!center.density)
				new /obj/ice_phoenix_ice_wall/vertical_mid(center)
			T = get_step(center, NORTH)
			if (!T.density)
				new /obj/ice_phoenix_ice_wall/vertical_mid(T)
			T = get_step(T, NORTH)
			if (!T.density)
				new /obj/ice_phoenix_ice_wall/north(T)

			T = get_step(center, SOUTH)
			if (!T.density)
				new /obj/ice_phoenix_ice_wall/vertical_mid(T)
			T = get_step(T, SOUTH)
			if (!T.density)
				new /obj/ice_phoenix_ice_wall/south(T)
			return
		if (!center.density)
			new /obj/ice_phoenix_ice_wall/horizontal_mid(center)
		T = get_step(center, EAST)
		if (!T.density)
			new /obj/ice_phoenix_ice_wall/horizontal_mid(T)
		T = get_step(T, EAST)
		if (!T.density)
			new /obj/ice_phoenix_ice_wall/east(T)

		T = get_step(center, WEST)
		if (!T.density)
			new /obj/ice_phoenix_ice_wall/horizontal_mid(T)
		T = get_step(T, WEST)
		if (!T.density)
			new /obj/ice_phoenix_ice_wall/west(T)

/datum/targetable/critter/ice_phoenix/thermal_shock
	name = "Thermal Shock"
	desc = "Channel to create an atmospheric-blocking tunnel that allows travel through by anyone. Can only be cast on walls."
	cooldown = 2 SECONDS // 20 SECONDS
	targeted = TRUE
	target_anything = TRUE
	cooldown_after_action = TRUE

	tryCast(atom/target, params)
		if (BOUNDS_DIST(src.holder.owner, target) > 0)
			boutput(src.holder.owner, SPAN_ALERT("You need to be adjacent to the target!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		if (!iswall(target))
			boutput(src.holder.owner, SPAN_ALERT("You can only cast this ability on walls!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		return ..()

	cast(atom/target)
		..()
		SETUP_GENERIC_ACTIONBAR(src.holder.owner, null, 5 SECONDS, /mob/living/critter/ice_phoenix/proc/create_ice_tunnel, list(target), \
			'icons/mob/critter/nonhuman/icephoenix.dmi', "icephoenix", null, INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_ATTACKED | INTERRUPT_STUNNED | INTERRUPT_ACTION)

/datum/targetable/critter/ice_phoenix/wind_chill
	name = "Wind chill"
	desc = "Create a freezing aura at the targeted location, inflicting cold on those within 5 tiles nearby, and freezing them solid if their body temperature is low enough."
	cooldown = 2 SECONDS // 30 SECONDS
	targeted = TRUE
	target_anything = TRUE

	cast(atom/target)
		..()
		var/turf/center = get_turf(target)
		var/obj/particle/cryo_sparkle/sparkle
		for (var/turf/T as anything in block(center.x - 2, center.y - 2, center.z, center.x + 2, center.y + 2, center.z))
			sparkle = new /obj/particle/cryo_sparkle(T)
			sparkle.alpha = rand(180, 255)
			for (var/mob/living/L in T)
				L.changeStatus("shivering", 10 SECONDS)
				L.bodytemperature -= 10
				if (L.bodytemperature <= 255.372) // 0 degrees fahrenheit
					new /obj/icecube(L.loc, L)
			SPAWN(2 SECONDS)
				qdel(sparkle)

/datum/targetable/critter/ice_phoenix/touch_of_death
	name = "Touch of Death"
	desc = "Delivers constant chills to an adjacent target. If their body temperature is low enough, it will deal rapid burn damage. If recently frozen by an ice cube, they will be unable to move."
	cooldown = 2 SECONDS // 60 SECONDS
	targeted = TRUE
	target_anything = TRUE

	tryCast(atom/target, params)
		if (BOUNDS_DIST(src.holder.owner, target) > 0)
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		if (!ishuman(target))
			boutput(src.holder.owner, SPAN_ALERT("You can only cast this ability on humans!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		return ..()

	cast(atom/target)
		..()
		actions.start(new /datum/action/bar/touch_of_death(target), src.holder.owner)

/datum/targetable/critter/ice_phoenix/permafrost
	name = "Permafrost"
	desc = "Target a station turf to channel a powerful ice beam that makes the station area habitable to you at the end."
	cooldown = 2 SECONDS // 60 SECONDS
	targeted = TRUE
	target_anything = TRUE

	tryCast(atom/target, params)
		if (!istype(get_area(target), /area/station))
			boutput(src.holder.owner, SPAN_ALERT("You can only cast this ability on a station turf!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		var/turf/T = get_turf(target)
		var/turf/phoenix_turf = get_turf(src.holder.owner)
		if (T == phoenix_turf)
			boutput(src.holder.owner, SPAN_ALERT("You can't cast this ability on the same turf you're on!"))
			return CAST_ATTEMPT_FAIL_NO_COOLDOWN
		return ..()

	cast(atom/target)
		..()
		actions.start(new /datum/action/bar/permafrost(target), src.holder.owner)

/datum/action/bar/touch_of_death
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION | INTERRUPT_ATTACKED
	duration = 1 SECOND
	//resumable = FALSE
	color_success = "#4444FF"

	var/mob/target

	New(atom/target)
		..()
		src.target = target

	onUpdate()
		..()
		if (src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)

	onStart()
		..()
		if(src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)
			return
		src.owner.visible_message(SPAN_ALERT("[src.owner] grips [src.target] with its talons!"), SPAN_ALERT("You begin channeling your cold into [src.target]."))
		if (TIME - src.target.last_cubed < 10 SECONDS)
			APPLY_ATOM_PROPERTY(src.target, PROP_MOB_CANTMOVE, "phoenix_touch_of_death")
			src.target.last_cubed = TIME

	onEnd()
		..()
		if(src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)
			return

		src.target.changeStatus("shivering", 2 SECONDS)
		src.target.bodytemperature -= 15
		if (src.target.bodytemperature <= 255.372) // 0 degrees fahrenheit
			src.target.TakeDamage("All", burn = 10)

		src.onRestart()

	onInterrupt()
		..()
		REMOVE_ATOM_PROPERTY(src.target, PROP_MOB_CANTMOVE, "phoenix_touch_of_death")

	// need to do temperature check
	proc/check_for_interrupt()
		var/mob/living/critter/ice_phoenix/phoenix = src.owner
		return QDELETED(phoenix) || QDELETED(src.target) || isdead(phoenix) || isdead(src.target) || BOUNDS_DIST(src.target, phoenix) > 0

/datum/action/bar/permafrost
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION | INTERRUPT_ATTACKED
	duration = 10 SECONDS //30 SECONDS
	//resumable = FALSE
	color_success = "#4444FF"

	var/turf/target
	var/obj/beam_dummy/dummy
	var/list/turfs_in_area = list()

	New(atom/target)
		..()
		src.target = get_turf(target)

	onStart()
		..()
		if(src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)
			return
		EndSpacePush(src.owner)
		src.owner.set_dir(get_dir(src.owner, target))
		src.owner.visible_message(SPAN_ALERT("[src.owner] begins channeling a beam of ice!"), SPAN_ALERT("You begin channeling your ice power."))
		//var/list/turfs/affected = DrawLine(get_step(src.owner, src.owner.dir), src.target, /obj/ice_phoenix_ice_wall/east)
		src.dummy = showLine(src.owner, target, "zigzag")
		src.dummy.color = "#2e2af1"

		for (var/turf/T in get_area(target))
			src.turfs_in_area += T

	onUpdate()
		..()
		if (src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)
			return
		var/area/A = get_area(src.target)
		var/mob/living/M
		for (var/datum/mind/mind as anything in A.population)
			M = mind.current
			M.changeStatus("shivering", 1 SECOND)
			if (!ON_COOLDOWN(M, "ice_phoenix_permafrost_chill", 1 SECOND))
				M.TakeDamage("All", burn = 1)
			// body temp decrease

	onEnd()
		..()
		if(src.check_for_interrupt())
			interrupt(INTERRUPT_ALWAYS)
			return

		for (var/turf/simulated/floor/T in src.turfs_in_area)
			if (T.intact && !istype(T, /turf/simulated/floor/glassblock))
				T.ReplaceWith(/turf/simulated/floor/snow/snowball)
				T.icon = 'icons/turf/snow.dmi'
				T.icon_state = "snow[pick(1, 2, 3)]"
				T.set_dir(pick(cardinal))
			else
				T.icon = 'icons/turf/floors.dmi'
				T.icon_state = "snow[pick(null, 1, 2, 3, 4)]"
				T.set_dir(pick(cardinal))

			new /obj/effects/precipitation/snow/grey/tile/light(T)

		QDEL_NULL(src.dummy)

	proc/check_for_interrupt()
		var/mob/living/critter/ice_phoenix/phoenix = src.owner
		return QDELETED(phoenix) || isdead(phoenix)

ABSTRACT_TYPE(/obj/ice_phoenix_ice_wall)
/obj/ice_phoenix_ice_wall
	name = "compacted snow wall"
	desc = "A wall of compacted snow and ice. An obstacle that can be destroyed, best by heat."
	icon = 'icons/turf/walls/moon.dmi'
	density = TRUE
	anchored = ANCHORED_ALWAYS
	layer = TURF_LAYER
	default_material = "ice"
	mat_changename = FALSE
	var/hits_left = 3

	New()
		..()
		//src.reagents = new /datum/reagent(25)
		//src.reagents.my_atom = src
		//src.reagents.add_reagent("water", 25)

		SPAWN(1 MINUTE)
			qdel(src)

	horizontal_mid
		icon_state = "moon-12"

	east
		icon_state = "moon-8"

	west
		icon_state = "moon-4"

	vertical_mid
		icon_state = "moon-3"

	north
		icon_state = "moon-2"

	south
		icon_state = "moon-1"

	attack_hand(mob/user)
		attack_particle(user, src)
		user.lastattacked = src

		if (istype(user, /mob/living/critter/ice_phoenix))
			qdel(src)
			return

		boutput(user, SPAN_ALERT("Unfortunately, the snow is a little too compacted to be destroyed by hand."))

	attackby(obj/item/I, mob/user)
		attack_particle(user, src)
		user.lastattacked = src

		if (isweldingtool(I) && I:welding)
			user.visible_message(SPAN_ALERT("[user] melts [src]!"), SPAN_ALERT("You melt [src]!"))
			qdel(src)
		else if (I.force)
			if (I.force >= 20)
				user.visible_message(SPAN_ALERT("[user] destroys [src]!"), SPAN_ALERT("You destroy [src]!"))
				qdel(src)
				return
			src.hits_left--
			if (src.hits_left > 0)
				user.visible_message(SPAN_ALERT("[user] damages [src]!"), SPAN_ALERT("You damage [src]!"))
			else
				user.visible_message(SPAN_ALERT("[user] destroys [src]!"), SPAN_ALERT("You destroy [src]!"))
				qdel(src)
		else
			..()
			boutput(user, SPAN_ALERT("Unfortunately, [I] is too weak to damage [src]."))

	bullet_act(obj/projectile/P)
		if (P.power >= 20)
			src.visible_message(SPAN_ALERT("[src] is destroyed by [P]!"))
			qdel(src)
		else if (P.power)
			src.hits_left--
			if (src.hits_left > 0)
				src.visible_message(SPAN_ALERT("[src] is destroyed by [P]!"))
				qdel(src)
			else
				..()

	hitby(atom/movable/AM, datum/thrown_thing/thr)
		..()
		if (AM.throwforce >= 20)
			src.visible_message(SPAN_ALERT("[src] is destroyed by [AM]!"))
			qdel(src)
		else
			src.hits_left--
			if (src.hits_left <= 0)
				src.visible_message(SPAN_ALERT("[src] is destroyed by [AM]!"))
				qdel(src)

	Bumped(atom/A)
		if (istype(A, /obj/machinery/vehicle))
			qdel(src)
			return
		return ..()

	ex_act()
		qdel(src)

	blob_act()
		qdel(src)

	// need snow particle effects for destroying the wall
	disposing()
		// create water here
		//src.reagents.trans_to(get_turf(src), 25)
		..()
