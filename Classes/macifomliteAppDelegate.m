//
//  macifomliteAppDelegate.m
//  macifomlite
//
//  Created by Auston Stewart on 9/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "macifomliteAppDelegate.h"
#import "NESAPUEmulator.h"
#import "NESPPUEmulator.h"
#import "NESCartridgeEmulator.h"
#import "NES6502Interpreter.h"
#import "NESControllerInterface.h"
#import "NESCartridge.h"
#import "NESPlayfieldGLKViewController.h"
#import "NESExternalGLKViewController.h"
#import "NESControllerViewController.h"
#import "NESROMListController.h"

@implementation macifomliteAppDelegate

@synthesize window, externalWindow;
@synthesize viewController;
@synthesize gameIsLoaded;
@synthesize romListController;

#pragma mark -
#pragma mark Application lifecycle

- (UIScreenMode *)preferredScreenModeForOptions:(NSArray *)screenModes
{
    UIScreenMode *bestMode = nil;
    
    for (UIScreenMode *mode in screenModes) {
        
        NSLog(@"Considering display mode: %.0fx%.0f %.2f PASP",mode.size.width,mode.size.height,mode.pixelAspectRatio);
        if (((mode.size.height <= 720.f) && (mode.size.width <= 1280.f) && (mode.pixelAspectRatio == 1.f)) && (!bestMode || (mode.size.height > bestMode.size.height))) bestMode = mode;
    }
    
    return bestMode;
}

- (void)configureScreens
{
    UIScreenMode *targetScreenMode;
    
    if (([[UIScreen screens] count] > 1) && (targetScreenMode = [self preferredScreenModeForOptions:[[[UIScreen screens] objectAtIndex:1] availableModes]])) {
        
        // A second display is attached and it has a suitable display mode
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];
        secondScreen.currentMode = targetScreenMode;
        self.externalWindow = [[[UIWindow alloc] initWithFrame:[secondScreen bounds]] autorelease];
        self.externalWindow.screen = secondScreen;
        self.viewController = [[[NESExternalGLKViewController alloc] initWithVideoBuffer:[ppuEmulator videoBuffer] andDisplayBounds:[secondScreen bounds]] autorelease];
        self.externalWindow.rootViewController = self.viewController;
        self.externalWindow.hidden = NO;
        
        // If we don't already have a controller view up, display one
        if (!self.window.rootViewController || ![self.window.rootViewController isKindOfClass:[NESControllerViewController class]]) {
            
            self.window.rootViewController = [[[NESControllerViewController alloc] init] autorelease];
            ((NESControllerViewController *)self.window.rootViewController).controllerInterface = controllerInterface;
        }
    }
    else {
        
        // Destroy the external window object, if present
        if (self.externalWindow) self.externalWindow.hidden = YES;
        self.externalWindow = nil;
        
        // Configure for internal display and controls
        if (!self.window.rootViewController || ![self.window.rootViewController isKindOfClass:[NESPlayfieldGLKViewController class]]) {
            
            self.viewController = [[[NESPlayfieldGLKViewController alloc] initWithVideoBuffer:[ppuEmulator videoBuffer]] autorelease];
            ((NESPlayfieldGLKViewController *)self.viewController).controllerInterface = controllerInterface;
            
            // Add the view controller's view to the window and display.
            self.window.rootViewController = self.viewController;
        }
    }
}

- (void)handleScreenConnectNotification:(NSNotification*)aNotification
{
    [self pause:self];
    [self configureScreens];
    [self play:self];
}

- (void)handleScreenDisconnectNotification:(NSNotification*)aNotification
{
    [self pause:self];
    [self configureScreens];
    [self play:self];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Register application defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"externalControl",@"icade",@"externalControlType",nil]];
    
    // Setup Emulation Singletons
    controllerInterface = [[NESControllerInterface alloc] init];
    ppuEmulator = [[NESPPUEmulator alloc] init];
    apuEmulator = [[NESAPUEmulator alloc] init];
    cpuInterpreter = [[NES6502Interpreter alloc] initWithPPU:ppuEmulator andAPU:apuEmulator];
	cartEmulator = [[NESCartridgeEmulator alloc] initWithPPU:ppuEmulator andCPU:cpuInterpreter];
	[apuEmulator setDMCReadObject:cpuInterpreter];
	gameIsLoaded = NO;
	gameIsRunning = NO;
	playOnActivate = NO;
	
    // self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // [self configureScreens];
    self.window.rootViewController = self.romListController;
    [self.window makeKeyAndVisible];
    
    // Load the game
    // [self loadROM:@"BattleKid2-NewDemo.nes"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenConnectNotification:)
                                                 name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenDisconnectNotification:)
                                                 name:UIScreenDidDisconnectNotification object:nil];
    
    return YES;
}

