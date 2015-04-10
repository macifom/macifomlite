//
//  NESControllerViewController.m
//  Battle Kid 2 Lite
//
//  Created by Auston Stewart on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NESControllerViewController.h"
#import "NESControllerInterface.h"
#import "macifomliteAppDelegate.h"
#include "macifomliteConstants.h"
#import <ImageIO/ImageIO.h>

@interface NESControllerViewController ()

@end

@implementation NESControllerViewController

@synthesize controllerImageView;

- (CGImageRef)cgImageAtURL:(NSURL *)url
{
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];
    CGImageSourceRef imageSource;
    CGImageRef image;
    
    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanFalse;
    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    // Create the dictionary
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    
    imageSource = CGImageSourceCreateWithURL((CFURLRef)url,myOptions);
    image = CGImageSourceCreateImageAtIndex(imageSource, 0, myOptions);
    CFRelease(myOptions);
    CFRelease(imageSource);
    
    return image;
}

- (void)setParameters
{
    interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
}

- (UIImage *)imageForKey:(NSString *)key
{
    NSString *resourcePrefix;
    CGImageRef backgroundImage;
    UIImage *imageToReturn = nil;
    
    resourcePrefix = [NSString stringWithFormat:@"%@_%@",SKIN_ARTFILE_PREFIX,key];
    
    backgroundImage = [self cgImageAtURL:[[NSBundle mainBundle] URLForResource:([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? [NSString stringWithFormat:@"%@_iPad",resourcePrefix] : [NSString stringWithFormat:(([UIScreen mainScreen].scale > 1) ? ([UIScreen mainScreen].bounds.size.height > 480.f ? @"%@_iPhone_5inRetina" : @"%@_iPhone_Retina") : @"%@_iPhone"),resourcePrefix]) withExtension:@"png"]];
    
    imageToReturn = [UIImage imageWithCGImage:backgroundImage];
    CGImageRelease(backgroundImage);
    
    return imageToReturn;
}

- (id)init
{
    self = [super initWithNibName:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"NESControllerViewControlleriPad" : @"NESControllerViewController") bundle:nil];
    
    if (self) {
        
        [self setParameters];
    }
    
    return self;
}

- (void)configureControllerInput
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"externalControl"] && [[[NSUserDefaults standardUserDefaults] objectForKey:@"externalControl"] boolValue]) {
        
        [_controllerInterface configureExternalControls];
        
        if (!_icadeReader) {
            
            _icadeReader = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
            [self.view addSubview:_icadeReader];
            _icadeReader.delegate = _controllerInterface;
        }
        _icadeReader.active = YES;
        iCadeModeIsEnabled = YES;
    }
    else {
        
        if (_icadeReader) {
            
            _icadeReader.active = NO;
        }
        iCadeModeIsEnabled = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureControllerInput];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.multipleTouchEnabled = YES;
    self.controllerImageView.image = [self imageForKey:@"portrait"];
    [self configureControllerInput];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Device orientation handling

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) self.controllerImageView.image = [self imageForKey:@"tvoutLandscape"];
    else self.controllerImageView.image = [self imageForKey:@"portrait"];
    
    [_controllerInterface deviceDidRotateToOrientation:toInterfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] pause:self];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] play:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[_controllerInterface touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[_controllerInterface touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[_controllerInterface touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_controllerInterface touchesCancelled:touches withEvent:event];
}

- (NESControllerInterface *)controllerInterface
{
    return _controllerInterface;
}

- (void)setControllerInterface:(NESControllerInterface *)controllerInterface
{
    _controllerInterface = controllerInterface;
    [_controllerInterface configureForExternalDisplay];
}

@end
