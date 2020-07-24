
/*

CONTAINS:
T-RAY
HEALTH ANALYZER
GAS ANALYZER
SLIME SCANNER
NANITE SCANNER
GENE SCANNER

*/
/obj/item/t_scanner
	name = "\improper T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	custom_price = 10
	icon = 'icons/obj/device.dmi'
	icon_state = "t-ray0"
	var/on = FALSE
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	materials = list(/datum/material/iron=150)

/obj/item/t_scanner/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to emit terahertz-rays into [user.p_their()] brain with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return TOXLOSS

/obj/item/t_scanner/proc/toggle_on()
	on = !on
	icon_state = copytext_char(icon_state, 1, -1) + "[on]"
	if(on)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)

/obj/item/t_scanner/attack_self(mob/user)
	toggle_on()

/obj/item/t_scanner/cyborg_unequip(mob/user)
	if(!on)
		return
	toggle_on()

/obj/item/t_scanner/process()
	if(!on)
		STOP_PROCESSING(SSobj, src)
		return null
	scan()

/obj/item/t_scanner/proc/scan()
	t_ray_scan(loc)

/proc/t_ray_scan(mob/viewer, flick_time = 8, distance = 3)
	if(!ismob(viewer) || !viewer.client)
		return
	var/list/t_ray_images = list()
	for(var/obj/O in orange(distance, viewer) )
		if(O.level != 1)
			continue

		if(O.invisibility == INVISIBILITY_MAXIMUM || HAS_TRAIT(O, TRAIT_T_RAY_VISIBLE))
			var/image/I = new(loc = get_turf(O))
			var/mutable_appearance/MA = new(O)
			MA.alpha = 128
			MA.dir = O.dir
			I.appearance = MA
			t_ray_images += I
	if(t_ray_images.len)
		flick_overlay(t_ray_images, list(viewer.client), flick_time)

/obj/item/healthanalyzer
	name = "health analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "health"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner able to distinguish vital signs of the subject."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	materials = list(/datum/material/iron=200)
	var/advanced = FALSE

/obj/item/healthanalyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!</span>")
	return BRUTELOSS

/obj/item/healthanalyzer/attack_self(mob/user)
			to_chat(user, "<span class='notice'>You switch the health analyzer to report extra info on wounds.</span>")

/obj/item/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)
	flick("[icon_state]-scan", src)	//makes it so that it plays the scan animation upon scanning, including clumsy scanning

	// Clumsiness/brain damage check
	if ((HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_TRAIT(user, TRAIT_DUMB)) && prob(50))
		to_chat(user, "<span class='notice'>You stupidly try to analyze the floor's vitals!</span>")
		user.visible_message("<span class='warning'>[user] has analyzed the floor's vitals!</span>")
		to_chat(user, "<span class='info'>Analyzing results for The floor:\n\tOverall status: <b>Healthy</b></span>")
		to_chat(user, "<span class='info'>Key: <font color='blue'>Suffocation</font>/<font color='green'>Toxin</font>/<font color='#FF8000'>Burn</font>/<font color='red'>Brute</font></span>")
		to_chat(user, "<span class='info'>\tDamage specifics: <font color='blue'>0</font>-<font color='green'>0</font>-<font color='#FF8000'>0</font>-<font color='red'>0</font></span>")
		to_chat(user, "<span class='info'>Body temperature: ???</span>")
		return


	else if(scanmode == SCANMODE_CHEMICAL)
		chemscan(user, M)

	add_fingerprint(user)


