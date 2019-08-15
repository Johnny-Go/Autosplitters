state("EmuHawk") //probably need to specify a version here, currently using 2.3.1 and I think there are differences in the memory addresses between versions
{
	//generally useful memory addresses
	byte level: "octoshock.dll", 0x28FA4C; // 0-12 for stages that have bosses
	byte stage: "octoshock.dll", 0x28FA4D; //0 for stage one, 1 for stage 2
	byte characterSelect1: "octoshock.dll", 0x28FA41; //when set to 4 along with characterSelect2 being set to 1
	byte characterSelect2: "octoshock.dll", 0x28FA66; //when set to 1 along with characterSelect1 being set to 4
	byte generalDialogStart: "octoshock.dll", 0x291585; //1 for starting General's dialog
	byte triggerTeleport: "octoshock.dll", 0x28FA4F; //triggers teleport on 16 (fanfare plays first), 1 (just teleports), 64 (fade to black)
	byte teleportAnimationStart: "octoshock.dll", 0x25F17C; //when 80 starts teleport animation
	byte goldTeleportActive: "octoshock.dll", 0x283459; //when 2 the gold teleporter is active
	byte upgrades: "octoshock.dll", 0x28FA87; //stores equipment upgrade (0001 for helm, 0010 for armor, 0100 for buster, 1000 for boots) (14 for splitting on dragoon revisit).
	byte exitSelected: "octoshock.dll", 0x292D50; //when 1 and menu is closed exit level
	byte allOtherBossHp: "octoshock.dll", 0x2597AC; //every boss except for the first dragoon fight and double
	
	//boss explosion memory addresses
	byte stingrayRefightsExplosion: "octoshock.dll", 0x260969; //26 seems to be the value when explosion starts
	byte walrusExplosion: "octoshock.dll", 0x260A89; //26 seems to be the value when explosion starts
	byte dragoonExplosion: "octoshock.dll", 0x260A29; //26 seems to be the value when explosion starts
	byte beastDoubleExplosion: "octoshock.dll", 0x260909; //26 seems to be the value when explosion starts
	byte eregionMushroomExplosion: "octoshock.dll", 0x260939; //26 seems to be the value when explosion starts
	byte spiderExplosion: "octoshock.dll", 0x2609C9; //26 seems to be the value when explosion starts
	byte owlPeacockColonel2Explosion: "octoshock.dll", 0x2608D9; //26 seems to be the value when explosion starts
	byte generalExplosion: "octoshock.dll", 0x260819; //26 seems to be the value when explosion starts
	byte colonel1Teleport: "octoshock.dll", 0x25976A; //177 seems to be the value when Colonel 1 teleports after the fight
}

startup
{
	print("startup called");
	settings.Add("teleportSplit", true, "Split on teleport instead of boss explosion");
	settings.SetToolTip("teleportSplit", "Turn off if you want to split on boss explosion");
	settings.Add("fadeSplit", true, "Split on fade to black after refights");
	settings.SetToolTip("fadeSplit", "Turn off if you want to split on gold teleport");
	settings.Add("revisitSplit", true, "Split when exit is selected after the Dragoon revist");
	settings.SetToolTip("revisitSplit", "Turn off if you don't want this split");
	settings.Add("doubleSplit", true, "Split after Double");
	settings.SetToolTip("doubleSplit", "Turn off if you don't want this split");

	LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) =>
	{
		vars.armorSplitOccurred = false;
		vars.colonelTeleportCount = 0;
	};
	vars.resetAction = resetAction;
	timer.OnReset += vars.resetAction;
	
	//set level values
	vars.introLevel = 0;
	vars.webSpider = 1;
	vars.frostWalrus = 2;
	vars.splitMushroom = 3;
	vars.magmaDragoon = 4;
	vars.jetStingray = 5;
	vars.cyberPeacock = 6;
	vars.stormOwl = 7;
	vars.slashBeast = 8;
	vars.colonel1 = 9;
	vars.colonel2 = 10;
	vars.doubleGeneral = 11;
	vars.refightsSigma = 12;
	
	vars.getBossName = (Func<int, string>)((levelCode) =>
	{
		switch(levelCode)
		{
			case 0:
				return "Intro";
			case 1:
				return "Web Spider";
			case 2:
				return "Frost Walrus";
			case 3:
				return "Split Mushroom";
			case 4:
				return "Magma Dragoon";
			case 5:
				return "Jet Stingray";
			case 6:
				return "Cyber Peacock";
			case 7:
				return "Storm Owl";
			case 8:
				return "Slash Beast";
			case 11:
				return "General";
			default:
				return "Unknown boss";
		}
	});
}

init
{
	print("init called");
	
	//initialize the variables
	vars.showModuleInfo = true;
	vars.armorSplitOccurred = false; //probably unneeded since doing the revisit twice would kill your run
	vars.colonelTeleportCount = 0; //hacky variable since I can't find a useful memory address
}

start
{
	//start timer once a character is selected
	if(current.characterSelect1 == 4 && current.characterSelect2 == 1) {
		print("Starting timer");
		return true;
	}
}

