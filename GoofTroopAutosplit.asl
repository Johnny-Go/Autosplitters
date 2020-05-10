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
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0002) { Name = "gameStartOne" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0004) { Name = "gameStartTwo" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0202) { Name = "gameStartThree" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x023D) { Name = "gameStartFour" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x00A5) { Name = "endLevelCount" }, //seems to count down 64-0, then 248 to 0 when A8 is set to 2, 'Stage Clear' banner shows at 247
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x00A8) { Name = "endLevelFlag" } //2 starts end level process
	};
}

update
{
	vars.watchers.UpdateAll(game);
}

start
{
	//probably a better way to do this
	if(vars.watchers["gameStartOne"].Current == 0
		&& vars.watchers["gameStartTwo"].Current == 128
		&& vars.watchers["gameStartThree"].Current == 4
		&& (vars.watchers["gameStartFour"].Current == 64 && vars.watchers["gameStartFour"].Old == 255))
	{
		return true;
	}
}

split
{
	if(vars.watchers["endLevelFlag"].Current == 2 && vars.watchers["endLevelCount"].Current == 247)
	{
		return true;
	}
}
