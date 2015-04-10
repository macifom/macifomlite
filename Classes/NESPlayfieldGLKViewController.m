//
//  NESPlayfieldGLKViewController.m
//  macifomlite
//
//  Created by Auston Stewart on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NESPlayfieldGLKViewController.h"
#import "NESControllerInterface.h"
#import "macifomliteAppDelegate.h"
#include "macifomliteConstants.h"
#import <ImageIO/ImageIO.h>
#import <OpenGLES/ES1/gl.h>

@implementation NESPlayfieldGLKViewController

@synthesize context = _context;

// Dummy update method
- (void)nextFrame
{
    
}

- (GLint)textureDimensionForCGImage:(CGImageRef)imageRef
{
    CGFloat longestDimension = (CGImageGetWidth(imageRef) >= CGImageGetHeight(imageRef) ? CGImageGetWidth(imageRef) : CGImageGetHeight(imageRef));
    
    if (longestDimension <= 256.f) return 256;
    else if (longestDimension <= 512.f) return 512;
    else if (longestDimension <= 1024.f) return 1024;
    else if (longestDimension <= 2048.f) return 2048;
    
    return 0;
}

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

- (GLuint)setupTextureWithCGImage:(CGImageRef)spriteImage {
    
    GLint textureDimension;
    int rect[4] = { 0, 0, 0, 0 };
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    // NSLog(@"Loading image of size: %lux%lu",width,height);
    rect[2] = (int)width;
    rect[3] = (int)-height;
    
    textureDimension = [self textureDimensionForCGImage:spriteImage];
    
    GLubyte * spriteData = (GLubyte *)calloc(textureDimension * textureDimension * 4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, textureDimension, textureDimension, 8, textureDimension * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);    
    
    CGContextDrawImage(spriteContext, CGRectMake(0.f, 0.f, width, height), spriteImage);
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_CROP_RECT_OES, rect);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureDimension, textureDimension, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    // glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

- (void)dealloc
{
    [_context release];
    
    [super dealloc];
}

- (void)setParameters
{
    self.paused = YES;
    self.pauseOnWillResignActive = NO;
    self.resumeOnDidBecomeActive = NO;
    
    _updateObject = self;
    _updateMethod = [self methodForSelector:@selector(nextFrame)];
    iCadeModeIsEnabled = NO;
    interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    // _videoBuffer = (uint_fast16_t *)malloc(sizeof(uint_fast16_t)*256*256); // Making a power-of-two texture
    deviceScale = [UIScreen mainScreen].scale;
    mainScreenBounds = [UIScreen mainScreen].bounds;
    backingWidth = deviceScale * mainScreenBounds.size.width;
    backingHeight = deviceScale * mainScreenBounds.size.height;
    transparentOverlayInLandscape = ((interfaceIdiom == UIUserInterfaceIdiomPad) || (mainScreenBounds.size.height > 480.f));
    
    // Set Default Video Parameters
    videoWidth = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_WIDTH_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_WIDTH_IPHONE5_PORTRAIT : VIDEO_WIDTH_IPHONE_PORTRAIT)) * deviceScale;
    videoHeight = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HEIGHT_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_HEIGHT_IPHONE5_PORTRAIT : VIDEO_HEIGHT_IPHONE_PORTRAIT)) * deviceScale;
    videoHorizontalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HORIZONTAL_OFFSET_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_HORIZONTAL_OFFSET_IPHONE5_PORTRAIT : VIDEO_HORIZONTAL_OFFSET_IPHONE_PORTRAIT)) * deviceScale;
    videoVerticalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_VERTICAL_OFFSET_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_VERTICAL_OFFSET_IPHONE5_PORTRAIT : VIDEO_VERTICAL_OFFSET_IPHONE_PORTRAIT)) * deviceScale;
    
    // NSLog(@"Got Main Screen Bounds: %.0f,%.0f",mainScreenBounds.size.width,mainScreenBounds.size.height);
    // videoScale = deviceScale * (interfaceIdiom == UIUserInterfaceIdiomPad ? 3 : 1);
    if (_videoBuffer == NULL) NSLog(@"Unable to allocate video buffer.");
    
    currentOrientation = UIInterfaceOrientationPortrait;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setParameters];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [self setParameters];
    }
    return self;
}