update
{
	//update colonel 1 teleport count
	if(current.level == vars.colonel1
		&& current.allOtherBossHp == 0
		&& (current.colonel1Teleport == 177 && old.colonel1Teleport != 177))
	{
		vars.colonelTeleportCount += 1;
	}
}

split
{
	//split on teleport after bosses
	if(settings["teleportSplit"])
	{
		//split on teleport after boss except colonel 1, colonel 2, double, refights, and sigma
		if(current.stage == 1
			&& (current.triggerTeleport == 16 || current.triggerTeleport == 1)
			&& (current.teleportAnimationStart == 80 && old.teleportAnimationStart != 80)
			&& current.exitSelected == 0)
		{
			print("Split after " + vars.getBossName(current.level));
			return true;
		}
		
		//split after colonel 1 and 2
		if((current.level == vars.colonel1 || current.level == vars.colonel2)
			&& (current.triggerTeleport == 16 || current.triggerTeleport == 1)
			&& (current.teleportAnimationStart == 80 && old.teleportAnimationStart != 80))
		{
			print("Split after " + (current.level == vars.colonel1 ? "Colonel 1" : "Colonel 2"));
			return true;
		}
		
		//split after double
		if(settings["doubleSplit"]
			&& current.level == vars.doubleGeneral
			&& current.stage == 0
			&& (current.triggerTeleport == 16 || current.triggerTeleport == 1)
			&& (current.teleportAnimationStart == 80 && old.teleportAnimationStart != 80))
		{
			print("Split after Double");
			return true;
		}
	}
	//split on boss explosion, can probably consolidate this a lot but it seems to work for now which is good enough
	else
	{
		//split after stingray
		if(current.level == vars.jetStingray
			&& current.stage == 1
			&& (current.stingrayRefightsExplosion == 26 && old.stingrayRefightsExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after walrus
		if(current.level == vars.frostWalrus
			&& current.stage == 1
			&& (current.walrusExplosion == 26 && old.walrusExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after dragoon
		if(current.level == vars.magmaDragoon
			&& current.stage == 1
			&& (current.dragoonExplosion == 26 && old.dragoonExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after beast
		if(current.level == vars.slashBeast
			&& current.stage == 1
			&& (current.beastDoubleExplosion == 26 && old.beastDoubleExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after double
		if(current.level == vars.doubleGeneral
			&& current.stage == 0
			&& (current.beastDoubleExplosion == 26 && old.beastDoubleExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after eregion/mushroom
		if((current.level == vars.splitMushroom || current.level == vars.introLevel)
			&& current.stage == 1
			&& (current.eregionMushroomExplosion == 26 && old.eregionMushroomExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after spider
		if(current.level == vars.webSpider
			&& current.stage == 1
			&& (current.spiderExplosion == 26 && old.spiderExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after owl/peacock
		if((current.level == vars.stormOwl || current.level == vars.cyberPeacock)
			&& current.stage == 1
			&& (current.owlPeacockColonel2Explosion == 26 && old.owlPeacockColonel2Explosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after colonel 2
		if(current.level == vars.colonel2
			&& current.stage == 0
			&& (current.owlPeacockColonel2Explosion == 26 && old.owlPeacockColonel2Explosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after general
		if(current.level == vars.doubleGeneral
			&& current.stage == 1
			&& (current.generalExplosion == 26 && old.generalExplosion != 26))
		{
			print("Split on " + vars.getBossName(current.level) + " explosion");
			return true;
		}
		
		//split after colonel 1 teleport
		if(current.level == vars.colonel1
			&& current.allOtherBossHp == 0
			&& vars.colonelTeleportCount == 2
			&& (current.colonel1Teleport == 177 && old.colonel1Teleport != 177))
		{
			print("Split on " + vars.getBossName(current.level) + " teleport");
			return true;
		}
	}
	
	//split after dragoon revisit
	if(settings["revisitSplit"]
		&& current.level == vars.magmaDragoon
		&& current.upgrades == 14
		&& current.exitSelected == 1
		&& !vars.armorSplitOccurred)
	{
		print("Split after Dragoon revisit");
		vars.armorSplitOccurred = true;
		return true;
	}
	
	//split after refights
	if(settings["fadeSplit"] 
		&& current.level == vars.refightsSigma
		&& current.stage == 0
		&& (current.triggerTeleport == 64 && old.triggerTeleport != 64))
	{
		print("Split after Refights - fade to black");
		return true;
	}
	else if(!settings["fadeSplit"]
		&& current.goldTeleportActive == 2
		&& (current.teleportAnimationStart == 80 && old.teleportAnimationStart != 80))
	{
		print("Split after Refights - gold teleport");
		return true;
	}
	
	//split on loss of control after sigma
	if (current.level == vars.refightsSigma
		&& current.stage == 1
		&& current.generalDialogStart == 1) 
	{
		print("Final split");
		return true;
	}
}

shutdown
{
	print("shutdown called");
	
	//unload event
	timer.OnReset -= vars.resetAction;
}