// Used by the PDA medical scanner too
	if(isliving(user) && (user.incapacitated() || user.is_blind()))
		return
	// Damage specifics
	var/oxy_loss = M.getOxyLoss()
	var/tox_loss = M.getToxLoss()
	var/fire_loss = M.getFireLoss()
	var/brute_loss = M.getBruteLoss()
	var/mob_status = (M.stat == DEAD ? "<span class='alert'><b>Deceased</b></span>" : "<b>[round(M.health/M.maxHealth,0.01)*100]% healthy</b>")

	if(HAS_TRAIT(M, TRAIT_FAKEDEATH) && !advanced)
		mob_status = "<span class='alert'><b>Deceased</b></span>"
		oxy_loss = max(rand(1, 40), oxy_loss, (300 - (tox_loss + fire_loss + brute_loss))) // Random oxygen loss

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.undergoing_cardiac_arrest() && H.stat != DEAD)
			render_list += "<span class='alert'>Subject suffering from heart attack: Apply defibrillation or other electric shock immediately!</span>\n"

	render_list += "<span class='info'>Analyzing results for [M]:</span>\n<span class='info ml-1'>Overall status: [mob_status]</span>\n"

	// Damage descriptions
	if(brute_loss > 10)
		render_list += "<span class='alert ml-1'>[brute_loss > 50 ? "Severe" : "Minor"] tissue damage detected.</span>\n"
	if(fire_loss > 10)
		render_list += "<span class='alert ml-1'>[fire_loss > 50 ? "Severe" : "Minor"] burn damage detected.</span>\n"
	if(oxy_loss > 10)
		render_list += "<span class='info ml-1'><span class='alert'>[oxy_loss > 50 ? "Severe" : "Minor"] oxygen deprivation detected.</span>\n"
	if(tox_loss > 10)
		render_list += "<span class='alert ml-1'>[tox_loss > 50 ? "Severe" : "Minor"] amount of toxin damage detected.</span>\n"
	if(M.getStaminaLoss())
		render_list += "<span class='alert ml-1'>Subject appears to be suffering from fatigue.</span>\n"
		if(advanced)
			render_list += "<span class='info ml-1'>Fatigue Level: [M.getStaminaLoss()]%.</span>\n"
	if (M.getCloneLoss())
		render_list += "<span class='alert ml-1'>Subject appears to have [M.getCloneLoss() > 30 ? "Severe" : "Minor"] cellular damage.</span>\n"
		if(advanced)
			render_list += "<span class='info ml-1'>Cellular Damage Level: [M.getCloneLoss()].</span>\n"
	if (!M.getorganslot(ORGAN_SLOT_BRAIN)) // brain not added to carbon/human check because it's funny to get to bully simple mobs
		render_list += "<span class='alert ml-1'>Subject lacks a brain.</span>\n"
	if(ishuman(M))
		var/mob/living/carbon/human/the_dude = M
		var/datum/species/the_dudes_species = the_dude.dna.species
		if (!(NOBLOOD in the_dudes_species.species_traits) && !the_dude.getorganslot(ORGAN_SLOT_HEART))
			render_list += "<span class='alert ml-1'>Subject lacks a heart.</span>\n"
		if (!(TRAIT_NOBREATH in the_dudes_species.species_traits) && !the_dude.getorganslot(ORGAN_SLOT_LUNGS))
			render_list += "<span class='alert ml-1'>Subject lacks lungs.</span>\n"
		if (!(TRAIT_NOMETABOLISM in the_dudes_species.species_traits) && !the_dude.getorganslot(ORGAN_SLOT_LIVER))
			render_list += "<span class='alert ml-1'>Subject lacks a liver.</span>\n"
		if (!(NOSTOMACH in the_dudes_species.species_traits) && !the_dude.getorganslot(ORGAN_SLOT_STOMACH))
			render_list += "<span class='alert ml-1'>Subject lacks a stomach.</span>\n"

	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(LAZYLEN(C.get_traumas()))
			var/list/trauma_text = list()
			for(var/datum/brain_trauma/B in C.get_traumas())
				var/trauma_desc = ""
				switch(B.resilience)
					if(TRAUMA_RESILIENCE_SURGERY)
						trauma_desc += "severe "
					if(TRAUMA_RESILIENCE_LOBOTOMY)
						trauma_desc += "deep-rooted "
					if(TRAUMA_RESILIENCE_MAGIC, TRAUMA_RESILIENCE_ABSOLUTE)
						trauma_desc += "permanent "
				trauma_desc += B.scan_desc
				trauma_text += trauma_desc

		if(C.roundstart_quirks.len)
				render_list += "<span class='info ml-1'>Subject Minor Disabilities: [C.get_quirk_string(FALSE, CAT_QUIRK_MINOR_DISABILITY)].</span>\n"
		if(C.has_quirk(/datum/quirk/allergic))
			render_list += "\t<span class='info ml-1'>Subject is allergic to the chemical [C.allergies].</span>"
	if(advanced)
		render_list += "<span class='info ml-1'>Brain Activity Level: [(200 - M.getOrganLoss(ORGAN_SLOT_BRAIN))/2]%.</span>\n"

	if (M.radiation)
		render_list += "<span class='alert ml-1'>Subject is irradiated.</span>\n"
		if(advanced)
			render_list += "<span class='info ml-1'>Radiation Level: [M.radiation]%.</span>\n"

	if(advanced && M.hallucinating())
		render_list += "<span class='info ml-1'>Subject is hallucinating.</span>\n"

	// Body part damage report
	if(iscarbon(M) && mode == SCANNER_VERBOSE)
		var/mob/living/carbon/C = M
		var/list/damaged = C.get_damaged_bodyparts(1,1)
		if(length(damaged)>0 || oxy_loss>0 || tox_loss>0 || fire_loss>0)
							<td><font color='blue'>[CEILING(oxy_loss,1)]</font></td></tr>"


	if(ishuman(M))
		var/mob/living/carbon/human/H = M
				<td style='width:12em;'><font color='#0000CC'><b>Status</b></font></td>"

				render_list += toReport + "</table>" // tables do not need extra linebreak
		//Genetic damage
		if(advanced && H.has_dna())
			render_list += "<span class='info ml-1'>Genetic Stability: [H.dna.stability]%.</span>\n"

		// Species and body temperature
		var/datum/species/S = H.dna.species
			|| S.flying_species != initial(S.flying_species)

	render_list += "<span class='info ml-1'>Body temperature: [round(M.bodytemperature-T0C,0.1)] &deg;C ([round(M.bodytemperature*1.8-459.67,0.1)] &deg;F)</span>\n"

	// Time of death
	if(M.tod && (M.stat == DEAD || ((HAS_TRAIT(M, TRAIT_FAKEDEATH)) && !advanced)))
		render_list += "<span class='info ml-1'>Time of Death: [M.tod]</span>\n"
		var/tdelta = round(world.time - M.timeofdeath)
		render_list += "<span class='danger'>Subject died [DisplayTimeText(tdelta)] ago, defibrillation[tdelta < (DEFIB_TIME_LIMIT * 10 " may be possible!</span>" ? : " no longer possible." ]</span>"

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(!(D.visibility_flags & HIDDEN_SCANNER))
			</span>" // divs do not need extra linebreak


	// Blood Level
	if(M.has_dna())
		var/mob/living/carbon/C = M
		var/blood_id = C.get_blood_id()
		if(blood_id)
			if(ishuman(C))
				var/mob/living/carbon/human/H = C
			var/blood_percent =  round((C.blood_volume / BLOOD_VOLUME_NORMAL(C))*100)
			var/blood_type = C.dna.blood_type
			if(blood_id != /datum/reagent/blood) // special blood substance
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_id]
				render_list += "<span class='alert ml-1'>Blood level: <b>CRITICAL [blood_percent] %</b>, [C.blood_volume] cl,</span> <span class='info'>type: [blood_type]</span>\n"
			else
				render_list += "<span class='info ml-1'>Blood level: [blood_percent] %, [C.blood_volume] cl, type: [blood_type]</span>\n"

		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/CI in C.internal_organs)
			if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
				cyberimp_detect += "[!cyberimp_detect ? "[CI.get_examine_string(user)]" : ", [CI.get_examine_string(user)]"]"
		if(cyberimp_detect)

	SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, FALSE)

