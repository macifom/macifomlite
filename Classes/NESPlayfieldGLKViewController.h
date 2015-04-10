//
//  NESPlayfieldGLKViewController.h
//  macifomlite
//
//  Created by Auston Stewart on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <GLKit/GLKit.h>
#import "iCadeReaderView.h"

@class NESControllerInterface;

@interface NESPlayfieldGLKViewController : GLKViewController
{
    EAGLContext *_context;
    GLint backingWidth;
	GLint backingHeight;
	GLuint texture;
    GLuint portraitSkinTexture;
    GLuint landscapeSkinTexture;
    uint_fast16_t *_videoBuffer;
    GLint deviceScale;
    GLint videoHorizontalOffset;
    GLint videoVerticalOffset;
    GLint videoWidth;
    GLint videoHeight;
    UIInterfaceOrientation currentOrientation;
    UIUserInterfaceIdiom interfaceIdiom;
    CGFloat dpadSectionSize;
    CGFloat dpadLeftOffset;
    CGFloat dpadBottomOffset;
    CGFloat shoulderButtonWidth;
    CGFloat buttonSectionSize;
    CGFloat buttonsRightOffset;
    CGFloat buttonsBottomOffset;
    CGRect mainScreenBounds;
    CGRect dpadRect;
    CGRect buttonsRect;
    CGRect topButtonsRect;
    int _externalControlBButtonMask;
    int _externalControlAButtonMask;
    int _externalControlSelectButtonMask;
    int _externalControlStartButtonMask;
    
    BOOL iCadeModeIsEnabled;
    BOOL transparentOverlayInLandscape;
    
    NESControllerInterface *_controllerInterface;
    iCadeReaderView *_icadeReader;
    
    IMP _updateMethod;
    id _updateObject;
}

- (id)initWithVideoBuffer:(uint_fast16_t *)videoBuffer;
- (uint_fast16_t *)videoBuffer;
- (NESControllerInterface *)controllerInterface;
- (void)configureControllerInput;
- (void)enableUpdates;

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NESControllerInterface *controllerInterface;

@end
