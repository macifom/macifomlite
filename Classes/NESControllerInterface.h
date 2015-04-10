//
//  NESControllerInterface.h
//  Macifom
//
//  Created by Auston Stewart on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCadeReaderView.h"

typedef enum {
	
	NESControllerButtonUp = 0,
	NESControllerButtonDown,
	NESControllerButtonLeft,
	NESControllerButtonRight,
	NESControllerButtonSelect,
	NESControllerButtonStart,
	NESControllerButtonA,
	NESControllerButtonB
} NESControllerButton;

@interface NESControllerInterface : NSObject<iCadeEventDelegate> {
	
	uint_fast32_t *_controllers;
    
    UIInterfaceOrientation currentOrientation;
    UIUserInterfaceIdiom interfaceIdiom;
    CGFloat dpadSectionSize;
    CGFloat dpadDeadspaceSize;
    CGFloat dpadLeftOffset;
    CGFloat dpadBottomOffset;
    CGFloat shoulderButtonWidth;
    CGFloat buttonSectionSize;
    CGFloat buttonsRightOffset;
    CGFloat buttonsBottomOffset;
    CGRect mainScreenBounds;
    CGRect dpadRect;
    CGRect directionUpRect;
    CGRect directionDownRect;
    CGRect directionLeftRect;
    CGRect directionRightRect;
    CGRect buttonsRect;
    CGRect topButtonsRect;
    int _externalControlBButtonMask;
    int _externalControlAButtonMask;
    int _externalControlSelectButtonMask;
    int _externalControlStartButtonMask;
    uint _rapidFireLimiter;
    
    iCadeReaderView *_icadeReader;
    BOOL iCadeModeIsEnabled;
    BOOL externalDisplayModeEnabled;
}

- (void)stateChanged:(iCadeState)state;
- (void)configureExternalControls;
- (void)configureForInternalDisplay;
- (void)configureForExternalDisplay;

- (uint_fast32_t)readController:(int)index;
- (void)setButton:(NESControllerButton)button forController:(int)index withBool:(int)flag;
- (void)deviceDidRotateToOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void)stateChanged:(iCadeState)state;
- (void)setControlToState:(BOOL)flag withTouchPoint:(CGPoint)touchPoint touchEnded:(BOOL)touchEnded;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
