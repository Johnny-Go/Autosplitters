state("EmuHawk") {}
state("Xebra") {}
state("Mednafen") {}
state("MMX4") {}

startup
{
	print("startup called");
	
	//set the refresh rate to once a second until the octoshock.dll is found
	refreshRate = 1;
	
	//create info
	settings.Add("infosection", true, "---Info---");
	settings.Add("info", true, "Mega Man X4 AutoSplitter by Johnny_Go", "infosection");
	settings.Add("info0", true, "- Supported emulators: EmuHawk 2.3.0 - 2.3.2, Xebra 19/06/25, Mednafen 1.22.2 32 and 64 bit", "infosection");
	
	//create settings
	settings.Add("teleportSplit", true, "Split on teleport instead of boss explosion");
	settings.SetToolTip("teleportSplit", "Turn off if you want to split on boss explosion");
	settings.Add("fadeSplit", true, "Split on fade to black after refights");
	settings.SetToolTip("fadeSplit", "Turn off if you want to split on gold teleport");
	settings.Add("revisitSplit", true, "Split after Dragoon revisit when exit is selected");
	settings.SetToolTip("revisitSplit", "Turn off if you don't want this split");
	settings.Add("doubleSplit", true, "Split after Double/Iris");
	settings.SetToolTip("doubleSplit", "Turn off if you don't want this split");
	
	//setup reset action
	LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) =>
	{
		vars.armorSplitOccurred = false;
		vars.allowColonelSplit = false;
	};
	vars.resetAction = resetAction;
	timer.OnReset += vars.resetAction;
	
	//set level values
	vars.magmaDragoon = 4;
	vars.colonel1 = 9;
	vars.colonel2 = 10;
	vars.doubleGeneral = 11;
	vars.refightsSigma = 12;
	
	//method for getting boss name
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
	
	vars.GetMemoryInfoXebra = (Action<Process, int>)((proc, myModuleSize) =>
	{
		vars.memoryStart = IntPtr.Zero;
		vars.additionalOffset = IntPtr.Zero;
		
		switch(myModuleSize)
		{
			case 770048: //Xebra 19/06/25
				vars.memoryStart = (IntPtr)proc.ReadValue<int>((IntPtr)0x4A6E28);
				vars.additionalOffset = -0x11D880;
				break;
			default: //Unknown
				vars.memoryStart = IntPtr.Zero;
				vars.additionalOffset = IntPtr.Zero;
				break;
		}
	});
	
	vars.GetMemoryInfoNonXebra = (Action<int>)((myModuleSize) =>
	{
		vars.additionalOffset = IntPtr.Zero;
		
		switch(myModuleSize)
		{
			case 7061504: //BizHawk 2.3.0 x64
				vars.additionalOffset = 0x30;
				break;
			case 7249920: //BizHawk 2.3.1 x64
				vars.additionalOffset = 0x0;
				break;
			case 6938624: //BizHawk 2.3.2 x64
				vars.additionalOffset = 0x0;
				break;
			case 68435968: //Mednafen 1.22.2-win32
				vars.additionalOffset = 0x01AE6C60;
				break;
			case 97869824: //Mednafen-1.22.2-win64
				vars.additionalOffset = 0x023FD980;
				break;
			case 2203648: //MMX4 PC
				vars.additionalOffset = 0x0;
				break;
			default: //Unknown
				vars.additionalOffset = IntPtr.Zero;
				break;
		}
	});
	
	//method for getting watchers for emulators
	vars.GetWatcherListEmulators = (Func<IntPtr, int, MemoryWatcherList>)((memoryStart, additionalOffset) =>
	{
		return new MemoryWatcherList
		{
			new MemoryWatcher<byte>(memoryStart + 0x28FA4C + additionalOffset) { Name = "level" }, //0-12 for levels that have bosses
			new MemoryWatcher<byte>(memoryStart + 0x28FA4D + additionalOffset) { Name = "stage" }, //0 for stage one, 1 for stage 2
			new MemoryWatcher<byte>(memoryStart + 0x28FA41 + additionalOffset) { Name = "characterSelect1" }, //when set to 4 along with characterSelect2 being set to 1
			new MemoryWatcher<byte>(memoryStart + 0x28FA66 + additionalOffset) { Name = "characterSelect2" }, //when set to 1 along with characterSelect1 being set to 4
			new MemoryWatcher<byte>(memoryStart + 0x291585 + additionalOffset) { Name = "generalDialogStartX" }, //1 for starting General's post Sigma dialog as X
			new MemoryWatcher<byte>(memoryStart + 0x291525 + additionalOffset) { Name = "generalDialogStartZero" }, //1 for starting General's post Sigma dialog as Zero
			new MemoryWatcher<byte>(memoryStart + 0x28FA4F + additionalOffset) { Name = "triggerTeleport" }, //triggers teleport on 16 (fanfare plays first), 1 (just teleports), 64 (fade to black)
			new MemoryWatcher<byte>(memoryStart + 0x28BE6E + additionalOffset) { Name = "xBlueTeleport" }, //for X 238 when blue teleport starts
			new MemoryWatcher<byte>(memoryStart + 0x28BE97 + additionalOffset) { Name = "zeroRedTeleport" }, //for Zero 136 when red teleport starts
			new MemoryWatcher<byte>(memoryStart + 0x283459 + additionalOffset) { Name = "goldTeleportActive" }, //when 2 the gold teleporter is active
			new MemoryWatcher<byte>(memoryStart + 0x28FA87 + additionalOffset) { Name = "upgrades" }, //stores equipment upgrade (0001 for helm, 0010 for armor, 0100 for buster, 1000 for boots) (14 for splitting on dragoon revisit)
			new MemoryWatcher<byte>(memoryStart + 0x292D50 + additionalOffset) { Name = "exitSelected" }, //when 1 and menu is closed exit level
			new MemoryWatcher<byte>(memoryStart + 0x2597AC + additionalOffset) { Name = "allOtherBossHp" }, //every boss except for the first dragoon fight and double
			new MemoryWatcher<byte>(memoryStart + 0x28FA83 + additionalOffset) { Name = "characterFlag" }, //0 if  X or 1 if Zero
			new MemoryWatcher<byte>(memoryStart + 0x25F1B2 + additionalOffset) { Name = "useForTeleport" }, //normally set to 15, set to 0 on teleport after boss, level select, boss door transitions and some other times
			new MemoryWatcher<byte>(memoryStart + 0x260969 + additionalOffset) { Name = "stingrayRefightsExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x260A89 + additionalOffset) { Name = "walrusExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x260A29 + additionalOffset) { Name = "dragoonExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x260909 + additionalOffset) { Name = "beastDoubleIrisExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x260939 + additionalOffset) { Name = "eregionMushroomExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x2609C9 + additionalOffset) { Name = "spiderExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x2608D9 + additionalOffset) { Name = "owlPeacockColonel2Explosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x260819 + additionalOffset) { Name = "generalExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x259754 + additionalOffset) { Name = "colonelDefeated" }, //2 when colonel1 has been defeated
			new MemoryWatcher<byte>(memoryStart + 0x259753 + additionalOffset) { Name = "colonelOnScreen" }, //1 when colone11 is present on screen
			new MemoryWatcher<byte>(memoryStart + 0x28FA64 + additionalOffset) { Name = "bossHpBars" } //0 to hide boss hp bars
		};
	});
	
	//method for getting watchers for the PC version
	vars.GetWatcherListPc = (Func<IntPtr, int, MemoryWatcherList>)((memoryStart, additionalOffset) =>
	{
		return new MemoryWatcherList
		{
			new MemoryWatcher<byte>(memoryStart + 0x13A04C + additionalOffset) { Name = "level" }, //0-12 for levels that have bosses
			new MemoryWatcher<byte>(memoryStart + 0x13A04D + additionalOffset) { Name = "stage" }, //0 for stage one, 1 for stage 2
			new MemoryWatcher<byte>(memoryStart + 0x13A041 + additionalOffset) { Name = "characterSelect1" }, //when set to 4 along with characterSelect2 being set to 1
			new MemoryWatcher<byte>(memoryStart + 0x13A066 + additionalOffset) { Name = "characterSelect2" }, //when set to 1 along with characterSelect1 being set to 4
			new MemoryWatcher<byte>(memoryStart + 0x149085 + additionalOffset) { Name = "generalDialogStartX" }, //1 for starting General's post Sigma dialog as X
			new MemoryWatcher<byte>(memoryStart + 0x149025 + additionalOffset) { Name = "generalDialogStartZero" }, //1 for starting General's post Sigma dialog as Zero
			new MemoryWatcher<byte>(memoryStart + 0x13A04F + additionalOffset) { Name = "triggerTeleport" }, //triggers teleport on 16 (fanfare plays first), 1 (just teleports), 64 (fade to black)
			new MemoryWatcher<byte>(memoryStart + 0x145786 + additionalOffset) { Name = "xBlueTeleport" }, //for X 238 when blue teleport starts
			new MemoryWatcher<byte>(memoryStart + 0x14578F + additionalOffset) { Name = "zeroRedTeleport" }, //for Zero 136 when red teleport starts
			new MemoryWatcher<byte>(memoryStart + 0x1223C9 + additionalOffset) { Name = "goldTeleportActive" }, //when 2 the gold teleporter is active
			new MemoryWatcher<byte>(memoryStart + 0x13A087 + additionalOffset) { Name = "upgrades" }, //stores equipment upgrade (0001 for helm, 0010 for armor, 0100 for buster, 1000 for boots) (14 for splitting on dragoon revisit)
			new MemoryWatcher<byte>(memoryStart + 0x144E10 + additionalOffset) { Name = "exitSelected" }, //when 1 and menu is closed exit level
			new MemoryWatcher<byte>(memoryStart + 0x13E13C + additionalOffset) { Name = "allOtherBossHp" }, //every boss except for the first dragoon fight and double
			new MemoryWatcher<byte>(memoryStart + 0x13A083 + additionalOffset) { Name = "characterFlag" }, //0 if  X or 1 if Zero
			new MemoryWatcher<byte>(memoryStart + 0x144F6A + additionalOffset) { Name = "useForTeleport" }, //normally set to 15, set to 0 on teleport after boss, level select, boss door transitions and some other times
			new MemoryWatcher<byte>(memoryStart + 0x138FD1 + additionalOffset) { Name = "stingrayRefightsExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x1390F1 + additionalOffset) { Name = "walrusExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x139091 + additionalOffset) { Name = "dragoonExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x138F71 + additionalOffset) { Name = "beastDoubleIrisExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x138FA1 + additionalOffset) { Name = "eregionMushroomExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x139031 + additionalOffset) { Name = "spiderExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x138F41 + additionalOffset) { Name = "owlPeacockColonel2Explosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x138E81 + additionalOffset) { Name = "generalExplosion" }, //26 seems to be the value when explosion starts
			new MemoryWatcher<byte>(memoryStart + 0x13E0E4 + additionalOffset) { Name = "colonelDefeated" }, //2 when colonel1 has been defeated
			new MemoryWatcher<byte>(memoryStart + 0x13E0E3 + additionalOffset) { Name = "colonelOnScreen" }, //1 when colone11 is present on screen
			new MemoryWatcher<byte>(memoryStart + 0x13A064 + additionalOffset) { Name = "bossHpBars" } //0 to hide boss hp bars
		};
	});
}