/proc/chemscan(mob/living/user, mob/living/M)
			render_list += "<span class='notice ml-1'>Subject is not addicted to any reagents.</span>\n"

/obj/item/healthanalyzer/advanced
	name = "advanced health analyzer"
	icon_state = "health_adv"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	advanced = TRUE

/obj/item/analyzer
	desc = "A hand-held environmental scanner which reports current gas levels. Alt-Click to use the built in barometer function."
	name = "analyzer"
	custom_price = 10
	icon = 'icons/obj/device.dmi'
	icon_state = "analyzer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	tool_behaviour = TOOL_ANALYZER
	materials = list(/datum/material/iron=30, /datum/material/glass=20)
	grind_results = list(/datum/reagent/mercury = 5, /datum/reagent/iron = 5, /datum/reagent/silicon = 5)
	var/cooldown = FALSE
	var/cooldown_time = 250
	var/accuracy // 0 is the best accuracy.

/obj/item/analyzer/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click [src] to activate the barometer function.</span>"

/obj/item/analyzer/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!</span>")
	return BRUTELOSS

/obj/item/analyzer/attack_self(mob/user)
	add_fingerprint(user)
	scangasses(user)			//yogs start: Makes the gas scanning able to be used elseware

/obj/item/proc/scangasses(mob/user)
	//yogs stop

	if (user.stat || user.eye_blind)
		return

	var/turf/location = user.loc
	if(!istype(location))
		return

	var/datum/gas_mixture/environment = location.return_air()

	var/pressure = environment.return_pressure()
	var/total_moles = environment.total_moles()

	to_chat(user, "<span class='info'><B>Results:</B></span>")
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		to_chat(user, "<span class='info'>Pressure: [round(pressure, 0.01)] kPa</span>")
	else
		to_chat(user, "<span class='alert'>Pressure: [round(pressure, 0.01)] kPa</span>")
	if(total_moles)
		var/o2_concentration = environment.get_moles(/datum/gas/oxygen)/total_moles
		var/n2_concentration = environment.get_moles(/datum/gas/nitrogen)/total_moles
		var/co2_concentration = environment.get_moles(/datum/gas/carbon_dioxide)/total_moles
		var/plasma_concentration = environment.get_moles(/datum/gas/plasma)/total_moles

		if(abs(n2_concentration - N2STANDARD) < 20)
			to_chat(user, "<span class='info'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/nitrogen), 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='alert'>Nitrogen: [round(n2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/nitrogen), 0.01)] mol)</span>")

		if(abs(o2_concentration - O2STANDARD) < 2)
			to_chat(user, "<span class='info'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/oxygen), 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='alert'>Oxygen: [round(o2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/oxygen), 0.01)] mol)</span>")

		if(co2_concentration > 0.01)
			to_chat(user, "<span class='alert'>CO2: [round(co2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/carbon_dioxide), 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='info'>CO2: [round(co2_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/carbon_dioxide), 0.01)] mol)</span>")

		if(plasma_concentration > 0.005)
			to_chat(user, "<span class='alert'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/plasma), 0.01)] mol)</span>")
		else
			to_chat(user, "<span class='info'>Plasma: [round(plasma_concentration*100, 0.01)] % ([round(environment.get_moles(/datum/gas/plasma), 0.01)] mol)</span>")

		for(var/id in environment.get_gases())
			if(id in GLOB.hardcoded_gases)
				continue
			var/gas_concentration = environment.get_moles(id)/total_moles
			to_chat(user, "<span class='alert'>[GLOB.meta_gas_info[id][META_GAS_NAME]]: [round(gas_concentration*100, 0.01)] % ([round(environment.get_moles(id), 0.01)] mol)</span>")
		to_chat(user, "<span class='info'>Temperature: [round(environment.return_temperature()-T0C, 0.01)] &deg;C ([round(environment.return_temperature(), 0.01)] K)</span>")

