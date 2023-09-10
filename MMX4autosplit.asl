//Created by JohnnyGo
//Last updated 9/10/2023
//Used Coltaho's Duckstation and Bizhawk memory finder logic

state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
//1721CC		level
//1721CD		stage
//1721C1		characterSelect1
//1721E6		characterSelect2
//11D880		generalDialogStartX
//173CA5		generalDialogStartZero
//1721CF		triggerTeleport
//16E5EE		xBlueTeleport
//16E617		zeroRedTeleport
//165BD9		goldTeleportActive
//172207		upgrades
//1754D0		exitSelected
//172203		characterFlag
//141932		useForTeleport
//143059		owlPeacockColonel2Sigma2and3Explosion

state("EmuHawk") {}
//Add 0x11D880 to RAM watch address to get these
//byte level :									"octoshock.dll", 0x1721CC;
//byte stage :									"octoshock.dll", 0x1721CD;
//byte characterSelect1 :						"octoshock.dll", 0x1721C1;
//byte characterSelect2 :						"octoshock.dll", 0x1721E6
//byte generalDialogStartX :					"octoshock.dll", 0x11D880
//byte generalDialogStartZero :					"octoshock.dll", 0x173CA5
//byte triggerTeleport :						"octoshock.dll", 0x1721CF
//byte xBlueTeleport :							"octoshock.dll", 0x16E5EE
//byte zeroRedTeleport :						"octoshock.dll", 0x16E617
//byte goldTeleportActive :						"octoshock.dll", 0x165BD9
//byte upgrades :								"octoshock.dll", 0x172207
//byte exitSelected :							"octoshock.dll", 0x1754D0
//byte characterFlag :							"octoshock.dll", 0x172203
//byte useForTeleport :							"octoshock.dll", 0x141932
//byte owlPeacockColonel2Sigma2and3Explosion :	"octoshock.dll", 0x143059

state("MMX4") {}
//byte level :									"x4.exe", 0x13A04C;
//byte stage :									"x4.exe", 0x13A04D;
//byte characterSelect1 :						"x4.exe", 0x13A041;
//byte characterSelect2 :						"x4.exe", 0x13A066;
//byte generalDialogStartX :					"x4.exe", 0x149085;
//byte generalDialogStartZero :					"x4.exe", 0x149025;
//byte triggerTeleport :						"x4.exe", 0x13A04F;
//byte xBlueTeleport :							"x4.exe", 0x145786;
//byte zeroRedTeleport :						"x4.exe", 0x14578F;
//byte goldTeleportActive :						"x4.exe", 0x1223C9;
//byte upgrades :								"x4.exe", 0x13A087;
//byte exitSelected :							"x4.exe", 0x144E10;
//byte characterFlag :							"x4.exe", 0x13A083;
//byte useForTeleport :							"x4.exe", 0x144F6A;
//byte owlPeacockColonel2Sigma2and3Explosion :	"x4.exe", 0x138F41;

state("RXC2") {
	
}

startup {
	print("--[Autosplitter] Starting up!");
	refreshRate = 1;
	
	//create info
	settings.Add("infosection", true, "---Info---");
	settings.Add("info", true, "Mega Man X4 AutoSplitter by Johnny_Go", "infosection");
	settings.Add("info0", true, "- Supported emulators: Bizhawk, DuckStation, PC XLC, and Windows X4", "infosection");
	
	//create settings
	settings.Add("revisitSplit", true, "Split after Dragoon revisit when exit is selected");
	settings.SetToolTip("revisitSplit", "Turn off if you don't want this split");
	settings.Add("doubleSplit", true, "Split after Double/Iris");
	settings.SetToolTip("doubleSplit", "Turn off if you don't want this split");
	
	//setup reset action
	LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) => {
		vars.armorSplitOccurred = false;
		vars.allowZeroSigmaSplit = false;
	};
	vars.resetAction = resetAction;
	timer.OnReset += vars.resetAction;
}

