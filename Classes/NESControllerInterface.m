//
//  NESControllerInterface.m
//  Macifom
//
//  Created by Auston Stewart on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NESControllerInterface.h"
#include "macifomliteConstants.h"
#import "macifomliteAppDelegate.h"

@implementation NESControllerInterface

- (NSString *)_nameForButton:(NESControllerButton)button
{
	switch (button) {
            
		case NESControllerButtonUp:
			return @"Up";
			break;
		case NESControllerButtonDown:
			return @"Down";
			break;
		case NESControllerButtonLeft:
			return @"Left";
			break;
		case NESControllerButtonRight:
			return @"Right";
			break;
		case NESControllerButtonSelect:
			return @"Select";
			break;
		case NESControllerButtonStart:
			return @"Start";
			break;
		case NESControllerButtonA:
			return @"A";
			break;
		case NESControllerButtonB:
			return @"B";
			break;
		default:
			break;
	}
	
	return nil;
}

- (void)configureForInternalDisplay
{
    // _videoBuffer = (uint_fast16_t *)malloc(sizeof(uint_fast16_t)*256*256); // Making a power-of-two texture
    mainScreenBounds = [UIScreen mainScreen].bounds;
    externalDisplayModeEnabled = NO;
    
    // NSLog(@"Got Main Screen Bounds: %.0f,%.0f",mainScreenBounds.size.width,mainScreenBounds.size.height);
    [self deviceDidRotateToOrientation:currentOrientation];
}

- (void)configureForExternalDisplay
{
    externalDisplayModeEnabled = YES;
    
    [self deviceDidRotateToOrientation:currentOrientation];
}

- (id)init {
    
	[super init];
    
    _rapidFireLimiter = 0;
	_controllers = (uint_fast32_t *)malloc(sizeof(uint_fast32_t)*2);
	_controllers[0] = 0x0001FF00; // Should indicate one controller on $4016 per nestech.txt
	_controllers[1] = 0x0002FF00; // Should indicate one controller on $4017 per nestech.txt
    
    iCadeModeIsEnabled = NO;
    interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    currentOrientation = UIInterfaceOrientationPortrait;
    
    [self configureForInternalDisplay];
	
	return self;
}

- (void)setButton:(NESControllerButton)button forController:(int)index withBool:(int)flag
{
	switch (button) {
			
		case NESControllerButtonUp:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFFCF; // FIXME: Currently, we clear up and down to prevent errors. Perhaps I should clear all directions?
				_controllers[index] |= 0x10; // Up
			}
			else {
				_controllers[index] &= 0xFFFFFFEF; // Clear up
			}
			break;
		case NESControllerButtonLeft:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFF3F; // Clear left and right to prevent errors
				_controllers[index] |= 0x40; // Left
			}
			else {
				_controllers[index] &= 0xFFFFFFBF;
			}
			break;
		case NESControllerButtonDown:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFFCF;
				_controllers[index] |= 0x20; // Down
			}
			else {
				_controllers[index] &= 0xFFFFFFDF;
			}
			break;
		case NESControllerButtonRight:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFF3F;
				_controllers[index] |= 0x80; // Right
			}
			else {
				_controllers[index] &= 0xFFFFFF7F;
			}
			break;
		case NESControllerButtonA:
			if (flag) {
				
				_controllers[index] |= 0x1; // A button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFE; // A button release
			}
			break;
		case NESControllerButtonB:
			if (flag) {
				
				_controllers[index] |= 0x2; // B button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFD; // B button release
			}
			break;
		case NESControllerButtonSelect:
			if (flag) {
				
				_controllers[index] |= 0x4; // Select button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFB; // Select button fire
			}
			break;
		case NESControllerButtonStart:
			if (flag) {
				
				_controllers[index] |= 0x8; // Start button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFF7; // Start button fire
			}
			break;
		default:
			break;
	}
}