- (void)nextFrame {
	
	uint_fast32_t actualCPUCyclesRun;
	
    [cpuInterpreter setData:[controllerInterface readController:0] forController:0];
	[cpuInterpreter setData:[controllerInterface readController:1] forController:1];// Pull latest controller data
	
	if ([ppuEmulator triggeredNMI]) [cpuInterpreter _performNonMaskableInterrupt]; // Invoke NMI if triggered by the PPU
	[cpuInterpreter executeUntilCycle:[ppuEmulator cpuCyclesUntilPrimingScanline]]; // Run CPU until just past VBLANK
	actualCPUCyclesRun = [cpuInterpreter executeUntilCycle:[ppuEmulator cpuCyclesUntilVblank]]; // Run CPU until the beginning of next VBLANK
	[apuEmulator endFrameOnCycle:actualCPUCyclesRun]; // End the APU frame and update timing correction
	[ppuEmulator runPPUUntilCPUCycle:actualCPUCyclesRun];
	[ppuEmulator resetCPUCycleCounter]; // Reset PPU's CPU cycle counter for next frame and update cartridge scanline counters (must occur before CPU cycle counter is reset)
	[cpuInterpreter resetCPUCycleCounter]; // Reset CPU cycle counter for next frame
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	NSLog(@"Macifomlite resigning active");
	
    [self pause:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (gameIsLoaded) [[cartEmulator cartridge] writeWRAMToDisk]; // Save SRAM to disk if the game uses it
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    NSLog(@"In applicationWillEnterForeground");
    
    // Configure screens in case the configuration has changed
    [self configureScreens];
    
    // Notify view controller to check controller settings
    if ([self.window.rootViewController respondsToSelector:@selector(configureControllerInput)]) [self.window.rootViewController performSelector:@selector(configureControllerInput)];
    
    // Unpause the game if one is loaded
    [self play:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenConnectNotification:)
                                                 name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenDisconnectNotification:)
                                                 name:UIScreenDidDisconnectNotification object:nil];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	// [self _willGainFocus:nil];
    
    // Make sure we recover from an SMS or phone call.
    NSLog(@"In applicationDidBecomeActive");
    
    if (gameIsLoaded && !gameIsRunning) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenConnectNotification:)
                                                     name:UIScreenDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenDisconnectNotification:)
                                                     name:UIScreenDidDisconnectNotification object:nil];
        [self play:self];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	if (gameIsRunning) [self pause:self]; // Pause the game
	[apuEmulator stopAPUPlayback]; // Terminate audio playback
	if (gameIsLoaded) [[cartEmulator cartridge] writeWRAMToDisk]; // Save SRAM to disk if the game uses it
	
	// return NSTerminateNow;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	// NSLog(@"Memory warning!");
}


- (void)dealloc {
    
    if (gameIsRunning) {
        
        self.viewController.paused = YES;
        [apuEmulator stopAPUPlayback];
    }
    [cpuInterpreter release];
    [apuEmulator release];
    [ppuEmulator release];
    [cartEmulator release];
    [controllerInterface release];
    [viewController release];
    [window release];
    [externalWindow release];
    
    [super dealloc];
}