- (id)initWithVideoBuffer:(uint_fast16_t *)videoBuffer;
{
    self = [super initWithNibName:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"NESPlayfieldGLKViewControlleriPad" : @"NESPlayfieldGLKViewController") bundle:nil];
    
    if (self) {
        
        _videoBuffer = videoBuffer;
        [self setParameters];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (GLuint)loadTextureForKey:(NSString *)key
{
    NSString *resourcePrefix;
    CGImageRef backgroundImage;
    GLuint textureNumber = 0;
    
    resourcePrefix = [NSString stringWithFormat:@"%@_%@",SKIN_ARTFILE_PREFIX,key];
    
    backgroundImage = [self cgImageAtURL:[[NSBundle mainBundle] URLForResource:([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? [NSString stringWithFormat:@"%@_iPad",resourcePrefix] : [NSString stringWithFormat:((deviceScale > 1) ? (mainScreenBounds.size.height > 480.f ? @"%@_iPhone_5inRetina" : @"%@_iPhone_Retina") : @"%@_iPhone"),resourcePrefix]) withExtension:@"png"]];
    
    textureNumber = [self setupTextureWithCGImage:backgroundImage];
    CGImageRelease(backgroundImage);
    
    return textureNumber;
}

#pragma mark - View lifecycle

- (void)setupGL
{    
    GLint rect[4] = {0, -24, NES_VISIBLE_PIXELS_WIDTH, -NES_VISIBLE_PIXELS_HEIGHT};
    
	[EAGLContext setCurrentContext:self.context];
    
    //glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	//glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    // NSLog(@"%dx%d",backingWidth,backingHeight);
    // backgroundRect[2] = backingWidth;
    // backgroundRect[3] = -backingHeight;
    
	// Sets up matrices and transforms for OpenGL ES
	// glViewport(0, 0, 320, 480);
	// glMatrixMode(GL_PROJECTION);
	// glLoadIdentity();
	// glOrthox(0, 320, 480, 0, 0, 1);
	// glMatrixMode(GL_MODELVIEW);
	
    // Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    portraitSkinTexture = [self loadTextureForKey:@"portrait"];
    landscapeSkinTexture = [self loadTextureForKey:@"landscape"];
    
    NSLog(@"Portrait texture: %d",portraitSkinTexture);
    NSLog(@"Landscape texture: %d",landscapeSkinTexture);
    
    // Use OpenGL ES to generate a name for the video texture.
    glGenTextures(1, &texture);
	glBindTexture(GL_TEXTURE_2D, texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_CROP_RECT_OES, rect);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    /*
     glDeleteBuffers(1, &_vertexBuffer);
     glDeleteBuffers(1, &_indexBuffer);
     
     if (_program) {
     glDeleteProgram(_program);
     _program = 0;
     }
     */
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
    
    [_controllerInterface deviceDidRotateToOrientation:self.interfaceOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"In NESPlayfieldGLKViewController viewWillAppear");
    
    [super viewWillAppear:animated];
    [self configureControllerInput];
    [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0.f];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // NSLog(@"In viewDidLoad");
    // Do any additional setup after loading the view from its nib.    
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1] autorelease];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
        
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    // _numActiveLayers = 0;
    self.preferredFramesPerSecond = 60;
    view.drawableMultisample = GLKViewDrawableMultisampleNone;
    view.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    view.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    self.view.multipleTouchEnabled = YES;
    
    [self setupGL];
    [self configureControllerInput];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    
    iCadeModeIsEnabled = NO;
    _icadeReader.active = NO;
    _icadeReader.delegate = nil;
    [_icadeReader release];
    _icadeReader = nil;
}

/*
 - (void)viewWillAppear:(BOOL)animated
 {
 [super viewWillAppear:animated];
 currentOrientation = [[UIDevice currentDevice] orientation];
 }
 */