- (void)configureExternalControls
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"externalControlType"] && [[[NSUserDefaults standardUserDefaults] objectForKey:@"externalControlType"] isEqualToString:@"icadeMobile"]) {
        
        // iCade Mobile Button Masks
        _externalControlBButtonMask = iCadeButtonA;
        _externalControlAButtonMask = iCadeButtonB;
        _externalControlSelectButtonMask = iCadeButtonE;
        _externalControlStartButtonMask = iCadeButtonF;
    }
    else {
        
        // Standard iCade Button Masks
        _externalControlBButtonMask = iCadeButtonD;
        _externalControlAButtonMask = iCadeButtonE;
        _externalControlSelectButtonMask = iCadeButtonB;
        _externalControlStartButtonMask = iCadeButtonA;
    }
}

- (void)deviceDidRotateToOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (externalDisplayModeEnabled && !(interfaceOrientation == UIInterfaceOrientationPortrait) && (interfaceIdiom == UIUserInterfaceIdiomPhone)) {
        
        // Large button mode for external display mode on iPhone
        dpadSectionSize = DPAD_SECTION_SIZE_IPHONE_TV;
        dpadLeftOffset = DPAD_LEFT_OFFSET_IPHONE_TV;
        dpadBottomOffset = DPAD_BOTTOM_OFFSET_IPHONE_TV;
        buttonSectionSize = BUTTON_SECTION_SIZE_IPHONE_TV;
        buttonsRightOffset = BUTTONS_RIGHT_OFFSET_IPHONE_TV;
        buttonsBottomOffset = BUTTONS_BOTTOM_OFFSET_IPHONE_TV;
        shoulderButtonWidth = SHOULDER_BUTTON_WIDTH_IPHONE;
        dpadDeadspaceSize = DPAD_DEADSPACE_SIZE_IPHONE_TV;
    }
    else {
        
        // Default Control Parameters
        dpadSectionSize = (interfaceIdiom == UIUserInterfaceIdiomPad ? DPAD_SECTION_SIZE_IPAD : DPAD_SECTION_SIZE_IPHONE);
        dpadDeadspaceSize = (interfaceIdiom == UIUserInterfaceIdiomPad ? DPAD_DEADSPACE_SIZE_IPAD : DPAD_DEADSPACE_SIZE_IPHONE);
        dpadLeftOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? DPAD_LEFT_OFFSET_IPAD : DPAD_LEFT_OFFSET_IPHONE);
        dpadBottomOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? DPAD_BOTTOM_OFFSET_IPAD : DPAD_BOTTOM_OFFSET_IPHONE);
        buttonSectionSize = (interfaceIdiom == UIUserInterfaceIdiomPad ? BUTTON_SECTION_SIZE_IPAD : BUTTON_SECTION_SIZE_IPHONE);
        buttonsRightOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? BUTTONS_RIGHT_OFFSET_IPAD : BUTTONS_RIGHT_OFFSET_IPHONE);
        buttonsBottomOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? BUTTONS_BOTTOM_OFFSET_IPAD : BUTTONS_BOTTOM_OFFSET_IPHONE);
        shoulderButtonWidth = (interfaceIdiom == UIUserInterfaceIdiomPad ? SHOULDER_BUTTON_WIDTH_IPAD : SHOULDER_BUTTON_WIDTH_IPHONE);
    }
    
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        
        dpadRect = CGRectMake(dpadLeftOffset, mainScreenBounds.size.height - dpadBottomOffset - (dpadDeadspaceSize + (2.f * dpadSectionSize)), dpadDeadspaceSize + (2.f * dpadSectionSize), dpadDeadspaceSize + (2.f * dpadSectionSize));
        directionUpRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y, dpadRect.size.width, dpadSectionSize);
        directionDownRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y + dpadDeadspaceSize + dpadSectionSize, dpadRect.size.width, dpadSectionSize);
        directionLeftRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y, dpadSectionSize, dpadRect.size.height);
        directionRightRect = CGRectMake(dpadLeftOffset + dpadDeadspaceSize + dpadSectionSize, dpadRect.origin.y, dpadSectionSize, dpadRect.size.height);
        buttonsRect = CGRectMake(mainScreenBounds.size.width - buttonsRightOffset - (2.f * buttonSectionSize), mainScreenBounds.size.height - buttonsBottomOffset - (2.f * buttonSectionSize), 2.f * buttonSectionSize, 2.f * buttonSectionSize);
        topButtonsRect = CGRectMake(0.f, 0.f, mainScreenBounds.size.width, 40.f);
    }
    else if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        
        dpadRect = CGRectMake(dpadLeftOffset, mainScreenBounds.size.width - dpadBottomOffset - (dpadDeadspaceSize + (2.f * dpadSectionSize)), dpadDeadspaceSize + (2.f * dpadSectionSize), dpadDeadspaceSize + (2.f * dpadSectionSize));
        directionUpRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y, dpadRect.size.width, dpadSectionSize);
        directionDownRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y + dpadDeadspaceSize + dpadSectionSize, dpadRect.size.width, dpadSectionSize);
        directionLeftRect = CGRectMake(dpadLeftOffset, dpadRect.origin.y, dpadSectionSize, dpadRect.size.height);
        directionRightRect = CGRectMake(dpadLeftOffset + dpadDeadspaceSize + dpadSectionSize, dpadRect.origin.y, dpadSectionSize, dpadRect.size.height);
        buttonsRect = CGRectMake(mainScreenBounds.size.height - buttonsRightOffset - (2.f * buttonSectionSize), mainScreenBounds.size.width - buttonsBottomOffset - (2.f * buttonSectionSize), 2.f * buttonSectionSize, 2.f * buttonSectionSize);
        topButtonsRect = CGRectMake(0.f, 0.f, mainScreenBounds.size.height, 40.f);
    }
    
    currentOrientation = interfaceOrientation;
}

