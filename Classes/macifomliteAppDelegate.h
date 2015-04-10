//
//  macifomliteAppDelegate.h
//  macifomlite
//
//  Created by Auston Stewart on 9/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

@class NESROMListController;
@class NESPlayfieldGLKViewController;
@class NESManualViewController;
@class NESPlayfieldView, NES6502Interpreter, NESAPUEmulator, NESPPUEmulator, NESCartridgeEmulator, NESControllerInterface;

@interface macifomliteAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    NESPlayfieldGLKViewController *viewController;
	
	uint_fast32_t ppuCyclesInLastFrame;
	NES6502Interpreter *cpuInterpreter;
	NESAPUEmulator *apuEmulator;
	NESPPUEmulator *ppuEmulator;
	NESCartridgeEmulator *cartEmulator;
	NESControllerInterface *controllerInterface;
	
	NESPlayfieldView *playfieldView;
	NESManualViewController *manualController;
    
	BOOL gameIsLoaded;
	BOOL gameIsRunning;
	BOOL playOnActivate;
}

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
/*
 - (IBAction)displayManual:(id)sender;
 - (IBAction)hideManual:(id)sender;
 */
- (void)loadROM:(NSString *)romName;
- (void)reset;
- (void)setGameIsLoaded:(BOOL)flag;
- (void)nextFrame;
- (void)returnToROMList;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UIWindow *externalWindow;
@property (nonatomic, retain) GLKViewController *viewController;
@property (nonatomic, assign) BOOL gameIsLoaded;
@property (nonatomic, retain) IBOutlet NESROMListController *romListController;

@end