init
{
	print("init called");
	
	vars.watchers = new MemoryWatcherList();
	vars.memoryStart = IntPtr.Zero;
	vars.additionalOffset = IntPtr.Zero;
	
	//get the emulator type since EmuHawk uses the octoshock.dll 
	vars.moduleName = modules.First().ModuleName.ToString();
	if(vars.moduleName == "EmuHawk.exe")
	{
		if(!modules.Any(m => m.ModuleName == "octoshock.dll"))
		{
			throw new Exception("Can't find octoshock.dll");
		}
		vars.memoryStart = modules.First(m => m.ModuleName == "octoshock.dll").BaseAddress;
		vars.GetMemoryInfoNonXebra(modules.First().ModuleMemorySize);
		vars.platform = "BizHawk";
	}
	else if(vars.moduleName == "mednafen.exe")
	{
		vars.memoryStart = modules.First().BaseAddress;
		vars.GetMemoryInfoNonXebra(modules.First().ModuleMemorySize);
		vars.platform = "mednafen";
	}
	else if(vars.moduleName == "MMX4.exe")
	{
		vars.memoryStart = modules.First().BaseAddress;
		vars.GetMemoryInfoNonXebra(modules.First().ModuleMemorySize);
		vars.platform = "MMX4PC";
	}
	else if(vars.moduleName == "XEBRA.EXE")
	{
		vars.GetMemoryInfoXebra(game, modules.First().ModuleMemorySize);
		vars.platform = "XEBRA";
	}
	else
	{
		print("Unsupported emulator");
		vars.platform = "-1";
	}
	
	//initialize the variables
	vars.armorSplitOccurred = false; //probably unneeded since doing the revisit twice would kill your run
	vars.allowColonelSplit = false;
	
	//reset to the default refresh rate
	refreshRate = 60;
}

