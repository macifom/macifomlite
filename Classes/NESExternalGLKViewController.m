//
//  NESPlayfieldGLKViewController.m
//  macifomlite
//
//  Created by Auston Stewart on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NESExternalGLKViewController.h"
#import "macifomliteAppDelegate.h"
#include "macifomliteConstants.h"
#import <OpenGLES/ES1/gl.h>

@implementation NESExternalGLKViewController

@synthesize context = _context;

// Dummy update method
- (void)nextFrame
{
    
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
}

- (id)initWithVideoBuffer:(uint_fast16_t *)videoBuffer andDisplayBounds:(CGRect)bounds;
{
    self = [super init];
    if (self) {
        
        _videoBuffer = videoBuffer;
        externalDisplayBounds = bounds;
        [self setParameters];
        
        self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1] autorelease];
        
        if (!self.context) {
            NSLog(@"Failed to create ES context");
        }
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)setupGL
{
    GLint rect[4] = {0, -24, NES_VISIBLE_PIXELS_WIDTH, -NES_VISIBLE_PIXELS_HEIGHT};
    
	[EAGLContext setCurrentContext:self.context];
    
    // [(GLKView *)self.view bindDrawable];
    // glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	// glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    // NSLog(@"Got backing size: %dx%d",backingWidth,backingHeight);
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
    
    // portraitSkinTexture = [self loadTextureForKey:@"portrait"];
    // landscapeSkinTexture = [self loadTextureForKey:@"landscape"];
    
    // NSLog(@"Portrait texture: %d",portraitSkinTexture);
    // NSLog(@"Landscape texture: %d",landscapeSkinTexture);
    
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

- (void)loadView
{
    self.view = [[GLKView alloc] initWithFrame:CGRectMake(0.f,0.f,externalDisplayBounds.size.width,externalDisplayBounds.size.height) context:self.context];
    ((GLKView *)self.view).contentScaleFactor = 1.f;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [EAGLContext setCurrentContext:self.context];
    
    if ((self.view.frame.size.height / self.view.frame.size.width) == 0.75f) {
        
        // If this is a 4:3 resolution, fill it
        videoWidth = self.view.frame.size.width;
        videoHeight = self.view.frame.size.height;
    }
    else {
        
        // Find the closest 4:3 that will fit
        if (self.view.frame.size.width >= NES_VISIBLE_PIXELS_WIDTH * 4.f) {
            
            // This is nice for 720p, which nearly all HDTVs support
            videoWidth = NES_VISIBLE_PIXELS_WIDTH * 4;
            videoHeight = NES_VISIBLE_PIXELS_HEIGHT * 3;
        }
        else {
            
            videoHeight = self.view.frame.size.height;
            videoWidth = floorf(self.view.frame.size.height * 1.333333f);
        }
    }
    
    videoHorizontalOffset = floorf((self.view.frame.size.width - videoWidth) / 2.f);
    videoVerticalOffset = floorf((self.view.frame.size.height - videoHeight) / 2.f);
    
    NSLog(@"Decided on external video size: %dx%d with offset %d,%d",videoWidth,videoHeight,videoHorizontalOffset,videoVerticalOffset);
    
    // _numActiveLayers = 0;
    self.preferredFramesPerSecond = 60;
    self.view.userInteractionEnabled = NO;
    ((GLKView *)self.view).drawableMultisample = GLKViewDrawableMultisampleNone;
    ((GLKView *)self.view).drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    ((GLKView *)self.view).drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    ((GLKView *)self.view).drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    // self.view.multipleTouchEnabled = YES;
    
    [self setupGL];
    // [self configureControllerInput];
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
}

- (void)update
{
    _updateMethod(_updateObject,@selector(nextFrame));
    
    // Upload the next frame of the game to OpenGL
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, VIDEO_PIXEL_WIDTH, VIDEO_PIXEL_HEIGHT, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, _videoBuffer);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Draw the game video using the OpenGL ES 1.1 Extension OES_draw_texture
    glBindTexture(GL_TEXTURE_2D, texture);
    glDrawTexiOES(videoHorizontalOffset, videoVerticalOffset, 0, videoWidth, videoHeight);
}

- (void)enableUpdates
{
    _updateObject = [[UIApplication sharedApplication] delegate];
    _updateMethod = [(macifomliteAppDelegate *)[[UIApplication sharedApplication] delegate] methodForSelector:@selector(nextFrame)];
}

@end
