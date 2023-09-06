//Autosplitter created by JohnnyGo
//Retroarch sigscan copied from BenInSweeden's update to the SMW Autosplitter
//Currently just supports retroarchX64 with the 'Snes9x - Current' core

state("retroarch") {}

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
			
			//have to do some interesting casting that didn't used to be required, maybe related to Windows 11 or having 32gb of memory, I dunno
			int memoryReference = memory.ReadValue<int>(codeOffset) + (int)((long)codeOffset + 0x04 - (long)libretromodule.BaseAddress);

			byte memoryReferenceoffset = memory.ReadValue<byte>(codeOffset + 7);
			IntPtr outOffset;
			new DeepPointer("snes9x_libretro.dll", memoryReference, memoryReferenceoffset, 0x0).DerefOffsets(game, out outOffset);
			memoryOffset = (long)outOffset;
		}
	}
	
	if (memoryOffset == 0)
	{
		throw new Exception("Memory not yet initialized.");
	}
		
	vars.watchers = new MemoryWatcherList
	{
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0096) { Name = "startedOne" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1863) { Name = "startedTwo" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x3784) { Name = "startedThree" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x3785) { Name = "startedFour" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x008E) { Name = "globalStage" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0A6F) { Name = "peteHealth" }
	};
}

update
{
	vars.watchers.UpdateAll(game);
}

start
{
	//probably a better way to do this
	if(vars.watchers["startedOne"].Current == 1 && vars.watchers["startedOne"].Old == 0
		&& vars.watchers["startedTwo"].Current == 131 && vars.watchers["startedTwo"].Old == 128
		&& vars.watchers["startedThree"].Current == 60 && vars.watchers["startedThree"].Old == 1
		&& vars.watchers["startedFour"].Current == 188 && vars.watchers["startedFour"].Old == 89)
	{
		return true;
	}
}

split
{
	//don't split on character select screen
	if(vars.watchers["globalStage"].Current == 34)
	{
		return;
	}

	//split on screen transition after boss/miniboss
	if((vars.watchers["globalStage"].Current == 3 && vars.watchers["globalStage"].Old == 2)			//turkey
		|| (vars.watchers["globalStage"].Current == 35 && vars.watchers["globalStage"].Old == 30)	//pig
		|| (vars.watchers["globalStage"].Current == 7 && vars.watchers["globalStage"].Old == 6)		//moth
		|| (vars.watchers["globalStage"].Current == 32 && vars.watchers["globalStage"].Old == 8)	//plant
		|| (vars.watchers["globalStage"].Current == 27 && vars.watchers["globalStage"].Old == 26)	//skeleton
		|| (vars.watchers["globalStage"].Current == 33 && vars.watchers["globalStage"].Old == 29)	//worm
		|| (vars.watchers["globalStage"].Current == 11 && vars.watchers["globalStage"].Old == 10)	//cannon
		|| (vars.watchers["globalStage"].Current == 44 && vars.watchers["globalStage"].Old == 12)	//pirate
		|| (vars.watchers["globalStage"].Current == 40 && vars.watchers["globalStage"].Old == 15)	//octopus
		|| (vars.watchers["globalStage"].Current == 42 && vars.watchers["globalStage"].Old == 18)	//yeti
		//|| (vars.watchers["globalStage"].Current == 69 && vars.watchers["globalStage"].Old == 22)	//refight 1 - cannon
		|| (vars.watchers["globalStage"].Current == 24 && vars.watchers["globalStage"].Old == 23)	//refight 2 - pirate
		|| (vars.watchers["globalStage"].Current == 25 && vars.watchers["globalStage"].Old == 24))	//magician
	{
		return true;
	}

	//split on last hit for pete
	if(vars.watchers["globalStage"].Current == 25 && vars.watchers["peteHealth"].Current == 0 && vars.watchers["peteHealth"].Old != 0)
	{
		return true;
	}
}
