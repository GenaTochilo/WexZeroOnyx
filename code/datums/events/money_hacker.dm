// TODO(rufus): with the economy currently not playing a major part in the crew's life, this event can stay
//   as it is for now. However, gameplay-wise it's just an annoyance that players don't really interact with.
//   At best an experineced HoP or player with access will suspend the accounts temporarily through a cryptic
//   financial console at the HoP's office. The usual case though is some people know to increase their account's
//   security level and the rest doesn't, and then they'd just complain about the withdrawn money because they missed
//   the event announcement.
//   This does create *some* interactions, but needs to be imrpoved together with the global economy part of the game.
/datum/event/money_hacker
	id = "money_hacker"
	name = "Money Hacker"
	description = ""

	mtth = 2 HOURS
	difficulty = 55
	fire_only_once = TRUE

/datum/event/money_hacker/get_mtth()
	. = ..()
	. -= (SSevents.triggers.living_players_count * (6 MINUTES))
	. = max(1 HOUR, .)

/datum/event/money_hacker/check_conditions()
	. = SSevents.evars["money_hacker_running"] != TRUE

/datum/event/money_hacker/on_fire()
	if(!length(all_money_accounts))
		return

	SSevents.evars["money_hacker_running"] = TRUE

	command_announcement.Announce(
		"A brute force hack has been detected (in progress since [stationtime2text()]). The target of the attack is: Financial accounts, \
		without intervention this attack will succeed in approximately 10 minutes. Possible solutions: suspension of accounts, disabling NTnet server, \
		increase account security level. Notifications will be sent as updates occur.",
		"[station_name()] Firewall Subroutines",
		// TODO(rufus): the announcement sound is borked because generated speech literally pronounces "backslash", needs fixing.
		new_sound = 'sound/AI/moneyhackstart.ogg'
	)

	addtimer(CALLBACK(src, nameof(.proc/end)), 10 MINUTES)

/datum/event/money_hacker/proc/end()
	SSevents.evars["money_hacker_running"] = FALSE

	var/message
	var/snd
	var/list/datum/money_account/affected_accounts = list()

	for(var/datum/money_account/M in all_money_accounts)
		if(M.suspended)
			continue
		if(M.security_level >= 1)
			continue
		if(M.off_station)
			continue
		if(M.money <= 0)
			continue
		affected_accounts |= M

	if(ntnet_global?.check_function() && length(affected_accounts))
		//hacker wins
		message = "The hack attempt has succeeded."
		snd = 'sound/AI/moneyhackwin.ogg'
		var/target_name = pick("","yo brotha from anotha motha","el Presidente","chieF smackDowN")
		var/purpose = pick("Ne$ ---ount fu%ds init*&lisat@*n","PAY BACK YOUR MUM","Funds withdrawal","pWnAgE","l33t hax","liberationez")
		var/d1 = "31 December, 1999"
		var/d2 = "[num2text(rand(1,31))] [pick("January","February","March","April","May","June","July","August","September","October","November","December")], [rand(1000,3000)]"
		var/date = pick("", stationdate2text(), d1, d2)
		var/t1 = rand(0, 99999999)
		var/t2 = "[round(t1 / 36000)+12]:[(t1 / 600 % 60) < 10 ? add_zero(t1 / 600 % 60, 1) : t1 / 600 % 60]"
		var/time = pick("", stationtime2text(), t2)

		//create a taunting log entry
		spawn()
			var/amount = rand(1, length(affected_accounts))
			while(amount)
				var/datum/money_account/affected_account = pick_n_take(affected_accounts)
				var/datum/transaction/T = new()
				T.target_name = target_name
				T.purpose = purpose
				T.amount = -affected_account.money
				T.date = date
				T.time = time
				T.source_terminal = pick("","[pick("Biesel","New Gibson")] GalaxyNet Terminal #[rand(111,999)]","your mums place","nantrasen high CommanD")
				affected_account.do_transaction(T)
				amount--

	else
		//crew wins
		snd = 'sound/AI/moneyhackloose.ogg'

	command_announcement.Announce(message, "[station_name()] Firewall Subroutines", new_sound = snd)
