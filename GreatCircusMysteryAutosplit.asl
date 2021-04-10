//Autosplitter created by JohnnyGo
//Thanks to BenInSweeden, Coltaho, and Gelly for help and suggestions
//Retroarch sigscan copied from BenInSweeden's update to the SMW Autosplitter
//Currently just supports retroarchX64 with the 'Snes9x - Current' core

state("retroarch") {}

startup
{
	settings.Add("miniboss", false, "Split on miniboss kill");
	settings.SetToolTip("miniboss", "Split last hit of minibosses");
}

init
{
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
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0456) { Name = "cloudHealth" }
	};
	
	vars.enemyHealthWatchers = new MemoryWatcherList();
	vars.enemySpriteWatchers = new MemoryWatcherList();
	for(int i = 0; i < 24; i++)
	{
		var healthOffset = 0x0420 + (i * 0x60);
		var spriteOffset = 0x0411 + (i * 0x60);
		
		vars.enemyHealthWatchers.Add(new MemoryWatcher<byte>((IntPtr)memoryOffset + healthOffset) { Name = ("enemyHealth" + i.ToString()) });
		vars.enemySpriteWatchers.Add(new MemoryWatcher<byte>((IntPtr)memoryOffset + spriteOffset) { Name = ("enemySprite" + i.ToString()) });
	}
	
	//initialize variables
	vars.deathSprite = -1;
}

update
{
	vars.watchers.UpdateAll(game);
	vars.enemyHealthWatchers.UpdateAll(game);
	vars.enemySpriteWatchers.UpdateAll(game);
	
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
		case 16: //this is the sled weasel, it doesn't make sense to split when it dies since the level is on a timer, split on screen transition instead
			//vars.deathSprite = -1; //202 for miniboss death sprite
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
	
	//split on boss/miniboss death
	for(int i = 0; i < 24; i++)
	{
		var healthName = "enemyHealth" + i.ToString();
		var spriteName = "enemySprite" + i.ToString();
		
		if(vars.enemyHealthWatchers[healthName].Current == 0 && vars.enemySpriteWatchers[spriteName].Current == vars.deathSprite && vars.enemySpriteWatchers[spriteName].Old != vars.deathSprite)
		{
			return true;
		}
	}
	
	//split on screen transition for ice level
	if(settings["miniboss"] && vars.watchers["globalStage"].Current == 17 && vars.watchers["globalStage"].Old == 16)
	{
		return true;
	}
	
	//cloud boss is weird, hopefully it's health doesn't get placed in different places in memory like the other bosses
	if(vars.watchers["globalStage"].Current == 18 && vars.watchers["cloudHealth"].Current == 0 && vars.watchers["cloudHealth"].Old != 0)
	{
		return true;
	}
}