start
{
	//start timer once a character is selected
	if(vars.watchers["characterSelect1"].Current == 4 && vars.watchers["characterSelect2"].Current == 1)
	{
		print("Starting timer");
		return true;
	}
}

update
{
	//failed to find supported version, do nothing
	if(vars.platform == "-1")
	{
		return false;
	}
	
	//get the watchers
	if(vars.watchers.Count == 0)
	{
		if(vars.platform == "MMX4PC")
		{
			vars.watchers = vars.GetWatcherListPc(vars.memoryStart, vars.additionalOffset);
		}
		else
		{
			vars.watchers = vars.GetWatcherListEmulators(vars.memoryStart, vars.additionalOffset);
		}
		return false;
	}
	else
	{
		vars.watchers.UpdateAll(game);
	}
	
	//allow splitting after colonel 1 once he teleports after talking
	if(!settings["teleportSplit"]
		&& vars.watchers["level"].Current == vars.colonel1
		&& vars.watchers["allOtherBossHp"].Current == 0
		&& vars.watchers["colonelDefeated"].Current == 2
		&& vars.watchers["bossHpBars"].Current == 0
		&& vars.watchers["colonelOnScreen"].Current == 1
		)
	{
		vars.allowColonelSplit = true;
	}
}

split
{
	//split on teleport after bosses
	if(settings["teleportSplit"])
	{
		//split on teleport after boss except colonel 1, colonel 2, double, refights, and sigma
		if(vars.watchers["stage"].Current == 1
			&& (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
			&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0))
		{
			print("Split after " + vars.getBossName(vars.watchers["level"].Current));
			return true;
		}
		
		//split after colonel 1 and 2
		if((vars.watchers["level"].Current == vars.colonel1 || vars.watchers["level"].Current == vars.colonel2)
			&& (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
			&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0))
		{
			print("Split after " + (vars.watchers["level"].Current == vars.colonel1 ? "Colonel 1" : "Colonel 2"));
			return true;
		}
		
		//split after double/iris
		if(settings["doubleSplit"]
			&& vars.watchers["level"].Current == vars.doubleGeneral
			&& vars.watchers["stage"].Current == 0
			&& ((vars.watchers["characterFlag"].Current == 0 && (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
				&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0))
				|| (vars.watchers["characterFlag"].Current == 1 && (vars.watchers["triggerTeleport"].Current == 64 && vars.watchers["triggerTeleport"].Old != 64))))
		{
			print("Split after Double/Iris");
			return true;
		}
	}
	//split on boss explosion
	else
	{
		//if the second half of the level, and a boss is exploding split
		if(vars.watchers["stage"].Current == 1
			&& ((vars.watchers["stingrayRefightsExplosion"].Current == 26 && vars.watchers["stingrayRefightsExplosion"].Old != 26) //stingray
				|| (vars.watchers["walrusExplosion"].Current == 26 && vars.watchers["walrusExplosion"].Old != 26) //walrus
				|| (vars.watchers["dragoonExplosion"].Current == 26 && vars.watchers["dragoonExplosion"].Old != 26) //dragoon
				|| (vars.watchers["beastDoubleIrisExplosion"].Current == 26 && vars.watchers["beastDoubleIrisExplosion"].Old != 26) //beast
				|| (vars.watchers["eregionMushroomExplosion"].Current == 26 && vars.watchers["eregionMushroomExplosion"].Old != 26) //eregion and mushroom
				|| (vars.watchers["spiderExplosion"].Current == 26 && vars.watchers["spiderExplosion"].Old != 26) //spider
				|| (vars.watchers["owlPeacockColonel2Explosion"].Current == 26 && vars.watchers["owlPeacockColonel2Explosion"].Old != 26) //owl and peacock
				|| (vars.watchers["generalExplosion"].Current == 26 && vars.watchers["generalExplosion"].Old != 26))) //general
		{
			print("Split on " + vars.getBossName(vars.watchers["level"].Current) + " explosion");
			return true;
		}
		
		//if first half of a the level and a boss is exploding split as long as it's not the refights
		if(vars.watchers["stage"].Current == 0
			&& vars.watchers["level"].Current != 12
			&& ((settings["doubleSplit"] && vars.watchers["beastDoubleIrisExplosion"].Current == 26 && vars.watchers["beastDoubleIrisExplosion"].Old != 26) //double and iris
				|| (vars.watchers["owlPeacockColonel2Explosion"].Current == 26 && vars.watchers["owlPeacockColonel2Explosion"].Old != 26))) //colonel 2
		{
			if(vars.watchers["level"].Current == 11)
			{
				print("Split on Double/Iris explosion");
			}
			else
			{
				print("Split on Colonel 2 explosion");
			}
			return true;
		}
		
		//split after colonel 1 teleport
		if(vars.watchers["level"].Current == vars.colonel1
			&& vars.watchers["allOtherBossHp"].Current == 0
			&& (vars.watchers["colonelOnScreen"].Current == 0 && vars.watchers["colonelOnScreen"].Old != 0)
			&& vars.colonelTest)
		{
			print("Split on Colonel 1 teleport");
			return true;
		}
	}
	
	//split after dragoon revisit
	if(settings["revisitSplit"]
		&& vars.watchers["level"].Current == vars.magmaDragoon
		&& vars.watchers["upgrades"].Current == 14
		&& vars.watchers["exitSelected"].Current == 1
		&& !vars.armorSplitOccurred)
	{
		print("Split after Dragoon revisit");
		vars.armorSplitOccurred = true;
		return true;
	}
	
	//split after refights
	if(settings["fadeSplit"] 
		&& vars.watchers["level"].Current == vars.refightsSigma
		&& vars.watchers["stage"].Current == 0
		&& (vars.watchers["triggerTeleport"].Current == 64 && vars.watchers["triggerTeleport"].Old != 64))
	{
		print("Split after Refights - fade to black");
		return true;
	}
	else if(!settings["fadeSplit"]
		&& vars.watchers["goldTeleportActive"].Current == 2
		&& ((vars.watchers["characterFlag"].Current == 0 && vars.watchers["xBlueTeleport"].Current == 238 && vars.watchers["xBlueTeleport"].Old != 238)
			|| (vars.watchers["characterFlag"].Current == 1 && vars.watchers["zeroRedTeleport"].Current == 136 && vars.watchers["zeroRedTeleport"].Old != 136)))
	{
		print("Split after Refights - gold teleport");
		return true;
	}
	
	//split on loss of control after sigma
	if (vars.watchers["level"].Current == vars.refightsSigma
		&& vars.watchers["stage"].Current == 1
		&& ((vars.watchers["characterFlag"].Current == 0 && vars.watchers["generalDialogStartX"].Current == 1 && vars.watchers["generalDialogStartX"].Old != 1)
			|| (vars.watchers["characterFlag"].Current == 1 && vars.watchers["generalDialogStartZero"].Current == 1 && vars.watchers["generalDialogStartZero"].Old != 1)))
	{
		print("Final split");
		return true;
	}
}

exit
{
	print("exit called");
	
	//set the refresh rate to once a second until the octoshock.dll is found
	refreshRate = 1;
}

shutdown
{
	print("shutdown called");
	
	//unload event
	timer.OnReset -= vars.resetAction;
}