/obj/item/analyzer/AltClick(mob/user) //Barometer output for measuring when the next storm happens
	..()

	if(user.canUseTopic(src, BE_CLOSE))

		if(cooldown)
			to_chat(user, "<span class='warning'>[src]'s barometer function is preparing itself.</span>")
			return

		var/turf/T = get_turf(user)
		if(!T)
			return

		playsound(src, 'sound/effects/pop.ogg', 100)
		var/area/user_area = T.loc
		var/datum/weather/ongoing_weather = null

		if(!user_area.outdoors)
			to_chat(user, "<span class='warning'>[src]'s barometer function won't work indoors!</span>")
			return

		for(var/V in SSweather.processing)
			var/datum/weather/W = V
			if(W.barometer_predictable && (T.z in W.impacted_z_levels) && W.area_type == user_area.type && !(W.stage == END_STAGE))
				ongoing_weather = W
				break

		if(ongoing_weather)
			if((ongoing_weather.stage == MAIN_STAGE) || (ongoing_weather.stage == WIND_DOWN_STAGE))
				to_chat(user, "<span class='warning'>[src]'s barometer function can't trace anything while the storm is [ongoing_weather.stage == MAIN_STAGE ? "already here!" : "winding down."]</span>")
				return

			to_chat(user, "<span class='notice'>The next [ongoing_weather] will hit in [butchertime(ongoing_weather.next_hit_time - world.time)].</span>")
			if(ongoing_weather.aesthetic)
				to_chat(user, "<span class='warning'>[src]'s barometer function says that the next storm will breeze on by.</span>")
		else
			var/next_hit = SSweather.next_hit_by_zlevel["[T.z]"]
			var/fixed = next_hit ? next_hit - world.time : -1
			if(fixed < 0)
				to_chat(user, "<span class='warning'>[src]'s barometer function was unable to trace any weather patterns.</span>")
			else
				to_chat(user, "<span class='warning'>[src]'s barometer function says a storm will land in approximately [butchertime(fixed)].</span>")
		cooldown = TRUE
		addtimer(CALLBACK(src,/obj/item/analyzer/proc/ping), cooldown_time)

