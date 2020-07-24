/obj/item/stack/medical
	name = "medical pack"
	singular_name = "medical pack"
	icon = 'icons/obj/stack_medical.dmi'
	amount = 6
	max_amount = 6
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	resistance_flags = FLAMMABLE
	max_integrity = 40
	novariants = FALSE
	item_flags = NOBLUDGEON
	var/self_delay = 5 SECONDS
	var/other_delay = 0
	///does stack automatically attempt to repeat treatment if patient is still hurt
	var/repeating = FALSE
	///skip dead check in try_heal
	var/corpse_healing = FALSE

/obj/item/stack/medical/attack(mob/living/M, mob/user)
	. = ..()
	try_heal(M, user)


/obj/item/stack/medical/proc/try_heal(mob/living/patient, mob/user, silent = FALSE)
	if(!patient.can_inject(user, TRUE))
		return
	if(!corpse_healing && patient.stat == DEAD)
		to_chat(user, "<span class='warning'>[patient] is dead! You can not help [patient.p_them()].</span>")
		return
	if(patient == user)
		if(!silent)
			user.visible_message("<span class='notice'>[user] starts to apply \the [src] on [user.p_them()]self...</span>", "<span class='notice'>You begin applying \the [src] on yourself...</span>")
		if(!do_mob(user, patient, self_delay, extra_checks=CALLBACK(patient, /mob/living/proc/can_inject, user, TRUE)))
			return
	else if(other_delay)
		if(!silent)
			user.visible_message("<span class='notice'>[user] starts to apply \the [src] on [patient].</span>", "<span class='notice'>You begin applying \the [src] on [patient]...</span>")
		if(!do_mob(user, patient, other_delay, extra_checks=CALLBACK(patient, /mob/living/proc/can_inject, user, TRUE)))
			return

	if(heal(patient, user))
		log_combat(user, patient, "healed", src.name)
		use(1)
		if(repeating && amount > 0)
			try_heal(patient, user, TRUE)


/// The healing effects on a carbon patient. Since we have extra details for dealing with bodyparts, we get our own fancy proc. Still returns TRUE on success and FALSE on fail
/obj/item/stack/medical/proc/heal_carbon(mob/living/carbon/C, mob/user, brute, burn)
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))
	if(!affecting) //Missing limb?
		to_chat(user, "<span class='warning'>[C] doesn't have \a [parse_zone(user.zone_selected)]!</span>")
		return
	if(affecting.status != BODYPART_ORGANIC) //Limb must be organic to be healed - RR
		to_chat(user, "<span class='warning'>[src] won't work on a robotic limb!</span>")
		return FALSE
	if(affecting.brute_dam && brute || affecting.burn_dam && burn)
		user.visible_message("<span class='green'>[user] applies [src] on [C]'s [affecting.name].</span>", "<span class='green'>You apply [src] on [C]'s [affecting.name].</span>")
		var/previous_damage = affecting.get_damage()
		if(affecting.heal_damage(brute, burn))
			C.update_damage_overlays()
		post_heal_effects(max(previous_damage - affecting.get_damage(), 0), C, user)
		return TRUE
	to_chat(user, "<span class='warning'>[C]'s [affecting.name] can not be healed with \the [src]!</span>")

///Override this proc for special post heal effects.
/obj/item/stack/medical/proc/post_heal_effects(amount_healed, mob/living/carbon/healed_mob, mob/user)
	return

/obj/item/stack/medical/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "A therapeutic gel pack and bandages designed to treat blunt-force trauma."
	icon_state = "brutepack"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	heal_brute = 4 SECONDS
	self_delay = 2 SECONDS
	grind_results = list(/datum/reagent/medicine/c2/libital = 10)

