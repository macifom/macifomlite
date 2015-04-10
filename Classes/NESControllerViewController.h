//
//  NESControllerViewController.h
//  Battle Kid 2 Lite
//
//  Created by Auston Stewart on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCadeReaderView.h"

@class NESControllerInterface;

@interface NESControllerViewController : UIViewController<iCadeEventDelegate>
{
    UIUserInterfaceIdiom interfaceIdiom;
    
    BOOL iCadeModeIsEnabled;
    
    NESControllerInterface *_controllerInterface;
    iCadeReaderView *_icadeReader;
}

- (void)configureControllerInput;

@property (nonatomic,assign) IBOutlet UIImageView *controllerImageView;
@property (nonatomic, assign) NESControllerInterface *controllerInterface;

@end