- (void)setDirectionWithPoint:(CGPoint)point toState:(BOOL)flag forController:(int)controller
{
    if (CGRectContainsPoint(directionUpRect, point)) [self setButton:NESControllerButtonUp forController:controller withBool:flag];
    else if (CGRectContainsPoint(directionDownRect, point)) [self setButton:NESControllerButtonDown forController:controller withBool:flag];
    
    if (CGRectContainsPoint(directionLeftRect, point)) [self setButton:NESControllerButtonLeft forController:controller withBool:flag];
    else if (CGRectContainsPoint(directionRightRect, point)) [self setButton:NESControllerButtonRight forController:controller withBool:flag];
}

- (void)setControlToState:(BOOL)flag withTouchPoint:(CGPoint)touchPoint touchEnded:(BOOL)touchEnded
{
    if (currentOrientation != UIInterfaceOrientationPortrait) {
        
        if (currentOrientation == UIInterfaceOrientationLandscapeLeft) {
            
            // Landscape Left
            // NSLog(@"Converting point for landscape left.");
            touchPoint = CGPointMake(mainScreenBounds.size.height - touchPoint.y, touchPoint.x);
        }
        else {
            
            // Landscape Right
            // NSLog(@"Converting point for landscape right");
            touchPoint = CGPointMake(touchPoint.y, mainScreenBounds.size.width - touchPoint.x);
        }
        // NSLog(@"Touchpoint converted to: %.0f,%.0f",touchPoint.x,touchPoint.y);
    }
    
    if (CGRectContainsPoint(dpadRect, touchPoint)) {
        
        // NSLog(@"Touch in dpad rect: %.0f,%.0f",touchPoint.x,touchPoint.y);
        [self setDirectionWithPoint:touchPoint toState:flag forController:0];
    }
    else if (CGRectContainsPoint(buttonsRect, touchPoint)) {
        
        // NSLog(@"Touch in buttons rect: %.0f,%.0f",touchPoint.x,touchPoint.y);
        
        if ((touchPoint.y - buttonsRect.origin.y) < buttonSectionSize) {
            
            if ((touchPoint.x - buttonsRect.origin.x) >= buttonSectionSize) {
                
                // A button was pressed
                [self setButton:NESControllerButtonA forController:0 withBool:flag];
            }
            else {
                
                // A+B button pressed
                [self setButton:NESControllerButtonA forController:0 withBool:flag];
                
                [self setButton:NESControllerButtonB forController:0 withBool:flag && !_rapidFireLimiter];
                
                if (touchEnded) _rapidFireLimiter = 0;
                else _rapidFireLimiter = (_rapidFireLimiter + 1) % 6;
            }
        }
        else if (((touchPoint.x - buttonsRect.origin.x) < buttonSectionSize) && ((touchPoint.y - buttonsRect.origin.y) >= buttonSectionSize)) {
            
            // B button was pressed
            [self setButton:NESControllerButtonB forController:0 withBool:flag];
        }
    }
    else if (CGRectContainsPoint(topButtonsRect, touchPoint)) {
        
        //NSLog(@"Touch in top button rect: %.0f,%.0f",touchPoint.x,touchPoint.y);
        
        if (touchPoint.x < shoulderButtonWidth) {
            
            // Select Was Pressed
            [self setButton:NESControllerButtonSelect forController:0 withBool:flag];
            
        }
        else if ((touchPoint.x + shoulderButtonWidth) > topButtonsRect.size.width) {
            
            // Start Was Pressed
            [self setButton:NESControllerButtonStart forController:0 withBool:flag];
        }
        else {
			
            [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] returnToROMList];
        }
    }
}

