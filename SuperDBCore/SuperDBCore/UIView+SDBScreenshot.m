//
//  UIView+SDBScreenshot.m
//  SuperDBCore
//
//  Created by Mathieu Godart on 05/03/13.
//  Copyright (c) 2013 Super Debugger. All rights reserved.
//

#import "UIView+SDBScreenshot.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (SDBScreenshot)

// Generate an image of the receiver appearance.
// TODO: Improve the target resolution of the generated photo. See that page, to do so:
// http://stackoverflow.com/questions/2500915/how-to-create-an-image-from-a-uiview-uiscrollview
- (UIImage *)generateImage
{
    UIGraphicsBeginImageContext(self.frame.size);
    CGContextRef generatingContext = UIGraphicsGetCurrentContext();
    
    [self.layer renderInContext:generatingContext];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