/obj/item/stack/medical/bruise_pack/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is bludgeoning [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (BRUTELOSS)

/obj/item/stack/medical/gauze
	name = "medical gauze"
	desc = "A roll of elastic cloth, perfect for stabilizing all kinds of wounds, from cuts and burns, to broken bones. "
	gender = PLURAL
	singular_name = "medical gauze"
	icon_state = "gauze"
	other_delay = 20
	self_delay = 2 SECONDS
	max_amount = 12
	grind_results = list(/datum/reagent/cellulose = 2)


// gauze is only relevant for wounds, which are handled in the wounds themselves
/obj/item/stack/medical/gauze/try_heal(mob/living/M, mob/user, silent)
	var/obj/item/bodypart/limb = M.get_bodypart(check_zone(user.zone_selected))
	if(!limb)
		to_chat(user, "<span class='notice'>There's nothing there to bandage!</span>")
		return
	if(!LAZYLEN(limb.wounds))
		to_chat(user, "<span class='notice'>There's no wounds that require bandaging on [user==M ? "your" : "[M]'s"] [limb.name]!</span>") // good problem to have imo
		return


	var/gauzeable_wound = FALSE
	for(var/i in limb.wounds)
		var/datum/wound/woundies = i
		if(woundies.wound_flags & ACCEPTS_GAUZE)
			gauzeable_wound = TRUE
			break
	if(!gauzeable_wound)
		to_chat(user, "<span class='notice'>There's no wounds that require bandaging on [user==M ? "your" : "[M]'s"] [limb.name]!</span>") // good problem to have imo
		return

	if(limb.current_gauze && (limb.current_gauze.absorption_capacity * 0.8 > absorption_capacity)) // ignore if our new wrap is < 20% better than the current one, so someone doesn't bandage it 5 times in a row
		to_chat(user, "<span class='warning'>The bandage currently on [user==M ? "your" : "[M]'s"] [limb.name] is still in good condition!</span>")
		return

	user.visible_message("<span class='warning'>[user] begins wrapping the wounds on [M]'s [limb.name] with [src]...</span>", "<span class='warning'>You begin wrapping the wounds on [user == M ? "your" : "[M]'s"] [limb.name] with [src]...</span>")

	if(!do_after(user, (user == M ? self_delay : other_delay), target=M))
		return

	user.visible_message("<span class='green'>[user] applies [src] to [M]'s [limb.name].</span>", "<span class='green'>You bandage the wounds on [user == M ? "yourself" : "[M]'s"] [limb.name].</span>")
	limb.apply_gauze(src)

/obj/item/stack/medical/gauze/twelve
	amount = 12

/obj/item/stack/medical/gauze/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER || I.is_sharp())
		if(get_amount() < 2)
			to_chat(user, "<span class='warning'>You need at least two gauzes to do this!</span>")
			return
		new /obj/item/stack/sheet/cloth(user.drop_location())
		user.visible_message("<span class='notice'>[user] cuts [src] into pieces of cloth with [I].</span>", \
					 "<span class='notice'>You cut [src] into pieces of cloth with [I].</span>", \
					 "<span class='hear'>You hear cutting.</span>")
		use(2)
	else
		return ..()

/obj/item/stack/medical/gauze/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] begins tightening \the [src] around [user.p_their()] neck! It looks like [user.p_they()] forgot how to use medical supplies!</span>")
	return OXYLOSS

/obj/item/stack/medical/gauze/improvised
	name = "improvised gauze"
	singular_name = "improvised gauze"

/obj/item/stack/medical/gauze/cyborg
	custom_materials = null
	is_cyborg = 1
	cost = 250

/obj/item/stack/medical/suture
	name = "suture"
	desc = "Basic sterile sutures used to seal up cuts and lacerations and stop bleeding."
	gender = PLURAL
	singular_name = "suture"
	icon_state = "suture"
	self_delay = 3 SECONDS
	other_delay = 1 SECONDS
	amount = 15
	max_amount = 15
	repeating = TRUE
	heal_brute = 10
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/suture/medicated
	name = "medicated suture"
	icon_state = "suture_purp"
	desc = "A suture infused with drugs that speed up wound healing of the treated laceration."
	heal_brute = 15
	stop_bleeding = 0.75
	grind_results = list(/datum/reagent/medicine/polypyr = 1)

/obj/item/stack/medical/mesh
	name = "regenerative mesh"
	desc = "A bacteriostatic mesh used to dress burns."
	gender = PLURAL
	singular_name = "regenerative mesh"
	icon_state = "regen_mesh"
	self_delay = 3 SECONDS
	other_delay = 1 SECONDS
	amount = 15
	max_amount = 15
	repeating = TRUE

	var/is_open = TRUE ///This var determines if the sterile packaging of the mesh has been opened.
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/mesh/Initialize()
	. = ..()
	if(amount == max_amount)	 //only seal full mesh packs
		is_open = FALSE
		update_icon()


/obj/item/stack/medical/mesh/update_icon()
	if(is_open)
		return ..()
	icon_state = "regen_mesh_closed"

/obj/item/stack/medical/mesh/try_heal(mob/living/M, mob/user, silent = FALSE)
	if(!is_open)
		to_chat(user, "<span class='warning'>You need to open [src] first.</span>")
		return
	return ..()

/obj/item/stack/medical/mesh/AltClick(mob/living/user)
	if(!is_open)
		to_chat(user, "<span class='warning'>You need to open [src] first.</span>")
		return
	return ..()

/obj/item/stack/medical/mesh/attack_hand(mob/user)
	if(!is_open & user.get_inactive_held_item() == src)
		to_chat(user, "<span class='warning'>You need to open [src] first.</span>")
		return
	return ..()

/obj/item/stack/medical/mesh/attack_self(mob/user)
	if(!is_open)
		is_open = TRUE
		to_chat(user, "<span class='notice'>You open the sterile mesh package.</span>")
		update_icon()
		playsound(src, 'sound/items/poster_ripped.ogg', 20, TRUE)
		return
	. = ..()

/obj/item/stack/medical/mesh/advanced
	name = "advanced regenerative mesh"
	desc = "An advanced mesh made with aloe extracts and sterilizing chemicals, used to treat burns."

	gender = PLURAL
	icon_state = "aloe_mesh"
	heal_burn = 15
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	merge_type = /obj/item/stack/medical/mesh/advanced

/obj/item/stack/medical/mesh/advanced/update_icon()
	if(is_open)
		return ..()
	icon_state = "aloe_mesh_closed"

/obj/item/stack/medical/aloe
	name = "aloe cream"
	desc = "A healing paste you can apply on wounds."

	gender = PLURAL
	singular_name = "aloe cream"
	icon_state = "aloe_paste"
	self_delay = 2 SECONDS
	other_delay = 1 SECONDS
	novariants = TRUE
	amount = 20
	max_amount = 20
	repeating = TRUE
	heal_brute = 3
	heal_burn = 3
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	merge_type = /obj/item/stack/medical/aloe

	if(iscarbon(M))

	to_chat(user, "<span class='warning'>You can't heal [M] with the \the [src]!</span>")

	/*
	The idea is for these medical devices to work like a hybrid of the old brute packs and tend wounds,
	they heal a little at a time, have reduced healing density and does not allow for rapid healing while in combat.
	However they provice graunular control of where the healing is directed, this makes them better for curing work-related cuts and scrapes.

	The interesting limb targeting mechanic is retained and i still believe they will be a viable choice, especially when healing others in the field.
	 */

/obj/item/stack/medical/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "A potent medical gel that, when applied to a damaged bone in a proper surgical setting, triggers an intense melding reaction to repair the wound. Can be directly applied alongside surgical sticky tape to a broken bone in dire circumstances, though this is very harmful to the patient and not recommended."

	icon = 'icons/obj/surgery.dmi'
	icon_state = "bone-gel"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

	amount = 4
	self_delay = 2 SECONDS
	grind_results = list(/datum/reagent/medicine/c2/libital = 10)
	novariants = TRUE

/obj/item/stack/medical/bone_gel/attack(mob/living/M, mob/user)
	to_chat(user, "<span class='warning'>Bone gel can only be used on fractured limbs!</span>")
	return

/obj/item/stack/medical/bone_gel/suicide_act(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.visible_message("<span class='suicide'>[C] is squirting all of \the [src] into [C.p_their()] mouth! That's not proper procedure! It looks like [C.p_theyre()] trying to commit suicide!</span>")
		if(do_after(C, 2 SECONDS))
			C.emote("scream")
			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				var/datum/wound/blunt/severe/oof_ouch = new
				oof_ouch.apply_wound(bone)
				var/datum/wound/blunt/critical/oof_OUCH = new
				oof_OUCH.apply_wound(bone)

			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				bone.receive_damage(brute=60)
			use(1)
			return (BRUTELOSS)
		else
			C.visible_message("<span class='suicide'>[C] screws up like an idiot and still dies anyway!</span>")
			return (BRUTELOSS)

/obj/item/stack/medical/bone_gel/cyborg
	custom_materials = null
	is_cyborg = 1
	cost = 250

/obj/item/stack/medical/bone_gel/four
	amount = 4

/obj/item/stack/medical/poultice
	name = "mourning poultices"
	singular_name = "mourning poultice"
	desc = "A type of primitive herbal poultice.\nWhile traditionally used to prepare corpses for the mourning feast, it can also treat scrapes and burns on the living, however, it is liable to cause shortness of breath when employed in this manner.\nIt is imbued with ancient wisdom."
	icon_state = "poultice"
	amount = 15
	max_amount = 15
	heal_brute = 10
	heal_burn = 10
	self_delay = 4 SECONDS
	other_delay = 1 SECONDS
	repeating = TRUE
	drop_sound = 'sound/misc/moist_impact.ogg'
	mob_throw_hit_sound = 'sound/misc/moist_impact.ogg'
	hitsound = 'sound/misc/moist_impact.ogg'
	merge_type = /obj/item/stack/medical/poultice

/obj/item/stack/medical/poultice/heal(mob/living/M, mob/user)
	if(iscarbon(M))
		playsound(src, 'sound/misc/soggy.ogg', 30, TRUE)
		return heal_carbon(M, user, heal_brute, heal_burn)
	return ..()

/obj/item/stack/medical/poultice/post_heal_effects(amount_healed, mob/living/carbon/healed_mob, mob/user)
	. = ..()
	healed_mob.adjustOxyLoss(amount_healed)