/obj/item/analyzer/proc/ping()
	if(isliving(loc))
		var/mob/living/L = loc
		to_chat(L, "<span class='notice'>[src]'s barometer function is ready!</span>")
	playsound(src, 'sound/machines/click.ogg', 100)
	cooldown = FALSE

/obj/item/analyzer/proc/butchertime(amount)
	if(!amount)
		return
	if(accuracy)
		var/inaccurate = round(accuracy*(1/3))
		if(prob(50))
			amount -= inaccurate
		if(prob(50))
			amount += inaccurate
	return DisplayTimeText(max(1,amount))

/proc/atmosanalyzer_scan(mixture, mob/living/user, atom/target = src)
	var/icon = target
	user.visible_message("[user] has used the analyzer on [icon2html(icon, viewers(user))] [target].", "<span class='notice'>You use the analyzer on [icon2html(icon, user)] [target].</span>")
	to_chat(user, "<span class='boldnotice'>Results of analysis of [icon2html(icon, user)] [target].</span>")

	var/list/airs = islist(mixture) ? mixture : list(mixture)
	for(var/g in airs)
		if(airs.len > 1) //not a unary gas mixture
			to_chat(user, "<span class='boldnotice'>Node [airs.Find(g)]</span>")
		var/datum/gas_mixture/air_contents = g

		var/total_moles = air_contents.total_moles()
		var/pressure = air_contents.return_pressure()
		var/volume = air_contents.return_volume() //could just do mixture.volume... but safety, I guess?
		var/temperature = air_contents.return_temperature()
		var/cached_scan_results = air_contents.analyzer_results

		if(total_moles > 0)
			to_chat(user, "<span class='notice'>Moles: [round(total_moles, 0.01)] mol</span>")
			to_chat(user, "<span class='notice'>Volume: [volume] L</span>")
			to_chat(user, "<span class='notice'>Pressure: [round(pressure,0.01)] kPa</span>")

			for(var/id in air_contents.get_gases())
				var/gas_concentration = air_contents.get_moles(id)/total_moles
				to_chat(user, "<span class='notice'>[GLOB.meta_gas_info[id][META_GAS_NAME]]: [round(gas_concentration*100, 0.01)] % ([round(air_contents.get_moles(id), 0.01)] mol)</span>")
			to_chat(user, "<span class='notice'>Temperature: [round(temperature - T0C,0.01)] &deg;C ([round(temperature, 0.01)] K)</span>")

		else
			if(airs.len > 1)
				to_chat(user, "<span class='notice'>This node is empty!</span>")
			else
				to_chat(user, "<span class='notice'>[target] is empty!</span>")

		if(cached_scan_results && cached_scan_results["fusion"]) //notify the user if a fusion reaction was detected
			var/instability = round(cached_scan_results["fusion"], 0.01)
			to_chat(user, "<span class='boldnotice'>Large amounts of free neutrons detected in the air indicate that a fusion reaction took place.</span>")
			to_chat(user, "<span class='notice'>Instability of the last fusion reaction: [instability].</span>")
	return

