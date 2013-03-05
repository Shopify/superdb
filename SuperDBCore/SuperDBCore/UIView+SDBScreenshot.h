//
//  UIView+SDBScreenshot.h
//  SuperDBCore
//
//  Created by Mathieu Godart on 05/03/13.
//  Copyright (c) 2013 Super Debugger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SDBScreenshot)

// Generate an image of the receiver appearance.
// TODO: Improve the target resolution of the generated photo. See that page, to do so:
// http://stackoverflow.com/questions/2500915/how-to-create-an-image-from-a-uiview-uiscrollview
- (UIImage *)generateImage;

@end