#pragma mark - Device orientation handling

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == currentOrientation) return;
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        
        // Set Portrait Video Parameters
        videoWidth = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_WIDTH_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_WIDTH_IPHONE5_PORTRAIT : VIDEO_WIDTH_IPHONE_PORTRAIT)) * deviceScale;
        videoHeight = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HEIGHT_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_HEIGHT_IPHONE5_PORTRAIT : VIDEO_HEIGHT_IPHONE_PORTRAIT)) * deviceScale;
        videoHorizontalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HORIZONTAL_OFFSET_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_HORIZONTAL_OFFSET_IPHONE5_PORTRAIT : VIDEO_HORIZONTAL_OFFSET_IPHONE_PORTRAIT)) * deviceScale;
        videoVerticalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_VERTICAL_OFFSET_IPAD_PORTRAIT : (mainScreenBounds.size.height > 480.f ? VIDEO_VERTICAL_OFFSET_IPHONE5_PORTRAIT : VIDEO_VERTICAL_OFFSET_IPHONE_PORTRAIT)) * deviceScale;
        
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_BLEND);
    }
    else if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        
        // Set Landscape Video Parameters
        videoWidth = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_WIDTH_IPAD_LANDSCAPE : (mainScreenBounds.size.height > 480.f ? VIDEO_WIDTH_IPHONE5_LANDSCAPE : VIDEO_WIDTH_IPHONE_LANDSCAPE)) * deviceScale;
        videoHeight = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HEIGHT_IPAD_LANDSCAPE : (mainScreenBounds.size.height > 480.f ? VIDEO_HEIGHT_IPHONE5_LANDSCAPE : VIDEO_HEIGHT_IPHONE_LANDSCAPE)) * deviceScale;
        videoHorizontalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_HORIZONTAL_OFFSET_IPAD_LANDSCAPE : (mainScreenBounds.size.height > 480.f ? VIDEO_HORIZONTAL_OFFSET_IPHONE5_LANDSCAPE : VIDEO_HORIZONTAL_OFFSET_IPHONE_LANDSCAPE)) * deviceScale;
        videoVerticalOffset = (interfaceIdiom == UIUserInterfaceIdiomPad ? VIDEO_VERTICAL_OFFSET_IPAD_LANDSCAPE : (mainScreenBounds.size.height > 480.f ? VIDEO_VERTICAL_OFFSET_IPHONE5_LANDSCAPE : VIDEO_VERTICAL_OFFSET_IPHONE_LANDSCAPE)) * deviceScale;

        // NSLog(@"New Video Size: %dx%d and Offset: (%d,%d)",videoWidth,videoHeight,videoHorizontalOffset,videoVerticalOffset);
        if (transparentOverlayInLandscape) {
            
            glEnable(GL_ALPHA_TEST);
            glEnable(GL_BLEND);
        }
    }
    
    currentOrientation = toInterfaceOrientation;
    [_controllerInterface deviceDidRotateToOrientation:currentOrientation];
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

#pragma mark - Drawing update methods

- (void)update
{
    _updateMethod(_updateObject,@selector(nextFrame));
    
    // Upload the next frame of the game to OpenGL
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, VIDEO_PIXEL_WIDTH, VIDEO_PIXEL_HEIGHT, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, _videoBuffer);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (((currentOrientation != UIInterfaceOrientationPortrait) &&transparentOverlayInLandscape) || iCadeModeIsEnabled) glClear(GL_COLOR_BUFFER_BIT);
    else {
     
        // Draw the background texture
        glBindTexture(GL_TEXTURE_2D,(currentOrientation == UIInterfaceOrientationPortrait) ? portraitSkinTexture : landscapeSkinTexture);
        glDrawTexiOES(0, 0, 0, (currentOrientation == UIInterfaceOrientationPortrait) ? backingWidth : backingHeight,  (currentOrientation == UIInterfaceOrientationPortrait) ? backingHeight : backingWidth);
    }
    
    // Draw the game video using the OpenGL ES 1.1 Extension OES_draw_texture
    glBindTexture(GL_TEXTURE_2D, texture);
    glDrawTexiOES(videoHorizontalOffset, videoVerticalOffset, 0, videoWidth, videoHeight);
    
    if ((currentOrientation != UIInterfaceOrientationPortrait) &&transparentOverlayInLandscape && !iCadeModeIsEnabled) {
        
        // If we're in a landscape mode on iPad or iPhone 5 and iCade mode isnt' enabled, draw the overlay
        glBindTexture(GL_TEXTURE_2D, landscapeSkinTexture);
        glDrawTexiOES(0, 0, 0, backingHeight, backingWidth);
    }
}

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

- (uint_fast16_t *)videoBuffer
{
	return _videoBuffer;
}

- (NESControllerInterface *)controllerInterface
{
    return _controllerInterface;
}

- (void)setControllerInterface:(NESControllerInterface *)controllerInterface
{
    _controllerInterface = controllerInterface;
    [_controllerInterface configureForInternalDisplay];
}

- (void)enableUpdates
{
    _updateObject = [[UIApplication sharedApplication] delegate];
    _updateMethod = [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] methodForSelector:@selector(nextFrame)];
}

@end
