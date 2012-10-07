//
//  Geometry.h
//  SuperDBCore
//
//  Created by Jason Brennan on 2012-10-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Geometry : NSObject

+ (CGRect)makeRectWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;
+ (CGPoint)makePointWithX:(CGFloat)x y:(CGFloat)y;
+ (CGSize)makeSizeWithWidth:(CGFloat)width height:(CGFloat)height;

@end