init {
	print("--Setting init variables!--");
	refreshRate = 60;

	//initialize memory variables
	vars.myBaseAddress = IntPtr.Zero;
	vars.watchersInitialized = false;
	vars.tokenSource = new CancellationTokenSource();

	//initialize splitting variables
	vars.armorSplitOccurred = false; //probably unneeded since doing the revisit twice would kill your run
	vars.allowZeroSigmaSplit = false; //probably can find some other value that works making this variable irrelevant

	//set level values
	vars.magmaDragoon = 4;
	vars.colonel1 = 9;
	vars.colonel2 = 10;
	vars.doubleGeneral = 11;
	vars.refightsSigma = 12;

	//method for getting watchers for emulators
	vars.initializeWatchers = (Func<bool>)(() => {
		vars.watchers = new MemoryWatcherList() {
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1721CC)) { Name = "level" }, //0-12 for levels that have bosses
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1721CD)) { Name = "stage" }, //0 for stage one, 1 for stage 2
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1721C1)) { Name = "characterSelect1" }, //when set to 4 along with characterSelect2 being set to 1
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1721E6)) { Name = "characterSelect2" }, //when set to 1 along with characterSelect1 being set to 4
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x11D880)) { Name = "generalDialogStartX" }, //1 for starting General's post Sigma dialog as X
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x173CA5)) { Name = "generalDialogStartZero" }, //1 for starting General's post Sigma dialog as Zero
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1721CF)) { Name = "triggerTeleport" }, //triggers teleport on 16 (fanfare plays first), 1 (just teleports), 64 (fade to black)
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x16E5EE)) { Name = "xBlueTeleport" }, //for X 238 when blue teleport starts
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x16E617)) { Name = "zeroRedTeleport" }, //for Zero 136 when red teleport starts
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x165BD9)) { Name = "goldTeleportActive" }, //when 2 the gold teleporter is active
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x172207)) { Name = "upgrades" }, //stores equipment upgrade (0001 for helm, 0010 for armor, 0100 for buster, 1000 for boots) (14 for splitting on dragoon revisit)
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1754D0)) { Name = "exitSelected" }, //when 1 and menu is closed exit level
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x172203)) { Name = "characterFlag" }, //0 if  X or 1 if Zero
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x141932)) { Name = "useForTeleport" }, //normally set to 15, set to 0 on teleport after boss, level select, boss door transitions and some other times
			new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x143059)) { Name = "owlPeacockColonel2Sigma2and3Explosion" } //26 seems to be the value when explosion starts
		};

		vars.watchersInitialized = true;
		print("--[Autosplitter] Watchers Initialized!");
		return true;
	});
	
	vars.threadScan = new Thread(() => {
		print("--[Autosplitter] Starting Thread Scan...");
		var processName = game.ProcessName.ToLowerInvariant();
		SignatureScanner gameAssemblyScanner = null;
		ProcessModuleWow64Safe gameAssemblyModule = null;

		//Scans for Bizhawk PS1 MainMem
		SigScanTarget gameScanTarget = new SigScanTarget(0x8, "49 03 c9 ff e1 48 8d 05 ?? ?? ?? ?? 48 89 02");
		IntPtr gameSigAddr = IntPtr.Zero;

		while(!vars.tokenSource.IsCancellationRequested) {
			if ((processName.Length > 10) && (processName.Substring(0, 11) == "duckstation")) {
				//gets base address of the first mem_mapped region of 0x200000 size
				foreach (var page in game.MemoryPages(true)) {
					if ((page.RegionSize != (UIntPtr)0x200000) || (page.Type != MemPageType.MEM_MAPPED))
						continue;
					vars.myBaseAddress = page.BaseAddress;
					break;
				}
				if (vars.myBaseAddress != IntPtr.Zero) {
					print("--[Autosplitter] Duckstation Memory BaseAddress: " + vars.myBaseAddress.ToString("X"));
					vars.initializeWatchers();
				}
			}
			else if (processName == "emuhawk") {
				if(gameAssemblyScanner == null) {
					ProcessModuleWow64Safe[] loadedModules = null;
					try {
						loadedModules = game.ModulesWow64Safe();
					}
					catch {
						loadedModules = new ProcessModuleWow64Safe[0];
					}

					gameAssemblyModule = loadedModules.FirstOrDefault(m => m.ModuleName == "octoshock.dll");
					if(gameAssemblyModule == null) {
						print("--[Autosplitter] Modules not initialized");
						Thread.Sleep(500);
						continue;
					}

					gameAssemblyScanner = new SignatureScanner(game, gameAssemblyModule.BaseAddress, gameAssemblyModule.ModuleMemorySize);
				}

				print("--[Autosplitter] Scanning memory");

				if(gameSigAddr == IntPtr.Zero && (gameSigAddr = gameAssemblyScanner.Scan(gameScanTarget)) != IntPtr.Zero) {
					int offset = (int)((long)game.ReadValue<int>(gameSigAddr) + (long)gameSigAddr + 4 - (long)gameAssemblyModule.BaseAddress);
					print("--[Autosplitter] Bizhawk offset from module to Mem: " + offset.ToString("X"));
					vars.myBaseAddress = gameAssemblyModule.BaseAddress + offset;
					print("--[Autosplitter] Bizhawk Memory BaseAddress: " + vars.myBaseAddress.ToString("X"));
					vars.initializeWatchers();
				}
			}
			else if (processName == "mmx4") {
				vars.myBaseAddress = modules.First().BaseAddress;
				vars.watchers = new MemoryWatcherList()
				{
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A04C)) { Name = "level" }, //0-12 for levels that have bosses
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A04D)) { Name = "stage" }, //0 for stage one, 1 for stage 2
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A041)) { Name = "characterSelect1" }, //when set to 4 along with characterSelect2 being set to 1
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A066)) { Name = "characterSelect2" }, //when set to 1 along with characterSelect1 being set to 4
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x149085)) { Name = "generalDialogStartX" }, //1 for starting General's post Sigma dialog as X
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x149025)) { Name = "generalDialogStartZero" }, //1 for starting General's post Sigma dialog as Zero
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A04F)) { Name = "triggerTeleport" }, //triggers teleport on 16 (fanfare plays first), 1 (just teleports), 64 (fade to black)
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x145786)) { Name = "xBlueTeleport" }, //for X 238 when blue teleport starts
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x14578F)) { Name = "zeroRedTeleport" }, //for Zero 136 when red teleport starts
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x1223C9)) { Name = "goldTeleportActive" }, //when 2 the gold teleporter is active
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A087)) { Name = "upgrades" }, //stores equipment upgrade (0001 for helm, 0010 for armor, 0100 for buster, 1000 for boots) (14 for splitting on dragoon revisit)
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x144E10)) { Name = "exitSelected" }, //when 1 and menu is closed exit level
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x13A083)) { Name = "characterFlag" }, //0 if  X or 1 if Zero
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x144F6A)) { Name = "useForTeleport" }, //normally set to 15, set to 0 on teleport after boss, level select, boss door transitions and some other times
					new MemoryWatcher<byte>(new DeepPointer(vars.myBaseAddress + 0x138F41)) { Name = "owlPeacockColonel2Sigma2and3Explosion" }, //26 seems to be the value when explosion starts
				};
				vars.watchersInitialized = true;
			}
			else if (processName == "rxc1")
			{
				vars.watchers = new MemoryWatcherList()
				{
				};
				vars.watchersInitialized = false;
			}
			
			if (vars.watchersInitialized) {
				break;
			}

			print("--[Autosplitter] Couldn't find the pointers I want! Game is still starting or an update broke things!");
			Thread.Sleep(2000);
		}
		print("--[Autosplitter] Exited Thread Scan");
	});

	vars.threadScan.Start();
}