//slime scanner

/obj/item/slime_scanner
	name = "slime scanner"
	desc = "A device that analyzes a slime's internal composition and measures its stats."
	icon = 'icons/obj/device.dmi'
	icon_state = "adv_spectrometer"
	item_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	materials = list(/datum/material/iron=30, /datum/material/glass=20)

/obj/item/slime_scanner/attack(mob/living/M, mob/living/user)
	if(user.stat || user.eye_blind)
		return
	if (!isslime(M))
		to_chat(user, "<span class='warning'>This device can only scan slimes!</span>")
		return
	var/mob/living/simple_animal/slime/T = M
	slime_scan(T, user)

/proc/slime_scan(mob/living/simple_animal/slime/T, mob/living/user)
	to_chat(user, "========================")
	to_chat(user, "<b>Slime scan results:</b>")
	to_chat(user, "<span class='notice'>[T.colour] [T.is_adult ? "adult" : "baby"] slime</span>")
	to_chat(user, "Nutrition: [T.nutrition]/[T.get_max_nutrition()]")
	if (T.nutrition < T.get_starve_nutrition())
		to_chat(user, "<span class='warning'>Warning: slime is starving!</span>")
	else if (T.nutrition < T.get_hunger_nutrition())
		to_chat(user, "<span class='warning'>Warning: slime is hungry</span>")
	to_chat(user, "Electric charge strength: [T.powerlevel]")
	to_chat(user, "Health: [round(T.health/T.maxHealth,0.01)*100]%")
	if (T.slime_mutation[4] == T.colour)
		to_chat(user, "This slime does not evolve any further.")
	else
		if (T.slime_mutation[3] == T.slime_mutation[4])
			if (T.slime_mutation[2] == T.slime_mutation[1])
				to_chat(user, "Possible mutation: [T.slime_mutation[3]]")
				to_chat(user, "Genetic instability: [T.mutation_chance/2] % chance of mutation on splitting")
			else
				to_chat(user, "Possible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]] (x2)")
				to_chat(user, "Genetic instability: [T.mutation_chance] % chance of mutation on splitting")
		else
			to_chat(user, "Possible mutations: [T.slime_mutation[1]], [T.slime_mutation[2]], [T.slime_mutation[3]], [T.slime_mutation[4]]")
			to_chat(user, "Genetic instability: [T.mutation_chance] % chance of mutation on splitting")
	if (T.cores > 1)
		to_chat(user, "Multiple cores detected")
	to_chat(user, "Growth progress: [T.amount_grown]/[SLIME_EVOLUTION_THRESHOLD]")
	if(T.effectmod)
		to_chat(user, "<span class='notice'>Core mutation in progress: [T.effectmod]</span>")
		to_chat(user, "<span class = 'notice'>Progress in core mutation: [T.applied] / [SLIME_EXTRACT_CROSSING_REQUIRED]</span>")
	to_chat(user, "========================")


/obj/item/nanite_scanner
	name = "nanite scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_scanner"
	item_state = "nanite_remote"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner able to detect nanites and their programming."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	materials = list(/datum/material/iron=200)