- (void)stateChanged:(iCadeState)state
{
    [self setButton:NESControllerButtonUp forController:0 withBool:state & iCadeJoystickUp];
    [self setButton:NESControllerButtonDown forController:0 withBool:state & iCadeJoystickDown];
    [self setButton:NESControllerButtonLeft forController:0 withBool:state & iCadeJoystickLeft];
    [self setButton:NESControllerButtonRight forController:0 withBool:state & iCadeJoystickRight];
    
    [self setButton:NESControllerButtonSelect forController:0 withBool:state & _externalControlSelectButtonMask];
    [self setButton:NESControllerButtonStart forController:0 withBool:state & _externalControlStartButtonMask];
    
    [self setButton:NESControllerButtonB forController:0 withBool:state & _externalControlBButtonMask];
    [self setButton:NESControllerButtonA forController:0 withBool:state & _externalControlAButtonMask];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint;
	
	for (UITouch *touch in touches) {
        
		touchPoint = [touch locationInView:nil];
		[self setControlToState:YES withTouchPoint:touchPoint touchEnded:NO];
		// NSLog(@"New touch occurred at %f,%f.",touchPoint.x,touchPoint.y);
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint;
	
	for (UITouch *touch in touches) {
		
		touchPoint = [touch previousLocationInView:nil];
		[self setControlToState:NO withTouchPoint:touchPoint touchEnded:NO];
		touchPoint = [touch locationInView:nil];
		[self setControlToState:YES withTouchPoint:touchPoint touchEnded:NO];
		// NSLog(@"Touch moved to %f,%f.",touchPoint.x,touchPoint.y);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint;
	
	for (UITouch *touch in touches) {
		
        touchPoint = [touch previousLocationInView:nil];
		// WAS: touchPoint = [touch locationInView:nil];
		[self setControlToState:NO withTouchPoint:touchPoint touchEnded:YES];
		// NSLog(@"Touch ended at %f,%f.",touchPoint.x,touchPoint.y);
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touchPoint;
    
    for (UITouch *touch in touches) {
		
        touchPoint = [touch previousLocationInView:nil];
		// WAS: touchPoint = [touch locationInView:nil];
		[self setControlToState:NO withTouchPoint:touchPoint touchEnded:YES];
		// NSLog(@"Touch ended at %f,%f.",touchPoint.x,touchPoint.y);
	}
}

- (uint_fast32_t)readController:(int)index
{
	return _controllers[index];
}

@end