- (void)loadROM:(NSString *)path
{
	NSError *propagatedError;
    
    if (nil == (propagatedError = [cartEmulator loadROMFileAtPath:path])) {
		
        NESCartridge *cartridge = [cartEmulator cartridge];
        iNESFlags *cartridgeData = [cartridge iNesFlags];
        
        // Friendly Cartridge Info
        NSLog(@"Cartridge Information:");
        NSLog(@"Mapper #: %d\t\tDescription: %@",cartridgeData->mapperNumber,[cartEmulator mapperDescription]);
        NSLog(@"Trainer: %@\t\tVideo Type: %@",(cartridgeData->hasTrainer ? @"Yes" : @"No"),(cartridgeData->isPAL ? @"PAL" : @"NTSC"));
        NSLog(@"Mirroring: %@\tBackup RAM: %@",(cartridgeData->usesVerticalMirroring ? @"Vertical" : @"Horizontal"),(cartridgeData->usesBatteryBackedRAM ? @"Yes" : @"No"));
        NSLog(@"Four-Screen VRAM Layout: %@",(cartridgeData->usesFourScreenVRAMLayout ? @"Yes" : @"No"));
        NSLog(@"PRG-ROM Banks: %d x 16kB\tCHR-ROM Banks: %d x 8kB",cartridgeData->numberOf16kbPRGROMBanks,cartridgeData->numberOf8kbCHRROMBanks);
        NSLog(@"Onboard RAM Banks: %d x 8kB",cartridgeData->numberOf8kbWRAMBanks);
        
        if (gameIsLoaded) [apuEmulator stopAPUPlayback]; // Terminate audio playback
        
        // Reconfigure the screen
        [self configureScreens];
        
        // Reset the PPU
        [ppuEmulator resetPPUstatus];
        
        // Set initial ROM pointers
        [cartridge setInitialROMPointers];
        
        // Configure initial PPU state
        [cartridge configureInitialPPUState];
        
        // Allow CPU Interpreter to cache PRGROM pointers
        [cpuInterpreter setCartridge:cartridge];
        
        // Reset the CPU to prepare for execution
        [cpuInterpreter reset];
        
        // Flip the bool to indicate that the game is loaded
        self.gameIsLoaded = YES;
        
        // Flip on audio
        [apuEmulator beginAPUPlayback];
        
        // Start the game
        [self play:self];
    }
    else {
        
        // Throw an error
        // errorDialog = [NSAlert alertWithError:propagatedError];
        // [errorDialog runModal];
        NSLog(@"Error loading ROM: %@",[propagatedError localizedDescription]);
    }
}

- (void)reset {
	
	if (gameIsLoaded) {
		
		// Reset the PPU
		[ppuEmulator resetPPUstatus];
		
		// Reset ROM bank mapping
		[[cartEmulator cartridge] setInitialROMPointers];
		
		// Configure initial PPU state
		[[cartEmulator cartridge] configureInitialPPUState];
		
		// Reset the CPU to prepare for execution
		[cpuInterpreter reset];
	}
}


- (IBAction)play:(id)sender {
	
	if (!gameIsRunning && gameIsLoaded) {
		
		gameIsRunning = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        // Allow viewController to drive emulation loop
        if ([self.viewController respondsToSelector:@selector(enableUpdates)]) {
            
            [self.viewController performSelector:@selector(enableUpdates)];
        }
        self.viewController.paused = NO;
		[apuEmulator resume]; // Start up the APU's buffered playback
	}
}

- (IBAction)pause:(id)sender {
    
    if (gameIsRunning && gameIsLoaded) {
        
        gameIsRunning = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [apuEmulator pause];
        self.viewController.paused = YES;
    }
}

- (void)returnToROMList
{
    [self pause:self];
    self.window.rootViewController = self.romListController;
    [self.window makeKeyAndVisible];
}

/*
 - (IBAction)displayManual:(id)sender
 {
 [self pause:sender];
 CATransition* transition = [CATransition animation];
 transition.duration = 0.5f;
 transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
 transition.type = kCATransitionFade;
 [self.window.layer addAnimation:transition forKey:nil];
 self.window.rootViewController = [[[NESManualViewController alloc] initWithNibName:@"NESManualViewController" bundle:nil] autorelease];
 }
 
 - (IBAction)hideManual:(id)sender
 {
 CATransition* transition = [CATransition animation];
 transition.duration = 0.5f;
 transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
 transition.type = kCATransitionFade;
 [self.window.layer addAnimation:transition forKey:nil];
 self.window.rootViewController = self.viewController;
 [self play:sender];
 }
 */

@end