start {
	//start timer once a character is selected
	if(vars.watchers["characterSelect1"].Current == 4 && vars.watchers["characterSelect2"].Current == 1) {
		print("Starting timer");
		return true;
	}
}

update {
	//failed to find supported version, do nothing
	if(!vars.watchersInitialized) {
		return false;
	}

	vars.watchers.UpdateAll(game);
	
	//allow splitting after sigma dies
	if(vars.watchers["characterFlag"].Current == 1
		&& vars.watchers["level"].Current == vars.refightsSigma
		&& vars.watchers["stage"].Current == 1
		&& vars.watchers["owlPeacockColonel2Sigma2and3Explosion"].Current == 26 && vars.watchers["owlPeacockColonel2Sigma2and3Explosion"].Old != 26) {
		vars.allowZeroSigmaSplit = true;
	}
}

split {
	//split on teleport after boss except colonel 1, colonel 2, double, refights, and sigma
	if(vars.watchers["stage"].Current == 1
		&& (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
		&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0)) {
		return true;
	}
	
	//split after colonel 1 and 2
	if((vars.watchers["level"].Current == vars.colonel1 || vars.watchers["level"].Current == vars.colonel2)
		&& (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
		&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0)) {
		return true;
	}
	
	//split after double/iris
	if(settings["doubleSplit"]
		&& vars.watchers["level"].Current == vars.doubleGeneral
		&& vars.watchers["stage"].Current == 0
		&& ((vars.watchers["characterFlag"].Current == 0 && (vars.watchers["triggerTeleport"].Current == 16 || vars.watchers["triggerTeleport"].Current == 1)
			&& (vars.watchers["useForTeleport"].Current == 0 && vars.watchers["useForTeleport"].Old != 0))
			|| (vars.watchers["characterFlag"].Current == 1 && (vars.watchers["triggerTeleport"].Current == 64 && vars.watchers["triggerTeleport"].Old != 64)))) {
		return true;
	}
	
	//split after dragoon revisit
	if(settings["revisitSplit"]
		&& vars.watchers["level"].Current == vars.magmaDragoon
		&& vars.watchers["stage"].Current == 1
		&& vars.watchers["upgrades"].Current == 14
		&& vars.watchers["exitSelected"].Current == 1
		&& !vars.armorSplitOccurred) {
		vars.armorSplitOccurred = true;
		return true;
	}
	
	//split after refights
	if(vars.watchers["goldTeleportActive"].Current == 2
		&& ((vars.watchers["characterFlag"].Current == 0 && vars.watchers["xBlueTeleport"].Current == 238 && vars.watchers["xBlueTeleport"].Old != 238)
			|| (vars.watchers["characterFlag"].Current == 1 && vars.watchers["zeroRedTeleport"].Current == 136 && vars.watchers["zeroRedTeleport"].Old != 136))) {
		return true;
	}
	
	//split on loss of control after sigma
	if (vars.watchers["level"].Current == vars.refightsSigma
		&& vars.watchers["stage"].Current == 1
		&& ((vars.watchers["characterFlag"].Current == 0 && vars.watchers["generalDialogStartX"].Current == 1 && vars.watchers["generalDialogStartX"].Old != 1)
			|| (vars.watchers["characterFlag"].Current == 1 && vars.allowZeroSigmaSplit && vars.watchers["generalDialogStartZero"].Current == 1 && vars.watchers["generalDialogStartZero"].Old != 1))) {
		return true;
	}
}

exit {
	//set the refresh rate to once a second until the octoshock.dll is found
	refreshRate = 1;

	vars.tokenSource.Cancel();
}

shutdown {
	//unload event
	timer.OnReset -= vars.resetAction;

	vars.tokenSource.Cancel();
}
