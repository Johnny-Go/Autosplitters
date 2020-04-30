//Autosplitter created by JohnnyGo
//Retroarch sigscan copied from BenInSweeden's update to the SMW Autosplitter
//Currently just supports retroarch with the 'Snes9x - Current' core

state("retroarch") {}

startup
{
	settings.Add("miniboss", false, "Split on miniboss kill");
	settings.SetToolTip("miniboss", "Split last hit of minibosses");
}

init
{
	print("init called");
	
	long memoryOffset = 0;
	if (game.ProcessName.ToLower() == "retroarch")
	{
		ProcessModuleWow64Safe libretromodule = modules.Where(m => m.ModuleName == "snes9x_libretro.dll").First();
		IntPtr baseAddress = libretromodule.BaseAddress;
		if (game.Is64Bit())
		{
			IntPtr result = IntPtr.Zero;
			SigScanTarget target = new SigScanTarget(13, "83 F9 01 74 10 83 F9 02 75 2C 48 8B 05 ?? ?? ?? ?? 48 8B 40 ??");
			SignatureScanner scanner = new SignatureScanner(game, baseAddress, (int)libretromodule.ModuleMemorySize);
			IntPtr codeOffset = scanner.Scan(target);
			int memoryReference = memory.ReadValue<int>(codeOffset) + (int) codeOffset + 0x04 +  - (int) libretromodule.BaseAddress;
			byte memoryReferenceoffset = memory.ReadValue<byte>(codeOffset + 7);
			IntPtr outOffset;
			new DeepPointer("snes9x_libretro.dll", memoryReference, memoryReferenceoffset, 0x0).DerefOffsets(game, out outOffset);
			memoryOffset = (long) outOffset;
		}
	}
	
	if (memoryOffset == 0)
	{
		throw new Exception("Memory not yet initialized.");
	}
	
	vars.watchers = new MemoryWatcherList
	{
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x00A0) { Name = "screenIndicator" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x00B7) { Name = "level" }, //0-5
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x00B9) { Name = "globalStage" }, //0-24
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0402) { Name = "startedOne" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0403) { Name = "startedTwo" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0424) { Name = "startedThree" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0440) { Name = "startedFour" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0456) { Name = "cloudHealth" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0420) { Name = "enemy1Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0480) { Name = "enemy2Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x04E0) { Name = "enemy3Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0540) { Name = "enemy4Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x05A0) { Name = "enemy5Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0600) { Name = "enemy6Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0660) { Name = "enemy7Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x06C0) { Name = "enemy8Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0720) { Name = "enemy9Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0780) { Name = "enemy10Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x07E0) { Name = "enemy11Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0840) { Name = "enemy12Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x08A0) { Name = "enemy13Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0900) { Name = "enemy14Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0960) { Name = "enemy15Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x09C0) { Name = "enemy16Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0A20) { Name = "enemy17Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0A80) { Name = "enemy18Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0AE0) { Name = "enemy19Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0B40) { Name = "enemy20Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0BA0) { Name = "enemy21Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0C00) { Name = "enemy22Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0C60) { Name = "enemy23Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0CC0) { Name = "enemy24Health" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0411) { Name = "enemy1Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0471) { Name = "enemy2Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x04D1) { Name = "enemy3Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0531) { Name = "enemy4Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0591) { Name = "enemy5Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x05F1) { Name = "enemy6Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0651) { Name = "enemy7Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x06B1) { Name = "enemy8Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0711) { Name = "enemy9Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0771) { Name = "enemy10Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x07D1) { Name = "enemy11Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0831) { Name = "enemy12Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0891) { Name = "enemy13Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x08F1) { Name = "enemy14Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0951) { Name = "enemy15Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x09B1) { Name = "enemy16Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0A11) { Name = "enemy17Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0A71) { Name = "enemy18Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0AD1) { Name = "enemy19Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0B31) { Name = "enemy20Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0B91) { Name = "enemy21Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0BF1) { Name = "enemy22Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0C51) { Name = "enemy23Sprite" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0CB1) { Name = "enemy24Sprite" }
	};
	
	//initialize variables
	vars.deathSprite = -1;
}

update
{
	vars.watchers.UpdateAll(game);
	
	//boss death sprites
	switch((int)vars.watchers["globalStage"].Current)
	{
		case 0:
			vars.deathSprite = settings["miniboss"] ? 121 : -1;
			break;
		case 2:
			vars.deathSprite = 154;
			break;
		case 3:
			vars.deathSprite = settings["miniboss"] ? 245 : -1;
			break;
		case 6:
			vars.deathSprite = 221;
			break;
		case 9:
			vars.deathSprite = settings["miniboss"] ? 221 : -1;
			break;
		case 12:
			vars.deathSprite = 215;
			break;
		case 14:
			vars.deathSprite = settings["miniboss"] ? 248 : -1;
			break;
		case 15:
			vars.deathSprite = 116;
			break;
		case 16:
			vars.deathSprite = settings["miniboss"] ? 202 : -1;
			break;
		case 18: //this is the cloud boss stage, may be able to split on cloud hp as it's different from all other bosses
			vars.deathSprite = -1;
			break;
		case 22:
			vars.deathSprite = settings["miniboss"] ? 221 : -1;
			break;
		case 24:
			vars.deathSprite = 179;
			break;
		default:
			vars.deathSprite = -1;
			break;
	}
}

