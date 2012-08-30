/*   ReplacementForCoderForClass.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <Foundation/Foundation.h>

@class NSString;

@interface FSReplacementForCoderForClass : NSObject <NSCoding>
{
  NSString *className;
}

- awakeAfterUsingCoder:(NSCoder *)aCoder;
- (void)dealloc;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- initWithClass:(Class)theClass;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
