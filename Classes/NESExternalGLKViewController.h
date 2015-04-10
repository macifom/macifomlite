//
//  NESExternalGLKViewController.h
//  Battle Kid 2 Lite
//
//  Created by Auston Stewart on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface NESExternalGLKViewController : GLKViewController
{
    EAGLContext *_context;
    GLint backingWidth;
	GLint backingHeight;
	GLuint texture;
    uint_fast16_t *_videoBuffer;
    GLint deviceScale;
    GLint videoScale;
    GLint videoHorizontalOffset;
    GLint videoVerticalOffset;
    GLint videoWidth;
    GLint videoHeight;
    
    CGRect externalDisplayBounds;
    
    IMP _updateMethod;
    id _updateObject;
}

- (id)initWithVideoBuffer:(uint_fast16_t *)videoBuffer andDisplayBounds:(CGRect)bounds;
- (void)enableUpdates;

@property (nonatomic, retain) EAGLContext *context;

@end