/obj/item/nanite_scanner/attack(mob/living/M, mob/living/carbon/human/user)
	user.visible_message("<span class='notice'>[user] has analyzed [M]'s nanites.</span>")

	add_fingerprint(user)

	var/response = SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, TRUE)
	if(!response)
		to_chat(user, "<span class='info'>No nanites detected in the subject.</span>")

/obj/item/sequence_scanner
	name = "genetic sequence scanner"
	icon = 'icons/obj/device.dmi'
	icon_state = "gene"
	item_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held scanner for analyzing someones gene sequence on the fly. Hold near a DNA console to update the internal database."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	materials = list(/datum/material/iron=200)
	var/list/discovered = list() //hit a dna console to update the scanners database
	var/list/buffer
	var/ready = TRUE
	var/cooldown = 200

/obj/item/sequence_scanner/attack(mob/living/M, mob/living/carbon/human/user)
	add_fingerprint(user)
	if (!HAS_TRAIT(M, TRAIT_GENELESS) && !HAS_TRAIT(M, TRAIT_BADDNA)) //no scanning if its a husk or DNA-less Species
		user.visible_message("<span class='notice'>[user] has analyzed [M]'s genetic sequence.</span>")
		gene_scan(M, user)

	else
		user.visible_message("<span class='notice'>[user] failed to analyse [M]'s genetic sequence.</span>", "<span class='warning'>[M] has no readable genetic sequence!</span>")

/obj/item/sequence_scanner/attack_self(mob/user)
	display_sequence(user)

/obj/item/sequence_scanner/attack_self_tk(mob/user)
	return

/obj/item/sequence_scanner/afterattack(obj/O, mob/user, proximity)
	. = ..()
	if(!istype(O) || !proximity)
		return

	if(istype(O, /obj/machinery/computer/scan_consolenew))
		var/obj/machinery/computer/scan_consolenew/C = O
		if(C.stored_research)
			to_chat(user, "<span class='notice'>[name] database updated.</span>")
			discovered = C.stored_research.discovered_mutations
		else
			to_chat(user,"<span class='warning'>No database to update from.</span>")

/obj/item/sequence_scanner/proc/gene_scan(mob/living/carbon/C, mob/living/user)
	if(!iscarbon(C) || !C.has_dna())
		return
	buffer = C.dna.mutation_index
	to_chat(user, "<span class='notice'>Subject [C.name]'s DNA sequence has been saved to buffer.</span>")
	if(LAZYLEN(buffer))
		for(var/A in buffer)
			to_chat(user, "<span class='notice'>[get_display_name(A)]</span>")


/obj/item/sequence_scanner/proc/display_sequence(mob/living/user)
	if(!LAZYLEN(buffer) || !ready)
		return
	var/list/options = list()
	for(var/A in buffer)
		options += get_display_name(A)

	var/answer = input(user, "Analyze Potential", "Sequence Analyzer")  as null|anything in options
	if(answer && ready && user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		var/sequence
		for(var/A in buffer) //this physically hurts but i dont know what anything else short of an assoc list
			if(get_display_name(A) == answer)
				sequence = buffer[A]
				break

		if(sequence)
			var/display
			for(var/i in 0 to length_char(sequence) / DNA_MUTATION_BLOCKS-1)
				if(i)
					display += "-"
				display += copytext_char(sequence, 1 + i*DNA_MUTATION_BLOCKS, DNA_MUTATION_BLOCKS*(1+i) + 1)

			to_chat(user, "<span class='boldnotice'>[display]</span><br>")

		ready = FALSE
		icon_state = "[icon_state]_recharging"
		addtimer(CALLBACK(src, .proc/recharge), cooldown, TIMER_UNIQUE)

/obj/item/sequence_scanner/proc/recharge()
	icon_state = initial(icon_state)
	ready = TRUE

/obj/item/sequence_scanner/proc/get_display_name(mutation)
	var/datum/mutation/human/HM = GET_INITIALIZED_MUTATION(mutation)
	if(!HM)
		return "ERROR"
	if(mutation in discovered)
		return  "[HM.name] ([HM.alias])"
	else
		return HM.alias