start
{
	//print("start called");
	
	//probably a better way to do this
	if(vars.watchers["startedOne"].Current == 4
		&& (vars.watchers["startedTwo"].Current == 2 || vars.watchers["startedTwo"].Current == 4)
		&& (vars.watchers["startedThree"].Current == 1 || vars.watchers["startedThree"].Current == 2)
		&& vars.watchers["startedFour"].Current == 0)
	{
		return true;
	}
}

split
{
	//don't split on character select
	if(vars.watchers["screenIndicator"].Current == 4)
	{
		return;
	}
	
	//split on boss death
	if((vars.watchers["enemy1Health"].Current == 0 && vars.watchers["enemy1Sprite"].Current == vars.deathSprite && vars.watchers["enemy1Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy2Health"].Current == 0 && vars.watchers["enemy2Sprite"].Current == vars.deathSprite && vars.watchers["enemy2Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy3Health"].Current == 0 && vars.watchers["enemy3Sprite"].Current == vars.deathSprite && vars.watchers["enemy3Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy4Health"].Current == 0 && vars.watchers["enemy4Sprite"].Current == vars.deathSprite && vars.watchers["enemy4Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy5Health"].Current == 0 && vars.watchers["enemy5Sprite"].Current == vars.deathSprite && vars.watchers["enemy5Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy6Health"].Current == 0 && vars.watchers["enemy6Sprite"].Current == vars.deathSprite && vars.watchers["enemy6Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy7Health"].Current == 0 && vars.watchers["enemy7Sprite"].Current == vars.deathSprite && vars.watchers["enemy7Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy8Health"].Current == 0 && vars.watchers["enemy8Sprite"].Current == vars.deathSprite && vars.watchers["enemy8Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy9Health"].Current == 0 && vars.watchers["enemy9Sprite"].Current == vars.deathSprite && vars.watchers["enemy9Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy10Health"].Current == 0 && vars.watchers["enemy10Sprite"].Current == vars.deathSprite && vars.watchers["enemy10Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy11Health"].Current == 0 && vars.watchers["enemy11Sprite"].Current == vars.deathSprite && vars.watchers["enemy11Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy12Health"].Current == 0 && vars.watchers["enemy12Sprite"].Current == vars.deathSprite && vars.watchers["enemy12Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy13Health"].Current == 0 && vars.watchers["enemy13Sprite"].Current == vars.deathSprite && vars.watchers["enemy13Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy14Health"].Current == 0 && vars.watchers["enemy14Sprite"].Current == vars.deathSprite && vars.watchers["enemy14Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy15Health"].Current == 0 && vars.watchers["enemy15Sprite"].Current == vars.deathSprite && vars.watchers["enemy15Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy16Health"].Current == 0 && vars.watchers["enemy16Sprite"].Current == vars.deathSprite && vars.watchers["enemy16Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy17Health"].Current == 0 && vars.watchers["enemy17Sprite"].Current == vars.deathSprite && vars.watchers["enemy17Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy18Health"].Current == 0 && vars.watchers["enemy18Sprite"].Current == vars.deathSprite && vars.watchers["enemy18Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy19Health"].Current == 0 && vars.watchers["enemy19Sprite"].Current == vars.deathSprite && vars.watchers["enemy19Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy20Health"].Current == 0 && vars.watchers["enemy20Sprite"].Current == vars.deathSprite && vars.watchers["enemy20Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy21Health"].Current == 0 && vars.watchers["enemy21Sprite"].Current == vars.deathSprite && vars.watchers["enemy21Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy22Health"].Current == 0 && vars.watchers["enemy22Sprite"].Current == vars.deathSprite && vars.watchers["enemy22Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy23Health"].Current == 0 && vars.watchers["enemy23Sprite"].Current == vars.deathSprite && vars.watchers["enemy23Sprite"].Old != vars.deathSprite)
		|| (vars.watchers["enemy24Health"].Current == 0 && vars.watchers["enemy24Sprite"].Current == vars.deathSprite && vars.watchers["enemy24Sprite"].Old != vars.deathSprite))
	{
		print("Boss dead: " + vars.deathSprite.ToString());
		return true;
	}
	
	//cloud boss is weird, hopefully it's health doesn't get placed in different places in memory like the other bosses
	if(vars.watchers["globalStage"].Current == 18 && vars.watchers["cloudHealth"].Current == 0 && vars.watchers["cloudHealth"].Old != 0)
	{
		print("Cloud dead");
		return true;
	}
}
