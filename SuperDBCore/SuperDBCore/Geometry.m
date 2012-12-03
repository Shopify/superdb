//
//  Geometry.m
//  SuperDBCore
//
//  Created by Jason Brennan on 2012-10-07.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "Geometry.h"

@implementation Geometry


+ (CGRect)makeRectWithX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
	return CGRectMake(x, y, width, height);
}


+ (CGPoint)makePointWithX:(CGFloat)x y:(CGFloat)y {
	return CGPointMake(x, y);
}


+ (CGSize)makeSizeWithWidth:(CGFloat)width height:(CGFloat)height {
	return CGSizeMake(width, height);
}


@end
